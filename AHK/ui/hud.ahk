
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
