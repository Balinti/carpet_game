import 'package:flutter_test/flutter_test.dart';
import 'package:carpet_game/main.dart';

void main() {
  testWidgets('App loads home screen with all game modes', (WidgetTester tester) async {
    await tester.pumpWidget(const CarpetGameApp());

    // Verify the home screen loads with the app title
    expect(find.text('Carpet Game'), findsOneWidget);
    expect(find.text('Tile Matching Fun!'), findsOneWidget);

    // Verify kid-friendly modes section
    expect(find.text('For Kids'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Learning Mode'), findsOneWidget);

    // Verify cooperative modes section
    expect(find.text('Play Together'), findsOneWidget);
    expect(find.text('Build Together'), findsWidgets);

    // Verify competitive modes section
    expect(find.text('Challenge Mode'), findsOneWidget);
    expect(find.text('Color Dominoes'), findsWidgets);
  });
}
