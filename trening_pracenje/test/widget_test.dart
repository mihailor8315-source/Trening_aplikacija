import 'package:flutter_test/flutter_test.dart';
import 'package:trening_pracenje/main.dart';

void main() {
  testWidgets('App se pokreće bez grešaka', (WidgetTester tester) async {
    await tester.pumpWidget(const TreningApp());
    expect(find.text('Moj Trening'), findsWidgets);
  });
}
