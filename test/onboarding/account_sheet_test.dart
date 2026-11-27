import 'package:carpet_game/l10n/app_localizations.dart';
import 'package:carpet_game/l10n/locale_provider.dart';
import 'package:carpet_game/main.dart' show LocaleProviderScope;
import 'package:carpet_game/onboarding/account_deletion.dart';
import 'package:carpet_game/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopAuth implements AccountAuth {
  int deletes = 0;
  @override
  String? get currentUid => 'u1';
  @override
  Set<SignInMethod> get signInMethods => const {SignInMethod.password};
  @override
  bool get needsRecentLogin => false;
  @override
  Future<void> reauthenticateWithPassword(String password) async {}
  @override
  Future<void> reauthenticateWithGoogle() async {}
  @override
  Future<void> deleteUser() async => deletes++;
  @override
  Future<void> signOut() async {}
}

class _NoopData implements UserDataStore {
  @override
  Future<void> deleteCollection(String uid, String collection) async {}
  @override
  Future<void> deleteUserDoc(String uid) async {}
}

class _NoopLocal implements LocalDataStore {
  @override
  Future<void> clear(String uid) async {}
}

Widget _app(Widget home, AppLanguage lang) => LocaleProviderScope(
      provider: LocaleProvider(),
      child: MaterialApp(
        locale: lang.locale,
        supportedLocales: AppLanguage.values.map((l) => l.locale),
        localizationsDelegates: [
          AppLocalizationsDelegate(lang),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

void main() {
  for (final lang in [AppLanguage.hebrew, AppLanguage.english]) {
    testWidgets('delete account shows confirm dialog (${lang.code})',
        (tester) async {
      // The level guide rows overflow with the test font (not this feature).
      final onError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        onError?.call(d);
      };
      addTearDown(() => FlutterError.onError = onError);
      HomeScreen.debugAnimate = false;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = _NoopAuth();
      var deleted = 0;
      await tester.pumpWidget(_app(
        HomeScreen(
          accountDeletion: AccountDeletionService(
              auth: auth, data: _NoopData(), local: _NoopLocal()),
          onAccountDeleted: () => deleted++,
        ),
        lang,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account_privacy')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account_delete')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('delete_confirm_dialog')), findsOneWidget);
      expect(
        find.textContaining(
            lang == AppLanguage.hebrew ? 'לצמיתות' : 'permanently'),
        findsWidgets,
      );

      // Cancel keeps the account.
      await tester.tap(find.byKey(const ValueKey('delete_cancel')));
      await tester.pumpAndSettle();
      expect(auth.deletes, 0);
      expect(deleted, 0);

      // Confirm deletes it.
      await tester.tap(find.byKey(const ValueKey('account_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_confirm')));
      await tester.pumpAndSettle();
      expect(auth.deletes, 1);
      expect(deleted, 1);
    });
  }
}
