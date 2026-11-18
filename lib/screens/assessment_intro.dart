import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/tile_painter.dart';
import '../widgets/visual_style.dart';

/// Instructions before the assessment (text by Shemer Arazi): fill the board
/// by dragging pieces, touching edges must be the same color. Two buttons
/// show a correct and a wrong example; the green button starts.
class AssessmentIntro extends StatefulWidget {
  final VoidCallback onStart;
  const AssessmentIntro({super.key, required this.onStart});

  @override
  State<AssessmentIntro> createState() => _AssessmentIntroState();
}

class _AssessmentIntroState extends State<AssessmentIntro> {
  /// null = no example yet, true = correct, false = wrong.
  bool? _example;

  static const _he = 'לפנייך משטח. עלייך לגרור את החלקים ולמלא אותו.\n'
      'עלייך לשמור על חוק הצבעים: מחברים צבע לצבע.';
  static const _en = 'In front of you is a board. Drag the pieces to fill it.\n'
      'Keep the color rule: join color to color.';

  // Left piece: right edge blue. Right piece: left edge blue (correct)
  // or yellow (wrong).
  static const _a = CarpetTile(
    id: 'ex_a',
    top: TileColor.red,
    right: TileColor.blue,
    bottom: TileColor.yellow,
    left: TileColor.green,
  );
  static const _bGood = CarpetTile(
    id: 'ex_b',
    top: TileColor.green,
    right: TileColor.red,
    bottom: TileColor.yellow,
    left: TileColor.blue,
  );
  static const _bBad = CarpetTile(
    id: 'ex_b',
    top: TileColor.green,
    right: TileColor.red,
    bottom: TileColor.blue,
    left: TileColor.yellow,
  );

  @override
  Widget build(BuildContext context) {
    final st = VisualStyle.current.isClassic
        ? VisualStyle.soft3d
        : VisualStyle.current;
    final he = AppLocalizations.of(context).language == AppLanguage.hebrew;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: st.boardBackground,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Directionality(
                    textDirection: he ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          he ? _he : _en,
                          key: const ValueKey('intro_text'),
                          style: TextStyle(
                            color: st.onTray,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _exampleButton(
                              key: const ValueKey('intro_good'),
                              icon: Icons.check_circle,
                              color: Colors.greenAccent.shade700,
                              label: he ? 'דוגמה נכונה' : 'Correct example',
                              selected: _example == true,
                              onTap: () => setState(() => _example = true),
                            ),
                            _exampleButton(
                              key: const ValueKey('intro_bad'),
                              icon: Icons.cancel,
                              color: Colors.redAccent,
                              label: he ? 'דוגמה שגויה' : 'Wrong example',
                              selected: _example == false,
                              onTap: () => setState(() => _example = false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, c) => _exampleView(
                      st,
                      ((c.maxWidth - 40) / 2)
                          .clamp(48.0, c.maxHeight * 0.55)
                          .clamp(48.0, 130.0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Material(
                    key: const ValueKey('intro_start'),
                    color: st.palette[1],
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onStart,
                      child: const SizedBox(
                        width: 76,
                        height: 76,
                        child: Icon(Icons.play_arrow_rounded,
                            size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exampleButton({
    required Key key,
    required IconData icon,
    required Color color,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Material(
        key: key,
        color:
            selected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: selected ? 3 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _exampleView(VisualStyle st, double size) {
    final ex = _example;
    if (ex == null) {
      return Center(
        child: Icon(Icons.touch_app_rounded,
            size: 64, color: st.onTray.withOpacity(0.35)),
      );
    }
    final color = ex ? Colors.greenAccent : Colors.redAccent;
    Widget tile(CarpetTile t) => CustomPaint(
          size: Size(size, size),
          painter: TilePainter(tile: t),
        );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: ValueKey(ex ? 'intro_example_good' : 'intro_example_bad'),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color, width: 4),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 18),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile(_a),
                const SizedBox(width: 4),
                tile(ex ? _bGood : _bBad),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Icon(ex ? Icons.check_circle : Icons.cancel, color: color, size: 44),
        ],
      ),
    );
  }
}
