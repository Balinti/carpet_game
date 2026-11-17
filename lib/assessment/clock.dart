/// Time source for the assessment recorder, so tests can control time.
abstract class Clock {
  const Clock();
  DateTime now();
}

/// Wall-clock time.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Manually advanced clock for tests.
class FakeClock extends Clock {
  DateTime _now;

  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2025, 1, 1);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void advanceMs(int ms) => advance(Duration(milliseconds: ms));
}
