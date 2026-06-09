import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/screens/auth/login_screen.dart';
//import 'package:bear_tahan/screens/auth/forgot_password_screen.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  testWidgets('Login Screen shows core branding and buttons', (tester) async {
    tester.view.physicalSize = const Size(1344, 2992);
    tester.view.devicePixelRatio = 3.5;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsWidgets); // Found in Tab and Button
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
