// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:example/generated/texts/web.dart';
import 'package:web/web.dart';

void main() {
  (document.querySelector('#content') as HTMLElement).text = running;
}
