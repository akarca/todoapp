# Sidebar Pending Counts — Design Spec

Date: 2026-09-04
Status: Approved

## Overview

Each list in the sidebar shows how many of its items are still pending
(`isDone == false`). In the expanded sidebar the count sits at the right edge
of the list-name row; in the collapsed sidebar it appears as a black circular
badge with white text on the bottom-right corner of the list's swatch box.

## Requirements

- Count = number of items with `isDone == false` in that list.
- Expanded mode: number right-aligned on the same row as the list title.
- Collapsed mode: badge overlaid on the bottom-right corner of the 42×42
  swatch box; black circle, white font.
- When the count is **0**, nothing is shown in either mode (no "0" text, no
  empty badge).
- Counts update reactively as items are added/toggled/deleted (state already
  flows through `AppStore`).

## Chosen Approach

**`TodoList.pendingCount` computed property in TodoKit** (Approach B),
following the existing `displayedItems` pattern in `Models.swift`. Rejected:
computing inline in `SidebarView` (Approach A) — leaves untested model logic
duplicated in the view.

## Design

### Model (TodoKit/Models.swift)

- `public var pendingCount: Int { items.filter { !$0.isDone }.count }` on
  `TodoList`, placed next to `displayedItems`.
- Unit tests in `TodoKitTests/ModelsTests.swift`: mixed done/undone items,
  all-done list → 0, empty list → 0.

### Expanded row (SidebarView.listRow)

- The leading title `Text` and a trailing count `Text` share the row: title
  keeps `frame(maxWidth: .infinity, alignment: .leading)`; count is rendered
  only when `pendingCount > 0`, in `.secondary` color, tabular-figure monospaced
  digits so rows don't jitter.
- Count participates in the same `opacity(collapsed ? 0 : 1)` toggle as the
  title.

### Collapsed badge (SidebarView.listRow)

- Overlay on the 42×42 swatch box, aligned `.bottomTrailing`, offset outward
  (~4pt) so it overlaps the box edge.
- Background: black `Circle` for a single digit (~20pt diameter); black
  capsule for two or more digits. Text: white, ~11pt, semibold, centered.
- Rendered only when `pendingCount > 0`; participates in the existing
  `opacity(collapsed ? 1 : 0)` and `.animation(.default, value: collapsed)`.

### Error handling

None needed: counts are pure derived data; no new failure modes.

## Testing

- `swift test` — new `pendingCount` model tests plus the existing suite.
- Manual: toggle items, add/delete, resize sidebar; verify badge appears in
  collapsed mode only above 0 and right-alignment in expanded mode.
