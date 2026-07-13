import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_desk/main.dart';
import 'package:happy_desk/screens/splash_loading_screen.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HappyDeskApp());
    expect(find.byType(SplashLoadingScreen), findsOneWidget);
  });
}
