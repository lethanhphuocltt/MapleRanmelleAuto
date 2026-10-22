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

