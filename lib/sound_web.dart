import 'dart:js_interop';

@JS('window.__carpetChime')
external JSFunction? get _chime;

@JS('eval')
external JSAny? _eval(JSString code);

/// Short rising three-note chime (Web Audio), plus a buzz on Android.
void playSuccess() {
  try {
    if (_chime == null) {
      _eval('''
window.__carpetChime = function () {
  try {
    var A = window.AudioContext || window.webkitAudioContext;
    if (!A) return;
    var ctx = window.__carpetCtx || (window.__carpetCtx = new A());
    if (ctx.state === 'suspended') ctx.resume();
    var t = ctx.currentTime;
    [523.25, 659.25, 783.99, 1046.5].forEach(function (f, i) {
      var o = ctx.createOscillator(), g = ctx.createGain();
      o.type = 'triangle'; o.frequency.value = f;
      g.gain.setValueAtTime(0.0001, t + i * 0.09);
      g.gain.exponentialRampToValueAtTime(0.25, t + i * 0.09 + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, t + i * 0.09 + 0.35);
      o.connect(g); g.connect(ctx.destination);
      o.start(t + i * 0.09); o.stop(t + i * 0.09 + 0.4);
    });
    if (navigator.vibrate) navigator.vibrate([60, 40, 120]);
  } catch (e) {}
};'''
          .toJS);
    }
    _chime?.callAsFunction();
  } catch (_) {}
}
