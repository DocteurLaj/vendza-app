import 'dart:js_interop';

@JS('vendzaGoogleWebClientId')
external JSString? get _vendzaGoogleWebClientId;

String runtimeGoogleWebClientId() {
  final value = _vendzaGoogleWebClientId;
  if (value == null) return '';
  return value.toDart.trim();
}
