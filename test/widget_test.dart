import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login Screen shows core branding and buttons', (tester) async {
    debugPrint("Logical Width: ${tester.view.physicalSize.width / tester.view.devicePixelRatio}");
    debugPrint("Logical Height: ${tester.view.physicalSize.height / tester.view.devicePixelRatio}");
    tester.view.physicalSize = const Size(1344, 2992); 
    tester.view.devicePixelRatio = 3.5;
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        ),
      ),
    );

    debugPrint("Verified Logical Width: ${tester.view.physicalSize.width / tester.view.devicePixelRatio}");

    await tester.pumpAndSettle();

    expect(find.text('BearTahan'), findsOneWidget);
    expect(find.text('Log In / Start Learning'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}