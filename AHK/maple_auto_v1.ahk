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
    ["q", "w", "e", "r", "t", "1", "2", "3", "4", "5", "6", "7", "8", "9", "o", "p"],
    ["a", "s", "d", "f", "control", "alt", "z", "x", "c", "u", "i", "j", "k", "l", "n", "m"],
]
DefaultSkills := [
    ; hàng 1 (quickslot hàng trên)
    "q|60|1|0|0|0|0", "w|60|1|1|0|0|0", "e|120|1|2|1|0|1", "r|60|1|3|0|0|0",
    "t|60|1|4|0|0|0", "1|60|1|5|1|0|1", "2|300|1|6|1|0|1", "3|360|1|7|1|0|1",
    "4|60|1|8|0|0|0", "5|60|1|9|0|0|0", "6|60|1|10|0|0|0", "7|60|1|11|0|0|0",
    "8|60|1|12|0|0|0", "9|60|1|13|0|0|0", "o|60|1|14|0|0|0", "p|60|1|15|0|0|0",
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

; ===== Hệ số phóng =====
; Mọi số px trong script/ini (QS_*, BandPts, điểm dò bảng buff, BtnDX/DY...) được đo
; tại vùng game RefW x RefH. Khi cửa sổ game to/nhỏ hơn thì quy đổi lại theo trục.
EnsureRef(cw, ch) {
    global RefW, RefH
    if RefW > 0 {
        if RefH <= 0 && ch > 0
            RefH := ch
        return
    }
    if cw > 0 {
        RefW := cw
        RefH := ch > 0 ? ch : Round(cw * 9 / 16)
        DLog("ENV: chưa có RefW -> tự lấy vùng game hiện tại " RefW "x" RefH " (hệ số phóng = 1)")
    }
}
ScaleX(cw, ch := 0) {
    global RefW, SlotScale
    EnsureRef(cw, ch)
    return SlotScale = "native" ? 1 : (RefW > 0 ? cw / RefW : 1)
}
ScaleY(cw, ch) {
    global RefH, SlotScale
    EnsureRef(cw, ch)
    if SlotScale = "native"
        return 1
    if SlotScale = "stretch"
        return RefH > 0 ? ch / RefH : ScaleX(cw, ch)
    return ScaleX(cw, ch)
}
; Nhiều hằng số trong script là "tỉ lệ của CHIỀU RỘNG" (LoginRY, PlayRY, DotDY...).
; YRatio() đổi chúng sang pixel; YFactor() bù để mode uniform giữ đúng hành vi cũ.
YFactor(cw, ch) {
    global RefW
    EnsureRef(cw, ch)
    return cw > 0 ? RefW * ScaleY(cw, ch) / cw : 1
}
YPx(refPx, cw, ch) => refPx * ScaleY(cw, ch)
YRatio(ry, cw, ch) => ry * cw * YFactor(cw, ch)

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

; ===== Thanh cuộn dọc cho cửa sổ cài đặt khi nội dung cao hơn màn hình =====
ScrollGuis := Map()     ; hwnd -> Map("content", chiều cao nội dung, "view", chiều cao hiển thị)

MakeScrollable(g) {
    g.Show("Hide AutoSize")
    g.GetClientPos(, , &cw, &ch)
    MonitorGetWorkArea(MonitorGetPrimary(), &wl, &wt, &wr, &wb)
    view := (wb - wt) - 70                      ; chừa thanh tiêu đề + viền
    if ch <= view {
        g.Show()
        return
    }
    g.Opt("+0x200000")   ; WS_VSCROLL (v2 không có tùy chọn tên "VScroll" cho Gui)
    ScrollGuis[g.Hwnd] := Map("content", ch, "view", view)
    ScrollSetInfo(g.Hwnd, ch, view, 0)
    g.Show("w" cw " h" view " Center")
}

ScrollSetInfo(hwnd, content, view, pos) {
    si := Buffer(28, 0)
    NumPut("UInt", 28, si, 0)
    NumPut("UInt", 0x7, si, 4)                  ; SIF_RANGE | SIF_PAGE | SIF_POS
    NumPut("Int", 0, si, 8)
    NumPut("Int", content - 1, si, 12)
    NumPut("UInt", view, si, 16)
    NumPut("Int", pos, si, 20)
    DllCall("SetScrollInfo", "Ptr", hwnd, "Int", 1, "Ptr", si, "Int", 1)
}

ScrollGetInfo(hwnd, &pos, &track) {
    si := Buffer(28, 0)
    NumPut("UInt", 28, si, 0)
    NumPut("UInt", 0x17, si, 4)                 ; SIF_ALL
    DllCall("GetScrollInfo", "Ptr", hwnd, "Int", 1, "Ptr", si)
    pos := NumGet(si, 20, "Int")
    track := NumGet(si, 24, "Int")
}

ScrollTo(hwnd, newPos) {
    info := ScrollGuis[hwnd]
    maxPos := Max(0, info["content"] - info["view"])
    newPos := Min(maxPos, Max(0, newPos))
    ScrollGetInfo(hwnd, &cur, &tr)
    dy := cur - newPos
    if dy = 0
        return
    DllCall("ScrollWindowEx", "Ptr", hwnd, "Int", 0, "Int", dy, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x1 | 0x2 | 0x4)
    ScrollSetInfo(hwnd, info["content"], info["view"], newPos)
}

OnVScroll(wParam, lParam, msg, hwnd) {
    if !ScrollGuis.Has(hwnd)
        return
    info := ScrollGuis[hwnd]
    ScrollGetInfo(hwnd, &pos, &track)
    code := wParam & 0xFFFF
    switch code {
        case 0: np := pos - 30
        case 1: np := pos + 30
        case 2: np := pos - info["view"]
        case 3: np := pos + info["view"]
        case 4, 5: np := track
        case 6: np := 0
        case 7: np := info["content"]
        default: return
    }
    ScrollTo(hwnd, np)
    return 0
}

OnWheelScroll(wParam, lParam, msg, hwnd) {
    root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
    if !ScrollGuis.Has(root)
        return
    delta := (wParam >> 16) & 0xFFFF
    if delta > 32767
        delta -= 65536
    ScrollGetInfo(root, &pos, &tr)
    ScrollTo(root, pos - Round(delta / 120) * 60)
    return 0
}
OnMessage(0x115, OnVScroll)
OnMessage(0x20A, OnWheelScroll)

; F5 = bật/tắt bảng cài đặt. Esc hoặc nút Đóng = đóng mà KHÔNG lưu.
ToggleSettings(*) {
    global SettingsGui
    if IsObject(SettingsGui) && GuiVisible(SettingsGui)
        SettingsGui.Hide()
    else
        ShowSettings()
}

ShowSettings(*) {
    global SettingsGui, GuiCtl, SettingsBusy, BuffEditN, ScriptBuild
    SettingsBusy := true        ; tạm dừng trước, rồi mới dựng/mở bảng cài đặt
    Paused()
    if Holding
        ReleaseMain()
    if IsObject(SettingsGui) {
        try SettingsGui.Show()
        SettingsBusy := false
        return
    }
    GuiCtl := Map()
    g := Gui("+AlwaysOnTop", "Maple Auto v1 - Cài đặt [" ScriptBuild "]")
    g.SetFont("s9", "Segoe UI")
    g.AddText("x16 y10 w688", "Chỉnh xong bấm LƯU (nút dưới cùng): script sẽ tự khởi động lại với thiết lập mới. Chi tiết xem HUONG_DAN.txt.")
    tab := g.AddTab3("x16 y34 w688 h600", ["Chung", "Skill", "Buff", "Đăng nhập lại"])
    tab.UseTab(1)
    ; Bảng cài đặt chia 4 thẻ cho gọn. tab.UseTab(n) khiến các control thêm sau đó thuộc thẻ n
    ; (tự ẩn/hiện theo thẻ) và toạ độ tính từ góc trên-trái vùng hiển thị của thẻ (0,0 .. 676,534).
    ; Quên UseTab thì mọi thẻ bị vẽ đè lên nhau.
    rows := [
        ["General", "ToggleKey", "Phím bắt đầu / tạm dừng / tiếp tục:"],
        ["General", "MainKey", "Phím skill chính:"],
        ["General", "MainTapMs", "Chế độ ấn nhả: cách nhau (ms):"],
        ["General", "GameExe", "Tên file game (.exe):"],
        ["General", "GameClass", "Class cửa sổ game:"],
        ["General", "RandMin", "Random sau hồi chiêu - tối thiểu (ms):"],
        ["General", "RandMax", "Random sau hồi chiêu - tối đa (ms):"],
        ["General", "RepMax", "Skill 'lặp': ấn lại tối đa sau (ms):"],
        ["Detect", "GameResW", "Độ rộng độ phân giải game (0 = không phóng):"],
        ["Detect", "RefW", "Độ rộng vùng game lúc đo px tham chiếu (0 = tự):"],
        ["Detect", "RefH", "Chiều cao vùng game lúc đo px tham chiếu (0 = tự):"],
    ]
    y := 8
    for r in rows {
        g.AddText("x24 y" y " w320", r[3])
        GuiCtl[r[2]] := g.AddEdit("x352 y" (y - 3) " w220", Cfg(r[1], r[2]))
        y += 24
    }
    g.AddText("x24 y" y " w320", "Cách phóng toạ độ theo cửa sổ game:")
    GuiCtl["SlotScale"] := g.AddDropDownList("x352 y" (y - 3) " w220 Choose" (SlotScale = "stretch" ? 2 : SlotScale = "native" ? 3 : 1), ["uniform (đều theo chiều rộng - cũ)", "stretch (X theo rộng, Y theo cao)", "native (giữ nguyên px, UI không phóng)"])
    y += 28
    g.AddText("x24 y" y " w320", "Cách dùng skill chính:")
    GuiCtl["MainMode"] := g.AddDropDownList("x352 y" (y - 3) " w220 Choose" (MainMode = "tap" ? 2 : 1), ["Ấn giữ", "Ấn nhả (ấn rồi nhả liên tục)"])
    y += 30
    GuiCtl["AutoFocus"] := g.AddCheckbox("x24 y" y " w320", "Tự đưa game lên trước (chống mất focus), mỗi (giây):")
    GuiCtl["AutoFocus"].Value := AutoFocus ? 1 : 0
    GuiCtl["FocusSec"] := g.AddEdit("x352 y" (y - 3) " w60", Cfg("General", "FocusSec"))
    y += 30
    GuiCtl["ShowHud"] := g.AddCheckbox("x24 y" y " w320", "Hiện bảng thông tin (tooltip) giữa màn hình")
    GuiCtl["ShowHud"].Value := ShowHud ? 1 : 0
    g.AddButton("x352 y" (y - 4) " w220", "Đặt lại thời gian (buff + hồi chiêu)").OnEvent("Click", ResetTimersBtn)
    y += 30
    GuiCtl["DebugOn"] := g.AddCheckbox("x24 y" y " w320", "Ghi log debug vào debug.log - số dòng tối đa:")
    GuiCtl["DebugOn"].Value := DebugOn ? 1 : 0
    GuiCtl["DebugMax"] := g.AddEdit("x352 y" (y - 3) " w60", Cfg("Debug", "MaxEvents"))
    y += 34
    g.AddText("x24 y" y " w640 cGray", "Cài đặt chia 4 thẻ: Chung / Skill / Buff / Đăng nhập lại. Bấm LƯU ở đáy cửa sổ để ghi và khởi động lại script.")

    ; --- Tab 3: Buff (số dòng thêm/bớt bằng nút + / − ở đáy thẻ; bấm LƯU để ghi [Buff] Count) ---
    tab.UseTab(3)
    nB := BuffEditN >= 1 ? BuffEditN : BuffCount
    BuffEditN := nB
    GuiCtl["bufN"] := nB
    y := 16
    loop nB {
        i := A_Index
        pre := "B" i "_"
        GuiCtl[pre "Enabled"] := g.AddCheckbox("x24 y" y " w150", "Tự buff " i ": phím")
        GuiCtl[pre "Enabled"].Value := BuffRowVal(i, "Enabled") = "1" ? 1 : 0
        GuiCtl[pre "Key"] := g.AddEdit("x178 y" (y - 3) " w40", BuffRowVal(i, "Key"))
        g.AddText("x226 y" y " w74", "mỗi (giây):")
        GuiCtl[pre "EverySec"] := g.AddEdit("x302 y" (y - 3) " w52", BuffRowVal(i, "EverySec"))
        g.AddText("x362 y" y " w86", "chờ cast (s):")
        GuiCtl[pre "WaitSec"] := g.AddEdit("x450 y" (y - 3) " w52", BuffRowVal(i, "WaitSec"))
        y += 26
        g.AddText("x24 y" y " w120", "Khi hiện bảng:")
        bAct := StrLower(Trim(BuffRowVal(i, "Action")))
        GuiCtl[pre "Action"] := g.AddDropDownList("x150 y" (y - 3) " w400 Choose" (bAct = "esc" ? 3 : bAct = "all" ? 2 : 1), ["Bấm nút Use Unapplied Buffs (chuột)", "Ấn Enter = Use All Buffs", "Tắt bảng (ESC)"])
        y += 26
    }
    g.AddText("x24 y" y " w650 cGray", "Chỉ khi bảng buff hiện mới ấn Enter/ESC/bấm chuột; không có bảng thì không ấn gì.")
    y += 24
    GuiCtl["BtnInfo"] := g.AddText("x24 y" y " w280", IsNumber(BtnDX) && IsNumber(BtnDY) ? "Vị trí nút đã chọn: " BtnDX ", " BtnDY : "Vị trí nút: chưa chọn (tự tìm bằng màu)")
    g.AddButton("x312 y" (y - 4) " w160", "Chọn vị trí nút...").OnEvent("Click", CaptureBtnPos)
    GuiCtl["AlwaysManual"] := g.AddCheckbox("x480 y" (y + 2) " w190", "Luôn dùng vị trí đã chọn")
    GuiCtl["AlwaysManual"].Value := BuffAlwaysManual ? 1 : 0
    y += 26
    g.AddText("x24 y" y " w650 cGray", "Đặt lại thời gian = buff ấn ngay ở lần chạy tới và mọi skill tính lại hồi chiêu từ đầu.")
    g.AddButton("x24 y478 w150", "Thêm buff (+)").OnEvent("Click", (*) => BuffRowDelta(1))
    g.AddButton("x182 y478 w150", "Bớt buff (−)").OnEvent("Click", (*) => BuffRowDelta(-1))
    g.AddText("x348 y482 w330 cGray", "Tối đa " BuffCountMax " dòng. Thêm/bớt rồi bấm LƯU để ghi.")

    ; --- Tab 4: Đăng nhập lại ---
    tab.UseTab(4)
    GuiCtl["ReOn"] := g.AddCheckbox("x24 y8 w640", "Bật: game văng thì mở launcher (nếu chưa có), bấm PLAY, chọn kênh, Log In")
    GuiCtl["ReOn"].Value := ReloginOn ? 1 : 0
    g.AddText("x24 y40 w150", "Launcher (.exe):")
    GuiCtl["ReLauncher"] := g.AddEdit("x180 y37 w480", ReLauncher)
    g.AddText("x24 y72 w150", "Kênh cần chọn (1-30):")
    GuiCtl["ReChannel"] := g.AddEdit("x180 y69 w80", ReChannel)
    g.AddText("x290 y72 w200", "Coi là văng sau (giây):")
    GuiCtl["ReLost"] := g.AddEdit("x496 y69 w80", ReLostSec)
    g.AddButton("x24 y104 w320", "Nhận diện màn hình (khoanh vùng bằng kéo thả)...").OnEvent("Click", (*) => ShowZoneGui())
    g.AddButton("x352 y104 w300", "Chạy thử quy trình đăng nhập lại").OnEvent("Click", TestRelogin)
    g.AddText("x24 y140 w640 cGray", "F9 = chạy thử quy trình (mở sẵn launcher hoặc màn hình chọn kênh). Log từng bước: debug_v1.log.")

    ; --- Tab 2: Skill ---
    tab.UseTab(2)
    GuiCtl["UseSlotCheck"] := g.AddCheckbox("x20 y8 w430", "Đọc ô quickslot để biết hồi chiêu xong (bỏ = chỉ dùng bộ đếm)")
    GuiCtl["UseSlotCheck"].Value := UseSlotCheck ? 1 : 0
    g.AddButton("x462 y4 w210", "Màu chuẩn ô (bảng lấy màu)...").OnEvent("Click", (*) => ShowColorGui())
    GuiCtl["Relearn"] := g.AddCheckbox("x20 y30 w230", "Tự học lại màu ô (BETA)")
    GuiCtl["Relearn"].Value := RelearnOn ? 1 : 0
    g.AddText("x256 y33 w300", "Coi là hồi chiêu quá lâu (phút) thì ngừng ấn:")
    GuiCtl["RelearnMin"] := g.AddEdit("x560 y30 w50", Cfg("Detect", "RelearnMin"))
    g.AddText("x20 y54 w440", "Ấn mãi không ra thì ngừng ấn phím đó (phút, 0 = không ngừng):")
    GuiCtl["BlockMin"] := g.AddEdit("x466 y51 w50", Cfg("Detect", "BlockMin"))
    g.SetFont("s8", "Segoe UI")          ; tiêu đề cột nhỏ hơn để 2 dòng chữ dài vẫn vừa ô hẹp
    for cx in [20, 366] {
        g.AddText("x" cx " y80 w26", "Bật")
        g.AddText("x" (cx + 32) " y80 w46", "Phím")
        g.AddText("x" (cx + 82) " y76 w50", "Cooldown`n(giây)")
        g.AddText("x" (cx + 136) " y76 w72", "Ấn lặp`n(bỏ hồi chiêu)")
        g.AddText("x" (cx + 212) " y76 w104", "Không dừng`nmain Skill")
    }
    g.SetFont("s9", "Segoe UI")

    GuiCtl["rows"] := []
    extra := 0
    loop MaxSkillRows {
        line := IniRead(IniFile, "Skills", "Skill" A_Index, "")
        f := StrSplit(line, "|")
        while f.Length < 7
            f.Push("")
        fx := LayoutEntry(A_Index)
        fixed := fx[1] != ""
        if fixed
            f[1] := fx[1], f[3] := String(fx[2]), f[4] := String(fx[3])
        if Trim(f[2]) = ""
            f[2] := "60"
        ; hàng 1 của bàn phím -> cột trái, hàng 2 -> cột phải, phím ngoài danh sách -> cuối cột phải
        cx := (!fixed || fx[2] = 2) ? 366 : 20
        cy := 104 + (fixed ? fx[3] : 16 + extra) * 22
        if !fixed
            extra += 1
        c0 := g.AddCheckbox("x" cx " y" (cy + 3) " w26", "")
        c0.Value := (Trim(f[7]) = "0" || Trim(f[1]) = "") ? 0 : 1      ; không ghi/trống = bật; dòng trống = tắt
        e1 := fixed ? g.AddEdit("x" (cx + 30) " y" cy " w46 ReadOnly BackgroundEEEEEE", KeyLabel(f[1])) : g.AddEdit("x" (cx + 30) " y" cy " w46", f[1])
        e2 := g.AddEdit("x" (cx + 80) " y" cy " w66", f[2])
        c5 := g.AddCheckbox("x" (cx + 154) " y" (cy + 3) " w30", "")
        c5.Value := Trim(f[5]) = "1" ? 1 : 0
        c6 := g.AddCheckbox("x" (cx + 212) " y" (cy + 3) " w98", "")
        c6.Value := Trim(f[6]) = "1" ? 1 : 0
        ; Map (không dùng object literal) vì SaveSettings/ListSkills truy cập bằng r["..."] - object thường không hỗ trợ []
        GuiCtl["rows"].Push(Map("e1", e1, "e2", e2, "c5", c5, "c6", c6, "c0", c0, "fixed", fx, "oldRow", f[3], "oldCol", f[4]))
    }
    g.AddText("x20 y512 w650 cGray", "Phím/hàng/cột đã cố định theo 2 hàng phím: chỉ cần điền Cooldown + tick Bật.`nẤn lặp = bỏ qua hồi chiêu đã nhập, ấn lại sau RepMin-RepMax ms (cấu hình ở thẻ Chung).`nKhông dừng main Skill = vẫn giữ phím chính khi dùng skill này. 2 dòng cuối cột phải: phím ngoài danh sách.")
    ; --- Nút điều khiển: luôn nằm ở đáy cửa sổ, ngoài các thẻ ---
    tab.UseTab(1)          ; hiện lại thẻ đầu khi mở bảng
    tab.UseTab()           ; không truyền số = các control sau thuộc về cửa sổ, toạ độ tuyệt đối
    g.AddButton("x16 y650 w110 Default", "LƯU").OnEvent("Click", SaveSettings)
    g.AddButton("x+8 w140", "Mở HƯỚNG DẪN").OnEvent("Click", (*) => OpenGuide())
    g.AddButton("x+8 w110", "Đóng").OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    g.OnEvent("Escape", (*) => g.Hide())    ; Esc = đóng bảng, KHÔNG lưu (LƯU chỉ chạy khi bấm nút hoặc Enter)
    SettingsGui := g
    if Holding
        ReleaseMain()
    g.Show("w732 h716 Center")
    TabPageShift(g)
    GuiGeomLog(nB)
    SettingsBusy := false
}

; AHK v2 đặt control của trang thẻ theo gốc client của CỬA SỔ, không theo gốc trang thẻ, nên toàn bộ
; control bị lệch lên đúng bằng khoảng cách từ đỉnh vùng thẻ tới đỉnh trang và những dòng sát trên bị cắt mất.
; Hàm này đo độ lệch thật của từng trang rồi đẩy control xuống cho khớp (không đổi kích thước).
TabPageShift(g) {
    global DebugOn
    pt := Buffer(8, 0)
    DllCall("ClientToScreen", "Ptr", g.Hwnd, "Ptr", pt.Ptr, "Int")
    guiTop := NumGet(pt, 4, "Int")
    msg := ""
    hPage := 0
    while (hPage := DllCall("FindWindowEx", "Ptr", g.Hwnd, "Ptr", hPage, "Str", "#32770", "Ptr", 0, "Ptr")) {
        rc := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", hPage, "Ptr", rc.Ptr, "Int")
        dy := NumGet(rc, 4, "Int") - guiTop
        if (dy <= 0)
            continue
        n := 0
        hCtl := 0
        while (hCtl := DllCall("FindWindowEx", "Ptr", hPage, "Ptr", hCtl, "Ptr", 0, "Ptr", 0, "Ptr")) {
            cr := Buffer(16, 0)
            DllCall("GetWindowRect", "Ptr", hCtl, "Ptr", cr.Ptr, "Int")
            q := Buffer(8, 0)
            NumPut("Int", NumGet(cr, 0, "Int"), q, 0)
            NumPut("Int", NumGet(cr, 4, "Int") + dy, q, 4)
            DllCall("ScreenToClient", "Ptr", hPage, "Ptr", q.Ptr, "Int")
            DllCall("SetWindowPos", "Ptr", hCtl, "Ptr", 0
                , "Int", NumGet(q, 0, "Int"), "Int", NumGet(q, 4, "Int")
                , "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0004 | 0x0010)
            n += 1
        }
        msg .= (msg = "" ? "" : ", ") "trang " n " ctl bù " dy "px"
    }
    if (DebugOn && msg != "")
        DLog("GUI thẻ: " msg)
}

; Ghi hình học thẻ Buff vào log để nghiệm thu: dòng nào đang hiện, nằm ở đâu, có bị che/khuất không
GuiGeomLog(nB) {
    global SettingsGui, GuiCtl, DebugOn, BuffCount, BuffEditN
    if !DebugOn
        return
    st := ""
    try {
        tabC := SettingsGui["SysTabControl321"]
        tx := "", ty := "", tw := "", th := ""
        tabC.GetPos(&tx, &ty, &tw, &th)
        tabC.Value := 3
        Sleep 150
        st := "thẻ=" tx "," ty " " tw "x" th
        loop nB {
            c := GuiCtl["B" A_Index "_Enabled"]
            x := "", y := "", w := "", h := ""
            c.GetPos(&x, &y, &w, &h)
            st .= " | B" A_Index " y=" y " '" StrReplace(c.Text, ": phím", "") "'"
                . (DllCall("IsWindowVisible", "Ptr", c.Hwnd, "Int") ? " hiện" : " ẨN")
        }
        tabC.Value := 1
    } catch as e {
        st .= " (lỗi " e.Message ")"
    }
    st .= " || Count=" BuffCount " EditN=" BuffEditN " k1=" BuffRowVal(1, "Key")
        . " k2=" (nB >= 2 ? BuffRowVal(2, "Key") : "")
    DLog("GUI Buff: " nB " dòng | " st)
}
; Thêm/bớt 1 dòng buff trong thẻ Buff: chỉ đổi số dòng đang hiện, bấm LƯU mới ghi vào ini
BuffRowDelta(d) {
    global BuffEditN, BuffCountMax, SettingsGui, BuffDraft, GuiCtl
    base := BuffEditN >= 1 ? BuffEditN : BuffCount
    n := Max(1, Min(BuffCountMax, base + d))
    if n = base {
        if (d > 0 && base >= BuffCountMax)
            ToolTip("Tối đa " BuffCountMax " dòng buff."), SetTimer(() => ToolTip(), -1500)
        return
    }
    ; giữ lại giá trị đang sửa (chưa LƯU) trước khi dựng lại cửa sổ
    BuffDraft := Map()
    loop base {
        i := A_Index, pre := "B" i "_"
        if !GuiCtl.Has(pre "Key")
            continue
        BuffDraft[i "|Enabled"] := GuiCtl[pre "Enabled"].Value ? "1" : "0"
        BuffDraft[i "|Key"] := Trim(GuiCtl[pre "Key"].Value)
        BuffDraft[i "|EverySec"] := Trim(GuiCtl[pre "EverySec"].Value)
        BuffDraft[i "|WaitSec"] := Trim(GuiCtl[pre "WaitSec"].Value)
        v := GuiCtl[pre "Action"].Value
        BuffDraft[i "|Action"] := v = 3 ? "esc" : v = 2 ? "all" : "unapplied"
    }
    BuffEditN := n
    if IsObject(SettingsGui) {
        try SettingsGui.Destroy()
        SettingsGui := ""
    }
    ShowSettings()
}

ResetTimersBtn(*) {
    ResetTimers()
    MsgBox "Đã đặt lại thời gian: buff sẽ ấn ngay và các skill tính lại từ đầu khi chạy tiếp.", "Maple Auto", "Iconi T4"
}

OpenGuide() {
    f := A_ScriptDir "\HUONG_DAN.txt"
    if FileExist(f)
    {
        try {
            Run 'notepad.exe "' f '"'
        } catch {
            try Run('"' f '"')
            catch
                MsgBox "Không mở được tự động. Hãy mở file này bằng tay:`\n" f, "Maple Auto", "Icon!"
        }
    }
    else
        MsgBox "Không tìm thấy HUONG_DAN.txt cạnh script.", "Maple Auto", "Icon!"
}

SaveSettings(*) {
    ; kiểm tra số
    for k in ["RandMin", "RandMax", "RepMax", "GameResW", "RefW", "RefH", "MainTapMs", "FocusSec"] {
        if !IsInteger(Trim(GuiCtl[k].Value)) || Integer(Trim(GuiCtl[k].Value)) < 0 {
            MsgBox "Ô '" k "' phải là số nguyên không âm.", "Maple Auto", "Icon!"
            return
        }
    }
    loop GuiCtl["bufN"] {
        pre := "B" A_Index "_"
        for k in ["EverySec", "WaitSec"] {
            if !IsNumber(Trim(GuiCtl[pre k].Value)) || Number(Trim(GuiCtl[pre k].Value)) < 0 {
                MsgBox "Ô '" k "' của Tự buff " A_Index " phải là số không âm.", "Maple Auto", "Icon!"
                return
            }
        }
        if GuiCtl[pre "Enabled"].Value && Trim(GuiCtl[pre "Key"].Value) = "" {
            MsgBox "Hãy nhập phím cho Tự buff " A_Index " hoặc bỏ chọn nó.", "Maple Auto", "Icon!"
            return
        }
    }
    if !IsInteger(Trim(GuiCtl["DebugMax"].Value)) || Integer(Trim(GuiCtl["DebugMax"].Value)) < 50 {
        MsgBox "Số dòng log tối đa phải là số nguyên từ 50 trở lên.", "Maple Auto", "Icon!"
        return
    }
    if !IsNumber(Trim(GuiCtl["RelearnMin"].Value)) || Number(Trim(GuiCtl["RelearnMin"].Value)) < 0 {
        MsgBox "'Coi là hồi chiêu quá lâu' phải là số phút không âm.", "Maple Auto", "Icon!"
        return
    }
    if !IsNumber(Trim(GuiCtl["BlockMin"].Value)) || Number(Trim(GuiCtl["BlockMin"].Value)) < 0 || Number(Trim(GuiCtl["BlockMin"].Value)) > 120 {
        MsgBox "'Ngừng ấn phím khi ấn mãi không ra' phải là số phút từ 0 đến 120.", "Maple Auto", "Icon!"
        return
    }
    if !IsInteger(Trim(GuiCtl["ReChannel"].Value)) || Integer(Trim(GuiCtl["ReChannel"].Value)) < 1 || Integer(Trim(GuiCtl["ReChannel"].Value)) > 30 {
        MsgBox "Kênh phải là số từ 1 đến 30.", "Maple Auto", "Icon!"
        return
    }
    if !IsInteger(Trim(GuiCtl["ReLost"].Value)) || Integer(Trim(GuiCtl["ReLost"].Value)) < 3 {
        MsgBox "'Coi là văng sau' phải là số nguyên từ 3 giây trở lên.", "Maple Auto", "Icon!"
        return
    }
    tk := Trim(GuiCtl["ToggleKey"].Value)
    if tk = "" {
        MsgBox "Hãy nhập phím bắt đầu / tạm dừng (vd F1).", "Maple Auto", "Icon!"
        return
    }
    try {
        Hotkey("$" tk, (*) => 0, "Off")
    } catch {
        MsgBox "Tên phím '" tk "' không hợp lệ (vd: F1, F3, Pause, NumpadAdd).", "Maple Auto", "Icon!"
        return
    }
    if Trim(GuiCtl["MainKey"].Value) = "" || Trim(GuiCtl["GameExe"].Value) = "" {
        MsgBox "Phím chính và tên file game không được để trống.", "Maple Auto", "Icon!"
        return
    }
    n := 0
    lines := []
    for r in GuiCtl["rows"] {
        fx := r["fixed"]
        if fx[1] != "" {
            key := fx[1], row := String(fx[2]), col := String(fx[3])
        } else {
            key := StrLower(Trim(r["e1"].Value))
            if key = ""
                continue
            row := Trim(r["oldRow"]), col := Trim(r["oldCol"])
            if !IsInteger(row) || Integer(row) < 0 || Integer(row) > 2 || !IsInteger(col) || Integer(col) < 0
                row := "0", col := "0"
        }
        cd := Trim(r["e2"].Value)
        if cd = ""
            cd := "60"           ; dòng để trống cooldown thì dùng 60 giây, không chặn việc lưu
        else if !IsNumber(cd) || Number(cd) <= 0 {
            MsgBox "Dòng skill '" key "' có cooldown không hợp lệ (phải > 0).", "Maple Auto", "Icon!"
            return
        }
        lines.Push(key "|" cd "|" row "|" col "|" (r["c5"].Value ? 1 : 0) "|" (r["c6"].Value ? 1 : 0) "|" (r["c0"].Value ? 1 : 0))
    }
    try {
        IniWrite GuiCtl["ShowHud"].Value, IniFile, "General", "ShowHud"
        IniWrite GuiCtl["ReOn"].Value, IniFile, "Relogin", "Enabled"
        IniWrite Trim(GuiCtl["ReLauncher"].Value), IniFile, "Relogin", "LauncherPath"
        IniWrite Trim(GuiCtl["ReChannel"].Value), IniFile, "Relogin", "Channel"
        IniWrite Trim(GuiCtl["ReLost"].Value), IniFile, "Relogin", "LostSec"
        IniWrite GuiCtl["DebugOn"].Value, IniFile, "Debug", "Enabled"
        IniWrite Trim(GuiCtl["DebugMax"].Value), IniFile, "Debug", "MaxEvents"
        for k in ["ToggleKey", "MainKey", "MainTapMs", "GameExe", "GameClass", "RandMin", "RandMax", "RepMax"]
            IniWrite Trim(GuiCtl[k].Value), IniFile, "General", k
        IniWrite Trim(GuiCtl["GameResW"].Value), IniFile, "Detect", "GameResW"
        IniWrite Trim(GuiCtl["RefW"].Value), IniFile, "Detect", "RefW"
        IniWrite Trim(GuiCtl["RefH"].Value), IniFile, "Detect", "RefH"
        rl := Trim(GuiCtl["RelearnMin"].Value)
        IniWrite (IsNumber(rl) && Number(rl) >= 0 ? rl : "5"), IniFile, "Detect", "RelearnMin"
        IniWrite (GuiCtl["Relearn"].Value ? "1" : "0"), IniFile, "Detect", "Relearn"
        IniWrite (Trim(GuiCtl["BlockMin"].Value)), IniFile, "Detect", "BlockMin"
        IniWrite (GuiCtl["SlotScale"].Value = 2 ? "stretch" : GuiCtl["SlotScale"].Value = 3 ? "native" : "uniform"), IniFile, "Detect", "SlotScale"
        IniWrite (GuiCtl["MainMode"].Value = 2 ? "tap" : "hold"), IniFile, "General", "MainMode"
        IniWrite GuiCtl["UseSlotCheck"].Value, IniFile, "Detect", "UseSlotCheck"
        IniWrite Trim(GuiCtl["FocusSec"].Value), IniFile, "General", "FocusSec"
        IniWrite GuiCtl["AutoFocus"].Value, IniFile, "General", "AutoFocus"
        IniWrite GuiCtl["bufN"], IniFile, "Buff", "Count"
        loop GuiCtl["bufN"] {
            pre := "B" A_Index "_"
            sec := BuffSec(A_Index)
            IniWrite GuiCtl[pre "Enabled"].Value, IniFile, sec, "Enabled"
            IniWrite Trim(GuiCtl[pre "Key"].Value), IniFile, sec, "Key"
            IniWrite Trim(GuiCtl[pre "EverySec"].Value), IniFile, sec, "EverySec"
            IniWrite Trim(GuiCtl[pre "WaitSec"].Value), IniFile, sec, "WaitSec"
            v := GuiCtl[pre "Action"].Value
            IniWrite (v = 3 ? "esc" : v = 2 ? "all" : "unapplied"), IniFile, sec, "Action"
        }
        loop BuffCountMax {            ; bớt dòng thì xoá cấu hình của các dòng dư
            if A_Index <= GuiCtl["bufN"]
                continue
            for k in ["Enabled", "Key", "EverySec", "WaitSec", "Action"]
                IniDelete IniFile, BuffSec(A_Index), k
        }
        IniWrite GuiCtl["AlwaysManual"].Value, IniFile, "Buff", "AlwaysManual"
        if IsObject(NewBtn) {
            IniWrite NewBtn[1], IniFile, "Buff", "BtnDX"
            IniWrite NewBtn[2], IniFile, "Buff", "BtnDY"
        }
        loop MaxSkillRows
            IniDelete IniFile, "Skills", "Skill" A_Index
        for i, l in lines
            IniWrite l, IniFile, "Skills", "Skill" i
    } catch as err {
        MsgBox "Không ghi được file cài đặt (có thể file đang bị khoá):`n" IniFile "`n`n" err.Message, "Maple Auto", "Icon!"
        return
    }
    ; đọc lại để chắc chắn đã ghi được (nếu ghi hụt thì báo ngay, không im lặng khởi động lại)
    if IniRead(IniFile, "General", "ToggleKey", "") != Trim(GuiCtl["ToggleKey"].Value) {
        MsgBox "Ghi cài đặt KHÔNG thành công:`n" IniFile "`n`nHãy kiểm tra quyền ghi file rồi bấm LƯU lại.", "Maple Auto", "Icon!"
        return
    }
    try Send "{" MainKey " up}"
    ToolTip "Đã lưu cài đặt - đang khởi động lại..."
    SetTimer () => ToolTip(), -1200
    Sleep 250
    Reload
}

A_TrayMenu.Add()
A_TrayMenu.Add("Cài đặt (F5)", ToggleSettings)
A_TrayMenu.Add("Hướng dẫn", (*) => OpenGuide())
if FirstRun
    SetTimer ShowSettings, -500

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

; ===== Chụp gộp dải quickslot =====
; Đọc từng điểm bằng PixelGetColor rất chậm trong sandbox (~30ms/điểm, vì mỗi lần gọi phải lấy lại ảnh màn hình qua GPU ảo),
; mà mỗi lượt quét cần hàng chục điểm. Ở đây chụp CẢ dải quickslot một lần vào bộ nhớ rồi đọc các điểm từ ảnh đó (tức thời).
; Ảnh chụp dùng chung cho quét ô, quét nháy trắng và kiểm tra sau khi ấn (còn mới <= 80ms thì không chụp lại).
; Chụp lỗi 3 lần liên tiếp thì tự tắt và quay về đọc từng điểm. Tắt hẳn bằng BatchCapture=0 trong settings_v1.ini [Detect].
QsBuf := ""
QsX := 0, QsY := 0, QsW := 0, QsH := 0
QsCx := 0, QsCy := 0, QsCw := 0, QsCh := 0
QsAt := 0, QsOk := false, QsFails := 0, QsOff := false, QsLogged := 0, QsLastSlow := 0
QsGeomSig := ""

QsCapture(cx, cy, cw, ch, kx, ky, force := false) {
    global QsBuf, QsX, QsY, QsW, QsH, QsCx, QsCy, QsCw, QsCh, QsAt, QsOk, QsFails, QsOff, QsLogged, QsLastSlow, QsGeomSig
    if !UseBatch || QsOff
        return false
    if !force && QsOk && A_TickCount - QsAt <= 80 && QsCx = cx && QsCy = cy && QsCw = cw && QsCh = ch
        return true
    maxCol := -1
    for s in Skills {
        if s.Has("slot")
            maxCol := Max(maxCol, s["slot"][1])
    }
    if maxCol < 0
        return false
    minPX := 99999, maxPX := -99999, minPY := 99999, maxPY := -99999
    for p in BandPts {
        minPX := Min(minPX, p[1]), maxPX := Max(maxPX, p[1])
        minPY := Min(minPY, p[2]), maxPY := Max(maxPY, p[2])
    }
    xl := cx + cw - QS_X0 * kx
    x := Floor(xl + minPX * kx) - 3
    xe := Ceil(xl + QS_DX * kx * maxCol + maxPX * kx) + 3
    y := Floor(cy + ch - Max(QS_Y1, QS_Y2) * ky + minPY * ky) - 3
    ye := Ceil(cy + ch - Min(QS_Y1, QS_Y2) * ky + maxPY * ky) + 3
    w := xe - x + 1
    h := ye - y + 1
    if w < 1 || h < 1 || w > 4000 || h > 1000
        return false
    ok := false
    t := PerfNow()
    Critical "On"                       ; không cho timer khác chen vào giữa lúc chụp / sao chép
    try {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        if hdc {
            mdc := DllCall("CreateCompatibleDC", "Ptr", hdc, "Ptr")
            bmi := Buffer(40, 0)
            NumPut("UInt", 40, bmi, 0)
            NumPut("Int", w, bmi, 4)
            NumPut("Int", -h, bmi, 8)           ; âm = ảnh xuôi (hàng trên cùng trước)
            NumPut("UShort", 1, bmi, 12)
            NumPut("UShort", 32, bmi, 14)
            bits := 0
            hbm := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bmi, "UInt", 0, "Ptr*", &bits, "Ptr", 0, "UInt", 0, "Ptr")
            if mdc && hbm && bits {
                old := DllCall("SelectObject", "Ptr", mdc, "Ptr", hbm, "Ptr")
                if DllCall("BitBlt", "Ptr", mdc, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdc, "Int", x, "Int", y, "UInt", 0x00CC0020, "Int") {
                    if !IsObject(QsBuf) || QsBuf.Size < w * h * 4
                        QsBuf := Buffer(w * h * 4)
                    DllCall("RtlMoveMemory", "Ptr", QsBuf, "Ptr", bits, "UPtr", w * h * 4)
                    ok := true
                }
                DllCall("SelectObject", "Ptr", mdc, "Ptr", old)
            }
            if hbm
                DllCall("DeleteObject", "Ptr", hbm)
            if mdc
                DllCall("DeleteDC", "Ptr", mdc)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        }
        if ok {
            QsX := x, QsY := y, QsW := w, QsH := h
            QsCx := cx, QsCy := cy, QsCw := cw, QsCh := ch
            QsAt := A_TickCount
            QsOk := true
            QsFails := 0
        } else {
            QsOk := false
            QsFails += 1
        }
    } finally {
        Critical "Off"
    }
    d := PerfNow() - t
    if DebugOn {
        PerfAdd("chụp_dải_ô", d)
        sig := x "," y "," w "," h
        if QsGeomSig != sig {
            QsGeomSig := sig
            QsLogged += 1
            DLog("QS: vùng chụp đổi -> " w "x" h " tại (" x "," y ") mất " Round(d, 1) "ms " (ok ? "OK" : "LỖI") "  (client " cw "x" ch " tại " cx "," cy "  kx=" Round(kx, 3) " ky=" Round(ky, 3) "  lần " QsLogged ")")
        } else if d > 300 && A_TickCount - QsLastSlow > 2000 {
            QsLastSlow := A_TickCount
            DLog("QS: chụp gộp chậm " Round(d) "ms")
        }
    }
    if !ok && QsFails >= 3 {
        QsOff := true
        DLog("QS: chụp gộp lỗi 3 lần liên tiếp -> TẮT, quay về đọc từng điểm")
    }
    return ok
}

; Màu 1 điểm (0xRRGGBB): lấy từ ảnh chụp gộp nếu điểm nằm trong đó, không thì đọc trực tiếp
QsPix(x, y) {
    if QsOk && x >= QsX && x < QsX + QsW && y >= QsY && y < QsY + QsH
        return NumGet(QsBuf, ((y - QsY) * QsW + (x - QsX)) * 4, "UInt") & 0xFFFFFF
    return PxGet(x, y)
}

; ===== Đọc ô quickslot =====
; Khi hồi chiêu, ô KHÔNG tối đi mà có một dải xám mờ ở mép dưới icon (và nháy trắng lúc hồi xong).
; Vì vậy script đọc màu vài điểm trên dải đó rồi so với màu lúc skill sẵn sàng (lưu bằng nút "Lấy màu chuẩn" trong F5).

; Đọc màu các điểm trên dải; trả về mảng [[r,g,b], ...] hoặc "" nếu không đọc được
SlotSample(s) {
    if !GameHwnd()
        return ""
    WinGetClientPos &cx, &cy, &cw, &ch, GameHwnd()
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    x0 := cx + cw - QS_X0 * kx + QS_DX * kx * s["slot"][1]
    y0 := cy + ch - (s["slot"][2] = 1 ? QS_Y1 : QS_Y2) * ky
    out := []
    try {
        QsCapture(cx, cy, cw, ch, kx, ky)
        for p in BandPts {
            c := QsPix(Round(x0 + p[1] * kx), Round(y0 + p[2] * ky))
            out.Push([(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF])
        }
    } catch {
        return ""
    }
    return out
}

; Khoảng cách màu LỚN NHẤT giữa các điểm tương ứng của hai mẫu
SampleDist(a, b) {
    m := 0
    for i, p in a {
        q := b[i]
        d := Sqrt((p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2 + (p[3] - q[3]) ** 2)
        if d > m
            m := d
    }
    return m
}

SampleToStr(a) {
    out := ""
    for p in a {
        if out != ""
            out .= ";"
        out .= p[1] "," p[2] "," p[3]
    }
    return out
}

; Mẫu toàn điểm sáng gần trắng = nháy trắng lúc vừa hồi chiêu xong
SampleIsWhite(c) {
    for p in c {
        if Min(p[1], p[2], p[3]) < 175 || Max(p[1], p[2], p[3]) - Min(p[1], p[2], p[3]) > 60
            return false
    }
    return c.Length > 0
}

StrToSample(str) {
    out := []
    for part in StrSplit(str, ";") {
        c := StrSplit(part, ",")
        out.Push([Number(c[1]), Number(c[2]), Number(c[3])])
    }
    return out
}

; 1 = sẵn sàng, 0 = đang hồi chiêu, -1 = không đọc được / chưa có màu chuẩn
SlotState(s) {
    key := s["key"]
    if !Base.Has(key)
        return -1
    t := DebugOn ? PerfNow() : 0
    cur := SlotSample(s)
    if DebugOn
        PerfAdd("đọc_ô(" key ")", PerfNow() - t)
    if !IsObject(cur)
        return -1
    return SampleDist(cur, Base[key]) <= ReadyDist ? 1 : 0
}

; F2: bảng màu các ô quickslot trong 10 giây - XANH = sẵn sàng, ĐỎ = đang hồi chiêu
DebugSlots() {
    global Skills, Base, ReadyDist, SlotColorGui
    if IsObject(SlotColorGui) {
        try SlotColorGui.Destroy()
        SlotColorGui := ""
    }
    WinGetClientPos , , &cw, &ch, GameHwnd()
    g := Gui("+AlwaysOnTop -Caption +Border +ToolWindow", "Màu ô quickslot")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 10
    g.AddText("cBlack", "Vùng game " cw "x" ch "  kx=" Round(ScaleX(cw, ch), 3) " ky=" Round(ScaleY(cw, ch), 3) "  (sẵn sàng nếu lệch <= " ReadyDist ")")
    nReady := 0, nCool := 0
    for s in Skills {
        if !s.Has("slot")
            continue
        k := StrUpper(s["key"])
        cur := SlotSample(s)
        if !IsObject(cur) {
            g.AddText("cGray", k ": LỖI không đọc được ô")
            continue
        }
        if !Base.Has(s["key"]) {
            g.AddText("cGray", k ": chưa lưu màu chuẩn (thẻ Skill > Màu chuẩn ô)")
            continue
        }
        d := SampleDist(cur, Base[s["key"]])
        if d <= ReadyDist {
            nReady += 1
            g.AddText("cGreen", k ": SẴN SÀNG - lệch " Round(d))
        } else {
            nCool += 1
            g.AddText("cRed", k ": HỒI CHIÊU - lệch " Round(d))
        }
    }
    g.AddText("cBlack", "Sẵn sàng: " nReady "   Hồi chiêu: " nCool "   (F2 lại để xem tiếp, tự đóng sau 10s)")
    g.Show("AutoSize Center")
    SlotColorGui := g
    SetTimer CloseSlotColor, -10000
}

CloseSlotColor(*) {
    global SlotColorGui
    if IsObject(SlotColorGui) {
        try SlotColorGui.Destroy()
        SlotColorGui := ""
    }
}

; Ô đã rời màu hồi chiêu (khác cdSample) và giữ nguyên >= 2 giây -> lấy màu đó làm màu "sẵn sàng".
; KHÔNG bao giờ lấy màu đang hồi chiêu: nếu mẫu trùng màu hồi chiêu đã biết hoặc là nháy trắng thì bỏ qua.
RelearnSlot(s, cur) {
    global Base, SlotIni, Relearns, RelearnMs, VerifyDist
    if !IsObject(cur)
        return false
    now := A_TickCount
    if now - s.Get("relearnAt", 0) < 30000        ; mỗi phím học lại tối đa 1 lần / 30 giây
        return false
    if SampleIsWhite(cur)
        return false
    if IsObject(s["cdSample"]) && SampleDist(cur, s["cdSample"]) <= VerifyDist
        return false
    old := Base.Has(s["key"]) ? SampleToStr(Base[s["key"]]) : "(chưa có)"
    if Base.Has(s["key"]) && SampleDist(cur, Base[s["key"]]) <= VerifyDist
        return false                               ; vẫn là màu cũ -> không cần học lại
    Base[s["key"]] := cur
    try IniWrite SampleToStr(cur), SlotIni, "Band", s["key"]
    try IniWrite FormatTime(, "dd/MM HH:mm:ss"), SlotIni, "Time", s["key"]
    s["relearnAt"] := now
    ResetSlotGuard(s, true)          ; màu mới = màu hiện tại nên ô này coi như sẵn sàng
    Relearns += 1
    DLog("TỰ HỌC LẠI MÀU: " StrUpper(s["key"]) " ô hàng " s["slot"][2] " cột " s["slot"][1] " đã rời màu hồi chiêu -> cập nhật màu chuẩn (lần " Relearns ") | cũ: " old " | mới: " SampleToStr(cur))
    return true
}

; Vừa đổi màu chuẩn của ô -> xoá mọi trạng thái bảo vệ cũ để phím hoạt động lại ngay.
; ready = true: màu mới là màu hiện tại của ô nên coi như ô đang sẵn sàng.
ResetSlotGuard(s, ready) {
    s["coolSince"] := 0
    s["diffSince"] := 0
    s["stuckWarn"] := 0
    s["blocked"] := 0
    s["fails"] := 0
    s["retries"] := 0
    s["probe"] := false
    s["force"] := false
    s["cdAt"] := 0
    s["cdSample"] := ""             ; màu hồi chiêu cũ không còn tin được -> học lại từ đầu
    s["stuckPress"] := 0
    s["overSince"] := 0
    if ready
        s["st"] := 1
}

; Lưu màu hiện tại của các ô làm màu "sẵn sàng". Trả về chuỗi kết quả.
CalibrateSlots() {
    txt := ""
    ts := FormatTime(, "dd/MM HH:mm:ss")
    for s in Skills {
        if !s.Has("slot")
            continue
        cur := SlotSample(s)
        if !IsObject(cur) {
            txt .= StrUpper(s["key"]) ": LỖI không đọc được`n"
            continue
        }
        Base[s["key"]] := cur
        IniWrite SampleToStr(cur), SlotIni, "Band", s["key"]
        IniWrite ts, SlotIni, "Time", s["key"]
        ResetSlotGuard(s, true)
        txt .= StrUpper(s["key"]) ": OK`n"
    }
    return txt
}

GameHwnd() {
    h := WinExist(GameWin)
    return h ? h : WinExist(GameWin2)
}

; ===== Cửa sổ "Màu chuẩn ô quickslot" (mở từ F5): lấy màu TỪNG PHÍM, xem trước/sau rồi mới lưu =====
ColorGui := ""
ColorRows := []
ColorAlive() {
    try {
        if IsObject(ColorGui) && ColorGui.Hwnd
            return DllCall("IsWindow", "Ptr", ColorGui.Hwnd)
    }
    return false
}
Hex(c) => Format("{:02X}{:02X}{:02X}", c[1], c[2], c[3])

; Danh sách skill có ô quickslot theo BẢNG đang nhập trong cửa sổ Cài đặt (kể cả khi chưa bấm LƯU)
ListSkills() {
    out := []
    if !IsObject(GuiCtl) || !GuiCtl.Has("rows")
        return out
    for r in GuiCtl["rows"] {
        fx := r["fixed"]
        if fx[1] != "" {
            out.Push(Map("key", fx[1], "slot", [fx[3], fx[2]]))
            continue
        }
        key := StrLower(Trim(r["e1"].Value))
        row := Trim(r["oldRow"])
        col := Trim(r["oldCol"])
        if key = "" || !IsInteger(row) || !IsInteger(col) || Integer(row) < 1 || Integer(row) > 2 || Integer(col) < 0
            continue
        out.Push(Map("key", key, "slot", [Integer(col), Integer(row)]))
    }
    return out
}

ShowColorGui(*) {
    global ColorGui, ColorRows
    if ColorAlive()
        ColorGui.Destroy()
    g := Gui("+AlwaysOnTop", "Màu chuẩn ô quickslot")
    g.SetFont("s9", "Segoe UI")
    g.AddText("w660", "Màu chuẩn = màu dải mép dưới ô khi skill SẴN SÀNG; script so màu hiện tại với màu này để biết skill hồi xong chưa.")
    g.AddText("w660", "Cách làm với từng phím: chờ skill đó SẴN SÀNG (hết nháy trắng) > bấm [Lấy] (đợi 3 giây, đừng che game) > so cột TRƯỚC (đã lưu) với cột SAU (mới lấy) > bấm [Lưu] nếu đúng.")
    g.AddButton("w100", "Đóng").OnEvent("Click", (*) => g.Destroy())
    g.AddText("xm w40 y+12", "Phím")
    g.AddText("x+4 yp w104", "TRƯỚC (đã lưu)")
    g.AddText("x+14 yp w104", "SAU (mới lấy)")
    g.AddText("x+10 yp w260", "Thông tin")
    ColorRows := []
    i := 0
    for s in ListSkills() {
        i += 1
        g.AddText("xm w40 y+8 h24 +0x200", StrUpper(s["key"]))
        sv := []
        nw := []
        loop 3
            sv.Push(g.AddText((A_Index = 1 ? "x+4" : "x+2") " yp w32 h24 +Border BackgroundC0C0C0"))
        g.AddText("x+6 yp w8 h24 +0x200", "→")
        loop 3
            nw.Push(g.AddText((A_Index = 1 ? "x+4" : "x+2") " yp w32 h24 +Border BackgroundC0C0C0"))
        info := g.AddText("x+10 yp w260 h24 +0x200", "")
        bGet := g.AddButton("x+4 yp-2 w56 h28", "Lấy")
        bSave := g.AddButton("x+4 yp w56 h28", "Lưu")
        bSave.Enabled := false
        ColorRows.Push(Map("skill", s, "saved", sv, "new", nw, "info", info, "pend", "", "bSave", bSave))
        bGet.OnEvent("Click", CaptureOne.Bind(i))
        bSave.OnEvent("Click", SaveOne.Bind(i))
    }
    g.AddText("xm w660 y+14", "Ba ô màu = ba điểm đo trên dải mép dưới icon. Hai nhóm màu phải gần giống nhau nếu cùng ở trạng thái sẵn sàng.")
    g.OnEvent("Close", (*) => g.Destroy())
    ColorGui := g
    g.Show()
    loop ColorRows.Length
        RefreshRow(A_Index)
}

SetSwatch(ctrl, c) {
    ctrl.Opt("+Background" (IsObject(c) ? Hex(c) : "C0C0C0"))
    ctrl.Redraw()
}

RefreshRow(i) {
    if !ColorAlive()
        return
    r := ColorRows[i]
    key := r["skill"]["key"]
    tm := IniRead(SlotIni, "Time", key, "")
    saved := Base.Has(key) ? Base[key] : ""
    pend := r["pend"]
    loop 3 {
        SetSwatch(r["saved"][A_Index], IsObject(saved) ? saved[A_Index] : "")
        SetSwatch(r["new"][A_Index], IsObject(pend) ? pend[A_Index] : "")
    }
    if IsObject(pend) {
        if IsObject(saved)
            r["info"].Text := "Mới lệch " Round(SampleDist(pend, saved)) " so với bản đã lưu. Đúng rồi thì bấm Lưu"
        else
            r["info"].Text := "Chưa có bản đã lưu. Đúng rồi thì bấm Lưu"
    } else if IsObject(saved) {
        r["info"].Text := "Đã lưu lúc " tm
    } else {
        r["info"].Text := "Chưa lưu màu chuẩn"
    }
    r["bSave"].Enabled := IsObject(pend)
}

; Lấy mẫu màu của MỘT phím (chưa lưu, chỉ để xem trước)
CaptureOne(i, *) {
    hwnd := GameHwnd()
    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game (" GameExe ").`nHãy mở game rồi thử lại.", "Maple Auto", "Icon!"
        return
    }
    global CapturePause
    r := ColorRows[i]
    s := r["skill"]
    CapturePause := true            ; không để auto ấn phím trong lúc lấy màu
    if Holding
        ReleaseMain()
    if IsObject(SettingsGui)
        try SettingsGui.Hide()
    ColorGui.Hide()
    SoftActivate(hwnd)
    Sleep 400
    loop 3 {
        ToolTip "Lấy màu phím " StrUpper(s["key"]) " sau " (4 - A_Index) " giây... (skill phải đang SẴN SÀNG)", 20, 20, 4
        Sleep 1000
    }
    smp := SlotSample(s)
    ToolTip , , , 4
    CapturePause := false
    if IsObject(SettingsGui)
        try SettingsGui.Show()
    if ColorAlive()
        ColorGui.Show()
    if !IsObject(smp) {
        MsgBox "Không đọc được màu ô của phím " StrUpper(s["key"]) ".", "Maple Auto", "Icon!"
        return
    }
    r["pend"] := smp
    RefreshRow(i)
}

SaveOne(i, *) {
    r := ColorRows[i]
    if !IsObject(r["pend"])
        return
    key := r["skill"]["key"]
    Base[key] := r["pend"]
    IniWrite SampleToStr(r["pend"]), SlotIni, "Band", key
    IniWrite FormatTime(, "dd/MM HH:mm:ss"), SlotIni, "Time", key
    for sk in Skills {
        if sk["key"] = key
            ResetSlotGuard(sk, true)
    }
    r["pend"] := ""
    RefreshRow(i)
    ToolTip "Đã lưu màu chuẩn phím " StrUpper(key), 20, 20, 4
    SetTimer () => ToolTip(, , , 4), -1500
}

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

; Vị trí góc trên-phải của màn hình đang chứa cửa sổ game (tooltip rộng w px đặt sát mép phải)
HudPos(hwnd, w, &x, &y) {
    x := A_ScreenWidth - w - 10
    y := 10
    try {
        WinGetPos &wx, &wy, &ww, &wh, hwnd
        mx := wx + ww // 2
        my := wy + wh // 2
        loop MonitorGetCount() {
            MonitorGet A_Index, &l, &t, &r, &b
            if mx >= l && mx < r && my >= t && my < b {
                x := r - w - 10
                y := t + 10
                break
            }
        }
    }
}

; Bảng trạng thái: phím nào sẵn sàng / đang hồi + 10 phím vừa ấn
UpdateHud() {
    if Paused() {
        if UserPaused && Enabled && ShowHud && !SettingsBusy && !GuiVisible(SettingsGui) && !GuiVisible(ColorGui) {
            h := GameHwnd()
            if h {
                HudPos(h, 330, &hx, &hy)
                ToolTip "⏸ TẠM DỪNG - ấn " ToggleKey " để tiếp tục", hx, hy, 2
                return
            }
        }
        ToolTip "", , , 2
        return
    }
    if !Enabled || !ShowHud
        return
    hwnd := WinExist(GameWin)
    if !hwnd
        hwnd := WinExist(GameWin2)
    if !hwnd
        return
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    active := IsGameActive()
    now := A_TickCount
    ready := ""
    cool := ""
    if active {
        for s in Skills {
            k := StrUpper(s["key"])
            if UseSlotCheck && s.Has("slot") {
                if s.Get("blocked", 0) > now {                 ; tạm ngừng ấn (ấn mãi không ra / ô đọc sai)
                    cool .= k "⛔ "
                } else if s["force"] {                                ; ấn mà chưa ra, đang thử lại
                    ready .= k "↻" (s["next"] > now ? "(" Ceil((s["next"] - now) / 1000) "s)" : "") " "
                } else if s["flash"] > s["press"] {            ; vừa thấy nháy trắng
                    extra := (s["wait"] > now) ? "(" Ceil((s["wait"] - now) / 1000) "s)" : ""
                    ready .= k extra " "
                } else if Base.Has(s["key"]) && s["st"] >= 0 {
                    if ColorReady(s, now)
                        ready .= k " "
                    else if s["st"] = 0 && (s["press"] = 0 || now >= s["tmr"])
                        ready .= k "(bộ đếm) "                    ; ô kẹt: vẫn ấn theo bộ đếm cooldown
                    else
                        cool .= k " "
                } else if now >= s["tmr"] {
                    ready .= k " "
                } else {
                    cool .= k "(" Ceil((s["tmr"] - now) / 1000) "s) "
                }
            } else if now >= s["next"] {
                ready .= k " "
            } else {
                cool .= k "(" Ceil((s["next"] - now) / 1000) "s) "
            }
        }
    }
    txt := "AUTO: BẬT" (active ? "" : "  - TẠM DỪNG (chưa focus game)") "`n"
    if CfgWarn != ""
        txt .= "!!! CẤU HÌNH: " CfgWarn "`n"
    if RatioWarn != ""
        txt .= "!!! TỈ LỆ: " RatioWarn "`n"
    if active {
        for bf in Buffs {
            if bf["enabled"] && bf["key"] != ""
                txt .= "BUFF " StrUpper(bf["key"]) ": " (now >= bf["next"] ? "đến lượt" : Ceil((bf["next"] - now) / 1000) "s") "`n"
        }
    }
    if active {
        txt .= "SẴN SÀNG: " (ready = "" ? "-" : RTrim(ready)) "`n"
        txt .= "HỒI CHIÊU: " (cool = "" ? "-" : RTrim(cool)) "`n"
    }
    txt .= FormatTime(, "HH:mm:ss") "  quét ô " ScanMs "ms  nháy " FlashMs "ms  F1:" F1Count "  PID " ProcessExist() "  vòng:" LoopTicks "  tự học lại:" Relearns "`n"
    if LastErr != ""
        txt .= "LỖI: " LastErr "`n"
    inst := InstanceCount()
    if inst > 1
        txt .= "!!! ĐANG CÓ " inst " BẢN SCRIPT CHẠY CÙNG LÚC`n"
    txt .= "--- 10 phím gần nhất ---`n"
    if PressLog.Length = 0 {
        txt .= "(chưa ấn phím nào)"
    } else {
        for line in PressLog
            txt .= line "`n"
    }
    HudPos(hwnd, 460, &hx, &hy)
    ToolTip RTrim(txt, "`n"), hx, hy, 2
}

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

; ===== Buff (Q): ấn phím buff; nếu hiện bảng "Buff Sequence" thì bấm "Use Unapplied Buffs" rồi chờ cast =====
; Bảng nằm GIỮA vùng game; chiều cao đổi theo số buff trong danh sách nên vị trí nút được tìm bằng màu mỗi lần.
; Loại bảng đang hiện: 1 = bảng "Buff Sequence" (Use All Buffs / Use Unapplied Buffs), 2 = bảng "Use the new EXP Buff Coupon?"
; (nhỏ hơn, nút Confirm/Cancel), 0 = không có bảng. Nhận diện bằng màu nền xanh ngọc của bảng ở các điểm hai bên.
PixelRGB(x, y) {
    c := PxGet(x, y)
    return [(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF]
}

; ===== Chụp gộp vùng bảng buff (dò bảng 8 điểm -> 1 lần chụp) =====
BdBuf := ""
BdX := 0, BdY := 0, BdW := 0, BdH := 0, BdMx := 0, BdMy := 0
BdAt := 0, BdOk := false, BdFails := 0, BdOff := false, BdLogged := 0

; Chụp hình chữ nhật (toạ độ màn hình) vào buf (BGRA, ảnh xuôi). Trả về true nếu thành công.
GrabRect(x, y, w, h, &buf) {
    ok := false
    Critical "On"
    try {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        if hdc {
            mdc := DllCall("CreateCompatibleDC", "Ptr", hdc, "Ptr")
            bmi := Buffer(40, 0)
            NumPut("UInt", 40, bmi, 0)
            NumPut("Int", w, bmi, 4)
            NumPut("Int", -h, bmi, 8)
            NumPut("UShort", 1, bmi, 12)
            NumPut("UShort", 32, bmi, 14)
            bits := 0
            hbm := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bmi, "UInt", 0, "Ptr*", &bits, "Ptr", 0, "UInt", 0, "Ptr")
            if mdc && hbm && bits {
                old := DllCall("SelectObject", "Ptr", mdc, "Ptr", hbm, "Ptr")
                if DllCall("BitBlt", "Ptr", mdc, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdc, "Int", x, "Int", y, "UInt", 0x00CC0020, "Int") {
                    if !IsObject(buf) || buf.Size < w * h * 4
                        buf := Buffer(w * h * 4)
                    DllCall("RtlMoveMemory", "Ptr", buf, "Ptr", bits, "UPtr", w * h * 4)
                    ok := true
                }
                DllCall("SelectObject", "Ptr", mdc, "Ptr", old)
            }
            if hbm
                DllCall("DeleteObject", "Ptr", hbm)
            if mdc
                DllCall("DeleteDC", "Ptr", mdc)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        }
    } finally {
        Critical "Off"
    }
    return ok
}

; mx,my = tâm vùng client game; kx,ky = hệ số phóng theo trục. Ảnh còn mới <= 40ms thì dùng lại (sau khi ấn phím luôn phải thấy ảnh mới).
BdCapture(mx, my, kx, ky) {
    global BdBuf, BdX, BdY, BdW, BdH, BdMx, BdMy, BdAt, BdOk, BdFails, BdOff, BdLogged
    if !UseBatch || BdOff
        return false
    if BdOk && A_TickCount - BdAt <= 40 && BdMx = mx && BdMy = my
        return true
    x := Floor(mx - 171 * kx) - 3
    xe := Ceil(mx + 171 * kx) + 3
    y := Floor(my - 60 * ky) - 3
    ye := Ceil(my + 25 * ky) + 3
    w := xe - x + 1
    h := ye - y + 1
    if w < 1 || h < 1 || w > 4000 || h > 1000
        return false
    t := PerfNow()
    ok := GrabRect(x, y, w, h, &BdBuf)
    d := PerfNow() - t
    if ok {
        BdX := x, BdY := y, BdW := w, BdH := h, BdMx := mx, BdMy := my
        BdAt := A_TickCount
        BdOk := true
        BdFails := 0
    } else {
        BdOk := false
        BdFails += 1
    }
    if DebugOn {
        PerfAdd("chụp_bảng_buff", d)
        if BdLogged < 2 {
            BdLogged += 1
            DLog("QS: chụp gộp vùng bảng buff " w "x" h " tại (" x "," y ") mất " Round(d, 1) "ms " (ok ? "OK" : "LỖI"))
        }
    }
    if !ok && BdFails >= 3 {
        BdOff := true
        DLog("QS: chụp gộp bảng buff lỗi 3 lần liên tiếp -> TẮT, quay về đọc từng điểm")
    }
    return ok
}

BdRGB(x, y) {
    if BdOk && x >= BdX && x < BdX + BdW && y >= BdY && y < BdY + BdH
        c := NumGet(BdBuf, ((y - BdY) * BdW + (x - BdX)) * 4, "UInt") & 0xFFFFFF
    else
        c := PxGet(x, y)
    return [(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF]
}

BuffDialogKind() {
    t0 := A_TickCount
    r := BuffDialogKindRaw()
    global LastDlgKind
    d := A_TickCount - t0
    if DebugOn
        PerfAdd("dò_bảng_buff", d)
    if r != LastDlgKind || d > 400
        DLog("DÒ BẢNG -> loại " r " (mất " d "ms)" (r != LastDlgKind ? " [đổi từ " LastDlgKind "]" : ""))
    LastDlgKind := r
    return r
}
LastDlgKind := 0

BuffDialogKindRaw() {
    hwnd := GameHwnd()
    if !hwnd
        return 0
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    mx := cx + cw / 2
    my := cy + ch / 2
    try {
        BdCapture(mx, my, kx, ky)
        ; loại 1: bảng lớn, nền xanh ngọc đậm ~ (37,135,168)
        n := 0
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            c := BdRGB(Round(mx + p[1] * kx), Round(my + p[2] * ky))
            if Abs(c[1] - 40) <= 24 && Abs(c[2] - 140) <= 34 && Abs(c[3] - 170) <= 34
                n += 1
        }
        if n >= 3
            return 1
        ; loại 2: bảng nhỏ, phần trên xanh ngọc sáng ~ (44,165,186), phần dưới xám nhạt ~ (236,236,237)
        n := 0
        for p in [[-140, -45], [140, -45], [-140, -20], [140, -20]] {
            c := BdRGB(Round(mx + p[1] * kx), Round(my + p[2] * ky))
            if Abs(c[1] - 44) <= 20 && Abs(c[2] - 165) <= 20 && Abs(c[3] - 186) <= 20
                n += 1
        }
        if n >= 3 {
            g := 0
            for p in [[-140, 25], [140, 25]] {
                c := BdRGB(Round(mx + p[1] * kx), Round(my + p[2] * ky))
                if c[1] >= 215 && c[2] >= 215 && c[3] >= 215
                    g += 1
            }
            if g >= 1
                return 2
        }
    } catch {
        return 0
    }
    return 0
}

; Có bảng nào đang hiện không (loại nào cũng tính)
BuffDialogOpen() {
    return BuffDialogKind() != 0
}

; Chiều cao bảng thay đổi theo số buff trong danh sách (bảng luôn nằm giữa) nên vị trí nút KHÔNG cố định:
; nhận diện bảng bằng màu nền xanh ngọc ở 4 điểm hai bên, rồi tìm nút olive xanh lá trong dải bên dưới tâm màn hình.
; Trả về true nếu thấy bảng + nút; x,y = tâm nút (toạ độ màn hình).
BuffFindButton(&x, &y, &hits) {
    hits := 0
    hwnd := GameHwnd()
    if !hwnd
        return false
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    mx := cx + cw / 2
    my := cy + ch / 2
    teal := 0
    try {
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            c := PxGet(Round(mx + p[1] * kx), Round(my + p[2] * ky))
            r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
            if Abs(r - 40) <= 24 && Abs(g - 140) <= 34 && Abs(b - 170) <= 34
                teal += 1
        }
    } catch {
        return false
    }
    if teal < 3
        return false
    hits := teal
    manual := IsNumber(BtnDX) && IsNumber(BtnDY)
    if !(manual && BuffAlwaysManual) {
        ; nút "Use Unapplied Buffs": viền/nền olive ~ (146,176,25); nằm lệch phải tâm khoảng 18px, rộng ~118px
        found := false
        try found := PixelSearch(&fx, &fy, Round(mx - 30 * kx), Round(my + 95 * ky), Round(mx + 70 * kx), Round(my + 240 * ky), 0x92B019, 45)
        if found {
            x := Round(fx + 40 * kx)
            y := Round(fy + 12 * ky)
            return true
        }
    }
    if manual {                         ; dùng vị trí người dùng đã chọn trong F5
        x := Round(mx + Number(BtnDX) * kx)
        y := Round(my + Number(BtnDY) * ky)
        return true
    }
    return false
}

BuffButtonPos(&x, &y) {
    hits := 0
    if BuffFindButton(&x, &y, &hits)
        return true
    hwnd := GameHwnd()
    if !hwnd
        return false
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    x := Round(cx + cw / 2 + 18 * kx)
    y := Round(cy + ch / 2 + 173 * ky)
    return true
}

; Thử nhiều cách bấm vì game có thể bỏ qua kiểu bấm này: lần 1 chuột thường, lần 2 SendInput, lần 3 gửi thẳng tin nhắn chuột vào cửa sổ game
ClickBuffButton(attempt := 1) {
    if !BuffButtonPos(&x, &y)
        return
    ClickAt(x, y, attempt)
}

; Bấm chuột tại toạ độ màn hình (x,y) theo cách số attempt (1-5)
ClickAt(x, y, attempt := 1) {
    hwnd := GameHwnd()
    cx := 0, cy := 0
    if hwnd
        WinGetClientPos &cx, &cy, , , hwnd
    if attempt = 1 {                        ; chuột thường (mouse_event qua AHK), di chuyển từng bước
        MouseMove x - 30, y - 15, 0
        Sleep 100
        MouseMove x - 8, y - 4, 2
        Sleep 100
        MouseMove x, y, 2
        Sleep 250
        Click "down"
        Sleep 200
        Click "up"
    } else if attempt = 2 {                 ; SendInput
        SendMode "Input"
        MouseMove x - 10, y - 5, 0
        Sleep 100
        MouseMove x, y, 0
        Sleep 250
        Click x ", " y ", down"
        Sleep 200
        Click x ", " y ", up"
        SendMode "Event"
    } else if attempt = 3 {                 ; gửi thẳng tin nhắn chuột vào cửa sổ game
        lp := ((y - cy) << 16) | ((x - cx) & 0xFFFF)
        PostMessage 0x0200, 0, lp, , hwnd   ; WM_MOUSEMOVE
        Sleep 100
        PostMessage 0x0201, 1, lp, , hwnd   ; WM_LBUTTONDOWN
        Sleep 200
        PostMessage 0x0202, 0, lp, , hwnd   ; WM_LBUTTONUP
    } else if attempt = 4 {                 ; mouse_event toạ độ tuyệt đối gọi thẳng API
        ; phải quy theo VÙNG ẢO của mọi màn hình + cờ VIRTUALDESK, nếu không sẽ bấm nhầm màn chính
        vs := VirtualScreen()
        ax := Round((x - vs[1]) * 65535 / Max(1, vs[3] - 1))
        ay := Round((y - vs[2]) * 65535 / Max(1, vs[4] - 1))
        DllCall("mouse_event", "UInt", 0xC001, "UInt", ax, "UInt", ay, "UInt", 0, "UPtr", 0)     ; MOVE|ABSOLUTE|VIRTUALDESK
        Sleep 250
        DllCall("mouse_event", "UInt", 0x8002, "UInt", ax, "UInt", ay, "UInt", 0, "UPtr", 0)     ; LEFTDOWN
        Sleep 200
        DllCall("mouse_event", "UInt", 0x8004, "UInt", ax, "UInt", ay, "UInt", 0, "UPtr", 0)     ; LEFTUP
    } else {                                ; ControlClick (toạ độ trong vùng game)
        try ControlClick "x" (x - cx) " y" (y - cy), hwnd, , , , "NA"
    }
}

; Thứ tự thử các cách bấm: cách đã thành công lần trước (nếu có) đứng đầu
ClickOrder() {
    order := []
    if BuffClickMode >= 1 && BuffClickMode <= 5
        order.Push(BuffClickMode)
    loop 5 {
        if A_Index != BuffClickMode
            order.Push(A_Index)
    }
    return order
}

; Ấn Enter (Use All Buffs, nút chọn sẵn) hoặc ESC (tắt bảng) khi bảng đang hiện. Trả về true nếu bảng đã tắt, -1 nếu bị ngắt.
; Nút Cancel của bảng EXP Coupon (lệch phải tâm ~44px, thấp hơn tâm ~37px theo px game)
CancelButtonPos(&x, &y) {
    hwnd := GameHwnd()
    if !hwnd
        return false
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    x := Round(cx + cw / 2 + 44 * kx)
    y := Round(cy + ch / 2 + 37 * ky)
    return true
}

; Tắt bảng đang chặn game: ESC (tối đa 3 lần); bảng EXP Coupon vẫn còn thì bấm nút Cancel (không bao giờ bấm Confirm).
; Trả về true nếu bảng đã tắt, false nếu không, -1 nếu bị ngắt.
CloseBlockingDialog() {
    kind := BuffDialogKind()
    if !kind
        return true
    r := PressDialogKey("{Esc}", "ESC")
    if r != false
        return r
    if BuffDialogKind() = 2 && CancelButtonPos(&x, &y) {
        for m in ClickOrder() {
            ClickAt(x, y, m)
            if !WaitActive(900)
                return -1
            if !BuffDialogOpen()
                return true
        }
    }
    return false
}

PressDialogKey(keyStr := "{Enter}", label := "Enter", showTip := false) {
    loop 3 {
        if showTip
            ToolTip "Ấn " label " lần " A_Index "/3...", 20, 20, 4
        Send keyStr
        if !WaitActive(500)
            return -1
        if !BuffDialogOpen() {
            if showTip
                ToolTip , , , 4
            return true
        }
    }
    if showTip
        ToolTip , , , 4
    return false
}

; Thử bấm nút lần lượt từng cách cho tới khi bảng tắt. Trả về cách thành công (0 = không cách nào được)
TryClickButton(showTip := false) {
    global BuffClickMode
    for m in ClickOrder() {
        if showTip
            ToolTip "Thử cách bấm " m "/5...", 20, 20, 4
        ClickBuffButton(m)
        if !WaitActive(1000)
            return -1
        if !BuffDialogOpen() {
            if m != BuffClickMode {
                BuffClickMode := m
                IniWrite m, IniFile, "Buff", "ClickMode"
            }
            if showTip
                ToolTip , , , 4
            return m
        }
    }
    if showTip
        ToolTip , , , 4
    return 0
}

; F7: bảng buff đang hiện thì thử bấm nút bằng các cách, báo cách nào được
TestBuffClick() {
    global CapturePause
    if !BuffDialogOpen() {
        ToolTip "F7: chưa thấy bảng buff. Hãy ấn phím buff để bảng hiện rồi ấn F7."
        SetTimer () => ToolTip(), -3500
        return
    }
    CapturePause := true
    if Holding
        ReleaseMain()
    act := Buffs[1]["action"]
    kind := BuffDialogKind()
    if act = "all" || act = "esc" || kind != 1 {
        res := HandleBuffDialog(Buffs[1], kind)
        CapturePause := false
        ToolTip "Bảng loại " kind ": " res, 20, 20, 4
        SetTimer () => ToolTip(, , , 4), -6000
        return
    }
    m := TryClickButton(true)
    CapturePause := false
    BuffButtonPos(&bx, &by)
    msg := m > 0 ? "Cách bấm " m " đã làm bảng tắt ✓ (đã nhớ cho các lần sau)" : "KHÔNG cách nào làm bảng tắt. Nút được nhắm ở (" bx "," by "). Có thể game chặn chuột giả hoặc vị trí chưa đúng."
    ToolTip msg, 20, 20, 4
    SetTimer () => ToolTip(, , , 4), -6000
}

; Chọn vị trí nút "Use Unapplied Buffs": BẤM THẲNG vào nút trong game (không cần rê chuột/chờ). Script ghi lại chỗ bạn bấm,
; rồi quét xem bảng đã tắt chưa: tắt = bấm đúng nút -> mới lưu vị trí.
CaptureBtnPos(*) {
    global CapturePause, NewBtn
    hwnd := GameHwnd()
    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game (" GameExe ").`nHãy mở game rồi thử lại.", "Maple Auto", "Icon!"
        return
    }
    if MsgBox("Làm theo thứ tự:`n1) Bấm OK, rồi trong game ấn phím buff để bảng 'Buff Sequence' hiện ra.`n2) Dùng chuột BẤM VÀO nút 'Use Unapplied Buffs' (trong vòng 40 giây).`nScript ghi lại chỗ bạn bấm và kiểm tra bảng đã tắt chưa.", "Chọn vị trí nút", "OKCancel Icon!") != "OK"
        return
    CapturePause := true
    if Holding
        ReleaseMain()
    if IsObject(SettingsGui)
        try SettingsGui.Hide()
    SoftActivate(hwnd)
    px := 0, py := 0, got := false
    t0 := A_TickCount
    while A_TickCount - t0 < 40000 {
        ToolTip "Ấn phím buff để hiện bảng, rồi bấm chuột vào nút Use Unapplied Buffs... (còn " Ceil((40000 - (A_TickCount - t0)) / 1000) "s)", 20, 20, 4
        if KeyWait("LButton", "D T0.3") {
            MouseGetPos &px, &py
            got := true
            break
        }
    }
    ToolTip , , , 4
    KeyWait "LButton"                   ; chờ nhả chuột
    result := ""
    if got {
        Sleep 900                       ; chờ bảng đóng
        closed := !BuffDialogOpen()
        WinGetClientPos &cx, &cy, &cw, &ch, hwnd
        kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
        inside := px >= cx && py >= cy && px <= cx + cw && py <= cy + ch
        if closed && inside {
            NewBtn := [Round((px - (cx + cw / 2)) / kx, 1), Round((py - (cy + ch / 2)) / ky, 1)]
            result := "OK"
        } else if !inside {
            result := "Chỗ bạn bấm nằm ngoài cửa sổ game, hãy thử lại."
        } else {
            result := "Bảng buff VẪN CÒN sau khi bấm - có thể bạn bấm trượt nút (hoặc bảng chưa hiện lúc bấm). Hãy thử lại."
        }
    } else {
        result := "Hết 40 giây mà chưa thấy bạn bấm chuột. Hãy thử lại."
    }
    CapturePause := false
    if IsObject(SettingsGui)
        try SettingsGui.Show()
    if result = "OK" {
        GuiCtl["BtnInfo"].Text := "Đã lưu tạm vị trí: " NewBtn[1] ", " NewBtn[2] "  (bảng đã tắt ✓ - bấm LƯU để áp dụng)"
        ToolTip "Bấm đúng nút, bảng đã tắt ✓", 20, 20, 4
        SetTimer () => ToolTip(, , , 4), -2500
    } else {
        MsgBox result, "Chọn vị trí nút", "Icon!"
    }
}

; F6: kiểm tra nhận diện bảng buff và đưa con trỏ tới nút (để chỉnh khi cần)
DebugBuff() {
    hwnd := GameHwnd()
    if !hwnd {
        ToolTip "Không tìm thấy cửa sổ game"
        SetTimer () => ToolTip(), -3000
        return
    }
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    kx := ScaleX(cw, ch), ky := ScaleY(cw, ch)
    mx := cx + cw / 2
    my := cy + ch / 2
    found := BuffFindButton(&bx, &by, &hits)
    txt := "Vùng game " cw "x" ch "  hệ số kx=" Round(kx, 3) " ky=" Round(ky, 3) "`nLoại bảng: " BuffDialogKind() " (1 = Buff Sequence, 2 = EXP Coupon, 0 = không có)`nNút Use Unapplied Buffs: " (found ? "thấy ở (" bx "," by ")" : "không thấy") "`n"
    txt .= "Điểm nền (cần ~ 40,140,170; đạt " hits "/4): "
    for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
        c := PxGet(Round(mx + p[1] * kx), Round(my + p[2] * ky))
        txt .= ((c >> 16) & 0xFF) "," ((c >> 8) & 0xFF) "," (c & 0xFF) "  "
    }
    ToolTip txt, cx + 10, cy + 10, 5
    SetTimer () => ToolTip(, , , 5), -10000
    if found
        MouseMove bx, by, 5
}

; Chờ ms mili-giây nhưng dừng sớm nếu tắt auto / rời game. Trả về false nếu bị ngắt.
WaitActive(ms) {
    t0 := A_TickCount
    while A_TickCount - t0 < ms {
        if !Enabled || !IsGameActive() || Paused()
            return false
        Sleep 50
    }
    return true
}

; Trong lúc xử lý buff/bảng buff, các timer quét ô tạm im để không giành CPU (log cho thấy dò bảng từng mất 4-22 giây vì bị quét ô chen vào)
BuffBusy := false
DoBuff(bf) {
    global BuffBusy, LastLoopTick
    BuffBusy := true
    try
        DoBuffInner(bf)
    finally {
        BuffBusy := false
        LastLoopTick := A_TickCount     ; buff chạy bên trong vòng chính, không tính là "vòng trễ"
    }
}

DoBuffInner(bf) {
    bf["next"] := A_TickCount + bf["every"] * 1000
    ReleaseMain()
    Sleep 80
    if !Enabled
        return
    DLog("BUFF " StrUpper(bf["key"]) " đến lượt")
    Send "{" bf["key"] "}"
    LogPress(bf["key"], "buff")
    t0 := A_TickCount
    if !WaitActive(250)
        return
    ; chờ bảng xuất hiện (kiểm tra mỗi 0,25 giây, tối đa ~2,5 giây); KHÔNG có bảng thì không ấn Enter/ESC/chuột
    kind := 0
    loop 10 {
        kind := BuffDialogKind()
        if kind
            break
        if !WaitActive(250)
            return
    }
    handled := kind != 0
    tDetect := A_TickCount - t0
    if !kind && DebugOn
        DLog("BUFF " StrUpper(bf["key"]) ": không thấy bảng - " BuffSampleDump())
    DLog("BUFF " StrUpper(bf["key"]) ": dò xong sau " tDetect "ms, loại bảng " kind)
    if kind {
        r := HandleBuffDialog(bf, kind)
        if r = -1
            return
        PressLog[1] := PressLog[1] r " [thấy bảng sau " tDetect "ms, xử lý xong sau " (A_TickCount - t0) "ms]"
    } else {
        PressLog[1] := PressLog[1] " (không hiện bảng sau " tDetect "ms)"
    }
    if !WaitActive(bf["waitMs"])    ; chờ cast buff xong
        return
    ; Kiểm tra lại một lần sau khi chờ: bảng phải đã tắt; còn thì xử lý lại một lần nữa
    kind := BuffDialogKind()
    DLog("BUFF " StrUpper(bf["key"]) ": kiểm tra lại sau chờ cast, loại bảng " kind)
    if kind {
        r := HandleBuffDialog(bf, kind)
        if r = -1
            return
        PressLog[1] := PressLog[1] " | kiểm tra lại sau " Round(bf["waitMs"] / 1000) "s: bảng còn ->" r
    } else if handled {
        PressLog[1] := PressLog[1] " | kiểm tra lại: bảng đã tắt ✓"
    }
}

; Xử lý bảng đang hiện theo Action của phím buff. Trả về chuỗi mô tả cho lịch sử, hoặc -1 nếu bị ngắt.
; Enter / bấm chuột chỉ dùng cho bảng "Buff Sequence" (loại 1) để không xác nhận nhầm bảng khác (vd dùng EXP Coupon); ESC dùng cho mọi bảng.
HandleBuffDialog(bf, kind) {
    act := bf["action"]
    if act = "esc" {
        r := CloseBlockingDialog()
        if r = -1
            return -1
        return r ? " → ESC tắt bảng ✓" : " → ấn ESC / bấm Cancel nhưng bảng vẫn còn ✗"
    }
    if kind != 1
        return " → hiện bảng khác (EXP Coupon?) nên KHÔNG ấn Enter/bấm; hãy chọn 'Tắt bảng (ESC)' cho phím này nếu muốn tắt"
    if act = "all" {
        r := PressDialogKey("{Enter}", "Enter")
        if r = -1
            return -1
        return r ? " → Enter (Use All Buffs) ✓" : " → ấn Enter nhưng bảng vẫn còn ✗"
    }
    m := TryClickButton()
    if m = -1
        return -1
    return m > 0 ? " → bấm Use Unapplied Buffs ✓ (cách " m ")" : " → đã thử 5 cách bấm nhưng bảng vẫn còn ✗ (F7 để thử tay)"
}

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


; =====================================================================
;  VÙNG NHẬN DIỆN HỌC BẰNG KÉO THẢ (mở từ F5 > "Nhận diện màn hình...")
;  Mỗi vùng lưu: vị trí (tỉ lệ theo cửa sổ) + màu mẫu của lưới điểm trong vùng. Lưu trong settings_v1.ini mục [Zones].
;  Vùng chưa học thì dùng vị trí/màu mặc định đã dựng sẵn.
; =====================================================================
ZoneDefs := [
    ["L_PLAY", "L", "Nút PLAY của launcher", "rect"],
    ["L_DOT_IDLE", "L", "Chấm GAME của launcher lúc 'Not running'", "rect"],
    ["L_DOT_RUN", "L", "Chấm GAME lúc 'Running' (cùng vị trí chấm trên)", "color"],
    ["G_CHANNEL", "G", "Màn chọn kênh (vùng nền sáng của bảng kênh)", "rect"],
    ["G_GRID", "G", "Lưới 30 kênh (CH.1 đến CH.30)", "rect"],
    ["G_LOGIN", "G", "Nút Log In (màn chọn kênh)", "rect"],
    ["G_LOADING", "G", "Màn đang tải (NOW LOADING)", "rect"]
]
Zones := Map()
ZoneTol := 30           ; dung sai mỗi kênh màu R/G/B để coi 1 điểm là "khớp"
ZoneNeed := 0.7         ; tỉ lệ điểm khớp tối thiểu để coi vùng là "khớp"
ZoneLoad()

ZoneLoad() {
    global Zones
    Zones := Map()
    for d in ZoneDefs {
        v := IniRead(IniFile, "Zones", d[1], "")
        if v = ""
            continue
        parts := StrSplit(v, "|")
        if parts.Length < 2
            continue
        h := StrSplit(parts[1], ",")
        if h.Length < 6
            continue
        pts := []
        for hx in StrSplit(parts[2], ",") {
            if hx != ""
                pts.Push(Integer("0x" hx))
        }
        Zones[d[1]] := Map("l", Number(h[1]), "t", Number(h[2]), "r", Number(h[3]), "b", Number(h[4]), "C", Integer(h[5]), "R", Integer(h[6]), "pts", pts)
    }
}

ZoneSaveIni(id) {
    z := Zones[id]
    hexs := ""
    for c in z["pts"]
        hexs .= (hexs = "" ? "" : ",") ColStr(c)
    IniWrite Format("{:.4f},{:.4f},{:.4f},{:.4f},{},{}", z["l"], z["t"], z["r"], z["b"], z["C"], z["R"]) "|" hexs, IniFile, "Zones", id
}

ZoneDefOf(id) {
    for d in ZoneDefs {
        if d[1] = id
            return d
    }
    return ""
}

ZoneHwnd(id) {
    return SubStr(id, 1, 1) = "L" ? LauncherHwnd() : GameHwnd()
}

; Tỉ lệ -> pixel màn hình. Launcher: x theo rộng, y theo cao; Game: y lưu theo bội số CHIỀU RỘNG
; (như các điểm mặc định) nên nhân thêm YFactor để đúng khi SlotScale khác uniform.
ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2) {
    z := Zones[id]
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    sy := SubStr(id, 1, 1) = "L" ? ch : cw * YFactor(cw, ch)
    x1 := Round(cx + z["l"] * cw)
    x2 := Round(cx + z["r"] * cw)
    y1 := Round(cy + z["t"] * sy)
    y2 := Round(cy + z["b"] * sy)
}

ZoneCenter(id, hwnd, &x, &y) {
    ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2)
    x := (x1 + x2) // 2
    y := (y1 + y2) // 2
}

; Lưới điểm lấy mẫu C x R nằm đều trong vùng
ZonePoints(x1, y1, x2, y2, nCols, nRows) {
    pts := []
    w := x2 - x1
    h := y2 - y1
    loop nRows {
        ri := A_Index
        loop nCols {
            ci := A_Index
            pts.Push([Round(x1 + (ci - 0.5) * w / nCols), Round(y1 + (ri - 0.5) * h / nRows)])
        }
    }
    return pts
}

; Tỉ lệ điểm khớp (0..1) của vùng với màu mẫu đã học; -1 nếu chưa học hoặc không có cửa sổ
ZoneMatch(id, hwnd) {
    if !Zones.Has(id) || !hwnd
        return -1
    z := Zones[id]
    ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2)
    n := 0
    ok := 0
    for i, p in ZonePoints(x1, y1, x2, y2, z["C"], z["R"]) {
        if i > z["pts"].Length
            break
        c := Integer(PxGet(p[1], p[2]))
        r := z["pts"][i]
        n += 1
        if Abs(((c >> 16) & 255) - ((r >> 16) & 255)) <= ZoneTol && Abs(((c >> 8) & 255) - ((r >> 8) & 255)) <= ZoneTol && Abs((c & 255) - (r & 255)) <= ZoneTol
            ok += 1
    }
    return n ? ok / n : -1
}

; Khoảng cách màu trung bình (0..255) giữa màu hiện tại tại vùng rectId và màu mẫu của ptsId
ZoneDistance(rectId, ptsId, hwnd) {
    if !Zones.Has(rectId) || !Zones.Has(ptsId) || !hwnd
        return 999
    z := Zones[rectId]
    ref := Zones[ptsId]["pts"]
    ZoneToPx(rectId, hwnd, &x1, &y1, &x2, &y2)
    sum := 0
    n := 0
    for i, p in ZonePoints(x1, y1, x2, y2, z["C"], z["R"]) {
        if i > ref.Length
            break
        c := Integer(PxGet(p[1], p[2]))
        r := ref[i]
        sum += (Abs(((c >> 16) & 255) - ((r >> 16) & 255)) + Abs(((c >> 8) & 255) - ((r >> 8) & 255)) + Abs((c & 255) - (r & 255))) / 3
        n += 1
    }
    return n ? sum / n : 999
}

; Khung đỏ mờ đánh dấu một vùng (cửa sổ xuyên chuột)
ShowBox(x1, y1, x2, y2) {
    b := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
    b.BackColor := "FF2020"
    b.Show("x" x1 " y" y1 " w" Max(2, x2 - x1) " h" Max(2, y2 - y1) " NoActivate")
    WinSetTransparent(110, b.Hwnd)
    return b
}

; Kéo chuột khoanh một vùng trên màn hình. Trả về [x1,y1,x2,y2] (toạ độ màn hình) hoặc "" nếu hủy (Esc)
DragSelect(prompt) {
    KeyWait "LButton", "T2"
    ov := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    ov.BackColor := "000000"
    vs := VirtualScreen()
    ov.Show("x" vs[1] " y" vs[2] " w" vs[3] " h" vs[4] " NoActivate")
    WinSetTransparent(70, ov.Hwnd)
    sel := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
    sel.BackColor := "FF2020"
    ToolTip prompt "`nKéo chuột trái để khoanh, thả chuột để chốt. Esc = hủy.", 20, 20, 7
    cancelled := false
    res := ""
    while !GetKeyState("LButton", "P") {
        if GetKeyState("Escape", "P") {
            cancelled := true
            break
        }
        Sleep 20
    }
    if !cancelled {
        MouseGetPos &sx, &sy
        sel.Show("x" sx " y" sy " w2 h2 NoActivate")
        WinSetTransparent(120, sel.Hwnd)
        while GetKeyState("LButton", "P") {
            MouseGetPos &mx, &my
            sel.Move(Min(sx, mx), Min(sy, my), Max(2, Abs(mx - sx)), Max(2, Abs(my - sy)))
            Sleep 15
        }
        MouseGetPos &ex, &ey
        res := [Min(sx, ex), Min(sy, ey), Max(sx, ex), Max(sy, ey)]
    }
    ToolTip(, , , 7)
    try sel.Destroy()
    try ov.Destroy()
    Sleep 250
    return cancelled ? "" : res
}

; Chạy fn trong lúc các cửa sổ cài đặt/nhận diện được ẩn (để không che vùng cần đọc), auto tạm dừng
ZoneRun(fn) {
    global CapturePause
    wasS := GuiVisible(SettingsGui)
    wasZ := GuiVisible(ZoneGui)
    CapturePause := true
    Paused()
    try {
        if wasS
            SettingsGui.Hide()
        if wasZ
            ZoneGui.Hide()
        fn()
    } finally {
        CapturePause := false
        if wasS {
            try SettingsGui.Show()
        }
        if wasZ {
            try ZoneGui.Show()
            RefreshZoneStat()
        }
    }
}

ZoneNeedWindow(id) {
    hwnd := ZoneHwnd(id)
    if !hwnd {
        MsgBox "Không thấy cửa sổ " (SubStr(id, 1, 1) = "L" ? "launcher" : "game") ".`nHãy mở nó và để đúng màn hình cần học rồi bấm lại.", "Maple Auto v1", "Icon!"
        return 0
    }
    SoftActivate(hwnd)
    Sleep 500
    return hwnd
}

ZoneLearn(id, *) {
    ZoneRun(() => ZoneLearnInner(id))
}

ZoneLearnInner(id) {
    def := ZoneDefOf(id)
    hwnd := ZoneNeedWindow(id)
    if !hwnd
        return
    isL := SubStr(id, 1, 1) = "L"
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    sy := isL ? ch : cw * YFactor(cw, ch)
    baseId := id
    if def[4] = "color" {
        baseId := "L_DOT_IDLE"
        if !Zones.Has(baseId) {
            MsgBox "Hãy khoanh 'Chấm GAME lúc Not running' trước (để có vị trí chấm), rồi mới lấy màu lúc Running.", "Maple Auto v1", "Icon!"
            return
        }
        ZoneToPx(baseId, hwnd, &x1, &y1, &x2, &y2)
        gc := Zones[baseId]["C"]
        gr := Zones[baseId]["R"]
    } else {
        sel := DragSelect("Khoanh vùng: " def[3])
        if !IsObject(sel)
            return
        x1 := sel[1], y1 := sel[2], x2 := sel[3], y2 := sel[4]
        if x1 < cx || y1 < cy || x2 > cx + cw || y2 > cy + ch {
            MsgBox "Vùng khoanh nằm ngoài cửa sổ " (isL ? "launcher" : "game") ". Hãy khoanh lại trong cửa sổ.", "Maple Auto v1", "Icon!"
            return
        }
        if x2 - x1 < 6 || y2 - y1 < 6 {
            MsgBox "Vùng quá nhỏ (cần tối thiểu 6x6 pixel).", "Maple Auto v1", "Icon!"
            return
        }
        gc := Min(5, Max(1, (x2 - x1) // 8))
        gr := Min(3, Max(1, (y2 - y1) // 8))
    }
    if id = "G_GRID" {
        ratio := (x2 - x1) / (y2 - y1)
        if ratio < 1.6 || ratio > 2.6 {
            if MsgBox("Lưới kênh bình thường có tỉ lệ rộng/cao khoảng 2 (5 cột x 6 hàng). Vùng bạn khoanh có tỉ lệ " Round(ratio, 2) ".`nCó thể đã khoanh dư (cả tiêu đề) hoặc thiếu hàng. Chỉ khoanh từ GÓC TRÊN-TRÁI ô CH.1 tới GÓC DƯỚI-PHẢI ô CH.30, không kèm tiêu đề.`n`nVẫn lưu vùng này?", "Maple Auto v1", "YesNo Icon!") != "Yes"
                return
        }
    }
    MouseMove cx + 3, cy + 3, 0         ; đưa chuột ra xa để không làm đổi màu (hover) trước khi đọc
    Sleep 250
    pts := []
    desc := ""
    for p in ZonePoints(x1, y1, x2, y2, gc, gr) {
        pc := Integer(PxGet(p[1], p[2]))
        pts.Push(pc)
        if A_Index <= 6
            desc .= ColStr(pc) " "
    }
    Sleep 700           ; đọc lần 2 để đo độ ổn định (vùng có hiệu ứng động sẽ đổi màu)
    stab := 0
    for i, p in ZonePoints(x1, y1, x2, y2, gc, gr) {
        pc2 := Integer(PxGet(p[1], p[2]))
        if ColNear(pc2, (pts[i] >> 16) & 255, (pts[i] >> 8) & 255, pts[i] & 255, ZoneTol)
            stab += 1
    }
    stabPct := Round(stab / pts.Length * 100)
    box := ShowBox(x1, y1, x2, y2)
    ans := MsgBox("Vùng: " def[3] "`nKích thước " (x2 - x1) "x" (y2 - y1) " px, " pts.Length " điểm mẫu.`nMàu mẫu đầu tiên: " desc "`nĐộ ổn định (2 lần đọc cách nhau 0,7s): " stabPct "%" (stabPct < 85 ? "`n!!! THẤP: vùng có hiệu ứng động/nền chuyển động, dễ nhận diện sai. Nên khoanh vùng khác (nền đứng yên)." : "") "`n`nLưu vùng này?", "Maple Auto v1 - Xem trước", "YesNo Icon?")
    try box.Destroy()
    if ans != "Yes"
        return
    Zones[id] := Map("l", (x1 - cx) / cw, "t", (y1 - cy) / sy, "r", (x2 - cx) / cw, "b", (y2 - cy) / sy, "C", gc, "R", gr, "pts", pts)
    ZoneSaveIni(id)
    RLog("ĐÃ HỌC vùng " id " (" def[3] "): " (x2 - x1) "x" (y2 - y1) "px, lưới " gc "x" gr ", ổn định " stabPct "%, màu đầu " desc)
}

ZoneDelete(id, *) {
    if !Zones.Has(id)
        return
    Zones.Delete(id)
    IniDelete IniFile, "Zones", id
    RLog("XÓA vùng " id)
    RefreshZoneStat()
}

; Mô tả mức khớp hiện tại của một vùng (dùng cho nút Xem / Kiểm tra)
ZoneStatusText(id, hwnd) {
    if !Zones.Has(id)
        return id ": chưa học"
    if id = "L_DOT_IDLE" || id = "L_DOT_RUN" {
        dI := ZoneDistance("L_DOT_IDLE", "L_DOT_IDLE", hwnd)
        dR := ZoneDistance("L_DOT_IDLE", "L_DOT_RUN", hwnd)
        return "Chấm GAME: cách mẫu Not running " Round(dI) ", cách mẫu Running " (dR >= 999 ? "(chưa học)" : Round(dR)) " -> " (Min(dI, dR) > 45 ? "không rõ" : dI <= dR ? "Not running" : "Running")
    }
    return id ": khớp " Round(ZoneMatch(id, hwnd) * 100) "%"
}

ZoneView(id, *) {
    ZoneRun(() => ZoneViewInner(id))
}

ZoneViewInner(id) {
    if !Zones.Has(id) {
        MsgBox "Vùng này chưa học.", "Maple Auto v1", "Icon!"
        return
    }
    hwnd := ZoneNeedWindow(id)
    if !hwnd
        return
    txt := ZoneStatusText(id, hwnd)            ; đọc trước khi vẽ khung (khung làm đổi màu)
    ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2)
    RLog("XEM " txt)
    box := ShowBox(x1, y1, x2, y2)
    ToolTip txt, x1, y2 + 12, 7
    Sleep 3000
    ToolTip(, , , 7)
    try box.Destroy()
}

ZoneCheckAll(*) {
    ZoneRun(() => ZoneCheckInner())
}

ZoneCheckInner() {
    out := ""
    lh := LauncherHwnd()
    gh := GameHwnd()
    if lh {
        SoftActivate(lh)
        Sleep 400
    }
    out .= "LAUNCHER: " (lh ? "có cửa sổ" : "không thấy cửa sổ") "`n"
    if lh {
        for id in ["L_PLAY", "L_DOT_IDLE"]
            out .= "  " ZoneStatusText(id, lh) "`n"
    }
    if gh {
        SoftActivate(gh)
        Sleep 400
    }
    out .= "GAME: " (gh ? "có cửa sổ" : "không thấy cửa sổ") "`n"
    if gh {
        for id in ["G_CHANNEL", "G_GRID", "G_LOGIN", "G_LOADING"]
            out .= "  " ZoneStatusText(id, gh) "`n"
        sc := ScreenOf(gh)
        out .= "  => nhận ra màn hình: " (sc[1] = "" ? "khác / đã vào game" : sc[1]) "`n"
    }
    RLog("KIỂM TRA NHẬN DIỆN: " StrReplace(out, "`n", " | "))
    MsgBox out, "Kiểm tra nhận diện", "Iconi"
}

RefreshZoneStat() {
    for d in ZoneDefs {
        try ZoneStat[d[1]].Text := Zones.Has(d[1]) ? "đã học" : "chưa học (mặc định)"
    }
}

ShowZoneGui() {
    global ZoneGui, ZoneStat
    if IsObject(ZoneGui) {
        try {
            ZoneGui.Show()
            RefreshZoneStat()
            return
        }
    }
    g := Gui("+AlwaysOnTop", "Nhận diện màn hình đăng nhập lại - khoanh vùng bằng kéo thả")
    g.SetFont("s9", "Segoe UI")
    g.AddText("w700", "Mở đúng màn hình cần học (launcher hoặc game), bấm 'Khoanh vùng', kéo chuột quanh vùng rồi thả, kiểm tra khung đỏ và bấm Yes để lưu.`nThứ tự gợi ý:`n  1) Tắt game, mở launcher: khoanh nút PLAY và chấm GAME (đang Not running).`n  2) Bấm PLAY (bằng tay), khi launcher báo Running: bấm 'Lấy màu' ở dòng chấm GAME Running.`n  3) Khi game lên màn hình chọn kênh: khoanh màn chọn kênh, lưới kênh, nút Log In.`n  4) Bấm Log In (bằng tay), khi hiện NOW LOADING: khoanh màn đang tải.`nVùng chưa học sẽ dùng giá trị mặc định. Trong lúc học, auto tạm dừng.")
    ZoneStat := Map()
    for d in ZoneDefs {
        id := d[1]
        g.AddText("xm y+12 w330", d[3])
        ZoneStat[id] := g.AddText("x+4 yp w130", "")
        g.AddButton("x+4 yp-4 w100", d[4] = "color" ? "Lấy màu" : "Khoanh vùng").OnEvent("Click", ZoneLearn.Bind(id))
        g.AddButton("x+4 w50", "Xem").OnEvent("Click", ZoneView.Bind(id))
        g.AddButton("x+4 w50", "Xóa").OnEvent("Click", ZoneDelete.Bind(id))
    }
    g.AddButton("xm y+18 w200", "Kiểm tra nhận diện").OnEvent("Click", ZoneCheckAll)
    g.AddButton("x+8 w260", "Chạy thử quy trình đăng nhập lại").OnEvent("Click", TestRelogin)
    g.AddButton("x+8 w100", "Đóng").OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    ZoneGui := g
    RefreshZoneStat()
    MakeScrollable(g)
}

; =====================================================================
;  TỰ ĐĂNG NHẬP LẠI KHI VĂNG GAME
;  Phát hiện mất tiến trình game (sau khi đã thấy nó chạy) -> chạy máy trạng thái:
;    launcher chưa có  -> mở exe launcher (đã có thì KHÔNG mở lại)
;    launcher sẵn sàng -> bấm nút PLAY
;    game đã mở        -> màn hình chọn kênh: bấm kênh rồi bấm Log In
;    màn hình tải      -> chờ
;    hết tải           -> vào game, auto chạy tiếp
;  Mọi bước/mốc thời gian/màu đọc được ghi vào debug_v1.log (dòng có [ĐN]) để phân tích chỗ nghẽn.
; =====================================================================
RLog(m) {
    DLog("[ĐN] " m)
}

ColStr(c) => Format("{:06X}", Integer(c) & 0xFFFFFF)

ColNear(c, r, g, b, tol := 28) {
    c := Integer(c)
    return Abs(((c >> 16) & 255) - r) <= tol && Abs(((c >> 8) & 255) - g) <= tol && Abs((c & 255) - b) <= tol
}

; Điểm trong vùng game theo tỉ lệ so với CHIỀU RỘNG vùng game (x và y đều nhân với chiều rộng)
ClientW(hwnd) {
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    return cw
}
ClientH(hwnd) {
    WinGetClientPos , , , &ch, hwnd
    return ch
}

GamePt(hwnd, rx, ry, &x, &y) {
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    x := Round(cx + rx * cw)
    y := Round(cy + YRatio(ry, cw, ch))
}

GameCol(hwnd, rx, ry) {
    GamePt(hwnd, rx, ry, &x, &y)
    return PxGet(x, y)
}

; Nhận biết màn hình hiện tại của game: "channel" (chọn kênh + nhân vật), "loading" (NOW LOADING) hoặc ""
; Trả về mảng [tên màn hình, mô tả các màu đã đọc] để ghi log
ScreenOf(hwnd) {
    info := ""
    isChan := false
    if Zones.Has("G_CHANNEL") {
        m1 := ZoneMatch("G_CHANNEL", hwnd)
        info := "G_CHANNEL=" Round(m1 * 100) "%"
        isChan := m1 >= ZoneNeed
    }
    if !isChan {            ; vùng đã học không khớp (hoặc chưa học): thử thêm kiểm tra mặc định
        c1 := GameCol(hwnd, LoginRX, LoginRY)           ; nút Log In (xanh ngọc)
        c2 := GameCol(hwnd, PanelRX, PanelRY)           ; nền bảng kênh (rất sáng)
        info .= " [mặc định: LogIn=" ColStr(c1) " Panel=" ColStr(c2) "]"
        isChan := ColNear(c2, 227, 242, 247, 14) && ColNear(c1, 67, 194, 224, 40)
    }
    if isChan
        return ["channel", info]
    isLoad := false
    if Zones.Has("G_LOADING") {
        m2 := ZoneMatch("G_LOADING", hwnd)
        info .= " G_LOADING=" Round(m2 * 100) "%"
        isLoad := m2 >= ZoneNeed
    }
    if !isLoad {
        c3 := GameCol(hwnd, 0.05, 0.05)                 ; nền xanh của màn hình tải
        c4 := GameCol(hwnd, 0.154, 0.3455)              ; dải xanh chanh của màn hình tải
        info .= " [mặc định: Load1=" ColStr(c3) " Load2=" ColStr(c4) "]"
        isLoad := ColNear(c3, 74, 204, 223, 14) && ColNear(c4, 199, 226, 9, 26)
    }
    if isLoad
        return ["loading", info]
    return ["", info]
}

; Tìm cửa sổ launcher, KỂ CẢ khi đang thu nhỏ hoặc bị ẩn (launcher hay ẩn xuống khay khi game chạy).
; Trả về hwnd (0 = không có cửa sổ nào hợp lệ).
LauncherHwnd() {
    old := A_DetectHiddenWindows
    DetectHiddenWindows True
    found := 0
    try {
        for h in WinGetList("ahk_exe " ReLauncherExe) {
            try {
                mm := WinGetMinMax(h)
                WinGetPos , , &w, &hh, h
                if mm = -1 || (w > 300 && hh > 200) {
                    found := h
                    break
                }
            }
        }
    }
    DetectHiddenWindows old
    return found
}

; Mô tả mọi cửa sổ của launcher (để ghi log chẩn đoán)
LauncherDump() {
    old := A_DetectHiddenWindows
    DetectHiddenWindows True
    out := "tiến trình " ReLauncherExe "=" (ProcessExist(ReLauncherExe) ? "CÓ" : "không") "; cửa sổ: "
    n := 0
    try {
        for h in WinGetList("ahk_exe " ReLauncherExe) {
            n += 1
            try {
                WinGetPos &x, &y, &w, &hh, h
                out .= "[" Format("0x{:X}", h) " '" WinGetTitle(h) "' " WinGetClass(h) " " w "x" hh " tại " x "," y " hiện=" (DllCall("IsWindowVisible", "Ptr", h) ? 1 : 0) " minmax=" WinGetMinMax(h) "] "
            }
        }
    }
    DetectHiddenWindows old
    return out (n = 0 ? "(không có)" : "")
}

; Đọc chấm trạng thái "GAME" của launcher (nằm dưới nút PLAY, bên phải): xanh lá = Running, xám xanh nhạt = Not running.
; Trả về [trạng thái, màu, toạ độ]; trạng thái: "running" | "idle" | "?"
LauncherDot(lh) {
    if Zones.Has("L_DOT_IDLE") && Zones.Has("L_DOT_RUN") {
        dI := ZoneDistance("L_DOT_IDLE", "L_DOT_IDLE", lh)
        dR := ZoneDistance("L_DOT_IDLE", "L_DOT_RUN", lh)
        st := "?"
        if Min(dI, dR) <= 45
            st := dI <= dR ? "idle" : "running"
        return [st, "đã học: cách Not running " Round(dI) ", cách Running " Round(dR), "vùng đã học"]
    }
    WinGetClientPos &cx, &cy, &cw, &ch, lh
    x := Round(cx + (PlayRX + DotDX) * cw)
    y := Round(cy + PlayRY * ch + DotDY * cw)
    c := Integer(PxGet(x, y))
    r := (c >> 16) & 255, g := (c >> 8) & 255, b := c & 255
    st := "?"
    if g > r + 40 && g > b + 20
        st := "running"
    else if b > r + 25 && b > 150
        st := "idle"
    return [st, ColStr(c), x "," y]
}

ClickPlay(lh, n) {
    FocusWin(lh, "launcher")
    WinGetClientPos &cx, &cy, &cw, &ch, lh
    if Zones.Has("L_PLAY") {
        ZoneCenter("L_PLAY", lh, &x, &y)
        m := ZoneMatch("L_PLAY", lh)
        RLog("PLAY lần " n ": vùng đã học, tâm (" x "," y ") khớp " Round(m * 100) "% (cần >= 50%)")
        if m < 0.5 {
            RLog("PLAY: màu nút không khớp mẫu đã học (launcher đang bận/khác trạng thái?) - chưa bấm")
            return false
        }
    } else {
        x := Round(cx + PlayRX * cw)
        y := Round(cy + PlayRY * ch)
        ; Chữ "PLAY RANMELLE" màu nâu nằm ngay giữa nút nên KHÔNG đọc màu ở tâm; đọc 4 điểm cách tâm 2 bên (vẫn nằm trong nút cam)
        cc := PxGet(x, y)
        n1 := 0
        desc := ""
        for off in [-0.16, -0.10, 0.10, 0.16] {
            c := PxGet(Round(x + off * cw), y)
            desc .= ColStr(c) " "
            if ColNear(c, 247, 190, 93, 40)
                n1 += 1
        }
        ok := n1 >= 2
        RLog("PLAY lần " n ": launcher " cw "x" ch " tại (" cx "," cy "); tâm nút (" x "," y ") màu tâm " ColStr(cc) "; 4 điểm 2 bên " desc "-> " n1 "/4 là cam" (ok ? " OK" : " KHÔNG phải nút cam sẵn sàng"))
        if !ok {
            RLog("PLAY: nút chưa cam (launcher đang bận/cập nhật/đã bấm?) - chưa bấm")
            return false
        }
    }
    mode := [1, 4, 2][Mod(n - 1, 3) + 1]
    FocusWin(lh, "launcher")
    ClickAt(x, y, mode)
    RLog("PLAY: đã bấm (cách " mode ")")
    return true
}

; Ô kênh đang được chọn có nền xanh ngọc (như CH.3 khi chọn), ô thường nền trắng xám
ChannelSelected(x, y, cellW, cellH) {
    n := 0
    for p in [[0.30, -0.22], [0.36, 0.0], [-0.05, 0.28]] {      ; 3 điểm trong ô, né chữ "CH.n" ở bên trái
        c := PxGet(Round(x + p[1] * cellW), Round(y + p[2] * cellH))
        r := (c >> 16) & 255, g := (c >> 8) & 255, b := c & 255
        if b > r + 60 && g > r + 40 && r < 150
            n += 1
    }
    return n >= 2
}

; Trả về true nếu đã chọn đúng kênh và bấm Log In; false = chưa chọn được kênh (không bấm Log In)
ChooseChannelAndLogin(gh, n) {
    FocusGameWin(gh)
    col := Mod(ReChannel - 1, 5)
    row := (ReChannel - 1) // 5
    useGrid := false
    if Zones.Has("G_GRID") {
        ZoneToPx("G_GRID", gh, &gx1, &gy1, &gx2, &gy2)
        ratio := (gx2 - gx1) / Max(1, gy2 - gy1)
        if ratio >= 1.6 && ratio <= 2.6
            useGrid := true
        else
            RLog("CẢNH BÁO: vùng lưới kênh G_GRID tỉ lệ rộng/cao " Round(ratio, 2) " (bình thường ~2.2) -> có vẻ khoanh dư tiêu đề 'Special' nên TẠM DÙNG vị trí mặc định. Hãy khoanh lại G_GRID: từ góc trên-trái ô CH.1 tới góc dưới-phải ô CH.30.")
    }
    if useGrid {
        cellW := (gx2 - gx1) / 5
        cellH := (gy2 - gy1) / 6
        x := Round(gx1 + (col + 0.5) * cellW)
        y := Round(gy1 + (row + 0.5) * cellH)
        RLog("KÊNH: lưới học được (" gx1 "," gy1 ")-(" gx2 "," gy2 ") ô " Round(cellW) "x" Round(cellH))
    } else {
        GamePt(gh, Ch1RX + col * ChDX, Ch1RY + row * ChDY, &x, &y)
        cellW := Round(ChDX * ClientW(gh))
        cellH := Round(ChDY * ClientW(gh) * YFactor(ClientW(gh), ClientH(gh)))
    }
    sel := false
    loop 3 {
        MouseMove x + Round(cellW * 0.6), y + Round(cellH * 0.9), 0     ; bỏ hover để đọc màu đúng
        Sleep 150
        if ChannelSelected(x, y, cellW, cellH) {
            RLog("KÊNH: CH." ReChannel " đã sáng xanh sẵn -> KHÔNG bấm chọn lại")
            sel := true
            break
        }
        mode := [1, 4, 2][A_Index]
        FocusGameWin(gh)
        ClickAt(x, y, mode)
        Sleep 700
        MouseMove x + Round(cellW * 0.6), y + Round(cellH * 0.9), 0     ; bỏ hover để đọc màu đúng
        Sleep 150
        sel := ChannelSelected(x, y, cellW, cellH)
        RLog("KÊNH: bấm CH." ReChannel " tại (" x "," y ") cách " mode " -> " (sel ? "ĐÃ CHỌN (ô xanh)" : "CHƯA thấy ô xanh") "; màu mẫu " ColStr(PxGet(Round(x + 0.3 * cellW), Round(y - 0.22 * cellH))))
        if sel
            break
    }
    if !sel {
        RLog("KÊNH: không chọn được CH." ReChannel " -> KHÔNG bấm Log In (tránh vào nhầm kênh)")
        return false
    }
    if Zones.Has("G_LOGIN")
        ZoneCenter("G_LOGIN", gh, &x, &y)
    else
        GamePt(gh, LoginRX, LoginRY, &x, &y)
    FocusGameWin(gh)
    ClickAt(x, y, [1, 4, 2, 3][Min(n, 4)])
    RLog("LOG IN: bấm tại (" x "," y ") lần " n)
    return true
}

ReloginWatch() {
    global SeenGame, LostSince
    if !ReloginOn || !Enabled || Paused()
        return
    if ProcessExist(GameExe) {
        SeenGame := true
        LostSince := 0
        return
    }
    if !SeenGame
        return
    if !LostSince {
        LostSince := A_TickCount
        RLog("MẤT tiến trình game " GameExe " - chờ " ReLostSec "s để chắc là văng")
        return
    }
    if A_TickCount - LostSince >= ReLostSec * 1000 {
        LostSince := 0
        DoRelogin(false)
    }
}

F9:: DoRelogin(true)

; Nút "Chạy thử": chạy cả quy trình từ nhận diện launcher cho tới khi vào game (ẩn cửa sổ cài đặt để không che)
TestRelogin(*) {
    note := ProcessExist(GameExe) ? "`n`nLƯU Ý: game đang chạy nên quy trình sẽ coi là đã vào game gần như ngay. Muốn thử đủ từ đầu: tắt game (để nguyên launcher) rồi bấm lại." : ""
    if MsgBox("Chạy thử quy trình đăng nhập lại:`n  nhận diện launcher -> bấm PLAY -> chờ game -> chọn kênh -> Log In -> chờ vào game.`n`nCửa sổ cài đặt sẽ ẩn trong lúc chạy; xong thì mở lại bằng F5. Có thể ấn " ToggleKey " để hủy giữa chừng. Log: debug_v1.log." note "`n`nChạy thử bây giờ?", "Maple Auto v1", "YesNo Icon?") != "Yes"
        return
    try SettingsGui.Hide()
    try ZoneGui.Hide()
    SetTimer () => DoRelogin(true), -400
}

DoRelogin(test := false, startLevel := 0) {
    global Relogging, StartTick, Enabled, RelogCancel, UserPaused
    if Relogging
        return
    RelogCancel := false
    if test && UserPaused {             ; chạy thử thì bỏ trạng thái tạm dừng cũ, nếu không sẽ bị hủy ngay lập tức
        RLog("Bỏ trạng thái 'tạm dừng' còn sót từ trước để chạy thử")
        UserPaused := false
    }
    if !test && UserPaused {
        RLog("Không chạy đăng nhập lại: auto đang ở trạng thái tạm dừng (ấn " ToggleKey " để tiếp tục)")
        return
    }
    Relogging := true
    Paused()
    if Holding
        ReleaseMain()
    tAll := A_TickCount
    RLog("=== BẮT ĐẦU ĐĂNG NHẬP LẠI" (test ? " (chạy thử bằng F9)" : "") " ===")
    result := false
    try {
        loop ReMaxTries {
            r := ReloginAttempt(A_Index, test, startLevel)
            if r = -1 {
                RLog("Bị dừng bởi người dùng")
                result := -1
                break
            }
            if r {
                result := true
                break
            }
            RLog("Lần thử " A_Index " thất bại")
        }
    } catch as e {
        RLog("LỖI quy trình: " e.Message " @dòng " e.Line)
    }
    Relogging := false
    ToolTip(, , , 6)
    secs := Round((A_TickCount - tAll) / 1000, 1)
    if result = true {
        RLog("=== ĐĂNG NHẬP LẠI XONG sau " secs "s ===")
        try {
            h := GameHwnd()
            if h && !IsGameActive() {
                RLog("Đưa game lên trước để auto gửi phím (không chặn)")
                SoftActivate(h)
            }
        }
        if Enabled {
            ResetTimers()
            StartTick := A_TickCount
        }
        ToolTip "ĐÃ ĐĂNG NHẬP LẠI (" secs "s) - auto chạy tiếp"
        SetTimer () => ToolTip(), -3000
    } else if result = false {
        RLog("=== THẤT BẠI sau " secs "s - dừng auto ===")
        if !test
            Enabled := false
        ToolTip "KHÔNG ĐĂNG NHẬP LẠI ĐƯỢC - đã dừng auto`nXem debug_v1.log (dòng [ĐN])"
        SetTimer () => ToolTip(), -8000
    }
}

; Đặt vị trí game (chỉ di chuyển cửa sổ, không đưa lên trên cùng)
FocusGameWin(gh) {
    return FocusWin(gh, "game")
}

; CHỈ di chuyển cửa sổ tới vị trí cố định (một lần cho mỗi cửa sổ). KHÔNG kích hoạt/khôi phục/WinShow/"luôn trên cùng"
; vì các thao tác đó làm game/launcher chạy sai. Chỉ ghi log nếu cửa sổ không nằm trên cùng.
FocusWin(hwnd, label) {
    static placed := Map(), lastWarn := 0
    if !placed.Has(label) || placed[label] != hwnd {
        placed[label] := hwnd
        PlaceWin(hwnd, label)
    }
    ok := WinActive(hwnd) ? true : false
    if !ok && A_TickCount - lastWarn > 5000 {
        lastWarn := A_TickCount
        RLog("Lưu ý: " label " không phải cửa sổ trên cùng (không tự kích hoạt)")
    }
    return ok
}

; Đặt vị trí cố định: game = giữa vùng làm việc của màn hình đang chứa nó, launcher = góc trên-trái màn hình chính.
; Chỉ di chuyển khi lệch > 3px (không đổi kích thước)
PlaceWin(hwnd, label) {
    static lastLog := 0
    if !PlaceWindows
        return
    try {
        if WinGetMinMax(hwnd) != 0
            return
        WinGetPos &x, &y, &w, &h, hwnd
        mon := GameMonitor(hwnd)
        if !mon
            mon := MonitorGetPrimary()
        if label = "launcher" {
            WinGetClientPos &cx, &cy, , , hwnd
            ; góc trên-trái của vùng làm việc màn hình CHÍNH (0,0 chỉ đúng khi màn chính ở gốc toạ độ)
            if MonitorGetWorkArea(MonitorGetPrimary(), &wl, &wt, , )
                tx := wl + (x - cx), ty := wt + (y - cy)
            else
                tx := x - cx, ty := y - cy
            where := "góc trên-trái màn hình chính"
        } else if mon && MonitorGetWorkArea(mon, &wl, &wt, &wr, &wb) {
            ; đặt giữa vùng làm việc của MÀN HÌNH CHỨA cửa sổ game (không phải luôn màn chính)
            tx := wl + Max(0, (wr - wl - w) // 2), ty := wt + Max(0, (wb - wt - h) // 2)
            where := "màn " mon "/" MonitorGetCount() " vùng làm việc " wl "," wt " - " wr "," wb
        } else {
            tx := Max(0, (A_ScreenWidth - w) // 2), ty := Max(0, (A_ScreenHeight - h) // 2)
            where := "màn hình chính " A_ScreenWidth "x" A_ScreenHeight
        }
        if Abs(x - tx) > 3 || Abs(y - ty) > 3 {
            WinMove tx, ty, , , hwnd
            Sleep 200
            if A_TickCount - lastLog > 3000 {
                lastLog := A_TickCount
                RLog("Đặt vị trí " label ": (" x "," y ") -> (" tx "," ty "), cỡ " w "x" h ", " where)
            }
        }
    } catch as e {
        RLog("Không đặt được vị trí " label ": " e.Message)
    }
}

; Chụp nhanh tình trạng để biết đang kẹt ở đâu (ghi vào log)
StuckDiag(gh, lh) {
    out := "CHẨN ĐOÁN: tiến trình game=" (ProcessExist(GameExe) ? "CÓ" : "không") ", cửa sổ game=" (gh ? "có" : "không") ", tiến trình launcher=" (ProcessExist(ReLauncherExe) ? "CÓ" : "không") ", cửa sổ launcher=" (lh ? "có" : "không")
    if lh {
        dot := LauncherDot(lh)
        out .= " | launcher: chấm GAME=" dot[1] " " dot[2]
        for id in ["L_PLAY"]
            out .= " | " ZoneStatusText(id, lh)
    }
    if gh {
        sc := ScreenOf(gh)
        out .= " | game: nhận ra=" (sc[1] = "" ? "khác" : sc[1]) " " sc[2]
        for id in ["G_CHANNEL", "G_GRID", "G_LOGIN", "G_LOADING"]
            out .= " | " ZoneStatusText(id, gh)
    }
    return out
}

; Ấn ESC (tắt bảng thông báo/hộp thoại có thể đang che) rồi quét lại màn hình. Trả về kết quả ScreenOf
EscAndRescan(gh) {
    SoftActivate(gh)                ; phím chỉ vào game khi game đang ở trên cùng (không chặn)
    Sleep 500
    Send "{Esc}"
    Sleep 1500
    sc := ScreenOf(gh)
    RLog("Sau ESC: nhận ra màn hình = " (sc[1] = "" ? "khác" : sc[1]) "  " sc[2])
    return sc
}

; Đóng game (và launcher nếu cần) để đăng nhập lại từ đầu
KillForRestart(withLauncher) {
    if ProcessExist(GameExe) {
        RLog("Đóng game " GameExe)
        try ProcessClose GameExe
        ProcessWaitClose GameExe, 10
        if ProcessExist(GameExe)
            RLog("CẢNH BÁO: game vẫn chưa đóng sau 10s")
    }
    if withLauncher && ProcessExist(ReLauncherExe) {
        RLog("Đóng launcher " ReLauncherExe)
        try ProcessClose ReLauncherExe
        ProcessWaitClose ReLauncherExe, 10
    }
    Sleep 1500
}

; Một lần thử. Trả về true = vào game, false = hết thời gian, -1 = người dùng dừng
ReloginAttempt(num, test, startLevel := 0) {
    t0 := A_TickCount
    RLog("--- lần thử " num "/" ReMaxTries)
    state := ""
    stateAt := t0
    launcherRun := 0, launcherSeen := 0, lastAct := 0, lastDot := "", dotSince := 0
    playClicks := 0, lastPlay := 0
    loginClicks := 0, lastLogin := 0
    stableSince := 0
    lastDump := 0
    seenLoading := false
    firstLoop := true, gameAtStart := false
    chanFails := 0, stuckLevel := startLevel, stuck := "", escFor := -1
    unkLimit := startLevel ? 15000 : 60000
    while A_TickCount - t0 < ReAttemptMs {
        it0 := A_TickCount
        if RelogCancel || (!test && !Enabled) || UserPaused
            return -1
        gh := GameHwnd()
        gp := ProcessExist(GameExe)
        lh := LauncherHwnd()
        st := ""
        info := ""
        if firstLoop {
            gameAtStart := gh ? true : false
            firstLoop := false
        }
        if !gp && !gh {
            stableSince := 0
            lp := ProcessExist(ReLauncherExe)
            if !lh {
                if lp {
                    st := "launcher đang chạy nhưng chưa thấy cửa sổ (ẩn xuống khay?)"
                    if !launcherRun || A_TickCount - launcherRun > 60000 {
                        launcherRun := A_TickCount
                        RLog("Launcher ĐANG CHẠY (tiến trình có) nhưng không thấy cửa sổ -> gọi cửa sổ lên bằng cách chạy lại exe (launcher một bản sẽ tự hiện): " LauncherDump())
                        try Run('"' ReLauncher '"', RegExReplace(ReLauncher, "\\[^\\]+$"))
                        catch as e
                            RLog("KHÔNG gọi được cửa sổ launcher: " e.Message)
                    }
                } else {
                    st := "chờ launcher mở"
                    if !launcherRun || A_TickCount - launcherRun > 60000 {
                        launcherRun := A_TickCount
                        RLog("Launcher chưa chạy -> mở " ReLauncher ". " LauncherDump())
                        try Run('"' ReLauncher '"', RegExReplace(ReLauncher, "\\[^\\]+$"))
                        catch as e
                            RLog("KHÔNG mở được launcher: " e.Message)
                    }
                }
            } else {
                st := "launcher sẵn sàng (chờ bấm PLAY)"
                if !launcherSeen {
                    launcherSeen := A_TickCount
                    RLog("Thấy launcher sau " (A_TickCount - t0) "ms - " (launcherRun ? "phải mở/gọi exe" : "launcher vẫn đang chạy nên KHÔNG mở lại exe") ". " LauncherDump())
                    if !DllCall("IsWindowVisible", "Ptr", lh)
                        RLog("Lưu ý: launcher đang bị ẩn (không WinShow)")
                }
                FocusWin(lh, "launcher")        ; đưa launcher lên trên cùng (khôi phục nếu thu nhỏ) trước khi đọc màu
                dot := LauncherDot(lh)
                if dot[1] != lastDot {
                    RLog("Launcher: chấm GAME = " dot[1] (dot[1] = "running" ? " (Running: MapleStory đang chạy theo launcher)" : dot[1] = "idle" ? " (Not running: sẵn sàng bấm PLAY)" : " (không rõ)") "  màu " dot[2] " tại (" dot[3] ")")
                    lastDot := dot[1]
                    dotSince := A_TickCount
                }
                waited := A_TickCount - launcherSeen
                canClick := false
                why := ""
                if dot[1] = "idle" {
                    canClick := true
                } else if dot[1] = "?" && waited >= 8000 {
                    canClick := true
                    why := " (không đọc được chấm GAME sau 8s - bấm thử)"
                } else if dot[1] = "running" && waited >= 20000 {
                    canClick := true
                    why := " (launcher vẫn báo Running dù game đã mất - có thể trạng thái cũ, bấm thử)"
                }
                if canClick && waited >= 2500 && A_TickCount - lastPlay >= 12000 && playClicks < 6 {
                    playClicks += 1
                    lastPlay := A_TickCount
                    if why != ""
                        RLog("PLAY:" why)
                    ClickPlay(lh, playClicks)
                } else if dot[1] = "running" && !canClick
                    st := "launcher báo GAME Running nhưng game đã mất - chờ launcher cập nhật"
            }
        } else if !gh {
            st := "game đang khởi động (có tiến trình, chưa có cửa sổ)"
            stableSince := 0
        } else {
            FocusGameWin(gh)            ; đưa game lên trên cùng TRƯỚC khi đọc màu/bấm (đọc điểm ảnh lấy màu của cửa sổ đang nằm trên)
            sc := ScreenOf(gh)
            info := sc[2]
            if sc[1] = "channel" {
                st := "màn hình chọn kênh"
                stableSince := 0
                if A_TickCount - lastLogin >= 15000 && loginClicks < 4 {
                    lastLogin := A_TickCount
                    if ChooseChannelAndLogin(gh, loginClicks + 1) {
                        loginClicks += 1
                        chanFails := 0
                    } else {
                        chanFails += 1
                        lastLogin := A_TickCount - 11000     ; chưa chọn được kênh: thử lại sau ~4s
                    }
                }
            } else if sc[1] = "loading" {
                st := "đang tải (NOW LOADING)"
                seenLoading := true
                stableSince := 0
            } else {
                st := "màn hình khác / đã vào game?"
                if !stableSince
                    stableSince := A_TickCount
                if A_TickCount - stableSince >= unkLimit && loginClicks = 0 {
                    stuck := Round(unkLimit / 1000) "s ở màn hình KHÔNG nhận ra (chưa thấy màn chọn kênh/tải)"
                    stableSince := A_TickCount
                }
                if A_TickCount - stableSince >= 4000 && (loginClicks > 0 || (test && gameAtStart)) {
                    RLog("Ổn định 4s ngoài màn hình kênh/tải (đã bấm Log In " loginClicks " lần, thấy loading=" (seenLoading ? "có" : "không") ") -> coi là đã vào game")
                    return true
                }
            }
        }
        ; ===== Phát hiện KẸT và xử lý theo bậc thang =====
        if stuck = "" && st = state {
            age := A_TickCount - stateAt
            if InStr(st, "chờ launcher mở") || InStr(st, "launcher đang chạy nhưng") {
                if age > 90000
                    stuck := "90s không thấy cửa sổ launcher"
            } else if InStr(st, "launcher") {
                if playClicks >= 6 && A_TickCount - lastPlay >= 15000
                    stuck := "đã bấm PLAY " playClicks " lần mà game không lên"
                else if age > 150000
                    stuck := "150s ở launcher mà game không lên"
            } else if InStr(st, "game đang khởi động") {
                if age > 90000
                    stuck := "90s game có tiến trình nhưng chưa có cửa sổ"
            } else if InStr(st, "chọn kênh") {
                if chanFails >= 5
                    stuck := "không chọn được kênh sau " chanFails " lần"
                else if loginClicks >= 4 && A_TickCount - lastLogin >= 20000
                    stuck := "đã bấm Log In " loginClicks " lần mà vẫn ở màn chọn kênh"
                else if age > 90000
                    stuck := "90s vẫn ở màn chọn kênh"
            } else if InStr(st, "đang tải") {
                if age > 150000
                    stuck := "150s vẫn ở màn đang tải"
            }
        }
        if stuck != "" && gh && escFor != stuckLevel {
            ; TRƯỚC mỗi bậc xử lý: ấn ESC (có thể đang có bảng thông báo che) rồi quét lại; nếu đã nhận ra màn hình thì chạy tiếp, chưa thì mới xử lý
            escFor := stuckLevel
            RLog("!!! KẸT: " stuck " -> thử ấn ESC để tắt bảng thông báo (nếu có) trước khi xử lý")
            sc := EscAndRescan(gh)
            if sc[1] = "" {
                sc := EscAndRescan(gh)          ; lần 2: có thể lần 1 chỉ mở menu của game
            }
            if sc[1] = "channel" || sc[1] = "loading" {
                RLog("ESC có tác dụng: đã thấy màn " (sc[1] = "channel" ? "chọn kênh" : "đang tải") " -> tiếp tục quy trình, chưa cần reset")
                stuck := ""
                loginClicks := 0, lastLogin := 0, chanFails := 0, stableSince := 0
                state := ""
                stateAt := A_TickCount
                Sleep 300
                continue
            }
            RLog("ESC không giúp được (vẫn không nhận ra màn hình) -> xử lý theo bậc")
        }
        if stuck != "" {
            stuckLevel += 1
            RLog("!!! KẸT: " stuck " (bậc xử lý " stuckLevel "/4)")
            RLog(StuckDiag(gh, lh))
            stuck := ""
            if stuckLevel = 1 {
                RLog("Bậc 1: kiểm tra lại màn hình rồi làm lại các bước từ trạng thái hiện tại (KHÔNG đóng game). Nếu đang ở màn chọn kênh/đăng nhập thì chọn kênh + Log In lại để vào game")
                playClicks := 0, lastPlay := 0, loginClicks := 0, lastLogin := 0, chanFails := 0
                launcherSeen := 0, stableSince := 0
            } else if stuckLevel <= 3 {
                RLog("Bậc " stuckLevel ": ĐÓNG game" (stuckLevel = 3 ? " và launcher" : "") " rồi đăng nhập lại từ đầu")
                KillForRestart(stuckLevel = 3)
                playClicks := 0, lastPlay := 0, loginClicks := 0, lastLogin := 0, chanFails := 0
                launcherSeen := 0, launcherRun := 0, stableSince := 0
                seenLoading := false, gameAtStart := false
                t0 := A_TickCount
            } else {
                RLog("Đã thử hết các bậc xử lý kẹt (kiểm tra lại, đóng game, đóng cả launcher) mà vẫn kẹt -> báo thất bại")
                return false
            }
            state := ""
            stateAt := A_TickCount
            Sleep 300
            continue
        }
        if st != state {
            RLog("→ " st "   [t+" (A_TickCount - t0) "ms, ở trạng thái trước " (A_TickCount - stateAt) "ms]" (info != "" ? "  " info : ""))
            state := st
            stateAt := A_TickCount
            lastDump := A_TickCount
        } else if info != "" && A_TickCount - lastDump >= 4000 {
            RLog("   (vẫn: " st " " Round((A_TickCount - stateAt) / 1000) "s) " info)
            lastDump := A_TickCount
        }
        ToolTip "ĐĂNG NHẬP LẠI (lần " num "): " st "  " Round((A_TickCount - t0) / 1000) "s", 20, 60, 6
        dur := A_TickCount - it0
        if dur > 800
            RLog("   vòng kiểm tra chậm " dur "ms (đọc điểm ảnh/cửa sổ chậm)")
        Sleep 300
    }
    RLog("Hết " Round(ReAttemptMs / 1000) "s ở trạng thái: " state)
    return false
}

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
