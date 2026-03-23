import 'package:flutter_test/flutter_test.dart';
import 'package:edalab_app/app.dart';

void main() {
  testWidgets('EdaLab app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EdaLabApp());
    await tester.pump();
  });
}
