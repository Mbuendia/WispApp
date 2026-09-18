local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Minimap — Button + Badge (v1.1)
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

local mmBtn, mmBadge, mmBadgeText

--------------------------------------------------------------------------------
-- UPDATE MINIMAP BADGE
--------------------------------------------------------------------------------
function ns.updateMinimapBadge()
    if not mmBadge then return end
    local total = ns.getTotalUnread()
    if total > 0 then
        mmBadgeText:SetText(total > 9 and "9+" or tostring(total))
        mmBadge:Show()
    else
        mmBadge:Hide()
    end
    -- Also update peek bar if in peek mode
    if ns.peekMode and ns.peekBadgeText then
        if total > 0 then
            ns.peekBadgeText:SetText("|cff25d366Wisp|r|cffffffffApp|r  |cffff4444" .. total .. "|r")
        else
            ns.peekBadgeText:SetText("|cff25d366Wisp|r|cffffffffApp|r")
        end
    end
end

--------------------------------------------------------------------------------
-- BUILD MINIMAP BUTTON
--------------------------------------------------------------------------------
function ns.buildMinimapButton()
    mmBtn = CreateFrame("Button", "WispCraftMMButton", Minimap)
    mmBtn:SetSize(26, 26)
    mmBtn:SetFrameStrata("MEDIUM")
    mmBtn:SetFrameLevel(8)

    local iconBG = mmBtn:CreateTexture(nil, "BACKGROUND")
    iconBG:SetAllPoints(); iconBG:SetColorTexture(ns.U(ns.C.hdr))

    local iconTxt = mmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iconTxt:SetAllPoints(); iconTxt:SetText("💬")

    -- Position on minimap edge
    local angle = math.rad(220)
    local radius = 82
    mmBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)

    -- Badge (red circle with unread count)
    mmBadge = CreateFrame("Frame", nil, mmBtn)
    mmBadge:SetSize(16, 16)
    mmBadge:SetPoint("TOPRIGHT", mmBtn, "TOPRIGHT", 4, 4)
    mmBadge:SetFrameLevel(mmBtn:GetFrameLevel() + 1)

    local badgeBG = mmBadge:CreateTexture(nil, "BACKGROUND")
    badgeBG:SetAllPoints()
    badgeBG:SetColorTexture(ns.U(ns.C.red))

    mmBadgeText = mmBadge:CreateFontString(nil, "OVERLAY")
    mmBadgeText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    mmBadgeText:SetAllPoints()
    mmBadgeText:SetJustifyH("CENTER")
    mmBadgeText:SetJustifyV("MIDDLE")
    mmBadgeText:SetTextColor(1, 1, 1, 1)
    mmBadge:Hide()

    -- Click handler
    mmBtn:SetScript("OnClick", function()
        if ns.phoneFrame then
            if ns.peekMode then
                -- Expand from peek
                ns.setPeekMode(false)
            elseif ns.phoneFrame:IsShown() then
                -- Collapse to peek
                ns.setPeekMode(true)
            else
                -- Show phone
                ns.phoneFrame:Show()
                if ns.peekBar then ns.peekBar:Hide() end
                ns.peekMode = false
            end
        end
    end)

    -- Tooltip
    mmBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff25d366WispCraft|r")
        GameTooltip:AddLine("Clic para abrir/cerrar", 0.8, 0.8, 0.8)
        local total = ns.getTotalUnread()
        if total > 0 then
            GameTooltip:AddLine(total .. " mensaje(s) sin leer", 0.9, 0.2, 0.2)
        end
        GameTooltip:Show()
    end)
    mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
