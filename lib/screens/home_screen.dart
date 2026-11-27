import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'assessment_intro.dart';
import '../game/practice_save.dart';
import '../l10n/l10n.dart';
import '../main.dart';
import '../models/carpet_tile.dart';
import '../models/game_mode.dart';
import '../models/tile_color.dart';
import '../onboarding/account_deletion.dart';
import '../onboarding/onboarding_strings.dart';
import '../onboarding/welcome/tile_art.dart';
import 'account_sheet.dart';
import 'assessment_screen.dart';
import 'game_screen.dart';

/// Home screen: animated aurora background, glass cards, a glowing
/// assessment button, colorful practice tiles and the two game paths.
class HomeScreen extends StatefulWidget {
  /// Shown as a small logout icon when set.
  final VoidCallback? onSignOut;

  /// Shown as a small chart icon (admins only).
  final VoidCallback? onOpenDashboard;

  /// Shown as a small account icon (privacy policy, delete account) when set.
  final AccountDeletionService? accountDeletion;

  /// Called after the account was deleted (go back to the start).
  final VoidCallback? onAccountDeleted;

  /// Tests turn the endless background animation off so pumpAndSettle ends.
  static bool debugAnimate = true;

  const HomeScreen({
    super.key,
    this.onSignOut,
    this.onOpenDashboard,
    this.accountDeletion,
    this.onAccountDeleted,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Home-screen texts (he / en / es).
class _S {
  final AppLanguage lang;
  const _S(this.lang);
  String _t(String en, String es, String he) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.spanish => es,
        AppLanguage.hebrew => he,
      };
  String get tagline => _t('Train your brain, one tile at a time',
      'Entrena tu mente, pieza a pieza', 'מאמנים את המוח, אריח אחרי אריח');
  String get assessment => _t('Assessment', 'Evaluación', 'הערכה');
  String get assessmentSub => _t('3 boards · time and rotations measured',
      '3 tableros · se mide tiempo y giros', '3 לוחות · מודדים זמן וסיבובים');
  String get start => _t('Start', 'Empezar', 'התחלה');
  String get practice => _t('Free practice', 'Práctica libre', 'תרגול חופשי');
  String get practiceSub =>
      _t('Pick a board size', 'Elige un tamaño', 'בוחרים גודל לוח');
  String get resume => _t('Continue', 'Seguir', 'המשך');
  String get paths => _t('Game paths', 'Modos de juego', 'מסלולי משחק');
  String get levels => _t('Level path', 'Ruta de niveles', 'מסלול שלבים');
  String get levelsSub => _t('12 levels, from 2×2 up to 6×6',
      '12 niveles, de 2×2 a 6×6', '12 שלבים, מ-2×2 ועד 6×6');
  String get shapes => _t('Shape path', 'Ruta de formas', 'מסלול צורות');
  String get shapesSub => _t(
      'Build 7 shapes while filling the board',
      'Forma 7 figuras mientras llenas el tablero',
      'בונים 7 צורות תוך כדי מילוי הלוח');
}

/// Bright gradient for each practice size.
const _sizeColors = <int, List<Color>>{
  2: [Color(0xFFFF6B6B), Color(0xFFFFA94D)],
  3: [Color(0xFFFFC93C), Color(0xFF3DDC97)],
  4: [Color(0xFF2EC5FF), Color(0xFF4D7CFF)],
  5: [Color(0xFF9B5CFF), Color(0xFFFF5CC8)],
  6: [Color(0xFFFF4D8D), Color(0xFF7B2FF7)],
};

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  /// Practice sizes with a saved, unfinished board.
  Set<int> _saved = {};

  @override
  void initState() {
    super.initState();
    if (HomeScreen.debugAnimate) _clock.repeat();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final out = <int>{};
    for (var n = 2; n <= 6; n++) {
      if (await PracticeSave.load(n) != null) out.add(n);
    }
    if (mounted) setState(() => _saved = out);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _push(Widget Function(BuildContext) b) async {
    await Navigator.push(context, MaterialPageRoute(builder: b));
    _loadSaved();
  }

  /// A saved unfinished board continues straight away; otherwise the
  /// instructions first, then the board.
  Future<void> _practice(int n) async {
    final saved = await PracticeSave.load(n);
    if (!mounted) return;
    if (saved != null) {
      return _push((_) => GameScreen(
            mode: GameMode.regularFlow,
            practiceGridSize: n,
            resumeFrom: saved,
          ));
    }
    return _push((ctx) => AssessmentIntro(
          onStart: () => Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(
              builder: (_) => GameScreen(
                mode: GameMode.regularFlow,
                practiceGridSize: n,
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = _S(l10n.language);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B24),
      body: Stack(
        children: [
          Positioned.fill(child: _AuroraBackground(clock: _clock)),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Hero(
                                clock: _clock,
                                title: l10n.appTitle,
                                tagline: s.tagline),
                            const SizedBox(height: 26),
                            _AssessmentCta(
                              clock: _clock,
                              title: s.assessment,
                              subtitle: s.assessmentSub,
                              start: s.start,
                              onTap: () =>
                                  _push((_) => const AssessmentScreen()),
                            ),
                            const SizedBox(height: 30),
                            _SectionTitle(s.practice, s.practiceSub),
                            const SizedBox(height: 12),
                            _practiceGrid(s),
                            const SizedBox(height: 30),
                            _SectionTitle(s.paths, null),
                            const SizedBox(height: 12),
                            _PathCard(
                              title: s.levels,
                              subtitle: s.levelsSub,
                              icon: Icons.trending_up_rounded,
                              colors: const [
                                Color(0xFF2EC5FF),
                                Color(0xFF4D7CFF)
                              ],
                              onTap: () => _push((_) =>
                                  const GameScreen(mode: GameMode.regularFlow)),
                            ),
                            const SizedBox(height: 12),
                            _PathCard(
                              title: s.shapes,
                              subtitle: s.shapesSub,
                              icon: Icons.category_rounded,
                              colors: const [
                                Color(0xFF3DDC97),
                                Color(0xFF00B3A4)
                              ],
                              onTap: () => _push((_) =>
                                  const GameScreen(mode: GameMode.shapeFlow)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          if (widget.onSignOut != null)
            _GlassIcon(icon: Icons.logout_rounded, onTap: widget.onSignOut!),
          if (widget.onOpenDashboard != null)
            _GlassIcon(
                icon: Icons.insights_rounded, onTap: widget.onOpenDashboard!),
          if (widget.accountDeletion != null)
            _GlassIcon(
              key: const ValueKey('account_button'),
              icon: Icons.manage_accounts_rounded,
              tooltip: OnboardingStrings.of(context).account,
              onTap: () => showAccountSheet(
                context,
                deletion: widget.accountDeletion!,
                onDeleted: widget.onAccountDeleted ?? () {},
              ),
            ),
          const Spacer(),
          const _LanguageButton(),
        ],
      ),
    );
  }

  Widget _practiceGrid(_S s) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 10.0;
      // 5 in a row when there is room, else 3 + 2.
      final perRow = c.maxWidth >= 420 ? 5 : 3;
      final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var n = 2; n <= 6; n++)
            SizedBox(
              width: w,
              height: math.min(w * 1.1, 130),
              child: _SizeTile(
                key: ValueKey('practice_$n'),
                n: n,
                colors: _sizeColors[n]!,
                saved: _saved.contains(n),
                resumeLabel: s.resume,
                onTap: () => _practice(n),
              ),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Background

/// Deep night gradient, slowly drifting colored light blobs and a few game
/// pieces floating upward.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.clock});
  final Animation<double> clock;

  static final _floaters = () {
    final rnd = math.Random(11);
    const cs = TileColor.values;
    TileColor c() => cs[rnd.nextInt(cs.length)];
    return [
      for (var i = 0; i < 9; i++)
        (
          tile: CarpetTile(
              id: 'f$i', top: c(), right: c(), bottom: c(), left: c()),
          x: rnd.nextDouble(),
          phase: rnd.nextDouble(),
          size: 26.0 + rnd.nextDouble() * 34,
          spin: (rnd.nextBool() ? 1 : -1) * (0.5 + rnd.nextDouble()),
        )
    ];
  }();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t = clock.value;
          return LayoutBuilder(builder: (context, box) {
            final h = box.maxHeight, w = box.maxWidth;
            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _AuroraPainter(t))),
              for (final f in _floaters)
                Positioned(
                  left: f.x * (w - f.size),
                  top: (1 - ((t + f.phase) % 1)) * (h + f.size * 2) - f.size,
                  child: Opacity(
                    opacity: 0.13,
                    child: Transform.rotate(
                      angle: (t + f.phase) * f.spin * math.pi * 2,
                      child: TileArt(f.tile, size: f.size),
                    ),
                  ),
                ),
            ]);
          });
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);
  final double t;

  static const _blobs = [
    (Color(0xFFFF4D8D), 0.15, 0.10, 0.0),
    (Color(0xFF7B2FF7), 0.85, 0.22, 0.25),
    (Color(0xFF2EC5FF), 0.20, 0.62, 0.5),
    (Color(0xFFFFC93C), 0.80, 0.85, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120E3A), Color(0xFF0B0B24), Color(0xFF16082E)],
        ).createShader(rect),
    );
    final r = math.max(size.width, size.height) * 0.55;
    for (final (color, bx, by, ph) in _blobs) {
      final a = (t + ph) * math.pi * 2;
      final c = Offset(
        size.width * (bx + 0.12 * math.sin(a)),
        size.height * (by + 0.08 * math.cos(a * 2)),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withOpacity(0.42),
            color.withOpacity(0.0),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Hero

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.clock, required this.title, required this.tagline});
  final Animation<double> clock;
  final String title;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = clock.value;
        final bob = math.sin(t * math.pi * 2 * 4) * 6;
        return Column(
          children: [
            const SizedBox(height: 6),
            Transform.translate(
              offset: Offset(0, bob),
              child: Transform.rotate(
                angle: math.sin(t * math.pi * 2 * 2) * 0.06,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(
                                const Color(0xFFFF4D8D),
                                const Color(0xFF2EC5FF),
                                0.5 + 0.5 * math.sin(t * math.pi * 2))!
                            .withOpacity(0.45),
                        blurRadius: 50,
                      ),
                    ],
                  ),
                  child: const TileMosaic(
                      rows: 2, cols: 2, tileSize: 42, gap: 5, seed: 3),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => LinearGradient(
                colors: const [
                  Color(0xFFFFC93C),
                  Color(0xFFFF5CC8),
                  Color(0xFF7DF9FF),
                  Color(0xFFFFC93C),
                ],
                transform: GradientRotation(t * math.pi * 2),
              ).createShader(r),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.78),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Assessment button

/// Big glowing card with a rotating rainbow border and a shine that sweeps
/// across it.
class _AssessmentCta extends StatelessWidget {
  const _AssessmentCta({
    required this.clock,
    required this.title,
    required this.subtitle,
    required this.start,
    required this.onTap,
  });
  final Animation<double> clock;
  final String title;
  final String subtitle;
  final String start;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    return _Pressable(
      key: const ValueKey('assessment_button'),
      onTap: onTap,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, child) {
          final t = clock.value;
          final glow = 0.5 + 0.5 * math.sin(t * math.pi * 2 * 6);
          return Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFF4D8D),
                  Color(0xFFFFC93C),
                  Color(0xFF3DDC97),
                  Color(0xFF2EC5FF),
                  Color(0xFF9B5CFF),
                  Color(0xFFFF4D8D),
                ],
                transform: GradientRotation(t * math.pi * 2 * 3),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFFFF4D8D).withOpacity(0.30 + 0.25 * glow),
                  blurRadius: 26 + 14 * glow,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF7B2FF7).withOpacity(0.35),
                  blurRadius: 40,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 2.5),
              child: Stack(children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7B2FF7), Color(0xFFE0379A)],
                      ),
                    ),
                  ),
                ),
                // Shine sweep (once per cycle of 4).
                Positioned.fill(
                  child: LayoutBuilder(builder: (context, box) {
                    final p = (t * 4) % 1;
                    return Transform.translate(
                      offset: Offset((p * 3 - 1) * box.maxWidth, 0),
                      child: Transform(
                        transform: Matrix4.skewX(-0.4),
                        child: Container(
                          width: box.maxWidth * 0.35,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.28),
                              Colors.white.withOpacity(0),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                child!,
              ]),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  start,
                  style: const TextStyle(
                    color: Color(0xFF7B2FF7),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Practice tiles and path cards

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 5,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFC93C), Color(0xFFFF4D8D)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One practice size: gradient tile with a mini n×n grid.
class _SizeTile extends StatelessWidget {
  const _SizeTile({
    super.key,
    required this.n,
    required this.colors,
    required this.saved,
    required this.resumeLabel,
    required this.onTap,
  });
  final int n;
  final List<Color> colors;
  final bool saved;
  final String resumeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(children: [
          // Glossy top highlight.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.30),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _MiniGrid(n: n)),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: Text(
                      '$n×$n',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0x55000000), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (saved)
            PositionedDirectional(
              top: 6,
              end: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  resumeLabel,
                  style: TextStyle(
                    color: colors.last,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, box) {
        const gap = 2.0;
        final cell = (box.maxWidth - gap * (n - 1)) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < n * n; i++)
              Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(cell * 0.25),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Frosted-glass card for a game path.
class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return _Pressable(
      onTap: onTap,
      child: _Glass(
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                rtl
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 20});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shrinks a little while pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon(
      {super.key, required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white.withOpacity(0.10),
        shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.18))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProviderScope.of(context);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<AppLanguage>(
      tooltip: l10n.selectLanguage,
      onSelected: localeProvider.setLanguage,
      itemBuilder: (context) => AppLanguage.values.map((language) {
        final isSelected = language == localeProvider.language;
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(
                language.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              localeProvider.language.displayName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
