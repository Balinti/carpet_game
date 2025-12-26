import 'package:flutter_test/flutter_test.dart';
import 'package:carpet_game/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CarpetGameApp());

    // Verify the home screen loads with the app title
    expect(find.text('Carpet Game'), findsOneWidget);
    expect(find.text('Tile Matching Challenge'), findsOneWidget);

    // Verify game mode options are present
    expect(find.text('Color Dominoes'), findsWidgets);
    expect(find.text('2 Players - Pass and Play'), findsOneWidget);
  });
}
