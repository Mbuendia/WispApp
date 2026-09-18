local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft v1.1 â€” Entry Point & Slash Commands
--  WoW Forever / Midnight Â· Build 12.1.0 (120100)
-- ============================================================

SLASH_WispCraft1 = "/WispCraft"
SLASH_WispCraft2 = "/wc"
SlashCmdList["WispCraft"] = function(msg)
    if msg == "config" or msg == "settings" then
        if ns.toggleConfig then ns.toggleConfig() end
    elseif msg == "reset" then
        WispCraftDB = {}
        ReloadUI()
    elseif msg == "combat on" then
        if WispCraftDB.settings then
            WispCraftDB.settings.hideInCombat = true
            print("|cff25d366WispCraft:|r Auto-ocultar en combate ACTIVADO.")
        end
    elseif msg == "combat off" then
        if WispCraftDB.settings then
            WispCraftDB.settings.hideInCombat = false
            print("|cff25d366WispCraft:|r Auto-ocultar en combate DESACTIVADO.")
        end
    else
        if ns.phoneFrame then
            if ns.peekMode then
                ns.setPeekMode(false)
            elseif ns.phoneFrame:IsShown() then
                ns.setPeekMode(true)
            else
                ns.phoneFrame:Show()
                ns.peekMode = false
                if ns.peekBar then ns.peekBar:Hide() end
            end
        end
end
end

hooksecurefunc("ChatEdit_InsertLink", function(text)
    if ns.inputBox and ns.inputBox:IsVisible() and ns.inputBox:HasFocus() then
        ns.inputBox:Insert(text)
        return true
    end
end)

