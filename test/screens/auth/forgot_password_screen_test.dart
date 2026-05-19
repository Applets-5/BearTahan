import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bear_tahan/screens/auth/forgot_password_screen.dart';
import 'package:bear_tahan/providers/data_providers.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
      ],
      child: const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
  }

  testWidgets('renders all UI elements', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Reset Password'), findsOneWidget);
    expect(
      find.text('Enter your email address and we\'ll send you a link to reset your password.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('shows error when email is empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('calls sendPasswordResetEmail and pops when successful', (tester) async {
    when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
        .thenAnswer((_) async => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), 'test@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    verify(() => mockAuth.sendPasswordResetEmail(email: 'test@example.com')).called(1);
    
    // Check for success snackbar
    expect(find.text('Password reset email sent! Please check your inbox.'), findsOneWidget);
  });
}
