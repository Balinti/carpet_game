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

  /// Starts by itself after this long (the green button starts sooner).
  final Duration autoStart;
  const AssessmentIntro({
    super.key,
    required this.onStart,
    this.autoStart = const Duration(seconds: 12),
  });

  @override
  State<AssessmentIntro> createState() => _AssessmentIntroState();
}

class _AssessmentIntroState extends State<AssessmentIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown =
      AnimationController(vsync: this, duration: widget.autoStart)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _go();
        })
        ..forward();
  bool _started = false;

  void _go() {
    if (_started || !mounted) return;
    _started = true;
    _countdown.stop();
    widget.onStart();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

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
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
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
            child: Flex(
              // Upright phone: text, examples and button stacked.
              direction: portrait ? Axis.vertical : Axis.horizontal,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16, height: 16),
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = ((c.maxWidth - 110) / 2)
                          .clamp(36.0, (c.maxHeight - 60) / 2)
                          .clamp(36.0, 110.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _exampleView(st, size, true),
                          _exampleView(st, size, false),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: portrait
                      ? const EdgeInsets.only(top: 12)
                      : const EdgeInsets.only(left: 12),
                  child: Material(
                    key: const ValueKey('intro_start'),
                    color: st.palette[1],
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _go,
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ring that fills up until the board starts.
                            AnimatedBuilder(
                              animation: _countdown,
                              builder: (_, __) => SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: _countdown.value,
                                  strokeWidth: 5,
                                  color: Colors.white,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.25),
                                ),
                              ),
                            ),
                            const Icon(Icons.play_arrow_rounded,
                                size: 46, color: Colors.white),
                          ],
                        ),
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

  Widget _exampleView(VisualStyle st, double size, bool ex) {
    final color = ex ? Colors.greenAccent : Colors.redAccent;
    Widget tile(CarpetTile t) => CustomPaint(
          size: Size(size, size),
          painter: TilePainter(tile: t),
        );
    return Center(
      child: Row(
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
          const SizedBox(width: 12),
          Icon(ex ? Icons.check_circle : Icons.cancel, color: color, size: 44),
        ],
      ),
    );
  }
}
