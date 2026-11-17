import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Release web builds came up with the native (method channel) Firebase
/// platform, so Firebase.initializeApp failed. Register the web plugins
/// ourselves, core first, if that happened.
void ensureFirebaseWebPlugins() {
  if (FirebasePlatform.instance is FirebaseCoreWeb) return;
  FirebaseCoreWeb.registerWith(webPluginRegistrar);
  try {
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
  } catch (_) {}
  try {
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
  } catch (_) {}
}
