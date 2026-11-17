import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'validators.dart';

/// Onboarding strings in English / Spanish / Hebrew, same `_t(en, es, he)`
/// pattern as [AppLocalizations]. Kept in its own file so it merges cleanly.
class OnboardingStrings {
  final AppLanguage language;
  const OnboardingStrings(this.language);

  static OnboardingStrings of(BuildContext context) =>
      OnboardingStrings(AppLocalizations.of(context).language);

  // Sign up
  String get signUpTitle => _t('Create your account', 'Crea tu cuenta', 'יצירת חשבון');
  String get name => _t('Name', 'Nombre', 'שם');
  String get email => _t('Email', 'Correo electrónico', 'אימייל');
  String get password => _t('Password', 'Contraseña', 'סיסמה');
  String get age => _t('Age', 'Edad', 'גיל');
  String get createAccount => _t('Create account', 'Crear cuenta', 'יצירת חשבון');
  String get continueWithGoogle => _t('Continue with Google', 'Continuar con Google', 'המשך עם Google');
  String get orUseEmail => _t('or use email', 'o usa tu correo', 'או עם אימייל');
  String get haveAccount => _t('I already have an account', 'Ya tengo una cuenta', 'יש לי כבר חשבון');
  String get kidHint => _t('Under 13? A parent can help fill this in.',
      '¿Menor de 13? Un adulto puede ayudar.', 'מתחת לגיל 13? הורה יכול לעזור למלא.');

  // Complete profile (signed in, but no profile on this device)
  String get completeProfileTitle => _t('Tell us about you', 'Cuéntanos sobre ti', 'ספרו לנו עליכם');
  String get continueLabel => _t('Continue', 'Continuar', 'המשך');

  // Sign in
  String get signInTitle => _t('Welcome back', 'Bienvenido de nuevo', 'ברוכים השבים');
  String get signIn => _t('Sign in', 'Iniciar sesión', 'כניסה');
  String get newAccount => _t('Create a new account', 'Crear una cuenta nueva', 'יצירת חשבון חדש');

  // Verify email
  String get verifyTitle => _t('Check your email', 'Revisa tu correo', 'בדקו את האימייל');
  String verifyBody(String email) => _t(
      'We sent a link to $email. Open it, then come back and tap the button below.',
      'Enviamos un enlace a $email. Ábrelo y luego vuelve y toca el botón de abajo.',
      'שלחנו קישור אל $email. פתחו אותו, ואז חזרו ולחצו על הכפתור למטה.');
  String get iConfirmed => _t('I confirmed', 'Ya confirmé', 'אישרתי');
  String get resend => _t('Send the email again', 'Enviar el correo otra vez', 'שליחה חוזרת');
  String get resent => _t('Sent again. Check your inbox and spam folder.',
      'Enviado otra vez. Revisa tu bandeja de entrada y spam.', 'נשלח שוב. בדקו גם בתיקיית הספאם.');
  String get notVerifiedYet => _t("We can't see the confirmation yet. Open the link in the email, then try again.",
      'Aún no vemos la confirmación. Abre el enlace del correo e inténtalo de nuevo.',
      'עדיין לא רואים אישור. פתחו את הקישור באימייל ונסו שוב.');
  String get differentEmail => _t('Use a different email', 'Usar otro correo', 'שימוש באימייל אחר');

  // Questionnaire
  String get questionnaireTitle => _t('Getting to know you', 'Conociéndote', 'שאלון היכרות');
  String get start => _t('Start', 'Empezar', 'מתחילים');
  String get back => _t('Back', 'Atrás', 'חזרה');
  String questionOf(int i, int n) => _t('Question $i of $n', 'Pregunta $i de $n', 'שאלה $i מתוך $n');
  String get kidIntroHeading => _t('Answer together with a parent', 'Respondan junto con un adulto', 'עונים יחד עם הורה');
  String get adultIntroHeading => _t('A few quick questions', 'Unas preguntas rápidas', 'כמה שאלות קצרות');

  // Validation
  String fieldError(FieldError e) => switch (e) {
        FieldError.nameRequired => _t('Please enter a name', 'Escribe un nombre', 'נא להזין שם'),
        FieldError.emailInvalid => _t('Please enter a valid email', 'Escribe un correo válido', 'נא להזין אימייל תקין'),
        FieldError.passwordTooShort => _t('At least $kMinPasswordLength characters',
            'Al menos $kMinPasswordLength caracteres', 'לפחות $kMinPasswordLength תווים'),
        FieldError.ageInvalid => _t('Age $kMinAge to $kMaxAge', 'Edad de $kMinAge a $kMaxAge', 'גיל $kMinAge עד $kMaxAge'),
      };

  // Auth errors (codes follow Firebase Auth)
  String authError(String code) => switch (code) {
        'email-already-in-use' => _t('This email already has an account. Sign in instead.',
            'Este correo ya tiene una cuenta. Inicia sesión.', 'לאימייל הזה כבר יש חשבון. היכנסו במקום.'),
        'invalid-email' => fieldError(FieldError.emailInvalid),
        'weak-password' => _t('Choose a stronger password', 'Elige una contraseña más segura', 'בחרו סיסמה חזקה יותר'),
        'user-not-found' || 'wrong-password' || 'invalid-credential' => _t(
            'Wrong email or password', 'Correo o contraseña incorrectos', 'אימייל או סיסמה שגויים'),
        'too-many-requests' => _t('Too many tries. Wait a minute and try again.',
            'Demasiados intentos. Espera un minuto.', 'יותר מדי ניסיונות. חכו דקה ונסו שוב.'),
        'network-request-failed' => _t('No internet connection', 'Sin conexión a internet', 'אין חיבור לאינטרנט'),
        _ => _t('Something went wrong. Please try again.', 'Algo salió mal. Inténtalo de nuevo.', 'משהו השתבש. נסו שוב.'),
      };

  String _t(String en, String es, String he) {
    switch (language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.spanish:
        return es;
      case AppLanguage.hebrew:
        return he;
    }
  }
}
