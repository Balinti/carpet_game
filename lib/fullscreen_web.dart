import 'dart:js_interop';

@JS('document.documentElement.requestFullscreen')
external JSPromise? _requestFullscreen();

@JS('document.fullscreenElement')
external JSAny? get _fullscreenElement;

@JS('document.fullscreenEnabled')
external bool? get _fullscreenEnabled;

/// Hide the browser bars (Android Chrome). iPhone Safari doesn't allow
/// this for web pages, so there it does nothing.
void requestFullscreen() {
  try {
    if (_fullscreenEnabled != true || _fullscreenElement != null) return;
    _requestFullscreen();
  } catch (_) {}
}
