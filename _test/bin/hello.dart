import 'package:collection/collection.dart';

main() {
  var queue = new QueueList.from(['foo', 'bar']);
  queue.add('baz');
  print(queue.first); // prints null ??
  print(queue.length); // prints 3 yay!
  print(queue); // throws
}
