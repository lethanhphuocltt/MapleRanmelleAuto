# Kế hoạch cải tiến Maple Auto v1

> Mục tiêu: script chạy đúng với **nhiều độ phân giải màn hình**, **nhiều kích thước cửa sổ game** và **nhiều bộ skill khác nhau**, không phải sửa code mỗi lần đổi máy.
>
> Trạng thái hiện tại: **P0 đã xong** (xem §1). Tài liệu này là phần còn lại.

---

## 1. Đã hoàn thành (P0)

| # | Việc | Ghi chú |
|---|------|---------|
| 1 | DPI awareness Per-Monitor V2 | Tránh lệch toạ độ khi Windows scale 125/150% |
| 2 | `RefW` / `RefH` / `SlotScale` | Mọi px trong ini được hiểu là px tại khung `RefW x RefH` |
| 3 | `ScaleX` / `ScaleY` / `YFactor` / `YRatio` | Quy đổi độc lập theo từng trục |
| 4 | Thay toàn bộ `Scale()` (13 chỗ) | Hết cảnh dùng 1 hệ số cho cả 2 trục |
| 5 | Fix cache `QsCapture` | Thêm `QsCh` vào điều kiện cache (trước chỉ so `cw`) |
| 6 | `PlaceWin` theo monitor | Dùng `MonitorGetWorkArea` của màn chứa cửa sổ, không hard-code `0,0` |
| 7 | `ClickAt` attempt 4 + `DragSelect` | Quy đổi theo virtual screen, hỗ trợ màn phụ nằm bên trái/trên |
| 8 | `GamePt` / `cellH` | Nhân thêm `YFactor` |
| 9 | GUI F5 + `SaveSettings` | 3 key mới, dropdown "Cách phóng toạ độ" |

**Tương thích ngược:** `settings_v1.ini` cũ vẫn chạy nguyên — `SlotScale` mặc định `uniform` cho kết quả y hệt bản trước.

Ba chế độ:

```
uniform  kx = ky = cw / RefW      (mặc định, giống bản cũ)
stretch  kx = cw / RefW, ky = ch / RefH
native   kx = ky = 1              (game vẽ UI đúng cỡ px, không phóng)
```

---

## 2. P1 — Nên làm tiếp (giá trị cao, rủi ro thấp)

### P1-1. Tự hiệu chỉnh ô quickslot (Calibrate) — bỏ phụ thuộc `QS_X0/DX/Y1/Y2`

**Vấn đề:** 4 hằng số này là điểm chết người khi đổi bộ skill / đổi UI scale / đổi độ phân giải. Hiện phải sửa tay trong ini.

**Cách làm:**
- Thêm nút **"Hiệu chỉnh ô quickslot"** trong F5.
- Người dùng kéo chuột khoanh 1 ô bất kỳ (dùng lại `DragSelect`).
- Script suy ra: `QS_X0`, `QS_Y1|Y2`, `QS_DX` (nếu khoanh ≥2 ô liền kề thì suy luôn `DX`).
- Ghi lại theo **px tại khung `RefW x RefH`** (quy đổi ngược bằng `ScaleX/ScaleY`) để giữ đúng semantics hiện tại.

**Nghiệm thu:** Đổi cửa sổ game sang 1920×1080 sau khi calibrate ở 1366×768 → F2 vẫn báo "SẴN SÀNG".

---

### P1-2. Hồ sơ (profile) cho từng bộ skill

**Vấn đề:** `[Skills]`, `[Buff]`, `[Buff2]` nằm chung `settings_v1.ini`; đổi nhân vật/bộ skill phải sửa tay 14 dòng.

**Cách làm:**
- Tách `[Skills]` + `[Buff]` + `[Buff2]` sang `profiles/<tên>.ini`.
- Thêm `[General] Profile=default` + dropdown chọn profile trong F5.
- Hotkey (mặc định `F8`) để xoay vòng profile, có HUD báo tên.
- Nút **Xuất / Nhập** profile để chia sẻ.

**Nghiệm thu:** 2 profile (`farm-map1`, `boss`) chuyển qua lại bằng F8, không cần khởi động lại.

---

### P1-3. Nhận diện trạng thái bằng ảnh thu nhỏ thay vì 15 điểm màu

**Vấn đề:** mỗi zone (`G_LOGIN`, `L_PLAY`, `G_CHANNEL`…) đang so 15 điểm màu với dung sai cố định. Đổi theme UI, đổi độ phân giải lẻ, hoặc khác driver GPU → sai.

**Cách làm:**
- Lưu thêm ảnh thu nhỏ 32×32 (grayscale) của zone.
- So bằng **NCC / SAD chuẩn hoá** → điểm tương đồng 0..100, ngưỡng cấu hình được (`ZoneSimMin`, mặc định 85).
- Giữ phương pháp điểm màu làm fallback (zone cũ chưa có ảnh vẫn chạy).

**Nghiệm thu:** Zone học ở 1366×768 nhận đúng ở 1280×720 và 1920×1080 với `SlotScale=uniform`.

---

### P1-4. Tự phát hiện "khung hình đã đổi" và reset cache

**Vấn đề:** `QsCw/QsCw/QsCh` và `BdMx/BdMy` chỉ so theo giá trị; khi cửa sổ đổi kích thước giữa phiên, có thể dùng ảnh cũ trong ≤80ms — thực tế thường ổn nhưng nên chủ động.

**Cách làm:**
- Trong `Loop1`: nếu `(cw, ch)` khác lần trước → `QsOk := false`, `BdOk := false`, ghi `DLog("ENV: cửa sổ đổi ...")`, và cảnh báo HUD nếu tỉ lệ lệch `RefW/RefH` > 5%.

**Nghiệm thu:** Kéo co cửa sổ game → log có dòng `ENV: cửa sổ đổi`, không có lần đọc màu sai.

---

### P1-5. Cảnh báo cấu hình sai ngay khi khởi động

Kiểm tra lúc load, hiện trong HUD + log:
- `RefW/RefH` lệch tỉ lệ so với cửa sổ game hiện tại > 5% mà `SlotScale=uniform` → gợi ý `stretch`.
- `QS_X0 > cw` hoặc `QS_Y1 > ch` → cấu hình vô lý.
- Skill trùng phím / trùng hàng ô (dễ gây "kẹt").
- `MaxSkillRows` < số dòng `[Skills]` đang dùng.

**Nghiệm thu:** Cố tình đặt `QS_X0=99999` → HUD báo lỗi rõ ràng, không im lặng.

---

## 3. P2 — Nên làm sau (giá trị trung bình, đụng nhiều code)

### P2-1. Tách file bằng `#Include`
`maple_auto_v1.ahk` đã ~3.700 dòng. Tách:
```
core/scale.ahk      core/capture.ahk   core/zones.ahk
core/skills.ahk     core/buff.ahk      core/relogin.ahk
ui/settings.ahk     ui/hud.ahk         main.ahk
```
Lợi ích: sửa scaling chỉ đụng 1 file; giảm rủi ro "global trắng" của AHK v2.

### P2-2. Bộ test tự động cho phần toán
`tests/scale_test.ahk`: bảng `(mode, cw, ch) → kx/ky/YFactor/YRatio` so với giá trị kỳ vọng, exit code ≠ 0 nếu lệch. Chạy trước mỗi lần phát hành. Đã có script thử trong `%TEMP%`, chỉ cần chuyển vào repo.

### P2-3. Đo hiệu năng có ngưỡng
`PerfReport` đã có (30s/lần). Thêm: cảnh báo khi `BitBlt` > 5ms hoặc `Loop1` chiếm > 3ms trung bình — phát hiện sớm máy yếu / DPI scaling nặng.

### P2-4. Nhiều mẫu màu cho slot (multi-theme)
`slot_base_v1.ini` hiện có 1 bộ `[Band]`. Cho phép lưu nhiều bộ (theme sáng/tối, hiệu ứng trong suốt) và tự chọn bộ khớp nhất.

### P2-5. Hỗ trợ cửa sổ game bị Windows scale (DPI ≠ 100%)
Nếu game không phải DPI-aware, Windows phóng bitmap → toạ độ "mềm" khác "cứng". Thêm `[Detect] DpiComp=0|1` để nhân thêm `A_ScreenDPI/96` cho nhánh `native`.

---

## 4. Việc nhỏ còn tồn (dọn dẹp)

- [ ] Bổ sung mô tả `RefW/RefH/SlotScale` vào `HUONG_DAN_CAI_DAT.txt` (dòng ~36).
- [ ] Sau lần chạy đầu, ghi `RefW/RefH` thực tế vào ini (hiện `0` = tự dò) để log dễ đối chiếu.
- [ ] Xoá file thử trong `%TEMP%`: `ahk_scale_test.ahk`, `ahk_scope_test.ahk`, `ahk_mon_test.ahk`.
- [ ] Kiểm thử thực tế ≥3 độ phân giải: 1366×768, 1600×900, 1920×1080 (cùng 16:9) và 1 cửa sổ bị kéo lệch tỉ lệ.

---

## 5. Thứ tự thực hiện đề xuất

```
P1-1 (Calibrate)  ──┐
P1-5 (Cảnh báo)     ├─→ P1-4 (reset cache) ─→ P2-1 (tách file) ─→ P2-2 (test)
P1-2 (Profile)    ──┘
P1-3 (Ảnh thu nhỏ) ─── làm độc lập, sau cùng
```

Lý do: P1-1 + P1-5 giải quyết 80% lỗi "đổi máy là hỏng" mà không đụng kiến trúc. P1-2 giải quyết "bộ skill khác". Tách file (P2-1) chỉ nên làm **sau** khi P1 ổn định, để tránh vừa refactor vừa sửa logic.

---

## 6. Tiêu chí nghiệm thu chung

Một bản phát hành được coi là "tương thích" khi:

1. Cùng 1 `settings_v1.ini` chạy đúng ở 1366×768, 1600×900, 1920×1080 (16:9).
2. Kéo cửa sổ game lệch tỉ lệ 10% vẫn nhận đúng khi đặt `SlotScale=stretch`.
3. Đổi bộ skill chỉ cần đổi profile, không sửa code.
4. Dòng `ENV:` trong `debug_v1.log` luôn khớp với thực tế (`kx`, `ky`, `RefW/RefH`, `SlotScale`).
5. Không có hồi quy: `settings_v1.ini` cũ (không có 3 key mới) vẫn chạy như trước.
