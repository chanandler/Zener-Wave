# Zener Wave - Bug & Feature Tracker

Last updated: 2026-03-11

---

## Legend
- Status: `[ ]` Open · `[~]` In Progress · `[x]` Done
- Priority: 🔴 High · 🟡 Medium · 🟢 Low

---

## Open Issues

No open issues.

---

## Features

### High Priority

- [ ] 🔴 **F1 — Session History & Statistics**
  Persist game results across sessions using `SwiftData`. Track total games played, all-time average score, best score, and a score trend over time. This is the single most impactful addition — right now every game is forgotten the moment you tap Play Again, which removes any incentive to keep coming back.

- [ ] 🔴 **F2 — Score Interpretation**
  After a test, put the raw score in context. Random chance predicts exactly 5/25 (20%). Show a brief interpretation based on how far above or below chance the score is (e.g. "Above chance — statistically 1 in 47"), plus an optional fun flavour line ("Your psychic sensitivity appears to be... dormant."). Makes results more meaningful and far more shareable.

- [ ] 🔴 **F3 — Configurable Round Count**
  The game is hardcoded to 25 rounds. A simple picker (5 / 10 / 25) would make the app more accessible for casual sessions without changing anything about the core mechanic.

### Medium Priority

- [ ] 🟡 **F4 — Sound Effects**
  A subtle chime on a correct guess and a soft thud on incorrect would complement the existing haptic feedback. Use `AVFoundation` or `AudioServicesPlaySystemSound` for lightweight playback.

- [ ] 🟡 **F5 — Streak Counter**
  Display a live streak indicator during play ("3 in a row!") with a brief animation when a streak is broken. Streaks are emotionally engaging and make the session feel more dynamic without changing the core mechanic.

- [ ] 🟡 **F6 — Share Results**
  A share sheet button on the results screen letting users post their score as text or an image (e.g. "I scored 14/25 on the Zener Wave ESP test — can you beat it?"). Drives organic discovery with no backend required.

- [ ] 🟡 **F7 — Symbol Accuracy Breakdown**
  On the results screen, show a per-symbol accuracy table (e.g. "Waves: 4/5 correct · Star: 0/5 correct"). Some users will find they consistently perform differently on specific symbols, which leans into the mystique of the app.

### Low Priority

- [ ] 🟢 **F8 — Home Screen / Lock Screen Widget**
  A simple widget showing today's best score or last session summary. Low effort relative to the engagement it drives — users see it every time they unlock their phone.

- [ ] 🟢 **F9 — Timed Mode**
  An optional mode where each round has a countdown (e.g. 3 seconds to answer). Adds pressure and a distinctly different feel — impulsive vs. considered guessing.

- [ ] 🟢 **F10 — In-App Theme Toggle**
  The app currently follows the system appearance. An explicit in-app dark/light toggle in Settings or About would be a simple addition, especially if the app leans into a moody, mystical aesthetic in dark mode.

---

## Fixed — 2026-03-11 (Low Severity)

- [x] 🟢 **#3 ZenerGameView.swift** - `LazyVGrid` used for 5 static symbol buttons. **Fix:** Replaced with a plain `HStack`, which is simpler and avoids unnecessary lazy layout overhead.

- [x] 🟢 **#7 ZenerGameView.swift** - Toolbar button order relied on undocumented SwiftUI declaration ordering, which could differ on iPad or macOS Catalyst. **Fix:** Consolidated into a single `ToolbarItem` containing an `HStack` for explicit, reliable ordering.

- [x] 🟢 **#12 TipJarView.swift** - `NavigationStack` wrapped a sheet that had no push navigation; it was only used for the toolbar title and close button. **Fix:** Removed `NavigationStack`; title and toolbar are now applied directly to the content view.

- [x] 🟢 **#16 AboutView.swift** - `copyVersionToClipboard()` could re-trigger an already-visible alert if tapped repeatedly, causing a flicker. **Fix:** Added `guard !didCopyVersion else { return }` at the top of the function.

- [x] 🟢 **#20 Zener_WaveApp.swift** - `transactionListenerTask` was stored as `@State` on the App struct with no explicit cancellation path. **Fix:** Moved to a dedicated `AppDelegate` class; the task is started in `application(_:didFinishLaunchingWithOptions:)` and cancelled in `deinit`.

---

## Fixed — 2026-03-11 (Medium & High Severity)

- [x] 🔴 **#1 ZenerGameView.swift** - Stacked `DispatchQueue` timers: every symbol tap queued a new timer to clear `flashedSymbol` but previous timers were never cancelled. **Fix:** Replaced with a cancellable `Task` stored in `@State`; cancelled before each new one is scheduled.

- [x] 🔴 **#8 TipJarView.swift + Zener_WaveApp.swift** - Double transaction finishing: both `purchase()` and the app-level transaction listener called `transaction.finish()` and both triggered the toast. **Fix:** `purchase()` no longer calls `finish()`; the app-level listener is the sole authority.

- [x] 🔴 **#14 AboutView.swift** - The toolbar `info.circle` icon button called `copyVersionToClipboard()` instead of showing info, silently modifying the user's clipboard. **Fix:** Misleading toolbar button removed entirely.

- [x] 🟡 **#2 ZenerGameView.swift** - `ZenerGame` ObservableObject was not marked `@MainActor`, leaving `@Published` mutations without guaranteed main-thread isolation. **Fix:** Class marked `@MainActor`.

- [x] 🟡 **#5 ZenerGameView.swift** - `ForEach` in results list used `\.offset` as identity instead of the model's stable `UUID`. **Fix:** Changed to `id: \.element.id`.

- [x] 🟡 **#6 ZenerGameView.swift** - `flashedSymbol` was not cleared when "Play Again" was tapped, letting a stale flash persist into the new game. **Fix:** Play Again now cancels the pending flash task and resets `flashedSymbol` to `nil`.

- [x] 🟡 **#9 TipJarView.swift** - The `onReceive(.purchaseCompleted)` handler reset the toast timer on top of the one already started by `purchase()`, creating conflicting dismissal closures. **Fix:** Duplicate `onReceive` handler removed; toast is set only in the `purchase()` call path.

- [x] 🟡 **#10 TipJarView.swift** - `DispatchQueue.main.asyncAfter` was mixed inside `Task` blocks, creating unstructured, non-cancellable callbacks. **Fix:** Replaced with `try? await Task.sleep(for: .seconds(2))` in `@MainActor` Tasks throughout.

- [x] 🟡 **#11 TipJarView.swift** - "Restore Purchases" always showed "Restored purchases" toast even when nothing was restored. **Fix:** `restore()` now returns a `Bool`; the view shows "No purchases to restore" when no entitlements are found.

- [x] 🟡 **#15 AboutView.swift** - Version string was displayed twice in adjacent rows. **Fix:** Removed the inline duplicate; only the `AppVersionRow` remains.

- [x] 🟡 **#17 ContentView.swift** - `ContentView` was never used; app root is set directly to `ZenerGameView`. **Fix:** `ContentView.swift` deleted.

- [x] 🟡 **#19 Features.swift** - File was 478 lines of the same file-header comment copy-pasted repeatedly with no actual Swift code. **Fix:** File deleted.

- [x] 🟡 **#21 Zener_WaveApp.swift** - Transaction listener fired `purchaseCompleted` notification for any product, not just tips. **Fix:** Notification post removed from the listener; it now only calls `finish()`.
