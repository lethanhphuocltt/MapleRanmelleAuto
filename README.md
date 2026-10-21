# 🍁 MapleRanmelleAuto

> **Bộ Auto toàn diện cho MapleStory Private Server — Ranmelle**  
> Viết bằng AutoHotkey v2 · Hỗ trợ Windows Sandbox · Tự đăng nhập lại khi game văng

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng](#-tính-năng)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Hướng dẫn cài đặt](#-hướng-dẫn-cài-đặt)
- [Cách sử dụng](#-cách-sử-dụng)
- [Phím tắt](#-phím-tắt)
- [Cấu hình (settings\_v1.ini)](#-cấu-hình-settings_v1ini)
  - [Danh sách Skill](#danh-sách-skill)
  - [Buff tự động](#buff-tự-động)
  - [Tự đăng nhập lại](#tự-đăng-nhập-lại)
  - [Nhận diện ô Quickslot](#nhận-diện-ô-quickslot)
- [Cửa sổ Cài đặt (F5)](#-cửa-sổ-cài-đặt-f5)
- [Nhận diện màn hình (Zones)](#-nhận-diện-màn-hình-zones)
- [Debug & Log](#-debug--log)
- [Kiến trúc kỹ thuật](#-kiến-trúc-kỹ-thuật)
- [Cập nhật GitHub](#-cập-nhật-github)
- [Lưu ý & FAQ](#-lưu-ý--faq)

---

## 🎮 Giới thiệu

**MapleRanmelleAuto** là script AutoHotkey v2 64-bit chạy trong **Windows Sandbox**, giúp tự động hóa gameplay trên server private **Ranmelle** (MapleStory). Script được thiết kế đặc biệt để:

- Hoạt động ổn định trong môi trường **Windows Sandbox** (GPU ảo, tốc độ đọc pixel chậm).
- Tự đăng nhập lại sau khi game văng mà **không cần người dùng can thiệp**.
- Hỗ trợ nhận diện hồi chiêu bằng **màu ô Quickslot** (không chỉ đếm thời gian).
- Ghi **log chi tiết** (debug + performance) để dễ chẩn đoán lỗi.

---

## ✨ Tính năng

| Tính năng | Mô tả |
|---|---|
| 🎯 **Skill tự động** | Ấn / giữ phím skill chính liên tục; tự ấn các skill phụ theo hồi chiêu |
| ⏱️ **Nhận diện hồi chiêu** | Đọc màu ô Quickslot (dải xám + nháy trắng) kết hợp bộ đếm thời gian |
| 🛡️ **Buff tự động** | Tự ấn tối đa 7 phím buff theo chu kỳ (thêm/bớt dòng trong thẻ Buff); xử lý bảng `Buff Sequence` & `EXP Coupon` |
| 🔄 **Tự đăng nhập lại** | Phát hiện game văng → mở launcher → bấm PLAY → chọn kênh → Log In |
| 🖥️ **Nhận diện màn hình** | Học vùng màn hình bằng kéo thả (launcher, chọn kênh, đang tải...) |
| 🏃 **Tự focus game** | Tự đưa cửa sổ game lên trước khi bị che/mất focus |
| 📊 **HUD trạng thái** | Tooltip hiện trạng thái skill/buff/hồi chiêu góc màn hình |
| 🐛 **Debug & Perf** | Ghi log chi tiết: CPU, RAM, thời gian từng tác vụ, phát hiện lag |
| ⚙️ **GUI Cài đặt** | Bảng cài đặt đồ họa đầy đủ (F5), lưu vào INI, tự reload script |
| 🔒 **Sandbox-safe** | Chụp gộp dải Quickslot 1 lần/lượt thay vì đọc từng điểm (nhanh hơn ~10×) |

---

## 📁 Cấu trúc thư mục

```
MapleRanmelleAuto/
├── AHK/
│   ├── maple_auto_v1.ahk      # Script chính (AutoHotkey v2, ~3650 dòng)
│   ├── AutoHotkey64.exe        # Runtime AHK v2.0.19 64-bit (không cần cài)
│   ├── settings_v1.ini         # Cài đặt hiện tại (skill, buff, kênh, v.v.)
│   ├── slot_base_v1.ini        # Màu chuẩn ô Quickslot (lưu bằng F5 > Màu chuẩn)
│   ├── start_v1.cmd            # Khởi động: chạy AHK rồi mở launcher
│   ├── debug_v1.log            # Log debug (tự sinh, tối đa 500 dòng)
│   ├── error_v1.log            # Log lỗi script
│   └── AutoHotkey-LICENSE.txt  # Giấy phép AutoHotkey (GPLv2)
├── DLL/
│   └── *.dll                   # Visual C++ Runtime (vcruntime140, msvcp140...)
├── Game.wsb                    # Cấu hình Windows Sandbox
├── install_vc.ps1              # Cài VC++ & AHK trong Sandbox (chạy tự động)
├── HUONG_DAN_CAI_DAT.txt       # Hướng dẫn cài đặt (tiếng Việt)
└── README.md                   # Tài liệu này
```

> **Gói này KHÔNG chứa file game.** Cần có sẵn thư mục game đầy đủ (`Ranmelle.exe`, `MapleStory.exe`, `Data/`...).

---

## 💻 Yêu cầu hệ thống

| Yêu cầu | Chi tiết |
|---|---|
| **OS** | Windows 10/11 Pro hoặc Enterprise |
| **Ảo hóa** | Bật Virtualization trong BIOS |
| **Windows Sandbox** | Bật tính năng `Windows Sandbox` trong Windows Features |
| **Mạng** | Cần mạng lần đầu để `install_vc.ps1` tải VC++ & AHK |
| **Game** | Thư mục game Ranmelle đầy đủ (có `Ranmelle.exe` + `MapleStory.exe`) |

---

## 🚀 Hướng dẫn cài đặt

### Bước 1 — Lấy gói
```bash
git clone https://github.com/lethanhphuocltt/MapleRanmelleAuto.git
# Hoặc tải ZIP trên GitHub > giải nén
```

### Bước 2 — Chép vào thư mục game
Chép **toàn bộ nội dung** gói (`Game.wsb`, `install_vc.ps1`, thư mục `AHK`, `DLL`) vào **thư mục chứa `Ranmelle.exe`**.

```
Ví dụ: E:\CleanSetupv412\
├── Ranmelle.exe
├── MapleStory.exe
├── Game.wsb              ← chép vào đây
├── install_vc.ps1        ← chép vào đây
├── AHK\                  ← chép vào đây
└── DLL\                  ← chép vào đây (nếu Sandbox thiếu VC++)
```

### Bước 3 — Cấu hình Sandbox
Mở `Game.wsb` bằng Notepad, sửa dòng:
```xml
<HostFolder>E:\CleanSetupv412</HostFolder>
```
Thành đường dẫn thư mục game thật trên máy bạn. **Giữ nguyên** `<SandboxFolder>`.

### Bước 4 — Bật Windows Sandbox *(một lần)*
```
Control Panel > Programs > Turn Windows features on or off
> ✅ Windows Sandbox > OK > Khởi động lại máy
```

### Bước 5 — Khởi động Sandbox
Nhấp đôi `Game.wsb`. Sandbox mở và **tự chạy `install_vc.ps1`** (vài phút, cần mạng lần đầu):
- Cài Visual C++ Runtime (x86 + x64)
- Cài AutoHotkey v2

### Bước 6 — Chạy Auto
Trong Sandbox, mở `Desktop\CleanSetupv412\AHK\` và chạy `start_v1.cmd`:
- Script xin quyền Admin → bấm **Yes**
- Launcher Ranmelle mở ra → đăng nhập / lưu tài khoản trong launcher
- Bấm **F1** để bắt đầu auto

---

## 🕹️ Cách sử dụng

### Quy trình thông thường
1. Mở Sandbox (nhấp đôi `Game.wsb`)
2. Chạy `start_v1.cmd` → script AHK + launcher khởi động
3. Trong launcher: đăng nhập tài khoản → bấm PLAY → vào game
4. **Bấm F1** để bật auto
5. Script tự động: giữ phím skill chính (mặc định `V`), ấn skill phụ theo hồi chiêu, ấn buff định kỳ

### Lần đầu trên máy mới
- Vào **F5 > Màu chuẩn ô** → lấy màu chuẩn từng ô Quickslot (mỗi ô khi skill **SẴN SÀNG**)
- Vào **F5 > Nhận diện màn hình** → khoanh lại các vùng (nút PLAY, lưới kênh, nút Log In, màn tải)
- Đặt **kênh cần chọn** trong F5 (mặc định CH.3)

---

## ⌨️ Phím tắt

| Phím | Chức năng |
|---|---|
| **F1** | Bật / Tạm dừng / Tiếp tục auto *(có thể đổi trong F5)* |
| **Ctrl+F1** | Dừng khẩn cấp, nhả phím, thoát script |
| **F2** | Xem độ lệch màu ô Quickslot (debug, 8 giây) |
| **F4** | Bật/tắt HUD trạng thái (tooltip góc màn hình) |
| **F5** | Mở cửa sổ **Cài đặt** |
| **F6** | Debug nhận diện bảng Buff (xem loại bảng + vị trí nút) |
| **F7** | Thử bấm nút `Use Unapplied Buffs` bằng 5 cách khác nhau |
| **F9** | Chạy thử quy trình **Tự đăng nhập lại** |

> Tất cả phím F2/F4/F6/F7 chỉ hoạt động khi **cửa sổ game đang active**.

---

## ⚙️ Cấu hình (settings\_v1.ini)

File INI được tạo tự động lần đầu. Có thể sửa bằng **F5** (giao diện đồ họa) hoặc sửa tay.

### Danh sách Skill

```ini
[Skills]
; Định dạng: phím|cooldown(giây)|hàng_ô|cột_ô|lặp|không_dừng_V|bật
; Bảng được điền sẵn 2 hàng phím mặc định (hàng 1 = ô quickslot hàng trên, hàng 2 = ô hàng dưới):
;   Q W E R T 1 2 3 4 5 6 7 8 9 O P     (cột 0..15)
;   A S D F Ctrl Alt Z X C U I J K L N M (cột 0..15)
Skill1=q|60|1|0|0|0|0     ; phím Q, CD 60s, ô hàng 1 cột 0, không lặp, đang tắt
Skill3=e|120|1|2|1|0|1    ; phím E, CD 120s, hàng 1 cột 2, có lặp, bật
Skill8=3|360|1|7|1|0|1    ; phím 3, CD 360s, hàng 1 cột 7, có lặp, bật
Skill18=s|10|2|1|1|1|1    ; phím S, CD 10s, hàng 2 cột 1, lặp + không dừng V, bật
```

| Cột | Ý nghĩa | Giá trị |
|---|---|---|
| `phím` | Phím bấm (cố định, do F5 tự điền) | `q`, `e`, `3`, `control`... |
| `cooldown` | Thời gian hồi chiêu (giây) | Số dương |
| `hàng_ô` | Hàng Quickslot (tự tính từ `KeyLayout`) | `0` = không đọc, `1` = hàng trên, `2` = hàng dưới |
| `cột_ô` | Cột Quickslot (tự tính, từ 0, tính từ phải) | `0`, `1`, `2`... |
| `lặp` | Ấn lại dù CD chưa hết (trong khoảng RepMin-RepMax) | `1`/`0` |
| `không_dừng_V` | Ấn skill mà không nhả phím chính V | `1`/`0` |
| `bật` | Bật/tắt dòng này | `1`/`0` |

### Buff tự động

```ini
[Buff]
Count=2         ; số dòng buff đang dùng (thêm/bớt bằng nút + / − trong thẻ Buff)
Enabled=1
Key=q           ; phím buff
EverySec=180    ; chu kỳ ấn (giây)
WaitSec=5       ; chờ sau khi cast xong (giây)
Action=all      ; esc | all | unapplied

[Buff2]
Enabled=1
Key=6
EverySec=180
WaitSec=5
Action=esc

[Buff3]         ; dòng 3 trở đi: cùng các khoá như [Buff2]
Enabled=0
Key=
EverySec=180
WaitSec=5
Action=all
```

- Số dòng buff lưu ở `[Buff] Count` (1..**7**). File ini cũ chưa có `Count` thì script tự đếm các section
  `[Buff2]`, `[Buff3]`... đang có, nên không phải sửa tay.
- Dòng thêm mới mặc định **tắt** và **trống phím** — bật mà để trống phím thì nút LƯU sẽ báo lỗi.

**Action khi bảng Buff Sequence hiện:**
- `esc` — Ấn ESC để tắt bảng
- `all` — Ấn Enter (Use All Buffs)
- `unapplied` — Bấm chuột vào nút "Use Unapplied Buffs"

### Tự đăng nhập lại

```ini
[Relogin]
Enabled=1
LauncherExe=Ranmelle.exe    ; tên file launcher
Channel=3                    ; kênh cần chọn (1-30)
LostSec=8                    ; giây chờ sau khi mất game mới coi là văng
MaxTries=3                   ; số lần thử tối đa
AttemptSec=300               ; thời gian tối đa mỗi lần thử (giây)
PlaceWindows=1               ; tự đặt vị trí cửa sổ (game giữa màn, launcher góc trên-trái)
```

**Luồng tự đăng nhập lại:**
```
Mất game > Chờ LostSec giây > Mở launcher (nếu chưa có)
> Đọc chấm GAME > Bấm PLAY > Chờ game mở
> Nhận ra màn chọn kênh > Bấm kênh CH.N > Bấm Log In
> Nhận ra màn đang tải > Chờ tải xong > Coi là đã vào game ✓
```

**Xử lý kẹt theo bậc thang:**
| Bậc | Hành động |
|---|---|
| 0 | Ấn ESC để tắt bảng thông báo đang che |
| 1 | Kiểm tra lại, làm lại các bước từ trạng thái hiện tại |
| 2 | Đóng game, đăng nhập lại từ đầu |
| 3 | Đóng cả game + launcher, đăng nhập lại từ đầu |
| 4 | Báo thất bại, dừng auto |

### Nhận diện ô Quickslot & quy đổi theo độ phân giải

```ini
[Detect]
UseSlotCheck=1      ; 1 = đọc màu ô; 0 = chỉ dùng bộ đếm
GameResW=1366       ; độ rộng game lúc đo px (0 = không phóng) - giữ cho tương thích ini cũ
RefW=1366           ; vùng game (rộng) lúc đo các số px bên dưới; 0 = theo GameResW, rồi tự lấy vùng đang mở
RefH=768            ; vùng game (cao) lúc đo; 0 = 9/16 của RefW, rồi tự lấy vùng đang mở
SlotScale=uniform   ; uniform = phóng đều theo chiều rộng (như bản cũ) | stretch = X theo rộng, Y theo cao | native = giữ nguyên px
QS_X0=544           ; khoảng cách từ mép phải game đến cột đầu tiên (px tại khung RefWxRefH)
QS_DX=35            ; khoảng cách giữa 2 cột (px)
QS_Y1=64            ; hàng trên cách mép dưới (px)
QS_Y2=29            ; hàng dưới cách mép dưới (px)
ReadyDist=45        ; ngưỡng lệch màu để coi là "sẵn sàng"
BatchCapture=1      ; 1 = chụp gộp dải ô 1 lần (nhanh hơn nhiều trong Sandbox)
RelearnMin=5        ; ô bị coi là "hồi chiêu" quá chừng này phút -> tạm ngừng ấn phím đó + cảnh báo (0 = tắt)
```

**Tự học lại màu ô + chống ấn dồn dập (`RelearnMin`).** Màu chuẩn của ô được lưu lúc còn ở một
kích thước/hiệu ứng nhất định; sau khi đổi kích thước cửa sổ, đổi bộ skill hoặc đổi hiệu ứng, 3 điểm
dò có thể rơi lệch khỏi dải xám → ô bị coi là "hồi chiêu" mãi (hay gặp với phím S). Script xử lý
theo các lớp sau. Trên HUD: `<phím>⛔` = phím đang bị tạm ngừng ấn.

1. **Tự học lại màu, chỉ khi có bằng chứng ô ĐÃ rời màu hồi chiêu.** Sau mỗi lần ấn mà skill ra
   (kiểm tra `✓`), script ghi lại màu ô lúc đang hồi chiêu (`cdSample`, lấy 2 lần: ngay sau khi ấn và
   sau 1,5 giây để bỏ hiệu ứng loé). Khi ô đang bị coi là "hồi chiêu" nhưng màu **khác hẳn**
   `cdSample` và giữ nguyên **≥ 2 giây** → coi đó là màu lúc sẵn sàng, ghi vào `slot_base_v1.ini`,
   log `TỰ HỌC LẠI MÀU: <phím> ... cũ: ... | mới: ...`. Mỗi phím học lại tối đa 1 lần / 30 giây.
   **Không bao giờ** lấy màu đang hồi chiêu làm màu chuẩn — đây chính là lỗi của bản cũ: học nhầm màu
   hồi chiêu → ô luôn "sẵn sàng" → ấn liên tục → bị đăng xuất.
2. **Chưa biết màu hồi chiêu** (skill chưa từng ấn ra lần nào): quá `RelearnMin` phút → ấn **thử 1
   lần** để lấy mẫu màu hồi chiêu (log `THỬ LẠI <phím>: ... ấn thử 1 lần ...`), không thử lại dồn dập.
3. **Ô bị coi là hồi chiêu quá `RelearnMin` phút** (mặc định **5**; đã biết màu hồi chiêu): **không**
   ấn phím đó nữa trong 10 phút, HUD hiện `<phím>⛔`, log
   `!!! KHÔNG ĐỌC ĐƯỢC Ô <phím>: ... Mở F5 > Màu chuẩn ô > Lấy lại màu cho <phím>`. Ô hoạt động lại
   ngay khi bạn lấy lại màu trong F5, hoặc khi script tự học được màu mới (lớp 1).
4. **Ấn mãi không ra skill** (`✗` nhiều lần): giãn cách ấn **1,2 giây** cho 3 lần đầu, sau đó tăng gấp đôi
   mỗi lần (30s → 60s → 120s → 240s), chặn trên **5 phút**; **5 lần liên tiếp ✗** → tạm ngừng phím đó
   10 phút (`!!! TẠM NGỪNG ẤN <phím>`). `✓` reset bộ đếm. Lần **ấn thử** (lớp 2) không tính vào bộ đếm
   này, nên không bao giờ ấn dồn dập. Nếu vẫn còn skill khác `✓` trong 2 phút qua thì **không** chạy quy
   trình đăng nhập lại (tránh đăng xuất oan).
5. **Ô "kẹt" — hết hồi chiêu theo bộ đếm mà ô vẫn báo hồi chiêu:** vẫn ấn theo **bộ đếm cooldown**
   (giữ đủ 2 giây rồi ấn, cách nhau ít nhất `cooldown + 3s`) để phím không bị "chết" vì màu chuẩn cũ.
   Lần đầu ghi log `Ô KẸT: <phím> vẫn báo hồi chiêu dù bộ đếm đã hết <N>s -> ấn theo bộ đếm ...`,
   HUD hiện `<phím>(bộ đếm)`. Phím **chưa từng được ấn lần nào** cũng được ấn ngay (log `chưa ấn lần
   nào`) để lấy mẫu màu hồi chiêu — bản cũ bỏ qua vĩnh viễn trong trường hợp này.
6. **Hết hạn tạm ngừng** (lớp 3, 4): tự xoá cờ, quên `cdSample` cũ và thử lại; log
   `HẾT TẠM NGỪNG <phím>: thử lại phím này ...`.

Đặt `RelearnMin=0` để tắt lớp 2 và 3 (vẫn giữ lớp 1, 4, 5; muốn lấy lại màu bằng tay thì dùng nút
**Màu chuẩn ô**).

Mọi số px trong ini (QS_*, BandPts, điểm dò bảng buff, BtnDX/BtnDY, vùng đã khoanh) đều được
hiểu là px tại khung `RefW x RefH`. Khi cửa sổ game to/nhỏ hơn, script tự nhân hệ số theo trục:
`uniform` (mặc định - y như bản cũ), `stretch` (khung bị kéo dài/co chiều cao), `native`
(game vẽ UI đúng cỡ px, không phóng). Dòng `ENV:` trong `debug_v1.log` ghi `kx`, `ky`, `RefW/RefH`,
`SlotScale` để biết script đang quy đổi thế nào.

---

## 🖥️ Cửa sổ Cài đặt (F5)

Bảng cài đặt đồ họa chia thành **4 thẻ (tab)** để không phải cuộn: **Chung / Skill / Buff / Đăng nhập lại**.
Bốn nút **LƯU**, **Màu chuẩn ô**, **Mở HƯỚNG DẪN**, **Đóng** nằm **cố định ở đáy cửa sổ**, không thuộc thẻ nào —
bấm được ở mọi thẻ, không bị cắt khi cửa sổ nhỏ. Cửa sổ mở ở kích thước cố định 732×676.

### Thẻ Chung
- Phím bắt đầu/tạm dừng, phím skill chính, chế độ ấn (giữ / ấn nhả)
- Tên file game, class cửa sổ
- Random delay sau hồi chiêu, chế độ focus tự động
- Độ phân giải game (0 = tự dò), khung tham chiếu `RefW`/`RefH`, kiểu scale ô quickslot
- Nút **Đặt lại thời gian**, tuỳ chọn Debug

### Thẻ Skill
- Bảng 34 dòng với **phím cố định** theo 2 hàng mặc định — chỉ hiện 5 cột: **Bật / Phím / Cooldown / Lặp / Không dừng V** (không còn cột hàng ô, cột ô):
  - hàng 1 → ô quickslot hàng trên: `Q W E R T 1 2 3 4 5 6 7 8 9 O P`
  - hàng 2 → ô quickslot hàng dưới: `A S D F Ctrl Alt Z X C U I J K L N M`
- Cột **Phím** chỉ đọc (nền xám) — không sửa được, script tự tính hàng/cột ô quickslot. `Ctrl` lưu thành `control` (tên phím AHK).
- Việc cần làm: điền **Cooldown** + tick **Bật** cho phím đang dùng.
- Mặc định **bật** các phím đang dùng cũ (`e 3 2 1 4 5` + `a s d f`), các phím còn lại để tắt.
- Dòng đã có trong `settings_v1.ini` được giữ nguyên cooldown/lặp/không dừng/bật, chỉ sắp lại theo 2 hàng; phím lạ (không nằm trong danh sách) được đẩy xuống 2 dòng cuối và chỉ dùng bộ đếm thời gian.
- **Cooldown để trống = 60 giây** (không báo lỗi, không chặn nút LƯU).

### Thẻ Buff
- Mỗi dòng buff: bật/tắt, phím, chu kỳ, thời gian chờ, kiểu tác dụng (tối đa 7 dòng)
- Nút **Thêm buff (+)** / **Bớt buff (−)** ở đáy thẻ: thêm/bớt dòng buff, sau đó bấm **LƯU** để ghi
- Sau khi cửa sổ hiện, script tự đo độ lệch của từng trang thẻ rồi đẩy control xuống cho khớp (`TabPageShift`), nhờ đó dòng đầu của mọi thẻ không còn bị cắt; log (khi bật debug) ghi `GUI thẻ: trang N ctl bù 58px`
- Khi mở cửa sổ, log ghi 1 dòng `GUI Buff: N dòng | thẻ=... | B1 y=16 'Tự buff 1' hiện | ...` để kiểm tra dòng buff nào đang hiện (`hiện` / `ẨN`)
- Nút **Chọn vị trí nút** (dò nút buff trên màn hình), tuỳ chọn **Luôn ấn tay**

### Thẻ Đăng nhập lại
- Bật/tắt, đường dẫn launcher, kênh, thời gian coi là văng
- Nút **Nhận diện màn hình** — mở giao diện khoanh vùng
- Nút **Chạy thử** — kiểm tra quy trình đăng nhập lại

### Các nút cố định ở đáy
- **LƯU** (mặc định, Enter) — lưu tất cả, đọc lại INI để xác minh rồi tự reload script. Nếu ghi thất bại sẽ hiện hộp thoại báo lỗi thay vì im lặng.
- **Màu chuẩn ô** — lấy/lưu màu chuẩn từng ô Quickslot
- **Mở HƯỚNG DẪN** — mở HUONG_DAN.txt

---

## 🗺️ Nhận diện màn hình (Zones)

Script học vùng màn hình bằng **kéo thả chuột** (F5 > Nhận diện màn hình):

| Vùng | Cửa sổ | Mô tả |
|---|---|---|
| `L_PLAY` | Launcher | Nút PLAY |
| `L_DOT_IDLE` | Launcher | Chấm GAME lúc "Not running" |
| `L_DOT_RUN` | Launcher | Chấm GAME lúc "Running" |
| `G_CHANNEL` | Game | Màn chọn kênh (nền sáng) |
| `G_GRID` | Game | Lưới 30 kênh (CH.1–CH.30) |
| `G_LOGIN` | Game | Nút Log In |
| `G_LOADING` | Game | Màn đang tải (NOW LOADING) |

**Thứ tự học gợi ý:**
1. Tắt game, mở launcher → khoanh `L_PLAY` + `L_DOT_IDLE`
2. Bấm PLAY, khi launcher báo Running → bấm "Lấy màu" `L_DOT_RUN`
3. Khi game lên màn chọn kênh → khoanh `G_CHANNEL`, `G_GRID`, `G_LOGIN`
4. Bấm Log In, khi NOW LOADING → khoanh `G_LOADING`

---

## 🐛 Debug & Log

### debug\_v1.log
Ghi mọi sự kiện khi `Debug > Enabled = 1` (bật trong F5):

| Prefix | Ý nghĩa |
|---|---|
| `PHIÊN` | Thông tin đầu phiên: đường dẫn script/settings, khung tham chiếu, số skill, các mốc thời gian |
| `KIỂM TRA CẤU HÌNH` | Kết quả kiểm tra cấu hình 1 lần lúc khởi động (OK hoặc danh sách lỗi) |
| `KHUNG` | Toạ độ thật của dải Quickslot ở khung hình hiện tại (kx/ky, ô đầu, bước ngang, cao ô) |
| `ẤN X` | Ấn phím skill X |
| `BUFF X` | Ấn phím buff X |
| `[ĐN]` | Quy trình đăng nhập lại |
| `PERF` | Báo cáo hiệu năng 30 giây/lần |
| `TỔNG` | Cộng dồn mỗi 30 giây: kiểm tra skill ✓/✗, số lần tự học lại màu ô, số lần cửa sổ đổi, có cảnh báo hay không |
| `TỰ HỌC LẠI MÀU` | Ô đã rời màu hồi chiêu ≥ 2 giây trong khi vẫn bị coi là "hồi chiêu" → đã cập nhật màu chuẩn (ghi rõ màu cũ/mới) |
| `THỬ LẠI` | Ô bị coi là hồi chiêu quá `RelearnMin` phút nhưng chưa biết màu hồi chiêu → ấn thử 1 lần để lấy mẫu |
| `!!! KHÔNG ĐỌC ĐƯỢC Ô` | Ô bị coi là hồi chiêu quá `RelearnMin` phút và đã biết màu hồi chiêu → tạm ngừng ấn phím đó 10 phút |
| `!!! TẠM NGỪNG ẤN` | 5 lần ấn liên tiếp kiểm tra `✗` → tạm ngừng ấn phím đó 10 phút |
| `Ô KẸT` | Hết cooldown theo bộ đếm mà ô vẫn báo hồi chiêu → ấn theo bộ đếm (mỗi lần cách nhau ≥ cooldown + 3s) |
| `MÀU CHUẨN SAI` | Chưa biết màu hồi chiêu, ô quá cooldown > 10s mà vẫn báo hồi chiêu → lấy màu hiện tại làm màu sẵn sàng |
| `HẾT TẠM NGỪNG` | Hết 10 phút tạm ngừng → xoá cờ, quên màu hồi chiêu cũ và thử lại phím đó |
| `ENV` | Thông tin môi trường (màn hình, DPI, cửa sổ game) |
| `TỈ LỆ` | Độ lệch tỉ lệ cửa sổ game so với khung tham chiếu |
| `BENCH` | Đo tốc độ đọc điểm ảnh |
| `QS` | Chụp gộp dải Quickslot (ghi lại mỗi khi vùng chụp đổi) |
| `LỖI` | Lỗi script |
| `VÒNG CHÍNH TRỄ` | Phát hiện vòng lặp bị chậm (> 1.5s) |
| `CẢNH BÁO CẤU HÌNH` | Cấu hình dễ sai (trùng phím, trùng ô, hằng số vô lý, lệch tỉ lệ) |
| `KẾT THÚC` | Tổng kết khi thoát: ✓/✗, số lần cửa sổ đổi, cảnh báo còn hiệu lực |

### Cảnh báo tự động
Script tự kiểm tra và báo cả trên HUD (dòng `!!! CẤU HÌNH` / `!!! TỈ LỆ`) lẫn trong log:

- **Lúc khởi động:** skill trùng phím, 2 skill dùng chung một ô (hàng/cột), `QS_DX <= 0`, `QS_X0` / `QS_Y1` / `QS_Y2` nằm ngoài khung `RefW × RefH`.
- **Khi cửa sổ game đổi kích thước:** xoá ảnh đã chụp (`ENV: cửa sổ game đổi WxH`) để không đọc nhầm ảnh cũ, và cảnh báo nếu tỉ lệ cửa sổ lệch khung tham chiếu > 5% trong khi `SlotScale=uniform`.
- **Khi một ô "hồi chiêu" quá lâu:** chỉ học lại màu khi có bằng chứng ô đã rời màu hồi chiêu; nếu không, tạm ngừng ấn phím đó để không bị đăng xuất (xem `RelearnMin`).
- **Khi ấn mãi không ra skill:** giãn cách tăng dần rồi tạm ngừng phím đó; không chạy quy trình đăng nhập lại nếu vẫn còn skill khác ra `✓` trong 2 phút qua.

### error\_v1.log
Chỉ ghi khi có lỗi nghiêm trọng. Format: `HH:mm:ss  message @dòng N (function)`.

### Tối ưu hiệu năng trong Sandbox
Script dùng **chụp gộp bitmap** (`BitBlt`) thay vì `PixelGetColor` từng điểm:
- `QsCapture()` — chụp cả dải Quickslot một lần, đọc pixel từ buffer RAM
- `BdCapture()` — chụp vùng bảng buff
- Tự tắt nếu lỗi 3 lần liên tiếp, fallback về đọc từng điểm

---

## 🔧 Kiến trúc kỹ thuật

```
maple_auto_v1.ahk (3650+ dòng)
│
├── Khởi động
│   ├── Đọc settings_v1.ini, slot_base_v1.ini
│   ├── KillOtherInstances() — tắt bản cũ còn sót
│   └── CreateDefaults() — tạo INI mặc định nếu chưa có
│
├── Timers (vòng lặp chính)
│   ├── TmrLoop1 (100ms) — Loop1(): xử lý skill + buff + bảng chặn
│   ├── TmrScan (1000ms) — ScanSlots(): đọc màu ô Quickslot
│   ├── TmrFlash (200ms) — ScanFlash(): phát hiện nháy trắng hồi chiêu
│   ├── TmrHud (500ms)   — UpdateHud(): cập nhật tooltip trạng thái
│   └── TmrRelog (1000ms)— ReloginWatch(): phát hiện game văng
│
├── Nhận diện hồi chiêu
│   ├── SlotSample() — đọc màu 3 điểm dải mép dưới icon
│   ├── SampleDist() — khoảng cách màu max giữa 2 mẫu
│   ├── SlotState() — 1=sẵn sàng, 0=hồi chiêu, -1=không rõ
│   ├── SlotIsWhite() — phát hiện nháy trắng
│   └── CheckVerify() — xác nhận skill đã ra (so màu trước/sau)
│
├── Xử lý Buff
│   ├── DoBuff() — ấn phím buff + xử lý bảng
│   ├── BuffDialogKind() — nhận diện loại bảng (1/2/0)
│   ├── HandleBuffDialog() — xử lý bảng theo Action
│   └── TryClickButton() — thử 5 cách bấm chuột
│
├── Tự đăng nhập lại
│   ├── ReloginWatch() — phát hiện mất tiến trình game
│   ├── DoRelogin() — điều phối máy trạng thái
│   ├── ReloginAttempt() — một lần thử (state machine)
│   ├── ScreenOf() — nhận ra màn hình game
│   ├── LauncherDot() — đọc chấm trạng thái launcher
│   └── ChooseChannelAndLogin() — chọn kênh + bấm Log In
│
└── GUI
    ├── ShowSettings() — cửa sổ cài đặt (F5)
    ├── ShowColorGui() — lấy màu chuẩn ô
    └── ShowZoneGui() — khoanh vùng nhận diện màn hình
```

---

## 📤 Cập nhật GitHub

```bash
# Từ thư mục repo (E:\CleanSetupv412\MapleAuto_GitHub\MapleRanmelleAuto\)
git status           # kiểm tra trước khi commit
git add .
git commit -m "Cap nhat: mo ta ngan gon"
git push origin main
```

> ⚠️ Kiểm tra `git status` để đảm bảo `.gitignore` đã loại trừ:
> `*.dll`, `Ranmelle.exe`, `MapleStory.exe`, `Data/`, `*.log`

---

## ❓ Lưu ý & FAQ

### Sandbox bị xóa khi đóng?
**Bình thường.** File trong thư mục game được ánh xạ (ReadOnly=false) nên cài đặt, màu chuẩn và log **vẫn còn trên máy thật**.

### Hiện bảng "We can't open this 'ms-gamingoverlay' link"?
Xbox Game Bar không có trong Sandbox. Bấm **OK / ESC** để tắt, không ảnh hưởng đến auto.

### Skill ấn mãi không ra?
1. Kiểm tra phím skill đúng chưa trong F5
2. Bấm **F2** để xem độ lệch màu ô (cần < ReadyDist = 45)
3. Vào F5 > Màu chuẩn ô > lấy lại màu chuẩn khi skill **đang sẵn sàng**
4. Kiểm tra `QS_X0`, `QS_DX`, `QS_Y1`, `QS_Y2` có đúng với khung đo `RefW x RefH` (mặc định = độ phân giải game lúc đo)

### Đổi cửa sổ game / đổi máy khác độ phân giải thì ô quickslot đọc sai?
1. Xem dòng `ENV:` đầu `debug_v1.log`: `RefW/RefH`, `SlotScale`, `kx`, `ky` phải khớp với lúc bạn đo px
2. Nếu vùng game lúc đo là 1366x768 mà nay chơi 1920x1080 cùng tỉ lệ 16:9 → để `SlotScale=uniform`
3. Nếu cửa sổ bị kéo cho cao/thấp khác tỉ lệ → đặt `SlotScale=stretch`
4. Nếu game vẽ UI đúng cỡ px không phóng → đặt `SlotScale=native`
5. Sau khi đổi, mở F5 > LƯU (script tự khởi động lại) rồi bấm **F2** xem lại độ lệch màu

### Tự đăng nhập lại không hoạt động?
1. Bấm **F9** để chạy thử (xem log `debug_v1.log`, dòng `[ĐN]`)
2. Vào F5 > Nhận diện màn hình > khoanh lại từng vùng
3. Kiểm tra đường dẫn launcher trong F5

### Chạy bản này cùng bản gốc `maple_auto.ahk`?
**Không nên.** Hai bản cùng ấn phím sẽ xung đột. Bản v1 sẽ hỏi nếu phát hiện bản gốc đang chạy.

### Phím bắt đầu không nhận?
Kiểm tra `ToggleKey` trong F5 — tên phím phải hợp lệ với AutoHotkey v2 (vd: `F1`, `F3`, `Pause`, `NumpadAdd`).

---

## 📄 Giấy phép

Script này (`maple_auto_v1.ahk`) là tài sản riêng của tác giả.  
AutoHotkey đi kèm (`AutoHotkey64.exe`) được phân phối theo **GPLv2** — xem `AHK/AutoHotkey-LICENSE.txt`.

---

*Được phát triển cho Ranmelle Private Server — MapleStory v412*
