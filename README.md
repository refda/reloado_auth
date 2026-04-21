# Reloado Auth

A secure, open-source 2FA (TOTP) authenticator for Android.

## Features

- TOTP code generation (RFC 6238 compatible)
- QR code scanning to add accounts
- Biometric lock (fingerprint / face unlock)
- Encrypted local storage — no cloud sync, no tracking
- German and English UI

## Privacy

This app stores all data locally on your device using encrypted storage. Optional E2EE cloud sync.

## Build

Requires Flutter 3.x.

```bash
flutter pub get
flutter build apk --release
```

For signed release builds, create `android/key.properties`:

```properties
storeFile=path/to/your.jks
storePassword=...
keyAlias=...
keyPassword=...
```

If `key.properties` is absent (e.g. F-Droid builds), the app builds with the debug signing config.

## License

[GNU AFFERO GENERAL PUBLIC LICENSE](LICENSE)
