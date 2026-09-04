# Checkbox Reorder Animation — Design Spec

Date: 2026-09-04
Status: Approved

## Overview

When a user taps the checkbox on a `TodoItem` row, the item's `isDone` flips and
the item moves to the bottom of the list (per the `displayedItems` ordering rule
in `Models.swift:44-47`). Today this happens with no animation — the row jumps
instantly, and users miss the transition.

This change adds a short animated transition (~0.25s `easeOut`) so both
directions (undone → done, done → undone) visibly slide to their new position.
Row-level visuals (strikethrough, opacity, icon color) cross-fade in the same
transaction so the whole event feels like one cohesive animation.

## Tech Stack

No new dependencies. SwiftUI `withAnimation` + implicit `.animation(value:)`.

## Architecture

Single-file change in `TodoAppiOS/Sources/ListDetailView.swift`. No model or
data-layer changes.

Units involved:

- **`ListDetailView`** — owns the row UI and the checkbox tap handler. The only
  file edited.
- **`TodoItem` / `TodoList` (Models.swift)** — unchanged. `displayedItems` keeps
  its current stable-partition rule.

## Behavior

### Checkbox tap (the trigger)

The checkbox is rendered as an `Image(systemName:)` inside a row that's wrapped
in a `NavigationLink(value:)`. Tapping the row itself navigates to item detail,
so a nested `Button` would conflict with `List`'s row-tap routing. Instead, we
attach `onTapGesture` to the `Image`, with `.contentShape(Rectangle())` so the
whole icon glyph rectangle is hit-testable (not just the colored fill):

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

Because the image lives inside a `NavigationLink` row, SwiftUI may also fire
the row tap on the same gesture. Mitigation: keep the tap area small (just
the icon rectangle) and rely on `onTapGesture` taking precedence at the
local level. If a future build shows accidental navigation, the fix is to
extract the checkbox into a non-linked leading column using
`Section`/composite layout — out of scope for this change.

### Reorder animation

`withAnimation(.easeOut(duration: 0.25))` wraps the state mutation. SwiftUI,
inside the resulting transaction, animates the `ForEach`-driven `List`
reorder of the same-ID row from its old index to its new index. Duration 0.25s
matches Apple's default implicit animation window — sharp enough to feel
responsive, long enough to follow visually.

### Per-row visual cross-fade

Same row container gets an implicit `.animation(_:value:)` bound to
`item.isDone`:

```swift
HStack { /* row contents */ }
    .animation(.easeOut(duration: 0.25), value: item.isDone)
```

This animates strikethrough, foreground opacity (`.secondary` vs `.primary`),
and the icon/color change in sync with the reorder. Both directions.

The explicit `withAnimation` in the handler is the primary driver; the
implicit `.animation` on the row is a redundant safety net for the in-row
visuals.

## Data Flow

1. User taps checkbox icon.
2. `withAnimation(.easeOut(0.25)) { item.isDone.toggle() }` runs.
3. SwiftData persists `isDone` (existing autosave behavior).
4. `displayedItems` recomputes — item's index shifts (top of "done" block on
   uncheck; appended on check).
5. SwiftUI's `List` + `ForEach` rebuilds with the new order; because the
   transaction is animated, the row interpolates to its new position over
   0.25s.
6. Row-level visual properties (strikethrough, opacity, icon) cross-fade in
   the same transaction.

## Edge Cases

- **Single-item list**: no motion needed (row already at end / already at
  top). The icon + opacity still cross-fade.
- **Rapid taps**: each `withAnimation` cancels the in-progress one; the
  latest state wins. Natural and expected.
- **NavigationLink accidental tap**: tap area limited to icon rectangle via
  `.contentShape(Rectangle())`. If real-world testing shows bleed-through
  (opening `ItemDetailView` instead of toggling), an iteration can separate
  the checkbox into a non-link leading region. Not required for v1.
- **CloudKit sync**: animations are local; sync latency is unaffected and
  unrelated.

## Error Handling

None needed. This is a pure UI animation wrapper around an existing data
mutation. SwiftData persistence behavior is unchanged.

## Testing

No automated tests added. The change is a UI animation on top of existing,
already-tested state behavior (`displayedItems` ordering rule).

Manual verification checklist:

1. Build and run on iOS Simulator.
2. Create a list with 4–5 items. Tap checkbox on the top item → it slides
   down to the done-block at the bottom; strikethrough + opacity fade in over
   ~0.25s.
3. Tap the checkbox on a done item → it slides back up to its original
   insertion position; strikethrough + opacity fade out.
4. Rapid-tap the same checkbox twice → animation transitions cleanly, final
   state matches the data.
5. Subjective feel check: 0.25s should feel "snappy but visible". If too
   quick to perceive, bump to 0.30s; if sluggish, drop to 0.20s.

## Out of Scope

- Custom `AnyTransition` / `MatchedGeometryEffect`-based slide.
- Restoring original "insertion order" semantic on un-check (already correct
  per existing rule).
- Sidebar list reorder animations (not a user request).
- Separating the checkbox from the `NavigationLink` row layout.
- Adopting the same animation in the macOS `TodoApp` target (different
  codebase; can be done as a follow-up if requested).
