import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reloado_auth/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'service_icons.dart';

void main() => runApp(const ReloadoAuthApp());

// ──────────────────────────────────────────────
// App root – handles theme persistence
// ──────────────────────────────────────────────
class ReloadoAuthApp extends StatefulWidget {
  const ReloadoAuthApp({super.key});

  // ignore: library_private_types_in_public_api
  static _ReloadoAuthAppState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_ReloadoAuthAppState>();

  @override
  State<ReloadoAuthApp> createState() => _ReloadoAuthAppState();
}

class _ReloadoAuthAppState extends State<ReloadoAuthApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() => _themeMode = (p.getBool('dark_mode') ?? false)
          ? ThemeMode.dark
          : ThemeMode.light);
    });
  }

  void toggleTheme() async {
    final isDark = _themeMode == ThemeMode.dark;
    setState(() => _themeMode = isDark ? ThemeMode.light : ThemeMode.dark);
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reloado Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1a73e8), brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1a73e8), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('de')],
      home: const BiometricWrapper(),
    );
  }
}

// ──────────────────────────────────────────────
// Biometric unlock screen
// ──────────────────────────────────────────────
class BiometricWrapper extends StatefulWidget {
  const BiometricWrapper({super.key});
  @override
  State<BiometricWrapper> createState() => _BiometricWrapperState();
}

class _BiometricWrapperState extends State<BiometricWrapper> {
  final _auth = LocalAuthentication();
  bool _authenticated = false;
  bool _checking = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Delay until after first build so AppLocalizations is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAuth());
  }

  Future<void> _checkAndAuth() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // Device has no lock screen at all — skip auth
        if (mounted) setState(() { _authenticated = true; _checking = false; });
        return;
      }
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      if (!canCheck && enrolled.isEmpty) {
        // No biometrics and no device credentials enrolled — skip auth
        if (mounted) setState(() { _authenticated = true; _checking = false; });
        return;
      }
      if (mounted) setState(() => _checking = false);
      await _authenticate();
    } catch (e) {
      if (mounted) setState(() { _checking = false; _errorMsg = e.toString(); });
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() => _errorMsg = null);
    final loc = AppLocalizations.of(context)!;
    try {
      final ok = await _auth.authenticate(
        localizedReason: loc.biometricReason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: loc.biometricTitle,
            biometricHint: loc.biometricHint,
            cancelButton: loc.cancel,
          ),
          IOSAuthMessages(
            cancelButton: loc.cancel,
          ),
        ],
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) setState(() => _authenticated = true);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return const HomeScreen();
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 80, color: Color(0xFF1a73e8)),
                const SizedBox(height: 24),
                Text(loc.unlockToContinue,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(loc.authenticateButton),
                ),
              ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────
// ── RFC 6238 TOTP — self-contained, bypasses otp package base32 quirks ──

// Base32 decode (RFC 4648, A-Z + 2-7). Ignores padding and whitespace.
List<int> _base32Decode(String s) {
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  s = s.replaceAll(RegExp(r'[=\s]'), '').toUpperCase();
  int buf = 0, bitsLeft = 0;
  final out = <int>[];
  for (final ch in s.split('')) {
    final v = alpha.indexOf(ch);
    if (v < 0) continue;
    buf = (buf << 5) | v;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      out.add((buf >> bitsLeft) & 0xff);
    }
  }
  return out;
}

String _computeTOTP(String secret, int nowMs, int period, int digits, String alg) {
  final key     = _base32Decode(secret.replaceAll(RegExp(r'[\s=]'), '').toUpperCase());
  final counter = nowMs ~/ 1000 ~/ period;

  // Counter as 8-byte big-endian
  final msg = List<int>.filled(8, 0);
  var c = counter;
  for (int i = 7; i >= 0; i--) { msg[i] = c & 0xff; c >>= 8; }

  final Hash hashFn;
  switch (alg.toUpperCase()) {
    case 'SHA256': hashFn = sha256; break;
    case 'SHA512': hashFn = sha512; break;
    default:       hashFn = sha1;
  }

  final hash   = Hmac(hashFn, key).convert(msg).bytes;
  final offset = hash.last & 0x0f;
  final code   = ((hash[offset]     & 0x7f) << 24) |
                 ((hash[offset + 1] & 0xff) << 16) |
                 ((hash[offset + 2] & 0xff) <<  8) |
                  (hash[offset + 3] & 0xff);

  final mod = digits == 8 ? 100000000 : digits == 7 ? 10000000 : 1000000;
  return (code % mod).toString().padLeft(digits, '0');
}

String _generateTOTP(Map<String, dynamic> token) {
  try {
    return _computeTOTP(
      token['secret'] as String? ?? '',
      DateTime.now().millisecondsSinceEpoch,
      int.tryParse(token['period']?.toString()    ?? '30') ?? 30,
      int.tryParse(token['digits']?.toString()    ?? '6')  ?? 6,
      token['algorithm'] as String?               ?? 'SHA1',
    );
  } catch (_) { return '------'; }
}

String _generateNextTOTP(Map<String, dynamic> token) {
  try {
    final period = int.tryParse(token['period']?.toString() ?? '30') ?? 30;
    return _computeTOTP(
      token['secret'] as String? ?? '',
      DateTime.now().millisecondsSinceEpoch + period * 1000,
      period,
      int.tryParse(token['digits']?.toString() ?? '6') ?? 6,
      token['algorithm'] as String?            ?? 'SHA1',
    );
  } catch (_) { return '------'; }
}

int _timeLeft(Map<String, dynamic> token) {
  final period = int.tryParse(token['period']?.toString() ?? '30') ?? 30;
  return period - (DateTime.now().millisecondsSinceEpoch ~/ 1000 % period);
}

Map<String, dynamic> _parseOtpAuth(String uri) {
  try {
    final url    = Uri.parse(uri);
    final params = url.queryParameters;
    final label  = Uri.decodeComponent(url.path.substring(1));
    final parts  = label.split(':');

    // otpauth label format: "ServiceName:username@example.com" or just "username@example.com"
    final String name;
    final String username;
    if (parts.length > 1) {
      name     = parts[0].trim();
      username = parts.sublist(1).join(':').trim();
    } else {
      name     = params['issuer']?.trim() ?? '';
      username = parts[0].trim();
    }

    final issuer = (params['issuer'] ?? name).trim().toLowerCase();
    return {
      'name':      name,
      'username':  username,
      'issuer':    issuer,
      'secret':    (params['secret'] ?? '').toUpperCase(),
      'algorithm': params['algorithm'] ?? 'SHA1',
      'digits':    params['digits']    ?? '6',
      'period':    params['period']    ?? '30',
    };
  } catch (_) {
    return {};
  }
}

// Translate API error codes to localized strings
String _apiError(String? code, AppLocalizations loc) {
  switch (code) {
    case 'account_locked':  return loc.errAccountLocked;
    case 'rate_limit':      return loc.errRateLimit;
    case 'pass_too_short':  return loc.errPassTooShort;
    case 'email_exists':    return loc.errEmailExists;
    case 'invalid_creds':   return loc.errInvalidCreds;
    case 'not_verified':    return loc.errNotVerified;
    case 'email_not_found': return loc.errEmailNotFound;
    case 'invalid_token':   return loc.errInvalidToken;
    default:                return code ?? loc.errUnknown;
  }
}

// Translate API success message codes
String _apiMsg(String? code, AppLocalizations loc) {
  switch (code) {
    case 'reg_success':   return loc.msgRegSuccess;
    case 'reset_sent':    return loc.msgResetSent;
    case 'reset_success': return loc.passwordResetSuccess;
    default:              return code ?? '';
  }
}

// ──────────────────────────────────────────────
// Main vault screen
// ──────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> tokens = [];
  Timer? _timer;

  String? cloudEmail;
  String? cloudPassword;

  static const String _apiUrl = 'https://auth.reloado.com/api.php';

  @override
  void initState() {
    super.initState();
    _loadLocalTokens().then((_) => _loadCloudCredentials());
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalTokens() async {
    final raw = await _storage.read(key: 'local_vault');
    if (raw != null) {
      setState(() {
        tokens = List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
      });
    }
  }

  Future<void> _saveLocalTokens() async {
    await _storage.write(key: 'local_vault', value: jsonEncode(tokens));
    if (cloudEmail != null) _syncToCloud();
    setState(() {});
  }

  // ── Persistent cloud credentials (Android Keystore / iOS Keychain) ──
  Future<void> _loadCloudCredentials() async {
    final email = await _storage.read(key: 'cloud_email');
    final pw    = await _storage.read(key: 'cloud_password');
    if (email != null && pw != null && mounted) {
      cloudEmail    = email;
      cloudPassword = pw;
      setState(() {});
      _syncFromCloud(); // force sync on startup
    }
  }

  Future<void> _saveCloudCredentials() async {
    await _storage.write(key: 'cloud_email',    value: cloudEmail    ?? '');
    await _storage.write(key: 'cloud_password', value: cloudPassword ?? '');
  }

  Future<void> _clearCloudCredentials() async {
    await _storage.delete(key: 'cloud_email');
    await _storage.delete(key: 'cloud_password');
  }

  Future<void> _syncFromCloud(
      {List<Map<String, dynamic>>? localTokensToMerge}) async {
    if (cloudEmail == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final loc       = AppLocalizations.of(context)!;
    try {
      final res = await _apiCall('fetch');
      if (!mounted) return;
      if (res['error'] != null) {
        if (res['error'] == 'invalid_creds' ||
            res['error'] == 'account_locked') {
          await _clearCloudCredentials();
          setState(() { cloudEmail = null; cloudPassword = null; });
          messenger.showSnackBar(SnackBar(
            content: Text(loc.errSessionExpired),
            duration: const Duration(seconds: 4),
          ));
        }
        return;
      }
      if (res['vault'] != null) {
        final dec = _getEncrypter(cloudPassword!)
            .decrypt64(res['vault'] as String,
                iv: enc.IV.fromBase64(res['iv'] as String));
        var cloudTokens = List<Map<String, dynamic>>.from(
            (jsonDecode(dec) as List).map((e) => Map<String, dynamic>.from(e)));

        // Merge any local-only entries (by secret) into the cloud vault
        int mergedCount = 0;
        if (localTokensToMerge != null && localTokensToMerge.isNotEmpty) {
          final cloudSecrets =
              cloudTokens.map((t) => t['secret']?.toString()).toSet();
          final localOnly = localTokensToMerge
              .where((t) => !cloudSecrets.contains(t['secret']?.toString()))
              .toList();
          if (localOnly.isNotEmpty) {
            cloudTokens = [...cloudTokens, ...localOnly];
            mergedCount = localOnly.length;
          }
        }

        setState(() { tokens = cloudTokens; });
        await _storage.write(
            key: 'local_vault', value: jsonEncode(cloudTokens));

        if (mergedCount > 0) {
          await _syncToCloud();
          if (mounted) {
            messenger.showSnackBar(SnackBar(
              content: Text(loc.entriesMerged(mergedCount)),
              duration: const Duration(seconds: 3),
            ));
          }
        }
      } else if (tokens.isNotEmpty) {
        await _syncToCloud(); // push local vault if cloud is empty
      }
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }
  }

  Future<void> _changePassword() async {
    final loc       = AppLocalizations.of(context)!;
    final newPwCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? dialogError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: Text(loc.changePassword),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (dialogError != null) ...[
              Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: newPwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: loc.enterNewPassword,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: loc.confirmPassword,
                  border: const OutlineInputBorder()),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(loc.cancel)),
            FilledButton(
              onPressed: () {
                if (newPwCtrl.text.length < 8) {
                  setS(() => dialogError = loc.errPassTooShort);
                  return;
                }
                if (newPwCtrl.text != confirmCtrl.text) {
                  setS(() => dialogError = loc.confirmPassword);
                  return;
                }
                Navigator.pop(c, true);
              },
              child: Text(loc.confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final res = await _apiCall('change_password',
          extra: {'new_password': newPwCtrl.text});
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (res['success'] == true) {
        cloudPassword = newPwCtrl.text;
        await _saveCloudCredentials();
        await _syncToCloud();
        messenger.showSnackBar(SnackBar(content: Text(loc.pwChanged)));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(_apiError(res['error']?.toString(), loc))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── E2EE ──
  enc.Encrypter _getEncrypter(String password) {
    final bytes = sha256.convert(utf8.encode(password)).bytes;
    return enc.Encrypter(
        enc.AES(enc.Key(Uint8List.fromList(bytes)), mode: enc.AESMode.gcm));
  }

  Future<Map<String, dynamic>> _apiCall(String action,
      {Map<String, String>? extra}) async {
    final body = {
      'action':   action,
      'email':    cloudEmail   ?? '',
      'password': cloudPassword ?? '',
      ...?extra,
    };
    final res = await http.post(Uri.parse(_apiUrl), body: body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _syncToCloud() async {
    if (cloudEmail == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final loc       = AppLocalizations.of(context)!;
    try {
      final encrypter = _getEncrypter(cloudPassword!);
      final iv        = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(jsonEncode(tokens), iv: iv);
      final res = await _apiCall('sync',
          extra: {'vault': encrypted.base64, 'iv': iv.base64});
      if (!mounted) return;
      if (res['error'] == 'invalid_creds' ||
          res['error'] == 'account_locked') {
        await _clearCloudCredentials();
        setState(() { cloudEmail = null; cloudPassword = null; });
        messenger.showSnackBar(SnackBar(
          content: Text(loc.errSessionExpired),
          duration: const Duration(seconds: 4),
        ));
        return;
      }
      if (res['success'] == true) {
        messenger.showSnackBar(SnackBar(
          content: Text(loc.syncSuccess),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  // ── Add / Edit dialog ──
  void _showEntryDialog({int? editIndex}) {
    final loc          = AppLocalizations.of(context)!;
    final nameCtrl      = TextEditingController(text: editIndex != null ? tokens[editIndex]['name']?.toString()      : '');
    final usernameCtrl  = TextEditingController(text: editIndex != null ? tokens[editIndex]['username']?.toString()  : '');
    final issuerCtrl    = TextEditingController(text: editIndex != null ? tokens[editIndex]['issuer']?.toString()    : '');
    final secretCtrl    = TextEditingController(text: editIndex != null ? tokens[editIndex]['secret']?.toString()    : '');
    String algorithm    = editIndex != null ? (tokens[editIndex]['algorithm']?.toString() ?? 'SHA1') : 'SHA1';
    String digits       = editIndex != null ? (tokens[editIndex]['digits']?.toString()    ?? '6')    : '6';
    String period       = editIndex != null ? (tokens[editIndex]['period']?.toString()    ?? '30')   : '30';
    bool showAdvanced   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(editIndex != null ? loc.editEntry : loc.addAccount,
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),

              // QR scan button
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(loc.scanQrCode),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showQrScanner(editIndex: editIndex);
                },
              ),
              const SizedBox(height: 8),

              TextField(controller: nameCtrl,     decoration: InputDecoration(labelText: loc.serviceName)),
              TextField(controller: usernameCtrl, decoration: InputDecoration(labelText: loc.usernameEmail, hintText: 'e.g. john@example.com')),
              TextField(controller: issuerCtrl,   decoration: InputDecoration(labelText: loc.issuerDomain, hintText: 'e.g. github.com')),
              TextField(
                controller: secretCtrl,
                decoration: InputDecoration(labelText: loc.secretKey),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),

              // Advanced toggle
              InkWell(
                onTap: () => setS(() => showAdvanced = !showAdvanced),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text(loc.advanced,
                        style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
                    Icon(showAdvanced ? Icons.expand_less : Icons.expand_more),
                  ]),
                ),
              ),
              if (showAdvanced) ...[
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    initialValue: algorithm,
                    decoration: InputDecoration(labelText: loc.algorithm),
                    items: ['SHA1', 'SHA256', 'SHA512'].map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setS(() => algorithm = v!),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(
                    initialValue: digits,
                    decoration: InputDecoration(labelText: loc.digits),
                    items: ['6', '8'].map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setS(() => digits = v!),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(
                    initialValue: period,
                    decoration: InputDecoration(labelText: loc.periodSec),
                    items: ['30', '60'].map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setS(() => period = v!),
                  )),
                ]),
              ],

              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(loc.cancel)),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final entry = {
                      'name':      nameCtrl.text.trim(),
                      'username':  usernameCtrl.text.trim(),
                      'issuer':    issuerCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/.*$'), ''),
                      'secret':    secretCtrl.text.trim().replaceAll(' ', '').toUpperCase(),
                      'algorithm': algorithm,
                      'digits':    digits,
                      'period':    period,
                    };
                    if ((entry['name'] as String).isEmpty || (entry['secret'] as String).isEmpty) return;
                    if (editIndex != null) { tokens[editIndex] = entry; }
                    else { tokens.add(entry); }
                    _saveLocalTokens();
                    Navigator.pop(ctx);
                  },
                  child: Text(loc.save),
                ),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  // ── QR Scanner ──
  void _showQrScanner({int? editIndex}) {
    final ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
    bool scanned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Stack(children: [
          MobileScanner(
            controller: ctrl,
            onDetect: (capture) {
              if (scanned) return;
              final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
              if (raw.startsWith('otpauth://')) {
                scanned = true;
                final parsed = _parseOtpAuth(raw);
                if (parsed.isNotEmpty) {
                  if (editIndex != null) {
                    tokens[editIndex] = parsed;
                    _saveLocalTokens();
                  } else {
                    tokens.add(parsed);
                    _saveLocalTokens();
                  }
                }
                Navigator.pop(ctx);
              }
            },
          ),
          Positioned(
            top: 12, right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.scanQrCode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ]),
      ),
    ).whenComplete(() => ctrl.dispose());
  }

  // ── Cloud menu ──
  void _openCloudMenu() async {
    if (cloudEmail != null) {
      // Already logged in — show dashboard bottom sheet
      final loc = AppLocalizations.of(context)!;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1a73e8),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(cloudEmail!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(loc.cloudSyncActive),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(loc.forceSync),
            onTap: () { Navigator.pop(ctx); _syncFromCloud(); },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: Text(loc.changePassword),
            onTap: () { Navigator.pop(ctx); _changePassword(); },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(loc.logout),
            onTap: () async {
              Navigator.pop(ctx);
              await _clearCloudCredentials();
              setState(() { cloudEmail = null; cloudPassword = null; });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(loc.deleteAccount,
                style: const TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(loc.deleteAccount),
                  content: Text('${loc.deleteAccount}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false),
                        child: Text(loc.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(loc.delete,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _apiCall('delete_account');
                if (!mounted) return;
                await _clearCloudCredentials();
                setState(() { cloudEmail = null; cloudPassword = null; });
              }
            },
          ),
          const SizedBox(height: 16),
        ]),
      );
    } else {
      // Show full-screen login/register
      final result = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(builder: (_) => const CloudAuthScreen()),
      );
      if (result != null && mounted) {
        final localBefore = List<Map<String, dynamic>>.from(tokens);
        cloudEmail    = result['email'];
        cloudPassword = result['password'];
        await _saveCloudCredentials();
        await _syncFromCloud(localTokensToMerge: localBefore);
      }
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final loc       = AppLocalizations.of(context)!;
    final appState  = ReloadoAuthApp.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const _ReloadoLogo(),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined),
            onPressed: () => appState?.toggleTheme(),
            tooltip: isDark ? 'Light mode' : 'Dark mode',
          ),
          IconButton(
            icon: Icon(cloudEmail == null ? Icons.cloud_off : Icons.cloud_done,
                color: cloudEmail == null ? null : Colors.green),
            onPressed: _openCloudMenu,
            tooltip: 'Cloud Sync',
          ),
        ],
      ),
      body: tokens.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(loc.emptyVault,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center),
              ))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tokens.length,
              itemBuilder: (ctx, i) => _TokenCard(
                token:     tokens[i],
                onEdit:    () => _showEntryDialog(editIndex: i),
                onDelete:  () {
                  setState(() => tokens.removeAt(i));
                  _saveLocalTokens();
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Token card widget
// ──────────────────────────────────────────────
class _TokenCard extends StatelessWidget {
  final Map<String, dynamic> token;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TokenCard({
    required this.token,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmt(String code) => code.length >= 6
      ? '${code.substring(0, code.length ~/ 2)} ${code.substring(code.length ~/ 2)}'
      : code;

  @override
  Widget build(BuildContext context) {
    final period      = int.tryParse(token['period']?.toString() ?? '30') ?? 30;
    final timeLeft    = _timeLeft(token);
    final progress    = timeLeft / period;
    final issuer      = token['issuer']?.toString()   ?? '';
    final name        = token['name']?.toString()     ?? '';
    final username    = token['username']?.toString() ?? '';
    final display     = name.isNotEmpty ? name : issuer;
    final code        = _generateTOTP(token);
    final nextCode    = _generateNextTOTP(token);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final loc         = AppLocalizations.of(context)!;

    final barColor = timeLeft <= 5
        ? Colors.red
        : timeLeft <= 10
            ? Colors.orange
            : colorScheme.primary;

    return Dismissible(
      key: ValueKey('${token['secret']}_${token['issuer']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final l = AppLocalizations.of(ctx)!;
            return AlertDialog(
              title: Text(l.deleteEntryTitle),
              content: Text('"$display"\n${l.deleteEntryWarning}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l.delete),
                ),
              ],
            );
          },
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onLongPress: onEdit,
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          color: isDark ? colorScheme.surfaceContainerHigh : null,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: barColor,
                minHeight: 3,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left: name, username, code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(display,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (username.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(username,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.outline),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(loc.codeCopied),
                                  duration: const Duration(seconds: 1),
                                ));
                              },
                              child: Text(
                                _fmt(code),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: barColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Right: icon top, next code bottom
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ServiceLogo(issuer: issuer, name: name),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(loc.next,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.outline)),
                              Text(_fmt(nextCode),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.5,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Service logo with favicon + letter fallback
// ──────────────────────────────────────────────
class _ServiceLogo extends StatelessWidget {
  final String issuer;
  final String name;

  const _ServiceLogo({required this.issuer, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgUrl = simpleIconUrl(issuer, name, isDark: isDark);
    if (svgUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SvgPicture.network(
          svgUrl,
          width: 36, height: 36, fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox(width: 36, height: 36),
          errorBuilder: (ctx, _, __) => _faviconOrLetter(ctx),
        ),
      );
    }
    return _faviconOrLetter(context);
  }

  Widget _faviconOrLetter(BuildContext context) {
    final fav = faviconUrl(issuer);
    if (fav != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          fav,
          width: 36, height: 36, fit: BoxFit.contain,
          errorBuilder: (ctx, _, __) => _letterAvatar(ctx),
        ),
      );
    }
    return _letterAvatar(context);
  }

  Widget _letterAvatar(BuildContext context) {
    final display = name.isNotEmpty ? name : issuer;
    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        display.isNotEmpty ? display[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Full-screen Cloud Auth (Login / Register)
// ──────────────────────────────────────────────
class CloudAuthScreen extends StatefulWidget {
  const CloudAuthScreen({super.key});
  @override
  State<CloudAuthScreen> createState() => _CloudAuthScreenState();
}

class _CloudAuthScreenState extends State<CloudAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _loginEmailCtrl = TextEditingController();
  final _loginPwCtrl    = TextEditingController();
  final _regEmailCtrl   = TextEditingController();
  final _regPwCtrl      = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg   = true;
  bool _loading      = false;
  String? _error;
  String? _successMsg;

  static const _apiUrl = 'https://auth.reloado.com/api.php';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmailCtrl.dispose();
    _loginPwCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPwCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _api(String action, Map<String, String> params) async {
    final res = await http.post(Uri.parse(_apiUrl), body: {'action': action, ...params});
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.trim().isEmpty || _loginPwCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api('login', {
        'email':    _loginEmailCtrl.text.trim(),
        'password': _loginPwCtrl.text,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context, {
          'email':    _loginEmailCtrl.text.trim(),
          'password': _loginPwCtrl.text,
        });
      } else {
        final loc = AppLocalizations.of(context)!;
        setState(() => _error = _apiError(res['error']?.toString(), loc));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_regEmailCtrl.text.trim().isEmpty || _regPwCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; _successMsg = null; });
    try {
      final res = await _api('register', {
        'email':    _regEmailCtrl.text.trim(),
        'password': _regPwCtrl.text,
      });
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      if (res['error'] != null) {
        setState(() => _error = _apiError(res['error'].toString(), loc));
      } else {
        setState(() => _successMsg = _apiMsg(res['msg']?.toString(), loc));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final loc = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController(text: _loginEmailCtrl.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(loc.resetPassword),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(loc.resetVaultWarning,
              style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: loc.email,
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(loc.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(loc.sendToken)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _loading = true; _error = null; });
    try {
      await _api('reset_request', {'email': emailCtrl.text.trim(), 'password': ''});
      if (!mounted) return;

      final tokenCtrl = TextEditingController();
      final newPwCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(loc.enterResetToken),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: tokenCtrl,
              decoration: InputDecoration(
                labelText: loc.enterResetToken,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: loc.enterNewPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(loc.cancel)),
            FilledButton(
              onPressed: () async {
                final res = await _api('reset_password', {
                  'email':    emailCtrl.text.trim(),
                  'password': newPwCtrl.text,
                  'token':    tokenCtrl.text.trim(),
                });
                if (!c.mounted) return;
                Navigator.pop(c);
                if (mounted) {
                  if (res['success'] == true) {
                    setState(() {
                      _successMsg = _apiMsg('reset_success', loc);
                      _loginEmailCtrl.text = emailCtrl.text.trim();
                      _loginPwCtrl.text    = newPwCtrl.text;
                    });
                    _tabs.animateTo(0);
                  } else {
                    setState(() =>
                        _error = _apiError(res['error']?.toString(), loc));
                  }
                }
              },
              child: Text(loc.confirm),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const _ReloadoLogo(),
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => setState(() { _error = null; _successMsg = null; }),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.login),
            Tab(text: AppLocalizations.of(context)!.register),
          ],
        ),
      ),
      body: Column(children: [
        if (_error != null)
          Container(
            width: double.infinity,
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(_error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
        if (_successMsg != null)
          Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(_successMsg!,
                style: const TextStyle(color: Colors.green)),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_buildLoginTab(), _buildRegisterTab()],
          ),
        ),
      ]),
    );
  }

  Widget _buildLoginTab() {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16),
        const Icon(Icons.cloud_sync, size: 56, color: Color(0xFF1a73e8)),
        const SizedBox(height: 8),
        Text(loc.cloudSyncSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: loc.email,
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPwCtrl,
          obscureText: _obscureLogin,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) { if (!_loading) _login(); },
          decoration: InputDecoration(
            labelText: loc.password,
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscureLogin
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _login,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(loc.login),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _forgotPassword,
          child: Text(loc.forgotPassword,
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ]),
    );
  }

  Widget _buildRegisterTab() {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16),
        const Icon(Icons.person_add_outlined, size: 56, color: Color(0xFF1a73e8)),
        const SizedBox(height: 8),
        Text(loc.registerSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        TextField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: loc.email,
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _regPwCtrl,
          obscureText: _obscureReg,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) { if (!_loading) _register(); },
          decoration: InputDecoration(
            labelText: loc.password,
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscureReg
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureReg = !_obscureReg),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _register,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(loc.createAccount),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────
// Reloado logo widget
// ──────────────────────────────────────────────
class _ReloadoLogo extends StatelessWidget {
  const _ReloadoLogo();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF1a73e8), Color(0xFF0b5ed7), Color(0xFF0d47a1),
      Color(0xFF1565c0), Color(0xFF0277bd), Color(0xFF0288d1),
      Color(0xFF039be5), Color(0xFF00acc1), Color(0xFF0097a7),
      Color(0xFF0288d1), Color(0xFF039be5),
    ];
    const letters = 'Reloado Auth';
    final spans = <TextSpan>[];
    int ci = 0;
    for (final ch in letters.characters) {
      spans.add(TextSpan(
        text: ch,
        style: ch == ' ' ? null : TextStyle(color: colors[ci++ % colors.length]),
      ));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        children: spans,
      ),
    );
  }
}
