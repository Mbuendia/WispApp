local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft UI â€” Main Window, Sidebar, Bubbles & Peek (v1.1)
--  WoW Forever / Midnight Â· Build 12.1.0 (120100)
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

local function newBubble(m, lastY)
    local text, tsStr, isOut, isRead = m.msg, m.ts, m.out, m.read
    local w = ns.measureW(text, ns.BMAX)
    local h = ns.measureH(text, w) + 18

    local b = CreateFrame("Button", nil, ns.contentFrame, "BackdropTemplate")
    b.rawText = text
    b:SetScript("OnClick", function(self)
        local t = self.rawText
        if t:match("wowhead%.com") then
            local url = t:match("(https?://[%w_.~!*:@&+$/?%%#-]+)")
            if url then
                local dialog = StaticPopup_Show("WISPCRAFT_COPY_URL")
                if dialog then dialog.data = url end
            end
        elseif t:match("%[GPS:(%d+):([%d%.]+):([%d%.]+)%]") or t:match("%[GPS: (.-) ([%d%.]+) ([%d%.]+)%]") then
            local mapID, x, y, zone
            if t:match("%[GPS:(%d+):([%d%.]+):([%d%.]+)%]") then
                mapID, x, y = t:match("%[GPS:(%d+):([%d%.]+):([%d%.]+)%]")
                zone = ""
            else
                zone, x, y = t:match("%[GPS: (.-) ([%d%.]+) ([%d%.]+)%]")
                mapID = C_Map and C_Map.GetBestMapForUnit("player")
            end
            
            if SlashCmdList["TOMTOM_WAY"] then
                if zone ~= "" then
                    SlashCmdList["TOMTOM_WAY"](string.format("%s %s %s", zone, x, y))
                else
                    SlashCmdList["TOMTOM_WAY"](string.format("%s %s", x, y))
                end
            elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint and mapID then
                local pt = UiMapPoint.CreateFromCoordinates(tonumber(mapID), tonumber(x)/100, tonumber(y)/100)
                C_Map.SetUserWaypoint(pt)
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                print("|cff53bdeb[WispCraft]|r Marcador de mapa anadido en " .. x .. ", " .. y)
            else
                print("|cff53bdeb[WispCraft]|r Coordenadas: " .. x .. ", " .. y)
            end
        end
    end)
    
    -- Animations
    b.anim = b:CreateAnimationGroup()
    local slide = b.anim:CreateAnimation("Translation")
    slide:SetOffset(0, 15)
    slide:SetDuration(0)
    slide:SetOrder(1)
    
    local slideIn = b.anim:CreateAnimation("Translation")
    slideIn:SetOffset(0, -15)
    slideIn:SetSmoothing("OUT")
    slideIn:SetDuration(0.2)
    slideIn:SetOrder(2)
    
    local fade = b.anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.2)
    fade:SetOrder(2)
    
    b.anim:Play()
    b:SetSize(w, h)
    b:SetPoint("TOP", ns.contentFrame, "TOP", 0, lastY)
    if isOut then b:SetPoint("RIGHT", -ns.BPAD, 0)
    else          b:SetPoint("LEFT", ns.BPAD, 0) end

    b:SetSize(w, h + 8)

    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left=0, right=0, top=0, bottom=0}
    })
    b:SetBackdropColor(ns.U(isOut and ns.C.bOut or ns.C.bIn))
    b:SetBackdropBorderColor(0,0,0, 0.4)

    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("TOPLEFT", ns.BPAD, -8)
    txt:SetPoint("BOTTOMRIGHT", -ns.BPAD, 16)
    txt:SetJustifyH("LEFT"); txt:SetJustifyV("TOP")
    txt:SetText(text); txt:SetTextColor(1,1,1)

    local ts = b:CreateFontString(nil, "OVERLAY")
    ts:SetFont("Fonts\\FRIZQT__.TTF", 8)
    ts:SetPoint("BOTTOMRIGHT", -8, 6)
    if isOut then
        local color = isRead and "ff53bdeb" or "ff25d366"
        ts:SetText(tsStr .. " |c" .. color .. "âœ“âœ“|r")
    else
        ts:SetText(tsStr)
    end
    ts:SetTextColor(0.6,0.6,0.6)

    table.insert(ns.bubbles, b)
    return h
end

function ns.renderChat()
    clearBubbles()
    if not ns.active then return end
    local c = ns.convos[ns.active]
    local y = -10
    for _, m in ipairs(c) do
        local bh = newBubble(m, y)
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
    r:SetScript("OnLeave", function() local currentName = ns.contacts[idx]; bg:SetColorTexture(ns.U(ns.active==currentName and ns.C.sidSel or ns.C.sidebar)) end)

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

    r:RegisterForClicks("AnyUp")
    r:SetScript("OnClick", function(self, button)
        local contactName = ns.contacts[idx]
        if button == "RightButton" then
            if ns.showContextMenu then ns.showContextMenu(contactName, self) end
        else
            ns.selectContact(contactName)
        end
    end)

    local noteT = r:CreateFontString(nil, "OVERLAY")
    noteT:SetFont("Fonts\\FRIZQT__.TTF", 9)
    noteT:SetPoint("TOPLEFT", pT, "BOTTOMLEFT", 0, -2)
    noteT:SetWidth(75); noteT:SetJustifyH("LEFT"); noteT:SetTextColor(1, 0.82, 0) -- Gold for note
    noteT:SetWordWrap(false)

    if not ns.contactRows then ns.contactRows = {} end
    ns.contactRows[idx] = {f=r, bg=bg, av=av, avT=avT, nT=nT, pT=pT, tsT=tsT, bF=bF, bT=bT, noteT=noteT}
    return ns.contactRows[idx]
end

function ns.updateContactList()
    if not ns.contactRows then ns.contactRows = {} end
    for i, name in ipairs(ns.contacts) do
        local r = ns.contactRows[i] or buildContactRow(i)
        r.f:Show()
        r.bg:SetColorTexture(ns.U(ns.active==name and ns.C.sidSel or ns.C.sidebar))
        r.av:SetColorTexture(ns.avatarColor(name))
        r.avT:SetText(name:sub(1,1):upper())
        
        local status = ns.contactStatus[name]
        local tag = ""
        if WispCraftDB.muted and WispCraftDB.muted[name] then tag = " ðŸ”‡" end
        if status == "AFK" then tag = tag .. " |cffff8c00[AFK]|r"
        elseif status == "DND" then tag = tag .. " |cffff4444[DND]|r" end
        r.nT:SetText(name .. tag)

        local c = ns.convos[name]
        local last = c[#c]
        if last then
            r.pT:SetText((last.out and "Tu: " or "")..last.msg)
            r.tsT:SetText(last.ts)
        end

        local note = WispCraftDB.notes and WispCraftDB.notes[name]
        if note then
            r.noteT:SetText("* " .. note)
            r.noteT:Show()
        else
            r.noteT:Hide()
        end

        local ur = ns.unread[name]
        if ur and ur > 0 then
            r.bF:Show(); r.bT:SetText(ur > 9 and "9+" or ur)
        else r.bF:Hide() end
    end

    for i = #ns.contacts + 1, #ns.contactRows do
        if ns.contactRows[i] then ns.contactRows[i].f:Hide() end
    end
end

function ns.selectContact(name)
    if not name then return end
    ns.active = name
    ns.unread[name] = 0
    ns.headerName:SetText(name)
    
    local status = ns.contactStatus[name]
    if ns.isTyping[name] then
        ns.hdrStatus:SetText("escribiendo...")
        ns.hdrStatus:SetTextColor(0.145, 0.855, 0.561) -- #25d366
    elseif status == "AFK" then
        ns.hdrStatus:SetText("ðŸŒ™ AFK")
        ns.hdrStatus:SetTextColor(1, 0.55, 0) -- #ff8c00
    elseif status == "DND" then
        ns.hdrStatus:SetText("â›” DND")
        ns.hdrStatus:SetTextColor(1, 0.26, 0.26) -- #ff4444
    elseif ns.wispPeers[name] then
        ns.hdrStatus:SetText("en linea")
        ns.hdrStatus:SetTextColor(0.325, 0.741, 0.922) -- #53bdeb
        if ns.sendP2P then
            ns.sendP2P(name, "HELLO")
            ns.sendP2P(name, "READ")
        end
    else
        ns.hdrStatus:SetText("en linea")
        ns.hdrStatus:SetTextColor(0.145, 0.855, 0.561) -- #25d366
        if ns.sendP2P then ns.sendP2P(name, "HELLO") end
    end
    
    ns.hdrAvatarLetter:SetText(name:sub(1,1):upper())
    if ns.hdrAvatarBG then 
        local cClass = WispCraftDB.classes and WispCraftDB.classes[name]
        if cClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cClass] then
            local rc = RAID_CLASS_COLORS[cClass]
            ns.hdrAvatarBG:SetColorTexture(rc.r, rc.g, rc.b)
        else
            ns.hdrAvatarBG:SetColorTexture(ns.avatarColor(name))
        end
    end
    
    ns.inputBox:Enable(); ns.sendBtn:Enable()
    ns.noConvLabel:Hide()
    ns.updateContactList()
    ns.renderChat()
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

--------------------------------------------------------------------------------
-- CONTEXT MENU
--------------------------------------------------------------------------------

StaticPopupDialogs["WISPCRAFT_COPY_URL"] = {
    text = "Copiar enlace (Ctrl+C):",
    button1 = "Cerrar",
    hasEditBox = true,
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        eb:SetText(self.data or "")
        eb:HighlightText()
        eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["WISPCRAFT_EDIT_NOTE"] = {
    text = "Editar nota para %s:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    OnAccept = function(self, data)
        local eb = self.editBox or self.EditBox
        local text = eb:GetText()
        ns.setNote(data, text)
    end,
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        eb:SetText((WispCraftDB.notes and WispCraftDB.notes[self.data]) or "")
        eb:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self:GetText()
        ns.setNote(self:GetParent().data, text)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function buildContextMenu()
    local f = CreateFrame("Frame", "WispCraftContextMenu", UIParent, "BackdropTemplate")
    f:SetSize(150, 100)
    f:SetFrameStrata("TOOLTIP")
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:Hide()
    
    local function createBtn(idx, text, func)
        local b = CreateFrame("Button", nil, f)
        b:SetSize(130, 20)
        b:SetPoint("TOP", f, "TOP", 0, -10 - ((idx-1)*20))
        
        local tx = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tx:SetPoint("LEFT", 5, 0)
        tx:SetText(text)
        b:SetFontString(tx)
        
        local ht = b:CreateTexture(nil, "HIGHLIGHT")
        ht:SetAllPoints()
        ht:SetColorTexture(1, 1, 1, 0.2)
        
        b:SetScript("OnClick", function()
            func(f.contactName)
            f:Hide()
        end)
        return b
    end
    
    f.btnMute = createBtn(1, "Silenciar", function(name) ns.toggleMute(name) end)
    f.btnNote = createBtn(2, "Editar Nota", function(name)
        local dialog = StaticPopup_Show("WISPCRAFT_EDIT_NOTE", name)
        if dialog then dialog.data = name end
    end)
    f.btnDel = createBtn(3, "Borrar Conv.", function(name) ns.deleteConvo(name) end)
    f.btnCancel = createBtn(4, "Cerrar", function() end)
    
    -- Close when clicking outside
    f:SetScript("OnUpdate", function(self)
        if self:IsShown() and IsMouseButtonDown("LeftButton") then
            if not self:IsMouseOver() then
                self:Hide()
            end
        end
    end)
    
    ns.contextMenu = f
end

function ns.showContextMenu(name, anchorFrame)
    if not name then return end
    if not ns.contextMenu then buildContextMenu() end
    ns.contextMenu.contactName = name
    
    if WispCraftDB.muted and WispCraftDB.muted[name] then
        ns.contextMenu.btnMute:GetFontString():SetText("Desilenciar")
    else
        ns.contextMenu.btnMute:GetFontString():SetText("Silenciar")
    end
    
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    ns.contextMenu:ClearAllPoints()
    ns.contextMenu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x/scale, y/scale)
    ns.contextMenu:Show()
end

--------------------------------------------------------------------------------
-- BUILD UI
--------------------------------------------------------------------------------
function ns.buildUI()
    -- Phone Shell
    local pf = CreateFrame("Frame", "WispCraftPhone", UIParent)
    pf:SetMovable(true)
    pf:SetClampedToScreen(true)
    ns.phoneFrame = pf
    pf:SetSize(ns.PW, ns.PH)
    pf:SetPoint("CENTER")
    pf:SetMovable(true); pf:EnableMouse(true)
    pf:RegisterForDrag("LeftButton")
    pf:SetScript("OnDragStart", pf.StartMoving)
    
    pf:SetResizable(true)
    pf:SetResizeBounds(390, 570, 800, 900)
    
    pf:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        WispCraftDB.width = self:GetWidth()
        WispCraftDB.height = self:GetHeight()
        ns.BMAX = self:GetWidth() * 0.4
        ns.renderChat()
    end)
    
    pf:SetScript("OnSizeChanged", function(self, width, height)
        if ns.contentFrame then
            ns.contentFrame:SetWidth(width - ns.SW - 30)
        end
    end)
    
    pf:SetFrameStrata("DIALOG")
    ns.BG(pf, ns.C.phone)
    pf:Hide()

    -- Status Bar
    local sb = CreateFrame("Frame", nil, pf)
    sb:SetHeight(ns.STATUS_H)
    sb:SetPoint("TOPLEFT")
    sb:SetPoint("TOPRIGHT")
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
    pbT:SetText("WispCraft")
    ns.peekBadgeText = pbT

    pb:SetScript("OnClick", function() ns.setPeekMode(false) end)
    pb:Hide()

    -- Sidebar
    local sd = CreateFrame("Frame", nil, pf)
    ns.sidebarFrame = sd
    sd:SetWidth(ns.SW)
    sd:SetPoint("TOPLEFT", 0, -ns.STATUS_H)
    sd:SetPoint("BOTTOMLEFT")
    ns.BG(sd, ns.C.sidebar)

    local sh = CreateFrame("Frame", nil, sd)
    sh:SetSize(ns.SW, ns.HH)
    sh:SetPoint("TOPLEFT")
    sh:SetPoint("TOPRIGHT")
    ns.BG(sh, ns.C.hdrDark)
    local st = sh:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    st:SetPoint("CENTER", 0, 5); st:SetText("WispCraft")

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
    ch:EnableMouse(true)
    ch:RegisterForDrag("LeftButton")
    ch:SetScript("OnDragStart", function() pf:StartMoving() end)
    ch:SetScript("OnDragStop", function() pf:StopMovingOrSizing() end)
    ch:SetHeight(ns.HH)
    ch:SetPoint("TOPLEFT")
    ch:SetPoint("TOPRIGHT")
    ns.BG(ch, ns.C.hdr)

    local cClose = CreateFrame("Button", nil, ch)
    cClose:SetSize(24, 24)
    cClose:SetPoint("RIGHT", -8, 0)
    local cTx = cClose:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cTx:SetPoint("CENTER")
    cTx:SetText("X")
    cTx:SetTextColor(0.8, 0.8, 0.8)
    cClose:SetScript("OnEnter", function() cTx:SetTextColor(1, 0.2, 0.2) end)
    cClose:SetScript("OnLeave", function() cTx:SetTextColor(0.8, 0.8, 0.8) end)
    cClose:SetScript("OnClick", function() 
        ns.phoneFrame:Hide(); 
        ns.peekBar:Hide(); 
        if WispCraftDB.settings and WispCraftDB.settings.playSounds then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_CLOSE or 850) end
    end)

    local hA = ch:CreateTexture(nil, "ARTWORK")
    ns.hdrAvatarBG = hA
    hA:SetSize(36,36); hA:SetPoint("LEFT", 10, 0); hA:SetColorTexture(0.2,0.3,0.2)
    ns.hdrAvatarLetter = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.hdrAvatarLetter:SetPoint("CENTER", hA, "CENTER")
    ns.hdrAvatarLetter:SetText("?")

    ns.headerName = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ns.headerName:SetPoint("TOPLEFT", hA, "TOPRIGHT", 8, -4)
    ns.headerName:SetText("Ningun Wisp")

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
    ns.noConvLabel:SetText("Los susurros\naparecerÃ¡n aquÃ­.")
    ns.noConvLabel:SetTextColor(0.5,0.5,0.5)

    -- Input
    local ia = CreateFrame("Frame", nil, cp)
    ia:SetHeight(ns.IH)
    ia:SetPoint("BOTTOMLEFT")
    ia:SetPoint("BOTTOMRIGHT")
    ns.BG(ia, ns.C.inputBG)

    ns.inputBox = CreateFrame("EditBox", nil, ia, "InputBoxTemplate")
        local locBtn = CreateFrame("Button", nil, ia)
    locBtn:SetSize(32, 32)
    locBtn:SetPoint("LEFT", 5, 0)
    local locTx = locBtn:CreateFontString(nil, "OVERLAY")
    locTx:SetFont("Fonts\\FRIZQT__.TTF", 16)
    locTx:SetPoint("CENTER")
    locTx:Hide(); local locTex = locBtn:CreateTexture(nil, "ARTWORK"); locTex:SetAllPoints(); locTex:SetTexture("Interface\\\\Icons\\\\INV_Misc_Map02")
    locBtn:SetScript("OnClick", function()
        if ns.active then
            local loc = ns.shareLocation()
            ns.inputBox:Insert(loc .. " ")
            ns.inputBox:SetFocus()
        end
    end)
    ns.inputBox:SetPoint("LEFT", 40, 0); ns.inputBox:SetPoint("RIGHT", -45, 0)
    ns.inputBox:SetHeight(32); ns.inputBox:SetAutoFocus(false)
    ns.inputBox:SetFontObject("ChatFontNormal")
    ns.inputBox:Disable()

    ns.sendBtn = CreateFrame("Button", nil, ia)
    ns.sendBtn:SetSize(32,32); ns.sendBtn:SetPoint("RIGHT", -8, 0)
    ns.BG(ns.sendBtn, ns.C.hdr)
    local sTx = ns.sendBtn:CreateTexture(nil, "ARTWORK")
    sTx:SetSize(16,16)
    sTx:SetPoint("CENTER")
    sTx:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    ns.sendBtn:Disable()

    -- Resize Handle
    local rb = CreateFrame("Button", nil, pf)
    rb:SetSize(16, 16)
    rb:SetPoint("BOTTOMRIGHT", 0, 0)
    rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    rb:SetScript("OnMouseDown", function() pf:StartSizing("BOTTOMRIGHT") end)
    rb:SetScript("OnMouseUp", function() 
        pf:StopMovingOrSizing()
        WispCraftDB.width = pf:GetWidth()
        WispCraftDB.height = pf:GetHeight()
        ns.BMAX = pf:GetWidth() * 0.4
        ns.renderChat()
    end)

    local function doSend()
        local text = ns.inputBox:GetText()
        if text:len() > 0 and ns.active then
            local target = ns.active
            if not ns.pendingOut[target] then ns.pendingOut[target] = {} end
            ns.pendingOut[target][text] = true
            
            SendChatMessage(text, "WHISPER", nil, target)
            ns.pushMessage(target, text, true)
            ns.inputBox:SetText("")
            ns.renderChat()
            ns.updateContactList()
        end
    end

    local function buildQuickReplyPopup(parent)
        local popup = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        popup:SetSize(200, 150)
        popup:SetPoint("BOTTOMLEFT", ns.inputBox, "TOPLEFT", -5, 5)
        popup:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.9)
        popup:SetFrameStrata("DIALOG")
        popup:Hide()

        popup.buttons = {}
        ns.quickReplyPopup = popup

        function popup:Update()
            local templates = ns.getTemplates and ns.getTemplates() or {}
            for _, b in ipairs(self.buttons) do b:Hide() end
            
            local h = 10
            for i, text in ipairs(templates) do
                local btn = self.buttons[i]
                if not btn then
                    btn = CreateFrame("Button", nil, self)
                    btn:SetSize(180, 20)
                    btn:SetPoint("TOP", self, "TOP", 0, -h)
                    
                    local tx = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    tx:SetPoint("LEFT", 5, 0)
                    tx:SetJustifyH("LEFT")
                    tx:SetWidth(170)
                    tx:SetWordWrap(false)
                    btn:SetFontString(tx)
                    
                    local ht = btn:CreateTexture(nil, "HIGHLIGHT")
                    ht:SetAllPoints()
                    ht:SetColorTexture(1, 1, 1, 0.2)
                    
                    btn:SetScript("OnClick", function()
                        ns.inputBox:SetText(text)
                        self:Hide()
                    end)
                    self.buttons[i] = btn
                end
                btn:SetText(text)
                btn:SetPoint("TOP", self, "TOP", 0, -h)
                btn:Show()
                h = h + 20
            end
            self:SetHeight(math.max(h + 10, 30))
        end
    end

    ns.lastTypingState = false
    ns.inputBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local text = self:GetText()
            if text:sub(1,2) == "::" or text:sub(1,1) == "/" then
                if not ns.quickReplyPopup then buildQuickReplyPopup(cp) end
                ns.quickReplyPopup:Update()
                ns.quickReplyPopup:Show()
            elseif ns.quickReplyPopup then
                ns.quickReplyPopup:Hide()
            end
            
            if ns.active and ns.sendP2P then
                local target = ns.active
                local isTyping = text:len() > 0
                if isTyping ~= ns.lastTypingState then
                    ns.lastTypingState = isTyping
                    ns.sendP2P(target, isTyping and "TYPING" or "STOPPED")
                end
            end
        end
    end)

    ns.sendBtn:SetScript("OnClick", doSend)
    ns.inputBox:SetScript("OnEnterPressed", doSend)
    ns.inputBox:SetScript("OnEscapePressed", function() ns.inputBox:ClearFocus() end)
end

local oldSetPeekMode = ns.setPeekMode
function ns.setPeekMode(enable)
    if WispCraftDB.settings and WispCraftDB.settings.playSounds then
        if enable then
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_CLOSE or 850)
        else
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN or 850)
        end
    end
    oldSetPeekMode(enable)
end



















