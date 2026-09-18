local ADDON_NAME, ns = ...

-- ============================================================
--  WispChat Core — State, Constants, Theme & Helpers
--  WoW Forever / Midnight · Build 12.1.0 (120100)
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

function ns.U(t, a) return t[1], t[2], t[3], a or 1 end

function ns.BG(f, t, a)
    local tx = f:CreateTexture(nil, "BACKGROUND")
    tx:SetAllPoints(); tx:SetColorTexture(ns.U(t, a))
    return tx
end

--------------------------------------------------------------------------------
-- SAVED STATE
--------------------------------------------------------------------------------
WispChatDB = WispChatDB or {}

ns.convos      = {}
ns.unread      = {}
ns.contacts    = {}
ns.active      = nil
ns.bubbles     = {}
ns.pendingOut  = {}

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

function ns.pushMessage(contact, msg, isOut)
    ns.ensureConvo(contact)
    table.insert(ns.convos[contact], {msg=msg, ts=ns.ts(), out=isOut})
    ns.promoteContact(contact)
    if contact ~= ns.active then
        ns.unread[contact] = (ns.unread[contact] or 0) + 1
    end
    if ns.updateMinimapBadge then ns.updateMinimapBadge() end
end

function ns.getTotalUnread()
    local total = 0
    for _, count in pairs(ns.unread) do
        total = total + count
    end
    return total
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
