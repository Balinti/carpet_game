import '../models/board_position.dart';
import '../models/carpet_tile.dart';
import '../models/tile_color.dart';

/// Pure logic for replaying one round from its move log
/// (`RoundMetrics.deal` + `RoundMetrics.moves`). No Flutter widgets here so
/// it can be unit tested.

/// Board and Builder tray at one moment of the replay.
class ReplayState {
  final Map<BoardPosition, CarpetTile> board;
  final List<CarpetTile> tray;

  const ReplayState(this.board, this.tray);

  ReplayState copy() => ReplayState(Map.of(board), List.of(tray));

  /// Where piece [id] is on the board, or null.
  BoardPosition? positionOf(String id) {
    for (final e in board.entries) {
      if (e.value.id == id) return e.key;
    }
    return null;
  }
}

const _letters = {
  'r': TileColor.red,
  'g': TileColor.green,
  'b': TileColor.blue,
  'y': TileColor.yellow,
};

/// "rgby" -> colors top, right, bottom, left. Null if malformed.
List<TileColor>? parseOrientation(Object? o) {
  if (o is! String || o.length != 4) return null;
  final out = <TileColor>[];
  for (final ch in o.toLowerCase().split('')) {
    final c = _letters[ch];
    if (c == null) return null;
    out.add(c);
  }
  return out;
}

CarpetTile _tile(String id, List<TileColor> c) =>
    CarpetTile(id: id, top: c[0], right: c[1], bottom: c[2], left: c[3]);

/// "tile_3:rgby" -> CarpetTile. Null if malformed.
CarpetTile? parseDealPiece(String s) {
  final i = s.lastIndexOf(':');
  if (i <= 0) return null;
  final c = parseOrientation(s.substring(i + 1));
  if (c == null) return null;
  return _tile(s.substring(0, i), c);
}

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

/// Event time in ms (0 if missing).
int eventTime(Map<String, dynamic> e) => _int(e['t']) ?? 0;

/// Event kind ('' if missing).
String eventKind(Map<String, dynamic> e) => '${e['k'] ?? ''}';

BoardPosition? _pos(Map<String, dynamic> e, String r, String c) {
  final row = _int(e[r]), col = _int(e[c]);
  if (row == null || col == null) return null;
  return BoardPosition(row, col);
}

List<String> _ids(Object? v) =>
    v is List ? v.map((x) => '$x').toList() : const [];

/// Starting state: empty board, the dealt pieces in tray order.
ReplayState initialReplayState(List<String> deal) => ReplayState(
      {},
      [for (final s in deal) parseDealPiece(s)]
          .whereType<CarpetTile>()
          .toList(),
    );

/// Applies one event to [s] in place. Unknown or malformed events are
/// ignored so a partial log still replays.
void applyReplayEvent(ReplayState s, Map<String, dynamic> e) {
  final id = e['id'] == null ? null : '${e['id']}';
  final o = parseOrientation(e['o']);
  void toTray(CarpetTile? t) {
    if (t == null) return;
    s.tray.removeWhere((x) => x.id == t.id);
    s.tray.add(t);
  }

  switch (eventKind(e)) {
    case 'place':
      final p = _pos(e, 'r', 'c');
      if (id == null || p == null) return;
      final i = s.tray.indexWhere((t) => t.id == id);
      CarpetTile? piece = i >= 0 ? s.tray.removeAt(i) : null;
      // A piece already on the board can't be "placed" again; move it.
      final from = s.positionOf(id);
      if (piece == null && from != null) piece = s.board.remove(from);
      if (piece == null && o == null) return;
      piece = o != null ? _tile(id, o) : piece!;
      final old = s.board[p];
      s.board[p] = piece;
      if (old != null && old.id != id) toTray(old);
    case 'rot':
      if (id == null || o == null) return;
      final p = _pos(e, 'r', 'c');
      if (p != null && s.board[p]?.id == id) {
        s.board[p] = _tile(id, o);
        return;
      }
      final i = s.tray.indexWhere((t) => t.id == id);
      if (i >= 0) {
        s.tray[i] = _tile(id, o);
        return;
      }
      final at = s.positionOf(id);
      if (at != null) s.board[at] = _tile(id, o);
    case 'move':
      final a = _pos(e, 'r', 'c'), b = _pos(e, 'r2', 'c2');
      if (a == null || b == null || a == b) return;
      final pa = s.board.remove(a);
      if (pa == null) return;
      final pb = s.board.remove(b);
      s.board[b] = pa;
      if (pb != null) s.board[a] = pb;
    case 'back':
      final p = _pos(e, 'r', 'c');
      var at = p;
      if (at == null || (id != null && s.board[at]?.id != id)) {
        at = id != null ? s.positionOf(id) : at;
      }
      if (at == null) return;
      toTray(s.board.remove(at));
    case 'throw':
      for (final tid in _ids(e['ids'])) {
        final at = s.positionOf(tid);
        if (at != null) toTray(s.board.remove(at));
      }
    default:
      // check, giveup, solved: no change to pieces.
      break;
  }
}

/// State after the first [k] events (k clamped to 0..moves.length).
ReplayState replayStateAfter(
    List<String> deal, List<Map<String, dynamic>> moves, int k) {
  final s = initialReplayState(deal);
  final n = k.clamp(0, moves.length);
  for (var i = 0; i < n; i++) {
    applyReplayEvent(s, moves[i]);
  }
  return s;
}

/// All states: [0] = start, [i] = after event i-1. Length moves.length + 1.
List<ReplayState> replayAllStates(
    List<String> deal, List<Map<String, dynamic>> moves) {
  final s = initialReplayState(deal);
  final out = [s.copy()];
  for (final e in moves) {
    applyReplayEvent(s, e);
    out.add(s.copy());
  }
  return out;
}

/// Ids of the pieces event [e] touched (to highlight them).
/// [before] is the state just before the event.
Set<String> touchedIds(Map<String, dynamic> e, ReplayState before) {
  final id = e['id'] == null ? null : '${e['id']}';
  switch (eventKind(e)) {
    case 'place':
    case 'rot':
    case 'back':
      return {if (id != null) id};
    case 'move':
      final a = _pos(e, 'r', 'c');
      final t = a == null ? null : before.board[a];
      return {if (t != null) t.id};
    case 'throw':
      return _ids(e['ids']).toSet();
    default:
      return const {};
  }
}

/// Number of events whose time is <= [ms] (events assumed in time order).
int eventsUpTo(List<Map<String, dynamic>> moves, int ms) {
  var k = 0;
  while (k < moves.length && eventTime(moves[k]) <= ms) {
    k++;
  }
  return k;
}

/// ms -> "m:ss".
String formatReplayTime(int ms) {
  final s = (ms < 0 ? 0 : ms) ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Short description of event [e]. Board positions are shown 1-based, with
/// the board number when there are several boards.
String replayCaption(
  Map<String, dynamic> e, {
  required bool hebrew,
  required int gridSize,
  required int boards,
}) {
  String t(String h, String en) => hebrew ? h : en;
  String where(String r, String c) {
    final p = _pos(e, r, c);
    if (p == null) return '';
    final span = gridSize + 1;
    final b = p.col ~/ span, col = p.col % span;
    final cell = t('שורה ${p.row + 1}, עמודה ${col + 1}',
        'row ${p.row + 1}, col ${col + 1}');
    return boards > 1
        ? t('לוח ${b + 1} · $cell', 'board ${b + 1} · $cell')
        : cell;
  }

  switch (eventKind(e)) {
    case 'place':
      final base = t('הונח חלק ב${where('r', 'c')}',
          'Placed a piece at ${where('r', 'c')}');
      return e['out'] != null
          ? t('$base (החלק הקודם חזר לבונה)',
              '$base (old piece back to Builder)')
          : base;
    case 'rot':
      return _pos(e, 'r', 'c') != null
          ? t('סובב חלק על הלוח (${where('r', 'c')})',
              'Rotated a piece on the board (${where('r', 'c')})')
          : t('סובב חלק בבונה', 'Rotated a piece in the Builder');
    case 'move':
      return t('הזיז חלק מ${where('r', 'c')} אל ${where('r2', 'c2')}',
          'Moved a piece from ${where('r', 'c')} to ${where('r2', 'c2')}');
    case 'back':
      return t('החזיר חלק לבונה מ${where('r', 'c')}',
          'Returned a piece to the Builder from ${where('r', 'c')}');
    case 'check':
      return e['ok'] == true
          ? t('לחץ "סיימתי" – נכון!', 'Pressed "I finished" – correct!')
          : t('לחץ "סיימתי" – עדיין לא נכון',
              'Pressed "I finished" – not right yet');
    case 'throw':
      final n = _ids(e['ids']).length;
      return t('$n חלקים שגויים חזרו לבונה',
          '$n wrong piece${n == 1 ? '' : 's'} sent back to the Builder');
    case 'giveup':
      return t('לחץ "נתקעתי"', 'Pressed "I\'m stuck"');
    case 'solved':
      return t('נפתר!', 'Solved!');
    default:
      return eventKind(e);
  }
}
