import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assessment/assessment.dart';
import '../widgets/visual_style.dart';

/// Results dashboard for the research team (Shemer / Edoe).
/// Readable only by users listed in Firestore `admins/{uid}`.
class DashboardScreen extends StatefulWidget {
  final FirebaseFirestore? db;
  const DashboardScreen({super.key, this.db});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _Row {
  final String uid;
  final String name;
  final int? age;
  final String group;
  final AssessmentResult result;
  _Row(this.uid, this.name, this.age, this.group, this.result);
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final FirebaseFirestore _db = widget.db ?? FirebaseFirestore.instance;
  bool _loading = true;
  String? _error;
  int _users = 0, _kids = 0, _adults = 0, _questionnaires = 0;
  final List<_Row> _rows = [];
  final Map<String, int> _events7d = {};
  final Map<String, int> _eventsAll = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _db.collection('users').get();
      final profiles = <String, Map<String, dynamic>>{
        for (final d in users.docs) d.id: d.data(),
      };
      final assessments = await _db.collectionGroup('assessments').get();
      final events = await _db.collectionGroup('events').get();
      final questionnaires = await _db.collectionGroup('questionnaires').get();

      _rows.clear();
      for (final d in assessments.docs) {
        final uid = d.reference.parent.parent?.id ?? '';
        final p = profiles[uid] ?? const {};
        final age = (p['age'] as num?)?.toInt();
        _rows.add(_Row(
          uid,
          (p['name'] as String?) ?? '—',
          age,
          age == null ? '?' : (age < 13 ? 'kid' : 'adult'),
          AssessmentResult.fromJson(Map<String, dynamic>.from(d.data())),
        ));
      }
      _rows.sort((a, b) => b.result.startedAt.compareTo(a.result.startedAt));

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      _events7d.clear();
      _eventsAll.clear();
      for (final d in events.docs) {
        final t = (d.data()['type'] as String?) ?? '?';
        _eventsAll[t] = (_eventsAll[t] ?? 0) + 1;
        final at = d.data()['at'];
        if (at is Timestamp && at.toDate().isAfter(weekAgo)) {
          _events7d[t] = (_events7d[t] ?? 0) + 1;
        }
      }
      _users = profiles.length;
      _kids = profiles.values
          .where((p) => (p['age'] as num?) != null && (p['age'] as num) < 13)
          .length;
      _adults = profiles.values
          .where((p) => (p['age'] as num?) != null && (p['age'] as num) >= 13)
          .length;
      _questionnaires = questionnaires.size;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  static String _secs(int? ms) =>
      ms == null ? '—' : (ms / 1000).toStringAsFixed(1);

  static double? _avg(Iterable<num> xs) {
    final l = xs.toList();
    if (l.isEmpty) return null;
    return l.reduce((a, b) => a + b) / l.length;
  }

  /// One CSV line per assessment round (times in seconds).
  String _csv() {
    final b = StringBuffer(
        'uid,name,age,group,assessment_started_utc,round,grid,duration_s,'
        'active_s,rotations,rot_cw,rot_ccw,placements,avg_gap_s,'
        'avg_pick_to_place_s,back_to_builder,help_opens,board_moves,'
        'mismatches_first_full\n');
    for (final r in _rows) {
      for (var i = 0; i < r.result.rounds.length; i++) {
        final m = r.result.rounds[i];
        final gap = _avg(m.placementIntervalsMs);
        final pick = _avg(m.pickToPlaceMs);
        b.writeln([
          r.uid,
          '"${r.name.replaceAll('"', "'")}"',
          r.age ?? '',
          r.group,
          r.result.startedAt.toUtc().toIso8601String(),
          i + 1,
          '${m.gridSize}x${m.gridSize}',
          _secs(m.durationMs),
          _secs(m.activeDurationMs),
          m.rotations,
          m.rotationsCw,
          m.rotationsCcw,
          m.placements,
          gap == null ? '' : (gap / 1000).toStringAsFixed(2),
          pick == null ? '' : (pick / 1000).toStringAsFixed(2),
          m.backToBuilder,
          m.helpOpens,
          m.boardMoves,
          m.mismatchesWhenFirstFull ?? '',
        ].join(','));
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final st = VisualStyle.current;
    final on = st.isClassic ? Colors.black87 : st.onTray;
    return Scaffold(
      backgroundColor: st.isClassic ? null : st.trayBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(on)
                : _content(on),
      ),
    );
  }

  Widget _errorView(Color on) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Could not load (are you an admin?)',
              style: TextStyle(color: on, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: on.withOpacity(0.6))),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
          TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Back')),
        ]),
      );

  Widget _tile(String label, String value, Color on) => Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VisualStyle.current.trayCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  color: on, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: on.withOpacity(0.7))),
        ]),
      );

  Widget _content(Color on) {
    // Average per round index, split kid / adult.
    String avgFor(String group, int round, num? Function(RoundMetrics) f) {
      final xs = _rows
          .where((r) => r.group == group && r.result.rounds.length > round)
          .map((r) => f(r.result.rounds[round]))
          .whereType<num>();
      final a = _avg(xs);
      return a == null ? '—' : a.toStringAsFixed(1);
    }

    final roundLabels = ['2×2', '3×3 (1)', '3×3 (2)'];
    final textStyle = TextStyle(color: on);
    final head = TextStyle(color: on, fontWeight: FontWeight.w800);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: on),
            onPressed: () => Navigator.maybePop(context),
          ),
          Text('Results dashboard',
              style: TextStyle(
                  color: on, fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: on),
            onPressed: _load,
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy CSV'),
            onPressed: () => Clipboard.setData(ClipboardData(text: _csv())),
          ),
        ]),
        Wrap(children: [
          _tile('users', '$_users', on),
          _tile('kids (<13)', '$_kids', on),
          _tile('adults', '$_adults', on),
          _tile('questionnaires', '$_questionnaires', on),
          _tile('assessments', '${_rows.length}', on),
          for (final e in (_events7d.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))))
            _tile('${e.key} (7d)', '${e.value}', on),
        ]),
        const SizedBox(height: 12),
        Text('Averages per round (seconds / counts)', style: head),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: head,
            dataTextStyle: textStyle,
            columns: const [
              DataColumn(label: Text('group')),
              DataColumn(label: Text('round')),
              DataColumn(label: Text('time s'), numeric: true),
              DataColumn(label: Text('rotations'), numeric: true),
              DataColumn(label: Text('back to builder'), numeric: true),
              DataColumn(label: Text('help'), numeric: true),
              DataColumn(label: Text('pick→place s'), numeric: true),
            ],
            rows: [
              for (final g in ['kid', 'adult'])
                for (var i = 0; i < 3; i++)
                  DataRow(cells: [
                    DataCell(Text(g)),
                    DataCell(Text(roundLabels[i])),
                    DataCell(Text(avgFor(g, i,
                        (m) => m.durationMs == null ? null : m.durationMs! / 1000))),
                    DataCell(Text(avgFor(g, i, (m) => m.rotations))),
                    DataCell(Text(avgFor(g, i, (m) => m.backToBuilder))),
                    DataCell(Text(avgFor(g, i, (m) => m.helpOpens))),
                    DataCell(Text(avgFor(g, i, (m) {
                      final a = _avg(m.pickToPlaceMs);
                      return a == null ? null : a / 1000;
                    }))),
                  ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('All assessments (newest first)', style: head),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: head,
            dataTextStyle: textStyle,
            columns: [
              const DataColumn(label: Text('name')),
              const DataColumn(label: Text('age'), numeric: true),
              const DataColumn(label: Text('date')),
              for (final l in roundLabels) ...[
                DataColumn(label: Text('$l s'), numeric: true),
                DataColumn(label: Text('$l rot'), numeric: true),
                DataColumn(label: Text('$l back'), numeric: true),
              ],
              const DataColumn(label: Text('help'), numeric: true),
            ],
            rows: [
              for (final r in _rows)
                DataRow(cells: [
                  DataCell(Text(r.name)),
                  DataCell(Text('${r.age ?? '—'}')),
                  DataCell(Text(_date(r.result.startedAt))),
                  for (var i = 0; i < 3; i++) ...[
                    DataCell(Text(i < r.result.rounds.length
                        ? _secs(r.result.rounds[i].durationMs)
                        : '—')),
                    DataCell(Text(i < r.result.rounds.length
                        ? '${r.result.rounds[i].rotations}'
                        : '—')),
                    DataCell(Text(i < r.result.rounds.length
                        ? '${r.result.rounds[i].backToBuilder}'
                        : '—')),
                  ],
                  DataCell(Text(
                      '${r.result.rounds.fold<int>(0, (s, m) => s + m.helpOpens)}')),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('All events (all time)', style: head),
        Wrap(children: [
          for (final e in _eventsAll.entries) _tile(e.key, '${e.value}', on),
        ]),
      ],
    );
  }

  static String _date(DateTime d) {
    final l = d.toLocal();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
