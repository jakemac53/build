// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'workspace.dart';

class BuilderDescription {
  final Uri importUri;
  final String annotation;
  final String Function(String className)? buildClassContents;

  BuilderDescription(
    this.importUri,
    this.annotation, {
    this.buildClassContents,
  });
}

class ClassesAndFieldsInputGenerator {
  final List<BuilderDescription> builders;
  final int fieldsPerClass;
  final int classesPerLibrary;
  final int librariesPerCycle;

  ClassesAndFieldsInputGenerator({
    required this.builders,
    required this.fieldsPerClass,
    required this.classesPerLibrary,
    required this.librariesPerCycle,
  });

  void generate(Workspace workspace) {
    for (var i = 0; i != librariesPerCycle; ++i) {
      workspace.write('a$i.dart', source: _generateLibrary(i));
    }
  }

  String _generateLibrary(int index) {
    final buffer = StringBuffer();

    for (final builder in builders) {
      buffer.writeln("import '${builder.importUri}';");
    }

    if (librariesPerCycle != 1) {
      final nextLibrary = (index + 1) % librariesPerCycle;
      buffer.writeln("import 'a$nextLibrary.dart' as next_in_cycle;");
      buffer.writeln("part 'a$index.g.dart';");
      buffer.writeln('next_in_cycle.A0? referenceOther;');
    } else {
      buffer.writeln("part 'a$index.g.dart';");
    }

    for (var j = 0; j != classesPerLibrary; ++j) {
      buffer.write(_generateClass(index, j));
    }

    return buffer.toString();
  }

  String _generateClass(int libraryIndex, int index) {
    final className = 'A$index';
    String fieldName(int fieldIndex) {
      if (libraryIndex == 0 && index == 0 && fieldIndex == 0) {
        return 'aCACHEBUSTER';
      }
      return 'a$fieldIndex';
    }

    final result = StringBuffer();
    for (final builder in builders) {
      result.writeln(builder.annotation);
    }

    result.writeln('class $className {');

    // write the constructor
    result.writeln('$className({');
    for (var i = 0; i != fieldsPerClass; ++i) {
      result.writeln('this.${fieldName(i)},');
    }
    result.writeln('});');

    for (var builder in builders) {
      if (builder.buildClassContents case var buildClassContents?) {
        result.writeln(buildClassContents(className));
      }
    }

    for (var i = 0; i != fieldsPerClass; ++i) {
      result.writeln('int? ${fieldName(i)};');
    }

    result.writeln('}');
    return result.toString();
  }
}
