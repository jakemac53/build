import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:build/build.dart';
import 'package:built_value_generator/built_value_generator.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
// ignore: implementation_imports
import 'package:json_serializable/src/settings.dart';
import 'package:source_gen/source_gen.dart';
import 'plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(
    BuildAnalyzerPlugin(builders: [
      PartBuilder([
        ...jsonSerializable(const BuilderOptions({}, isRoot: true)),
        const BuiltValueGenerator(),
      ], '.g.dart')
    ], resourceProvider: PhysicalResourceProvider.INSTANCE),
  ).start(sendPort);
}

/// EVERYTHING BELOW HERE IS COPIED INTERNAL STUFF FROM json_serializable

/// Supports `package:build_runner` creation and configuration of
/// `json_serializable`.
///
/// Not meant to be invoked by hand-authored code.
List<Generator> jsonSerializable(BuilderOptions options) {
  try {
    final config = JsonSerializable.fromJson(options.config);
    return jsonPartBuilder(config: config);
  } on CheckedFromJsonException catch (e) {
    final lines = <String>[
      'Could not parse the options provided for `json_serializable`.'
    ];

    if (e.key != null) {
      lines.add('There is a problem with "${e.key}".');
    }
    if (e.message != null) {
      lines.add(e.message!);
    } else if (e.innerError != null) {
      lines.add(e.innerError.toString());
    }

    throw StateError(lines.join('\n'));
  }
}

/// Returns a [Builder] for use within a `package:build_runner`
/// `BuildAction`.
List<Generator> jsonPartBuilder({
  JsonSerializable? config,
}) {
  final settings = Settings(config: config);

  return [
    _UnifiedGenerator([
      JsonSerializableGenerator.fromSettings(settings),
      const JsonEnumGenerator(),
    ]),
    const JsonLiteralGenerator(),
  ];
}

/// Allows exposing separate [GeneratorForAnnotation] instances as one
/// generator.
///
/// We want duplicate items to be merged if folks use both `@JsonEnum` and
/// `@JsonSerializable` so we don't get duplicate enum helper functions.
///
/// This can only be done if the output is merged into one generator.
///
/// This class allows us to keep the implementations separate.
class _UnifiedGenerator extends Generator {
  final List<GeneratorForAnnotation> _generators;

  _UnifiedGenerator(this._generators);

  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    for (var generator in _generators) {
      for (var annotatedElement
          in library.annotatedWith(generator.typeChecker)) {
        // await pubspecHasRightVersion(buildStep);

        final generatedValue = generator.generateForAnnotatedElement(
            annotatedElement.element, annotatedElement.annotation, buildStep);
        for (var value in _normalizeGeneratorOutput(generatedValue)) {
          assert(value.length == value.trim().length);
          values.add(value);
        }
      }
    }

    return values.join('\n\n');
  }

  @override
  String toString() => 'JsonSerializableGenerator';
}

// Borrowed from `package:source_gen`
Iterable<String> _normalizeGeneratorOutput(Object? value) {
  if (value == null) {
    return const [];
  } else if (value is String) {
    value = [value];
  }

  if (value is Iterable) {
    return value.where((e) => e != null).map((e) {
      if (e is String) {
        return e.trim();
      }

      throw _argError(e as Object);
    }).where((e) => e.isNotEmpty);
  }
  throw _argError(value);
}

// Borrowed from `package:source_gen`
ArgumentError _argError(Object value) => ArgumentError(
    'Must be a String or be an Iterable containing String values. '
    'Found `${Error.safeToString(value)}` (${value.runtimeType}).');
