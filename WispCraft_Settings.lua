local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Settings — Config UI (v1.2)
-- ============================================================

function ns.initSettings()
    WispCraftDB = WispCraftDB or {}
    WispCraftDB.settings = WispCraftDB.settings or {
        hideInCombat = false,
        playSounds   = true,
        startPeeked  = false,
    }
    WispCraftDB.notes = WispCraftDB.notes or {}
    WispCraftDB.muted = WispCraftDB.muted or {}
end

local function createCheckbox(parent, label, key, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    cb.Text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.Text:SetPoint("LEFT", cb, "RIGHT", 5, 1)
    cb.Text:SetText(label)
    
    cb:SetScript("OnShow", function(self)
        if WispCraftDB.settings then
            self:SetChecked(WispCraftDB.settings[key])
        end
    end)
    
    cb:SetScript("OnClick", function(self)
        if WispCraftDB.settings then
            WispCraftDB.settings[key] = self:GetChecked()
        end
    end)
    
    return cb
end

local function buildConfigFrame()
    local f = CreateFrame("Frame", "WispCraftConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(300, 250)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    
    f.TitleText:SetText("WispCraft Settings")
    
    createCheckbox(f, "Auto-ocultar en combate", "hideInCombat", -40)
    createCheckbox(f, "Reproducir sonidos", "playSounds", -80)
    createCheckbox(f, "Iniciar en modo Peek", "startPeeked", -120)
    
    ns.configFrame = f
end

function ns.toggleConfig()
    if not ns.configFrame then
        buildConfigFrame()
    end
    
    if ns.configFrame:IsShown() then
        ns.configFrame:Hide()
    else
        ns.configFrame:Show()
    end
end
