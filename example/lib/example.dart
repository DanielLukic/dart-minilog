import 'package:dart_minilog/dart_minilog.dart';

void main(List<String> args) async {
  sink = fileSink('mini.log');

  somewhereElse();
}

void somewhereElse() {
  logWarn('where am i?');
}
