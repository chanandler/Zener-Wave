# Zener Wave - Bug & Feature Tracker

Last updated: 2026-03-11

---

## Legend
- Status: `[ ]` Open · `[~]` In Progress · `[x]` Fixed
- Severity: 🔴 High · 🟡 Medium · 🟢 Low

---

## High Severity

- [x] 🔴 **#1 ZenerGameView.swift** - Stacked `DispatchQueue` timers: Every symbol tap queued a new timer to clear `flashedSymbol` but previous timers were never cancelled. **Fixed:** Replaced with a cancellable `Task` stored in `@State`; cancelled before each new one is scheduled.

- [x] 🔴 **#8 TipJarView.swift + Zener_WaveApp.swift** - Double transaction finishing: both `purchase()` and the app-level transaction listener called `transaction.finish()` and both triggered the toast. **Fixed:** `purchase()` no longer calls `finish()`; the app-level listener is the sole authority.

- [x] 🔴 **#14 AboutView.swift** - The toolbar `info.circle` icon button called `copyVersionToClipboard()` instead of showing info, silently modifying the user's clipboard. **Fixed:** Misleading toolbar button removed entirely.

---

## Medium Severity

- [x] 🟡 **#2 ZenerGameView.swift** - `ZenerGame` ObservableObject was not marked `@MainActor`, leaving `@Published` mutations without guaranteed main-thread isolation. **Fixed:** Class marked `@MainActor`.

- [x] 🟡 **#5 ZenerGameView.swift** - `ForEach` in results list used `\.offset` as identity instead of the model's stable `UUID`. **Fixed:** Changed to `id: \.element.id`.

- [x] 🟡 **#6 ZenerGameView.swift** - `flashedSymbol` was not cleared when "Play Again" was tapped, letting a stale flash persist into the new game. **Fixed:** Play Again now cancels the pending flash task and resets `flashedSymbol` to `nil`.

- [x] 🟡 **#9 TipJarView.swift** - The `onReceive(.purchaseCompleted)` handler reset the toast timer on top of the one already started by `purchase()`, creating conflicting dismissal closures. **Fixed:** Duplicate `onReceive` handler removed; toast is set only in the `purchase()` call path.

- [x] 🟡 **#10 TipJarView.swift** - `DispatchQueue.main.asyncAfter` was mixed inside `Task` blocks, creating unstructured, non-cancellable callbacks. **Fixed:** Replaced with `try? await Task.sleep(for: .seconds(2))` in `@MainActor` Tasks throughout.

- [x] 🟡 **#11 TipJarView.swift** - "Restore Purchases" always showed "Restored purchases" toast even when nothing was restored. **Fixed:** `restore()` now returns a `Bool`; the view shows "No purchases to restore" when no entitlements were found.

- [x] 🟡 **#15 AboutView.swift** - Version string was displayed twice in adjacent rows. **Fixed:** Removed the inline version text from the `HStack`; only the `AppVersionRow` remains.

- [x] 🟡 **#17 ContentView.swift** - `ContentView` was never used (app root is set directly to `ZenerGameView`). **Fixed:** `ContentView.swift` deleted.

- [x] 🟡 **#19 Features.swift** - File was 478 lines of the same file-header comment copy-pasted repeatedly with no actual Swift code. **Fixed:** File was absent from the project structure (already deleted prior to this session).

- [x] 🟡 **#21 Zener_WaveApp.swift** - Transaction listener fired `purchaseCompleted` notification for any product, not just tips. **Fixed:** Notification post removed from the listener; the listener now only calls `finish()`, keeping concerns separate.

---

## Low Severity (Open)

- [ ] 🟢 **#3 ZenerGameView.swift** - `LazyVGrid` used for 5 static symbol buttons. A plain `HStack` would be lighter and simpler.

- [ ] 🟢 **#7 ZenerGameView.swift** - Toolbar button order relies on undocumented SwiftUI declaration ordering. Could differ on iPad or macOS Catalyst. **Fix:** Use a single `ToolbarItem` with an `HStack` for explicit ordering.

- [ ] 🟢 **#12 TipJarView.swift** - `NavigationStack` wraps a sheet that has no push navigation; used only for the toolbar title and close button. **Fix:** Remove `NavigationStack` and apply `.toolbar` directly to the sheet content.

- [ ] 🟢 **#16 AboutView.swift** - `copyVersionToClipboard()` can re-trigger an already-visible alert if tapped repeatedly, causing a flicker. **Fix:** Guard with `guard !didCopyVersion else { return }`.

- [ ] 🟢 **#20 Zener_WaveApp.swift** - `transactionListenerTask` stored as `@State` on the App struct with no explicit cancellation path. Low practical risk. **Fix:** Consider owning the task in a dedicated `AppDelegate` or actor.

---

## Features

<!-- Add planned features here, e.g.: -->
<!-- - [ ] Statistics tracking across sessions -->
<!-- - [ ] Custom round count setting -->
