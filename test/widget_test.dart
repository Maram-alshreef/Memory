import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marama/main.dart';

void main() {
  testWidgets('Memora app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoraApp());
    await tester.pump();

    expect(find.byType(MemoraApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
