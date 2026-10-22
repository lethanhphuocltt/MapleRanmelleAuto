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
ZoneNeed := 0.7         ; tỉ lệ điểm khớp tối thiểu để coi vùng là "khớp" (với dạng điểm cũ hoặc ngưỡng SAD 0.85 với ảnh 32x32)

; Co giãn vùng màn hình thành ảnh grayscale 32x32 (1024 bytes) bằng GDI
GrabGray32(x, y, w, h, &buf) {
    if w < 1 || h < 1
        return false
    ok := false
    Critical "On"
    try {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        if hdc {
            mdcSrc := DllCall("CreateCompatibleDC", "Ptr", hdc, "Ptr")
            mdcDst := DllCall("CreateCompatibleDC", "Ptr", hdc, "Ptr")
            
            bmiSrc := Buffer(40, 0)
            NumPut("UInt", 40, bmiSrc, 0)
            NumPut("Int", w, bmiSrc, 4)
            NumPut("Int", -h, bmiSrc, 8)
            NumPut("UShort", 1, bmiSrc, 12)
            NumPut("UShort", 32, bmiSrc, 14)
            bitsSrc := 0
            hbmSrc := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bmiSrc, "UInt", 0, "Ptr*", &bitsSrc, "Ptr", 0, "UInt", 0, "Ptr")
            
            bmiDst := Buffer(40, 0)
            NumPut("UInt", 40, bmiDst, 0)
            NumPut("Int", 32, bmiDst, 4)
            NumPut("Int", -32, bmiDst, 8)
            NumPut("UShort", 1, bmiDst, 12)
            NumPut("UShort", 32, bmiDst, 14)
            bitsDst := 0
            hbmDst := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bmiDst, "UInt", 0, "Ptr*", &bitsDst, "Ptr", 0, "UInt", 0, "Ptr")
            
            if mdcSrc && mdcDst && hbmSrc && hbmDst && bitsSrc && bitsDst {
                oldSrc := DllCall("SelectObject", "Ptr", mdcSrc, "Ptr", hbmSrc, "Ptr")
                oldDst := DllCall("SelectObject", "Ptr", mdcDst, "Ptr", hbmDst, "Ptr")
                
                ; Chụp ảnh gốc từ màn hình
                if DllCall("BitBlt", "Ptr", mdcSrc, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdc, "Int", x, "Int", y, "UInt", 0x00CC0020, "Int") {
                    ; Co về 32x32 với COLORONCOLOR (3)
                    DllCall("SetStretchBltMode", "Ptr", mdcDst, "Int", 3)
                    if DllCall("StretchBlt", "Ptr", mdcDst, "Int", 0, "Int", 0, "Int", 32, "Int", 32, "Ptr", mdcSrc, "Int", 0, "Int", 0, "Int", w, "Int", h, "UInt", 0x00CC0020, "Int") {
                        if !IsObject(buf) || buf.Size < 1024
                            buf := Buffer(1024, 0)
                        ; Chuyển 32x32 BGRA sang Grayscale theo luma 0.299*R + 0.587*G + 0.114*B
                        loop 1024 {
                            off := (A_Index - 1) * 4
                            b := NumGet(bitsDst, off, "UChar")
                            g := NumGet(bitsDst, off + 1, "UChar")
                            r := NumGet(bitsDst, off + 2, "UChar")
                            NumPut("UChar", Round(0.299 * r + 0.587 * g + 0.114 * b), buf, A_Index - 1)
                        }
                        ok := true
                    }
                }
                DllCall("SelectObject", "Ptr", mdcSrc, "Ptr", oldSrc)
                DllCall("SelectObject", "Ptr", mdcDst, "Ptr", oldDst)
            }
            if hbmSrc
                DllCall("DeleteObject", "Ptr", hbmSrc)
            if hbmDst
                DllCall("DeleteObject", "Ptr", hbmDst)
            if mdcSrc
                DllCall("DeleteDC", "Ptr", mdcSrc)
            if mdcDst
                DllCall("DeleteDC", "Ptr", mdcDst)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        }
    } finally {
        Critical "Off"
    }
    return ok
}

; Chụp thumbnail 32x32 của một Zone (trả về Buffer 1024 hoặc "")
ZoneCapture32(id, hwnd) {
    if !hwnd
        return ""
    ZoneToPx(id, hwnd, &x1, &y1, &x2, &y2)
    w := x2 - x1, h := y2 - y1
    buf := Buffer(1024, 0)
    if GrabGray32(x1, y1, w, h, &buf)
        return buf
    return ""
}

; Tính khoảng cách SAD trung bình (0..255) giữa 2 buffer 1024 bytes
BufferSad32(buf1, buf2) {
    if !IsObject(buf1) || !IsObject(buf2) || buf1.Size < 1024 || buf2.Size < 1024
        return 999.0
    sum := 0
    loop 1024 {
        i := A_Index - 1
        sum += Abs(NumGet(buf1, i, "UChar") - NumGet(buf2, i, "UChar"))
    }
    return sum / 1024.0
}

; Chuyển Buffer 1024 byte thành chuỗi Hex 2048 ký tự
Gray32ToHex(buf) {
    if !IsObject(buf) || buf.Size < 1024
        return ""
    chars := "0123456789ABCDEF"
    str := ""
    VarSetStrCapacity(&str, 2048)
    loop 1024 {
        b := NumGet(buf, A_Index - 1, "UChar")
        str .= SubStr(chars, (b >> 4) + 1, 1) . SubStr(chars, (b & 15) + 1, 1)
    }
    return str
}

; Chuyển chuỗi Hex 2048 ký tự thành Buffer 1024 bytes
HexToGray32(hexStr) {
    if StrLen(hexStr) != 2048
        return ""
    buf := Buffer(1024, 0)
    loop 1024 {
        h := SubStr(hexStr, (A_Index - 1) * 2 + 1, 2)
        NumPut("UChar", Integer("0x" h), buf, A_Index - 1)
    }
    return buf
}

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
        
        cCount := Integer(h[5]), rCount := Integer(h[6])
        hexData := parts[2]
        
        ; Nếu cCount=32 && rCount=32 và hexData có đúng 2048 ký tự -> dữ liệu mới Grayscale 32x32
        if cCount = 32 && rCount = 32 && StrLen(hexData) = 2048 {
            grayBuf := HexToGray32(hexData)
            Zones[d[1]] := Map("l", Number(h[1]), "t", Number(h[2]), "r", Number(h[3]), "b", Number(h[4]), "C", 32, "R", 32, "gray", grayBuf, "pts", [])
        } else {
            ; Dữ liệu điểm màu cũ
            pts := []
            for hx in StrSplit(hexData, ",") {
                if hx != ""
                    pts.Push(Integer("0x" hx))
            }
            Zones[d[1]] := Map("l", Number(h[1]), "t", Number(h[2]), "r", Number(h[3]), "b", Number(h[4]), "C", cCount, "R", rCount, "pts", pts)
        }
    }
}

ZoneSaveIni(id) {
    z := Zones[id]
    if z.Has("gray") && IsObject(z["gray"]) && z["gray"].Size >= 1024 {
        hexStr := Gray32ToHex(z["gray"])
        IniWrite Format("{:.4f},{:.4f},{:.4f},{:.4f},32,32|{}", z["l"], z["t"], z["r"], z["b"], hexStr), IniFile, "Zones", id
    } else {
        hexs := ""
        for c in z["pts"]
            hexs .= (hexs = "" ? "" : ",") ColStr(c)
        IniWrite Format("{:.4f},{:.4f},{:.4f},{:.4f},{},{}", z["l"], z["t"], z["r"], z["b"], z["C"], z["R"]) "|" hexs, IniFile, "Zones", id
    }
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
    
    ; Nếu đã học theo dạng thumbnail grayscale 32x32
    if z.Has("gray") && IsObject(z["gray"]) && z["gray"].Size >= 1024 {
        curBuf := ZoneCapture32(id, hwnd)
        if !IsObject(curBuf)
            return -1
        sad := BufferSad32(curBuf, z["gray"])
        ; SAD trung bình 0..255. Chuẩn hóa độ khớp: SAD = 0 -> 1.0, SAD = 255 -> 0.0
        return Max(0.0, 1.0 - (sad / 255.0))
    }
    
    ; Ngược lại dùng cơ chế lưới điểm cũ
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
    refZone := Zones[ptsId]
    
    ; Nếu cả 2 đều có thumbnail grayscale 32x32
    if z.Has("gray") && IsObject(z["gray"]) && refZone.Has("gray") && IsObject(refZone["gray"]) {
        curBuf := ZoneCapture32(rectId, hwnd)
        if !IsObject(curBuf)
            return 999
        return BufferSad32(curBuf, refZone["gray"])
    }
    
    ref := refZone["pts"]
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
    wBox := x2 - x1, hBox := y2 - y1
    gray1 := Buffer(1024, 0)
    hasGray := GrabGray32(x1, y1, wBox, hBox, &gray1)
    
    pts := []
    desc := ""
    for p in ZonePoints(x1, y1, x2, y2, gc, gr) {
        pc := Integer(PxGet(p[1], p[2]))
        pts.Push(pc)
        if A_Index <= 6
            desc .= ColStr(pc) " "
    }
    Sleep 700           ; đọc lần 2 để đo độ ổn định (vùng có hiệu ứng động sẽ đổi màu)
    stabPct := 0
    if hasGray {
        gray2 := Buffer(1024, 0)
        if GrabGray32(x1, y1, wBox, hBox, &gray2) {
            sad := BufferSad32(gray1, gray2)
            stabPct := Round(Max(0.0, 1.0 - (sad / 255.0)) * 100)
        }
    }
    if stabPct = 0 {
        stab := 0
        for i, p in ZonePoints(x1, y1, x2, y2, gc, gr) {
            pc2 := Integer(PxGet(p[1], p[2]))
            if ColNear(pc2, (pts[i] >> 16) & 255, (pts[i] >> 8) & 255, pts[i] & 255, ZoneTol)
                stab += 1
        }
        stabPct := Round(stab / pts.Length * 100)
    }
    box := ShowBox(x1, y1, x2, y2)
    ans := MsgBox("Vùng: " def[3] "`nKích thước " (x2 - x1) "x" (y2 - y1) " px (thu nhỏ 32x32 grayscale).`nMàu mẫu đầu tiên: " desc "`nĐộ ổn định (2 lần đọc cách nhau 0,7s): " stabPct "%" (stabPct < 85 ? "`n!!! THẤP: vùng có hiệu ứng động/nền chuyển động, dễ nhận diện sai. Nên khoanh vùng khác (nền đứng yên)." : "") "`n`nLưu vùng này?", "Maple Auto v1 - Xem trước", "YesNo Icon?")
    try box.Destroy()
    if ans != "Yes"
        return
    zMap := Map("l", (x1 - cx) / cw, "t", (y1 - cy) / sy, "r", (x2 - cx) / cw, "b", (y2 - cy) / sy, "C", gc, "R", gr, "pts", pts)
    if hasGray {
        zMap["C"] := 32
        zMap["R"] := 32
        zMap["gray"] := gray1
    }
    Zones[id] := zMap
    ZoneSaveIni(id)
    RLog("ĐÃ HỌC vùng " id " (" def[3] "): " (x2 - x1) "x" (y2 - y1) "px (32x32 gray), ổn định " stabPct "%, màu đầu " desc)
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

