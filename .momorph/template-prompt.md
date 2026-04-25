# Prompt Templates — MoMorph commands

Quick-reference templates for invoking MoMorph skills on this project. Keeps
phrasing consistent across sessions and makes sure fold-in frames are not
silently dropped.

Source of truth for which frames are standalone vs. fold-in:
[.momorph/contexts/SCREENFLOW.md](contexts/SCREENFLOW.md) — column `Strategy`.

---

## 1. `/momorph.screenflow`

### 1a. Standalone screen (no fold-in)

Use when the row in SCREENFLOW.md is tagged `✅ Standalone` and has **no**
fold-in frames pointing to it.

```
/momorph.screenflow Tạo screen specs cho màn <Tên> (<screenId>)
https://momorph.ai/files/<fileKey>/screens/<screenId>
```

### 1b. Standalone screen WITH fold-in frames

Use when one or more frames are marked `↪ Fold → #<this row>` in
SCREENFLOW.md. Add a **Fold-in:** block so the agent loads those child
frames too and writes them into the correct sections of the parent spec
(no separate `screen_specs/<child>.md` file).

```
/momorph.screenflow Tạo screen specs cho màn <Tên> (<screenId>)
https://momorph.ai/files/<fileKey>/screens/<screenId>

Fold-in (mô tả trong cùng 1 file spec, KHÔNG tạo file riêng):
- [<Tên frame con>] (<screenId>) → Section: Sub-sheets   | Type: filter / picker / modal
- [<Tên frame con>] (<screenId>) → Section: UI States    | Type: loading / error / empty
- [<Tên frame con>] (<screenId>) → Section: Animation    | Type: reveal keyframe
- [<Tên frame con>] (<screenId>) → Section: Variants     | Type: conditional rendering

Với mỗi fold-in: chạy `get_overview` (depth 3) để mô tả layout + trigger,
không tạo `screen_specs/<frame-con>.md` độc lập.
```

Standard section names to fold into (match `screen-spec-template.md`):

| Fold-in type | Section in parent spec |
|--------------|------------------------|
| Dropdown / picker / modal sheet | `Sub-sheets` (nested under Component Schema) |
| Loading / error / empty / action | `UI States` |
| Animation keyframes | `Animation` (nested under UI States or Implementation Notes) |
| Conditional rendering of same layout | `Variants` (nested under Component Schema) |

### 1c. Standalone screen WITH verify frames

Use when SCREENFLOW.md has a `❓ Verify` row whose parent is unclear. Ask
the agent to decide and report back.

```
/momorph.screenflow Tạo screen specs cho màn <Tên> (<screenId>)
https://momorph.ai/files/<fileKey>/screens/<screenId>

Fold-in:
- ... (nếu có)

Verify:
- [<Tên frame>] (<screenId>): chạy `get_overview` để so sánh layout với <screenId cha>.
  Nếu giống ≥ 80% layout → fold vào Section <tên section> (giải thích lý do).
  Nếu khác → mark standalone, giữ nguyên trong bảng Screens của SCREENFLOW.md
  và report lại để tôi chạy /momorph.screenflow riêng cho nó.
```

---

## 2. Worked examples from this project

### Example A — `[iOS] Access denied` (standalone, 0 fold-in)

```
/momorph.screenflow Tạo screen specs cho màn Access denied (k-7zJk2B7s)
https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/k-7zJk2B7s
```

### Example B — `[iOS] Home` (1 fold-in, shared component)

```
/momorph.screenflow Tạo screen specs cho màn Home (OuH1BUTYT0)
https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/OuH1BUTYT0

Fold-in:
- [iOS] Language dropdown (uUvW6Qm1ve) → Section: Sub-sheets | Type: modal picker
  (Đây là component chia sẻ với Login, đã được mô tả ở login.md —
  ở home.md chỉ cần tham chiếu ngắn + note "xem chi tiết ở screen_specs/login.md")
```

### Example C — `[iOS] Open secret box` (2 fold-in, 1 animation cluster)

```
/momorph.screenflow Tạo screen specs cho màn Open secret box (kQk65hSYF2)
https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/kQk65hSYF2

Fold-in:
- [iOS] Open secret box — action bấm mở (KUmv414uC9) → Section: UI States | Type: user tapped
- [iOS] Open secret box — Standby keyframes → Section: Animation | Type: reveal animation
  Primary frame: -LIblaeusT. Các keyframe bổ sung (chỉ cần mention, không cần get_overview hết):
  IXpGakYRm5, _cWAEarZPi, scvV-OQCAJ, wsI6gaO_yc, FvTOS7oCPU, xptNUunBS_
```

### Example D — `[iOS] Sun*Kudos` (fold-in + verify)

```
/momorph.screenflow Tạo screen specs cho màn Sun*Kudos (fO0Kt19sZZ)
https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/fO0Kt19sZZ

Fold-in:
- [iOS] Sun*Kudos_dropdown hashtag (V5GRjAdJyb) → Section: Sub-sheets | Type: filter
- [iOS] Sun*Kudos_dropdown phòng ban (76k69LQPfj) → Section: Sub-sheets | Type: filter

Verify:
- [iOS] Sun*Kudos_All Kudos (j_a2GQWKDJ): chạy get_overview để so sánh layout với
  fO0Kt19sZZ. Nếu là tab/filter state → fold vào Section UI States.
  Nếu là list riêng → báo lại để tôi chạy /momorph.screenflow riêng.
```

### Example E — `[iOS] Gửi lời chúc Kudos` (2 dropdown + 1 error state)

```
/momorph.screenflow Tạo screen specs cho màn Gửi lời chúc Kudos (PV7jBVZU1N)
https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/PV7jBVZU1N

Fold-in:
- [iOS] Sun*Kudos_Gửi — dropdown hashtag (aKWA2klsnt) → Section: Sub-sheets | Type: picker
- [iOS] Sun*Kudos_Gửi — dropdown tên người nhận (5MU728Tjck) → Section: Sub-sheets | Type: picker
- [iOS] Sun*Kudos_Lỗi chưa điền hết (0le8xKnFE_) → Section: UI States | Type: validation error

Verify:
- [iOS] Sun*Kudos_Viết Kudo_default (7fFAb-K35a): so sánh với PV7jBVZU1N. Nếu giống ≥ 80% →
  fold vào Section UI States với type "default empty state". Khác → báo lại.
```

---

## 3. Quick checklist before you hit Enter

- [ ] Row của `screenId` cha trong SCREENFLOW.md được đánh **✅ Standalone**? (nếu là ↪ Fold / ❓ Verify → dừng lại, đó là frame con)
- [ ] Đã liệt kê **tất cả** frame `↪ Fold → #<this row>` trong khối **Fold-in**?
- [ ] Mỗi fold-in đã gán đúng **Section** + **Type**?
- [ ] Nếu có `❓ Verify` chỉ về row này → đã thêm khối **Verify** với tiêu chí quyết định rõ ràng?
- [ ] Nếu fold-in là component chia sẻ đã có spec ở file khác (ví dụ Language dropdown) → nhắc agent "tham chiếu ngắn + link" thay vì mô tả lại đầy đủ?

---

## 4. Templates for other MoMorph commands

### `/momorph.specify`

Dùng sau khi cluster màn liên quan đến feature đã có `screen_specs/*.md`.

```
/momorph.specify Tạo feature spec cho <tên feature> (ví dụ: Authentication).
Feature này phủ các màn: <screenId1>, <screenId2>, ...
Tham khảo:
- .momorph/contexts/screen_specs/<file1>.md
- .momorph/contexts/screen_specs/<file2>.md
File key: <fileKey>
```

### `/momorph.specs` (detailed UI component specs)

Dùng sau khi đã có screen_spec và chuẩn bị implement UI.

```
/momorph.specs <fileKey> <screenId>
```

### `/momorph.plan`

```
/momorph.plan Lập implementation plan cho feature <tên feature>.
Spec đầu vào: .momorph/specs/<feature>/spec.md
```

### `/momorph.tasks`

```
/momorph.tasks Tạo task breakdown cho feature <tên feature>.
Plan đầu vào: .momorph/specs/<feature>/plan.md
```

### `/momorph.implement`

```
/momorph.implement Chạy tasks trong .momorph/specs/<feature>/tasks.md.
Phase 1 → Phase N tuần tự; dừng sau mỗi Checkpoint để tôi xác nhận.
```

---

## 5. Giải pháp tương lai (tuỳ chọn)

Có thể update prompt định nghĩa của skill `momorph.screenflow` để nó **tự đọc**
cột `Strategy` trong `.momorph/contexts/SCREENFLOW.md` và khỏi cần dán khối
**Fold-in:** mỗi lần. Khi thay đổi đó được áp dụng, các Example ở §2 có thể
rút gọn về chỉ còn dòng đầu.

Trước mắt, **copy/paste theo template ở §1 là cách an toàn nhất**.
