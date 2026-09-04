# TodoApp — Design Spec

Date: 2026-09-04
Status: Approved

## Overview

Things-inspired minimal to-do app for macOS, written in Swift (SwiftUI). Two-pane layout:

- **Left sidebar:** all todo list titles + a "New List" form that takes only a Title.
- **Right main pane:** items of the selected todo list.

Terminology (as used by the user): a "todo" is a list; a "todo item" is an entry inside a list.

## Tech Stack

- Swift Package Manager, executable target `TodoApp`, SwiftUI `@main`.
- No Xcode project files, no third-party dependencies.
- macOS 26 SDK, Swift 6.3 toolchain (present on machine).

## Architecture

Single executable target + test target:

```
Package.swift
Sources/TodoApp/
  TodoApp.swift        # @main App, window config, activation policy
  Models.swift         # TodoList, TodoItem (Codable structs)
  AppStore.swift       # @Observable store; all mutations; autosave trigger
  JSONStore.swift      # load/save to Application Support
  SidebarView.swift    # new-list form + list of titles
  DetailView.swift     # header, item rows, Cmd+N new-item field
Sources/TodoAppTests/
  AppStoreTests.swift
```

Units and interfaces:

- `Models.swift` — pure data. `TodoItem { id: UUID, title: String, isDone: Bool }`, `TodoList { id: UUID, title: String, items: [TodoItem] }`. No behavior beyond ordering helper.
- `AppStore` — the only mutable state. Public API used by views:
  `addList(title:)`, `addItem(listID:title:)`, `toggleDone(listID:itemID:)`,
  `deleteItem(listID:itemID:)`, `select(listID:)`. Exposes `lists`,
  `selectedListID`. Calls `persist()` after every mutation.
- `JSONStore` — `load() -> [TodoList]`, `save([TodoList]) throws`. Knows the file
  path, nothing else.
- Views observe `AppStore` via `@Observable` + `@Environment`/`@Bindable`.

## Data & Ordering Rules

- Storage file: `~/Library/Application Support/TodoApp/data.json`, rewritten
  atomically after every mutation.
- Display order: undone items first in insertion order, then done items at the
  bottom (stable partition of the stored `items` array). The stored array order
  is never re-sorted, so un-checking a done item returns it to its original
  position among undone items.

## UI Behavior

- Window ~900×600. Sidebar fixed 220pt, main pane flexible.
- **New List form (sidebar top):** single `TextField` with placeholder
  "New List"; Enter creates the list (title trimmed; blank rejected) and it
  appears in the sidebar under the new title. The new list becomes selected.
- **List selection:** clicking a sidebar row selects it; main pane shows that
  list's items under the list title header.
- **New item (Cmd+N):** `Cmd+N` (`.keyboardShortcut("n", .command)`) reveals a
  text input at the top of the item list; Enter adds the item to the selected
  list; Esc dismisses it. No-op when no list is selected.
- **Item row:** checkbox on the left; clicking the checkbox toggles done.
  Clicking elsewhere on the row selects the item (selection = one item per list,
  transient UI state).
- **Selected item:** "Mark as done" and "Delete" buttons appear at the right of
  the row. "Mark as done" marks the item done and is disabled when the item is
  already done (un-toggling is done via the checkbox); "Delete" removes the
  item. Selection is cleared when the selected item is deleted.
- **Done items:** strikethrough title, opacity ~0.5, sorted to the bottom.

## Error Handling

- Missing or unreadable/corrupt JSON file → start with empty store (corrupt file
  is left as-is; no data migration in v1).
- Save failures → SwiftUI alert showing the error; in-memory state is kept.
- Titles trimmed; whitespace-only titles rejected for both lists and items.

## Testing

- `swift test` covers AppStore logic: add/toggle/delete, display-ordering rule
  (undone insertion order first, done last, stable), un-toggle restores
  position, blank-title rejection, JSON round-trip through a temp directory.
- No UI tests. Manual verification: `swift run`, exercise all flows + Cmd+N.

## Out of Scope (v1)

Renaming/deleting lists, editing item titles, item ordering by hand, due
dates/tags, multiple windows, launch-at-login, App Store packaging.
