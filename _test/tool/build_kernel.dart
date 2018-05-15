// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/builders.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';

Future main(List<String> args) async {
  var builders = [
    apply('_test|test_bootstrap', [(_) => new TestBootstrapBuilder()], toRoot(),
        defaultGenerateFor:
            const InputSet(include: const ['test/**_test.dart']),
        hideOutput: true),
    apply(
        'build_modules|modules',
        [
          metaModuleBuilder,
          metaModuleCleanBuilder,
          moduleBuilder,
          (_) => new KernelSummaryBuilder(),
          (_) => new KernelModuleBuilder(),
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    // apply(
    //     'build_web_compilers|ddc',
    //     [
    //       (_) => new DevCompilerBuilder(useKernel: true),
    //     ],
    //     toAllPackages(),
    //     isOptional: true,
    //     hideOutput: true),
    // apply(
    //     'build_web_compilers|entrypoint',
    //     [
    //       (_) => new WebEntrypointBuilder(WebCompiler.DartDevc, useKernel: true)
    //     ],
    //     toRoot(),
    //     defaultGenerateFor: const InputSet(include: const [
    //       'web/**.dart',
    //       'test/**.browser_test.dart',
    //     ]),
    //     hideOutput: true),
    apply('build_web_compilers|vm_entrypoint',
        [(_) => new VmEntrypointBuilder()], toRoot(),
        defaultGenerateFor: const InputSet(include: const [
          'bin/hello.dart',
          'test/foo_test.dart',
          'test/help_test.dart',
          'test/help_test.dart.vm_test.dart',
        ]),
        hideOutput: true)
  ];

  await run(args, builders);
}
