import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:u_and_me/main.dart';
import 'package:u_and_me/screens/splash_loading_screen.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UAndMeApp());
    expect(find.byType(SplashLoadingScreen), findsOneWidget);
  });
}
