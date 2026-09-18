local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft v1.1 — Entry Point & Slash Commands
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

SLASH_WispCraft1 = "/WispCraft"
SLASH_WispCraft2 = "/wc"
SlashCmdList["WispCraft"] = function(msg)
    if msg == "reset" then
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
