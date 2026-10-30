# Trying the Asaan app on an iPhone

This explains how to get the Asaan app onto an iPhone for testing, without
paying Apple anything. It is written for the person doing the testing, not for
a developer.

**Read this first.** What you are installing is a *test* build. It runs for
**7 days**, then stops opening until it is installed again. That is Apple's
rule for apps installed without a paid developer account, and nothing can
change it. It is fine for trying the app out. It is not a way to give the app
to customers — see [Putting it in front of real
customers](#putting-it-in-front-of-real-customers) at the end.

---

## What you need

- An iPhone running iOS 13 or newer.
- A Windows PC or a Mac, once. The phone connects to it by cable the first
  time.
- An Apple ID. Your normal one is fine, and it stays free — you are not
  signing up for anything.
- The app file, `asaan-iphone-unsigned.ipa`.

---

## Installing it

1. **On the computer, install Sideloadly** from
   [sideloadly.io](https://sideloadly.io). It is free and runs on both Windows
   and Mac.

2. **Plug the iPhone into the computer** with its cable. On the phone, tap
   **Trust** if it asks whether to trust this computer.

3. **Open Sideloadly.** It should show your iPhone at the top. If it does not,
   unplug and replug the cable.

4. **Drag `asaan-iphone-unsigned.ipa` into the Sideloadly window.**

5. **Type your Apple ID** in the box Sideloadly shows, then press **Start**.
   It will ask for your Apple ID password. If your Apple ID uses two-factor
   sign-in, it will also ask for a code; see the note below if that gives
   trouble.

6. Wait. It takes a few minutes. Sideloadly says **Done** when it has
   finished.

7. **On the iPhone, allow the app to run.** Go to
   **Settings → General → VPN & Device Management**, tap your Apple ID under
   *Developer App*, and tap **Trust**.

   This step is required. Until you do it, tapping the app shows
   "Untrusted Developer" and nothing opens.

8. Open Asaan from the home screen.

---

## If something goes wrong

**"Unable to verify app" or "Untrusted Developer"**
Step 7 was skipped, or was done for a different Apple ID. Go back to
Settings → General → VPN & Device Management and tap Trust.

**Sideloadly asks for an app-specific password**
This happens when your Apple ID uses two-factor sign-in. Go to
[account.apple.com](https://account.apple.com), sign in, find
**App-Specific Passwords**, create one, and paste that into Sideloadly
instead of your normal password.

**"Maximum App ID limit reached"**
A free Apple ID can only register a limited number of apps in a week. Either
wait a few days, or use a different Apple ID.

**The app opens and immediately closes**
Usually the 7 days have run out. Install it again with the same steps.

---

## What will not work in this build

- **Push notifications.** The iPhone side of the notification service was
  never set up, so the app cannot receive them. Everything inside the app
  still works, including the notification list. This is not a bug to report.
- **Anything needing the App Store**, such as automatic updates.

Everything else — browsing, searching, the basket, accounts, checkout,
orders, reviews, languages — behaves as it does on Android.

---

## After 7 days

The app stops opening. To carry on testing, repeat the install steps. Nothing
is lost; it is the signature that expires, not the app.

Sideloadly can also refresh it automatically over Wi-Fi if you leave that
option on and the computer stays on the same network.

---

## Putting it in front of real customers

This build cannot do that, and no tool or service can change it. Apple only
lets an app onto other people's phones if it is signed by a **paid Apple
Developer Program membership**, which costs **$99 a year**.

Once that membership exists, the app can be distributed two ways:

- **TestFlight** — invite testers by email, no App Store review for internal
  testers, builds last 90 days.
- **The App Store** — public, requires Apple's review.

The build process is already set up and running on GitHub, so when the
membership is in place it only needs the signing details adding; the app
itself does not need rebuilding from scratch. See
[BUILD_AND_RELEASE.md](BUILD_AND_RELEASE.md).

In the meantime, iPhone customers are not stuck: the Asaan website can be
saved to the iPhone home screen and opens full screen with the Asaan icon,
like an app. The "Install on iPhone" button in the website footer shows them
how.
