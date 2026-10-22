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

