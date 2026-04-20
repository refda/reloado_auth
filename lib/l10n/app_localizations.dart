import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Reloado Auth'**
  String get appTitle;

  /// No description provided for @unlockToContinue.
  ///
  /// In en, this message translates to:
  /// **'Unlock to view your 2FA codes'**
  String get unlockToContinue;

  /// No description provided for @authenticateButton.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticateButton;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Reloado Auth to access your 2FA codes'**
  String get biometricReason;

  /// No description provided for @biometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get biometricTitle;

  /// No description provided for @biometricHint.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get biometricHint;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @issuerDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get issuerDomain;

  /// No description provided for @secretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get secretKey;

  /// No description provided for @algorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get algorithm;

  /// No description provided for @digits.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get digits;

  /// No description provided for @periodSec.
  ///
  /// In en, this message translates to:
  /// **'Period (s)'**
  String get periodSec;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced with cloud ✓'**
  String get syncSuccess;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email.'**
  String get verifyEmail;

  /// No description provided for @emptyVault.
  ///
  /// In en, this message translates to:
  /// **'Vault is empty. Tap + to add your first account.'**
  String get emptyVault;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @resetWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Resetting your password permanently deletes your 2FA vault in the cloud. Proceed?'**
  String get resetWarning;

  /// No description provided for @enterResetToken.
  ///
  /// In en, this message translates to:
  /// **'Enter reset token from email'**
  String get enterResetToken;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPassword;

  /// No description provided for @pwChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get pwChanged;

  /// No description provided for @errAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Account locked for 15 minutes.'**
  String get errAccountLocked;

  /// No description provided for @errRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get errRateLimit;

  /// No description provided for @errPassTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get errPassTooShort;

  /// No description provided for @errEmailExists.
  ///
  /// In en, this message translates to:
  /// **'This email address is already registered.'**
  String get errEmailExists;

  /// No description provided for @errInvalidCreds.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email address or password.'**
  String get errInvalidCreds;

  /// No description provided for @errNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address first.'**
  String get errNotVerified;

  /// No description provided for @errEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email address.'**
  String get errEmailNotFound;

  /// No description provided for @errInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired reset token.'**
  String get errInvalidToken;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errUnknown;

  /// No description provided for @msgRegSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please check your email to verify your account.'**
  String get msgRegSuccess;

  /// No description provided for @msgResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset token sent. Please check your email.'**
  String get msgResetSent;

  /// No description provided for @usernameEmail.
  ///
  /// In en, this message translates to:
  /// **'Username / Email'**
  String get usernameEmail;

  /// No description provided for @cloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your vault across devices.'**
  String get cloudSyncSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to back up and sync your 2FA entries.'**
  String get registerSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @sendToken.
  ///
  /// In en, this message translates to:
  /// **'Send Token'**
  String get sendToken;

  /// No description provided for @resetVaultWarning.
  ///
  /// In en, this message translates to:
  /// **'A reset token will be sent to your email.\nWarning: your cloud vault will be permanently cleared.'**
  String get resetVaultWarning;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully. You can now log in.'**
  String get passwordResetSuccess;

  /// No description provided for @cloudSyncActive.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync active'**
  String get cloudSyncActive;

  /// No description provided for @forceSync.
  ///
  /// In en, this message translates to:
  /// **'Force Sync'**
  String get forceSync;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get next;

  /// No description provided for @deleteEntryTitle.
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryWarning.
  String get deleteEntryWarning;

  /// No description provided for @errSessionExpired.
  String get errSessionExpired;

  /// No description provided for @entriesMerged.
  String entriesMerged(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
