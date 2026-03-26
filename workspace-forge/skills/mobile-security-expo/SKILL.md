---
name: mobile-security-expo
description: Security review patterns for React Native and Expo mobile applications. Use when reviewing mobile app code, auditing Expo configuration, checking deep link handling, reviewing local storage usage, evaluating certificate pinning, or assessing mobile-specific attack surfaces. Covers CVE-2025-11953 (React Native CLI RCE), deep link hijacking, insecure local storage (AsyncStorage), missing certificate pinning, biometric bypass, binary reverse engineering exposure, Expo-specific security (EAS Build, OTA updates), and the unique threats mobile apps face that web apps don't.
---

# Mobile Security — Expo / React Native

## Mobile vs Web: Different Threat Model

Mobile apps run on **attacker-controlled devices**. Unlike web apps where you control the server, mobile apps can be:
- **Decompiled and reverse-engineered** (JavaScript bundle is readable)
- **Run through proxy tools** (Charles, mitmproxy — intercept all traffic)
- **Modified and re-signed** (patched APK/IPA with custom behavior)
- **Debugged at runtime** (Frida, Objection — hook any function)

**Assumption**: Anything in the mobile binary is visible to the attacker. Every API call can be intercepted and replayed.

## Attack Surface 1: Insecure Storage

### The Problem
```typescript
// VULNERABLE — AsyncStorage is NOT encrypted
import AsyncStorage from '@react-native-async-storage/async-storage'
await AsyncStorage.setItem('auth_token', token)
await AsyncStorage.setItem('api_key', apiKey)
await AsyncStorage.setItem('user_data', JSON.stringify(sensitiveData))
// On Android: stored in plaintext XML in /data/data/com.app/
// On iOS: stored in plaintext plist in app sandbox
// A rooted/jailbroken device can read these trivially
```

### The Fix
```typescript
// SECURE — use encrypted storage
import * as SecureStore from 'expo-secure-store'

// iOS: Keychain (hardware-backed encryption)
// Android: Keystore (hardware-backed encryption)
await SecureStore.setItemAsync('auth_token', token)
await SecureStore.setItemAsync('refresh_token', refreshToken)

// For non-sensitive data, AsyncStorage is fine
await AsyncStorage.setItem('theme', 'dark')  // Not sensitive
await AsyncStorage.setItem('onboarding_complete', 'true')  // Not sensitive
```

### Storage Decision Matrix
| Data Type | Storage | Encryption |
|-----------|---------|------------|
| Auth tokens | SecureStore / Keychain | Hardware-backed |
| API keys | SecureStore / Keychain | Hardware-backed |
| User PII | SecureStore / Keychain | Hardware-backed |
| Preferences | AsyncStorage | Not needed |
| Cache data | AsyncStorage | Not needed |
| Temp files | Cache directory | Cleared on app close |

### Detection in Code Review
- [ ] Search for `AsyncStorage.setItem` — is any sensitive data stored?
- [ ] Search for tokens, keys, passwords stored in plain storage
- [ ] Check if `expo-secure-store` is in dependencies
- [ ] Verify sensitive data uses SecureStore, not AsyncStorage

## Attack Surface 2: Deep Link Hijacking

### The Problem
Deep links (`myapp://path`) can be claimed by ANY app on the device. If your app handles auth callbacks via deep links, another app can intercept them.

```typescript
// VULNERABLE — custom scheme deep link for OAuth callback
// app.json
{
  "scheme": "myapp",
  // OAuth redirects to myapp://callback?code=AUTHORIZATION_CODE
  // Malicious app also registers myapp:// scheme
  // 50/50 chance malicious app gets the auth code
}
```

### The Fix: Universal Links / App Links
```typescript
// SECURE — use verified domain-based links
// app.json
{
  "ios": {
    "associatedDomains": ["applinks:myapp.com"]
  },
  "android": {
    "intentFilters": [{
      "action": "VIEW",
      "autoVerify": true,  // Android verifies domain ownership
      "data": [{ "scheme": "https", "host": "myapp.com", "pathPrefix": "/callback" }]
    }]
  }
}
// https://myapp.com/callback can ONLY be opened by your verified app
```

### Detection
- [ ] Check `app.json` / `app.config.js` for `scheme` (custom URL scheme)
- [ ] If custom scheme used for auth callbacks → FLAG
- [ ] Check if Universal Links (iOS) / App Links (Android) configured
- [ ] Verify `autoVerify: true` on Android intent filters
- [ ] Check if `apple-app-site-association` file deployed on domain

## Attack Surface 3: Certificate Pinning

### The Problem
Without certificate pinning, an attacker with a proxy (mitmproxy, Charles) can intercept ALL API traffic from the app, even HTTPS.

### Implementation (Expo)
```typescript
// expo-network-config approach
// Create android/app/src/main/res/xml/network_security_config.xml
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <domain-config cleartextTrafficPermitted="false">
    <domain includeSubdomains="true">api.yourapp.com</domain>
    <domain includeSubdomains="true">yourproject.supabase.co</domain>
    <pin-set expiration="2027-01-01">
      <pin digest="SHA-256">YOUR_PIN_HASH_1</pin>
      <pin digest="SHA-256">YOUR_PIN_HASH_2</pin><!-- Backup pin -->
    </pin-set>
  </domain-config>
</network-security-config>
```

### Detection
- [ ] Is `network_security_config.xml` present? (Android)
- [ ] Does it include pin-set for your API domains?
- [ ] Is there a backup pin? (Required for pin rotation)
- [ ] Does the pin have an expiration date?
- [ ] iOS: Is ATS (App Transport Security) properly configured?

## Attack Surface 4: OTA Update Security (Expo)

### The Problem
Expo's OTA updates download JavaScript bundles from EAS servers. If the update channel is compromised or MITM'd, malicious code is pushed to all users.

### Security Measures
```typescript
// app.json
{
  "updates": {
    "url": "https://u.expo.dev/your-project-id",
    "codeSigningCertificate": "./code-signing/certificate.pem",
    "codeSigningMetadata": {
      "keyid": "main",
      "alg": "rsa-v1_5-sha256"
    }
  }
}
// Code signing: updates are cryptographically signed
// Only updates signed with YOUR key are accepted
```

### Detection
- [ ] Is code signing configured for EAS updates?
- [ ] Is the signing key stored securely (not in repo)?
- [ ] Are update channels separated (production vs staging)?

## Attack Surface 5: JavaScript Bundle Exposure

### The Problem
React Native apps ship JavaScript bundles that can be extracted and read:
```bash
# Android: Extract APK
unzip app.apk -d extracted/
cat extracted/assets/index.android.bundle  # All your JS code

# iOS: Extract IPA
unzip app.ipa -d extracted/
cat extracted/Payload/App.app/main.jsbundle  # All your JS code
```

Attackers can read: API endpoints, hardcoded keys, business logic, validation rules.

### What This Means
- **NEVER hardcode secrets in mobile code** — they WILL be extracted
- **NEVER rely on client-side validation alone** — it can be bypassed
- **API keys in mobile apps ARE public** — design your backend accordingly
- **Obfuscation slows attackers but doesn't stop them**

### Mitigation
```typescript
// WRONG — secret in mobile code
const API_SECRET = 'sk_live_abc123'

// RIGHT — fetch secrets from authenticated endpoint
const { data: config } = await supabase.functions.invoke('get-config')
// Backend verifies auth before returning any sensitive config
```

## Attack Surface 6: Biometric Bypass

### The Problem
```typescript
// VULNERABLE — biometric result stored as simple boolean
const result = await LocalAuthentication.authenticateAsync()
if (result.success) {
  const token = await AsyncStorage.getItem('auth_token')
  // Attacker: hook authenticateAsync to always return { success: true }
  // Using Frida/Objection: trivial bypass
}
```

### Secure Pattern
```typescript
// SECURE — biometric gates access to Keychain-stored token
import * as SecureStore from 'expo-secure-store'

// Store token requiring biometric to retrieve
await SecureStore.setItemAsync('auth_token', token, {
  requireAuthentication: true,  // OS enforces biometric before access
  authenticationPrompt: 'Authenticate to access your account',
})

// Retrieval FAILS without valid biometric — OS-enforced, not app-enforced
const token = await SecureStore.getItemAsync('auth_token', {
  requireAuthentication: true,
})
```

## Attack Surface 7: Development Server Exposure (CVE-2025-11953)

React Native development server (Metro bundler) listens on port 8081. CVE-2025-11953: the development server was accessible from external networks, enabling RCE.

### Detection
- [ ] Development server not running in production builds
- [ ] `__DEV__` checks properly gate development features
- [ ] No debug bridges accessible in release builds
- [ ] React DevTools disabled in production

## Complete Mobile Review Checklist

### Storage
- [ ] Sensitive data in SecureStore/Keychain, not AsyncStorage
- [ ] No secrets hardcoded in JavaScript
- [ ] No sensitive data in logs (console.log in production)
- [ ] Cache cleared on logout

### Network
- [ ] Certificate pinning configured for API domains
- [ ] All traffic over HTTPS (no cleartext)
- [ ] API tokens sent via Authorization header, not URL params
- [ ] Timeout and retry limits on all network requests

### Authentication
- [ ] Deep links use Universal Links / App Links (not custom schemes) for auth
- [ ] Biometric authentication gates Keychain access (OS-enforced)
- [ ] Session tokens have expiration
- [ ] Logout clears all stored tokens and SecureStore entries

### Build Security
- [ ] Code signing configured for OTA updates
- [ ] No debug features in production builds
- [ ] ProGuard/R8 obfuscation enabled (Android)
- [ ] Hermes engine used (compiled bytecode harder to read than plain JS)

### Input/Output
- [ ] All user input validated before API calls (defense in depth, not security)
- [ ] WebView usage restricted (if any) — no `javaScriptEnabled` on untrusted content
- [ ] No `eval()` or dynamic code execution
- [ ] Clipboard access restricted for sensitive data

## References

For Supabase auth patterns on mobile, see `jwt-session-attacks` skill.
For API security, see the relevant API security skills.
