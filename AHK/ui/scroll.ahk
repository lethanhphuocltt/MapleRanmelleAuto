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

