import 'cli.dart';

/// Big-B Calculator メインエントリーポイント
void main(List<String> arguments) {
  final cli = CliProcessor();
  cli.process(arguments);
}
