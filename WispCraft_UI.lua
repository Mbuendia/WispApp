local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft UI — Main Window, Sidebar, Bubbles & Peek (v1.1)
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

--------------------------------------------------------------------------------
-- PEEK MODE
--------------------------------------------------------------------------------
function ns.setPeekMode(enable)
    ns.peekMode = enable
    if enable then
        ns.phoneFrame:Hide()
        ns.peekBar:Show()
    else
        ns.phoneFrame:Show()
        ns.peekBar:Hide()
    end
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

--------------------------------------------------------------------------------
-- BUBBLES
--------------------------------------------------------------------------------
local function clearBubbles()
    for _, b in ipairs(ns.bubbles) do b:Hide() end
end

local function newBubble(text, tsStr, isOut, lastY)
    local w = ns.measureW(text, ns.BMAX)
    local h = ns.measureH(text, w) + 18

    local b = CreateFrame("Frame", nil, ns.contentFrame)
    b:SetSize(w, h)
    b:SetPoint("TOP", ns.contentFrame, "TOP", 0, lastY)
    if isOut then b:SetPoint("RIGHT", -ns.BPAD, 0)
    else          b:SetPoint("LEFT", ns.BPAD, 0) end

    ns.BG(b, isOut and ns.C.bOut or ns.C.bIn)

    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("TOPLEFT", ns.BPAD, -5)
    txt:SetPoint("BOTTOMRIGHT", -ns.BPAD, 12)
    txt:SetJustifyH("LEFT"); txt:SetJustifyV("TOP")
    txt:SetText(text); txt:SetTextColor(1,1,1)

    local ts = b:CreateFontString(nil, "OVERLAY")
    ts:SetFont("Fonts\\FRIZQT__.TTF", 8)
    ts:SetPoint("BOTTOMRIGHT", -5, 3)
    ts:SetText(tsStr); ts:SetTextColor(0.6,0.6,0.6)

    table.insert(ns.bubbles, b)
    return h
end

function ns.renderChat()
    clearBubbles()
    if not ns.active then return end
    local c = ns.convos[ns.contacts[ns.active]]
    local y = -10
    for _, m in ipairs(c) do
        local bh = newBubble(m.msg, m.ts, m.out, y)
        y = y - bh - 6
    end
    ns.contentFrame:SetHeight(math.abs(y))
    C_Timer.After(0.05, function()
        ns.scrollFrame:SetVerticalScroll(ns.scrollFrame:GetVerticalScrollRange())
    end)
end

--------------------------------------------------------------------------------
-- CONTACTS
--------------------------------------------------------------------------------
local function buildContactRow(idx)
    local r = CreateFrame("Button", nil, ns.contactListFrame)
    r:SetSize(ns.SW, ns.ROW_H)
    r:SetPoint("TOP", ns.contactListFrame, "TOP", 0, -(idx-1)*ns.ROW_H)

    local bg = ns.BG(r, ns.C.sidebar)
    r:SetScript("OnEnter", function() bg:SetColorTexture(ns.U(ns.C.sidHov)) end)
    r:SetScript("OnLeave", function() bg:SetColorTexture(ns.U(ns.active==idx and ns.C.sidSel or ns.C.sidebar)) end)

    local av = r:CreateTexture(nil, "ARTWORK")
    av:SetSize(38,38); av:SetPoint("LEFT", 8, 0)

    local avT = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    avT:SetPoint("CENTER", av, "CENTER"); avT:SetTextColor(1,1,1)

    local nT = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nT:SetPoint("TOPLEFT", av, "TOPRIGHT", 8, -4)
    nT:SetWidth(75); nT:SetJustifyH("LEFT"); nT:SetTextColor(1,1,1)

    local pT = r:CreateFontString(nil, "OVERLAY")
    pT:SetFont("Fonts\\FRIZQT__.TTF", 9)
    pT:SetPoint("TOPLEFT", nT, "BOTTOMLEFT", 0, -2)
    pT:SetWidth(75); pT:SetJustifyH("LEFT"); pT:SetTextColor(ns.U(ns.C.dgray))
    pT:SetWordWrap(false)

    local tsT = r:CreateFontString(nil, "OVERLAY")
    tsT:SetFont("Fonts\\FRIZQT__.TTF", 8)
    tsT:SetPoint("TOPRIGHT", -5, -6); tsT:SetTextColor(ns.U(ns.C.green))

    local bF = CreateFrame("Frame", nil, r)
    bF:SetSize(16,16); bF:SetPoint("BOTTOMRIGHT", -5, 8)
    ns.BG(bF, ns.C.badge)
    local bT = bF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bT:SetAllPoints(); bT:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    bT:SetTextColor(1,1,1)

    r:SetScript("OnClick", function() ns.selectContact(idx) end)

    if not ns.contactRows then ns.contactRows = {} end
    ns.contactRows[idx] = {f=r, bg=bg, av=av, avT=avT, nT=nT, pT=pT, tsT=tsT, bF=bF, bT=bT}
    return r
end

function ns.updateContactList()
    for i, name in ipairs(ns.contacts) do
        local r = ns.contactRows[i] or buildContactRow(i)
        r.f:Show()
        r.bg:SetColorTexture(ns.U(ns.active==i and ns.C.sidSel or ns.C.sidebar))
        r.av:SetColorTexture(ns.avatarColor(name))
        r.avT:SetText(name:sub(1,1):upper())
        r.nT:SetText(name)

        local c = ns.convos[name]
        local last = c[#c]
        if last then
            r.pT:SetText((last.out and "Tú: " or "")..last.msg)
            r.tsT:SetText(last.ts)
        end

        local ur = ns.unread[name]
        if ur and ur > 0 then
            r.bF:Show(); r.bT:SetText(ur > 9 and "9+" or ur)
        else r.bF:Hide() end
    end
end

function ns.selectContact(idx)
    ns.active = idx
    local name = ns.contacts[idx]
    ns.unread[name] = 0
    ns.headerName:SetText(name)
    ns.hdrStatus:SetText("en línea")
    ns.hdrAvatarLetter:SetText(name:sub(1,1):upper())
    ns.hdrAvatarLetter:GetParent():SetColorTexture(ns.avatarColor(name))
    
    ns.inputBox:Enable(); ns.sendBtn:Enable()
    ns.noConvLabel:Hide()
    ns.updateContactList()
    ns.renderChat()
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

--------------------------------------------------------------------------------
-- BUILD UI
--------------------------------------------------------------------------------
function ns.buildUI()
    -- Phone Shell
    local pf = CreateFrame("Frame", "WispCraftPhone", UIParent)
    ns.phoneFrame = pf
    pf:SetSize(ns.PW, ns.PH)
    pf:SetPoint("CENTER")
    pf:SetMovable(true); pf:EnableMouse(true)
    pf:RegisterForDrag("LeftButton")
    pf:SetScript("OnDragStart", pf.StartMoving)
    pf:SetScript("OnDragStop", pf.StopMovingOrSizing)
    pf:SetFrameStrata("DIALOG")
    ns.BG(pf, ns.C.phone)
    pf:Hide()

    -- Status Bar
    local sb = CreateFrame("Frame", nil, pf)
    sb:SetSize(ns.PW, ns.STATUS_H)
    sb:SetPoint("TOP")
    ns.BG(sb, ns.C.topbar)
    local sbt = sb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sbt:SetPoint("LEFT", 10, 0); sbt:SetText("WispCraft v1.1"); sbt:SetFont("Fonts\\FRIZQT__.TTF", 9)

    -- Peek Bar (v1.1)
    local pb = CreateFrame("Button", "WispCraftPeekBar", UIParent)
    ns.peekBar = pb
    pb:SetSize(ns.PW, ns.HH)
    pb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
    pb:SetMovable(true); pb:EnableMouse(true)
    pb:RegisterForDrag("LeftButton")
    pb:SetScript("OnDragStart", pb.StartMoving)
    pb:SetScript("OnDragStop", pb.StopMovingOrSizing)
    pb:SetFrameStrata("DIALOG")
    ns.BG(pb, ns.C.hdrDark)
    
    local pbT = pb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pbT:SetPoint("LEFT", 14, 0)
    pbT:SetText("|cff25d366Wisp|r|cffffffffApp|r")
    ns.peekBadgeText = pbT

    pb:SetScript("OnClick", function() ns.setPeekMode(false) end)
    pb:Hide()

    -- Sidebar
    local sd = CreateFrame("Frame", nil, pf)
    ns.sidebarFrame = sd
    sd:SetSize(ns.SW, ns.PH - ns.STATUS_H)
    sd:SetPoint("TOPLEFT", 0, -ns.STATUS_H)
    ns.BG(sd, ns.C.sidebar)

    local sh = CreateFrame("Frame", nil, sd)
    sh:SetSize(ns.SW, ns.HH)
    sh:SetPoint("TOPLEFT")
    ns.BG(sh, ns.C.hdrDark)
    local st = sh:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    st:SetPoint("CENTER", 0, 5); st:SetText("|cff25d366Wisp|r|cffffffffApp|r")

    ns.contactListFrame = CreateFrame("Frame", nil, sd)
    ns.contactListFrame:SetPoint("TOPLEFT", sh, "BOTTOMLEFT")
    ns.contactListFrame:SetPoint("BOTTOMRIGHT")

    -- Chat Panel
    local cp = CreateFrame("Frame", nil, pf)
    ns.chatPanel = cp
    cp:SetPoint("TOPLEFT", sd, "TOPRIGHT")
    cp:SetPoint("BOTTOMRIGHT")
    ns.BG(cp, ns.C.screen)

    -- Header
    local ch = CreateFrame("Frame", nil, cp)
    ch:SetSize(ns.PW - ns.SW, ns.HH)
    ch:SetPoint("TOPLEFT")
    ns.BG(ch, ns.C.hdr)

    local cClose = CreateFrame("Button", nil, ch, "UIPanelCloseButton")
    cClose:SetPoint("RIGHT", -5, 0)
    cClose:SetScript("OnClick", function() ns.setPeekMode(true) end) -- v1.1 close goes to peek

    local hA = ch:CreateTexture(nil, "ARTWORK")
    hA:SetSize(36,36); hA:SetPoint("LEFT", 10, 0); hA:SetColorTexture(0.2,0.3,0.2)
    ns.hdrAvatarLetter = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.hdrAvatarLetter:SetPoint("CENTER", hA, "CENTER")
    ns.hdrAvatarLetter:SetText("?")

    ns.headerName = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.headerName:SetPoint("TOPLEFT", hA, "TOPRIGHT", 8, -4)
    ns.headerName:SetText("Ningún Wisp")

    ns.hdrStatus = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.hdrStatus:SetPoint("BOTTOMLEFT", hA, "BOTTOMRIGHT", 8, 4)
    ns.hdrStatus:SetFont("Fonts\\FRIZQT__.TTF", 9); ns.hdrStatus:SetTextColor(ns.U(ns.C.lgray))
    ns.hdrStatus:SetText("selecciona un contacto")

    -- Scroll
    ns.scrollFrame = CreateFrame("ScrollFrame", "WispCraftScroll", cp, "UIPanelScrollFrameTemplate")
    ns.scrollFrame:SetPoint("TOPLEFT", ch, "BOTTOMLEFT", 0, -5)
    ns.scrollFrame:SetPoint("BOTTOMRIGHT", 0, ns.IH + 5)
    
    ns.contentFrame = CreateFrame("Frame", nil, ns.scrollFrame)
    ns.contentFrame:SetSize(ns.PW - ns.SW - 30, 100)
    ns.scrollFrame:SetScrollChild(ns.contentFrame)

    ns.noConvLabel = ns.scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.noConvLabel:SetPoint("CENTER")
    ns.noConvLabel:SetText("Los susurros\naparecerán aquí.")
    ns.noConvLabel:SetTextColor(0.5,0.5,0.5)

    -- Input
    local ia = CreateFrame("Frame", nil, cp)
    ia:SetSize(ns.PW - ns.SW, ns.IH)
    ia:SetPoint("BOTTOMLEFT")
    ns.BG(ia, ns.C.inputBG)

    ns.inputBox = CreateFrame("EditBox", nil, ia, "InputBoxTemplate")
    ns.inputBox:SetPoint("LEFT", 15, 0); ns.inputBox:SetPoint("RIGHT", -45, 0)
    ns.inputBox:SetHeight(32); ns.inputBox:SetAutoFocus(false)
    ns.inputBox:SetFontObject("ChatFontNormal")
    ns.inputBox:Disable()

    ns.sendBtn = CreateFrame("Button", nil, ia)
    ns.sendBtn:SetSize(32,32); ns.sendBtn:SetPoint("RIGHT", -8, 0)
    ns.BG(ns.sendBtn, ns.C.hdr)
    local sTx = ns.sendBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sTx:SetPoint("CENTER"); sTx:SetText(">")
    ns.sendBtn:Disable()

    local function doSend()
        local text = ns.inputBox:GetText()
        if text:len() > 0 and ns.active then
            local target = ns.contacts[ns.active]
            if not ns.pendingOut[target] then ns.pendingOut[target] = {} end
            ns.pendingOut[target][text] = true
            
            SendChatMessage(text, "WHISPER", nil, target)
            ns.pushMessage(target, text, true)
            ns.inputBox:SetText("")
            ns.renderChat()
            ns.updateContactList()
        end
    end

    ns.sendBtn:SetScript("OnClick", doSend)
    ns.inputBox:SetScript("OnEnterPressed", doSend)
    ns.inputBox:SetScript("OnEscapePressed", function() ns.inputBox:ClearFocus() end)
end
