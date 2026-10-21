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

; =====================================================================
;  MAPLE AUTO v1 (bản thử nghiệm: thêm TỰ ĐĂNG NHẬP LẠI khi văng game)
;  Bản sao riêng, KHÔNG đụng tới maple_auto.ahk: dùng file settings_v1.ini, slot_base_v1.ini, debug_v1.log, error_v1.log.
;  Đừng chạy cùng lúc với bản gốc (hai bản cùng ấn phím sẽ xung đột).
;  Mọi thiết lập nằm trong file settings_v1.ini (sửa tay hoặc ấn F5 để mở cửa sổ Cài đặt).
;  Xem HUONG_DAN.txt để biết cách dùng.
; =====================================================================
IniFile := A_ScriptDir "\settings_v1.ini"
SlotIni := A_ScriptDir "\slot_base_v1.ini"   ; màu "sẵn sàng" của từng ô (lưu bằng nút "Lấy màu chuẩn" trong F5)

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
    ["Buff", "BtnDX", ""],                  ; vị trí nút Use Unapplied Buffs do người dùng chọn (px game, tính từ tâm vùng game); trống = chưa chọn
    ["Buff", "BtnDY", ""],
    ["Buff", "Action", "all"],              ; khi hiện bảng buff (mặc định all): unapplied = bấm chuột "Use Unapplied Buffs"; all = ấn Enter (chọn "Use All Buffs")
    ["Buff", "ClickMode", "0"],             ; cách bấm chuột đã thử thành công (1-5); 0 = chưa biết, thử lần lượt
    ["Buff", "AlwaysManual", "0"],          ; 1 = luôn bấm vị trí đã chọn; 0 = tự tìm nút bằng màu, không thấy mới dùng vị trí đã chọn               ; chờ sau khi bấm để buff được cast xong (giây)
    ["Detect", "UseSlotCheck", "1"],        ; 1 = đọc ô quickslot để biết hồi chiêu xong; 0 = chỉ dùng bộ đếm thời gian
    ["Detect", "GameResW", "0"],            ; độ rộng độ phân giải GAME nếu game bị phóng to (vd 1366); 0 = không phóng
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
]
; Skill: phím|cooldown(giây)|hàng quickslot (0=không có/không đọc, 1=hàng trên, 2=hàng dưới)|cột (từ 0)|lặp (1/0)|không dừng phím chính khi dùng (1/0)
; Thứ tự = thứ tự ưu tiên.
DefaultSkills := [
    "e|120|1|2|1", "3|360|1|6|1", "2|300|1|5|1", "1|60|1|4|1", "a|60|2|0|0",
    "g|60|0|0|0", "f|30|2|3|1", "d|10|0|0|0", "s|10|2|1|1",
]
MaxSkillRows := 14

if !FileExist(IniFile)
    FirstRun := true
else
    FirstRun := false
CreateDefaults()
CreateDefaults() {
    for d in Defaults {
        if IniRead(IniFile, d[1], d[2], "<none>") = "<none>"
            IniWrite d[3], IniFile, d[1], d[2]
    }
    if IniRead(IniFile, "Skills", "Skill1", "<none>") = "<none>" {
        for i, v in DefaultSkills
            IniWrite v, IniFile, "Skills", "Skill" i
    }
}
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
; Các phím buff: [Buff] = buff 1, [Buff2] = buff 2. Action: unapplied (bấm chuột Use Unapplied Buffs) / all (Enter = Use All Buffs) / esc (tắt bảng).
; Chỉ khi bảng buff HIỆN thì mới ấn Enter/ESC/bấm chuột; không có bảng thì không ấn gì.
Buffs := []
for sec in ["Buff", "Buff2"] {
    act := StrLower(Trim(Cfg(sec, "Action")))
    if act != "all" && act != "unapplied" && act != "esc"
        act := "all"
    Buffs.Push(Map("sec", sec, "enabled", Cfg(sec, "Enabled") = "1", "key", Trim(Cfg(sec, "Key")),
        "every", Max(10, Number(Cfg(sec, "EverySec"))), "waitMs", Max(0, Number(Cfg(sec, "WaitSec"))) * 1000,
        "action", act, "next", 0))
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
QS_X0         := Number(Cfg("Detect", "QS_X0"))
QS_DX         := Number(Cfg("Detect", "QS_DX"))
QS_Y1         := Number(Cfg("Detect", "QS_Y1"))
QS_Y2         := Number(Cfg("Detect", "QS_Y2"))
UseBatch      := Cfg("Detect", "BatchCapture") != "0"
ReadyDist     := Number(Cfg("Detect", "ReadyDist"))
VerifyDist    := Number(Cfg("Detect", "VerifyDist"))
VerifyMs      := Integer(Cfg("Detect", "VerifyMs"))
MaxRetry      := Integer(Cfg("Detect", "MaxRetry"))
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

; Ghi 1 sự kiện vào debug.log (chỉ khi bật trong F5). Giữ tối đa DebugMax dòng gần nhất.
DLog(msg) {
    global DebugCount
    if !DebugOn
        return
    try {
        FileAppend(FormatTime(, "HH:mm:ss") "." Format("{:03}", Mod(A_TickCount, 1000)) "  " msg "`n", DebugFile, "UTF-8")
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
        k := Scale(cw)
        m := GameMonitor(h)
        DLog("ENV: game cửa sổ " ww "x" wh " tại (" wx "," wy ")  vùng client " cw "x" ch " tại (" cx "," cy ")  hệ số k=" Round(k, 3) " (GameResW=" GameResW ")  tỉ lệ client " Round(cw / Max(1, ch), 3) "  nằm trên màn " m "  DPI màn đó=" MonDpi(wx + ww // 2, wy + wh // 2) "  trạng thái=" WinGetMinMax(h) "  PID=" WinGetPID(h))
        DLog("ENV: tâm client (" Round(cx + cw / 2) "," Round(cy + ch / 2) ")  ô quickslot đầu tiên cách mép phải " QS_X0 " px, mép dưới " QS_Y1 "/" QS_Y2 " px (khi k=1)")
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
        loop 10 {
            t := PerfNow()
            PixelGetColor(x, y)
            d := PerfNow() - t, t1 += d, m1 := Max(m1, d)
            if h {
                t := PerfNow()
                PixelGetColor(gx, gy)
                d := PerfNow() - t, t2 += d, m2 := Max(m2, d)
                t := PerfNow()
                WinGetClientPos &a, &b, &c, &e, h
                d := PerfNow() - t, t3 += d, m3 := Max(m3, d)
            }
            t := PerfNow()
            WinActive(GameWin)
            d := PerfNow() - t, t4 += d, m4 := Max(m4, d)
        }
        tq := 0, mq := 0, qn := 0
        if h && UseBatch && !QsOff {
            loop 5 {
                t := PerfNow()
                if QsCapture(cx, cy, cw, ch, Scale(cw), true)
                    qn += 1
                d := PerfNow() - t, tq += d, mq := Max(mq, d)
            }
        }
        DLog("BENCH " label ": chụp gộp dải quickslot " (qn ? "tb=" Round(tq / 5, 1) "ms max=" Round(mq, 1) "ms" : "không chạy") "  | đọc 1 điểm ở góc màn hình tb=" Round(t1 / 10, 1) "ms max=" Round(m1, 1) "  | giữa game tb=" Round(t2 / 10, 1) "ms max=" Round(m2, 1) "  | WinGetClientPos tb=" Round(t3 / 10, 1) "ms max=" Round(m3, 1) "  | WinActive tb=" Round(t4 / 10, 2) "ms max=" Round(m4, 1))
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
    global PerfStat, PerfMaxGap, PerfReportAt, PerfSig, PerfReports, PerfPrev
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
    } else if Mod(PerfReports, 5) = 0 {
        PxBench("định kỳ")
    }
}

; Khi thấy không có bảng buff: ghi toạ độ + màu các điểm dò để biết dò trượt vì sai vị trí hay sai màu
BuffSampleDump() {
    h := GameHwnd()
    if !h
        return "không có cửa sổ game"
    WinGetClientPos &cx, &cy, &cw, &ch, h
    k := Scale(cw)
    mx := cx + cw / 2
    my := cy + ch / 2
    out := "client " cw "x" ch " k=" Round(k, 3) " tâm (" Round(mx) "," Round(my) ")  loại1 [cần ~40,140,170]: "
    try {
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            x := Round(mx + p[1] * k), y := Round(my + p[2] * k)
            c := PxGet(x, y)
            out .= "(" x "," y ")=" ((c >> 16) & 0xFF) "," ((c >> 8) & 0xFF) "," (c & 0xFF) "  "
        }
        out .= " loại2 [cần ~44,165,186]: "
        for p in [[-140, -45], [140, -45]] {
            x := Round(mx + p[1] * k), y := Round(my + p[2] * k)
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

; Độ phóng giữa độ phân giải game và vùng cửa sổ
Scale(cw) => GameResW > 0 ? cw / GameResW : 1

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
    Skills.Push(m)
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
        for k in ["next", "wait", "tmr", "press", "flash", "vat", "chk"] {
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

ShowSettings(*) {
    global SettingsGui, GuiCtl, SettingsBusy
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
    g := Gui("+AlwaysOnTop", "Maple Auto v1 - Cài đặt")
    g.SetFont("s9", "Segoe UI")
    g.AddText("w560", "Chỉnh xong bấm LƯU: script sẽ tự khởi động lại với thiết lập mới. Chi tiết xem HUONG_DAN.txt.")
    gb1 := g.AddGroupBox("w560 h584 Section", "Chung")
    gb1.GetPos(&gx, &gy)            ; bố cục 2 cột (vừa màn hình 24 inch): cột trái = Chung, cột phải = Skill + Đăng nhập lại
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
    ]
    y := 20
    for r in rows {
        g.AddText("xs+12 ys+" y " w300", r[3])
        GuiCtl[r[2]] := g.AddEdit("x+4 yp-3 w200", Cfg(r[1], r[2]))
        y += 24
    }
    g.AddText("xs+12 ys+" y " w300", "Cách dùng skill chính:")
    GuiCtl["MainMode"] := g.AddDropDownList("x+4 yp-3 w200 Choose" (MainMode = "tap" ? 2 : 1), ["Ấn giữ", "Ấn nhả (ấn rồi nhả liên tục)"])
    y += 24
    GuiCtl["AutoFocus"] := g.AddCheckbox("xs+12 ys+" y " w300", "Tự đưa game lên trước (chống mất focus), mỗi (giây):")
    GuiCtl["AutoFocus"].Value := AutoFocus ? 1 : 0
    GuiCtl["FocusSec"] := g.AddEdit("x+4 yp-3 w60", Cfg("General", "FocusSec"))
    y += 28
    GuiCtl["ShowHud"] := g.AddCheckbox("xs+12 ys+" y " w300", "Hiện bảng thông tin (tooltip) giữa màn hình")
    GuiCtl["ShowHud"].Value := ShowHud ? 1 : 0
    g.AddButton("x+4 yp-4 w230", "Đặt lại thời gian (buff + hồi chiêu)").OnEvent("Click", ResetTimersBtn)
    y += 28
    GuiCtl["DebugOn"] := g.AddCheckbox("xs+12 ys+" y " w300", "Ghi log debug vào debug.log - số dòng tối đa:")
    GuiCtl["DebugOn"].Value := DebugOn ? 1 : 0
    GuiCtl["DebugMax"] := g.AddEdit("x+4 yp-3 w60", Cfg("Debug", "MaxEvents"))
    y += 28
    for i, bf in Buffs {
        pre := "B" i "_"
        GuiCtl[pre "Enabled"] := g.AddCheckbox("xs+12 ys+" y " w110", "Tự buff " i ": phím")
        GuiCtl[pre "Enabled"].Value := bf["enabled"] ? 1 : 0
        GuiCtl[pre "Key"] := g.AddEdit("x+4 yp-3 w40", Cfg(bf["sec"], "Key"))
        g.AddText("x+8 yp+3", "mỗi (giây):")
        GuiCtl[pre "EverySec"] := g.AddEdit("x+4 yp-3 w50", Cfg(bf["sec"], "EverySec"))
        g.AddText("x+8 yp+3", "chờ cast (giây):")
        GuiCtl[pre "WaitSec"] := g.AddEdit("x+4 yp-3 w50", Cfg(bf["sec"], "WaitSec"))
        y += 28
        g.AddText("xs+30 ys+" y " w190", "Khi hiện bảng buff thì:")
        GuiCtl[pre "Action"] := g.AddDropDownList("x+4 yp-3 w300 Choose" (bf["action"] = "esc" ? 3 : bf["action"] = "all" ? 2 : 1), ["Bấm nút Use Unapplied Buffs (chuột)", "Ấn Enter = Use All Buffs", "Tắt bảng (ESC)"])
        y += 28
    }
    g.AddText("xs+30 ys+" y " w520 cGray", "Chỉ khi bảng buff hiện mới ấn Enter/ESC/bấm chuột; không có bảng thì không ấn gì.")
    y += 24
    GuiCtl["BtnInfo"] := g.AddText("xs+30 ys+" y " w250", IsNumber(BtnDX) && IsNumber(BtnDY) ? "Vị trí nút đã chọn: " BtnDX ", " BtnDY : "Vị trí nút: chưa chọn (tự tìm bằng màu)")
    g.AddButton("x+4 yp-4 w120", "Chọn vị trí nút...").OnEvent("Click", CaptureBtnPos)
    GuiCtl["AlwaysManual"] := g.AddCheckbox("x+8 yp+4 w170", "Luôn dùng vị trí đã chọn")
    GuiCtl["AlwaysManual"].Value := BuffAlwaysManual ? 1 : 0
    y += 28
    GuiCtl["UseSlotCheck"] := g.AddCheckbox("xs+12 ys+" y " w540", "Đọc ô quickslot để biết hồi chiêu xong (bỏ chọn = chỉ dùng bộ đếm thời gian)")
    GuiCtl["UseSlotCheck"].Value := UseSlotCheck ? 1 : 0

    g.AddGroupBox("x" (gx + 576) " y" gy " w560 h" (MaxSkillRows * 24 + 78) " Section", "Danh sách skill (theo thứ tự ưu tiên)")
    g.AddText("xs+12 ys+20 w28", "Bật")
    g.AddText("x+4 yp w60", "Phím")
    g.AddText("x+4 yp w80", "Cooldown (s)")
    g.AddText("x+4 yp w100", "Hàng ô (0/1/2)")
    g.AddText("x+4 yp w70", "Cột ô (từ 0)")
    g.AddText("x+4 yp w44", "Lặp")
    g.AddText("x+4 yp w100", "Không dừng V")
    GuiCtl["rows"] := []
    loop MaxSkillRows {
        line := IniRead(IniFile, "Skills", "Skill" A_Index, "")
        f := StrSplit(line, "|")
        while f.Length < 7
            f.Push("")
        yy := 40 + (A_Index - 1) * 24
        c0 := g.AddCheckbox("xs+12 ys+" (yy + 3) " w24", "")
        c0.Value := Trim(f[7]) = "0" ? 0 : 1      ; không ghi/trống = bật
        e1 := g.AddEdit("x+4 yp-3 w60", f[1])
        e2 := g.AddEdit("x+4 yp w80", f[2])
        e3 := g.AddEdit("x+4 yp w100", f[3])
        e4 := g.AddEdit("x+4 yp w70", f[4])
        c5 := g.AddCheckbox("x+4 yp+3 w44", "")
        c5.Value := Trim(f[5]) = "1" ? 1 : 0
        c6 := g.AddCheckbox("x+4 yp w100", "")
        c6.Value := Trim(f[6]) = "1" ? 1 : 0
        GuiCtl["rows"].Push([e1, e2, e3, e4, c5, c6, c0])
    }
    g.AddText("xs+12 ys+" (MaxSkillRows * 24 + 46) " w540", "Hàng ô: 0 = không đọc ô (dùng bộ đếm), 1 = hàng trên của quickslot, 2 = hàng dưới. Để trống phím = bỏ dòng. Không dừng V: ấn skill đó mà vẫn giữ phím chính. Bật: bỏ chọn = tạm tắt skill đó (vẫn giữ dòng cấu hình).")
    g.AddGroupBox("xs y+16 w560 h172 Section", "Tự đăng nhập lại khi văng game (bản v1)")
    GuiCtl["ReOn"] := g.AddCheckbox("xs+12 ys+20 w536", "Bật: game văng thì mở launcher (nếu chưa có), bấm PLAY, chọn kênh, Log In")
    GuiCtl["ReOn"].Value := ReloginOn ? 1 : 0
    g.AddText("xs+12 ys+48 w150", "Launcher (.exe):")
    GuiCtl["ReLauncher"] := g.AddEdit("x+4 yp-3 w380", ReLauncher)
    g.AddText("xs+12 ys+76 w150", "Kênh cần chọn (1-30):")
    GuiCtl["ReChannel"] := g.AddEdit("x+4 yp-3 w60", ReChannel)
    g.AddText("x+16 yp+3 w170", "Coi là văng sau (giây):")
    GuiCtl["ReLost"] := g.AddEdit("x+4 yp-3 w60", ReLostSec)
    g.AddButton("xs+12 ys+104 w300", "Nhận diện màn hình (khoanh vùng bằng kéo thả)...").OnEvent("Click", (*) => ShowZoneGui())
    g.AddButton("x+8 yp w224", "Chạy thử quy trình đăng nhập lại").OnEvent("Click", TestRelogin)
    g.AddText("xs+12 ys+138 w536 cGray", "F9 = chạy thử quy trình (mở sẵn launcher hoặc màn hình chọn kênh). Log từng bước: debug_v1.log.")
    g.AddButton("x" gx " y" (gy + Max(584, MaxSkillRows * 24 + 78 + 16 + 172) + 14) " w100 Default", "LƯU").OnEvent("Click", SaveSettings)
    g.AddButton("x+8 w130", "Màu chuẩn ô...").OnEvent("Click", (*) => ShowColorGui())
    g.AddButton("x+8 w130", "Mở HƯỚNG DẪN").OnEvent("Click", (*) => OpenGuide())
    g.AddButton("x+8 w100", "Đóng").OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    SettingsGui := g
    if Holding
        ReleaseMain()
    MakeScrollable(g)
    SettingsBusy := false
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
    for k in ["RandMin", "RandMax", "RepMax", "GameResW", "MainTapMs", "FocusSec"] {
        if !IsInteger(Trim(GuiCtl[k].Value)) || Integer(Trim(GuiCtl[k].Value)) < 0 {
            MsgBox "Ô '" k "' phải là số nguyên không âm.", "Maple Auto", "Icon!"
            return
        }
    }
    loop 2 {
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
        key := Trim(r[1].Value)
        if key = ""
            continue
        cd := Trim(r[2].Value)
        row := Trim(r[3].Value) = "" ? "0" : Trim(r[3].Value)
        col := Trim(r[4].Value) = "" ? "0" : Trim(r[4].Value)
        if !IsNumber(cd) || Number(cd) <= 0 || !IsInteger(row) || Integer(row) < 0 || Integer(row) > 2 || !IsInteger(col) || Integer(col) < 0 {
            MsgBox "Dòng skill '" key "' có giá trị không hợp lệ.`nCooldown phải > 0, hàng ô là 0/1/2, cột ô là số nguyên >= 0.", "Maple Auto", "Icon!"
            return
        }
        lines.Push(key "|" cd "|" row "|" col "|" (r[5].Value ? 1 : 0) "|" (r[6].Value ? 1 : 0) "|" (r[7].Value ? 1 : 0))
    }
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
    IniWrite (GuiCtl["MainMode"].Value = 2 ? "tap" : "hold"), IniFile, "General", "MainMode"
    IniWrite GuiCtl["UseSlotCheck"].Value, IniFile, "Detect", "UseSlotCheck"
    IniWrite Trim(GuiCtl["FocusSec"].Value), IniFile, "General", "FocusSec"
    IniWrite GuiCtl["AutoFocus"].Value, IniFile, "General", "AutoFocus"
    loop 2 {
        pre := "B" A_Index "_"
        sec := A_Index = 1 ? "Buff" : "Buff2"
        IniWrite GuiCtl[pre "Enabled"].Value, IniFile, sec, "Enabled"
        IniWrite Trim(GuiCtl[pre "Key"].Value), IniFile, sec, "Key"
        IniWrite Trim(GuiCtl[pre "EverySec"].Value), IniFile, sec, "EverySec"
        IniWrite Trim(GuiCtl[pre "WaitSec"].Value), IniFile, sec, "WaitSec"
        v := GuiCtl[pre "Action"].Value
        IniWrite (v = 3 ? "esc" : v = 2 ? "all" : "unapplied"), IniFile, sec, "Action"
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
    Send "{" MainKey " up}"
    Reload
}

A_TrayMenu.Add()
A_TrayMenu.Add("Cài đặt (F5)", ShowSettings)
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
    try FileAppend(FormatTime(, "HH:mm:ss") "  " LastErr "`n", A_ScriptDir "\error_v1.log", "UTF-8")
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
F5:: ShowSettings()

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
QsCx := 0, QsCy := 0, QsCw := 0
QsAt := 0, QsOk := false, QsFails := 0, QsOff := false, QsLogged := 0, QsLastSlow := 0

QsCapture(cx, cy, cw, ch, k, force := false) {
    global QsBuf, QsX, QsY, QsW, QsH, QsCx, QsCy, QsCw, QsAt, QsOk, QsFails, QsOff, QsLogged, QsLastSlow
    if !UseBatch || QsOff
        return false
    if !force && QsOk && A_TickCount - QsAt <= 80 && QsCx = cx && QsCy = cy && QsCw = cw
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
    xl := cx + cw - QS_X0 * k
    x := Floor(xl + minPX * k) - 3
    xe := Ceil(xl + QS_DX * k * maxCol + maxPX * k) + 3
    y := Floor(cy + ch - Max(QS_Y1, QS_Y2) * k + minPY * k) - 3
    ye := Ceil(cy + ch - Min(QS_Y1, QS_Y2) * k + maxPY * k) + 3
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
            QsCx := cx, QsCy := cy, QsCw := cw
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
        if QsLogged < 3 {
            QsLogged += 1
            DLog("QS: chụp gộp dải quickslot " w "x" h " tại (" x "," y ") mất " Round(d, 1) "ms " (ok ? "OK" : "LỖI"))
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
    k := Scale(cw)
    x0 := cx + cw - QS_X0 * k + QS_DX * k * s["slot"][1]
    y0 := cy + ch - (s["slot"][2] = 1 ? QS_Y1 : QS_Y2) * k
    out := []
    try {
        QsCapture(cx, cy, cw, ch, k)
        for p in BandPts {
            c := QsPix(Round(x0 + p[1] * k), Round(y0 + p[2] * k))
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

; F2: hiện độ lệch màu của từng ô trong 8 giây
DebugSlots() {
    WinGetClientPos , , &cw, &ch, GameHwnd()
    txt := "Vùng game: " cw "x" ch "  hệ số phóng: " Round(Scale(cw), 3) "  (sẵn sàng nếu lệch <= " ReadyDist ")`n"
    for s in Skills {
        if !s.Has("slot")
            continue
        cur := SlotSample(s)
        txt .= StrUpper(s["key"]) ": "
        if !IsObject(cur) {
            txt .= "LỖI không đọc được`n"
            continue
        }
        if !Base.Has(s["key"]) {
            txt .= "chưa lưu màu chuẩn - F5 > Màu chuẩn > Lấy màu`n"
            continue
        }
        d := SampleDist(cur, Base[s["key"]])
        txt .= "lệch=" Round(d) "  " (d <= ReadyDist ? "SẴN SÀNG" : "HỒI CHIÊU") "`n"
    }
    ToolTip txt
    SetTimer () => ToolTip(), -8000
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
        key := StrLower(Trim(r[1].Value))
        row := Trim(r[3].Value)
        col := Trim(r[4].Value)
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
    global ScanMs, ScanAt
    if !Enabled || Paused() || BuffBusy
        return
    if !IsGameActive() {
        for s in Skills
            s["st"] := -1
        return
    }
    t0 := A_TickCount
    for s in Skills {
        if !(UseSlotCheck && s.Has("slot"))
            s["st"] := -1
        else if t0 < s["press"] + s["cd"] * 500
            s["st"] := 0        ; chắc chắn còn hồi chiêu: không cần đọc ô (đọc điểm ảnh rất chậm trong sandbox)
        else
            s["st"] := SlotState(s)
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
                if s["force"] {                                ; ấn mà chưa ra, đang thử lại
                    ready .= k "↻" (s["next"] > now ? "(" Ceil((s["next"] - now) / 1000) "s)" : "") " "
                } else if s["flash"] > s["press"] {            ; vừa thấy nháy trắng
                    extra := (s["wait"] > now) ? "(" Ceil((s["wait"] - now) / 1000) "s)" : ""
                    ready .= k extra " "
                } else if Base.Has(s["key"]) && s["st"] >= 0 {
                    if ColorReady(s, now)
                        ready .= k " "
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
    txt .= FormatTime(, "HH:mm:ss") "  quét ô " ScanMs "ms  nháy " FlashMs "ms  F1:" F1Count "  PID " ProcessExist() "  vòng:" LoopTicks "`n"
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
    k := Scale(cw)
    x0 := cx + cw - QS_X0 * k + QS_DX * k * s["slot"][1]
    y0 := cy + ch - (s["slot"][2] = 1 ? QS_Y1 : QS_Y2) * k
    try {
        QsCapture(cx, cy, cw, ch, k)
        for p in [[-9, 13], [4, 13]] {
            c := QsPix(Round(x0 + p[1] * k), Round(y0 + p[2] * k))
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
    for s in Skills {
        if !s.Has("slot") || s.Get("vat", 0) = 0 || A_TickCount < s["vat"]
            continue
        s["vat"] := 0
        before := s["vb"]
        after := SlotSample(s)
        verdict := 0
        if IsObject(before) && IsObject(after)
            verdict := SampleDist(before, after) >= VerifyDist ? 1 : -1
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
        if verdict = -1 && s["vhow"] != "hẹn giờ" {
            s["retries"] += 1
            s["force"] := true
            s["next"] := A_TickCount + (s["retries"] <= MaxRetry ? RetryGapMs : SlowRetryMs)
        } else {
            s["retries"] := 0
        }
    }
    SkillStuckCheck()
}

; Skill ấn mãi không ra (nhiều skill cùng thất bại liên tiếp) = nhiều khả năng chưa thực sự vào game
; (kẹt ở màn đăng nhập/chọn kênh/tải, hoặc game treo) -> chuyển sang xử lý kẹt: kiểm tra màn hình, vào game tiếp, không được thì đóng game đăng nhập lại
SkillStuckCheck() {
    global SkillRecoverTimes, SkillRecoverBusy
    if !ReloginOn || Relogging || SkillRecoverBusy || !Enabled
        return
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

; mx,my = tâm vùng client game; k = hệ số phóng. Ảnh còn mới <= 40ms thì dùng lại (sau khi ấn phím luôn phải thấy ảnh mới).
BdCapture(mx, my, k) {
    global BdBuf, BdX, BdY, BdW, BdH, BdMx, BdMy, BdAt, BdOk, BdFails, BdOff, BdLogged
    if !UseBatch || BdOff
        return false
    if BdOk && A_TickCount - BdAt <= 40 && BdMx = mx && BdMy = my
        return true
    x := Floor(mx - 171 * k) - 3
    xe := Ceil(mx + 171 * k) + 3
    y := Floor(my - 60 * k) - 3
    ye := Ceil(my + 25 * k) + 3
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
    k := Scale(cw)
    mx := cx + cw / 2
    my := cy + ch / 2
    try {
        BdCapture(mx, my, k)
        ; loại 1: bảng lớn, nền xanh ngọc đậm ~ (37,135,168)
        n := 0
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            c := BdRGB(Round(mx + p[1] * k), Round(my + p[2] * k))
            if Abs(c[1] - 40) <= 24 && Abs(c[2] - 140) <= 34 && Abs(c[3] - 170) <= 34
                n += 1
        }
        if n >= 3
            return 1
        ; loại 2: bảng nhỏ, phần trên xanh ngọc sáng ~ (44,165,186), phần dưới xám nhạt ~ (236,236,237)
        n := 0
        for p in [[-140, -45], [140, -45], [-140, -20], [140, -20]] {
            c := BdRGB(Round(mx + p[1] * k), Round(my + p[2] * k))
            if Abs(c[1] - 44) <= 20 && Abs(c[2] - 165) <= 20 && Abs(c[3] - 186) <= 20
                n += 1
        }
        if n >= 3 {
            g := 0
            for p in [[-140, 25], [140, 25]] {
                c := BdRGB(Round(mx + p[1] * k), Round(my + p[2] * k))
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
    k := Scale(cw)
    mx := cx + cw / 2
    my := cy + ch / 2
    teal := 0
    try {
        for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
            c := PxGet(Round(mx + p[1] * k), Round(my + p[2] * k))
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
        try found := PixelSearch(&fx, &fy, Round(mx - 30 * k), Round(my + 95 * k), Round(mx + 70 * k), Round(my + 240 * k), 0x92B019, 45)
        if found {
            x := Round(fx + 40 * k)
            y := Round(fy + 12 * k)
            return true
        }
    }
    if manual {                         ; dùng vị trí người dùng đã chọn trong F5
        x := Round(mx + Number(BtnDX) * k)
        y := Round(my + Number(BtnDY) * k)
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
    k := Scale(cw)
    x := Round(cx + cw / 2 + 18 * k)
    y := Round(cy + ch / 2 + 173 * k)
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
        ax := Round(x * 65535 / (A_ScreenWidth - 1))
        ay := Round(y * 65535 / (A_ScreenHeight - 1))
        DllCall("mouse_event", "UInt", 0x8001, "UInt", ax, "UInt", ay, "UInt", 0, "UPtr", 0)
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
    k := Scale(cw)
    x := Round(cx + cw / 2 + 44 * k)
    y := Round(cy + ch / 2 + 37 * k)
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
        k := Scale(cw)
        inside := px >= cx && py >= cy && px <= cx + cw && py <= cy + ch
        if closed && inside {
            NewBtn := [Round((px - (cx + cw / 2)) / k, 1), Round((py - (cy + ch / 2)) / k, 1)]
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
    k := Scale(cw)
    mx := cx + cw / 2
    my := cy + ch / 2
    found := BuffFindButton(&bx, &by, &hits)
    txt := "Vùng game " cw "x" ch "  hệ số " Round(k, 3) "`nLoại bảng: " BuffDialogKind() " (1 = Buff Sequence, 2 = EXP Coupon, 0 = không có)`nNút Use Unapplied Buffs: " (found ? "thấy ở (" bx "," by ")" : "không thấy") "`n"
    txt .= "Điểm nền (cần ~ 40,140,170; đạt " hits "/4): "
    for p in [[-171, -60], [171, -60], [-171, -10], [171, -10]] {
        c := PxGet(Round(mx + p[1] * k), Round(my + p[2] * k))
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
                    s["wait"] := 0
                    continue
                }
                if s["wait"] = 0 {
                    s["wait"] := now + ReadyHoldMs + Random(RandMin, RandMax)
                    continue
                }
                if now < s["wait"]
                    continue
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

; Tỉ lệ -> pixel màn hình. Launcher: x theo rộng, y theo cao; Game: cả x và y theo CHIỀU RỘNG (như các điểm mặc định)
ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2) {
    z := Zones[id]
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    sy := SubStr(id, 1, 1) = "L" ? ch : cw
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
    ov.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
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
    sy := isL ? ch : cw
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

GamePt(hwnd, rx, ry, &x, &y) {
    WinGetClientPos &cx, &cy, &cw, &ch, hwnd
    x := Round(cx + rx * cw)
    y := Round(cy + ry * cw)
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
        cellH := Round(ChDY * ClientW(gh))
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

; Đặt vị trí cố định: game = giữa màn hình, launcher = góc trên-trái. Chỉ di chuyển khi lệch > 3px (không đổi kích thước)
PlaceWin(hwnd, label) {
    static lastLog := 0
    if !PlaceWindows
        return
    try {
        if WinGetMinMax(hwnd) != 0
            return
        WinGetPos &x, &y, &w, &h, hwnd
        if label = "launcher" {
            WinGetClientPos &cx, &cy, , , hwnd
            tx := x - cx, ty := y - cy              ; khung client chạm góc (0,0)
        } else {
            tx := Max(0, (A_ScreenWidth - w) // 2)
            ty := Max(0, (A_ScreenHeight - h) // 2)
        }
        if Abs(x - tx) > 3 || Abs(y - ty) > 3 {
            WinMove tx, ty, , , hwnd
            Sleep 200
            if A_TickCount - lastLog > 3000 {
                lastLog := A_TickCount
                RLog("Đặt vị trí " label ": (" x "," y ") -> (" tx "," ty "), cỡ " w "x" h ", màn hình " A_ScreenWidth "x" A_ScreenHeight)
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
    SetTimer PerfReport, 30000
    SetTimer PerfFirstEnv, -4000
}

OnExit (*) => Send("{" MainKey " up}")
