# Sidebar Pending Counts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show each list's pending (not-done) item count in the sidebar — right-aligned next to the list name when expanded, and as a black-circle/white-text badge on the swatch box's bottom-right corner when collapsed.

**Architecture:** A `pendingCount` computed property on `TodoList` in `JustTodoKit` (TDD, same pattern as `displayedItems`), consumed by `SidebarView.listRow` for both expanded text and collapsed badge. No new files.

**Tech Stack:** Swift 6.2, SwiftUI (macOS 14), XCTest via SwiftPM.

**Spec:** `docs/superpowers/specs/2026-09-04-sidebar-pending-counts-design.md`

**IMPORTANT — uncommitted rename in working tree:** The project was just renamed `TodoApp/TodoKit/TodoKitTests` → `JustTodoApp/JustTodoKit/JustTodoKitTests` (uncommitted). Do NOT stage or commit the old-path deletions or `Package.swift`; stage only the exact files listed in each commit step. The rename owner will commit the rest.

---

### Task 1: `TodoList.pendingCount` (model, TDD)

**Files:**
- Modify: `Sources/JustTodoKit/Models.swift` (add after `displayedItems`, ~line 45)
- Test: `Sources/JustTodoKitTests/ModelsTests.swift`

- [ ] **Step 1: Write the failing tests**

Append these three tests inside `final class ModelsTests` in `Sources/JustTodoKitTests/ModelsTests.swift` (after the existing `testDisplayedItemsPutDoneLastAndKeepInsertionOrder` method):

```swift
    func testPendingCountCountsOnlyUndoneItems() {
        let items = [
            TodoItem(title: "A", isDone: false),
            TodoItem(title: "B", isDone: true),
            TodoItem(title: "C", isDone: false),
            TodoItem(title: "D", isDone: true),
        ]
        let list = TodoList(title: "L", items: items)
        XCTAssertEqual(list.pendingCount, 2)
    }

    func testPendingCountIsZeroWhenAllDone() {
        let list = TodoList(title: "L", items: [TodoItem(title: "A", isDone: true)])
        XCTAssertEqual(list.pendingCount, 0)
    }

    func testPendingCountIsZeroForEmptyList() {
        XCTAssertEqual(TodoList(title: "L").pendingCount, 0)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter ModelsTests`
Expected: FAIL — compile error like `value of type 'TodoList' has no member 'pendingCount'`

- [ ] **Step 3: Write minimal implementation**

In `Sources/JustTodoKit/Models.swift`, inside `struct TodoList`, directly after the `displayedItems` property:

```swift
    /// Number of items not yet done.
    public var pendingCount: Int {
        items.filter { !$0.isDone }.count
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter ModelsTests`
Expected: PASS (6 tests, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add Sources/JustTodoKit/Models.swift Sources/JustTodoKitTests/ModelsTests.swift
git commit -m "feat: add TodoList.pendingCount for undone item count"
```

---

### Task 2: Expanded sidebar — right-aligned count next to list name

No automated view tests exist in this repo (tests cover `JustTodoKit` only), so this task is implement → build → manual check → commit.

**Files:**
- Modify: `Sources/JustTodoApp/SidebarView.swift:48-76` (`listRow`)

- [ ] **Step 1: Replace the title `Text` in the `listRow` ZStack**

In `Sources/JustTodoApp/SidebarView.swift`, inside `private func listRow(_ list: TodoList) -> some View`, replace:

```swift
            Text(list.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(collapsed ? 0 : 1)
```

with:

```swift
            HStack(spacing: 8) {
                Text(list.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if list.pendingCount > 0 {
                    Text("\(list.pendingCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .opacity(collapsed ? 0 : 1)
```

- [ ] **Step 2: Build**

Run: `swift build`
Expected: `Build complete!` with no errors/warnings

- [ ] **Step 3: Manual check (expanded)**

Run: `swift run JustTodoApp`
Verify:
- Lists with pending items show the count at the right edge of the row, grey (secondary).
- A list with 0 pending (or empty) shows no number.
- Checking/unchecking an item in the detail pane updates the sidebar number immediately.

- [ ] **Step 4: Commit**

```bash
git add Sources/JustTodoApp/SidebarView.swift
git commit -m "feat: show right-aligned pending count in expanded sidebar rows"
```

---

### Task 3: Collapsed sidebar — badge on swatch box corner

**Files:**
- Modify: `Sources/JustTodoApp/SidebarView.swift:48-76` (`listRow`)

- [ ] **Step 1: Add the badge overlay to the swatch box**

In `private func listRow(_ list: TodoList) -> some View`, find the swatch `Text(...)` chain ending with:

```swift
                .overlay {
                    if store.selectedListID == list.id {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0x00 / 255, green: 0x62 / 255, blue: 0xC1 / 255), lineWidth: 2)
                    }
                }
                .opacity(collapsed ? 1 : 0)
```

Insert a new overlay **between** the selection `.overlay { ... }` block and `.opacity(collapsed ? 1 : 0)`:

```swift
                .overlay(alignment: .bottomTrailing) {
                    if list.pendingCount > 0 {
                        Text("\(list.pendingCount)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, list.pendingCount > 9 ? 5 : 0)
                            .background(Color.black, in: Capsule())
                            .offset(x: 6, y: 6)
                    }
                }
```

Notes:
- A 20×20 `Capsule` renders as a circle for single digits; the extra horizontal padding for counts > 9 stretches it into a capsule.
- The `offset(x: 6, y: 6)` pulls the badge outward over the box edge. Row height (58) minus box height (42) plus row insets leaves enough room; if the badge ever clips against the next row, reduce the offset, do not change row height.

- [ ] **Step 2: Build**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 3: Manual check (collapsed)**

Run: `swift run JustTodoApp`
Verify:
- Collapse the sidebar (bottom `sidebar.left` button).
- Lists with pending items show a black circle with white count at the swatch's bottom-right corner.
- 10+ pending shows a black capsule, still white text.
- 0 pending shows no badge.
- Toggling the last pending item makes the badge disappear; expanding the sidebar hides badges and shows the expanded counts.
- Toggle back and forth: animation matches existing collapse behavior, no layout jitter.

- [ ] **Step 4: Full test suite**

Run: `swift test`
Expected: all tests pass (0 failures)

- [ ] **Step 5: Commit**

```bash
git add Sources/JustTodoApp/SidebarView.swift
git commit -m "feat: pending-count badge on collapsed sidebar swatch"
```

---

## Spec coverage self-review

- "pendingCount in TodoList + tests" → Task 1
- "Expanded: right-aligned secondary number, hidden at 0" → Task 2
- "Collapsed: black circle/capsule badge, white text, bottom-right corner, hidden at 0" → Task 3
- "Reactive updates via AppStore" → verified manually in Task 2 Step 3 / Task 3 Step 3 (state is observed `TodoList` values; no extra task needed)
- No placeholders; `pendingCount` name identical in all tasks.
