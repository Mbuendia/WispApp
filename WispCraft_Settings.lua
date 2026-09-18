local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Settings â€” Config UI (v1.2)
-- ============================================================

function ns.initSettings()
    WispCraftDB = WispCraftDB or {}
    WispCraftDB.settings = WispCraftDB.settings or {
        hideInCombat = false,
        playSounds   = true,
        startPeeked  = false,
        playShake    = true,
        enableP2P    = true,
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
    f:SetSize(350, 420)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ns.U(ns.C.phone, 0.85)); f:SetFrameLevel(100)
    f:Hide()
    
    f.TitleText:SetText("WispCraft Settings")
    
    createCheckbox(f, "Auto-ocultar en combate", "hideInCombat", -40)
    createCheckbox(f, "Reproducir sonidos", "playSounds", -70)
    createCheckbox(f, "Iniciar en modo Peek", "startPeeked", -100)
    createCheckbox(f, "Animar minimapa", "playShake", -130)
    createCheckbox(f, "Habilitar P2P", "enableP2P", -160)
    
    -- Templates Section
    local tl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tl:SetPoint("TOPLEFT", 20, -190)
    tl:SetText("Plantillas de respuesta rÃ¡pida (:: o /)")

    f.templateRows = {}
    
    local function updateTemplatesUI()
        local templates = ns.getTemplates()
        for _, row in ipairs(f.templateRows) do row:Hide() end
        
        local y = -210
        for i, text in ipairs(templates) do
            local row = f.templateRows[i]
            if not row then
                row = CreateFrame("Frame", nil, f)
                row:SetSize(300, 25)
                
                local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                txt:SetPoint("LEFT", 0, 0)
                txt:SetWidth(250)
                txt:SetJustifyH("LEFT")
                row.txt = txt
                
                local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                del:SetSize(40, 20)
                del:SetPoint("RIGHT", 0, 0)
                del:SetText("Del")
                del:SetScript("OnClick", function()
                    ns.removeTemplate(i)
                    updateTemplatesUI()
                end)
                
                f.templateRows[i] = row
            end
            row.txt:SetText(text)
            row:SetPoint("TOPLEFT", 20, y)
            row:Show()
            y = y - 25
        end
    end

    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(200, 20)
    addBox:SetPoint("BOTTOMLEFT", 25, 20)
    addBox:SetAutoFocus(false)
    
    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        local txt = addBox:GetText()
        if txt and txt ~= "" then
            ns.addTemplate(txt)
            addBox:SetText("")
            updateTemplatesUI()
        end
    end)
    
    f:SetScript("OnShow", function()
        updateTemplatesUI()
    end)
    
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



