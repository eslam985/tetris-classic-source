import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_classic/main.dart';

void main() {
  testWidgets('App starts and shows Tetris title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('TETRIS'), findsOneWidget);
  });
}