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

