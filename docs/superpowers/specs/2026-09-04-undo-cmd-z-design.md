# Undo (Cmd+Z) — Design Spec

Date: 2026-09-04
Status: Approved

## Overview

Pressing **Cmd+Z** in TodoApp reverts the most recent user operation. No redo
(Cmd+Shift+Z is intentionally out of scope, YAGNI).

## Requirements

- All `AppStore` mutations are undoable: `addList`, `addItem`, `toggleDone`,
  `setTitle`, `setNotes`, `deleteItem`.
- Text edits (title/notes fields fire `setTitle`/`setNotes` per keystroke) must
  collapse into **one undo step per editing session** on the same field, not one
  step per keystroke.
- Undo restores state and persists to disk like any other mutation.
- Menu item "Undo" appears in the Edit menu with the Cmd+Z shortcut; disabled
  when there is nothing to undo.

## Chosen Approach

**Snapshot stack inside `AppStore`** (Approach A). Rejected: Foundation
`UndoManager` (weak testability, injection plumbing for the same result) and
command pattern with per-mutation inverses (unnecessary complexity for a small
`Codable` model).

## Design

### AppStore changes (TodoKit)

- New `@ObservationIgnored private var undoStack: [[TodoList]]`, capped at 50
  entries (oldest dropped).
- `public var canUndo: Bool { !undoStack.isEmpty }`. The stack is kept
  **observed** (no `@ObservationIgnored`) so `canUndo` recomputes when it
  changes; snapshots are value types and never leak outside the store.
- New undo-tracking metadata: `@ObservationIgnored` fields `lastUndoKind:
  MutationKind?` and `lastUndoTargetID: UUID?`, where `MutationKind` is a
  private enum over the six mutations.
- `pushUndo(kind:targetID:)` called after a mutation's validation guards
  succeed and *before* `lists` is modified — mutations rejected by guards
  (e.g. empty title, missing item) push no snapshot:
  - If `lastUndoEntry == (kind, targetID)`, skip pushing (coalescing).
  - Otherwise push a deep copy of `lists`, enforce the cap, and update
    `lastUndoKind`/`lastUndoTargetID`.
- The shared `updateItem` helper gains a `MutationKind` parameter so each
  caller (`toggleDone`, `setNotes`, `setTitle`) pushes its own kind.
- `public func undo()`:
  - No-op if the stack is empty.
  - Pops the top snapshot, assigns it to `lists`, calls `persist()`.
  - Clears `lastUndoKind`/`lastUndoTargetID` (an undo is not part of any edit
    run).
  - If `selectedListID` no longer matches any list (e.g. undo of `addList`),
    select the first remaining list, or `nil` if none remain.

### Coalescing semantics

Consecutive calls of the same mutation kind targeting the same entity
(`itemID`, or `listID` for `addList`) form one undo step; the snapshot taken is
the state *before the first* call of the run. Any different mutation kind,
different target, or an `undo()` breaks the run. No timers.

### Menu wiring (TodoApp)

In `TodoAppMain`, add to the existing `Window` scene:

```swift
.commands {
    CommandGroup(replacing: .undoRedo) {
        Button("Undo") { store.undo() }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!store.canUndo)
    }
}
```

No other UI changes. The hidden `CommandGroup(.undoRedo)` default (SwiftUI's
built-in, which is inert without an `UndoManager`) is replaced entirely.

### Error handling

- `undo()` persists through the existing `persist()` path; a failed save uses
  the existing `saveError` alert flow. State still rolls back in memory.
- Cap of 50 snapshots bounds memory; lists are small so snapshots are cheap.

## Testing (TodoKitTests / AppStoreTests)

With a temp-dir `JSONStore`, assert:

1. `undo()` after each mutation restores the exact prior state (`lists` equals
   the pre-mutation value) and persists it.
2. Coalescing: multiple `setTitle` calls on one item → one `undo()` restores the
   title to its value before the run; same for `setNotes`.
3. Different targets or kinds break the run (two items edited → two undos).
4. `undo()` on an empty stack is a no-op; `canUndo` reflects stack emptiness.
5. Undo of `addList` fixes `selectedListID` to the first remaining list (nil
   when the last list is removed).
6. Stack cap: after >50 distinct mutations, only the latest 50 states are
   reachable.
7. Rejected mutations (empty title) push no snapshot.

## Out of Scope

- Redo (Cmd+Shift+Z)
- Undo for selection changes / focus state
- Per-field focus-based coalescing hooks in views (timer- and focus-free
  (kind, targetID) rule suffices)
