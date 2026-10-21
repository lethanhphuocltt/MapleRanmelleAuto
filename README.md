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
| 🛡️ **Buff tự động** | Tự ấn tối đa 2 phím buff theo chu kỳ; xử lý bảng `Buff Sequence` & `EXP Coupon` |
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
Skill1=e|120|1|2|1|0|1    ; phím E, CD 120s, hàng 1 cột 2, có lặp, bật
Skill2=3|360|1|6|1|0|1    ; phím 3, CD 360s, hàng 1 cột 6, có lặp, bật
Skill3=v|0|0|0|0|0|1      ; phím chính (V): chỉ cần nhập nếu muốn theo dõi
```

| Cột | Ý nghĩa | Giá trị |
|---|---|---|
| `phím` | Phím bấm | `e`, `3`, `v`, `a`... |
| `cooldown` | Thời gian hồi chiêu (giây) | Số dương |
| `hàng_ô` | Hàng Quickslot | `0` = không đọc, `1` = hàng trên, `2` = hàng dưới |
| `cột_ô` | Cột Quickslot (từ 0, tính từ phải) | `0`, `1`, `2`... |
| `lặp` | Ấn lại dù CD chưa hết (trong khoảng RepMin-RepMax) | `1`/`0` |
| `không_dừng_V` | Ấn skill mà không nhả phím chính V | `1`/`0` |
| `bật` | Bật/tắt dòng này | `1`/`0` |

### Buff tự động

```ini
[Buff]
Enabled=1
Key=q           ; phím buff
EverySec=180    ; chu kỳ ấn (giây)
WaitSec=5       ; chờ sau khi cast xong (giây)
Action=esc      ; esc | all | unapplied

[Buff2]
Enabled=1
Key=6
EverySec=180
WaitSec=5
Action=esc
```

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

### Nhận diện ô Quickslot

```ini
[Detect]
UseSlotCheck=1      ; 1 = đọc màu ô; 0 = chỉ dùng bộ đếm
GameResW=1366       ; độ rộng game (0 = không phóng)
QS_X0=544           ; khoảng cách từ mép phải game đến cột đầu tiên (px)
QS_DX=35            ; khoảng cách giữa 2 cột (px)
QS_Y1=64            ; hàng trên cách mép dưới (px)
QS_Y2=29            ; hàng dưới cách mép dưới (px)
ReadyDist=45        ; ngưỡng lệch màu để coi là "sẵn sàng"
BatchCapture=1      ; 1 = chụp gộp dải ô 1 lần (nhanh hơn nhiều trong Sandbox)
```

---

## 🖥️ Cửa sổ Cài đặt (F5)

Bảng cài đặt đồ họa gồm 3 khối chính:

### Khối Chung
- Phím bắt đầu/tạm dừng, phím skill chính, chế độ ấn (giữ / ấn nhả)
- Tên file game, class cửa sổ
- Random delay sau hồi chiêu, chế độ focus tự động
- Cài đặt buff 1 & buff 2

### Khối Danh sách Skill
- Bảng 14 dòng: bật/tắt từng skill, phím, cooldown, ô quickslot, chế độ lặp, không dừng V
- Nút **Đặt lại thời gian** — reset đồng hồ, buff ấn ngay

### Khối Tự đăng nhập lại
- Bật/tắt, đường dẫn launcher, kênh, thời gian coi là văng
- Nút **Nhận diện màn hình** — mở giao diện khoanh vùng
- Nút **Chạy thử** — kiểm tra quy trình đăng nhập lại

### Các nút bổ sung
- **LƯU** — lưu tất cả và tự reload script
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
| `ẤN X` | Ấn phím skill X |
| `BUFF X` | Ấn phím buff X |
| `[ĐN]` | Quy trình đăng nhập lại |
| `PERF` | Báo cáo hiệu năng 30 giây/lần |
| `ENV` | Thông tin môi trường (màn hình, DPI, cửa sổ game) |
| `BENCH` | Đo tốc độ đọc điểm ảnh |
| `QS` | Chụp gộp dải Quickslot |
| `LỖI` | Lỗi script |
| `VÒNG CHÍNH TRỄ` | Phát hiện vòng lặp bị chậm (> 1.5s) |

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
4. Kiểm tra `QS_X0`, `QS_DX`, `QS_Y1`, `QS_Y2` có đúng với độ phân giải game

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
