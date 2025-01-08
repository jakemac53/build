// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:benchmark_generator/input_generator.dart';
import 'package:benchmark_generator/workspace.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    print('''
Creates packages to benchmark build_analyzer_plugin performance.

Available builder names: JsonSerializable

Usage:

  dart run benchmark_generator <# libraries> <builder name> [additional builder names]
''');
    exit(1);
  }

  final libraryCount = int.parse(arguments[0]);

  final builderNames = arguments.skip(1).toList();
  final builders = <BuilderDescription>[
    for (final name in builderNames)
      switch (name) {
        'JsonSerializable' => BuilderDescription(
          Uri.parse('package:json_annotation/json_annotation.dart'),
          '@JsonSerializable()',
          buildClassContents:
              (String className) => '''
  factory $className.fromJson(Map<String, Object?> json) =>
      _\$${className}FromJson(json);

  Map<String, Object?> toJson() => _\$${className}ToJson(this);
''',
        ),
        _ => throw ArgumentError(name),
      },
  ];

  final workspace = await Workspace.find();
  print('Creating under: ${workspace.directory.path}');
  final inputGenerator = ClassesAndFieldsInputGenerator(
    builders: builders,
    fieldsPerClass: 100,
    classesPerLibrary: 10,
    librariesPerCycle: libraryCount,
  );
  inputGenerator.generate(workspace);
}
