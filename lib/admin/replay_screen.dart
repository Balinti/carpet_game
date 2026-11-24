import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';
import '../models/board_position.dart';
import '../models/carpet_tile.dart';
import '../widgets/tile_painter.dart';
import '../widgets/visual_style.dart';
import 'replay_logic.dart';

/// Plays back one round from its move log like a video: play/pause,
/// speed 1×/4×/16×, a time scrubber, step by event, and a caption.
///
/// Takes the raw log (`RoundMetrics.deal`, `RoundMetrics.moves`) plus the
/// board shape, so it does not depend on RoundMetrics fields directly.
class RoundReplayScreen extends StatefulWidget {
  final List<String> deal;
  final List<Map<String, dynamic>> moves;
  final int gridSize;
  final int boards;
  final String? title;

  const RoundReplayScreen({
    super.key,
    required this.deal,
    required this.moves,
    required this.gridSize,
    this.boards = 1,
    this.title,
  });

  @override
  State<RoundReplayScreen> createState() => _RoundReplayScreenState();
}

class _RoundReplayScreenState extends State<RoundReplayScreen>
    with SingleTickerProviderStateMixin {
  late List<ReplayState> _states;
  late int _totalMs;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// Playback position in ms and number of events applied.
  double _ms = 0;
  int _k = 0;
  bool _playing = false;
  int _speed = 1;

  @override
  void initState() {
    super.initState();
    _prepare();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant RoundReplayScreen old) {
    super.didUpdateWidget(old);
    if (old.deal != widget.deal || old.moves != widget.moves) {
      _prepare();
      _ms = 0;
      _k = 0;
    }
  }

  void _prepare() {
    _states = replayAllStates(widget.deal, widget.moves);
    final last = widget.moves.isEmpty ? 0 : eventTime(widget.moves.last);
    _totalMs = math.max(last, 1);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1000.0;
    _lastTick = elapsed;
    setState(() {
      _ms = math.min(_ms + dt * _speed, _totalMs.toDouble());
      _k = eventsUpTo(widget.moves, _ms.floor());
      if (_ms >= _totalMs) _stop();
    });
  }

  void _stop() {
    _playing = false;
    if (_ticker.isActive) _ticker.stop();
  }

  void _togglePlay() {
    setState(() {
      if (_playing) {
        _stop();
        return;
      }
      if (_ms >= _totalMs) {
        _ms = 0;
        _k = eventsUpTo(widget.moves, 0);
      }
      _playing = true;
      _lastTick = Duration.zero;
      _ticker.start();
    });
  }

  void _seek(double ms) {
    setState(() {
      _ms = ms.clamp(0, _totalMs.toDouble());
      _k = eventsUpTo(widget.moves, _ms.floor());
    });
  }

  void _step(int dir) {
    setState(() {
      _stop();
      _k = (_k + dir).clamp(0, widget.moves.length);
      _ms = _k == 0 ? 0 : eventTime(widget.moves[_k - 1]).toDouble();
    });
  }

  static VisualStyle _style() =>
      VisualStyle.current.isClassic ? VisualStyle.soft3d : VisualStyle.current;

  @override
  Widget build(BuildContext context) {
    final st = _style();
    final he = AppLocalizations.of(context).language == AppLanguage.hebrew;
    String t(String h, String e) => he ? h : e;

    final state = _states[_k];
    final current = _k > 0 ? widget.moves[_k - 1] : null;
    final touched = current == null
        ? const <String>{}
        : touchedIds(current, _states[_k - 1]);
    final caption = current == null
        ? t('תחילת הסיבוב', 'Start of the round')
        : replayCaption(current,
            hebrew: he, gridSize: widget.gridSize, boards: widget.boards);

    final onTray = st.onTray;
    final header = Row(children: [
      IconButton(
        icon: Icon(Icons.arrow_back, color: onTray),
        onPressed: () => Navigator.maybePop(context),
      ),
      Expanded(
        child: Text(
          widget.title ?? t('הקלטת סיבוב', 'Round replay'),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: onTray, fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      Text(
        '${formatReplayTime(_ms.floor())} / ${formatReplayTime(_totalMs)}',
        key: const ValueKey('replay_time'),
        style: TextStyle(
          color: onTray,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(width: 8),
    ]);

    final captionBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: st.trayCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${widget.moves.isEmpty ? '' : '$_k/${widget.moves.length}  '}$caption',
        key: const ValueKey('replay_caption'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: onTray, fontSize: 14),
      ),
    );

    final board = _ReplayBoard(
      state: state,
      gridSize: widget.gridSize,
      boards: widget.boards,
      touched: touched,
      style: st,
    );
    final tray = _ReplayTray(tray: state.tray, touched: touched, style: st);

    final controls = _controls(st, t);

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
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth > box.maxHeight;
              final stage = wide
                  ? Row(children: [
                      Expanded(flex: 3, child: board),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: tray),
                    ])
                  : Column(children: [
                      Expanded(flex: 3, child: board),
                      const SizedBox(height: 8),
                      Expanded(flex: 2, child: tray),
                    ]);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(child: stage),
                  const SizedBox(height: 6),
                  captionBox,
                  controls,
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _controls(VisualStyle st, String Function(String, String) t) {
    final c = st.onTray;
    Widget btn(String key, IconData icon, String tip, VoidCallback? on) =>
        IconButton(
          key: ValueKey(key),
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, color: on == null ? c.withValues(alpha: 0.3) : c),
          onPressed: on,
        );
    final buttons = [
      btn('replay_prev', Icons.skip_previous, t('צעד אחורה', 'Previous step'),
          _k > 0 ? () => _step(-1) : null),
      btn(
          'replay_play',
          _playing ? Icons.pause : Icons.play_arrow,
          _playing ? t('השהה', 'Pause') : t('נגן', 'Play'),
          widget.moves.isEmpty ? null : _togglePlay),
      btn('replay_next', Icons.skip_next, t('צעד קדימה', 'Next step'),
          _k < widget.moves.length ? () => _step(1) : null),
    ];
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: st.boardFrame,
        thumbColor: st.boardFrame,
        inactiveTrackColor: c.withValues(alpha: 0.2),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(
        key: const ValueKey('replay_slider'),
        value: _ms.clamp(0, _totalMs.toDouble()),
        max: _totalMs.toDouble(),
        onChanged: (v) {
          _stop();
          _seek(v);
        },
      ),
    );
    final speeds = [
      for (final s in const [1, 4, 16])
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: ChoiceChip(
            key: ValueKey('replay_speed_$s'),
            label: Text('$s×'),
            selected: _speed == s,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              color: _speed == s ? Colors.white : c,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: st.boardFrame,
            backgroundColor: st.trayCard,
            side: BorderSide(color: st.boardFrame.withValues(alpha: 0.5)),
            onSelected: (_) => setState(() => _speed = s),
          ),
        ),
    ];
    // Narrow (upright phone): slider on its own row so it stays usable.
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 600) {
        return Row(children: [...buttons, Expanded(child: slider), ...speeds]);
      }
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: slider,
        ),
        Row(children: [...buttons, const Spacer(), ...speeds]),
      ]);
    });
  }
}

/// The board grids side by side with an empty gap column between them.
class _ReplayBoard extends StatelessWidget {
  final ReplayState state;
  final int gridSize;
  final int boards;
  final Set<String> touched;
  final VisualStyle style;

  const _ReplayBoard({
    required this.state,
    required this.gridSize,
    required this.boards,
    required this.touched,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final n = math.max(gridSize, 1);
    final b = math.max(boards, 1);
    final cols = b * (n + 1) - 1;
    return LayoutBuilder(builder: (context, box) {
      const gap = 3.0;
      final cell = math.min(
        (box.maxWidth - gap * (cols - 1)) / cols,
        (box.maxHeight - gap * (n - 1)) / n,
      );
      if (cell <= 0) return const SizedBox.shrink();
      return Center(
        child: SizedBox(
          width: cell * cols + gap * (cols - 1),
          height: cell * n + gap * (n - 1),
          child: Stack(children: [
            for (var r = 0; r < n; r++)
              for (var c = 0; c < cols; c++)
                if (c % (n + 1) != n)
                  Positioned(
                    left: c * (cell + gap),
                    top: r * (cell + gap),
                    width: cell,
                    height: cell,
                    child: _cell(BoardPosition(r, c)),
                  ),
          ]),
        ),
      );
    });
  }

  Widget _cell(BoardPosition p) {
    final tile = state.board[p];
    if (tile == null) {
      return Container(
        decoration: BoxDecoration(
          color: style.emptySlot,
          border: Border.all(color: style.emptySlotBorder),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return _Piece(tile: tile, selected: touched.contains(tile.id));
  }
}

/// The Builder tray: pieces in tray order, sized to fit the area.
class _ReplayTray extends StatelessWidget {
  final List<CarpetTile> tray;
  final Set<String> touched;
  final VisualStyle style;

  const _ReplayTray({
    required this.tray,
    required this.touched,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: style.trayCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, box) {
        if (tray.isEmpty) return const SizedBox.shrink();
        const gap = 6.0;
        // Largest piece size that fits every piece in the area.
        var s = math.min(72.0, math.min(box.maxWidth, box.maxHeight));
        while (s > 12) {
          final perRow = ((box.maxWidth + gap) / (s + gap)).floor();
          if (perRow > 0) {
            final rows = (tray.length / perRow).ceil();
            if (rows * (s + gap) - gap <= box.maxHeight) break;
          }
          s -= 2;
        }
        return Center(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            alignment: WrapAlignment.center,
            children: [
              for (final t in tray)
                SizedBox(
                  width: s,
                  height: s,
                  child: _Piece(tile: t, selected: touched.contains(t.id)),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Piece extends StatelessWidget {
  final CarpetTile tile;
  final bool selected;
  const _Piece({required this.tile, required this.selected});

  @override
  Widget build(BuildContext context) => CustomPaint(
        key: ValueKey('replay_piece_${tile.id}'),
        painter: TilePainter(tile: tile, isSelected: selected),
      );
}
