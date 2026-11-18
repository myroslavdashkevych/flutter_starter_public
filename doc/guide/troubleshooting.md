# Troubleshooting

**Here:** what to do when building, running or analyzing fails: the symptom, the fix and the
section that holds the rule behind it; a clean rebuild as the last resort.

**Not here:** the rule behind each fix (each row links to its section); the checks to run
before a change is done ([workflow.md](../workflow.md), Verification).

## By symptom

| Symptom | What to do | Rule |
|---|---|---|
| After a checkout or pull, analyze or the build fails on `*.g.dart`, `*.freezed.dart`, `*.config.dart` or `app_localizations.dart` | `fvm dart run build_runner build`, then `fvm flutter gen-l10n`: generated files are not committed | [setup.md](setup.md), Generated code |
| A run without `--flavor` fails, or the app fails at startup on an unknown flavor | Pass `--flavor` and `--dart-define-from-file` on every run, or use the committed Android Studio run configurations | [setup.md](setup.md), Flavors |
| The IDE shows errors that `fvm flutter analyze` does not | The IDE uses another Flutter SDK: point it to `.fvm/flutter_sdk` | [setup.md](setup.md), Flavors |
| The build broke without any change in the repository | A new Flutter stable release arrived, since `.fvmrc` tracks `stable`. Adapt the code or packages to it, or pin an exact version in a project created from the template | [setup.md](setup.md), FVM |
| Android: the build fails at `processDevDebugGoogleServices` with `No matching client found for package name` | The Firebase configs do not match the applicationId: regenerate them with `flutterfire configure` | [new-project.md](new-project.md), Connect your own Firebase projects |
| iOS: the build fails in a FlutterFire build phase | Install the FlutterFire CLI: every iOS build calls it | [setup.md](setup.md), Firebase |
| iOS shows an old launch screen; Android 12 skips the splash when started from the IDE | Reinstall the app on iOS; launch from the app icon on Android | [setup.md](setup.md), Native splash |
| None of the above | A clean rebuild (below) | — |

## Clean rebuild

1. If `build/symbols/` holds the symbols of a store build, copy them out first:
   `flutter clean` deletes `build/` ([store-release.md](store-release.md), Crashlytics
   symbols).
2. Rebuild:

   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm dart run build_runner build
   fvm flutter gen-l10n
   ```

3. iOS only, if Swift packages still fail to resolve: in Xcode, File → Packages → Reset
   Package Caches. iOS plugins use Swift Package Manager, so there are no Pods to delete
   ([setup.md](setup.md), Flavors).
