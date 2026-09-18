local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Core â€” State, Constants, Theme & Helpers
--  WoW Forever / Midnight Â· Build 12.1.0 (120100)
-- ============================================================

--------------------------------------------------------------------------------
-- CONSTANTS & THEME
--------------------------------------------------------------------------------
ns.PW      = 390    -- phone width
ns.PH      = 570    -- phone height
ns.SW      = 135    -- sidebar width
ns.HH      = 52     -- header height
ns.IH      = 50     -- input area height
ns.STATUS_H = 22    -- top fake status bar
ns.BMAX    = 155    -- max bubble width
ns.BPAD    = 9      -- bubble inner padding
ns.ROW_H   = 66     -- contact row height

-- WhatsApp dark palette
ns.C = {
    phone    = {0.050, 0.050, 0.070},
    screen   = {0.071, 0.122, 0.153},
    hdr      = {0.071, 0.561, 0.380},
    hdrDark  = {0.044, 0.400, 0.267},
    sidebar  = {0.053, 0.067, 0.082},
    sidHov   = {0.100, 0.150, 0.180},
    sidSel   = {0.133, 0.196, 0.220},
    divider  = {0.100, 0.150, 0.180},
    bIn      = {0.133, 0.196, 0.220},
    bOut     = {0.071, 0.361, 0.249},
    inputBG  = {0.082, 0.133, 0.161},
    topbar   = {0.030, 0.030, 0.040},
    white    = {1.000, 1.000, 1.000},
    lgray    = {0.650, 0.650, 0.650},
    dgray    = {0.380, 0.380, 0.380},
    green    = {0.145, 0.855, 0.561},
    badge    = {0.071, 0.561, 0.380},
    red      = {0.800, 0.100, 0.100},
}

--------------------------------------------------------------------------------
-- DYNAMIC THEME (FACTION BASED)
--------------------------------------------------------------------------------
function ns.initFactionTheme()
    local faction = UnitFactionGroup("player")
    if faction == "Horde" then
        -- Official Horde Red but dark enough for white text accessibility
        ns.C.screen   = {0.08, 0.08, 0.08}
        ns.C.phone    = {0.05, 0.05, 0.05}
        ns.C.hdr      = {0.55, 0.09, 0.09} -- #8C1616 Horde Red
        ns.C.hdrDark  = {0.40, 0.06, 0.06}
        ns.C.bOut     = {0.40, 0.06, 0.06} -- Red outgoing bubbles
        ns.C.bIn      = {0.15, 0.15, 0.15}
        ns.C.sidebar  = {0.06, 0.06, 0.06}
        ns.C.sidHov   = {0.15, 0.05, 0.05}
        ns.C.sidSel   = {0.25, 0.05, 0.05}
        ns.C.accent   = {0.90, 0.10, 0.10}
    else
        -- Official Alliance Blue but dark enough for white text accessibility
        ns.C.screen   = {0.05, 0.07, 0.10}
        ns.C.phone    = {0.03, 0.04, 0.06}
        ns.C.hdr      = {0.00, 0.29, 0.58} -- #004a93 Alliance Blue
        ns.C.hdrDark  = {0.00, 0.16, 0.35}
        ns.C.bOut     = {0.00, 0.29, 0.58} -- Blue outgoing bubbles
        ns.C.bIn      = {0.10, 0.14, 0.20}
        ns.C.sidebar  = {0.04, 0.05, 0.07}
        ns.C.sidHov   = {0.00, 0.15, 0.30}
        ns.C.sidSel   = {0.00, 0.20, 0.45}
        ns.C.accent   = {0.94, 0.76, 0.05} -- Gold
    end
end

function ns.U(t, a) return t[1], t[2], t[3], a or 1 end

function ns.BG(f, t, a)
    local tx = f:CreateTexture(nil, "BACKGROUND")
    tx:SetAllPoints(); tx:SetColorTexture(ns.U(t, a))
    return tx
end

--------------------------------------------------------------------------------
-- SAVED STATE
--------------------------------------------------------------------------------
WispCraftDB = WispCraftDB or {}

ns.convos      = {}
ns.unread      = {}
ns.contacts    = {}
ns.contactStatus = {}
ns.active      = nil
ns.bubbles     = {}
ns.pendingOut  = {}

function ns.setContactStatus(name, status)
    ns.contactStatus[name] = status
    if ns.updateContactList then ns.updateContactList() end
    if ns.active == name then
        if ns.selectContact then ns.selectContact(ns.active) end
    end
end

function ns.toggleMute(name)
    WispCraftDB.muted = WispCraftDB.muted or {}
    WispCraftDB.muted[name] = not WispCraftDB.muted[name]
    if WispCraftDB.muted[name] then
        ns.unread[name] = 0
    end
    if ns.updateContactList then ns.updateContactList() end
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

function ns.deleteConvo(name)
    ns.convos[name] = nil
    ns.unread[name] = nil
    ns.contactStatus[name] = nil
    for i, n in ipairs(ns.contacts) do
        if n == name then
            table.remove(ns.contacts, i)
            break
        end
    end
    if ns.active == name then
        ns.active = nil
        ns.headerName:SetText("NingÃºn Wisp")
        ns.hdrStatus:SetText("selecciona un contacto")
        ns.hdrAvatarLetter:SetText("?")
        ns.inputBox:Disable()
        ns.sendBtn:Disable()
        ns.noConvLabel:Show()
        ns.renderChat()
    end
    if ns.updateContactList then ns.updateContactList() end
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

function ns.initTemplates()
    WispCraftDB = WispCraftDB or {}
    WispCraftDB.templates = WispCraftDB.templates or {"Ahora voy", "En combate"}
end

function ns.getTemplates()
    if not WispCraftDB.templates then ns.initTemplates() end
    return WispCraftDB.templates
end

function ns.addTemplate(text)
    if not WispCraftDB.templates then ns.initTemplates() end
    table.insert(WispCraftDB.templates, text)
end

function ns.removeTemplate(idx)
    if not WispCraftDB.templates then ns.initTemplates() end
    if WispCraftDB.templates[idx] then
        table.remove(WispCraftDB.templates, idx)
    end
end


function ns.setNote(name, note)
    WispCraftDB.notes = WispCraftDB.notes or {}
    if note == "" then note = nil end
    WispCraftDB.notes[name] = note
    if ns.updateContactList then ns.updateContactList() end
end

-- v1.1 state
ns.peekMode    = false
ns.wasVisible  = false

--------------------------------------------------------------------------------
-- FRAME REFERENCES (populated by UI module)
--------------------------------------------------------------------------------
ns.phoneFrame       = nil
ns.sidebarFrame     = nil
ns.chatPanel        = nil
ns.scrollFrame      = nil
ns.contentFrame     = nil
ns.headerName       = nil
ns.hdrAvatarLetter  = nil
ns.hdrStatus        = nil
ns.inputBox         = nil
ns.sendBtn          = nil
ns.contactListFrame = nil
ns.contactRows      = nil
ns.noConvLabel      = nil

-- v1.1 frame references
ns.peekBar          = nil
ns.peekBadgeText    = nil

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
function ns.ts() return date("%H:%M") end
function ns.me() return UnitName("player") or "You" end

function ns.stripRealm(name)
    return (name or ""):match("^([^%-]+)") or name
end

function ns.avatarColor(name)
    local h = 0
    for i = 1, #name do h = h + name:byte(i) end
    local hue = (h % 12) / 12
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

function ns.promoteContact(name)
    for i, n in ipairs(ns.contacts) do
        if n == name then table.remove(ns.contacts, i); break end
    end
    table.insert(ns.contacts, 1, name)
end

function ns.ensureConvo(name)
    if not ns.convos[name] then
        ns.convos[name] = {}; ns.unread[name] = 0
        table.insert(ns.contacts, 1, name)
    end
end

ns.wispPeers = {}
ns.isTyping = {}

function ns.sendP2P(target, action, payload)
    if WispCraftDB.settings and not WispCraftDB.settings.enableP2P then return end
    C_ChatInfo.SendAddonMessage("WISPCRAFT", action .. (payload and (":"..payload) or ""), "WHISPER", target)
end

function ns.pushMessage(contact, msg, isOut)
    ns.ensureConvo(contact)
    table.insert(ns.convos[contact], {msg=msg, ts=ns.ts(), out=isOut, read=false})
    ns.promoteContact(contact)
    if contact ~= ns.active then
        local muted = WispCraftDB.muted and WispCraftDB.muted[contact]
        if not muted then
            ns.unread[contact] = (ns.unread[contact] or 0) + 1
        end
    end
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

function ns.getTotalUnread()
    local total = 0
    for name, count in pairs(ns.unread) do
        local muted = WispCraftDB.muted and WispCraftDB.muted[name]
        if not muted then
            total = total + count
        end
    end
    return total
end

--------------------------------------------------------------------------------
-- GPS & PARSING HELPERS
--------------------------------------------------------------------------------
function ns.shareLocation()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            local info = C_Map.GetMapInfo(mapID)
            if pos and info then
                local x = math.floor(pos.x * 10000) / 100
                local y = math.floor(pos.y * 10000) / 100
                return string.format("[GPS: %s %s %s]", info.name, x, y)
            end
        end
    end
    return "[GPS: Ubicacion desconocida]"
end

--------------------------------------------------------------------------------
-- TEXT MEASUREMENT HELPER
--------------------------------------------------------------------------------
local _mF = CreateFrame("Frame", nil, UIParent)
_mF:SetSize(ns.BMAX - ns.BPAD*2, 400); _mF:Hide()
local _mT = _mF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
_mT:SetAllPoints(); _mT:SetWordWrap(true); _mT:SetJustifyH("LEFT")

function ns.measureH(text, w)
    _mT:SetWidth(w - ns.BPAD*2); _mT:SetText(text)
    return _mT:GetStringHeight()
end

function ns.measureW(text, maxW)
    _mT:SetWidth(maxW - ns.BPAD*2); _mT:SetText(text)
    return math.min(_mT:GetStringWidth() + ns.BPAD*2 + 6, maxW)
end



