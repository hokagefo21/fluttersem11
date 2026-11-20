# SRS 11: Clean Architecture for Firebase registration

This is a refactor of the existing Flutter registration app from Lab 7. The commit history includes the original app and its Android configuration. Users can still create an account, save a profile, receive a push notification, request another notification, and start a new registration. [Original project](https://github.com/hokagefo21/flutterseminar7)

## New feature: a local registration draft

Enter any contact field, then tap the save draft button below the form. Close the app completely, reopen it, and tap restore. The draft contains only the name, email, and phone number. The password field is always empty after restoration. Users can explicitly remove a draft. A successful registration also clears it. If local cleanup fails, the registration stays successful and cleanup can be retried.

## Architecture

| Layer | Responsibility | Start here |
| --- | --- | --- |
| Domain | Contact and profile entities, notification state, validation, repository contracts, and one use case per action | [Entities](lib/src/domain/entities/registration.dart), [contracts](lib/src/domain/repositories/contracts.dart), [use cases](lib/src/domain/usecases/registration_actions.dart) |
| Data | Firebase Auth, Realtime Database, FCM, local notifications, and SharedPreferences. Repository implementations map DTOs to entities and translate exceptions to domain failures. | [Data sources](lib/src/data/datasources), [mappers](lib/src/data/mapper), [repositories](lib/src/data/repositories) |
| Presentation | Cubit owns submission, retries, notification updates, and draft state. The page renders domain entities and delegates actions to the Cubit. | [Cubit](lib/src/presentation/bloc/registration_cubit.dart), [page](lib/src/presentation/pages/registration_page.dart), [widgets](lib/src/presentation/widgets) |
| Dependency injection | The composition root constructs platform clients, data sources, repositories, use cases, and the Cubit in dependency order. | [Composition root](lib/dependencies.dart) |

Domain uses plain Dart. The form checks the same validation rules as the registration use case. Presentation receives explicit empty, loading, success, and error states. An in-flight action disables repeat submission. On retry after a database failure, the remote source reuses the current account when its email matches. A late send acknowledgement preserves a push receipt that already reached the device.

## Error handling

| Condition | Domain result |
| --- | --- |
| No connection or timeout | `NetworkFailure` |
| HTTP 500 or Firebase internal server error | `ServerFailure` |
| HTTP 401/403 or Firebase permission failure | `UnauthorizedFailure` |
| HTTP 400 or invalid registration input | `ValidationFailure` |
| Too many attempts | `RateLimitFailure` |
| Local storage failure | `StorageFailure` |
| Unrecognized error | `UnknownFailure` |
| No draft on the device | `Empty<ContactDraft>` |

The UI displays localized messages. Raw exception strings, credentials, and registration tokens are excluded from user-facing errors. [Exception classification](lib/core/rest_client/data_exception.dart) | [Failure mapping](lib/src/data/mapper/failure_mapper.dart)

## Run on Android

1. Open the directory containing `pubspec.yaml` in Android Studio. Select an Android emulator with Google Play Services.
2. For real push delivery, run `start-push-server.cmd` on Windows and leave its console open. The worker uses the owner's Firebase CLI session for `lab7-uib`. If that session has expired, run `npx firebase-tools@latest login`. One worker serves both assignments.
3. Run the following commands from the project root and grant notification permission on the emulator.

```sh
flutter pub get
flutter run
```

The app retains the original Android package `com.example.untitled` and Firebase project. Android installs it as an update when the same package and signing key are already present. Local draft storage requires no network. Cloud registration and FCM delivery need internet access.

## Verification

```sh
flutter analyze
flutter test
flutter build apk --debug
```

The Flutter suite covers domain validation, error classification, DTO mapping, local draft operations, retry, empty state, duplicate submission, notification ordering, UI interaction, and import boundaries. To run the three inherited worker tests, change into `functions`, run `npm ci`, then run `npm test`.

On Jarvis, static analysis passed, all 21 Flutter tests and three worker tests passed, and the debug APK built for the Android API 36 x64 emulator. On the emulator, the contact draft survived a full process restart, restoration left the password blank, the profile was saved to Firebase, and the app received the worker's foreground push. [Restored draft](docs/evidence/srs11-draft.png) | [Received push](docs/evidence/srs11-received.png)
