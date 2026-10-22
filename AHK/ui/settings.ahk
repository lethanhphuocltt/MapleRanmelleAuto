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
