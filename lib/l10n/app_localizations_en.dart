// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Reloado Auth';

  @override
  String get unlockToContinue => 'Unlock to view your 2FA codes';

  @override
  String get authenticateButton => 'Authenticate';

  @override
  String get biometricReason => 'Unlock Reloado Auth to access your 2FA codes';

  @override
  String get biometricTitle => 'Authentication required';

  @override
  String get biometricHint => 'Verify your identity';

  @override
  String get addAccount => 'Add Account';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get enterManually => 'Enter Manually';

  @override
  String get serviceName => 'Service Name';

  @override
  String get issuerDomain => 'Domain';

  @override
  String get secretKey => 'Secret Key';

  @override
  String get algorithm => 'Algorithm';

  @override
  String get digits => 'Digits';

  @override
  String get periodSec => 'Period (s)';

  @override
  String get advanced => 'Advanced';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Sign Up';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get syncSuccess => 'Synced with cloud ✓';

  @override
  String get verifyEmail => 'Please verify your email.';

  @override
  String get emptyVault => 'Vault is empty. Tap + to add your first account.';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get resetWarning => 'WARNING: Resetting your password permanently deletes your 2FA vault in the cloud. Proceed?';

  @override
  String get enterResetToken => 'Enter reset token from email';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirm => 'Confirm';

  @override
  String get changePassword => 'Change Password';

  @override
  String get confirmPassword => 'Confirm New Password';

  @override
  String get pwChanged => 'Password changed successfully.';

  @override
  String get errAccountLocked => 'Too many failed attempts. Account locked for 15 minutes.';

  @override
  String get errRateLimit => 'Too many requests. Please try again later.';

  @override
  String get errPassTooShort => 'Password must be at least 8 characters.';

  @override
  String get errEmailExists => 'This email address is already registered.';

  @override
  String get errInvalidCreds => 'Incorrect email address or password.';

  @override
  String get errNotVerified => 'Please verify your email address first.';

  @override
  String get errEmailNotFound => 'No account found with this email address.';

  @override
  String get errInvalidToken => 'Invalid or expired reset token.';

  @override
  String get errUnknown => 'An error occurred. Please try again.';

  @override
  String get msgRegSuccess => 'Registration successful. Please check your email to verify your account.';

  @override
  String get msgResetSent => 'Reset token sent. Please check your email.';

  @override
  String get usernameEmail => 'Username / Email';

  @override
  String get cloudSyncSubtitle => 'Sign in to sync your vault across devices.';

  @override
  String get registerSubtitle => 'Create an account to back up and sync your 2FA entries.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get sendToken => 'Send Token';

  @override
  String get resetVaultWarning => 'A reset token will be sent to your email.\nWarning: your cloud vault will be permanently cleared.';

  @override
  String get passwordResetSuccess => 'Password reset successfully. You can now log in.';

  @override
  String get cloudSyncActive => 'Cloud Sync active';

  @override
  String get forceSync => 'Force Sync';

  @override
  String get next => 'next';

  @override
  String get deleteEntryTitle => 'Delete Entry';

  @override
  String get deleteEntryWarning => 'This action cannot be undone.';

  @override
  String get errSessionExpired => 'Cloud session expired. Please log in again.';

  @override
  String entriesMerged(int count) {
    return intl.Intl.plural(count,
        one: '$count local entry merged with cloud.',
        other: '$count local entries merged with cloud.',
        locale: localeName);
  }
}
