// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
// import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
// import 'package:cli_util/cli_util.dart' as cli_util;
// import 'package:path/path.dart' as p;

const appKernelExtension = '.app.dill';

/// A builder which compiles entrypoints for the vm to a single .dill file.
class VmEntrypointBuilder implements Builder {
  const VmEntrypointBuilder();

  @override
  final buildExtensions = const {
    '.dart': const [appKernelExtension],
  };

  @override
  Future<Null> build(BuildStep buildStep) async {
    var dartEntrypointId = buildStep.inputId;
    var isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) return;
    var moduleId = buildStep.inputId.changeExtension(moduleExtension);
    var module = new Module.fromJson(
        json.decode(await buildStep.readAsString(moduleId))
            as Map<String, dynamic>);
    var transitiveModules =
        await module.computeTransitiveDependencies(buildStep);
    var transitiveKernelModules = transitiveModules
        .map((m) => m.kernelModuleId)
        .followedBy([module.kernelModuleId]);
    var appContents = <int>[];
    for (var dependencyId in transitiveKernelModules) {
      appContents.addAll(await buildStep.readAsBytes(dependencyId));
    }
    await buildStep.writeAsBytes(
        buildStep.inputId.changeExtension(appKernelExtension), appContents);
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  var parsed = parseCompilationUnit(await reader.readAsString(dartId),
      suppressErrors: true);
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO: This misses the case where a Dart file doesn't contain main(),
  // but has a part that does, or it exports a `main` from another library.
  return parsed.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == 'main' &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}
