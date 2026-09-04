# Checkbox Reorder Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Animate `TodoItem` row reorder when the user taps the checkbox, so the row visibly slides to its new position (done-block bottom or back to its original insertion position) over ~0.25s, with strikethrough/opacity/icon cross-fading in the same transaction.

**Architecture:** Single-file change to `TodoAppiOS/Sources/ListDetailView.swift`. Wrap the existing checkbox toggle in `withAnimation(.easeOut(duration: 0.25))` so SwiftUI animates the `List` reorder of the same-ID row driven by `displayedItems`. Attach `.contentShape(Rectangle())` + `onTapGesture` to the icon so the tap doesn't conflict with the surrounding `NavigationLink`. Add `.animation(.easeOut(duration: 0.25), value: item.isDone)` to the row as a redundant safety net for in-row visuals.

**Tech Stack:** SwiftUI on iOS 17+, SwiftData (unchanged). No new dependencies.

**Reference spec:** `docs/superpowers/specs/2026-09-04-checkbox-reorder-animation-design.md`

---

## File Structure

- **Modify:** `TodoAppiOS/Sources/ListDetailView.swift` — only file changed. Three small edits: (1) `onTapGesture` + `contentShape` on the checkbox image, (2) `withAnimation` wrapper around `item.isDone.toggle()`, (3) `.animation(_:value:)` on the row's `HStack`.
- No create, no delete, no test files (animation behavior verified manually per spec § Testing).

---

## Task 1: Add `withAnimation` reorder + `onTapGesture` to checkbox

**Files:**
- Modify: `TodoAppiOS/Sources/ListDetailView.swift:15-16` (Image + foregroundStyle modifiers)

- [ ] **Step 1: Locate the checkbox Image in `ListDetailView.swift`**

Read `TodoAppiOS/Sources/ListDetailView.swift:12-38` and confirm the current shape of the checkbox `Image(systemName:)` at roughly line 15. The full row currently looks like:

```swift
ForEach(list.displayedItems) { item in
    NavigationLink(value: item) {
        HStack {
            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isDone ? .green : .secondary)
            VStack(alignment: .leading) {
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
                Spacer()
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
```

- [ ] **Step 2: Add `contentShape` + `onTapGesture` with `withAnimation` wrapper**

Replace the two-line `Image` block:

```swift
Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
    .foregroundStyle(item.isDone ? .green : .secondary)
```

with:

```swift
Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
    .foregroundStyle(item.isDone ? .green : .secondary)
    .contentShape(Rectangle())
    .onTapGesture {
        withAnimation(.easeOut(duration: 0.25)) {
            item.isDone.toggle()
        }
    }
```

Rationale:
- `.contentShape(Rectangle())` makes the whole icon rectangle hit-testable, not just the colored fill, so taps near the outline still register.
- `onTapGesture` is local to the `Image`, so it does not propagate as a `NavigationLink` row tap. The surrounding `NavigationLink` still handles taps on the rest of the row.
- `withAnimation(.easeOut(duration: 0.25))` opens a transaction that animates both the `List` reorder driven by `displayedItems` and any implicit animations triggered inside the row.

- [ ] **Step 3: Sanity-check the file structure**

Run: `cat TodoAppiOS/Sources/ListDetailView.swift | head -40`
Expected: the `Image(systemName: ...)` now has 4 chained modifiers (foregroundStyle, contentShape, onTapGesture) and the `onTapGesture` closure contains the `withAnimation` block exactly as in Step 2. No stray whitespace, no malformed braces.

- [ ] **Step 4: Commit**

```bash
git -C /Users/serdar/workspace/todoapp add TodoAppiOS/Sources/ListDetailView.swift
git -C /Users/serdar/workspace/todoapp commit -m "feat: animate checkbox reorder via withAnimation"
```

---

## Task 2: Add `.animation(_:value:)` safety net to the row

**Files:**
- Modify: `TodoAppiOS/Sources/ListDetailView.swift` — the trailing close brace of the row's outer `HStack` (the inner-most `HStack {...}` that holds the icon, VStack, and optional photo).

- [ ] **Step 1: Locate the row's outer `HStack`**

In `TodoAppiOS/Sources/ListDetailView.swift`, find the `HStack {` that immediately follows the `NavigationLink(value: item) {`. It currently closes after the photo `Image` block with `}`. The structure is:

```swift
NavigationLink(value: item) {
    HStack {                       // <-- this HStack
        Image(systemName: ...) { ... }
        VStack(alignment: .leading) { ... }
        if let photoData = item.photoData, ... { ... }
    }                              // <-- close at this brace
}
```

- [ ] **Step 2: Attach implicit animation to the row `HStack`**

Replace the closing `}` of that `HStack` so the `HStack` receives an `.animation(_:value:)` modifier:

Before:
```swift
        if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
            Spacer()
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
```

After:
```swift
        if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
            Spacer()
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    .animation(.easeOut(duration: 0.25), value: item.isDone)
}
```

Rationale:
- The `.animation(_:value: item.isDone)` modifier binds SwiftUI's implicit animation to flips of `item.isDone`. So strikethrough, foreground opacity, and the checkbox icon color cross-fade smoothly when `isDone` toggles.
- This is a redundant safety net for in-row visuals: the explicit `withAnimation` from Task 1 already covers them, but the explicit form guarantees visually-correct behavior regardless of any future refactor of the row's content.

- [ ] **Step 3: Sanity-check the row block**

Run: `awk '/NavigationLink\(value: item\)/,/^[[:space:]]*}\(\)/{print NR": "$0}' TodoAppiOS/Sources/ListDetailView.swift`

Expected: a contiguous block from `NavigationLink(value: item) {` through to the closing brace of that `NavigationLink`, with the final line containing `.animation(.easeOut(duration: 0.25), value: item.isDone)` immediately before the `NavigationLink`'s close.

- [ ] **Step 4: Commit**

```bash
git -C /Users/serdar/workspace/todoapp add TodoAppiOS/Sources/ListDetailView.swift
git -C /Users/serdar/workspace/todoapp commit -m "feat: cross-fade row visuals on isDone toggle"
```

---

## Task 3: Manual verification (per spec § Testing)

**Files:** none — this task is verification only.

- [ ] **Step 1: Build for iOS Simulator**

Run:
```bash
cd /Users/serdar/workspace/todoapp/TodoAppiOS && xcodebuild -project TodoAppiOS.xcodeproj -scheme TodoAppiOS -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **` (no compile errors). If it fails, fix the source per Xcode's diagnostic before continuing.

- [ ] **Step 2: Run the app on Simulator**

Open the `TodoAppiOS.xcodeproj` in Xcode, pick an iOS Simulator (any 17+ device), Run.

- [ ] **Step 3: Verify forward animation (undone → done)**

In a list with at least 4 items, tap the checkbox on the top item. Confirm:
1. The row visibly slides downward to the done-block (bottom of the list).
2. Strikethrough and opacity transition fade in over ~0.25s — not instant.
3. The icon morphs `circle` → `checkmark.circle.fill` smoothly.

- [ ] **Step 4: Verify reverse animation (done → undone)**

Tap the checkbox on a done item. Confirm:
1. The row slides upward to its original insertion position among undone items.
2. Strikethrough and opacity fade out over ~0.25s.
3. Icon morphs back to `circle`.

- [ ] **Step 5: Verify rapid taps**

Tap the same checkbox twice in quick succession (~0.1s apart). Confirm: the animation chain cleanly resets and final state matches the data (no jump-back, no flicker).

- [ ] **Step 6: Verify no accidental navigation**

Tap firmly on the checkbox icon. Confirm: detail navigation (`ItemDetailView`) does **not** trigger. Tapping elsewhere on the row still navigates as before.

If any check fails, iterate on `ListDetailView.swift` (revert with `git revert HEAD~..HEAD`, fix, recommit with `--amend` or a follow-up commit).

- [ ] **Step 7: Capture verification note (optional)**

If anything was tweaked during verification, commit the fix:

```bash
git -C /Users/serdar/workspace/todoapp add TodoAppiOS/Sources/ListDetailView.swift
git -C /Users/serdar/workspace/todoapp commit -m "chore: verification tweaks for checkbox animation"
```

(No commit needed if Step 1–6 all passed cleanly.)
