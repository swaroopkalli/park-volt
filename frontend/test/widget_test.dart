import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkvolt/main.dart';

void main() {
  testWidgets('shows login selector first', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ParkVoltApp()));
    await tester.pumpAndSettle();
    expect(find.text('Student 1'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
