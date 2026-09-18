local ADDON_NAME, ns = ...

-- ============================================================
--  WispChat v1.1 — Entry Point & Slash Commands
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

SLASH_WISPCHAT1 = "/wispchat"
SLASH_WISPCHAT2 = "/wc"
SlashCmdList["WISPCHAT"] = function(msg)
    if msg == "reset" then
        WispChatDB = {}
        ReloadUI()
    elseif msg == "combat on" then
        if WispChatDB.settings then
            WispChatDB.settings.hideInCombat = true
            print("|cff25d366WispChat:|r Auto-ocultar en combate ACTIVADO.")
        end
    elseif msg == "combat off" then
        if WispChatDB.settings then
            WispChatDB.settings.hideInCombat = false
            print("|cff25d366WispChat:|r Auto-ocultar en combate DESACTIVADO.")
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
