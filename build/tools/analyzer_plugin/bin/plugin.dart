import 'dart:isolate';

import 'package:build_analyzer_plugin/src/start.dart';

void main(List<String> args, SendPort sendPort) {
  start(args, sendPort);
}
