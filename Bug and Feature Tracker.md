# Zener Wave - Bug & Feature Tracker

Last updated: 2026-03-12

---

## Legend
- Status: `[ ]` Open · `[~]` In Progress · `[x]` Done
- Priority: 🔴 High · 🟡 Medium · 🟢 Low

---

## Open Issues

No open issues.

---

## Pre-Submission Audit Fixes — 2026-03-12

Issues found during a full deep-dive audit before App Store submission. All critical and high severity issues resolved; medium and low issues addressed where practical.

- [x] 🔴 **A1 — Double game start** `ZenerGame.swift` / `ZenerGameView.swift` — `ZenerGame.init()` called `startNewGame()` then `onAppear` called it again, discarding the first deck. Fixed: removed `startNewGame` from `init()`; `onAppear` is the sole entry point.

- [x] 🔴 **A2 — Data loss risk on quick exit** `ZenerGameView.swift` — `GameSession` was inserted into `modelContext` without an explicit save. If the app was terminated immediately after a game, SwiftData's autosave may not have fired. Fixed: added `try? modelContext.save()` after insert.

- [x] 🔴 **A3 — Force unwrap crash risk** `ZenerGame.swift` — `symbols.randomElement()!` could theoretically crash. Fixed: replaced with `?? .circle` fallback.

- [x] 🔴 **A4/A5 — Task leak on view dismissal** `ZenerGameView.swift` — `flashTask` and `timerTask` were never cancelled when the view disappeared (e.g. navigating back mid-game). Fixed: added `.onDisappear` that cancels both tasks.

- [x] 🔴 **A6 — Simplified onAppear condition** `ZenerGameView.swift` — The previous multi-clause condition was fragile and could fail to start the game in edge cases. Fixed: simplified to `if game.roundCount != roundCount`.

- [x] 🔴 **A7 — Timed mode timeout biased toward circle** `ZenerGameView.swift` — When the countdown expired, the forced guess always used `ZenerSymbol.allCases.first!` (circle), skewing scores. Fixed: uses `randomElement() ?? .circle` for an unbiased forced guess.

- [x] 🟡 **A8 — timeRemaining initialised to hardcoded 5** `ZenerGameView.swift` — The countdown state started at 5 regardless of the user's AppStorage setting. Fixed: `onAppear` now syncs `timeRemaining = timedModeSeconds` before starting.

- [x] 🟡 **A9 — Dead code: purchaseCompleted Notification** `Zener_WaveApp.swift` — `Notification.Name.purchaseCompleted` was defined but never posted or observed. Removed.

- [x] 🟡 **A10 — Duplicate "Copy Version" button** `AboutView.swift` — The button appeared both in the Actions section and as a footer. Removed the footer duplicate.

- [x] 🟡 **A11 — No visual feedback on timed mode timeout** `ZenerGameView.swift` — When the countdown hit zero and auto-advanced, there was no indication to the player. Fixed: brief "Time's up!" banner shown in the streak indicator area.

- [x] 🟡 **A12 — Progress bar not animated** `ZenerGameView.swift` — Progress bar updated instantly on each guess. Fixed: `.animation(.easeInOut(duration: 0.3), value: game.progress)` applied.

- [x] 🟢 **A13 — Guess button accessibility labels** `ZenerGameView.swift` — Labels were just the symbol name (e.g. "Circle"). Updated to "Guess Circle" etc. for clearer VoiceOver context.

- [x] 🟢 **A14 — Decorative star icon missing accessibility hint** `WelcomeView.swift` — The ★ header icon had no accessibility attribute. Added `.accessibilityHidden(true)`.

- [x] 🟢 **A15 — Force-unwrap on Wikipedia URL** `WelcomeView.swift`, `AboutView.swift` — Both used `URL(string:)!`. Changed to optional binding; links are simply not shown if the URL ever fails to parse.

---

## New Features

### Low Priority (Open)

- [ ] 🟢 **F8 — Home Screen / Lock Screen Widget**
  A simple widget showing today's best score or last session summary. Low effort relative to the engagement it drives — users see it every time they unlock their phone.

- [ ] 🟢 **F10 — In-App Theme Toggle**
  The app currently follows the system appearance. An explicit in-app dark/light toggle in Settings or About would be a simple addition, especially if the app leans into a moody, mystical aesthetic in dark mode.

---

## Features — Implemented 2026-03-12

- [x] 🔴 **F16 — Reworked app flow**
  `WelcomeView` is now the navigation root. It shows the Zener cards explanation, Wikipedia link, and a live stats summary (games played, accuracy, best score) when history exists. A "Let's Play" button navigates to `RoundPickerView`, which shows 5/10/25 options with labels (Quick / Standard / Full). Selecting a length navigates directly into `ZenerGameView`. On the results screen, "Change Length" navigates back to `RoundPickerView`. `FirstLaunchPickerView` was removed.

- [x] 🟢 **F9 — Timed Mode**
  Toggle in Settings → Game. When enabled, a per-round countdown timer is shown in the round header. The duration is configurable (3s / 5s / 10s, shown when toggle is on). If the timer expires, the round auto-advances as a miss. The timer resets on each new round and is cancelled immediately when the player makes a guess.

- [x] 🟡 **F15 — Feedback Toggle (Blind Mode)**
  Toggle in Settings → Game ("Show Feedback"). When disabled: the correct-symbol flash is suppressed, sounds are skipped, haptics are skipped, and the streak indicator is hidden during play. The Sound Effects toggle is automatically disabled when feedback is off. Full results (scores, round list, symbol breakdown, interpretation) are still shown at the end.

---

## New Features — Implemented 2026-03-11 (session 2)

- [x] 🟡 **F11 — Settings Screen**
  New `SettingsView.swift` provides a single destination for all app preferences and links. Sections: Game (round count picker, sound effects toggle), App (History, About, Tip Jar), Support (Rate app, Privacy Policy). Accessible via a `gearshape` toolbar icon on the main game screen.

- [x] 🟡 **F12 — Settings Cog Toolbar Button**
  The three individual toolbar icon buttons (History, About, Tip Jar) in `ZenerGameView` have been replaced with a single gear icon that navigates to `SettingsView`. Cleaner toolbar, everything in one place.

- [x] 🟡 **F13 — TipJar Explicit Close Button**
  `TipJarView` now shows a persistent header row with a visible "Close" button. The previous `.cancellationAction` toolbar approach was not rendering because `NavigationStack` was removed in fix #12. The header also displays the "Tip Jar" title consistently.

- [x] 🟡 **F14 — First-Launch Round Picker**
  On first launch, a `FirstLaunchPickerView` sheet is shown before the game starts. The user selects 5, 10, or 25 rounds. The choice is saved to `@AppStorage("preferredRoundCount")` and `hasLaunchedBefore` is set so the picker never reappears. Subsequent launches start directly with the saved preference.

---

## Features — Implemented 2026-03-11

- [x] 🔴 **F1 — Session History & Statistics**
  Game results are now persisted across sessions using SwiftData (`GameSession.swift`). A new History view (`HistoryView.swift`) shows total games played, all-time accuracy, best score, and a recent trend indicator. Accessible from the chart.bar toolbar button. History can be cleared with the trash button.

- [x] 🔴 **F2 — Score Interpretation**
  Results screen now shows a statistical interpretation using binomial probability (`ScoreInterpreter.swift`). Displays a headline (e.g. "Above Chance"), a fun flavour line, and the odds of scoring that high by chance (e.g. "1 in 47"). Chance baseline (5/25, 20%) is shown for context.

- [x] 🔴 **F3 — Configurable Round Count**
  A segmented picker (5 / 10 / 25 rounds) is shown on the results screen. The preference persists across launches via `@AppStorage`. The next game uses the selected count immediately.

- [x] 🟡 **F4 — Sound Effects**
  Correct and incorrect guesses now play distinct system sounds (`SoundManager.swift`) using `AudioToolbox`. Complements the existing haptic feedback. Zero bundled audio assets required.

- [x] 🟡 **F5 — Streak Counter**
  A live streak indicator ("X in a row!") is shown during play. A "Streak broken" message briefly appears when a streak ends. Best streak is shown on the results screen. Streak state is tracked in `ZenerGame`.

- [x] 🟡 **F6 — Share Results**
  A Share button on the results screen lets users share their score and interpretation via the native share sheet. Text includes the score, round count, and interpretation headline.

- [x] 🟡 **F7 — Symbol Accuracy Breakdown**
  The results screen now includes a per-symbol accuracy section showing correct/total for each of the 5 Zener symbols with a colour-coded progress bar (green = perfect, red = zero correct).

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
