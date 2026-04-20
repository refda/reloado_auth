// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Reloado Auth';

  @override
  String get unlockToContinue => 'Entsperren, um 2FA-Codes anzuzeigen';

  @override
  String get authenticateButton => 'Authentifizieren';

  @override
  String get biometricReason => 'Reloado Auth entsperren, um Ihre 2FA-Codes anzuzeigen';

  @override
  String get biometricTitle => 'Authentifizierung erforderlich';

  @override
  String get biometricHint => 'Identität bestätigen';

  @override
  String get addAccount => 'Konto hinzufügen';

  @override
  String get editEntry => 'Eintrag bearbeiten';

  @override
  String get scanQrCode => 'QR-Code scannen';

  @override
  String get enterManually => 'Manuell eingeben';

  @override
  String get serviceName => 'Dienstname';

  @override
  String get issuerDomain => 'Domain';

  @override
  String get secretKey => 'Geheimer Schlüssel';

  @override
  String get algorithm => 'Algorithmus';

  @override
  String get digits => 'Stellen';

  @override
  String get periodSec => 'Periode (s)';

  @override
  String get advanced => 'Erweitert';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get syncSuccess => 'Mit Cloud synchronisiert ✓';

  @override
  String get verifyEmail => 'Bitte bestätigen Sie Ihre E-Mail.';

  @override
  String get emptyVault => 'Tresor ist leer. Tippen Sie auf + um das erste Konto hinzuzufügen.';

  @override
  String get codeCopied => 'Code kopiert!';

  @override
  String get resetWarning => 'WARNUNG: Ein Passwort-Reset löscht Ihren 2FA-Tresor in der Cloud unwiderruflich. Fortfahren?';

  @override
  String get enterResetToken => 'Reset-Token aus E-Mail eingeben';

  @override
  String get enterNewPassword => 'Neues Passwort eingeben';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get confirmPassword => 'Neues Passwort bestätigen';

  @override
  String get pwChanged => 'Passwort erfolgreich geändert.';

  @override
  String get errAccountLocked => 'Zu viele Fehlversuche. Konto für 15 Minuten gesperrt.';

  @override
  String get errRateLimit => 'Zu viele Anfragen. Bitte versuchen Sie es später erneut.';

  @override
  String get errPassTooShort => 'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get errEmailExists => 'Diese E-Mail-Adresse ist bereits registriert.';

  @override
  String get errInvalidCreds => 'E-Mail-Adresse oder Passwort falsch.';

  @override
  String get errNotVerified => 'Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse.';

  @override
  String get errEmailNotFound => 'Kein Konto mit dieser E-Mail-Adresse gefunden.';

  @override
  String get errInvalidToken => 'Ungültiger oder abgelaufener Reset-Token.';

  @override
  String get errUnknown => 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get msgRegSuccess => 'Registrierung erfolgreich. Bitte prüfen Sie Ihre E-Mail zur Bestätigung.';

  @override
  String get msgResetSent => 'Reset-Token gesendet. Bitte prüfen Sie Ihre E-Mail.';

  @override
  String get usernameEmail => 'Benutzername / E-Mail';

  @override
  String get cloudSyncSubtitle => 'Anmelden, um Ihren Tresor geräteübergreifend zu synchronisieren.';

  @override
  String get registerSubtitle => 'Erstellen Sie ein Konto, um Ihre 2FA-Einträge zu sichern und zu synchronisieren.';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get sendToken => 'Token senden';

  @override
  String get resetVaultWarning => 'Ein Reset-Token wird an Ihre E-Mail gesendet.\nWarnung: Ihr Cloud-Tresor wird unwiderruflich gelöscht.';

  @override
  String get passwordResetSuccess => 'Passwort erfolgreich zurückgesetzt. Sie können sich jetzt anmelden.';

  @override
  String get cloudSyncActive => 'Cloud-Synchronisierung aktiv';

  @override
  String get forceSync => 'Synchronisierung erzwingen';

  @override
  String get next => 'nächster';

  @override
  String get deleteEntryTitle => 'Eintrag löschen';

  @override
  String get deleteEntryWarning => 'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get errSessionExpired => 'Cloud-Sitzung abgelaufen. Bitte erneut anmelden.';

  @override
  String entriesMerged(int count) {
    return intl.Intl.plural(count,
        one: '$count lokaler Eintrag mit Cloud zusammengeführt.',
        other: '$count lokale Einträge mit Cloud zusammengeführt.',
        locale: localeName);
  }
}
