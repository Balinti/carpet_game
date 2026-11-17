import 'package:flutter/services.dart';

/// Native apps: a firm buzz instead of a web chime.
void playSuccess() => HapticFeedback.heavyImpact();
