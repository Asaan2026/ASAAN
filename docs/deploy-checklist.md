# Asaan — Deploy & Release Checklist

This covers going live with the fixes: the product/category navigation, the
back button and exit confirmation, the notification-tap behaviour, and the
welcome notification plus working push.

There are **three separate things**. They do not all need the same steps.

---

## 1. Server (Laravel backend)

The code changes and the Firebase push settings live here. No phone rebuild is
needed for the server part.

### 1a. Deploy the code

Upload / pull the changed files:

- `packages/Cartxis/API/Observers/WelcomeNotificationObserver.php` (new)
- `packages/Cartxis/API/Providers/APIServiceProvider.php`
- `packages/Cartxis/API/Services/CustomerNotificationService.php`
- `packages/Cartxis/API/Http/Controllers/V1/NotificationController.php`

### 1b. Put the Firebase key on the server

The service-account key is a secret and is **not** in git. Copy it to the
server by hand:

```
secrets/asaan-eb1c9-firebase-adminsdk-fbsvc-070abffefe.json
```

Create the `secrets/` folder on the server if it is not there.

### 1c. Add two lines to the server `.env`

```
FCM_PROJECT_ID=asaan-eb1c9
FCM_CREDENTIALS_PATH=secrets/asaan-eb1c9-firebase-adminsdk-fbsvc-070abffefe.json
```

The path is relative to the project root (where `.env` lives).

### 1d. Clear the config cache

```
php artisan config:clear
php artisan cache:clear
```

Without this, Laravel keeps using the old `.env` and push stays off.

### 1e. Prove it works (do this before telling anyone)

1. Sign in to the phone app with your **admin** account.
2. On the website open **Admin -> Settings -> Notifications**.
3. The page now shows the Firebase project id and says the credentials are
   present.
4. Press **Send test push**.
5. Your phone should buzz within a few seconds.

If the phone buzzes, push is confirmed working from the server.

---

## 2. Android app

A **new build is required** — this is what puts the navigation, back button and
notification fixes on customers' phones.

Already done on this machine:

- Release bundle built: `mobile/build/app/outputs/bundle/release/app-release.aab`
- Signed with the release keystore (`mobile/android/app/asaan-release.jks`)

To publish:

1. Upload the `.aab` to **Google Play Console** -> your app -> Production -> new
   release.
2. Roll out.

Android push needs nothing more — the Firebase config file is already in the
app and the project matches.

To rebuild later (after any code change):

```
cd mobile
flutter build appbundle --release
```

---

## 3. iOS app (iPhone)

A **new build is required**, and one file is **missing**.

Right now there is no `GoogleService-Info.plist` in `mobile/ios/Runner/`, so
iPhone push will not work until it is added.

Steps:

1. In the Firebase console (project `asaan-eb1c9`), add an **iOS app** with the
   correct bundle id (if not already added).
2. Download `GoogleService-Info.plist`.
3. Put it at `mobile/ios/Runner/GoogleService-Info.plist`.
4. Open the iOS project in Xcode so the file is added to the Runner target.
5. Build and archive:

```
cd mobile
flutter build ipa --release
```

6. Upload to App Store Connect.

Everything else (the navigation and notification fixes) comes along in the same
build.

---

## Quick summary table

| What | New app build? | Server change? |
|---|---|---|
| Navigation / back button / notification-tap fixes | Yes (Android + iOS) | Deploy code |
| Welcome notification | No extra build | Deploy code (observer) |
| Firebase push credentials | No | `.env` + `config:clear` |
| Android push | Already configured | — |
| iPhone push | Yes, after adding the plist | — |

---

## Notes

- The `secrets/` folder is git-ignored on purpose. Never commit the key.
- The admin Notifications page has a **Send test push** button — use it any time
  to confirm push still works.
- If a phone never buzzes, check in this order: (1) `config:clear` was run,
  (2) the key file exists at the path in `.env`, (3) the customer signed in on
  that phone after the deploy, (4) notifications are allowed for the Asaan app
  in the phone's settings.
