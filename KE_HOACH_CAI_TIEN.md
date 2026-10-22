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

---

## 7. Nhật ký thay đổi

- **22/10/2026 — P1-4 + P1-5 xong**
  - `FrameCheck()` gọi mỗi vòng: cửa sổ game đổi kích thước → `QsOk := false`, `BdOk := false` (không dùng ảnh chụp theo khung cũ) + log `ENV: cửa sổ game đổi WxH → xoá ảnh đã chụp, kx=... ky=...`.
  - `RatioCheck()`: lệch tỉ lệ khung tham chiếu > 5% khi `SlotScale=uniform` → log `CẢNH BÁO CẤU HÌNH` + cảnh báo trên HUD.
  - `ValidateCfg()` chạy 1 lần lúc khởi động: skill trùng phím, skill trùng ô (hàng/cột), `QS_DX <= 0`, `QS_X0`/`QS_Y1`/`QS_Y2` ngoài `RefW x RefH` → log + HUD.
  - Kiểm thử logic: 7/7 ca PASS (trùng phím, trùng ô, cấu hình đúng, `QS_X0` vô lý, 16:9 khớp, lệch 15%, lệch 2%, `stretch` không cảnh báo).
- **22/10/2026 — Log đủ căn cứ nghiệm thu**
  - `StartupLog()`: khối `PHIÊN` đầu file log (đường dẫn script + kích thước + giờ sửa, đường dẫn settings, khung tham chiếu, `SlotScale`, `GameResW`, số skill, phím chính, nhịp timer, `MaxRetry`/`RetryGapMs`/`SlowRetryMs`, chụp gộp, canh đăng nhập).
  - `CfgSummary()`: luôn ghi 1 dòng `KIỂM TRA CẤU HÌNH: OK ...` (trước đây im lặng khi không có lỗi).
  - `FrameGeom()`: dòng `KHUNG` ghi toạ độ thật của dải Quickslot (client WxH, kx/ky, toạ độ ô đầu hàng trên/dưới, bước ngang, cao ô).
  - `RatioCheck()`: luôn ghi 1 dòng `TỈ LỆ` khi cửa sổ đổi (kể cả trong ngưỡng) để biết đã kiểm tra.
  - `QsCapture()`: `QS:` giờ ghi mỗi khi **vùng chụp đổi** (kèm client, kx, ky, số lần) thay vì chỉ 3 lần đầu.
  - `PerfReport()`: thêm dòng `TỔNG` (✓/✗ kiểm tra skill, số lần cửa sổ đổi, có cảnh báo cấu hình/tỉ lệ, có `GameHwnd`); `BENCH định kỳ` từ 5 phút xuống **2 phút**.
  - `OnExitLog()`: dòng `KẾT THÚC` tổng kết khi thoát.
  - Kiểm thử: `ahk /validate` ExitCode=0; chạy thật 16 giây ở máy host → log ra đúng khối `PHIÊN` (3 dòng), `KIỂM TRA CẤU HÌNH`, `ENV`, `PERF`+`TỔNG`, `KẾT THÚC`; không lỗi runtime.
- **22/10/2026 — Tự học lại màu ô + bảng skill 2 hàng mặc định (yêu cầu mới)**
  - Nguyên nhân phím S "mãi không hồi xong": 3 điểm dò (`BandPts`) bị nhân `kx/ky` sau khi đổi kích thước/hiệu ứng → lệch khỏi dải xám → `SampleDist` luôn lớn hơn `ReadyDist` → ô bị coi là hồi chiêu vĩnh viễn, không có cơ chế tự hiệu chuẩn.
  - Thêm key `[Detect] RelearnMin` (mặc định **5** phút, `0` = tắt) + ô nhập trong F5 + ghi vào `PHIÊN`/`KIỂM TRA CẤU HÌNH`.
  - `ScanSlotsInner()`: mỗi skill có `s["coolSince"]`; ô ở trạng thái hồi chiêu liên tục ≥ `RelearnMin` phút → `RelearnSlot()`.
  - `RelearnSlot(s)`: đọc lại 3 điểm của **riêng ô đó**, cập nhật `Base[key]` + `slot_base_v1.ini`, đặt `st := 1`/`force := false`, tăng biến đếm `Relearns`, log `TỰ HỌC LẠI MÀU: ... cũ: ... | mới: ...`.
  - Đếm `tự học lại màu N lần` trong `TỔNG` + `KẾT THÚC`, hiện `tự học lại:N` trên HUD.
  - **Thay** việc phải tự nhập phím/hàng/cột trong bảng skill F5 bằng **danh sách 2 hàng phím mặc định**: `KeyLayout` = `Q W E R T 1..9 O P` (ô hàng 1, cột 0..15) / `A S D F Ctrl Alt Z X C U I J K L N M` (ô hàng 2, cột 0..15), `Ctrl` lưu là `control`.
  - `DefaultSkills` (32 dòng) + `MaxSkillRows` 14 → **34** (dư chỗ cho phím ngoài danh sách).
  - F5 **bỏ hẳn 2 cột "Hàng ô"/"Cột ô"**: bảng chỉ còn `Bật / Phím / Cooldown / Lặp / Không dừng V`; cột **Phím** là `ReadOnly` (nền xám) — hàng/cột ô do `LayoutEntry(i)` suy ra từ `KeyLayout`, ghi thẳng vào ini khi LƯU. Hai dòng cuối vẫn cho nhập phím lạ (chỉ dùng bộ đếm, hàng/cột giữ nguyên).
  - `MigrateSkillLayout()` chạy 1 lần trong `CreateDefaults()`: giữ nguyên cooldown/lặp/không-dừng-V/bật của phím đã có, chỉ sắp lại theo 2 hàng và ghi đè hàng/cột; phím lạ đẩy xuống cuối; idempotent (so sánh trước khi ghi).
  - `ValidateCfg()` cảnh báo khi phím thuộc 2 hàng mặc định nhưng hàng/cột lệch `KeyLayout`.
  - `ahk /validate` ExitCode=0.
- **22/10/2026 — Chống học nhầm màu hồi chiêu + chống ấn dồn dập (sửa hồi quy của mục trên)**
  - Lỗi thực tế: chạy `RelearnMin=3` trong Sandbox → script **học nhầm màu đang hồi chiêu** làm màu "sẵn sàng" → `st` luôn `1` → `ColorReady` luôn đúng → ấn liên tục → **bị đăng xuất** → `SkillStuckCheck()` chạy quy trình đăng nhập lại → rơi vào xử lý kẹt.
  - `cdSample`: sau mỗi lần kiểm tra `✓`, ghi màu ô lúc **đang hồi chiêu**, lấy 2 mẫu (ngay sau khi ấn + sau 1,5 giây qua `cdAt`) để bỏ hiệu ứng loé.
  - `RelearnSlot(s, cur)` viết lại: chỉ học khi mẫu **khác `cdSample`** (`> VerifyDist`), **không phải nháy trắng** (`SampleIsWhite`), **khác màu chuẩn cũ**, và đã giữ nguyên ≥ 2 giây (`diffSince`); tối đa 1 lần / 30 giây (`relearnAt`).
  - `probe`: nếu **chưa biết** `cdSample` mà ô bị coi là hồi chiêu quá `RelearnMin` phút → ấn **thử 1 lần** (log `THỬ LẠI <phím>`) để lấy mẫu màu hồi chiêu; `CheckVerify()` nhận `✗` của lần ấn thử thì **không** tăng `fails`, **không** thử lại dồn dập.
  - `blocked`: ô bị coi là hồi chiêu quá `RelearnMs` phút **và** đã biết màu hồi chiêu → tạm ngừng ấn phím đó `Max(10 phút, 2×RelearnMs)`, log `!!! KHÔNG ĐỌC ĐƯỢC Ô <phím> ... Mở F5 > Màu chuẩn ô > Lấy lại màu ...`, HUD hiện `<phím>⛔`.
  - `fails`: đếm số lần ấn liên tiếp bị `✗`; giãn cách `RetryGapMs` (≤ `MaxRetry`) → `SlowRetryMs × 2^n`, chặn trên 5 phút; **5 lần** → `blocked` 10 phút + log `!!! TẠM NGỪNG ẤN <phím>`. `✓` reset `fails`.
  - `VerifyOkAt`: mốc lần `✓` gần nhất; `SkillStuckCheck()` **không** chạy quy trình đăng nhập lại nếu còn `✓` trong 2 phút qua (chỉ reset `retries`) → tránh đăng xuất oan.
  - `ShiftTimes()`/`ResetTimers()` dời/đặt lại `blocked`, `diffSince`, `coolSince`, `cdAt`, `probe`, `fails`.
  - Đổi nghĩa `RelearnMin` trong F5/`PHIÊN`/`KIỂM TRA CẤU HÌNH`/README: "ô bị coi là hồi chiêu quá lâu → **tạm ngừng ấn phím đó**".
  - `ahk /validate` ExitCode=0.
- **22/10/2026 — F5 chia 4 thẻ + sửa nút LƯU + phím "chết" vì ô kẹt**
  - **F5 quá bự** -> `ShowSettings()` viết lại: `AddTab3` 4 thẻ **Chung / Skill / Buff / Đăng nhập lại** (`x16 y34 w688 h560`), nội dung mỗi thẻ dùng toạ độ tuyệt đối của cửa sổ (y 64..586). Bỏ `MakeScrollable()` khỏi F5 (chỉ còn dùng cho `ShowZoneGui`).
  - 4 nút **LƯU / Màu chuẩn ô / Mở HƯỚNG DẪN / Đóng** đưa ra **đáy cố định** `y610`, nằm ngoài tab -> bấm được ở mọi thẻ. `g.Show("w732 h676 Center")` thay `AutoSize` (AutoSize cắt mất hàng nút đáy — đã đo bằng probe).
  - **Bug chặn nút LƯU**: `GuiCtl["rows"].Push({e1:...})` dùng object literal, mà AHK v2 **không** hỗ trợ `obj["strkey"]` (chỉ `Map` mới có) -> `SaveSettings()`/`ListSkills()` chết với `This value of type "Object" has no property named "__Item"` nên không ghi ini, không reload. Đổi sang `Map(...)`. Cooldown trống -> mặc định **60** thay vì báo lỗi chặn. Bọc `IniWrite/IniDelete` trong `try/catch` + đọc lại `ToggleKey` để xác minh trước khi `Reload`.
  - **Phím "chết"**: (a) vòng ấn skill reset `s["wait"] := 0` **trước** nhánh "ô kẹt" nên mỗi vòng lại hẹn giữ 2 giây -> **không bao giờ ấn**; chuyển việc reset vào nhánh "còn hồi chiêu thật". (b) `ScanSlotsInner()` chỉ áp dụng mốc "quá hạn" khi `press > 0` (trước đây `press = 0` khiến mọi phím bị coi là kẹt ngay khi bật script). (c) phím **chưa ấn lần nào** được ấn ngay (`how = "chưa ấn lần nào"`) thay vì bị bỏ qua vĩnh viễn. (d) `blocked` hết hạn -> `HẾT TẠM NGỪNG`, xoá cờ + quên `cdSample` + `st := -1` để thử lại. (e) HUD hiện `<phím>(bộ đếm)` cho phím đang ấn theo bộ đếm.
  - Test: `ahk /validate` ExitCode=0; 9/9 ca logic quyết định ấn skill PASS (`t7.ahk`), gồm ca1 chưa ấn lần nào, ca2-3 ô kẹt giữ 2s rồi ấn, ca4 bộ đếm chưa hết, ca5-6 tạm ngừng/hết tạm ngừng, ca7-8 ô sẵn sàng; test bấm LƯU thật (bản copy strip elevation) -> ini ghi đúng, script reload, không còn lỗi `__Item`.- **22/10/2026 (tiếp) — sửa 'giao diện đè lên thẻ đầu'**
  - Nguyên nhân: ShowSettings() đặt 	ab.Value := n rồi thêm control bằng toạ độ **tuyệt đối của cửa sổ** -> điều khiển của cả 4 thẻ cùng bị vẽ vào vùng hiển thị, thẻ sau đè lên thẻ trước.
  - Sửa: dùng 	ab.UseTab(n) cho từng thẻ, control tạo bằng g.AddText/AddEdit/... (không phải 	ab.AddText — Gui.Tab không có phương thức này) với toạ độ **tương đối** (0,0 = góc trên-trái vùng thẻ). Kết thúc bằng 	ab.UseTab(1) (mở thẻ đầu) + 	ab.UseTab() (trả về cửa sổ) rồi mới tạo 4 nút đáy y610.
  - Đo bằng probe: SysTabControl321 16,34 682x532 vùng nội dung -> 4 thẻ có số control hiện khác nhau (Chung 40, Skill 191, Buff 28, Đăng nhập lại 17) chứng minh ẩn/hiện đúng; maxX ≤ 676, nội dung maxY ≤ 590, chỉ 4 nút đáy nằm ngoài thẻ (đúng thiết kế).
  - Cắt tràn: ComboBox hành động buff w440 -> w420 (250+440=690 > 682), khối text hướng dẫn Skill y444 -> y440 (444+90=534 > 532).
  - Test LƯU sau khi chia thẻ: bấm BM_CLICK -> ini ghi lại **giống hệt** bản trước (diff = 0 dòng), script Reload, không lỗi.
- **22/10/2026 (tiếp) — thẻ Buff: thêm/bớt dòng buff (nút + / −)**
  - Trước đây cứng 2 dòng buff (`[Buff]`, `[Buff2]`) nên không thêm được buff khác (vd thêm Q bên cạnh 6).
  - Danh sách buff thành tuỳ biến: `[Buff]`, `[Buff2]`, `[Buff3]`... tối đa **7** dòng; số dòng lưu ở `[Buff] Count`.
    File ini cũ chưa có `Count` thì `BuffCountInit()` tự đếm các section đang có -> không phải sửa tay.
  - `BuffSec(i)` (tên section), `BuffVal(i,key)` (giá trị + mặc định: dòng 1 = q, dòng 2 = 6, dòng ≥3 = trống + tắt), `BuffRowVal()` (ưu tiên bản nháp đang sửa).
  - Thẻ Buff dựng theo `BuffEditN`; nút **Thêm buff (+)** / **Bớt buff (−)** gọi `BuffRowDelta(d)`: chụp giá trị đang sửa vào `BuffDraft` rồi dựng lại cửa sổ (`SettingsGui.Destroy()` + `ShowSettings()`) nên **không mất chữ đang nhập**. Chạm trần 7 -> ToolTip "Tối đa 7 dòng buff."
  - Hàng buff thu gọn 60 -> **52px/dòng** để 7 dòng vẫn vừa thẻ (footer ở y392..437, nút +/− ở y478, vùng nội dung thẻ cao 532).
  - `SaveSettings()`: validate + ghi theo `GuiCtl["bufN"]`, ghi `Count`, và `IniDelete` các khoá của section dư khi bớt dòng.
  - `StartupLog()` thêm `BuffSummary()`: log `... | 3 dòng buff, bật 2 (Q,6) | ...` để nghiệm thu nhanh.
  - Test (probe trong process): + hai lần -> 4 dòng; + tới trần -> 7 dòng, layout `maxX=678 maxY nội dung ≤590`, không tràn; giữ nháp `B1_EverySec=333`, `B2_Key=y`, `B3_Key=q` qua lần dựng lại; LƯU -> ini `Count=4`, `[Buff] EverySec=333`, `[Buff3] Enabled=1 Key=q`, script reload, log `3 dòng buff, bật 3 (Q,6,Q)`. `ahk /validate` = 0.
- **22/10/2026 (tiếp) — thẻ Buff: dòng 1 không hiện + log kiểm tra hình học**
  - Người dùng báo thẻ Buff chỉ thấy dòng 2 (`Tự buff 2` = 6), không thấy dòng 1 (Q). Lỗi có từ bản 2 dòng cố định.
  - Nghi mép trên vùng thẻ che dòng đầu -> đẩy dòng buff xuống: bắt đầu `y=16` (trước là 8); 7 dòng vẫn vừa (y 16..368, đáy thẻ 532, nút +/− ở 478).
  - Thêm `GuiGeomLog(nB)` gọi ngay sau `g.Show()`: ghi 1 dòng log `GUI Buff: N dòng | thẻ=x,y wxh | B1 y=16 'Tự buff 1' hiện | ...` (dùng `GetPos` + `IsWindowVisible`, tự chuyển sang thẻ Buff rồi trả về thẻ Chung). Có dòng này thì biết ngay dòng 1 bị **ẨN** (gán sai trang thẻ) hay **hiện nhưng bị che** (khuất mép).
  - Test: 2 dòng -> `B1 y=16 hiện | B2 y=68 hiện`; 7 dòng -> B1..B7 y=16,68,120,172,224,276,328 đều `hiện`. `ahk /validate` = 0.

- **22/10/2026 (tiếp) — SỬA GỐC: control trong thẻ bị đặt sai gốc toạ độ (lệch 58px)**
  - Tìm ra nguyên nhân thật: AHK v2 đặt control của trang thẻ theo gốc client của **cửa sổ**, không theo gốc **trang thẻ**. Mọi control bị dịch lên đúng 58px (khoảng cách đỉnh vùng thẻ tới đỉnh trang = tiêu đề + text giới thiệu + dải tab), nên control nào có `y < 58` bị cắt hoàn toàn.
  - Đo thực tế: `B1_Enabled` GetPos y=16 nhưng trên màn hình y = trang thẻ − 42px; `ToggleKey` (thẻ Chung) −53px; `UseSlotCheck` (thẻ Skill) −50px; `ReOn` (thẻ Đăng nhập lại) −50px. Thử `y=16/40` vẫn mất, `y=58/70` mới hiện -> ngưỡng an toàn 58.
  - Đã thử và loại: `Control.Move()` sau `Show()` (không tác dụng), thêm text ngoài thẻ (không đổi).
  - Cách sửa: thêm `TabPageShift(g)` — sau `g.Show()`, đo `GetWindowRect(trang)` so với `ClientToScreen(cửa sổ)` để lấy độ lệch thật, rồi `SetWindowPos` (NOSIZE|NOZORDER|NOACTIVATE) đẩy toàn bộ control của từng trang xuống đúng độ lệch (có đổi toạ độ màn hình -> client của trang bằng `ScreenToClient`). Log (debug): `GUI thẻ: trang N ctl bù 58px`.
  - Nhờ đẩy bằng độ lệch thật, nội dung thẻ dùng được gần hết chiều cao: tăng `AddTab3` `h560 -> h600`, cửa sổ `676 -> 716`, 4 nút đáy `y610 -> y650`. Thẻ Buff giữ nguyên 52px/dòng (7 dòng tới y=380, nút +/− y=478) — không phải nén. Thẻ Skill: 34 phím vẫn 2 cột x 17 dòng (đáy 463), dòng ghi chú dời `y440 -> y466` và rút còn 3 dòng để không đè dòng cuối (đáy 511 < 514).
  - Nghiệm thu bằng ảnh chụp + OCR cả 4 thẻ: thẻ Buff hiện `buff 1: phím ... q` + `buff 2: phím 6` (trước chỉ có dòng 2); thẻ Chung hiện dòng đầu `Phím bật đầu / tạm dừng / tiếp tục:`; thẻ Skill hiện checkbox `Đọc ô quickslot...` + 5 tiêu đề cột; thẻ Đăng nhập lại hiện khối hướng dẫn trên cùng. Không control nào bị cắt, không đè nút. `ahk /validate` = 0. Bản dựng: `20261022-build4`.
---

## 2026-10-22 - build5: tuỳ chọn tự học màu (BETA), thời gian ngừng ấn 1 phím, F2 tô màu, F5 bật/tắt

**1. Nút bật/tắt tự học lại màu (BETA)**
- Thêm `Detect > Relearn` (mặc định `0` = TẮT) + checkbox **Tự học lại màu ô (BETA)** ở đầu thẻ Skill; `StartupLog` ghi rõ BẬT/tắt.
- Code: mọi nhánh học màu trong `ScanSlotsInner` (`diffSince` + `RelearnSlot`) và nhánh ấn thử lấy mẫu `cdSample` đều chặn bằng `RelearnOn`. Khi tắt, script không bao giờ tự đổi `slot_base_v1.ini`.

**2. Tuỳ chỉnh thời gian ngừng ấn 1 phím**
- Thêm `Detect > BlockMin` (mặc định `10`, cho 0-120) + ô nhập trong thẻ Skill; `SaveSettings` kiểm tra hợp lệ.
- Thay toàn bộ hằng số `600000` cứng: `CheckVerify` (5 lần ✗ liên tiếp) và `ScanSlotsInner` (ô bị coi là hồi chiêu quá `RelearnMin`) dùng `BlockMs`; đặt `BlockMin=0` thì **không bao giờ** ngừng ấn mà chỉ ghi log cảnh báo.
- Log đổi theo giá trị thật (không còn "10 phút" viết cứng); bỏ `Max(600000, RelearnMs*2)` - giờ đúng `BlockMin` phút.

**3. F2 tô màu**
- `DebugSlots` đổi từ `ToolTip` 1 khối chữ sang cửa sổ `Gui +AlwaysOnTop -Caption +ToolWindow` (tự đóng sau 10 giây, bấm F2 lần nữa để dựng lại): **xanh lá = SẴN SÀNG**, **đỏ = HỒI CHIÊU**, **xám = chưa lưu màu chuẩn** + dòng tổng kết số phím sẵn sàng/hồi chiêu.

**4. Đổi nhãn + dọn nút**
- Tiêu đề cột thẻ Skill: `Cooldown (s)` -> `Cooldown (giây)`, `Lặp` -> `Ấn lặp (bỏ hồi chiêu)`, `Không dừng V` -> `Không dừng main Skill` (font `s8`, 2 dòng, canh giữa theo ô tick).
- Nút **Màu chuẩn ô (bảng lấy màu)...** chuyển từ hàng nút đáy vào góc phải đầu thẻ Skill; hàng đáy còn 3 nút: LƯU / Mở HƯỚNG DẪN / Đóng.
- `F5` = bật/tắt bảng (`ToggleSettings`); `Esc` = đóng **không lưu** (`OnEvent("Escape", ...)`), chỉ LƯU/Enter mới ghi ini.

**5. Sửa bố cục thẻ Skill sau khi thêm 2 ô số**
- Dòng nhãn dài bị xuống dòng đè lên ô nhập: nới nhãn (`x20 w440`) và dời ô `BlockMin` sang `x466`.
- Tiêu đề `Ấn lặp (bỏ hồi chiêu)` ở `s9` phải xuống 3 dòng -> đè dòng phím đầu; hạ font tiêu đề xuống `s8`, nới rộng 72px, dời `Không dừng main Skill` sang `x+212` là vừa 2 dòng.
- Ghi chú đáy dời `y486 -> y512` vì 2 dòng phím phụ (phím ngoài danh sách) kết thúc ở `y501`.
- Nghiệm thu tự động (không cần mắt): probe liệt kê mọi control của từng trang thẻ qua `GetWindowRect`, báo cặp control **chồng nhau** và control **bị cắt** trên/dưới trang -> cả 4 thẻ: 0 chồng, 0 cắt (Chung 33 / Skill 188 / Buff 24 / Đăng nhập 10 control). Ảnh chụp + OCR thẻ Skill xác nhận đủ 5 tiêu đề cột + 2 ô số + nút Màu chuẩn ô.

**Kiểm thử:** `ahk /validate` = 0. F2 dựng bằng probe có stub (3 xanh / 1 đỏ / 1 xám) — đếm điểm ảnh: xanh 144, đỏ 207. Bản dựng: `20261022-build5`.
