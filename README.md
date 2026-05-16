# Stip — Step Tracker iOS App

Pure black, streak-based step tracker. Built with SwiftUI + HealthKit.

---

## How to get the IPA on your iPhone (no Mac needed)

### Step 1 — Add your logo (optional)
Drop your logo PNG into:
```
Stip/Assets.xcassets/StipLogo.imageset/
```
Name the file exactly `StipLogo.png`.

---

### Step 2 — Push this folder to GitHub

1. Go to https://github.com/new → create a **private** repo called `Stip`
2. Upload this entire folder (drag the folder into the GitHub web UI, or use GitHub Desktop on Windows)

---

### Step 3 — Connect Codemagic

1. Go to https://codemagic.io → sign in with GitHub
2. Click **Add application** → select your `Stip` repo
3. Choose **"I use codemagic.yaml"** when asked
4. Go to **Teams → Integrations → Apple Developer Portal**
5. Sign in with your Apple ID (free account works for development/sideload)
6. In your app settings → **Environment variables**, add:
   - `CM_TEAM_ID` = your 10-character Apple Team ID
     (find it at https://developer.apple.com/account → Membership)

7. Click **Start build**

Codemagic will build on a real Mac in the cloud and email you the `.ipa`.

---

### Step 4 — Install on iPhone with Sideloadly (Windows)

1. Download **Sideloadly** from https://sideloadly.io (free, Windows)
2. Install **iTunes** (from Apple's site, NOT Microsoft Store)
3. Plug your iPhone into Windows via USB → trust the computer on your phone
4. Open Sideloadly → drag your `.ipa` into the window
5. Enter your Apple ID email → click Start
6. On your iPhone: **Settings → General → VPN & Device Management** → trust your Apple ID
7. Open Stip → grant HealthKit + Notifications when asked

**The app expires every 7 days** (free Apple ID limit).  
To renew: open Sideloadly → drag the same `.ipa` again → done in 30 seconds.

---

## File structure

```
StipRepo/
├── Stip.xcodeproj/
│   └── project.pbxproj       ← Xcode project (do not edit)
├── Stip/
│   ├── Sources/
│   │   ├── StipApp.swift
│   │   ├── ContentView.swift
│   │   ├── StepViewModel.swift
│   │   ├── NotificationManager.swift
│   │   ├── StreakManager.swift
│   │   ├── DashboardCard.swift
│   │   └── CircularProgressView.swift
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/   ← drop a 1024×1024 PNG here for app icon
│   │   └── StipLogo.imageset/    ← drop StipLogo.png here
│   └── Stip.entitlements
├── codemagic.yaml
├── exportOptions.plist
└── .gitignore
```

---

## Features
- HealthKit step tracking (midnight → midnight)
- 2,000 step daily goal
- Circular progress ring
- Today / Week / Month / Year breakdown cards
- Streak system (persisted in UserDefaults)
- Smart notifications — reminder OR congrats, never both
- Pure black UI, SF Pro, glass cards
