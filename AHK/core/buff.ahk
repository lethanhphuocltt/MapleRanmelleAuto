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

