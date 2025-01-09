import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';

import 'package:build/build.dart';
import 'package:crypto/src/digest.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';

import 'resolver.dart';

StreamSubscription? _loggerSub;

void _ensureListeningToLogs() {
  _loggerSub ??= Logger.root.onRecord.listen((logRecord) {
    // Ignore these, we will re-analyze in this case.
    if (logRecord.error is InconsistentAnalysisException) return;

    logRecord.zone!.logs!.add(logRecord);
  });
}

class BuildAnalyzerPlugin extends ServerPlugin {
  final List<Builder> builders;

  BuildAnalyzerPlugin(
      {required this.builders, required super.resourceProvider}) {
    _ensureListeningToLogs();
  }

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    final logsForFile = <LogRecord>[];
    // Exit if `path` isn't under the current root.
    if (!analysisContext.contextRoot.root.contains(path)) return;
    var uri = analysisContext.currentSession.uriConverter.pathToUri(path);
    if (uri == null) return;
    if (uri.scheme != 'package') {
      // TODO: Support non-package URIs by resolving with the package config
      //  and creating an asset uri.
      return;
    }
    var assetId = AssetId.resolve(uri);

    for (var builder in builders) {
      var completer = Completer<void>();
      final logger = Logger('${builder}');
      // We need to capture the zone for logging errors, onError runs in
      // the parent zone.
      late final Zone zone;
      runZonedGuarded(() async {
        zone = Zone.current;
        await _runBuilder(
            builder,
            path,
            assetId,
            _AnalyzerReader(analysisContext.currentSession),
            _AnalyzerWriter(channel, analysisContext, resourceProvider),
            AnalyzerResolvers(analysisContext.currentSession),
            logger);

        if (!completer.isCompleted) completer.complete();
      }, (e, s) {
        logger.log(Level.SEVERE, null, e, s, zone);
        if (!completer.isCompleted) completer.complete();
      }, zoneValues: {
        _pathZoneKey: path,
        _analyzeFileLogsKey: logsForFile,
      });
      await completer.future;
    }

    AnalysisError convertLog(LogRecord log) {
      final severity = switch (log.level) {
        var level when level >= Level.SEVERE => AnalysisErrorSeverity.ERROR,
        var level when level >= Level.WARNING => AnalysisErrorSeverity.WARNING,
        _ => AnalysisErrorSeverity.INFO,
      };
      return AnalysisError(
        severity,
        AnalysisErrorType.LINT,
        // TODO: Grab from stack trace?
        Location(path, 0, 10, 1, 1, endLine: 1, endColumn: 11),
        log.fullMessage,
        '${log.loggerName}',
      );
    }

    // We always send notifications, even if they are empty. This clears old
    // ones out.
    channel.sendNotification(
      AnalysisErrorsParams(path, [
        for (var log in logsForFile) convertLog(log),
      ]).toNotification(),
    );
  }

  Future<void> _runBuilder(
      Builder builder,
      String path,
      AssetId id,
      AssetReader reader,
      AssetWriter writer,
      Resolvers resolvers,
      Logger logger) async {
    try {
      if (!builder.buildExtensions.keys.any((ext) => path.endsWith(ext))) {
        return;
      }
      await runBuilder(builder, [id], reader, writer, resolvers,
          logger: logger);
    } on InconsistentAnalysisException {
      // Ignore these, we will be re-ran.
      return;
    }
  }

  @override
  // Always start analysis from just the primary inputs of the builders.
  List<String> get fileGlobsToAnalyze =>
      Set.of(builders.expand((builder) => builder.buildExtensions.keys))
          .map((ext) => '**/*$ext')
          .toList();

  @override
  String get name => "Analyzer plugin for package:build";

  @override
  String get version => '1.0.0';
}

class _AnalyzerReader implements AssetReader {
  final AnalysisSession currentSession;

  _AnalyzerReader(this.currentSession);

  @override
  Future<bool> canRead(AssetId id) async {
    var file = currentSession.fileForAsset(id);
    return file != null && file.exists;
  }

  @override
  Future<Digest> digest(AssetId id) {
    // TODO: implement digest
    throw UnimplementedError();
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    // TODO: implement findAssets
    throw UnimplementedError();
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    var file = currentSession.fileForAsset(id);
    if (file == null || !file.exists) {
      throw AssetNotFoundException(id);
    }
    return file.readAsBytesSync();
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async =>
      encoding.decode(await readAsBytes(id));
}

class _AnalyzerWriter implements AssetWriter {
  final PluginCommunicationChannel channel;
  final AnalysisContext context;
  final ResourceProvider resourceProvider;

  _AnalyzerWriter(this.channel, this.context, this.resourceProvider);

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    var path = context.currentSession.uriConverter.uriToPath(id.uri);
    if (path == null) return;
    var file = resourceProvider.getFile(path);
    if (file.exists) {
      var existing = file.readAsBytesSync();
      if (existing.length == bytes.length) {
        var isDifferent = false;
        for (var i = 0; i < bytes.length; i++) {
          if (bytes[i] != existing[i]) {
            isDifferent = true;
            break;
          }
        }
        if (!isDifferent) return;
      }
    }
    // TODO: This gives an error about overlay file systems not being able to
    // write files.
    // file.writeAsBytesSync(bytes);
    await io.File(file.path).writeAsBytes(bytes);
  }

  @override
  Future<void> writeAsString(AssetId id, String contents,
          {Encoding encoding = utf8}) =>
      writeAsBytes(id, encoding.encode(contents));
}

extension on LogRecord {
  String get fullMessage {
    final buffer = StringBuffer('$loggerName: $message');
    if (error != null) {
      buffer.writeln(error);
    }
    if (stackTrace != null) {
      buffer.writeln(stackTrace);
    }
    return buffer.toString();
  }
}

/// Zone key for the currently analyzed path.
final Symbol _pathZoneKey = #_buildAnalyzerPluginAnalyzedPath;
final Symbol _analyzeFileLogsKey = #_analyzeFileLogsKey;

extension on Zone {
  List<LogRecord>? get logs => this[_analyzeFileLogsKey] as List<LogRecord>?;
}
