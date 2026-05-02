import 'package:bear_tahan/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen on startup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BearTahanApp()));

    expect(find.text('BearTahan'), findsOneWidget);
    expect(find.text('Start Learning'), findsOneWidget);
    expect(find.text('Parent Mode'), findsOneWidget);
  });
}
