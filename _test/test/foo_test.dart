import 'package:collection/collection.dart';

main() {
  var queue = new QueueList.from([]);
  queue.add('baz');
  print(queue.first);
  print(queue.length);
  print(queue);
}
