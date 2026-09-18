local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Minimap â€” Button + Badge (v1.1)
--  WoW Forever / Midnight Â· Build 12.1.0 (120100)
-- ============================================================

local mmBtn, mmBadge, mmBadgeText

--------------------------------------------------------------------------------
-- UPDATE MINIMAP BADGE & ANIMATION
--------------------------------------------------------------------------------
function ns.doShake()
    if WispCraftDB.settings and not WispCraftDB.settings.playShake then return end
    if not mmBtn then return end
    
    if not ns.mmShakeAnim then
        ns.mmShakeAnim = mmBtn:CreateAnimationGroup()
        local a1 = ns.mmShakeAnim:CreateAnimation("Translation")
        a1:SetOffset(4, 0); a1:SetDuration(0.05); a1:SetOrder(1)
        local a2 = ns.mmShakeAnim:CreateAnimation("Translation")
        a2:SetOffset(-8, 0); a2:SetDuration(0.05); a2:SetOrder(2)
        local a3 = ns.mmShakeAnim:CreateAnimation("Translation")
        a3:SetOffset(8, 0); a3:SetDuration(0.05); a3:SetOrder(3)
        local a4 = ns.mmShakeAnim:CreateAnimation("Translation")
        a4:SetOffset(-4, 0); a4:SetDuration(0.05); a4:SetOrder(4)
    end
    if not ns.mmShakeAnim:IsPlaying() then
        ns.mmShakeAnim:Play()
    end
end

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
    iconTxt:SetAllPoints(); iconTxt:SetText("W")

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



