import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Hosted copy of web/privacy.html for the native apps.
const nativePrivacyUrl = 'https://balinti.github.io/carpet_game/privacy.html';

/// On the web `privacy.html` next to the app, elsewhere [nativePrivacyUrl].
Uri privacyPolicyUri() =>
    kIsWeb ? Uri.base.resolve('privacy.html') : Uri.parse(nativePrivacyUrl);

/// Opens the privacy policy in the browser. Never throws.
Future<void> openPrivacyPolicy() async {
  try {
    await launchUrl(
      privacyPolicyUri(),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {}
}
