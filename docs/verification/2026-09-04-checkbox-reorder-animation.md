# Checkbox Reorder Animation — Human Verification Checklist

Plan: `docs/superpowers/plans/2026-09-04-checkbox-reorder-animation.md`
Spec: `docs/superpowers/specs/2026-09-04-checkbox-reorder-animation-design.md`

Implementation commits:
- `647b266` — `feat: animate checkbox reorder via withAnimation` (Task 1)
- `a0c48b1` — `feat: cross-fade row visuals on isDone toggle` (Task 2)

`xcodebuild` already verified in CI/CLI: `** BUILD SUCCEEDED **`. CLI environment cannot
interactively drive the iOS Simulator, so the steps below must be performed by a developer
with Xcode + Simulator access.

## How to run

```bash
open /Users/serdar/workspace/todoapp/TodoAppiOS/TodoAppiOS.xcodeproj
```

Pick any iOS 17+ simulator, Run.

## Manual checks

- [ ] **Step 1: Forward animation (undone → done)**

  Create a list with at least 4 items. Tap the checkbox on the top item.

  - The row visibly slides downward to the done-block (bottom of the list).
  - Strikethrough and opacity fade in over ~0.25s (not instant).
  - Icon morphs `circle` → `checkmark.circle.fill` smoothly.

- [ ] **Step 2: Reverse animation (done → undone)**

  Tap the checkbox on a done item.

  - The row slides upward to its original insertion position among undone items.
  - Strikethrough and opacity fade out over ~0.25s.
  - Icon morphs back to `circle`.

- [ ] **Step 3: Rapid taps**

  Tap the same checkbox twice ~0.1s apart.

  - Final state matches the data (no jump-back, no flicker).
  - Animation chain resets cleanly without ghost frames.

- [ ] **Step 4: No accidental navigation**

  Tap firmly on the checkbox icon.

  - Detail view (`ItemDetailView`) does **not** open.
  - Tapping elsewhere on the row still navigates as before.

- [ ] **Step 5: Subjective feel check**

  - 0.25s should feel "snappy but visible." If too quick to perceive, bump to 0.30s.
  - If sluggish, drop to 0.20s.

## If something fails

1. Note the failure mode (which step + observed behavior).
2. Edit `TodoAppiOS/Sources/ListDetailView.swift` to address it.
3. Commit:
   ```bash
   git add TodoAppiOS/Sources/ListDetailView.swift
   git commit -m "chore: verification tweaks for checkbox animation"
   ```
4. Re-run all checks above.

Mark each checkbox as you complete it. When all pass, this verification is done.
