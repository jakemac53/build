// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:package_config/package_config.dart';

class Workspace {
  final Directory directory;

  Workspace(this.directory);

  static Future<Workspace> find() async {
    var packageConfig = await loadPackageConfigUri(Isolate.packageConfigSync!);
    var packageUri =
        packageConfig.resolve(Uri.parse('package:plugin_torture_test/'))!;
    var packageDir = Directory.fromUri(packageUri);

    if (packageDir.existsSync()) packageDir.deleteSync(recursive: true);
    packageDir.createSync(recursive: true);

    return Workspace(packageDir);
  }

  void write(String path, {required String source}) {
    final file = File.fromUri(directory.uri.resolve(path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(source);
  }
}
