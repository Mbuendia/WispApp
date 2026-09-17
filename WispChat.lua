local ADDON_NAME, ns = ...

-- ============================================================
--  WispChat — WhatsApp-style whisper interface
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

--------------------------------------------------------------------------------
-- CONSTANTS & THEME
--------------------------------------------------------------------------------
local PW, PH   = 390, 570   -- phone width, height
local SW        = 135        -- sidebar width
local HH        = 52         -- header height
local IH        = 50         -- input area height
local STATUS_H  = 22         -- top fake status bar
local BMAX      = 155        -- max bubble width
local BPAD      = 9          -- bubble inner padding
local ROW_H     = 66         -- contact row height

-- WhatsApp dark palette
local C = {
    phone    = {0.050, 0.050, 0.070},
    screen   = {0.071, 0.122, 0.153},
    hdr      = {0.071, 0.561, 0.380},
    hdrDark  = {0.044, 0.400, 0.267},
    sidebar  = {0.053, 0.067, 0.082},
    sidHov   = {0.100, 0.150, 0.180},
    sidSel   = {0.133, 0.196, 0.220},
    divider  = {0.100, 0.150, 0.180},
    bIn      = {0.133, 0.196, 0.220},  -- incoming (dark teal)
    bOut     = {0.071, 0.361, 0.249},  -- outgoing (WA green)
    inputBG  = {0.082, 0.133, 0.161},
    topbar   = {0.030, 0.030, 0.040},
    white    = {1.000, 1.000, 1.000},
    lgray    = {0.650, 0.650, 0.650},
    dgray    = {0.380, 0.380, 0.380},
    green    = {0.145, 0.855, 0.561},
    badge    = {0.071, 0.561, 0.380},
    red      = {0.800, 0.100, 0.100},
}

local function U(t, a) return t[1], t[2], t[3], a or 1 end

local function BG(f, t, a)
    local tx = f:CreateTexture(nil, "BACKGROUND")
    tx:SetAllPoints(); tx:SetColorTexture(U(t, a))
    return tx
end

--------------------------------------------------------------------------------
-- SAVED STATE
--------------------------------------------------------------------------------
WispChatDB = WispChatDB or {}

local convos   = {}   -- [name] = { {msg, ts, out}, ... }
local unread   = {}   -- [name] = integer
local contacts = {}   -- ordered (most-recent first)
local active   = nil  -- currently open contact
local bubbles  = {}   -- active bubble frames (for cleanup)
local pendingOut = {} -- dedup outgoing: [target][msg] = true

--------------------------------------------------------------------------------
-- FORWARD DECLARATIONS
--------------------------------------------------------------------------------
local phoneFrame, sidebarFrame, chatPanel
local scrollFrame, contentFrame
local headerName, hdrAvatarLetter, hdrStatus
local inputBox, sendBtn
local contactListFrame, contactRows
local noConvLabel
local updateContactList, renderChat, selectContact

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function ts() return date("%H:%M") end
local function me() return UnitName("player") or "You" end

local function stripRealm(name)
    return (name or ""):match("^([^%-]+)") or name
end

local function avatarColor(name)
    -- deterministic color per name
    local h = 0
    for i = 1, #name do h = h + name:byte(i) end
    local hue = (h % 12) / 12
    -- simple HSV→RGB (S=0.5, V=0.6)
    local r, g, b
    local i2 = math.floor(hue * 6)
    local f  = hue * 6 - i2
    local p  = 0.3; local q = 0.6 * (1 - f * 0.5); local tv = 0.6 * (1 - (1-f)*0.5)
    if     i2==0 then r,g,b=0.6,tv,p
    elseif i2==1 then r,g,b=q,0.6,p
    elseif i2==2 then r,g,b=p,0.6,tv
    elseif i2==3 then r,g,b=p,q,0.6
    elseif i2==4 then r,g,b=tv,p,0.6
    else              r,g,b=0.6,p,q end
    return r, g, b
end

local function promoteContact(name)
    for i, n in ipairs(contacts) do
        if n == name then table.remove(contacts, i); break end
    end
    table.insert(contacts, 1, name)
end

local function ensureConvo(name)
    if not convos[name] then
        convos[name] = {}; unread[name] = 0
        table.insert(contacts, 1, name)
    end
end

local function pushMessage(contact, msg, isOut)
    ensureConvo(contact)
    table.insert(convos[contact], {msg=msg, ts=ts(), out=isOut})
    promoteContact(contact)
    if contact ~= active then
        unread[contact] = (unread[contact] or 0) + 1
    end
end

--------------------------------------------------------------------------------
-- TEXT MEASUREMENT HELPER
-- Uses a hidden FontString to measure text dimensions before layout
--------------------------------------------------------------------------------
local _mF = CreateFrame("Frame", nil, UIParent)
_mF:SetSize(BMAX - BPAD*2, 400); _mF:Hide()
local _mT = _mF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
_mT:SetAllPoints(); _mT:SetWordWrap(true); _mT:SetJustifyH("LEFT")

local function measureH(text, w)
    _mT:SetWidth(w - BPAD*2); _mT:SetText(text)
    return _mT:GetStringHeight()
end
local function measureW(text, maxW)
    _mT:SetWidth(maxW - BPAD*2); _mT:SetText(text)
    return math.min(_mT:GetStringWidth() + BPAD*2 + 6, maxW)
end

--------------------------------------------------------------------------------
-- BUBBLE FACTORY
--------------------------------------------------------------------------------
local function clearBubbles()
    for _, b in ipairs(bubbles) do
        b:Hide(); b:SetParent(UIParent)
    end
    wipe(bubbles)
end

local function newBubble(entry, yOff)
    local isOut = entry.out
    local mH    = measureH(entry.msg, BMAX)
    local mW    = math.max(measureW(entry.msg, BMAX), 60)
    local tsH   = 11
    local bH    = BPAD + mH + 4 + tsH + BPAD

    local b = CreateFrame("Frame", nil, contentFrame)
    b:SetSize(mW, bH)
    b:SetPoint(
        isOut and "TOPRIGHT" or "TOPLEFT",
        contentFrame,
        isOut and "TOPRIGHT" or "TOPLEFT",
        isOut and -8 or 8,
        yOff
    )

    -- Background
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(U(isOut and C.bOut or C.bIn))

    -- Small triangle tail
    local tail = b:CreateTexture(nil, "BORDER")
    tail:SetSize(7, 7)
    if isOut then
        tail:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 4, 2)
        tail:SetColorTexture(U(C.bOut))
    else
        tail:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", -4, 2)
        tail:SetColorTexture(U(C.bIn))
    end

    -- Message text
    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("TOPLEFT",  BPAD, -BPAD)
    txt:SetPoint("TOPRIGHT", -BPAD, -BPAD)
    txt:SetWordWrap(true); txt:SetJustifyH("LEFT")
    txt:SetText(entry.msg)
    txt:SetTextColor(U(C.white))

    -- Timestamp
    local tst = b:CreateFontString(nil, "OVERLAY")
    tst:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    tst:SetPoint("BOTTOMRIGHT", -BPAD, BPAD)
    tst:SetText(entry.ts)
    tst:SetTextColor(U(C.lgray))

    -- Double-tick for outgoing
    if isOut then
        local tick = b:CreateFontString(nil, "OVERLAY")
        tick:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        tick:SetPoint("BOTTOMRIGHT", tst, "BOTTOMLEFT", -1, 0)
        tick:SetText("✓✓")
        tick:SetTextColor(U(C.green))
    end

    table.insert(bubbles, b)
    return bH
end

--------------------------------------------------------------------------------
-- RENDER CHAT
--------------------------------------------------------------------------------
renderChat = function()
    clearBubbles()
    if not active then
        if noConvLabel then noConvLabel:Show() end
        return
    end
    if noConvLabel then noConvLabel:Hide() end

    local msgs = convos[active] or {}
    local yOff = -8
    local gap  = 6

    for _, entry in ipairs(msgs) do
        local bH = newBubble(entry, yOff)
        yOff = yOff - bH - gap
    end

    local totalH = math.max(-yOff + 8, scrollFrame:GetHeight())
    contentFrame:SetHeight(totalH)

    C_Timer.After(0.05, function()
        if scrollFrame:IsVisible() then
            scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
        end
    end)
end

--------------------------------------------------------------------------------
-- CONTACT ROW FACTORY
--------------------------------------------------------------------------------
local function getPreview(name)
    local msgs = convos[name]
    if not msgs or #msgs == 0 then return "|cff666666Sin mensajes|r" end
    local last = msgs[#msgs]
    local pfx  = last.out and ("|cff25d366Tú:|r ") or ""
    local txt  = last.msg
    if #txt > 20 then txt = txt:sub(1,18) .. "…" end
    return pfx .. txt
end

local function buildContactRow(parent, name)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(SW - 1, ROW_H)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(U(C.sidebar)); row.bg = bg

    -- Avatar
    local av = row:CreateTexture(nil, "ARTWORK")
    av:SetSize(38, 38); av:SetPoint("LEFT", 8, 0)
    local r2, g2, b2 = avatarColor(name)
    av:SetColorTexture(r2, g2, b2, 1); row.av = av

    local avTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    avTxt:SetPoint("CENTER", av, "CENTER", 0, 0)
    avTxt:SetText(name:sub(1,1):upper())
    avTxt:SetTextColor(1, 1, 1, 1); row.avTxt = avTxt

    -- Name
    local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameTxt:SetPoint("TOPLEFT", av, "TOPRIGHT", 7, -5)
    nameTxt:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    nameTxt:SetJustifyH("LEFT"); nameTxt:SetText(name)
    nameTxt:SetTextColor(U(C.white)); row.nameTxt = nameTxt

    -- Preview
    local prevTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevTxt:SetPoint("TOPLEFT", nameTxt, "BOTTOMLEFT", 0, -3)
    prevTxt:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    prevTxt:SetJustifyH("LEFT")
    prevTxt:SetTextColor(U(C.dgray)); row.prevTxt = prevTxt

    -- Timestamp top-right
    local tsTxt = row:CreateFontString(nil, "OVERLAY")
    tsTxt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    tsTxt:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -7)
    tsTxt:SetTextColor(U(C.green)); row.tsTxt = tsTxt

    -- Unread badge
    local badge = CreateFrame("Frame", nil, row)
    badge:SetSize(18, 18); badge:SetPoint("BOTTOMRIGHT", av, "TOPRIGHT", 2, -6)
    local bbg = badge:CreateTexture(nil, "BACKGROUND")
    bbg:SetAllPoints(); bbg:SetColorTexture(U(C.badge))
    local bNum = badge:CreateFontString(nil, "OVERLAY")
    bNum:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    bNum:SetAllPoints(); bNum:SetJustifyH("CENTER"); bNum:SetJustifyV("MIDDLE")
    bNum:SetTextColor(1, 1, 1, 1)
    badge:Hide(); row.badge = badge; row.bNum = bNum

    -- Bottom divider
    local div = row:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  SW * 0.22, 0)
    div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT",  0, 0)
    div:SetColorTexture(U(C.divider))

    -- Hover / select
    row:SetScript("OnEnter", function(self)
        if self.contactName ~= active then self.bg:SetColorTexture(U(C.sidHov)) end
    end)
    row:SetScript("OnLeave", function(self)
        if self.contactName ~= active then self.bg:SetColorTexture(U(C.sidebar)) end
    end)
    row:SetScript("OnClick", function(self) selectContact(self.contactName) end)

    row.contactName = name
    return row
end

--------------------------------------------------------------------------------
-- UPDATE CONTACT LIST
--------------------------------------------------------------------------------
updateContactList = function()
    -- hide all
    for _, row in pairs(contactRows) do row:Hide() end

    local yOff = 0
    for _, name in ipairs(contacts) do
        local row = contactRows[name]
        if not row then
            row = buildContactRow(contactListFrame, name)
            contactRows[name] = row
        end

        row.prevTxt:SetText(getPreview(name))
        local msgs = convos[name]
        if msgs and #msgs > 0 then
            row.tsTxt:SetText(msgs[#msgs].ts)
        end

        local u = unread[name] or 0
        if u > 0 then
            row.badge:Show(); row.bNum:SetText(tostring(math.min(u, 99)))
        else
            row.badge:Hide()
        end

        row.bg:SetColorTexture(U(name == active and C.sidSel or C.sidebar))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", contactListFrame, "TOPLEFT", 0, -yOff)
        row:Show()
        yOff = yOff + ROW_H
    end

    contactListFrame:SetHeight(math.max(yOff, 1))
end

--------------------------------------------------------------------------------
-- SELECT CONTACT
--------------------------------------------------------------------------------
selectContact = function(name)
    active = name
    unread[name] = 0

    headerName:SetText(name)
    hdrAvatarLetter:SetText(name:sub(1,1):upper())
    hdrStatus:SetText("|cff25d366en línea|r")

    inputBox:Enable()
    inputBox:SetText("")
    inputBox:SetTextColor(U(C.white))
    sendBtn:Enable()

    renderChat()
    updateContactList()
end

--------------------------------------------------------------------------------
-- SEND WHISPER
--------------------------------------------------------------------------------
local function doSend()
    if not active then return end
    local msg = inputBox:GetText()
    if not msg or msg == "" or msg == inputBox._ph then return end

    -- Optimistic add locally
    pushMessage(active, msg, true)

    -- Mark pending so INFORM event skips it
    pendingOut[active] = pendingOut[active] or {}
    pendingOut[active][msg] = (pendingOut[active][msg] or 0) + 1

    -- Actually send
    SendChatMessage(msg, "WHISPER", nil, active)

    inputBox:SetText("")
    inputBox:SetTextColor(U(C.white))

    renderChat()
    updateContactList()
end

--------------------------------------------------------------------------------
-- BUILD PHONE UI
--------------------------------------------------------------------------------
local function buildUI()
    ---- Outer phone shell -------------------------------------------------
    phoneFrame = CreateFrame("Frame", "WispChatPhone", UIParent, "BackdropTemplate")
    phoneFrame:SetSize(PW, PH)
    phoneFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    phoneFrame:SetFrameStrata("HIGH")
    phoneFrame:SetClampedToScreen(true)
    phoneFrame:SetMovable(true)
    phoneFrame:EnableMouse(true)
    phoneFrame:RegisterForDrag("LeftButton")
    phoneFrame:SetScript("OnDragStart", phoneFrame.StartMoving)
    phoneFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        WispChatDB.x, WispChatDB.y = x, y
    end)
    phoneFrame:Hide()

    BG(phoneFrame, C.phone)
    phoneFrame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=8})
    phoneFrame:SetBackdropBorderColor(0.18, 0.18, 0.25, 1)

    ---- Status bar (fake phone top) ----------------------------------------
    local sb = CreateFrame("Frame", nil, phoneFrame)
    sb:SetHeight(STATUS_H)
    sb:SetPoint("TOPLEFT",  phoneFrame, "TOPLEFT",  1, -1)
    sb:SetPoint("TOPRIGHT", phoneFrame, "TOPRIGHT", -1, -1)
    BG(sb, C.topbar)

    local sbTime = sb:CreateFontString(nil, "OVERLAY")
    sbTime:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sbTime:SetPoint("LEFT", 8, 0)
    sbTime:SetTextColor(U(C.white))
    sbTime:SetText(date("%H:%M"))

    local sbRight = sb:CreateFontString(nil, "OVERLAY")
    sbRight:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sbRight:SetPoint("RIGHT", -6, 0)
    sbRight:SetTextColor(U(C.white))
    sbRight:SetText("▌▌▌ WiFi 🔋")

    C_Timer.NewTicker(60, function() sbTime:SetText(date("%H:%M")) end)

    ---- Sidebar -----------------------------------------------------------
    sidebarFrame = CreateFrame("Frame", nil, phoneFrame)
    sidebarFrame:SetWidth(SW)
    sidebarFrame:SetPoint("TOPLEFT",    phoneFrame, "TOPLEFT",    1,  -(1 + STATUS_H))
    sidebarFrame:SetPoint("BOTTOMLEFT", phoneFrame, "BOTTOMLEFT", 1,  1)
    BG(sidebarFrame, C.sidebar)

    -- Sidebar header ("WispApp")
    local sHdr = CreateFrame("Frame", nil, sidebarFrame)
    sHdr:SetHeight(HH)
    sHdr:SetPoint("TOPLEFT",  sidebarFrame, "TOPLEFT")
    sHdr:SetPoint("TOPRIGHT", sidebarFrame, "TOPRIGHT")
    BG(sHdr, C.hdrDark)

    local sTitle = sHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sTitle:SetPoint("CENTER", 0, 2)
    sTitle:SetText("|cff25d366Wisp|r|cffffffffApp|r")

    local sSub = sHdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sSub:SetPoint("CENTER", 0, -9)
    sSub:SetText("|cff888888Susurros|r")

    -- Vertical divider
    local vDiv = sidebarFrame:CreateTexture(nil, "ARTWORK")
    vDiv:SetWidth(1)
    vDiv:SetPoint("TOPRIGHT",    sidebarFrame, "TOPRIGHT",    0, 0)
    vDiv:SetPoint("BOTTOMRIGHT", sidebarFrame, "BOTTOMRIGHT")
    vDiv:SetColorTexture(U(C.divider))

    -- Contact scroll
    local sScroll = CreateFrame("ScrollFrame", nil, sidebarFrame, "UIPanelScrollFrameTemplate")
    sScroll:SetPoint("TOPLEFT",     sidebarFrame, "TOPLEFT",     0, -HH)
    sScroll:SetPoint("BOTTOMRIGHT", sidebarFrame, "BOTTOMRIGHT", -16, 0)

    contactListFrame = CreateFrame("Frame", nil, sScroll)
    contactListFrame:SetWidth(SW - 17)
    contactListFrame:SetHeight(1)
    sScroll:SetScrollChild(contactListFrame)
    contactRows = {}

    ---- Chat panel --------------------------------------------------------
    chatPanel = CreateFrame("Frame", nil, phoneFrame)
    chatPanel:SetPoint("TOPLEFT",     phoneFrame, "TOPLEFT",     SW + 1, -(1 + STATUS_H))
    chatPanel:SetPoint("BOTTOMRIGHT", phoneFrame, "BOTTOMRIGHT", -1, 1)
    BG(chatPanel, C.screen)

    -- Chat header
    local cHdr = CreateFrame("Frame", nil, chatPanel)
    cHdr:SetHeight(HH)
    cHdr:SetPoint("TOPLEFT",  chatPanel, "TOPLEFT")
    cHdr:SetPoint("TOPRIGHT", chatPanel, "TOPRIGHT")
    BG(cHdr, C.hdr)

    -- Back button
    local backBtn = CreateFrame("Button", nil, cHdr)
    backBtn:SetSize(28, 28); backBtn:SetPoint("LEFT", 6, 0)
    local bTxt = backBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bTxt:SetAllPoints(); bTxt:SetText("◀"); bTxt:SetTextColor(U(C.white))
    backBtn:SetScript("OnClick", function()
        active = nil
        headerName:SetText("Selecciona un contacto")
        hdrAvatarLetter:SetText("?")
        hdrStatus:SetText("|cff888888sin conversación|r")
        inputBox:Disable(); sendBtn:Disable()
        renderChat(); updateContactList()
    end)

    -- Avatar in header
    local hAvBG = cHdr:CreateTexture(nil, "ARTWORK")
    hAvBG:SetSize(36, 36); hAvBG:SetPoint("LEFT", backBtn, "RIGHT", 4, 0)
    hAvBG:SetColorTexture(0.2, 0.5, 0.4, 1); ns.hAvBG = hAvBG

    hdrAvatarLetter = cHdr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hdrAvatarLetter:SetPoint("CENTER", hAvBG, "CENTER")
    hdrAvatarLetter:SetText("?"); hdrAvatarLetter:SetTextColor(U(C.white))

    headerName = cHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerName:SetPoint("TOPLEFT", hAvBG, "TOPRIGHT", 6, -5)
    headerName:SetText("Selecciona un contacto")
    headerName:SetTextColor(U(C.white))

    hdrStatus = cHdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrStatus:SetPoint("TOPLEFT", hAvBG, "TOPRIGHT", 6, -19)
    hdrStatus:SetText("|cff888888sin conversación|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, phoneFrame)
    closeBtn:SetSize(20, 20); closeBtn:SetPoint("TOPRIGHT", phoneFrame, "TOPRIGHT", -2, -2)
    local cBG = closeBtn:CreateTexture(nil, "BACKGROUND")
    cBG:SetAllPoints(); cBG:SetColorTexture(0.5, 0.1, 0.1, 0.9)
    local cTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cTxt:SetAllPoints(); cTxt:SetText("✕"); cTxt:SetTextColor(U(C.white))
    closeBtn:SetScript("OnClick", function() phoneFrame:Hide() end)

    ---- Chat scroll area --------------------------------------------------
    scrollFrame = CreateFrame("ScrollFrame", nil, chatPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     chatPanel, "TOPLEFT",     0,   -HH)
    scrollFrame:SetPoint("BOTTOMRIGHT", chatPanel, "BOTTOMRIGHT", -16, IH)

    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetWidth(PW - SW - 1 - 16 - 2)
    contentFrame:SetHeight(1)
    scrollFrame:SetScrollChild(contentFrame)

    -- Placeholder label
    noConvLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noConvLabel:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    noConvLabel:SetText("|cff444444Ningún wisp seleccionado.\n\nLos susurros aparecerán\nautomáticamente aquí.|r")
    noConvLabel:SetJustifyH("CENTER")

    ---- Input area --------------------------------------------------------
    local inputArea = CreateFrame("Frame", nil, chatPanel)
    inputArea:SetHeight(IH)
    inputArea:SetPoint("BOTTOMLEFT",  chatPanel, "BOTTOMLEFT")
    inputArea:SetPoint("BOTTOMRIGHT", chatPanel, "BOTTOMRIGHT")
    BG(inputArea, C.inputBG)

    local iTop = inputArea:CreateTexture(nil, "ARTWORK")
    iTop:SetHeight(1)
    iTop:SetPoint("TOPLEFT",  inputArea, "TOPLEFT")
    iTop:SetPoint("TOPRIGHT", inputArea, "TOPRIGHT")
    iTop:SetColorTexture(U(C.divider))

    -- EditBox
    inputBox = CreateFrame("EditBox", "WispChatInputBox", inputArea, "InputBoxTemplate")
    inputBox:SetHeight(IH - 12)
    inputBox:SetPoint("LEFT",  inputArea, "LEFT",  10, 0)
    inputBox:SetPoint("RIGHT", inputArea, "RIGHT", -46, 0)
    inputBox:SetAutoFocus(false)
    inputBox:SetFontObject(GameFontNormal)
    inputBox:SetMaxLetters(255)
    inputBox._ph = "Escribe un mensaje..."

    inputBox:SetText(inputBox._ph)
    inputBox:SetTextColor(U(C.dgray))
    inputBox:Disable()

    inputBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == self._ph then
            self:SetText(""); self:SetTextColor(U(C.white))
        end
    end)
    inputBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(self._ph); self:SetTextColor(U(C.dgray))
        end
    end)
    inputBox:SetScript("OnEnterPressed", doSend)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Send button
    sendBtn = CreateFrame("Button", nil, inputArea)
    sendBtn:SetSize(38, 38)
    sendBtn:SetPoint("RIGHT", inputArea, "RIGHT", -4, 0)
    local sBG = sendBtn:CreateTexture(nil, "BACKGROUND")
    sBG:SetAllPoints(); sBG:SetColorTexture(U(C.hdr))
    local sTxt = sendBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sTxt:SetAllPoints(); sTxt:SetText("▶"); sTxt:SetTextColor(U(C.white))
    sendBtn:SetScript("OnClick", doSend)
    sendBtn:Disable()

    -- Disabled overlay tint for send button
    sendBtn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then sBG:SetColorTexture(U(C.green)) end
    end)
    sendBtn:SetScript("OnLeave", function(self)
        sBG:SetColorTexture(U(C.hdr))
    end)
end

--------------------------------------------------------------------------------
-- MINIMAP BUTTON
--------------------------------------------------------------------------------
local function buildMinimapButton()
    local mmBtn = CreateFrame("Button", "WispChatMMButton", Minimap)
    mmBtn:SetSize(26, 26)
    mmBtn:SetFrameStrata("MEDIUM")
    mmBtn:SetFrameLevel(8)

    local iconBG = mmBtn:CreateTexture(nil, "BACKGROUND")
    iconBG:SetAllPoints(); iconBG:SetColorTexture(U(C.hdr))

    local iconTxt = mmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iconTxt:SetAllPoints(); iconTxt:SetText("💬")

    -- Position on minimap edge
    local angle = math.rad(220)
    local radius = 82
    mmBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)

    mmBtn:SetScript("OnClick", function()
        if phoneFrame:IsShown() then phoneFrame:Hide() else phoneFrame:Show() end
    end)
    mmBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff25d366WispApp|r")
        GameTooltip:AddLine("Clic para abrir/cerrar", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

--------------------------------------------------------------------------------
-- EVENT HANDLER
--------------------------------------------------------------------------------
local evFrame = CreateFrame("Frame", "WispChatEvents", UIParent)
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:RegisterEvent("CHAT_MSG_WHISPER")
evFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

evFrame:SetScript("OnEvent", function(self, event, ...)
    ------------------------------------------------------------
    if event == "ADDON_LOADED" then
        if (...) ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        WispChatDB = WispChatDB or {}
        buildUI()
        buildMinimapButton()
        -- Restore position
        if WispChatDB.x and WispChatDB.y then
            phoneFrame:ClearAllPoints()
            phoneFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                WispChatDB.x, WispChatDB.y)
        end
        print("|cff25d366WispApp|r cargado! "
            .. "Usa |cffffcc00/wispchat|r o el botón 💬 del minimapa.")

    ------------------------------------------------------------
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        sender = stripRealm(sender)
        pushMessage(sender, msg, false)

        -- Notification sound
        PlaySound(SOUNDKIT and SOUNDKIT.IG_CHAT_WHISPER_NOTIFY or 566)

        if not phoneFrame:IsShown() then
            phoneFrame:Show()
        end
        -- Auto-open conversation if none active
        if not active then
            selectContact(sender)
        elseif active == sender then
            renderChat()
        end
        updateContactList()

    ------------------------------------------------------------
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local msg, target = ...
        target = stripRealm(target)

        -- Skip if already added optimistically from doSend()
        if pendingOut[target] and pendingOut[target][msg] and pendingOut[target][msg] > 0 then
            pendingOut[target][msg] = pendingOut[target][msg] - 1
            if pendingOut[target][msg] == 0 then pendingOut[target][msg] = nil end
            return
        end

        -- External whisper (sent from default chat box)
        pushMessage(target, msg, true)
        if not phoneFrame:IsShown() then phoneFrame:Show() end
        if not active then
            selectContact(target)
        elseif active == target then
            renderChat()
        end
        updateContactList()
    end
end)

--------------------------------------------------------------------------------
-- SLASH COMMANDS
--------------------------------------------------------------------------------
SLASH_WISPCHAT1 = "/wispchat"
SLASH_WISPCHAT2 = "/wc"
SlashCmdList["WISPCHAT"] = function(msg)
    if not phoneFrame then
        print("|cffff4444WispApp:|r El addon aún no ha terminado de cargar.")
        return
    end
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if msg == "" then
        if phoneFrame:IsShown() then phoneFrame:Hide() else phoneFrame:Show() end
    elseif msg == "reset" then
        phoneFrame:ClearAllPoints()
        phoneFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
        WispChatDB.x, WispChatDB.y = nil, nil
        print("|cff25d366WispApp:|r Posición reseteada.")
    else
        print("|cff25d366WispApp|r - Comandos:")
        print("  |cffffcc00/wispchat|r o |cffffcc00/wc|r — Abrir/cerrar")
        print("  |cffffcc00/wc reset|r — Resetear posición")
    end
end
