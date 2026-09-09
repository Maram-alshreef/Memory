import 'package:flutter_test/flutter_test.dart';
import 'package:marama/main.dart';

void main() {
  testWidgets('Memora app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoraApp());

    expect(find.text('Memora'), findsOneWidget);
  });
}
