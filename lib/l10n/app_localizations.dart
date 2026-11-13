import 'package:flutter/material.dart';

/// Supported languages in the app.
enum AppLanguage {
  english('en', 'English', TextDirection.ltr),
  spanish('es', 'Español', TextDirection.ltr),
  hebrew('he', 'עברית', TextDirection.rtl);

  final String code;
  final String displayName;
  final TextDirection textDirection;

  const AppLanguage(this.code, this.displayName, this.textDirection);

  bool get isRtl => textDirection == TextDirection.rtl;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Provides localized strings for the app.
class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguage.english);
  }

  // App title and general
  String get appTitle => _t('Carpet Game', 'Juego de Alfombra', 'משחק השטיח');
  String get rotatePhone => _t('Turn your phone sideways to play', 'Gira tu teléfono de lado para jugar', 'סובבו את הטלפון לרוחב כדי לשחק');
  String get playAnyway => _t('Play anyway', 'Jugar de todos modos', 'לשחק בכל זאת');
  String get appSubtitle => _t('Tile Matching Fun!', '¡Diversión con Azulejos!', '!כיף עם אריחים');

  // Section headers
  String get forKids => _t('For Kids', 'Para Niños', 'לילדים');
  String get playTogether => _t('Play Together', 'Jugar Juntos', 'לשחק ביחד');
  String get challengeMode => _t('Challenge Mode', 'Modo Desafío', 'מצב אתגר');

  // Game modes
  String get freePlay => _t('Free Play', 'Juego Libre', 'משחק חופשי');
  String get learningMode => _t('Learning Mode', 'Modo Aprendizaje', 'מצב למידה');
  String get buildTogether => _t('Build Together', 'Construir Juntos', 'לבנות ביחד');
  String get colorDominoes => _t('Color Dominoes', 'Dominó de Colores', 'דומינו צבעים');
  String get starterPuzzle => _t('Starter Puzzle', 'Rompecabezas Inicial', 'פאזל התחלתי');

  // Mode descriptions
  String get soloCreativePlay => _t('Solo Creative Play', 'Juego Creativo Solo', 'משחק יצירתי לבד');
  String get learnAtYourPace => _t('Learn at Your Own Pace', 'Aprende a Tu Ritmo', 'למד בקצב שלך');
  String get twoPlayersTeamUp => _t('2 Players - Team Up!', '2 Jugadores - ¡En Equipo!', '!שחקנים - צוות 2');
  String get familyFun => _t('3-4 Players - Family Fun!', '3-4 Jugadores - ¡Diversión Familiar!', '!שחקנים - כיף משפחתי 4-3');
  String get twoPlayersPassPlay => _t('2 Players - Pass and Play', '2 Jugadores - Pasar y Jugar', 'שחקנים - העבר ושחק 2');
  String get threeFourPlayers => _t('3-4 Players', '3-4 Jugadores', 'שחקנים 4-3');
  String get fillThe3x3Grid => _t('Fill the 3x3 Grid', 'Completa la Cuadrícula 3x3', 'מלא את הרשת 3x3');

  // Player dialog
  String get howManyPlayers => _t('How many players?', '¿Cuántos jugadores?', '?כמה שחקנים');
  String get threePlayers => _t('3 Players', '3 Jugadores', 'שחקנים 3');
  String get fourPlayers => _t('4 Players', '4 Jugadores', 'שחקנים 4');
  String get cancel => _t('Cancel', 'Cancelar', 'ביטול');

  // Game screen
  String get rules => _t('Rules', 'Reglas', 'חוקים');
  String get newGame => _t('New Game', 'Nuevo Juego', 'משחק חדש');
  String get undo => _t('Undo', 'Deshacer', 'בטל');
  String get drawTile => _t('Draw Tile', 'Sacar Azulejo', 'משוך אריח');
  String get points => _t('points', 'puntos', 'נקודות');
  String get playAgain => _t('Play Again', 'Jugar de Nuevo', 'שחק שוב');
  String get gotIt => _t('Got it!', '¡Entendido!', '!הבנתי');

  // Player names
  String get builder => _t('Builder', 'Constructor', 'בונה');
  String get learner => _t('Learner', 'Aprendiz', 'לומד');
  String player(int number) => _t('Player $number', 'Jugador $number', '$number שחקן');

  // Game messages
  String get selectTileFirst => _t('Select a tile first!', '¡Selecciona un azulejo primero!', '!בחר אריח קודם');
  String get tryAnotherSpot => _t('Try another spot!', '¡Prueba otro lugar!', '!נסה מקום אחר');
  String get undone => _t('Undone!', '¡Deshecho!', '!בוטל');
  String get letsBuildTogether => _t("Let's build together!", '¡Construyamos juntos!', '!בואו נבנה ביחד');
  String playerWins(String name) => _t('🎉 $name wins!', '🎉 ¡$name gana!', '!מנצח $name 🎉');
  String get extraTurn => _t('Extra turn!', '¡Turno extra!', '!תור נוסף');
  String playerTurn(String name) => _t("$name's turn!", '¡Turno de $name!', '!של $name תור');
  String get cannotPlaySkipping => _t('cannot play - skipping turn', 'no puede jugar - saltando turno', 'לא יכול לשחק - מדלג');
  String get amazingCarpet => _t('🎉 Amazing! You built a beautiful carpet together!', '🎉 ¡Increíble! ¡Construyeron una hermosa alfombra juntos!', '!בניתם שטיח יפהפה ביחד! מדהים 🎉');
  String get tryMatchingColors => _t('Try matching the colors next time!', '¡Intenta combinar los colores la próxima vez!', '!נסה להתאים את הצבעים בפעם הבאה');
  String perfectMatch(int points) => _t('Perfect match! +$points points', '¡Combinación perfecta! +$points puntos', 'נקודות $points+ !התאמה מושלמת');
  String nicePoints(int points) => _t('Nice! +$points points', '¡Bien! +$points puntos', 'נקודות $points+ !יפה');
  String plusPoints(int points) => _t('+$points points', '+$points puntos', 'נקודות $points+');

  // Achievements
  String get newStar => _t('⭐ New Star!', '⭐ ¡Nueva Estrella!', '!כוכב חדש ⭐');
  String get newStars => _t('⭐ New Stars!', '⭐ ¡Nuevas Estrellas!', '!כוכבים חדשים ⭐');
  String get firstTile => _t('🎉 First Tile!', '🎉 ¡Primer Azulejo!', '!אריח ראשון 🎉');
  String get gettingStarted => _t('🌟 Getting Started!', '🌟 ¡Comenzando!', '!מתחילים 🌟');
  String get tileMaster => _t('🏆 Tile Master!', '🏆 ¡Maestro de Azulejos!', '!אלוף האריחים 🏆');
  String get carpetBuilder => _t('🎨 Carpet Builder!', '🎨 ¡Constructor de Alfombras!', '!בונה שטיחים 🎨');
  String get perfectMatchAchievement => _t('✨ Perfect Match!', '✨ ¡Combinación Perfecta!', '!התאמה מושלמת ✨');
  String get matchExpert => _t('💫 Match Expert!', '💫 ¡Experto en Combinaciones!', '!מומחה התאמות 💫');

  // Rules - Color Dominoes
  String get howToPlay => _t('How to Play:', 'Cómo Jugar:', ':איך לשחק');
  String get rule1Tiles => _t('1. Each player starts with 6 tiles.', '1. Cada jugador comienza con 6 azulejos.', '.כל שחקן מתחיל עם 6 אריחים .1');
  String get rule2Turns => _t('2. Take turns placing tiles on the board.', '2. Túrnense para colocar azulejos en el tablero.', '.שחקו בתורות והניחו אריחים על הלוח .2');
  String get rule3Match => _t('3. Tiles must match colors on touching edges.', '3. Los azulejos deben coincidir en los bordes que se tocan.', '.האריחים חייבים להתאים בצבעים בקצוות הנוגעים .3');
  String get rule4Win => _t('4. First player to place all tiles wins!', '4. ¡El primer jugador en colocar todos sus azulejos gana!', '!השחקן הראשון שמניח את כל האריחים מנצח .4');
  String get specialRules => _t('Special Rules:', 'Reglas Especiales:', ':חוקים מיוחדים');
  String get solidTileExtra => _t('• Solid-colored tiles grant an extra turn.', '• Los azulejos de un solo color dan un turno extra.', '.אריחים בצבע אחיד נותנים תור נוסף •');

  // Rules - Free Play
  String get freePlayMode => _t('Free Play Mode', 'Modo Juego Libre', 'מצב משחק חופשי');
  String get noRulesPlace => _t('• No rules - place tiles anywhere you like!', '• Sin reglas - ¡coloca azulejos donde quieras!', '!בלי חוקים - הנח אריחים איפה שתרצה •');
  String get createPatterns => _t('• Create any pattern you can imagine.', '• Crea cualquier patrón que puedas imaginar.', '.צור כל דפוס שתוכל לדמיין •');
  String get earnPointsMatching => _t('• Earn points for matching colors.', '• Gana puntos por combinar colores.', '.צבור נקודות על התאמת צבעים •');
  String get drawMoreTiles => _t('• Draw more tiles whenever you need them.', '• Saca más azulejos cuando los necesites.', '.משוך עוד אריחים כשתצטרך •');
  String get useUndoExperiment => _t('• Use Undo to experiment freely!', '• ¡Usa Deshacer para experimentar libremente!', '!השתמש בביטול כדי להתנסות בחופשיות •');

  // Rules - Learning Mode
  String get learningModeTitle => _t('Learning Mode', 'Modo Aprendizaje', 'מצב למידה');
  String get placeAnywhere => _t('• Place tiles anywhere next to existing tiles.', '• Coloca azulejos en cualquier lugar junto a los existentes.', '.הנח אריחים בכל מקום ליד אריחים קיימים •');
  String get greenEdgesMatch => _t('• Green edges = colors match!', '• Bordes verdes = ¡los colores coinciden!', '!קצוות ירוקים = הצבעים מתאימים •');
  String get orangeEdgesDont => _t("• Orange edges = colors don't match yet.", '• Bordes naranjas = los colores aún no coinciden.', '.קצוות כתומים = הצבעים עדיין לא מתאימים •');
  String get earnMoreMatching => _t('• Earn more points for matching colors.', '• Gana más puntos por combinar colores.', '.צבור יותר נקודות על התאמת צבעים •');
  String get learnNoPressure => _t('• Learn at your own pace - no pressure!', '• Aprende a tu ritmo - ¡sin presión!', '!למד בקצב שלך - בלי לחץ •');

  // Rules - Cooperative
  String get buildTogetherTitle => _t('Build Together!', '¡Construir Juntos!', '!לבנות ביחד');
  String get workAsTeam => _t('• Work as a team to build a beautiful carpet!', '• ¡Trabajen en equipo para construir una hermosa alfombra!', '!עבדו כצוות לבנות שטיח יפהפה •');
  String get takeTurnsPlacing => _t('• Take turns placing tiles.', '• Túrnense para colocar azulejos.', '.שחקו בתורות בהנחת אריחים •');
  String get tilesMustMatch => _t('• Tiles must match colors on touching edges.', '• Los azulejos deben coincidir en los bordes que se tocan.', '.האריחים חייבים להתאים בצבעים בקצוות הנוגעים •');
  String get goalBuild20 => _t('• Goal: Build a carpet with 20 tiles!', '• Meta: ¡Construir una alfombra con 20 azulejos!', '!אריחים 20 המטרה: לבנות שטיח עם •');
  String get everyoneShares => _t('• Everyone shares the same score.', '• Todos comparten la misma puntuación.', '.כולם חולקים את אותה הניקוד •');

  // Player hand
  String get rotate => _t('Rotate', 'Rotar', 'סובב');
  String get doubleTapRotate => _t('Double-tap tile to rotate', 'Toca dos veces para rotar', 'הקש פעמיים לסיבוב');
  String get tapRotateDragPlace => _t('Tap to rotate, drag to place', 'Toca para rotar, arrastra para colocar', 'הקש לסיבוב, גרור להנחה');
  String tilesCount(int count) => _t('$count tiles', '$count azulejos', 'אריחים $count');

  // Language selector
  String get languageLabel => _t('Language', 'Idioma', 'שפה');
  String get selectLanguage => _t('Select Language', 'Seleccionar Idioma', 'בחר שפה');

  // Starter Puzzle mode
  String get rotations => _t('Rotations', 'Rotaciones', 'סיבובים');
  String get time => _t('Time', 'Tiempo', 'זמן');
  String get puzzleComplete => _t('Puzzle Complete!', '¡Rompecabezas Completo!', '!הפאזל הושלם');
  String get congratulations => _t('Congratulations!', '¡Felicidades!', '!כל הכבוד');
  String get yourTime => _t('Your Time', 'Tu Tiempo', 'הזמן שלך');
  String get totalRotations => _t('Total Rotations', 'Rotaciones Totales', 'סה"כ סיבובים');
  String get tapToRotate => _t('Tap tile to rotate', 'Toca para rotar', 'הקש לסיבוב');
  String get dragToPlace => _t('Drag tiles to the grid', 'Arrastra azulejos a la cuadrícula', 'גרור אריחים לרשת');
  String get matchingColors => _t('Match colors on touching edges!', '¡Combina colores en bordes que se tocan!', '!התאם צבעים בקצוות הנוגעים');
  String get starterPuzzleRules => _t('Starter Puzzle Rules', 'Reglas del Rompecabezas', 'חוקי הפאזל');
  String get rule1Place9 => _t('1. Place all 9 tiles on the 3x3 grid.', '1. Coloca los 9 azulejos en la cuadrícula 3x3.', '.הנח את כל 9 האריחים על הרשת 3x3 .1');
  String get rule2MatchColors => _t('2. Adjacent tiles must have matching colors.', '2. Los azulejos adyacentes deben tener colores coincidentes.', '.אריחים סמוכים חייבים להיות עם צבעים תואמים .2');
  String get rule3Rotate => _t('3. Tap tiles to rotate them before placing.', '3. Toca los azulejos para rotarlos antes de colocar.', '.הקש על אריחים לסיבוב לפני ההנחה .3');
  String get rule4Timer => _t('4. Complete as fast as you can!', '4. ¡Completa lo más rápido que puedas!', '!השלם כמה שיותר מהר .4');

  // Helper method for translations
  String _t(String en, String es, String he) {
    switch (language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.spanish:
        return es;
      case AppLanguage.hebrew:
        return he;
    }
  }
}

/// Localization delegate for AppLocalizations.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppLanguage language;

  const AppLocalizationsDelegate(this.language);

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => old.language != language;
}
