# Store Release

Step-by-step checklist for submitting an app created from this starter to Google Play
and the App Store. The starter itself is not submitted.

Store rules and SDK behavior change. Everything below was checked on 2026-11-02 against
the sources listed at the end. Recheck them before a submission; you are responsible for
your own declarations.

## 1. Prepare the project

Finish `docs/new-project.md` first: the rename, your own Firebase projects, and the
replaced starter content (icons, splash, hosting pages, contact, privacy policy), with
the hosting pages deployed.

## 2. Declare the data

The two forms below describe what the starter collects with its current SDKs. Review them
against your app, including anything you added. The optional Analytics features (Google
signals, linked Google Ads account, Data Sharing Settings, a User-ID) add data that these
tables do not cover. The starter does not use them; check the Analytics property settings.

### App Privacy (App Store Connect)

| SDK | Apple data type | Linked to user | Tracking | Purpose |
|---|---|---|---|---|
| Firebase Auth | Email Address | Yes | No | App Functionality |
| Firebase Auth | User ID | Yes | No | App Functionality |
| Firebase Crashlytics | Crash Data | **Yes** | No | App Functionality |
| Firebase Crashlytics | Other Diagnostic Data | **Yes** | No | App Functionality |
| Firebase Analytics | Product Interaction | No | No | Analytics |
| Firebase Analytics | Device ID (app instance ID, Vendor Identifier) | No | No | Analytics |
| Firebase Analytics | Coarse Location (from a masked IP address) | No | No | Analytics |
| Firebase Cloud Messaging | Device ID (Firebase Installation ID, APNs token) | No | No | App Functionality |
| Firebase Cloud Messaging | Other Data Types (app and device details) | No | No | Analytics |
| Firebase Cloud Messaging | Other Diagnostic Data | No | No | App Functionality |
| Firebase Auth, Installations, GoogleDataTransport | Other Diagnostic Data | No | No | Analytics |

- **Crash Data is linked to the user even though the Crashlytics manifest and the Privacy
  Report say it is not:** the app itself attaches the Firebase UID with
  `setUserIdentifier` (`app/observability/crash_reporting_user_sync.dart`). If you remove
  that call, you may declare it as not linked.
- **Analytics is not in the Privacy Report.** The Analytics frameworks ship without a
  privacy manifest; Google states this and they are not on Apple's list of SDKs that need
  one. Declare its data from the table above, not from the report.
- **Email Address is not in the Privacy Report either:** the Firebase Auth manifest lists
  only User ID and diagnostic data, while Firebase documents the email as usage dependent.
  The app collects it for sign-up, so declare it.

### Data safety (Google Play Console)

| SDK | Data type | Collected | Shared | Optional | Purpose |
|---|---|---|---|---|---|
| Firebase Auth | Personal info: Email address | Yes | No | Yes: guests have no account | Account management, App functionality |
| Firebase Auth | Personal info: User IDs | Yes | No | Yes: guests have no account | Account management, App functionality |
| Firebase Crashlytics | App info and performance: Crash logs, Diagnostics | Yes | No | Yes: the Settings switch | Analytics, App functionality |
| Firebase Crashlytics | Device or other IDs: Crashlytics installation UUID, Firebase Installation ID | Yes | No | Yes: the Settings switch | Analytics |
| Firebase Analytics | App activity: App interactions | Yes | No | Yes: the Settings switch | Analytics |
| Firebase Analytics | Device or other IDs: Advertising ID, app instance ID | Yes | No | Yes: the Settings switch | Analytics |
| Firebase Analytics | Location: Approximate location (from a masked IP address) | Yes | No | Yes: the Settings switch | Analytics |
| Firebase Cloud Messaging | Device or other IDs: Firebase Installation ID | Yes | No | No | App functionality |

Also answer: data is encrypted in transit (yes); users can request deletion (yes, give
the `delete-account` URL). Firebase acts as a service provider, which is why the table
says "not shared"; recheck this if you enable Analytics Data Sharing Settings.

### Advertising ID

Analytics collects the Android Advertising ID, and the release APK contains the
`com.google.android.gms.permission.AD_ID` permission merged from the SDK. Choose one:

**Keep it.** In Play Console, under App content → Advertising ID, answer that the app uses
it, for Analytics. Keep it in the Data safety table above and in the privacy policy.

**Turn it off, if the app shows no ads.**

1. In `android/app/src/main/AndroidManifest.xml`, add `xmlns:tools` to `<manifest>`, then:
   ```xml
   <uses-permission
       android:name="com.google.android.gms.permission.AD_ID"
       tools:node="remove" />
   ```
   and inside `<application>`:
   ```xml
   <meta-data
       android:name="google_analytics_adid_collection_enabled"
       android:value="false" />
   ```
   The merged manifest also has `ACCESS_ADSERVICES_AD_ID` and
   `ACCESS_ADSERVICES_ATTRIBUTION`; remove them the same way if you do not need them.
2. Check that the permission is gone from a built APK:
   ```bash
   aapt2 dump permissions build/app/outputs/flutter-apk/app-prod-release.apk
   ```
3. iOS: build Analytics without IDFA support. This project uses Swift Package Manager, so
   the CocoaPods `$FirebaseAnalyticsWithoutAdIdSupport` flag does not apply. The
   `firebase_analytics` plugin reads an environment variable instead (it then uses
   `FirebaseAnalyticsCore`):
   ```bash
   FIREBASE_ANALYTICS_WITHOUT_ADID=true fvm flutter build ipa --flavor prod --dart-define-from-file=config/prod.json
   ```
   Set the variable in CI as well, because it must be present on every build. If you
   return to CocoaPods, use `$FirebaseAnalyticsWithoutAdIdSupport = true` in the Podfile.
4. In Play Console, answer that the app does not use the Advertising ID, remove it from
   Data safety and from the privacy policy.

These steps have not been run on the starter.

## 3. Switching to opt-in (optional)

The starter collects by default, and the user can turn it off in Settings. For collection
to stay off until the user agrees:

1. Set `USAGE_DATA_SHARING_DEFAULT` to `false` in both `config/*.json`.
2. Turn off native collection, so that nothing is sent before Dart code runs. The Dart
   setting cannot cover this: on the very first launch, the SDKs start before it.

   `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
   ```xml
   <meta-data
       android:name="firebase_analytics_collection_enabled"
       android:value="false" />
   <meta-data
       android:name="firebase_crashlytics_collection_enabled"
       android:value="false" />
   ```

   `ios/Runner/Info.plist`:
   ```xml
   <key>FIREBASE_ANALYTICS_COLLECTION_ENABLED</key>
   <false/>
   <key>FirebaseCrashlyticsCollectionEnabled</key>
   <false/>
   ```
3. Update the privacy policy: its "Your choices" section says that sharing is on by
   default.
4. Check it on a fresh install: before the switch is turned on, logcat must show
   `Sessions SDK disabled through data collection` and no Analytics events.

The runtime calls in `syncUsageDataCollection` override these flags once the user turns
the switch on, and the SDKs remember that value. `firebase_analytics_collection_deactivated`
and `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED` are a different thing: they disable
Analytics permanently, and runtime calls cannot turn it back on. Do not use them for
opt-in.

Opt-in lowers the accuracy of crash-free and event metrics. Whether you need it depends on
your legal requirements in each market.

### How the switch behaves

- It stops Analytics immediately. Dart errors stop reaching Crashlytics immediately.
- Crashlytics itself applies `false` only from the next launch, so a native crash in the
  same session can still be reported. The privacy policy says this.
- Firebase Sessions stops from the next launch, together with Crashlytics.
- While collection is off, Crashlytics stores crashes on the device and sends them once
  collection is turned on. `FirebaseCrashReportingService` deletes them when collection is
  off, so that turning it on later does not upload them.
- It does not affect notifications (`docs/features.md` section 5).

## 4. Push notifications

- FCM runs in FID mode: `firebase_messaging_installation_id_enabled` in
  `AndroidManifest.xml`, with `FirebaseMessaging.register()` and `onRegistered`.
  `docs/features.md` section 6 has the details.
- **A backend must send with the target `fid`.** Registration tokens from `getToken` are
  not used.
- **Check any third-party push service for FID support before adopting it.**
- The FID is only logged by the starter: a real app must send it to its backend.
- **iOS needs an APNs key** from a paid Apple Developer Program membership. Create the key
  in the Apple Developer portal and upload it in Firebase Console → Project settings →
  Cloud Messaging, in the prod project and in the dev project. Without it, `register()`
  fails on every launch, which is logged as a warning.
- Send a test message on a real iOS device before submitting.

## 5. Data for both consoles

- [ ] **Test account for reviewers.** The sign-in screen is reachable, so give reviewers
  an email and a password for an account in the prod project. Keep it working, and do not
  use the account yourself: reviewers may delete it, as the app allows. Recreate it before
  every submission.
- [ ] **URLs:**
  | | Google Play | App Store Connect |
  |---|---|---|
  | `/privacy` | App content → Privacy policy | App Privacy → Privacy Policy URL |
  | `/delete-account` | App content → Data safety → the data deletion questions ([source](https://support.google.com/googleplay/android-developer/answer/13327111); it does not give the field's exact label) | Not requested; reachable from the policy |
  | `/support` | Store listing → Contact details, website | Version → Support URL |

## 6. Android

- [ ] **Upload key.** Create it once and back it up outside the repository:
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] **`android/key.properties`.** Gradle reads it when it exists; without it, release
  builds are signed with the debug key. It is in `.gitignore`, like `*.jks` and
  `*.keystore`:
  ```properties
  storePassword=<password>
  keyPassword=<password>
  keyAlias=upload
  storeFile=<absolute path, or relative to android/app>
  ```
  Check the signer of a release build: it must not be `CN=Android Debug`.
- [ ] **AAB.** New apps must publish with the Android App Bundle on Google Play, since
  August 2021 ([source](https://developer.android.com/guide/app-bundle)):
  ```bash
  fvm flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json
  ```
- [ ] **Play App Signing.** Enroll when you create the app: Google keeps the app signing
  key, and your key is the upload key. Then add the SHA-1 of the app signing key (Play
  Console → Setup → App signing) to the API key restriction and to the Firebase Android app
  (`docs/setup.md` section 5.4).
- [ ] **App content forms.** Privacy policy, App access (the test account), Ads, Content
  rating (the IARC questionnaire), Target audience, Data safety, Advertising ID.
- [ ] **Closed testing for new personal accounts.** Before production access, a personal
  account created after November 13, 2023 needs a closed test with at least 12 testers
  opted in for 14 consecutive days. A tester who opts out and back in restarts the count
  ([source](https://support.google.com/googleplay/android-developer/answer/14151465)).
  Start this early.
- [ ] **Platform.** `targetSdk` is set explicitly in `android/app/build.gradle.kts`. Check
  that it meets the current Play target API requirement. The starter's 16 KB page size
  check: `zipalign -c -P 16 -v 4 <apk>` and `llvm-readelf -l` on each `.so` (all `LOAD`
  segments aligned to at least `0x4000`). Repeat it after adding native plugins.
  Edge-to-edge and predictive back were checked on the starter; check them again for your
  own screens.

## 7. iOS

- [ ] **Xcode 26 or later.** Uploads must be built with the iOS 26 SDK (required since
  April 28, 2026).
- [ ] **App Store Connect.** Create the app record with the prod bundle ID; fill in the
  metadata, screenshots, age rating questions and export compliance.
  - **Check the version on the app page.** It must not be higher than `version` in
    `pubspec.yaml` (App Store Connect may suggest 1.0 for a new app, while the project
    starts at 0.0.1). A build with a lower version is not rejected with an error: the
    upload reports success, but the build never appears in TestFlight. Set the page to
    the project's version, or raise `version` in `pubspec.yaml` to the page's version.
- [ ] **App Privacy.** Use the table in section 2.
- [ ] **Build:**
  ```bash
  fvm flutter build ipa --flavor prod --dart-define-from-file=config/prod.json
  ```
  If you archive from Xcode instead, run a `flutter build` for prod first: Xcode takes the
  Dart defines from `ios/Flutter/Generated.xcconfig`, which the last Flutter command wrote.
- [ ] **Privacy Report.** In Xcode: Product → Archive with the `prod` scheme, then
  Organizer → right-click the archive → Generate Privacy Report. Check that:
  - `Errors Encountered` is absent;
  - Tracking is `NO` everywhere;
  - it lists User ID, Device ID, Crash Data, Other Diagnostic Data and Other Data Types;
  - Analytics is absent, which is expected (section 2).

  Then upload the build and watch for an email about missing manifests or API declarations
  (`ITMS-91061`, `ITMS-91053`). **Not confirmed in Apple's documentation:** the pages could
  not be read, so this rests on reports in the Apple Developer Forums
  ([ITMS-91061](https://developer.apple.com/forums/thread/774960),
  [ITMS-91053](https://developer.apple.com/forums/thread/750057)). Repeat after adding a
  plugin or an SDK.

## Sources

- [Apple: upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Apple: SDKs that need a privacy manifest](https://developer.apple.com/support/third-party-SDK-requirements/)
- [Firebase: data collected by SDKs on Android](https://firebase.google.com/docs/android/play-data-disclosure)
- [Firebase: data collected by SDKs on iOS](https://firebase.google.com/docs/ios/app-store-data-collection)
- [Firebase: privacy and security](https://firebase.google.com/support/privacy)
- [Firebase: Analytics data collection on Android](https://firebase.google.com/docs/analytics/android/configure-data-collection)
- [Firebase: Analytics data collection on iOS](https://firebase.google.com/docs/analytics/configure-data-collection)
- [Firebase: Crashlytics opt-in on Android](https://firebase.google.com/docs/crashlytics/android/customize-crash-reports)
- [Firebase: Crashlytics opt-in on iOS](https://firebase.google.com/docs/crashlytics/ios/customize-crash-reports)
- [Google Analytics: Google Play Data safety](https://support.google.com/analytics/answer/11582702)
- [Google Analytics: App Store privacy details](https://support.google.com/analytics/answer/10285841)
- [Google Analytics: data collection](https://support.google.com/analytics/answer/11593727)
- [Play Console: Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248)
- [Play Console: testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Play Console: account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Android: Android App Bundle](https://developer.android.com/guide/app-bundle)
