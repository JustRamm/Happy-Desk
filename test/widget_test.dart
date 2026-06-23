import 'package:flutter_test/flutter_test.dart';
import 'package:happy_desk/main.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HappyDeskApp());
    expect(find.text('Happy Desk'), findsOneWidget);
  });
}
