# Zener Wave - Bug & Optimisation Tracker

Last updated: 2026-03-11

---

## Legend
- Status: `[ ]` Open · `[~]` In Progress · `[x]` Fixed
- Severity: 🔴 High · 🟡 Medium · 🟢 Low

---

## High Severity

- [ ] 🔴 **#1 ZenerGameView.swift ~209-213** - Stacked `DispatchQueue` timers: Every symbol tap queues a new timer to clear `flashedSymbol` but previous timers are never cancelled. Rapid tapping causes earlier timers to fire and clear flashes prematurely. **Fix:** Store a cancellable `Task` in `@State`, cancel it before scheduling a new one.

- [ ] 🔴 **#8 TipJarView.swift ~42 + Zener_WaveApp.swift ~47** - Double transaction finishing: both `purchase()` and the app-level transaction listener call `transaction.finish()` and both trigger the "Thank you" toast, causing it to appear twice or the countdown to reset. **Fix:** Pick one place to finish transactions (recommended: app-level listener only).

- [ ] 🔴 **#14 AboutView.swift ~91-97** - The toolbar `info.circle` icon button calls `copyVersionToClipboard()` instead of showing info. A user tapping the info icon silently modifies their clipboard. **Fix:** Remove the toolbar button or replace its action with something informative.

---

## Medium Severity

- [ ] 🟡 **#2 ZenerGameView.swift ~41** - `ZenerGame` ObservableObject is not marked `@MainActor`. Its mutating methods update `@Published` properties without guaranteed main-thread isolation. **Fix:** Add `@MainActor` to the class declaration.

- [ ] 🟡 **#5 ZenerGameView.swift ~166** - `ForEach` uses `\.offset` as identity instead of the model's stable `UUID`. Reordering or filtering rounds would cause incorrect diffing and broken animations. **Fix:** Use `id: \.element.id` instead.

- [ ] 🟡 **#6 ZenerGameView.swift ~188-190** - `flashedSymbol` is not cleared when "Play Again" is tapped. A stale flash from the previous game can persist into the new one. **Fix:** Reset `flashedSymbol` (and cancel any pending flash task) inside the Play Again button action.

- [ ] 🟡 **#9 TipJarView.swift ~83-88 + ~135-139** - The `onReceive` notification handler resets the toast timer on top of the one already started by `purchase()`, causing conflicting dismissal closures. **Fix:** Guard against setting the toast message when it is already visible, or remove one of the two triggers.

- [ ] 🟡 **#10 TipJarView.swift ~136-138 + ~157-159** - `DispatchQueue.main.asyncAfter` is mixed inside `Task` blocks. The closure is not cancellable and escapes the Task scope. **Fix:** Replace with `try? await Task.sleep(for: .seconds(2))` inside a `@MainActor` Task.

- [ ] 🟡 **#11 TipJarView.swift ~153-160** - "Restore Purchases" always shows "Restored purchases" toast even when nothing was actually restored. **Fix:** Track whether any entitlement was found and show "No purchases to restore" when the result is empty.

- [ ] 🟡 **#15 AboutView.swift ~37-58** - Version string is displayed twice in adjacent rows (once in an `HStack`, once in `AppVersionRow`). **Fix:** Remove the duplicate; keep only the `AppVersionRow`.

- [ ] 🟡 **#17 ContentView.swift** - `ContentView` is never used. The app root is set directly to `ZenerGameView` in `Zener_WaveApp.swift`. **Fix:** Delete `ContentView.swift`.

- [ ] 🟡 **#19 Features.swift** - The entire 478-line file is the same file-header comment copy-pasted repeatedly. No actual Swift code exists in it. **Fix:** Delete or replace with a single proper header and real planning notes.

- [ ] 🟡 **#21 Zener_WaveApp.swift ~39-51** - The transaction listener fires `purchaseCompleted` for any product, not just tips. Would cause incorrect toasts if more products are added. **Fix:** Filter by product ID before posting the notification.

---

## Low Severity

- [ ] 🟢 **#3 ZenerGameView.swift ~197-231** - `LazyVGrid` used for 5 static symbol buttons. The lazy layout system is overhead for a fixed 5-item row. **Fix:** Replace with a plain `HStack`.

- [ ] 🟢 **#4 ZenerGameView.swift ~202-214** - Code inside the symbol button's action closure is indented at column 0, making it visually appear to be at file scope. **Fix:** Correct indentation throughout the closure.

- [ ] 🟢 **#7 ZenerGameView.swift ~90-108** - Toolbar button order relies on undocumented SwiftUI declaration ordering behaviour, which may differ on iPad or macOS Catalyst. **Fix:** Use a single `ToolbarItem` with an `HStack` for explicit ordering.

- [ ] 🟢 **#12 TipJarView.swift ~74** - `NavigationStack` wraps a sheet that has no push navigation. Used only to get a toolbar title and close button. **Fix:** Remove `NavigationStack` and apply `.toolbar` directly to the sheet content.

- [ ] 🟢 **#13 TipJarView.swift ~3** - Unused `import Combine`. **Fix:** Remove the import.

- [ ] 🟢 **#16 AboutView.swift ~99-103** - `copyVersionToClipboard()` can re-trigger an already-visible alert if tapped repeatedly, causing a flicker. **Fix:** Guard with `guard !didCopyVersion else { return }`.

- [ ] 🟢 **#18 ContentView.swift ~14-17** - Xcode "Hello, world!" template placeholder content still present. Moot if `ContentView.swift` is deleted (see #17).

- [ ] 🟢 **#20 Zener_WaveApp.swift ~27-52** - `transactionListenerTask` stored as `@State` on the App struct with no explicit cancellation path. Low practical risk but not idiomatic. **Fix:** Consider owning the task in a dedicated `AppDelegate` or actor.

---

## Fixed

<!-- Move items here when resolved, e.g.: -->
<!-- - [x] 🔴 **#1** Fixed stacked DispatchQueue timers — 2026-03-11 -->
