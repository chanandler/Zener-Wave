# Zener Wave — Changelog

All notable changes to Zener Wave are documented here.
Format: `[Version] — Date — Summary`

---

## [2.1] — 2026-03-12 — Pre-submission polish & new features

### New Features
- **Reworked app flow (F16):** New `WelcomeView` is the navigation root. Shows Zener cards info, Wikipedia link, and a stats summary if you've played before. "Let's Play" navigates to a dedicated `RoundPickerView` (Quick / Standard / Full), which then pushes into the game. Results screen now has "Change Length" and "Play Again" side by side.
- **Timed Mode (F9):** Optional countdown per round (3s / 5s / 10s). Configurable in Settings. Expired rounds auto-advance as a miss with a "Time's up!" banner. Timer cancels instantly when a guess is made.
- **Feedback Toggle / Blind Mode (F15):** Turn off per-guess feedback in Settings. When disabled: no symbol flash, no sounds, no haptics, no streak indicator during play. Full results still shown at the end. Mirrors a more rigorous ESP test protocol.
- **Settings Screen (F11/F12):** Single gear icon in the toolbar opens a dedicated Settings screen covering game preferences, History, About, Tip Jar, rate the app, and Privacy Policy.
- **Explicit Close button on Tip Jar (F13):** Persistent header row with a visible Close button replaces the invisible toolbar approach.
- **Zener cards info on Welcome & About screens:** Both screens now include a description of what Zener cards are, how the test works, and a link to the Wikipedia article.

### Bug Fixes & Code Quality
- Fixed double game start: `ZenerGame.init()` no longer calls `startNewGame()` — `onAppear` is the sole entry point.
- Fixed potential data loss: added explicit `modelContext.save()` after inserting a game session.
- Fixed crash risk: `randomElement()!` force unwrap replaced with safe fallback.
- Fixed task memory leaks: `flashTask` and `timerTask` now cancelled in `.onDisappear`.
- Fixed timed mode bias: timeout forced guess now uses a random symbol instead of always circle.
- Fixed `timeRemaining` not respecting the user's saved setting on first render.
- Fixed duplicate "Copy Version" button appearing twice in About.
- Removed dead `purchaseCompleted` Notification.Name definition.
- Animated progress bar between rounds.
- Improved VoiceOver accessibility labels on guess buttons ("Guess Circle" etc.).
- Decorative star icon marked `accessibilityHidden`.
- Wikipedia URL force-unwraps replaced with safe optional binding.

---

## [2.0] — 2025 — Major feature update

### New Features
- **Session History (F1):** Game results persisted with SwiftData. History view shows games played, all-time accuracy, best score, and recent trend. Clear history with the trash button.
- **Score Interpretation (F2):** Results screen shows binomial probability analysis — how likely your score was by chance, with a headline and flavour text.
- **Configurable Round Count (F3):** Choose 5, 10, or 25 rounds. Preference persisted via `@AppStorage`.
- **Sound Effects (F4):** Correct and incorrect guesses play distinct system sounds via AudioToolbox. No bundled audio assets.
- **Streak Counter (F5):** Live streak indicator during play. "Streak broken" message on miss. Best streak shown on results.
- **Share Results (F6):** Native share sheet on results screen with score and interpretation.
- **Symbol Accuracy Breakdown (F7):** Per-symbol correct/total with colour-coded progress bars on results screen.

### Bug Fixes
- Stacked DispatchQueue timers replaced with cancellable Tasks.
- `ZenerGame` marked `@MainActor` for thread-safe `@Published` mutations.
- `ForEach` identity changed from offset to stable UUID.
- `flashedSymbol` now cleared on Play Again.
- Double transaction finishing in StoreKit flow resolved.
- Duplicate toast on purchase resolved.
- `DispatchQueue` in purchase flow replaced with `Task.sleep`.
- Restore Purchases now correctly reports when nothing was found.
- Misleading toolbar button in About removed.
- Duplicate version string in About removed.
- Unused `ContentView.swift` deleted.
- Transaction listener now filters correctly and no longer fires spurious notifications.

---

## [1.0] — 2025 — Initial release

- Classic Zener card ESP guessing game with 5 symbols (circle, cross, wavy lines, square, star).
- 25-round game with score display.
- Haptic feedback on each guess.
- About screen with app version info.
- Tip Jar with StoreKit 2 in-app purchase.
