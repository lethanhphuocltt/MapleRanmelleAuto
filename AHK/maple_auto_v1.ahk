#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Chạy với quyền Admin =====
if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp
}

SendMode "Event"
SetKeyDelay 30, 40
CoordMode "Pixel", "Screen"
CoordMode "ToolTip", "Screen"
CoordMode "Mouse", "Screen"

; Toạ độ điểm ảnh / BitBlt phải là pixel vật lý trên mọi màn hình (Windows scale 125/150%).
; AHK v2 thường đã ở Per-Monitor; chỉ nâng cấp khi đang thấp hơn để tránh lệch toạ độ.
try {
    ctxDpi := DllCall("User32\GetThreadDpiAwarenessContext", "Ptr")
    if DllCall("User32\GetAwarenessFromDpiAwarenessContext", "Ptr", ctxDpi, "Int") < 2
        DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
}

; =====================================================================
;  MAPLE AUTO v1 (bản thử nghiệm: thêm TỰ ĐĂNG NHẬP LẠI khi văng game)
;  Bản sao riêng, KHÔNG đụng tới maple_auto.ahk: dùng file settings_v1.ini, slot_base_v1.ini, debug_v1.log, error_v1.log.
;  Đừng chạy cùng lúc với bản gốc (hai bản cùng ấn phím sẽ xung đột).
;  Mọi thiết lập nằm trong file settings_v1.ini (sửa tay hoặc ấn F5 để mở cửa sổ Cài đặt).
;  Mọi số px trong script/ini được hiểu là px tại khung game RefW x RefH [Detect] -> khi cửa sổ game
;  to/nhỏ hơn, script nhân hệ số theo trục (SlotScale = uniform | stretch | native).
;  Xem HUONG_DAN.txt để biết cách dùng.
; =====================================================================
IniFile := A_ScriptDir "\settings_" IniRead(A_ScriptDir "\settings_v1.ini", "General", "Profile", "v1") ".ini"
SlotIni := A_ScriptDir "\slot_base_v1.ini"   ; màu "sẵn sàng" của từng ô (lưu bằng nút "Lấy màu chuẩn" trong F5)
; Nhãn bản dựng: hiện ở tiêu đề cửa sổ F5 và dòng đầu log để biết cửa sổ đang chạy mã mới hay bản cũ còn nằm trong bộ nhớ
ScriptBuild := "20261022-build5"

; Giá trị mặc định: [mục, tên, mặc định]
Defaults := [
    ["General", "MainKey", "v"],            ; skill chính, giữ phím liên tục
    ["General", "MainMode", "hold"],        ; hold = giữ phím liên tục; tap = ấn nhả liên tục
    ["General", "MainTapMs", "150"],        ; chế độ tap: khoảng cách giữa 2 lần ấn (ms)
    ["General", "GameExe", "MapleStory.exe"],
    ["General", "GameClass", "MapleStoryClass"],
    ["General", "RandMin", "0"],            ; random thêm sau khi hồi chiêu xong (ms)
    ["General", "RandMax", "0"],
    ["General", "CastDelay", "0"],          ; ms chờ sau khi ấn skill rồi mới giữ lại phím chính
    ["General", "RepMin", "10000"],         ; skill đánh dấu "lặp": ấn lại tối đa sau RepMin-RepMax ms
    ["General", "RepMax", "20000"],
    ["General", "AutoFocus", "1"],          ; 1 = tự đưa cửa sổ game lên trước khi bị che/mất focus
    ["General", "FocusSec", "5"],           ; mỗi bao nhiêu giây kiểm tra 1 lần
    ["General", "ShowHud", "1"],            ; 1 = hiện bảng thông tin (tooltip) giữa màn hình
    ["General", "ToggleKey", "F1"],         ; phím bắt đầu / tạm dừng / tiếp tục
    ["Buff", "Enabled", "1"],               ; tự ấn phím buff theo chu kỳ; nếu hiện bảng "buff chưa áp dụng" thì bấm "Use Unapplied Buffs"
    ["Buff", "Key", "q"],
    ["Buff", "EverySec", "180"],            ; chu kỳ ấn buff (giây), 180 = 3 phút
    ["Buff", "WaitSec", "5"],
    ["Buff2", "Enabled", "1"],              ; phím buff thứ 2 (độc lập với phím buff 1): ấn phím, nếu hiện bảng thì ấn ESC (hoặc theo Action)
    ["Buff2", "Key", "6"],
    ["Buff2", "EverySec", "180"],
    ["Buff2", "WaitSec", "5"],
    ["Buff2", "Action", "esc"],
    ["Buff", "Count", "2"],                 ; số dòng buff đang dùng ([Buff], [Buff2], [Buff3]...); thêm/bớt bằng nút + / − trong thẻ Buff
    ["Buff", "BtnDX", ""],                  ; vị trí nút Use Unapplied Buffs do người dùng chọn (px game, tính từ tâm vùng game); trống = chưa chọn
    ["Buff", "BtnDY", ""],
    ["Buff", "Action", "all"],              ; khi hiện bảng buff (mặc định all): unapplied = bấm chuột "Use Unapplied Buffs"; all = ấn Enter (chọn "Use All Buffs")
    ["Buff", "ClickMode", "0"],             ; cách bấm chuột đã thử thành công (1-5); 0 = chưa biết, thử lần lượt
    ["Buff", "AlwaysManual", "0"],          ; 1 = luôn bấm vị trí đã chọn; 0 = tự tìm nút bằng màu, không thấy mới dùng vị trí đã chọn               ; chờ sau khi bấm để buff được cast xong (giây)
    ["Detect", "UseSlotCheck", "1"],        ; 1 = đọc ô quickslot để biết hồi chiêu xong; 0 = chỉ dùng bộ đếm thời gian
    ["Detect", "GameResW", "0"],            ; độ rộng độ phân giải GAME nếu game bị phóng to (vd 1366); 0 = không phóng
    ["Detect", "RefW", "0"],                ; vùng game lúc đo các số px (QS_*, BandPts, bảng buff); 0 = theo GameResW, rồi tự lấy vùng hiện tại
    ["Detect", "RefH", "0"],                ; chiều cao tương ứng; 0 = 9/16 của RefW (rồi tự lấy vùng hiện tại)
    ["Detect", "SlotScale", "uniform"],     ; uniform = phóng đều theo rộng (cũ); stretch = X theo rộng, Y theo cao; native = UI giữ nguyên px
    ["Detect", "QS_X0", "544"],             ; từ mép phải vùng game tới tâm ô cột đầu tiên
    ["Detect", "QS_DX", "35"],              ; khoảng cách giữa 2 ô
    ["Detect", "QS_Y1", "64"],              ; hàng trên cách mép dưới
    ["Detect", "QS_Y2", "29"],              ; hàng dưới cách mép dưới
    ["Detect", "BatchCapture", "1"],        ; 1 = chụp cả dải quickslot 1 lần rồi đọc màu từ ảnh (nhanh hơn nhiều so với đọc từng điểm); 0 = đọc từng điểm
    ["Detect", "ReadyDist", "45"],
    ["Detect", "VerifyDist", "60"],
    ["Detect", "VerifyMs", "300"],
    ["Debug", "Enabled", "1"],              ; 1 = ghi log debug vào debug.log (để gửi cho người hỗ trợ kiểm tra)
    ["Debug", "MaxEvents", "500"],          ; số dòng log tối đa giữ lại (cũ hơn bị xóa)
    ["Relogin", "Enabled", "1"],            ; 1 = game văng thì tự mở lại / đăng nhập lại
    ["Relogin", "LauncherPath", ""],        ; đường dẫn launcher; trống = Ranmelle.exe ở thư mục cha của thư mục script
    ["Relogin", "LauncherExe", "Ranmelle.exe"],
    ["Relogin", "LostSec", "8"],            ; mất tiến trình game quá chừng này giây thì coi là văng
    ["Relogin", "PlaceWindows", "1"],       ; 1 = tự đặt game ở giữa màn hình, launcher ở góc trên-trái khi đăng nhập lại
    ["Relogin", "MaxTries", "3"],           ; số lần thử đăng nhập lại tối đa
    ["Relogin", "AttemptSec", "300"],       ; mỗi lần thử tối đa chừng này giây
    ["Relogin", "Channel", "1"],            ; kênh cần chọn (1-30)
    ["Relogin", "PlayRX", "0.3372"],        ; nút PLAY trong launcher (tỉ lệ theo rộng/cao cửa sổ launcher)
    ["Relogin", "PlayRY", "0.6313"],
    ["Relogin", "DotDX", "0.0938"],         ; chấm trạng thái GAME của launcher: lệch so với tâm nút PLAY (theo rộng cửa sổ)
    ["Relogin", "DotDY", "0.0788"],
    ["Relogin", "LoginRX", "0.0721"],       ; các điểm trong game: tỉ lệ so với CHIỀU RỘNG vùng game (cả x và y)
    ["Relogin", "LoginRY", "0.4211"],       ; nút Log In
    ["Relogin", "Ch1RX", "0.3795"],         ; ô kênh CH.1
    ["Relogin", "Ch1RY", "0.2309"],
    ["Relogin", "ChDX", "0.0600"],          ; khoảng cách giữa các cột / hàng ô kênh
    ["Relogin", "ChDY", "0.0247"],
    ["Relogin", "PanelRX", "0.3542"],       ; điểm nền sáng của bảng kênh (để nhận ra màn hình chọn kênh)
    ["Relogin", "PanelRY", "0.1922"],
    ["Detect", "MaxRetry", "3"],            ; skill không ra: thử lại nhanh tối đa chừng này lần
    ["Detect", "SlowRetryMs", "15000"],     ; sau đó cứ chừng này ms thử lại 1 lần cho tới khi ra (các phím khác vẫn chạy bình thường)
    ["Detect", "RetryGapMs", "1200"],
    ["Detect", "MinGapMs", "3000"],
    ["Detect", "FlashEveryMs", "200"],
    ["Detect", "FlashIgnoreMs", "2000"],
    ["Detect", "CheckEveryMs", "1000"],
    ["Detect", "RelearnMin", "5"],          ; ô bị coi là "hồi chiêu" liên tục quá chừng này phút -> tạm ngừng ấn phím đó + cảnh báo (0 = tắt)
    ["Detect", "Relearn", "0"],             ; 1 = bật tự học lại màu ô (BETA), 0 = tắt
    ["Detect", "BlockMin", "10"],           ; ấn mãi không ra / ô đọc sai -> tạm ngừng ấn riêng phím đó chừng này phút (0 = không bao giờ ngừng)
]
; Skill: phím|cooldown(giây)|hàng quickslot (0=không có/không đọc, 1=hàng trên, 2=hàng dưới)|cột (từ 0)|lặp (1/0)|không dừng phím chính khi dùng (1/0)|bật (1/0)
; Thứ tự = thứ tự ưu tiên.
; 2 hàng phím mặc định: hàng trên = quickslot hàng 1, hàng dưới = quickslot hàng 2, cột đánh theo thứ tự
KeyLayout := [
    ["q", "w", "e", "r", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "o", "p"],
    ["a", "s", "d", "f", "control", "alt", "z", "x", "c", "u", "i", "j", "k", "l", "n", "m"],
]
DefaultSkills := [
    ; hàng 1 (quickslot hàng trên)
    "q|60|1|0|0|0|0", "w|60|1|1|0|0|0", "e|120|1|2|1|0|1", "r|60|1|3|0|0|0",
    "1|60|1|4|1|0|1", "2|300|1|5|1|0|1", "3|360|1|6|1|0|1", "4|60|1|7|0|0|0",
    "5|60|1|8|0|0|0", "6|60|1|9|0|0|0", "7|60|1|10|0|0|0", "8|60|1|11|0|0|0",
    "9|60|1|12|0|0|0", "0|60|1|13|0|0|0", "o|60|1|14|0|0|0", "p|60|1|15|0|0|0",
    ; hàng 2 (quickslot hàng dưới)
    "a|60|2|0|0|0|1", "s|10|2|1|1|1|1", "d|10|2|2|0|0|1", "f|30|2|3|1|0|1",
    "control|60|2|4|0|0|0", "alt|60|2|5|0|0|0", "z|60|2|6|0|0|0", "x|60|2|7|0|0|0",
    "c|60|2|8|0|0|0", "u|60|2|9|0|0|0", "i|60|2|10|0|0|0", "j|60|2|11|0|0|0",
    "k|60|2|12|0|0|0", "l|60|2|13|0|0|0", "n|60|2|14|0|0|0", "m|60|2|15|0|0|0",
]
MaxSkillRows := 34
SkillLayoutRows := 0     ; số dòng sau khi xếp lại bảng skill theo 2 hàng phím mặc định
; phím đang dùng của bộ skill cũ: khi phải tạo dòng mới thì bật sẵn
DefaultOn := Map("e", 1, "3", 1, "2", 1, "1", 1, "4", 1, "5", 1, "a", 1, "s", 1, "d", 1, "f", 1)

if !FileExist(IniFile)
    FirstRun := true
else
    FirstRun := false
CreateDefaults()
CreateDefaults() {
    global SkillLayoutRows
    for d in Defaults {
        if IniRead(IniFile, d[1], d[2], "<none>") = "<none>"
            IniWrite d[3], IniFile, d[1], d[2]
    }
    if IniRead(IniFile, "Skills", "Skill1", "<none>") = "<none>" {
        for i, v in DefaultSkills
            IniWrite v, IniFile, "Skills", "Skill" i
    }
    SkillLayoutRows := MigrateSkillLayout()
}

; Đưa [Skills] về đúng danh sách 2 hàng phím mặc định (điền sẵn phím/hàng/cột để không phải tự nhập).
; Giữ cooldown / lặp / không dừng V / bật của phím đã có; phím không thuộc danh sách mặc định thì để ở cuối.
MigrateSkillLayout() {
    global IniFile, KeyLayout, MaxSkillRows, DefaultOn
    cur := Map()
    loop MaxSkillRows {
        line := IniRead(IniFile, "Skills", "Skill" A_Index, "")
        if line = ""
            continue
        f := StrSplit(line, "|")
        k := StrLower(Trim(f[1]))
        if k = "" || cur.Has(k)
            continue
        while f.Length < 7
            f.Push("")
        if Trim(f[2]) = "" || !IsNumber(Trim(f[2]))
            f[2] := "60"
        if Trim(f[7]) = ""
            f[7] := "1"
        cur[k] := f
    }
    if cur.Count = 0
        return 0
    out := []
    for row, keys in KeyLayout {
        for col, k in keys {
            if cur.Has(k) {
                f := cur[k]
                out.Push(k "|" f[2] "|" row "|" (col - 1) "|" f[5] "|" f[6] "|" f[7])
                cur.Delete(k)
            } else {
                ; phím mới: bật sẵn nếu là phím đang dùng của bộ skill cũ
                out.Push(k "|60|" row "|" (col - 1) "|0|0|" (DefaultOn.Has(k) ? "1" : "0"))
            }
        }
    }
    for k, f in cur
        out.Push(k "|" f[2] "|" f[3] "|" f[4] "|" f[5] "|" f[6] "|" f[7])
    if out.Length > MaxSkillRows
        return 0
    same := true
    loop out.Length {
        if IniRead(IniFile, "Skills", "Skill" A_Index, "") != out[A_Index] {
            same := false
            break
        }
    }
    if !same {
        loop MaxSkillRows
            IniDelete IniFile, "Skills", "Skill" A_Index
        for i, l in out
            IniWrite l, IniFile, "Skills", "Skill" i
    }
    return out.Length
}
; Phím / hàng ô / cột ô của dòng thứ i (1..32) theo bảng 2 hàng cố định; "" nếu ngoài danh sách
LayoutEntry(i) {
    global KeyLayout
    n := 0
    for row, keys in KeyLayout {
        for col, k in keys {
            n += 1
            if n = i
                return [k, row, col - 1]
        }
    }
    return ["", 0, 0]
}
KeyLabel(k) => k = "control" ? "Ctrl" : k = "alt" ? "Alt" : StrUpper(k)

Cfg(sec, key) {
    for d in Defaults {
        if d[1] = sec && d[2] = key
            return IniRead(IniFile, sec, key, d[3])
    }
}

MainKey       := Trim(Cfg("General", "MainKey"))
MainMode      := StrLower(Trim(Cfg("General", "MainMode"))) = "tap" ? "tap" : "hold"
MainTapMs     := Max(30, Integer(Cfg("General", "MainTapMs")))
LastTap       := 0
GameExe       := Cfg("General", "GameExe")
GameClass     := Cfg("General", "GameClass")
RandMin       := Integer(Cfg("General", "RandMin"))
RandMax       := Max(RandMin, Integer(Cfg("General", "RandMax")))
CastDelay     := Integer(Cfg("General", "CastDelay"))
RepMin        := Integer(Cfg("General", "RepMin"))
RepMax        := Max(RepMin, Integer(Cfg("General", "RepMax")))
FocusMs       := Max(1, Integer(Cfg("General", "FocusSec"))) * 1000
AutoFocus     := Cfg("General", "AutoFocus") = "1"
; Các phím buff: dòng 1 = [Buff], dòng 2 = [Buff2], dòng 3 = [Buff3]... (số dòng ở [Buff] Count).
; Action: unapplied (bấm chuột Use Unapplied Buffs) / all (Enter = Use All Buffs) / esc (tắt bảng).
; Chỉ khi bảng buff HIỆN thì mới ấn Enter/ESC/bấm chuột; không có bảng thì không ấn gì.
BuffCountMax := 7
BuffSec(i) => i = 1 ? "Buff" : "Buff" i
BuffVal(i, key) {
    global IniFile
    d := key = "Enabled" ? (i <= 2 ? "1" : "0")
        : key = "Key" ? (i = 1 ? "q" : i = 2 ? "6" : "")
        : key = "EverySec" ? "180"
        : key = "WaitSec" ? "5"
        : key = "Action" ? (i = 2 ? "esc" : "all")
        : ""
    return IniRead(IniFile, BuffSec(i), key, d)
}
; Số dòng buff: đọc Count; file cũ chưa có Count thì đếm các section [Buff2], [Buff3]... đang có
BuffCountInit() {
    global IniFile, BuffCountMax
    n := Integer(IniRead(IniFile, "Buff", "Count", "0"))
    if n >= 1
        return Min(n, BuffCountMax)
    n := 1
    loop BuffCountMax - 1 {
        i := A_Index + 1
        if Trim(IniRead(IniFile, BuffSec(i), "Key", "")) = "" && Trim(IniRead(IniFile, BuffSec(i), "EverySec", "")) = ""
            break
        n := i
    }
    return n
}
BuffCount := BuffCountInit()
BuffEditN := 0                      ; > 0 = số dòng đang sửa trong thẻ Buff (chưa LƯU); 0 = theo BuffCount
BuffDraft := Map()                  ; giá trị đang sửa trong thẻ Buff, giữ lại khi bấm + / − (dựng lại cửa sổ)
; Giá trị hiển thị của dòng buff i: lấy bản nháp đang sửa, chưa có thì lấy từ ini
BuffRowVal(i, key) {
    global BuffDraft
    return BuffDraft.Has(i "|" key) ? BuffDraft[i "|" key] : BuffVal(i, key)
}
Buffs := []
loop BuffCount {
    i := A_Index
    act := StrLower(Trim(BuffVal(i, "Action")))
    if act != "all" && act != "unapplied" && act != "esc"
        act := "all"
    ev := Number(BuffVal(i, "EverySec")), ws := Number(BuffVal(i, "WaitSec"))
    if !IsNumber(ev) || ev < 10
        ev := 180
    if !IsNumber(ws) || ws < 0
        ws := 5
    Buffs.Push(Map("sec", BuffSec(i), "enabled", BuffVal(i, "Enabled") = "1", "key", Trim(BuffVal(i, "Key")),
        "every", ev, "waitMs", ws * 1000, "action", act, "next", 0))
}
BtnDX         := Trim(Cfg("Buff", "BtnDX"))
BtnDY         := Trim(Cfg("Buff", "BtnDY"))
BuffAlwaysManual := Cfg("Buff", "AlwaysManual") = "1"
NewBtn        := ""
GuardNext     := 0
BuffClickMode := Integer(Cfg("Buff", "ClickMode"))
ShowHud       := Cfg("General", "ShowHud") = "1"
ToggleKey     := Trim(Cfg("General", "ToggleKey"))
if ToggleKey = ""
    ToggleKey := "F1"
UseSlotCheck  := Cfg("Detect", "UseSlotCheck") = "1"
GameResW      := Integer(Cfg("Detect", "GameResW"))
RefW          := Integer(Cfg("Detect", "RefW"))
RefH          := Integer(Cfg("Detect", "RefH"))
if RefW <= 0
    RefW := GameResW
if RefH <= 0
    RefH := RefW > 0 ? Round(RefW * 9 / 16) : 0
SlotScale     := StrLower(Trim(Cfg("Detect", "SlotScale")))
if SlotScale != "stretch" && SlotScale != "native"
    SlotScale := "uniform"
QS_X0         := Number(Cfg("Detect", "QS_X0"))
QS_DX         := Number(Cfg("Detect", "QS_DX"))
QS_Y1         := Number(Cfg("Detect", "QS_Y1"))
QS_Y2         := Number(Cfg("Detect", "QS_Y2"))
UseBatch      := Cfg("Detect", "BatchCapture") != "0"
ReadyDist     := Number(Cfg("Detect", "ReadyDist"))
VerifyDist    := Number(Cfg("Detect", "VerifyDist"))
VerifyMs      := Integer(Cfg("Detect", "VerifyMs"))
MaxRetry      := Integer(Cfg("Detect", "MaxRetry"))
RelearnMin    := Number(Cfg("Detect", "RelearnMin"))
if !IsNumber(RelearnMin) || RelearnMin < 0
    RelearnMin := 5
RelearnMs     := Round(RelearnMin * 60000)
RelearnOn     := Cfg("Detect", "Relearn") != "0"      ; tự học lại màu ô (BETA)
BlockMin      := Number(Cfg("Detect", "BlockMin"))
if !IsNumber(BlockMin) || BlockMin < 0
    BlockMin := 10
BlockMin      := Min(BlockMin, 120)
BlockMs       := Round(BlockMin * 60000)
; Theo dõi khung hình game để xoá ảnh đã chụp khi cửa sổ đổi kích thước, và cảnh báo cấu hình sai
LastCliW      := 0
LastCliH      := 0
VerifyOk      := 0      ; số lần kiểm tra skill "ra ✓" (cộng dồn từ lúc chạy)
VerifyFail    := 0      ; số lần kiểm tra skill "KHÔNG ra ✗"
VerifyOkAt    := 0      ; mốc lần cuối có skill "ra ✓" (0 = chưa lần nào)
CacheResets   := 0      ; số lần xoá ảnh chụp vì cửa sổ game đổi kích thước
Relearns      := 0      ; số lần tự lấy lại màu chuẩn của ô vì "hồi chiêu" kéo dài bất thường
CfgWarn       := ""      ; cảnh báo cấu hình cố định (kiểm tra 1 lần lúc khởi động)
RatioWarn     := ""      ; cảnh báo tỉ lệ cửa sổ game so với khung tham chiếu (kiểm tra lại khi cửa sổ đổi)
DebugOn       := Cfg("Debug", "Enabled") = "1"
DebugMax      := IsInteger(Trim(Cfg("Debug", "MaxEvents"))) ? Max(50, Integer(Trim(Cfg("Debug", "MaxEvents")))) : 500
ReloginOn     := Cfg("Relogin", "Enabled") = "1"
ReLauncherExe := Trim(Cfg("Relogin", "LauncherExe"))
PlaceWindows  := Cfg("Relogin", "PlaceWindows") != "0"
ReLauncher    := Trim(Cfg("Relogin", "LauncherPath"))
if ReLauncher = "" || !FileExist(ReLauncher) {
    ; Tự tìm launcher: thư mục cha, rồi lên tối đa 4 cấp (khi chạy trong thư mục repo đặt lồng trong thư mục game)
    found := ""
    d := A_ScriptDir
    loop 4 {
        d := RegExReplace(d, "\\[^\\]+$")
        if FileExist(d "\" ReLauncherExe) {
            found := d "\" ReLauncherExe
            break
        }
    }
    if found != ""
        ReLauncher := found
    else if ReLauncher = ""
        ReLauncher := RegExReplace(A_ScriptDir, "\\[^\\]+$") "\" ReLauncherExe
}
ReLostSec     := Max(3, Integer(Cfg("Relogin", "LostSec")))
ReMaxTries    := Max(1, Integer(Cfg("Relogin", "MaxTries")))
ReAttemptMs   := Max(60, Integer(Cfg("Relogin", "AttemptSec"))) * 1000
ReChannel     := Min(30, Max(1, Integer(Cfg("Relogin", "Channel"))))
PlayRX := Number(Cfg("Relogin", "PlayRX")), PlayRY := Number(Cfg("Relogin", "PlayRY"))
LoginRX := Number(Cfg("Relogin", "LoginRX")), LoginRY := Number(Cfg("Relogin", "LoginRY"))
Ch1RX := Number(Cfg("Relogin", "Ch1RX")), Ch1RY := Number(Cfg("Relogin", "Ch1RY"))
ChDX := Number(Cfg("Relogin", "ChDX")), ChDY := Number(Cfg("Relogin", "ChDY"))
DotDX := Number(Cfg("Relogin", "DotDX")), DotDY := Number(Cfg("Relogin", "DotDY"))
PanelRX := Number(Cfg("Relogin", "PanelRX")), PanelRY := Number(Cfg("Relogin", "PanelRY"))
DebugFile     := A_ScriptDir "\debug_v1.log"
DebugCount    := 0
if DebugOn {
    try DebugCount := FileExist(DebugFile) ? StrSplit(FileRead(DebugFile, "UTF-8"), "`n").Length - 1 : 0
    DLog("=== script khởi động (tối đa " DebugMax " dòng) ===")
}

; Dấu thời gian có mili giây THẬT. Không dùng Mod(A_TickCount,1000): đó là ms từ lúc boot máy,
; không khớp với giây của đồng hồ nên các dòng log bị nhảy lùi (vd 49.812 -> 49.937 -> 49.125).
TsStr() {
    static b := Buffer(16, 0)
    DllCall("GetLocalTime", "Ptr", b)
    return Format("{:02}:{:02}:{:02}.{:03}", NumGet(b, 8, "UShort"), NumGet(b, 10, "UShort"), NumGet(b, 12, "UShort"), NumGet(b, 14, "UShort"))
}

; Ghi 1 sự kiện vào debug.log (chỉ khi bật trong F5). Giữ tối đa DebugMax dòng gần nhất.
DLog(msg) {
    global DebugCount
    if !DebugOn
        return
    try {
        FileAppend(TsStr() "  " msg "`n", DebugFile, "UTF-8")
        DebugCount += 1
        if DebugCount > DebugMax + 100 {        ; cắt bớt theo lô để không ghi lại file liên tục
            arr := StrSplit(RTrim(FileRead(DebugFile, "UTF-8"), "`n"), "`n")
            out := ""
            from := arr.Length - DebugMax + 1
            loop DebugMax
                out .= arr[from + A_Index - 1] "`n"
            f := FileOpen(DebugFile, "w", "UTF-8")
            f.Write(out)
            f.Close()
            DebugCount := DebugMax
        }
    }
}
; ===== Chẩn đoán hiệu năng (chỉ chạy khi bật "Ghi log debug" trong F5) =====
; Mỗi 30 giây ghi 2 dòng "PERF" vào debug_v1.log: thời gian tốn cho từng việc, CPU, RAM, độ trễ vòng chính.
; Khi màn hình / DPI / cỡ cửa sổ game đổi thì ghi lại các dòng "ENV" (thông tin môi trường).
PerfStat := Map()           ; tên -> [số lần, tổng ms, max ms]
PerfRecent := []            ; các việc chậm (> 500ms) gần đây, để gắn vào dòng "VÒNG CHÍNH TRỄ"
PerfMaxGap := 0
PerfLastSlowPx := 0
PerfReportAt := A_TickCount
PerfSig := ""
PerfReports := 0
PerfFreq := 0
DllCall("QueryPerformanceFrequency", "Int64*", &PerfFreq)
PerfPrev := Map()

PerfNow() {
    c := 0
    DllCall("QueryPerformanceCounter", "Int64*", &c)
    return c * 1000.0 / PerfFreq
}

PerfAdd(name, ms) {
    if !PerfStat.Has(name)
        PerfStat[name] := [0, 0.0, 0.0]
    a := PerfStat[name]
    a[1] += 1
    a[2] += ms
    if ms > a[3]
        a[3] := ms
    if ms > 500 && name != "loop" {
        PerfRecent.Push(name " " Round(ms) "ms lúc " FormatTime(, "HH:mm:ss"))
        if PerfRecent.Length > 5
            PerfRecent.RemoveAt(1)
    }
}

; Đọc màu 1 điểm, đo thời gian (kết quả giống hệt PixelGetColor)
PxGet(x, y) {
    if !DebugOn
        return PixelGetColor(x, y)
    global PerfLastSlowPx
    t := PerfNow()
    try {
        c := PixelGetColor(x, y)
    } catch as e {
        PerfAdd("pixel_lỗi", PerfNow() - t)
        throw e
    }
    d := PerfNow() - t
    PerfAdd("pixel", d)
    if d > 300 && A_TickCount - PerfLastSlowPx > 2000 {
        PerfLastSlowPx := A_TickCount
        DLog("CHẬM: PixelGetColor(" x "," y ") mất " Round(d) "ms")
    }
    return c
}

PerfRun(name, fn) {
    if !DebugOn {
        fn()
        return
    }
    t := PerfNow()
    try
        fn()
    finally
        PerfAdd(name, PerfNow() - t)
}
TimedFn(name, fn) => (*) => PerfRun(name, fn)

DpiAwareName() {
    try {
        ctx := DllCall("User32\GetThreadDpiAwarenessContext", "Ptr")
        a := DllCall("User32\GetAwarenessFromDpiAwarenessContext", "Ptr", ctx, "Int")
        return a = 2 ? "Per-Monitor (2)" : a = 1 ? "System (1) - toạ độ lệch nếu màn khác DPI" : a = 0 ? "Unaware (0)" : a
    }
    return "?"
}

MonDpi(x, y) {
    try {
        pt := (y << 32) | (x & 0xFFFFFFFF)
        hm := DllCall("User32\MonitorFromPoint", "Int64", pt, "UInt", 2, "Ptr")
        dx := 0, dy := 0
        DllCall("Shcore\GetDpiForMonitor", "Ptr", hm, "Int", 0, "UInt*", &dx, "UInt*", &dy)
        return dx
    }
    return 0
}

; Toàn bộ vùng ảo của mọi màn hình: [x, y, w, h] (x/y có thể âm nếu màn phụ nằm bên trái/trên màn chính)
VirtualScreen() {
    return [DllCall("GetSystemMetrics", "Int", 76), DllCall("GetSystemMetrics", "Int", 77)
        , DllCall("GetSystemMetrics", "Int", 78), DllCall("GetSystemMetrics", "Int", 79)]
}

; Chỉ số màn hình chứa tâm cửa sổ game (0 nếu không rõ)
GameMonitor(hwnd) {
    try {
        WinGetPos &wx, &wy, &ww, &wh, hwnd
        mx := wx + ww // 2
        my := wy + wh // 2
        loop MonitorGetCount() {
            MonitorGet A_Index, &l, &t, &r, &b
            if mx >= l && mx < r && my >= t && my < b
                return A_Index
        }
    }
    return 0
}

; Chữ ký "môi trường" của game: đổi thì ghi lại ENV
PerfEnvSig() {
    h := GameHwnd()
    if !h
        return "không có game"
    try {
        WinGetPos &wx, &wy, &ww, &wh, h
        WinGetClientPos , , &cw, &ch, h
        m := GameMonitor(h)
        return wx "," wy "," ww "x" wh " client " cw "x" ch " màn " m " dpi " MonDpi(wx + ww // 2, wy + wh // 2) " n=" MonitorGetCount()
    }
    return "?"
}

EnvDump() {
    try {
        DLog("ENV: AHK " A_AhkVersion (A_PtrSize = 8 ? " 64bit" : " 32bit") "  Windows " A_OSVersion "  user=" A_UserName "  số lõi CPU=" EnvGet("NUMBER_OF_PROCESSORS") "  admin=" A_IsAdmin)
        DLog("ENV: DPI hệ thống=" A_ScreenDPI "  chế độ DPI của script=" DpiAwareName() "  màn hình chính=" MonitorGetPrimary() "  số màn hình=" MonitorGetCount() "  A_ScreenWidth/Height=" A_ScreenWidth "x" A_ScreenHeight)
        loop MonitorGetCount() {
            MonitorGet A_Index, &l, &t, &r, &b
            dpi := MonDpi(l + 1, t + 1)
            DLog("ENV: màn " A_Index ": " (r - l) "x" (b - t) " tại (" l "," t ")  DPI=" dpi " (" Round(dpi / 96 * 100) "%)  tên=" MonitorGetName(A_Index))
        }
        h := GameHwnd()
        if !h {
            DLog("ENV: chưa có cửa sổ game")
            return
        }
        WinGetPos &wx, &wy, &ww, &wh, h
        WinGetClientPos &cx, &cy, &cw, &ch, h
        kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
        m := GameMonitor(h)
        DLog("ENV: game cửa sổ " ww "x" wh " tại (" wx "," wy ")  vùng client " cw "x" ch " tại (" cx "," cy ")  hệ số kx=" Round(kx, 3) " ky=" Round(ky, 3) " (RefW/RefH=" RefW "x" RefH ", SlotScale=" SlotScale ", GameResW=" GameResW ")  tỉ lệ client " Round(cw / Max(1, ch), 3) "  nằm trên màn " m "  DPI màn đó=" MonDpi(wx + ww // 2, wy + wh // 2) "  trạng thái=" WinGetMinMax(h) "  PID=" WinGetPID(h))
        DLog("ENV: tâm client (" Round(cx + cw / 2) "," Round(cy + ch / 2) ")  ô quickslot đầu tiên cách mép phải " QS_X0 " px, mép dưới " QS_Y1 "/" QS_Y2 " px (khi kx=ky=1)")
    } catch as e {
        DLog("ENV: lỗi khi thu thập: " e.Message)
    }
    PxBench("env")
}

; Đo tốc độ thao tác điểm ảnh / cửa sổ, tách riêng để biết cái nào chậm
PxBench(label) {
    h := GameHwnd()
    try {
        x := 5, y := 5, gx := 0, gy := 0
        if h {
            WinGetClientPos &cx, &cy, &cw, &ch, h
            gx := cx + cw // 2, gy := cy + ch // 2
        }
        t1 := 0, m1 := 0, t2 := 0, m2 := 0, t3 := 0, m3 := 0, t4 := 0, m4 := 0
        ; PixelGetColor trên cửa sổ game có tăng tốc GPU có thể mất >1 giây mỗi lần (đo được 14,8 giây trong Sandbox),
        ; nên chỉ lấy 1 mẫu ở giữa game và dừng ngay khi thấy chậm để không chặn vòng chính.
        nPx := label = "định kỳ" ? 2 : 3
        n1 := 0, n2 := 0
        loop nPx {
            n1 := A_Index
            t := PerfNow()
            PixelGetColor(x, y)
            d := PerfNow() - t, t1 += d, m1 := Max(m1, d)
            if h && n2 < 1 {
                n2 += 1
                t := PerfNow()
                PixelGetColor(gx, gy)
                d := PerfNow() - t, t2 += d, m2 := Max(m2, d)
            }
            t := PerfNow()
            WinGetClientPos &a, &b, &c, &e, h
            d := PerfNow() - t, t3 += d, m3 := Max(m3, d)
            t := PerfNow()
            WinActive(GameWin)
            d := PerfNow() - t, t4 += d, m4 := Max(m4, d)
            if m1 > 800 || m2 > 800
                break
        }
        tq := 0, mq := 0, qn := 0
        if h && UseBatch && !QsOff {
            loop (label = "định kỳ" ? 2 : 5) {
                t := PerfNow()
                if QsCapture(cx, cy, cw, ch, ScaleX(cw, ch), ScaleY(cw, ch), true)
                    qn += 1
                d := PerfNow() - t, tq += d, mq := Max(mq, d)
            }
        }
        DLog("BENCH " label ": chụp gộp dải quickslot " (qn ? "tb=" Round(tq / qn, 1) "ms max=" Round(mq, 1) "ms" : "không chạy") "  | đọc 1 điểm ở góc màn hình tb=" Round(t1 / Max(1, n1), 1) "ms max=" Round(m1, 1) "  | giữa game " (n2 ? "tb=" Round(t2 / n2, 1) "ms max=" Round(m2, 1) : "không đo") "  | WinGetClientPos tb=" Round(t3 / Max(1, n1), 1) "ms max=" Round(m3, 1) "  | WinActive tb=" Round(t4 / Max(1, n1), 2) "ms max=" Round(m4, 1) (n1 < nPx ? "  (dừng sớm vì 1 lần đọc điểm ảnh quá chậm)" : ""))
    }
}

PerfFirstEnv() {
    global PerfSig
    PerfSig := PerfEnvSig()
    EnvDump()
}

PerfProcTimes(h) {
    c := 0, e := 0, k := 0, u := 0
    if !DllCall("GetProcessTimes", "Ptr", h, "Int64*", &c, "Int64*", &e, "Int64*", &k, "Int64*", &u)
        return -1
    return k + u
}

PerfReport() {
    global PerfStat, PerfMaxGap, PerfReportAt, PerfSig, PerfReports, PerfPrev, VerifyOk, VerifyFail, VerifyOkAt, CacheResets, CfgWarn, RatioWarn, Relearns
    now := A_TickCount
    wall := Max(1, now - PerfReportAt)
    PerfReportAt := now
    PerfReports += 1
    ; CPU: máy / script / game (tính theo % của 1 lõi cho tiến trình, % toàn máy cho máy)
    idle := 0, kern := 0, user := 0
    DllCall("GetSystemTimes", "Int64*", &idle, "Int64*", &kern, "Int64*", &user)
    sysTxt := "?"
    if PerfPrev.Has("idle") {
        dt := (kern + user) - PerfPrev["tot"]
        if dt > 0
            sysTxt := Round((1 - (idle - PerfPrev["idle"]) / dt) * 100) "%"
    }
    PerfPrev["idle"] := idle, PerfPrev["tot"] := kern + user
    selfTxt := "?", gameTxt := "?"
    s := PerfProcTimes(DllCall("GetCurrentProcess", "Ptr"))
    if s >= 0 {
        if PerfPrev.Has("self")
            selfTxt := Round((s - PerfPrev["self"]) / (wall * 100)) "%"
        PerfPrev["self"] := s
    }
    gh := GameHwnd()
    if gh {
        try {
            hp := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", WinGetPID(gh), "Ptr")
            if hp {
                g := PerfProcTimes(hp)
                DllCall("CloseHandle", "Ptr", hp)
                if g >= 0 {
                    if PerfPrev.Has("game")
                        gameTxt := Round((g - PerfPrev["game"]) / (wall * 100)) "%"
                    PerfPrev["game"] := g
                }
            }
        }
    }
    mem := Buffer(64, 0)
    NumPut("UInt", 64, mem)
    DllCall("GlobalMemoryStatusEx", "Ptr", mem)
    ramTxt := NumGet(mem, 4, "UInt") "% dùng, trống " (NumGet(mem, 16, "UInt64") // 1048576) "MB"
    DLog("PERF " Round(wall / 1000) "s: vòng chính trễ nhất " PerfMaxGap "ms | CPU máy " sysTxt "  script " selfTxt " (của 1 lõi)  game " gameTxt " (của 1 lõi) | RAM " ramTxt " | game " (IsGameActive() ? "đang focus" : "KHÔNG focus") " | bản script=" InstanceCount() " | pause=" (Paused() ? "có" : "không"))
    DLog("TỔNG: kiểm tra skill ✓" VerifyOk " ✗" VerifyFail " | tự học lại màu " Relearns " lần | cửa sổ đổi " CacheResets " lần | cảnh báo cấu hình=" (CfgWarn = "" ? "không" : "CÓ") " cảnh báo tỉ lệ=" (RatioWarn = "" ? "không" : "CÓ") " | GameHwnd=" (GameHwnd() ? "có" : "KHÔNG"))
    line := ""
    for name, a in PerfStat
        line .= name ": n=" a[1] " tb=" Round(a[2] / a[1], 1) "ms max=" Round(a[3]) "ms chiếm=" Round(a[2] / wall * 100) "%  | "
    DLog("PERF chi tiết: " (line = "" ? "(chưa có hoạt động)" : RTrim(line, " |")))
    PerfStat := Map()
    PerfMaxGap := 0
    sig := PerfEnvSig()
    if sig != PerfSig {
        DLog("ENV đổi: [" PerfSig "] -> [" sig "]")
        PerfSig := sig
        EnvDump()
    } else if Mod(PerfReports, 4) = 0 {
        PxBench("định kỳ")
    }
}

; Khi thấy không có bảng buff: ghi toạ độ + màu các điểm dò để biết dò trượt vì sai vị trí hay sai màu
BuffSampleDump() {
    h := GameHwnd()
    if !h
        return "không có cửa sổ game"
    WinGetClientPos &cx, &cy, &cw, &ch, h
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    mx := cx + cw / 2
    my := cy + ch / 2
    out := "client " cw "x" ch " kx=" Round(kx, 3) " ky=" Round(ky, 3) " tâm (" Round(mx) "," Round(my) ")  loại1 [cần ~40,140,170]: "
    try {
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            x := Round(mx + p[1] * kx), y := Round(my + p[2] * ky)
            c := PxGet(x, y)
            out .= "(" x "," y ")=" ((c >> 16) & 0xFF) "," ((c >> 8) & 0xFF) "," (c & 0xFF) "  "
        }
        out .= " loại2 [cần ~44,165,186]: "
        for p in [[-140, -45], [140, -45]] {
            x := Round(mx + p[1] * kx), y := Round(my + p[2] * ky)
            c := PxGet(x, y)
            out .= "(" x "," y ")=" ((c >> 16) & 0xFF) "," ((c >> 8) & 0xFF) "," (c & 0xFF) "  "
        }
    } catch as e {
        out .= " LỖI " e.Message
    }
    return out
}

SlowRetryMs   := Integer(Cfg("Detect", "SlowRetryMs"))
RetryGapMs    := Integer(Cfg("Detect", "RetryGapMs"))
MinGapMs      := Integer(Cfg("Detect", "MinGapMs"))
FlashEveryMs  := Integer(Cfg("Detect", "FlashEveryMs"))
FlashIgnoreMs := Integer(Cfg("Detect", "FlashIgnoreMs"))
CheckEveryMs  := Integer(Cfg("Detect", "CheckEveryMs"))
TickMs := 100
ReadyHoldMs := 0
; Điểm lấy mẫu trên dải xám ở mép dưới icon: [lệch ngang, lệch dọc] so với tâm ô
BandPts := [[-9, 13], [-2, 13], [4, 13]]

#Include core\scale.ahk
; Đọc danh sách skill từ settings.ini
Skills := []
loop MaxSkillRows {
    line := IniRead(IniFile, "Skills", "Skill" A_Index, "")
    if line = ""
        continue
    f := StrSplit(line, "|")
    if f.Length < 2 || Trim(f[1]) = "" || !IsNumber(Trim(f[2]))
        continue
    m := Map("key", StrLower(Trim(f[1])), "cd", Number(Trim(f[2])))
    row := f.Length >= 3 && IsInteger(Trim(f[3])) ? Integer(Trim(f[3])) : 0
    col := f.Length >= 4 && IsInteger(Trim(f[4])) ? Integer(Trim(f[4])) : 0
    if row = 1 || row = 2
        m["slot"] := [col, row]
    if f.Length >= 5 && Trim(f[5]) = "1"
        m["rep"] := true
    if f.Length >= 6 && Trim(f[6]) = "1"
        m["nostop"] := true         ; ấn skill này mà KHÔNG nhả phím chính (V) và không chờ
    if f.Length >= 7 && Trim(f[7]) = "0"
        continue                    ; cột "Bật" bỏ chọn: giữ dòng trong ini nhưng không ấn skill này
    m["coolSince"] := 0             ; mốc bắt đầu "hồi chiêu" liên tục (0 = không theo dõi)
    m["cdSample"] := ""             ; màu ô chụp ngay SAU lần ấn thành công = màu lúc đang hồi chiêu
    m["cdAt"] := 0                  ; mốc lấy lại mẫu màu hồi chiêu đã ổn định (0 = không hẹn)
    m["diffSince"] := 0             ; mốc ô bắt đầu khác màu hồi chiêu đã biết (0 = không)
    m["blocked"] := 0               ; tạm ngừng ấn phím này đến mốc này (chống ấn quá nhiều lần)
    m["fails"] := 0                 ; số lần ấn liên tiếp mà kiểm tra báo "không ra"
    m["probe"] := false             ; lần ấn này là "ấn thử" để lấy màu hồi chiêu (không thử lại dồn dập)
    Skills.Push(m)
}

; Bắt các lỗi cấu hình hay gặp mà trước đây script im lặng làm sai (trùng phím, trùng ô, hằng số vô lý)
ValidateCfg() {
    global Skills, QS_DX, QS_X0, QS_Y1, QS_Y2, RefW, RefH, KeyLayout
    warn := []
    keys := Map(), slots := Map()
    cano := Map()
    for row, list in KeyLayout {
        for col, k in list
            cano[k] := [col - 1, row]       ; cột lưu trong ini tính từ 0
    }
    for s in Skills {
        k := s["key"]
        if keys.Has(k)
            warn.Push("skill trùng phím " StrUpper(k))
        else
            keys[k] := true
        if s.Has("slot") {
            sk := s["slot"][2] "|" s["slot"][1]
            if slots.Has(sk)
                warn.Push("skill " StrUpper(k) " trùng ô hàng " s["slot"][2] " cột " s["slot"][1] " với " StrUpper(slots[sk]))
            else
                slots[sk] := k
            ; Phím có trong 2 hàng mặc định nhưng hàng/cột khác đi -> dễ đọc sai ô
            if cano.Has(k) && (s["slot"][1] != cano[k][1] || s["slot"][2] != cano[k][2])
                warn.Push("phím " StrUpper(k) " đang ở hàng " s["slot"][2] " cột " (s["slot"][1] + 1) " nhưng theo 2 hàng phím mặc định là hàng " cano[k][2] " cột " (cano[k][1] + 1))
        }
    }
    if QS_DX <= 0
        warn.Push("QS_DX=" QS_DX " phải lớn hơn 0")
    if RefW > 0 && (QS_X0 <= 0 || QS_X0 > RefW)
        warn.Push("QS_X0=" QS_X0 " vô lý (RefW=" RefW ")")
    if RefH > 0 && (QS_Y1 <= 0 || QS_Y1 > RefH || QS_Y2 <= 0 || QS_Y2 > RefH)
        warn.Push("QS_Y1/QS_Y2 vô lý (RefH=" RefH ")")
    return warn
}
for w in ValidateCfg() {
    DLog("CẢNH BÁO CẤU HÌNH: " w)
    CfgWarn .= (CfgWarn = "" ? "" : "; ") w
}
; Ghi lại kết quả kiểm tra để log đủ căn cứ nghiệm thu (không chỉ ghi khi có lỗi)
CfgSummary() {
    global Skills, QS_X0, QS_DX, QS_Y1, QS_Y2, RefW, RefH, SlotScale, CfgWarn, RelearnMin
    nSlot := 0
    for s in Skills {
        if s.Has("slot")
            nSlot += 1
    }
    rl := RelearnMin > 0 ? "ô bị coi là hồi chiêu > " RelearnMin " phút thì tạm ngừng ấn phím đó" : "không bảo vệ ô hồi chiêu quá lâu"
    if CfgWarn = ""
        DLog("KIỂM TRA CẤU HÌNH: OK - " Skills.Length " skill (trong đó " nSlot " skill đọc ô màu), không trùng phím/ô; QS_X0=" QS_X0 " QS_DX=" QS_DX " QS_Y1=" QS_Y1 " QS_Y2=" QS_Y2 " (khung " RefText() ", SlotScale=" SlotScale "); " rl)
    else
        DLog("KIỂM TRA CẤU HÌNH: CÓ LỖI - " CfgWarn)
}
CfgSummary()

; Chỉ để hiển thị trong log: RefW/RefH = 0 nghĩa là tự lấy vùng game ở lần dùng đầu
RefText() {
    global RefW, RefH
    return (RefW > 0 ? RefW "x" RefH : "tự động")
}

; Tóm tắt buff cho log: tổng số dòng + số dòng đang bật và phím của chúng
BuffSummary() {
    global Buffs
    n := 0, txt := ""
    for bf in Buffs {
        if bf["enabled"] && bf["key"] != "" {
            n += 1
            txt .= (txt = "" ? "" : ",") StrUpper(bf["key"])
        }
    }
    return Buffs.Length " dòng buff, bật " n (txt = "" ? "" : " (" txt ")")
}

; Ghi 1 khối thông tin đầu phiên để log đủ căn cứ nghiệm thu (không phải mò lại cấu hình đã dùng)
StartupLog() {
    global IniFile, MainKey, ToggleKey, TickMs, CheckEveryMs, FlashEveryMs, ReloginOn, DebugMax
    global RefW, RefH, SlotScale, GameResW, UseBatch, MaxRetry, RetryGapMs, SlowRetryMs, Skills, RelearnMin
    global SkillLayoutRows, MaxSkillRows, ScriptBuild, RelearnOn, BlockMin
    try {
        sz := FileGetSize(A_ScriptFullPath)
        mt := FileGetTime(A_ScriptFullPath)
        DLog("=== PHIÊN: bản dựng " ScriptBuild " | script " A_ScriptFullPath " (" sz " byte, sửa " FormatTime(mt, "yyyy-MM-dd HH:mm:ss") ") ===")
        DLog("PHIÊN: settings " IniFile " | khung tham chiếu " RefText() " SlotScale=" SlotScale " GameResW=" GameResW " | " Skills.Length " skill (bật) | bảng skill " SkillLayoutRows "/" MaxSkillRows " dòng theo 2 hàng phím mặc định | phím chính=" StrUpper(MainKey) " bật/tắt=" ToggleKey " | " BuffSummary() " | log tối đa " DebugMax " dòng")
        DLog("PHIÊN: nhịp loop=" TickMs "ms quét ô=" CheckEveryMs "ms nháy=" FlashEveryMs "ms | MaxRetry=" MaxRetry " RetryGap=" RetryGapMs "ms SlowRetry=" SlowRetryMs "ms | chụp gộp=" (UseBatch ? "bật" : "tắt") " | canh đăng nhập=" (ReloginOn ? "bật" : "tắt") " | tự học lại màu ô (BETA): " (RelearnOn ? "BẬT - ô bị coi là hồi chiêu quá " RelearnMin " phút thì tạm ngừng ấn + học lại màu khi ô rời màu hồi chiêu" : "tắt") " | tạm ngừng 1 phím khi ấn mãi không ra: " (BlockMs > 0 ? BlockMin " phút" : "KHÔNG"))
    } catch as e {
        DLog("PHIÊN: lỗi khi ghi thông tin khởi động: " e.Message)
    }
}

; Gọi mỗi vòng: cửa sổ game đổi kích thước thì xoá ảnh đã chụp (không dùng ảnh cũ) và kiểm tra lại tỉ lệ
FrameCheck() {
    global LastCliW, LastCliH, QsOk, BdOk, CacheResets
    h := GameHwnd()
    if !h
        return
    WinGetClientPos , , &cw, &ch, h
    if cw < 10 || ch < 10
        return
    if cw = LastCliW && ch = LastCliH
        return
    first := LastCliW = 0
    LastCliW := cw, LastCliH := ch
    QsOk := false, BdOk := false        ; ảnh chụp theo khung cũ, phải chụp lại
    if first {
        FrameGeom("lúc bắt đầu", cw, ch)
    } else {
        CacheResets += 1
        DLog("ENV: cửa sổ game đổi " cw "x" ch " → xoá ảnh đã chụp (lần " CacheResets "), kx=" Round(ScaleX(cw, ch), 3) " ky=" Round(ScaleY(cw, ch), 3))
        FrameGeom("sau khi đổi", cw, ch)
    }
    RatioCheck(cw, ch)
}

; Toạ độ thật (tính từ góc trên-trái vùng client) của dải ô quickslot ở khung hình hiện tại
FrameGeom(tag, cw, ch) {
    global QS_X0, QS_DX, QS_Y1, QS_Y2, RefW, RefH, SlotScale
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    x0 := cw - QS_X0 * kx
    DLog("KHUNG " tag ": client " cw "x" ch "  kx=" Round(kx, 4) " ky=" Round(ky, 4) "  ô đầu hàng trên (" Round(x0) "," Round(ch - QS_Y1 * ky) ")  hàng dưới (" Round(x0) "," Round(ch - QS_Y2 * ky) ")  bước ngang " Round(QS_DX * kx, 1) "px  cao ô " Round((QS_Y1 - QS_Y2) * ky, 1) "px  (RefW/RefH=" RefW "x" RefH ", SlotScale=" SlotScale ")")
}

; Cửa sổ lệch tỉ lệ khung tham chiếu >5% mà vẫn phóng đều 1 hệ số -> dễ đọc sai ô quickslot
RatioCheck(cw, ch) {
    global RefW, RefH, SlotScale, RatioWarn
    if RefW <= 0 || RefH <= 0 {
        RatioWarn := ""
        return
    }
    ref := RefW / RefH
    dev := Abs(cw / ch - ref) / ref
    if SlotScale != "uniform" {
        RatioWarn := ""
        DLog("TỈ LỆ: cửa sổ " cw "x" ch " lệch khung " RefW "x" RefH " " Round(dev * 100, 1) "% - SlotScale=" SlotScale " nên không cảnh báo")
        return
    }
    if dev <= 0.05 {
        RatioWarn := ""
        DLog("TỈ LỆ: cửa sổ " cw "x" ch " lệch khung " RefW "x" RefH " " Round(dev * 100, 1) "% - trong ngưỡng 5%, SlotScale=uniform dùng được")
        return
    }
    msg := "cửa sổ " cw "x" ch " lệch tỉ lệ khung " RefW "x" RefH " " Round(dev * 100) "% - nếu ô quickslot đọc sai, đặt SlotScale=stretch"
    if RatioWarn != msg {
        RatioWarn := msg
        DLog("CẢNH BÁO CẤU HÌNH: " msg)
    }
}

GameWin := "ahk_exe " GameExe
GameWin2 := "ahk_class " GameClass

Enabled := false
Relogging := false      ; đang chạy quy trình đăng nhập lại: mọi thứ khác tạm dừng
RelogCancel := false    ; người dùng ấn phím bắt đầu/tạm dừng để hủy quy trình đăng nhập lại
SkillRecoverTimes := []
SkillRecoverBusy := false
SeenGame := false       ; đã từng thấy game chạy khi auto bật (tránh coi "chưa mở game" là văng)
LostSince := 0
StartTick := 0          ; lúc bấm bắt đầu; skill chỉ được ấn sau khi đã có 1 lượt quét ô mới hơn mốc này
UserPaused := false     ; tạm dừng bằng phím (khác với tắt hẳn): giữ nguyên đồng hồ, bật lại thì chạy tiếp
PauseSince := 0         ; mốc bắt đầu tạm dừng (mọi nguyên nhân) để dời đồng hồ khi chạy tiếp
SettingsBusy := false   ; đang mở cửa sổ cài đặt
Holding := false
Base := Map()           ; key -> màu các điểm lấy mẫu lúc skill sẵn sàng
PressLog := []          ; 10 lần ấn phím gần nhất (mới nhất ở đầu)
ScanMs := 0             ; lần quét ô gần nhất mất bao nhiêu ms
ScanAt := 0
FlashMs := 0            ; lần quét nháy trắng gần nhất mất bao nhiêu ms
F1Count := 0            ; số lần script nhận được phím F1 (để kiểm tra)

for s in Skills {
    s["next"] := 0
    s["wait"] := 0
    s["chk"] := 0
    s["st"] := -1       ; trạng thái ô lần quét gần nhất: 1 sẵn sàng, 0 đang hồi, -1 không rõ
    s["press"] := 0     ; thời điểm ấn gần nhất
    s["flash"] := 0     ; thời điểm thấy nháy trắng gần nhất
    s["tmr"] := 0       ; mốc ấn dự phòng theo thời gian
    s["force"] := false ; true = lần ấn trước skill chưa ra, đang chờ thử lại
    s["retries"] := 0
}

LoadBase() {
    for s in Skills {
        if !s.Has("slot")
            continue
        v := IniRead(SlotIni, "Band", s["key"], "")
        if v = ""
            continue
        try {
            smp := StrToSample(v)
            if smp.Length = BandPts.Length    ; bỏ qua màu chuẩn lưu từ bản cũ (số điểm khác)
                Base[s["key"]] := smp
        }
    }
}
LoadBase()

; Số bản script maple_auto.ahk đang chạy cùng lúc (phải là 1)
InstanceCount() {
    DetectHiddenWindows True
    SetTitleMatchMode 2
    return WinGetList(A_ScriptName " ahk_class AutoHotkey").Length
}

; Tắt các bản script cũ còn sót để chỉ còn đúng một bản đang chạy
KillOtherInstances() {
    DetectHiddenWindows True
    SetTitleMatchMode 2
    me := ProcessExist()
    for hwnd in WinGetList(A_ScriptName " ahk_class AutoHotkey") {
        pid := WinGetPID(hwnd)
        if pid != me
            try ProcessClose(pid)
    }
}
KillOtherInstances()

; Bản gốc (maple_auto.ahk / maple_auto.exe) đang chạy thì hỏi, vì hai bản cùng ấn phím sẽ xung đột
if ProcessExist("maple_auto.exe") || WinExist("maple_auto.ahk ahk_class AutoHotkey") {
    if MsgBox("Bản gốc maple_auto đang chạy.`nChạy cả hai cùng lúc sẽ ấn phím xung đột.`n`nVẫn chạy bản v1 này?", "Maple Auto v1", "YesNo Icon! Default2") != "Yes"
        ExitApp
}

; ===== Cửa sổ Cài đặt (F5 hoặc chuột phải vào biểu tượng ở khay hệ thống) =====
SettingsGui := ""
ZoneGui := ""
ZoneStat := Map()
GuiCtl := Map()
CapturePause := false
; Tạm dừng toàn bộ auto khi cửa sổ Cài đặt / Màu chuẩn đang hiện (hoặc đang lấy màu); đóng cửa sổ thì tự chạy tiếp
Paused() {
    global PauseSince
    p := Relogging || UserPaused || SettingsBusy || CapturePause || GuiVisible(SettingsGui) || GuiVisible(ColorGui) || GuiVisible(ZoneGui)
    if p && !PauseSince {
        PauseSince := A_TickCount
        DLog("TẠM DỪNG (người dùng=" UserPaused " cài đặt=" (SettingsBusy || GuiVisible(SettingsGui)) " lấy màu=" (CapturePause || GuiVisible(ColorGui)) ")")
        if Holding
            ReleaseMain()
    } else if !p && PauseSince {
        DLog("CHẠY TIẾP sau " (A_TickCount - PauseSince) "ms")
        ShiftTimes(A_TickCount - PauseSince)    ; thời gian tạm dừng không tính vào hồi chiêu / chu kỳ buff
        PauseSince := 0
    }
    return p
}

; Dời mọi mốc thời gian về sau d ms (để đồng hồ "đứng yên" trong lúc tạm dừng)
ShiftTimes(d) {
    global GuardNext
    if d <= 0
        return
    for s in Skills {
        for k in ["next", "wait", "tmr", "press", "flash", "vat", "chk", "blocked", "diffSince", "coolSince", "cdAt"] {
            if s.Has(k) && s[k] > 0
                s[k] += d
        }
    }
    for bf in Buffs {
        if bf["next"] > 0
            bf["next"] += d
    }
    GuardNext += d
}

; Đặt lại đồng hồ như lúc vừa bấm bắt đầu: buff ấn ngay, các skill coi như sẵn sàng
ResetTimers() {
    global PauseSince
    now := A_TickCount
    for bf in Buffs
        bf["next"] := now
    for i, s in Skills {
        s["next"] := now + (i - 1) * 1500
        s["wait"] := 0
        s["chk"] := 0
        s["tmr"] := now + (i - 1) * 1500
        s["press"] := 0
        s["flash"] := 0
        s["vat"] := 0
        s["force"] := false
        s["retries"] := 0
        s["fails"] := 0
        s["probe"] := false
        s["blocked"] := 0
        s["coolSince"] := 0
        s["diffSince"] := 0
        s["cdAt"] := 0
    }
    if PauseSince
        PauseSince := now       ; để khi chạy tiếp, các mốc vừa đặt không bị dời thêm cả thời gian đã tạm dừng
}

; Cửa sổ GUI còn tồn tại và đang hiện? (GUI đã bị Destroy thì .Hwnd báo lỗi nên phải bọc try)
GuiVisible(g) {
    try {
        if IsObject(g) && g.Hwnd
            return DllCall("IsWindow", "Ptr", g.Hwnd) && DllCall("IsWindowVisible", "Ptr", g.Hwnd)
    }
    return false
}

#Include ui\scroll.ahk
#Include ui\settings.ahk

IsGameActive() {
    if !DebugOn
        return WinActive(GameWin) || WinActive(GameWin2)
    t := PerfNow()
    r := WinActive(GameWin) || WinActive(GameWin2)
    PerfAdd("winactive", PerfNow() - t)
    return r
}

; Lỗi trong timer: không hiện hộp thoại (có thể bị game che và làm treo script) mà ghi file + tooltip
LastErr := ""
LoopTicks := 0
OnError(LogErr)
LogErr(e, mode) {
    global LastErr
    LastErr := e.Message " @dòng " e.Line " (" e.What ")"
    DLog("LỖI " LastErr)
    try FileAppend(TsStr() "  " LastErr "`n", A_ScriptDir "\error_v1.log", "UTF-8")
    ToolTip "LỖI SCRIPT: " LastErr, 20, 20, 3
    SetTimer () => ToolTip(, , , 3), -8000
    return -1
}

; ===== F1 bật/tắt | F2 xem số đọc được | F5 cài đặt (có nút lấy màu chuẩn) =====
; F1 không phụ thuộc điều kiện cửa sổ nên luôn nhận được; Ctrl+F1 = dừng hẳn script (khẩn cấp)
^F1:: PanicStop()
try Hotkey("$" ToggleKey, (*) => ToggleAuto())
catch
    MsgBox "Phím bắt đầu/tạm dừng '" ToggleKey "' không hợp lệ. Hãy sửa trong F5 hoặc settings.ini.", "Maple Auto", "Icon!"
F5:: ToggleSettings()

ToggleAuto() {
    global Enabled, F1Count, UserPaused, StartTick, SeenGame, LostSince, RelogCancel
    if Relogging {                      ; đang đăng nhập lại: phím này = HỦY quy trình (và tạm dừng auto nếu đang bật)
        RelogCancel := true
        if Enabled
            UserPaused := true
        ToolTip "Đã hủy quy trình đăng nhập lại"
        SetTimer () => ToolTip(), -2000
        return
    }
    F1Count += 1
    if Enabled && !UserPaused {         ; đang chạy -> TẠM DỪNG (không tắt hẳn)
        UserPaused := true
        Paused()
        ReleaseMain()
        ToolTip "AUTO: TẠM DỪNG (ấn " ToggleKey " để tiếp tục)"
        SetTimer () => ToolTip(), -1500
        return
    }
    if Enabled && UserPaused {          ; đang tạm dừng -> chạy tiếp, đồng hồ đi tiếp từ chỗ dừng
        UserPaused := false
        Paused()
        if ReloginOn && !ProcessExist(GameExe) && !GameHwnd() {     ; game đang không chạy -> không chỉ "tiếp tục" mà mở lại game luôn
            DLog("TIẾP TỤC nhưng game không chạy -> bắt đầu đăng nhập lại")
            SeenGame := true
            LostSince := 0
            ToolTip "AUTO: TIẾP TỤC - game chưa chạy, đang mở game..."
            SetTimer () => ToolTip(), -2500
            SetTimer () => DoRelogin(false), -100
            return
        }
        ToolTip "AUTO: TIẾP TỤC"
        SetTimer () => ToolTip(), -1200
        return
    }
    gameRunning := ProcessExist(GameExe) ? true : false
    if !IsGameActive() && !ReloginOn {  ; (không có chức năng đăng nhập lại) chỉ cho BẬT khi đang ở cửa sổ game
        ToolTip "Chưa ở cửa sổ game - không bật được"
        SetTimer () => ToolTip(), -1500
        return
    }
    Enabled := true
    UserPaused := false
    DLog("BẮT ĐẦU" (gameRunning ? "" : " (game chưa chạy -> tự mở game)"))
    SeenGame := true                    ; bật auto = mong game chạy; mất game thì tự đăng nhập lại
    LostSince := 0
    if !gameRunning {
        ResetTimers()
        StartTick := A_TickCount
        ToolTip "AUTO: BẬT - game chưa chạy, đang mở game..."
        SetTimer () => ToolTip(), -2500
        SetTimer () => DoRelogin(false), -100
        return
    }
    ResetTimers()
    StartTick := A_TickCount     ; không quét ô ngay (chậm, làm trễ buff đầu tiên); skill chờ lượt quét đầu của timer rồi mới ấn
    ToolTip "AUTO: BẬT"
    SetTimer () => ToolTip(), -1200
}

#HotIf IsGameActive()
F2:: DebugSlots()
F6:: DebugBuff()
F7:: TestBuffClick()
F4:: {
    global ShowHud
    ShowHud := !ShowHud
    if !ShowHud
        ToolTip "", , , 2
}
#HotIf

; ===== Tự focus game: cứ X giây nếu chưa focus game thì focus lại (bật/tắt và chu kỳ chỉnh trong F5) =====
FocusEnabled := AutoFocus
if FocusEnabled
    SetTimer KeepFocus, FocusMs

KeepFocus() {
    global FocusEnabled
    if !Enabled || Paused() || IsGameActive()     ; chỉ focus khi auto đang chạy (đã bắt đầu, không tạm dừng)
        return
    hwnd := WinExist(GameWin)
    if !hwnd
        hwnd := WinExist(GameWin2)
    if !hwnd && ReloginOn
        return                      ; mất game thì để chức năng đăng nhập lại lo
    if !hwnd {
        ; Không tìm thấy cửa sổ game: báo và dừng auto focus
        FocusEnabled := false
        SetTimer KeepFocus, 0
        ToolTip "KHÔNG TÌM THẤY CỬA SỔ GAME`nAUTO FOCUS: TẮT"
        SetTimer () => ToolTip(), -4000
        MsgBox "Không tìm thấy cửa sổ game.`nĐã tắt AUTO FOCUS (bật lại trong F5).", "Auto Focus", "Icon! T10"
        return
    }
    SoftActivate(hwnd)
}

; CHỈ focus (nhận phím) KHÔNG CHẶN: WinActivate gắn luồng và chờ game xử lý tin nhắn, nếu game đang bận (tải map)
; thì cả script bị treo. Không khôi phục cửa sổ thu nhỏ / không hiện / không "luôn trên cùng": chỉ xin focus rồi trả về ngay.
SoftActivate(hwnd) {
    try {
        if WinGetMinMax(hwnd) = -1
            return
    }
    DllCall("SwitchToThisWindow", "Ptr", hwnd, "Int", 0)
}

HoldMain() {
    global Holding, LastTap
    if MainMode = "tap" {
        if A_TickCount - LastTap >= MainTapMs {
            Send "{" MainKey "}"
            LastTap := A_TickCount
        }
        Holding := true
        return
    }
    Send "{" MainKey " down}"
    Holding := true
}

ReleaseMain() {
    global Holding
    Send "{" MainKey " up}"
    Holding := false
}

#Include core\capture.ahk
GameHwnd() {
    h := WinExist(GameWin)
    return h ? h : WinExist(GameWin2)
}

#Include ui\colors.ahk
; Ctrl+F1: dừng khẩn cấp, nhả V và thoát script (bấm đúp maple_auto.exe để chạy lại)
PanicStop() {
    global Enabled
    Enabled := false
    SetTimer TmrLoop1, 0
    SetTimer TmrHud, 0
    SetTimer TmrScan, 0
    SetTimer TmrFlash, 0
    ToolTip "", , , 2
    Send "{" MainKey " up}"
    ToolTip "ĐÃ DỪNG HẲN SCRIPT (Ctrl+F1)`nBấm đúp maple_auto.exe để chạy lại"
    Sleep 1500
    ExitApp
}

; Quét các ô quickslot định kỳ, lưu kết quả vào s["st"] cho Loop1 và bảng trạng thái dùng chung
ScanRunning := false
BuffDue() {
    for bf in Buffs {
        if bf["enabled"] && bf["key"] != "" && A_TickCount >= bf["next"]
            return true
    }
    return false
}

ScanSlots() {
    global ScanRunning
    ; Có buff đến lượt thì chưa quét: buff chạy trước, quét ngay sau đó (không để buff chen ngang giữa lượt quét)
    if ScanRunning || BuffBusy || BuffDue()
        return
    ScanRunning := true
    try
        ScanSlotsInner()
    finally
        ScanRunning := false
}

ScanSlotsInner() {
    global ScanMs, ScanAt, RelearnMs, RelearnOn, BlockMs, BlockMin, RelearnMin
    if !Enabled || Paused() || BuffBusy
        return
    if !IsGameActive() {
        for s in Skills {
            s["st"] := -1
            s["coolSince"] := 0
        }
        return
    }
    t0 := A_TickCount
    for s in Skills {
        read := false
        cur := ""
        if !(UseSlotCheck && s.Has("slot")) {
            s["st"] := -1
        } else if t0 < s["press"] + s["cd"] * 500 {
            s["st"] := 0        ; chắc chắn còn hồi chiêu: không cần đọc ô (đọc điểm ảnh rất chậm trong sandbox)
        } else {
            cur := SlotSample(s)
            if IsObject(cur) {
                s["st"] := !Base.Has(s["key"]) ? -1 : (SampleDist(cur, Base[s["key"]]) <= ReadyDist ? 1 : 0)
                read := true
            } else {
                s["st"] := -1
            }
        }
        ; ===== Tự học lại màu ô =====
        ; Màu ô chụp ngay sau lần ấn thành công (cdSample) = màu lúc đang hồi chiêu.
        ; Ô khác hẳn màu đó và giữ nguyên >= 2 giây mà mình không ấn -> đó là màu lúc SẴN SÀNG.
        ; Chưa biết màu hồi chiêu (cdSample trống) thì chỉ dám học khi bộ đếm đã quá hạn cooldown
        ; >= 10 giây - lúc đó chắc chắn ô không còn hồi chiêu nên không thể học nhầm.
        if RelearnOn && read && s["st"] = 0 && RelearnMs > 0 {
            overDue := s["press"] > 0 && t0 > s["press"] + s["cd"] * 1000 + 10000
            hadCd := IsObject(s["cdSample"])
            if hadCd ? (SampleDist(cur, s["cdSample"]) > VerifyDist) : overDue {
                if !s.Get("diffSince", 0)
                    s["diffSince"] := t0
                else if t0 - s["diffSince"] >= 2000 {
                    if RelearnSlot(s, cur) && !hadCd
                        DLog("MÀU CHUẨN SAI: " StrUpper(s["key"]) " đã quá cooldown " Round((t0 - s["press"]) / 1000) "s mà ô vẫn báo hồi chiêu -> lấy màu hiện tại làm màu sẵn sàng.")
                }
            } else
                s["diffSince"] := 0
        } else {
            s["diffSince"] := 0
        }
        ; Ô bị coi là hồi chiêu quá lâu: KHÔNG tự đổi màu chuẩn (dễ học nhầm màu hồi chiêu -> ấn liên tục -> bị đăng xuất).
        ; Chỉ tạm ngừng ấn phím đó + ghi cảnh báo để người dùng lấy lại màu trong F5.
        ; Chỉ áp dụng khi phím đã từng được ấn: chưa ấn lần nào thì "quá hạn" là vô nghĩa
        ; (press = 0 sẽ khiến mọi phím bị coi là kẹt ngay khi vừa bật script).
        if RelearnMs > 0 && read && s["st"] = 0 && s["press"] > 0 && t0 > s["press"] + s["cd"] * 2000 {
            if !s.Get("coolSince", 0)
                s["coolSince"] := t0
            else if t0 - s["coolSince"] >= RelearnMs && !s.Get("stuckWarn", 0) {
                if RelearnOn && !IsObject(s["cdSample"]) {
                    ; chưa biết màu lúc hồi chiêu -> ấn THỬ 1 lần để lấy mẫu (không ấn dồn dập, mỗi lần cách nhau RelearnMs)
                    s["probe"] := true
                    s["force"] := true
                    s["coolSince"] := t0
                    s["next"] := t0
                    DLog("THỬ LẠI " StrUpper(s["key"]) ": ô bị coi là hồi chiêu > " Round(RelearnMs / 60000, 1) " phút nhưng CHƯA biết màu hồi chiêu -> ấn thử 1 lần để lấy mẫu màu hồi chiêu.")
                } else {
                    s["stuckWarn"] := 1
                    s["blocked"] := BlockMs > 0 ? t0 + BlockMs : 0
                    if BlockMs > 0
                        DLog("!!! KHÔNG ĐỌC ĐƯỢC Ô " StrUpper(s["key"]) ": bị coi là hồi chiêu > " Round(RelearnMs / 60000, 1) " phút -> TẠM NGỪNG ấn phím này " BlockMin " phút để không bị đăng xuất. Mở thẻ Skill > Màu chuẩn ô > Lấy lại màu cho " StrUpper(s["key"]) ".")
                    else
                        DLog("!!! KHÔNG ĐỌC ĐƯỢC Ô " StrUpper(s["key"]) ": bị coi là hồi chiêu > " Round(RelearnMs / 60000, 1) " phút nhưng 'ngừng ấn' đang đặt 0 phút -> vẫn ấn theo bộ đếm. Mở thẻ Skill > Màu chuẩn ô > Lấy lại màu cho " StrUpper(s["key"]) ".")
                }
            }
        } else if read && s["st"] = 1 {
            s["coolSince"] := 0
            s["stuckWarn"] := 0
            s["blocked"] := 0
            s["stuckPress"] := 0
        } else if !read {
            s["coolSince"] := 0
        }
    }
    ScanMs := A_TickCount - t0
    ScanAt := A_TickCount
    if DebugOn
        PerfAdd("quét_ô_cả_lượt", ScanMs)
    if ScanMs > 500
        DLog("QUÉT Ô chậm: " ScanMs "ms")
}

; Ghi lại lần ấn phím (giữ 10 lần gần nhất)
LogPress(key, how) {
    DLog("ẤN " StrUpper(key) " (" how ")")
    PressLog.InsertAt(1, FormatTime(, "HH:mm:ss") "  " StrUpper(key) "  (" how ")")
    if PressLog.Length > 10
        PressLog.Pop()
}

#Include ui\hud.ahk
; Nháy trắng lúc hồi chiêu xong: cả 2 điểm trên dải mép dưới ô đều gần như trắng
SlotIsWhite(s) {
    WinGetClientPos &cx, &cy, &cw, &ch, GameHwnd()
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    x0 := cx + cw - QS_X0 * kx + QS_DX * kx * s["slot"][1]
    y0 := cy + ch - (s["slot"][2] = 1 ? QS_Y1 : QS_Y2) * ky
    try {
        QsCapture(cx, cy, cw, ch, kx, ky)
        for p in [[-9, 13], [4, 13]] {
            c := QsPix(Round(x0 + p[1] * kx), Round(y0 + p[2] * ky))
            r := (c >> 16) & 0xFF
            g := (c >> 8) & 0xFF
            b := c & 0xFF
            if Min(r, g, b) < 175 || Max(r, g, b) - Min(r, g, b) > 60
                return false
        }
    } catch {
        return false
    }
    return true
}

; Quét nhanh để bắt nháy trắng (kéo dài chưa tới 1 giây). Thấy nháy = skill vừa hồi xong.
ScanFlash() {
    global FlashMs
    if !Enabled || !UseSlotCheck || Paused() || BuffBusy || !IsGameActive()
        return
    t0 := A_TickCount
    for s in Skills {
        if !s.Has("slot") || s["flash"] > s["press"] || s["force"] || t0 - s["press"] < FlashIgnoreMs
            continue
        if SlotIsWhite(s) {
            s["flash"] := A_TickCount
            s["wait"] := A_TickCount + Random(RandMin, RandMax)    ; chờ random 1-3s sau khi hồi xong
        }
    }
    FlashMs := A_TickCount - t0
}

; Kiểm tra sau khi ấn: ô đổi màu (có dải xám hồi chiêu) = skill đã ra (✓); không đổi = chưa ra (✗) -> thử lại
; Ô trông sẵn sàng (dải xám đã hết so với màu chuẩn). Chỉ chặn trong vài giây đầu sau khi ấn
; (dải xám chưa kịp hiện); cooldown thật có thể ngắn hơn đã nhập nên KHÔNG chờ đủ cooldown cấu hình.
ColorReady(s, now) {
    return s["st"] = 1 && now >= s["press"] + Max(MinGapMs, 3000)
}

CheckVerify() {
    global VerifyOk, VerifyFail, VerifyOkAt, BlockMs, BlockMin
    for s in Skills {
        if s.Get("cdAt", 0) && A_TickCount >= s["cdAt"] {
            s["cdAt"] := 0
            c := SlotSample(s)
            if IsObject(c)
                s["cdSample"] := c      ; màu ô khi hồi chiêu đã ổn định (bỏ hiệu ứng loé lúc vừa ấn)
        }
        if !s.Has("slot") || s.Get("vat", 0) = 0 || A_TickCount < s["vat"]
            continue
        s["vat"] := 0
        before := s["vb"]
        after := SlotSample(s)
        verdict := 0
        if IsObject(before) && IsObject(after)
            verdict := SampleDist(before, after) >= VerifyDist ? 1 : -1
        vp := s.Get("probe", 0)
        if verdict = 1 {
            VerifyOk += 1
            s["cdSample"] := after        ; màu ô lúc ĐANG hồi chiêu (mốc để tự học lại màu ô)
            s["cdAt"] := A_TickCount + 1500 ; lấy thêm 1 mẫu lúc hồi chiêu đã ổn định (bỏ hiệu ứng vừa ấn)
            s["probe"] := false
            s["fails"] := 0
            VerifyOkAt := A_TickCount
        } else if verdict = -1 {
            VerifyFail += 1
            if vp {                     ; ấn thử để lấy màu hồi chiêu mà không ra skill: KHÔNG thử lại dồn dập
                s["probe"] := false
                s["force"] := false
                s["fails"] := 0
                s["retries"] := 0
                s["next"] := A_TickCount + RetryGapMs
            }
        }
        mark := verdict = 1 ? " ✓" : (verdict = -1 ? " ✗" : "")
        DLog("KIỂM TRA " StrUpper(s["key"]) ": " (verdict = 1 ? "ra skill ✓" : verdict = -1 ? "KHÔNG ra ✗ (lần thử " (s["retries"] + 1) ")" : "không rõ"))
        for i, line in PressLog {
            if line = s["vline"] {
                PressLog[i] := line . mark
                break
            }
        }
        if verdict = 1
            s["seen"] := true       ; đã thấy dải hồi chiêu xuất hiện: từ giờ tin màu ô, không cần chờ đủ cooldown cấu hình
        if verdict = -1 && s["vhow"] != "hẹn giờ" && !vp {
            s["retries"] += 1
            s["fails"] += 1
            s["force"] := true
            ; giãn cách tăng dần: ấn dồn dập khi ô đọc sai dễ bị đăng xuất
            s["next"] := A_TickCount + (s["fails"] <= MaxRetry ? RetryGapMs : Min(300000, SlowRetryMs * (2 ** Min(s["fails"] - MaxRetry, 4))))
            if s["fails"] >= 5 {
                s["blocked"] := BlockMs > 0 ? A_TickCount + BlockMs : 0
                s["retries"] := 0
                if BlockMs > 0
                    DLog("!!! TẠM NGỪNG ẤN " StrUpper(s["key"]) ": " s["fails"] " lần ấn liên tiếp KHÔNG ra skill -> dừng ấn phím này " BlockMin " phút để tránh bị đăng xuất. Kiểm tra phím/ô của " StrUpper(s["key"]) " ở thẻ Skill.")
                else
                    DLog("!!! " StrUpper(s["key"]) ": " s["fails"] " lần ấn liên tiếp KHÔNG ra skill nhưng 'ngừng ấn' đang đặt 0 phút -> vẫn ấn tiếp theo bộ đếm. Kiểm tra phím/ô của " StrUpper(s["key"]) " ở thẻ Skill.")
            }
        } else {
            s["retries"] := 0
        }
    }
    SkillStuckCheck()
}

; Skill ấn mãi không ra (nhiều skill cùng thất bại liên tiếp) = nhiều khả năng chưa thực sự vào game
; (kẹt ở màn đăng nhập/chọn kênh/tải, hoặc game treo) -> chuyển sang xử lý kẹt: kiểm tra màn hình, vào game tiếp, không được thì đóng game đăng nhập lại
SkillStuckCheck() {
    global SkillRecoverTimes, SkillRecoverBusy, VerifyOkAt
    if !ReloginOn || Relogging || SkillRecoverBusy || !Enabled
        return
    ; Vẫn còn skill "ra ✓" trong 2 phút qua = đang ở trong game, lỗi chỉ ở 1-2 phím/ô
    ; -> KHÔNG chạy quy trình đăng nhập lại (dễ bị đăng xuất oan).
    if VerifyOkAt && A_TickCount - VerifyOkAt < 120000 {
        for s in Skills
            s["retries"] := 0
        return
    }
    bad := 0, tot := 0, names := ""
    for s in Skills {
        if !s.Has("slot")
            continue
        tot += 1
        if s["retries"] >= MaxRetry + 2 {
            bad += 1
            names .= StrUpper(s["key"]) " "
        }
    }
    if bad < 1 || bad < Min(2, tot)
        return
    SkillRecoverBusy := true
    SetTimer () => SkillStuckRecover(names), -50
}

SkillStuckRecover(names) {
    global SkillRecoverTimes, SkillRecoverBusy, Enabled, UserPaused
    SkillRecoverBusy := false
    now := A_TickCount
    while SkillRecoverTimes.Length && now - SkillRecoverTimes[1] > 1800000
        SkillRecoverTimes.RemoveAt(1)
    for s in Skills
        s["retries"] := 0
    if SkillRecoverTimes.Length >= 3 {
        RLog("!!! KẸT KỸ NĂNG (" names ") nhưng đã tự xử lý 3 lần trong 30 phút mà vẫn không ra -> DỪNG auto để tránh lặp vô hạn. Kiểm tra phím skill/ô skill trong F5.")
        Enabled := false
        ToolTip "AUTO DỪNG: skill ấn mãi không ra dù đã đăng nhập lại 3 lần`nXem debug_v1.log"
        SetTimer () => ToolTip(), -8000
        return
    }
    static escTriedAt := 0
    gh0 := GameHwnd()
    if gh0 && now - escTriedAt > 180000 {
        escTriedAt := now
        RLog("!!! KẸT KỸ NĂNG: skill " names "ấn nhiều lần không ra -> thử ấn ESC để tắt bảng thông báo (nếu có) rồi quét lại")
        sc0 := EscAndRescan(gh0)
        if sc0[1] = "channel" || sc0[1] = "loading" {
            RLog("Sau ESC thấy màn " (sc0[1] = "channel" ? "chọn kênh" : "đang tải") " (chưa vào game) -> tiếp tục quy trình vào game")
            DoRelogin(false, 0)
        } else
            RLog("Đã ấn ESC, chờ xem skill có ra lại không; nếu vẫn không ra sẽ xử lý bước tiếp theo")
        return
    }
    SkillRecoverTimes.Push(now)
    gh := GameHwnd(), lh := LauncherHwnd()
    RLog("!!! KẸT KỸ NĂNG: skill " names "ấn nhiều lần không ra (lần xử lý " SkillRecoverTimes.Length "/3 trong 30 phút)")
    RLog(StuckDiag(gh, lh))
    sc := gh ? ScreenOf(gh) : ["", ""]
    if sc[1] = "channel" || sc[1] = "loading" {
        RLog("Đang ở màn hình " (sc[1] = "channel" ? "CHỌN KÊNH" : "ĐANG TẢI") " (chưa vào game) -> tiếp tục quy trình vào game")
        DoRelogin(false, 0)
    } else {
        RLog("Không ở màn chọn kênh/tải mà skill vẫn không ra -> thử xác nhận màn hình rồi đóng game, đăng nhập lại từ đầu")
        DoRelogin(false, 1)
    }
}

#Include core\buff.ahk
LastLoopTick := 0
Loop1() {
    global
    LoopTicks += 1
    if LastLoopTick && A_TickCount - LastLoopTick > PerfMaxGap && !Paused()
        PerfMaxGap := A_TickCount - LastLoopTick
    if LastLoopTick && A_TickCount - LastLoopTick > 1500 && !Paused() {
        rc := ""
        for it in PerfRecent
            rc .= it "; "
        DLog("VÒNG CHÍNH TRỄ: " (A_TickCount - LastLoopTick) "ms kể từ vòng trước (có thứ gì đó chặn). Việc chậm gần đây: " (rc = "" ? "(không ghi nhận)" : rc))
    }
    LastLoopTick := A_TickCount
    if !Enabled
        return
    ; Đang mở cửa sổ Cài đặt / lấy màu: tạm dừng tất cả, nhả phím chính
    if Paused() {
        if Holding
            ReleaseMain()
        return
    }
    ; Tạm dừng khi không ở cửa sổ game
    if !IsGameActive() {
        if Holding
            ReleaseMain()
        return
    }

    CheckVerify()
    FrameCheck()
    ; Bảng buff/EXP Coupon đang chặn game thì mọi phím đều vô tác dụng: tắt nó trước (kiểm tra mỗi 1,5 giây)
    if A_TickCount >= GuardNext {
        GuardNext := A_TickCount + 1500
        BuffBusy := true            ; lúc dò bảng, các timer quét ô tạm im để không chen vào
        try
            gk := BuffDialogKind()
        finally
            BuffBusy := false
        if gk {
            ReleaseMain()
            BuffBusy := true
            try
                r := CloseBlockingDialog()
            finally {
                BuffBusy := false
                LastLoopTick := A_TickCount
            }
            if r = -1 || !Enabled || !IsGameActive()
                return
            DLog("GUARD: bảng chặn game đã xử lý, kết quả " r)
            LogPress("esc", "bảng chặn game" (r ? " ✓ đã tắt" : " ✗ chưa tắt được"))
            return
        }
    }
    for bf in Buffs {
        if bf["enabled"] && bf["key"] != "" && A_TickCount >= bf["next"] && !ScanRunning {
            DoBuff(bf)
            if !Enabled || !IsGameActive()
                return
        }
    }
    ; Skill đã hồi chiêu xong được ưu tiên hơn việc giữ phím chính: ấn hết các skill đến lượt
    ; rồi mới giữ V lại ở cuối.
    for s in (UseSlotCheck && ScanAt < StartTick ? [] : Skills) {
        now := A_TickCount
        slotMode := UseSlotCheck && s.Has("slot")
        how := "hẹn giờ"
        if s.Get("blocked", 0) > now       ; đang tạm ngừng ấn phím này (tránh ấn quá nhiều lần -> bị đăng xuất)
            continue
        if s.Get("blocked", 0) {           ; vừa hết hạn tạm ngừng -> dọn trạng thái để phím được thử lại
            s["blocked"] := 0
            s["stuckWarn"] := 0
            s["coolSince"] := 0
            s["cdSample"] := ""            ; màu hồi chiêu cũ không còn tin được -> học lại từ đầu
            s["st"] := -1
            DLog("HẾT TẠM NGỪNG " StrUpper(s["key"]) ": thử lại phím này. Nếu vẫn báo hồi chiêu sai, mở F5 > Màu chuẩn ô > Lấy lại màu.")
        }
        if slotMode {
            if now < s["next"]
                continue
            if s["force"] {                                ; lần ấn trước skill chưa ra: thử lại
                how := "thử lại"
            } else if s["flash"] > s["press"] {            ; thấy nháy trắng = vừa hồi chiêu xong
                if now < s["wait"]
                    continue
                how := "nháy trắng"
            } else if Base.Has(s["key"]) && s["st"] >= 0 {
                ; màu ô (so với màu chuẩn đã lưu): dải xám hết = sẵn sàng, không chờ đủ cooldown đã nhập
                if !ColorReady(s, now) {
                    ; Ô báo hồi chiêu nhưng chưa ấn lần nào, hoặc bộ đếm cooldown đã hết từ lâu -> nhiều khả năng
                    ; màu chuẩn cũ không còn đúng (đổi cửa sổ / độ phân giải). Vẫn ấn theo bộ đếm để phím
                    ; không bị "chết", mỗi lần cách nhau ít nhất cd + 3 giây nên không ấn dồn dập.
                    if s["st"] = 0 && (s["press"] = 0 || now >= s["tmr"]) {
                        if s["press"] > 0 {
                            how := "bộ đếm (ô kẹt)"
                            if !s.Get("stuckPress", 0)
                                DLog("Ô KẸT: " StrUpper(s["key"]) " vẫn báo hồi chiêu dù bộ đếm đã hết " Round((now - s["tmr"]) / 1000) "s -> ấn theo bộ đếm. Nếu lặp lại, mở F5 > Màu chuẩn ô > Lấy lại màu.")
                            s["stuckPress"] := s.Get("stuckPress", 0) + 1
                        } else
                            how := "chưa ấn lần nào"
                    } else {
                        ; Còn hồi chiêu thật: xoá hẹn giờ giữ, khi nào ô sẵn sàng thì giữ lại 2 giây.
                        ; KHÔNG xoá s["wait"] ở nhánh "ô kẹt" ở trên, nếu xoá thì mỗi vòng lại hẹn lại -> không bao giờ ấn.
                        s["wait"] := 0
                        continue
                    }
                }
                if s["wait"] = 0 {
                    s["wait"] := now + ReadyHoldMs + Random(RandMin, RandMax)
                    continue
                }
                if now < s["wait"]
                    continue
                if how = "hẹn giờ"
                    how := "màu ô"
            } else if now < s["tmr"] {                     ; chưa có màu chuẩn (chưa lấy màu chuẩn) hoặc không đọc được: dùng bộ đếm cooldown
                continue
            }
        } else if now < s["next"] {
            continue
        }

        if !s.Has("nostop") {       ; skill "không dừng V": ấn thẳng khi V vẫn đang giữ, không nhả/không chờ
            ReleaseMain()           ; bỏ giữ V
            Sleep 80
        }
        if !Enabled                 ; vừa bị tắt bằng F1 giữa chừng
            return
        before := slotMode ? SlotSample(s) : ""     ; màu ô trước khi ấn
        Send "{" s["key"] "}"       ; ấn skill
        if CastDelay > 0
            Sleep CastDelay
        LogPress(s["key"], how)
        if slotMode {
            ; kiểm tra lại hình ảnh sau VerifyMs (không chặn việc giữ V): xem ô đã đổi màu chưa
            s["vb"] := before
            s["seen"] := false
            s["vat"] := A_TickCount + VerifyMs
            s["vhow"] := how
            s["vline"] := PressLog[1]
            s["force"] := false
            s["press"] := A_TickCount
            s["wait"] := 0
            s["next"] := A_TickCount + MinGapMs
            s["tmr"] := A_TickCount + s["cd"] * 1000 + Random(RandMin, RandMax) + 3000
        } else if s.Has("rep") {
            s["next"] := A_TickCount + Min(s["cd"] * 1000 + Random(RandMin, RandMax), Random(RepMin, RepMax))
        } else {
            s["next"] := A_TickCount + s["cd"] * 1000 + Random(RandMin, RandMax)
        }
        ; Nếu trong lúc chờ mà bạn ấn F1 tắt (hoặc rời game) thì KHÔNG giữ V lại
        if !Enabled || !IsGameActive()
            return
    }
    HoldMain()  ; hết skill đến lượt: giữ V (gửi lại down để duy trì giữ phím)
}


#Include core\relogin.ahk
TmrRelog := TimedFn("canh_đăng_nhập", ReloginWatch)
TmrLoop1 := TimedFn("loop", Loop1)
TmrScan := TimedFn("timer_quét_ô", ScanSlots)
TmrFlash := TimedFn("timer_nháy", ScanFlash)
TmrHud := TimedFn("bảng_trạng_thái", UpdateHud)
SetTimer TmrRelog, 1000
SetTimer TmrLoop1, TickMs
SetTimer TmrScan, CheckEveryMs
SetTimer TmrFlash, FlashEveryMs
SetTimer TmrHud, 500
if DebugOn {
    StartupLog()
    SetTimer PerfReport, 30000
    SetTimer PerfFirstEnv, -2000
}

OnExit(OnExitLog)

OnExitLog(*) {
    global VerifyOk, VerifyFail, CacheResets, CfgWarn, RatioWarn, MainKey, DebugCount, Relearns
    DLog("=== KẾT THÚC: kiểm tra skill ✓" VerifyOk " ✗" VerifyFail " | tự học lại màu " Relearns " lần | cửa sổ game đổi " CacheResets " lần | cảnh báo cấu hình=" (CfgWarn = "" ? "không" : "CÓ: " CfgWarn) " | cảnh báo tỉ lệ=" (RatioWarn = "" ? "không" : "CÓ: " RatioWarn) " | tổng dòng log=" DebugCount " ===")
    try Send("{" MainKey " up}")
    return 0
}
