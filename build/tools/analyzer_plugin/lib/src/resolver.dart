import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';

class AnalyzerResolvers extends Resolvers {
  final AnalysisSession currentSession;

  AnalyzerResolvers(this.currentSession);

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async =>
      AnalyzerResolver(buildStep, currentSession);
}

class AnalyzerResolver extends ReleasableResolver {
  final BuildStep buildStep;
  final AnalysisSession currentSession;

  AnalyzerResolver(this.buildStep, this.currentSession);

  @override
  Future<AssetId> assetIdForElement(Element element) async {
    final source = element.source;
    if (source == null) {
      throw UnresolvableAssetException(
          '${element.name} does not have a source');
    }

    final uri = source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException('${element.name} in ${source.uri}');
    }
    return AssetId.resolve(source.uri);
  }

  @override
  Future<AstNode?> astNodeFor(Element element, {bool resolve = false}) async {
    final library = element.library;
    if (library == null) {
      // Invalid elements (e.g. an MultiplyDefinedElement) are not part of any
      // library and can't be resolved like this.
      return null;
    }
    var path = library.source.fullName;

    var session = currentSession;
    if (resolve) {
      final result =
          await session.getResolvedLibrary(path) as ResolvedLibraryResult;
      if (element is CompilationUnitElement) {
        return result.unitWithPath(element.source.fullName)?.unit;
      }
      return result.getElementDeclaration(element)?.node;
    } else {
      final result = session.getParsedLibrary(path) as ParsedLibraryResult;
      if (element is CompilationUnitElement) {
        final unitPath = element.source.fullName;
        return result.units
            .firstWhereOrNull((unit) => unit.path == unitPath)
            ?.unit;
      }
      return result.getElementDeclaration(element)?.node;
    }
  }

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    var file = currentSession.fileForAsset(assetId);
    if (file == null || !file.exists) {
      throw AssetNotFoundException(assetId);
    }

    var parsedResult =
        currentSession.getParsedUnit(file.path) as ParsedUnitResult;
    if (!allowSyntaxErrors && parsedResult.errors.isNotEmpty) {
      throw SyntaxErrorInAssetException(assetId, [parsedResult]);
    }
    return parsedResult.unit;
  }

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async {
    await for (final library in libraries) {
      if (library.name == libraryName) return library;
    }
    return null;
  }

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    if (assetId.extension != '.dart') return false;
    if (!await buildStep.canRead(assetId)) return false;
    var file = currentSession.fileForAsset(assetId);
    if (file == null || !file.exists) return false;
    var result = currentSession.getFile(file.path) as FileResult;
    return !result.isPart;
  }

  @override
  // TODO: implement libraries
  Stream<LibraryElement> get libraries => throw UnimplementedError();

  @override
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    var uri = assetId.uri;
    var file = currentSession.fileForAsset(assetId);
    if (file == null || !file.exists) {
      throw AssetNotFoundException(assetId);
    }

    var parsedResult = currentSession.getParsedUnit(file.path);
    if (parsedResult is! ParsedUnitResult || parsedResult.isPart) {
      throw NonLibraryAssetException(assetId);
    }

    final library = await currentSession.getLibraryByUri(uri.toString())
        as LibraryElementResult;

    if (!allowSyntaxErrors) {
      final errors = await _syntacticErrorsFor(library.element);
      if (errors.isNotEmpty) {
        throw SyntaxErrorInAssetException(assetId, errors);
      }
    }

    return library.element;
  }

  /// Finds syntax errors in files related to the [element].
  ///
  /// This includes the main library and existing part files.
  Future<List<ErrorsResult>> _syntacticErrorsFor(LibraryElement element) async {
    final existingSources = [element.source];

    for (final part in element.definingCompilationUnit.parts) {
      var uri = part.uri;
      // There may be no source if the part doesn't exist. That's not important
      // for us since we only care about existing file syntax.
      if (uri is! DirectiveUriWithSource) continue;
      existingSources.add(uri.source);
    }

    final relevantResults = <ErrorsResult>[];

    for (final source in existingSources) {
      final path = currentSession.uriConverter.uriToPath(source.uri)!;
      final result = await currentSession.getErrors(path);
      if (result is ErrorsResult &&
          result.errors.any(
              (error) => error.errorCode.type == ErrorType.SYNTACTIC_ERROR)) {
        relevantResults.add(result);
      }
    }

    return relevantResults;
  }

  @override
  void release() {}
}

extension SessionHelpers on AnalysisSession {
  File? fileForAsset(AssetId id) {
    var path = uriConverter.uriToPath(id.uri);
    if (path == null) return null;
    return resourceProvider.getFile(path);
  }
}
