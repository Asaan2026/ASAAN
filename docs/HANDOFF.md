# HANDOFF — Asaan: app fixes, notifications, push

**Last updated:** 2026-10-23
**Read this first.** It says what is live, what is proven, and what is genuinely left.

---

## 1. Status at a glance

| Item | State |
|---|---|
| Six reported app/store bugs fixed in code | ✅ Done |
| Backend pushed to the live server (`asaandotaf.store`) | ✅ Done — deployed over SSH |
| FCM credentials on the live server | ✅ Done — were already in `.env.docker` |
| FCM key file readable by PHP on the server | ✅ Fixed — was `root:root 600`, now `www-data:www-data 400` |
| Push proven on the **live** server | ✅ Done — Google token obtained (1024 chars), welcome notification created |
| Storefront download link → v2.7.1 | ✅ Done — assets rebuilt on the server and verified in the bundle |
| Latest deploy | ✅ Done — run `39998919508`, success in 9m51s (image rebuilt from git) |
| Tests | ✅ 13/13 passing (suite is now hermetic — no real network calls) |
| Android AAB built (Play Store) | ✅ Built — **not uploaded** |
| Android APK published | ✅ GitHub release `Asaan-v2.7.1` (`asaan-latest.apk`, HTTP 200, 69.5 MB) |
| App version | ✅ `2.7.1+11` |
| iOS `GoogleService-Info.plist` | ❌ Still missing (needs the Firebase console) |
| Play Store upload | ❌ Needs the owner's Play Console |
| Confirming a real phone buzzes | ❌ Needs one admin-signed-in phone |

---

## 2. Hosting — there is NO Vercel

The live store is a **Laravel app in Docker on a VPS**. Nothing about this project
runs on Vercel; do not add Vercel.

- Live site: `https://asaandotaf.store` → `162.35.125.232`
- VPS: `ssh -i "$env:USERPROFILE\.ssh\asaan_vps" root@162.35.125.232`
- Repo on server: `/opt/asaan`
- Container: `asaan_online_store_app` (PHP-FPM + nginx + supervisor), DB container
  `asaan_online_store_db`
- Git remote on the server: `https://github.com/Asaan2026/ASAAN.git`
- DNS points straight at the VPS; there is no CDN/host in front of it.

### How configuration reaches the app

`docker-compose.yml` uses `env_file: .env.docker`. On every boot `entrypoint.sh`
**rewrites** `/var/www/html/.env` from the container's OS environment, including:

```
FCM_PROJECT_ID=asaan-eb1c9
FCM_CREDENTIALS_PATH=/var/www/html/secrets/asaan-eb1c9-firebase-adminsdk-fbsvc-070abffefe.json
FCM_ANDROID_CHANNEL=
```

Those already exist in `/opt/asaan/.env.docker` (lines 33–35). Editing the
container's `.env` by hand is pointless — it is regenerated on every restart.
**Change `.env.docker` instead**, then `docker compose up -d`.

The Firebase key is mounted read-only from the host:

```
./secrets:/var/www/html/secrets:ro
```

It was owned `root:root` mode `600`, so PHP (running as `www-data`) could not read
it and push would have silently failed. Fixed to `www-data:www-data`, mode `400`,
directory `700`. If the file is ever re-copied, re-apply that ownership.

---

## 3. What was deployed, and how

Because the GitHub account logged into `gh` has only read access to
`Asaan2026/ASAAN`, the code was deployed by copying files to the VPS and into the
running container:

```
scp <file> root@162.35.125.232:/opt/asaan/<path>
ssh ... "docker cp /opt/asaan/<path> asaan_online_store_app:/var/www/html/<path>"
```

Files deployed:

- `packages/Cartxis/API/Observers/WelcomeNotificationObserver.php` (new)
- `packages/Cartxis/API/Providers/APIServiceProvider.php`
- `packages/Cartxis/API/Services/CustomerNotificationService.php`
- `packages/Cartxis/API/Http/Controllers/V1/NotificationController.php`
- `templates/storefront/general/cartxis-default/resources/views/components/AppDownloadBlock.vue`
  — then `npm run build` inside the container (Vite), so the storefront serves v2.7.1.

Caches cleared (`config`, `route`, `view`, `cache`) and the container restarted.

> These files are now also **committed and pushed** to the client repo, so the next
> normal deploy rebuilds the same thing from git. `docker cp` changes alone would be
> lost when the container is recreated.

---

## 4. Proof that push works on the live server (not just locally)

Run as `www-data` inside the live container, bootstrapping Laravel:

```
SENDER=Cartxis\API\Services\Push\FcmPushSender
CONFIGURED=yes
GOOGLE_TOKEN=1024 chars
WELCOME_CREATED=1
```

What that means:

1. PHP can read the service-account key (permissions fix works).
2. The server signs a JWT and exchanges it with Google for a real access token.
3. The `User` observer is registered and creates a welcome notification on the live DB.

The only thing not yet observed is a physical phone receiving the notification.

---

## 5. Remaining work (all owner-side)

### A. Prove the buzz (2 minutes)
1. Sign in to the phone app with the **admin** account (so the device token exists).
2. Website → **Admin → Settings → Notifications**.
3. It should show project `asaan-eb1c9` and credentials present.
4. Press **Send test push**.

If nothing arrives, check, in order: notification permission on the phone; the
account signed in after this deploy; `docker exec asaan_online_store_app ls -l /var/www/html/secrets`.

### B. Play Store
Upload `mobile/build/app/outputs/bundle/release/app-release.aab` in Play Console →
Production → new release. The APK on the GitHub release is for direct install.

### C. iOS (only if wanted now)
1. Firebase console → project `asaan-eb1c9` → add/confirm the iOS app (bundle id).
2. Download `GoogleService-Info.plist`.
3. Put it at `mobile/ios/Runner/GoogleService-Info.plist`, add it to the Runner
   target in Xcode.
4. `cd mobile && flutter build ipa --release` on a Mac, upload to App Store Connect.

---

## 6. How to deploy from now on

Normal path (preferred): commit and push to `main` on `Asaan2026/ASAAN`.
`.github/workflows/deploy.yml` SSHes to the VPS and runs `/opt/asaan/deploy.sh`,
which does `git reset --hard origin/main`, rebuilds the image, and restarts compose.

The push needs a token with write access to the client repo. Use it per command and
**never store it** in `.git/config`:

```powershell
$env:ASAAN_TOKEN = "<token>"
git push "https://x-access-token:$env:ASAAN_TOKEN@github.com/Asaan2026/ASAAN.git" main
Remove-Item Env:\ASAAN_TOKEN
```

The `client` remote in `.git/config` must stay clean:
`https://github.com/Asaan2026/ASAAN.git`.

A full image rebuild takes several minutes (composer + npm + Vite). The workflow
timeout is 40 minutes.

### Quick manual hotfix (no git push)
1. `scp` the file to `/opt/asaan/...`
2. `docker cp` it into `asaan_online_store_app:/var/www/html/...`
3. `docker exec asaan_online_store_app php artisan config:clear` (and `view:clear`
   for Blade/Vue output)
4. Restart the container if PHP files changed.

Remember step 1 **and** step 2 — there is no bind mount for the code.

---

## 7. Verification commands

```bash
# service
curl -s -o /dev/null -w "%{http_code}\n" https://asaandotaf.store      # 200

# download link
curl -sI https://github.com/Asaan2026/ASAAN/releases/download/Asaan-v2.7.1/asaan-latest.apk

# which download tag the storefront bundle carries
docker exec asaan_online_store_app grep -roh "Asaan-v2.7.[0-9]" public/build | sort -u
# → Asaan-v2.7.1

# FCM health (script must run as www-data)
docker exec -u www-data asaan_online_store_app php /tmp/asaan_verify.php
```

---

## 8. Environment notes / gotchas

- **Windows PowerShell 5.1**: no `&&`; use `cmd1; if ($?) { cmd2 }`. Do not put
  `&&`/`||` inside an ssh command wrapped in double quotes — PowerShell parses them.
  Best: write the remote script to a file, `scp` it, then `ssh ... "bash /tmp/x.sh"`.
- Piping a here-string to `ssh ... "bash -s"` also works, but nested quotes get
  mangled; a script file is more reliable.
- `docker ps --format "{{.Names}}"` gets mangled through PowerShell quoting; put it
  in a script file.
- Local Windows PHP has no CA bundle, so outbound HTTPS from PHP fails locally
  (`cURL error 60`). The test suite no longer makes real network calls
  (`Http::fake()` in `MobileNotificationsTest`), so this cannot fail tests again.
- Do not run `php artisan tinker --execute=...` with class names containing `\`
  through PowerShell; write a temp PHP script instead (that is how FCM was verified).
- Mobile package: `vortex_app`, app id `com.cartxis.app`.
- Never commit `.env`, `.env.docker`, or anything in `secrets/`.

---

## 9. Files changed in this work (all committed)

**Backend**
- `packages/Cartxis/API/Observers/WelcomeNotificationObserver.php` (new)
- `packages/Cartxis/API/Providers/APIServiceProvider.php`
- `packages/Cartxis/API/Services/CustomerNotificationService.php` (`pushPendingWelcome`)
- `packages/Cartxis/API/Http/Controllers/V1/NotificationController.php`
- `tests/Feature/API/MobileNotificationsTest.php` (+ hermetic HTTP fake)

**Storefront**
- `templates/storefront/general/cartxis-default/resources/views/components/AppDownloadBlock.vue`

**Mobile (Flutter)**
- `lib/presentation/screens/main/main_navigation_screen.dart` — per-tab stacks,
  Back behaviour, exit confirmation
- `lib/presentation/screens/home/home_screen.dart` — cards open the product page
- `lib/routes/app_router.dart`, `lib/app.dart` — route tracking/observer
- `lib/core/utils/notification_navigator.dart` — tap routing without duplicates
- `lib/l10n/app_{en,fa,ps}.arb` + generated `app_localizations*.dart`
- `pubspec.yaml` → `2.7.1+11`

**Docs**
- `docs/HANDOFF.md` (this file), `docs/deploy-checklist.md`
