local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Events — Listeners for Whispers & Combat (v1.1)
--  WoW Forever / Midnight · Build 12.1.0 (120100)
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

-- v1.1: Combat detection
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- v1.2: AFK/DND detection
eventFrame:RegisterEvent("CHAT_MSG_AFK")
eventFrame:RegisterEvent("CHAT_MSG_DND")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "WispCraft" then
            if ns.initSettings then ns.initSettings() end
            if ns.initTemplates then ns.initTemplates() end
            ns.buildUI()
            ns.buildMinimapButton()
            if WispCraftDB.settings and WispCraftDB.settings.startPeeked then
                ns.setPeekMode(true)
            end
            print("|cff25d366WispCraft v1.2|r loaded. Type /wc to open.")
        end

    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local name = ns.stripRealm(sender)
        ns.pushMessage(name, msg, false)

        -- Play standard whisper sound
        local muted = WispCraftDB.muted and WispCraftDB.muted[name]
        if not muted and WispCraftDB.settings and WispCraftDB.settings.playSounds then
            PlaySound(SOUNDKIT and SOUNDKIT.IG_CHAT_WHISPER_NOTIFY or 566)
        end

        -- Update UI if it's the active conversation
        if ns.active and ns.contacts[ns.active] == name then
            ns.unread[name] = 0 -- Mark read
            if ns.renderChat then ns.renderChat() end
        end
        if ns.updateContactList then ns.updateContactList() end

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local msg, target = ...
        local name = ns.stripRealm(target)
        
        -- Dedup optimistic messages
        if ns.pendingOut[name] and ns.pendingOut[name][msg] then
            ns.pendingOut[name][msg] = nil
        else
            ns.pushMessage(name, msg, true)
            if ns.active and ns.contacts[ns.active] == name then
                if ns.renderChat then ns.renderChat() end
            end
            if ns.updateContactList then ns.updateContactList() end
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        if WispCraftDB.settings and WispCraftDB.settings.hideInCombat then
            ns.wasVisible = ns.phoneFrame and ns.phoneFrame:IsShown() and not ns.peekMode
            if ns.wasVisible then
                ns.setPeekMode(true)
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        if WispCraftDB.settings and WispCraftDB.settings.hideInCombat then
            if ns.wasVisible then
                ns.setPeekMode(false)
                ns.wasVisible = false
            end
        end

    elseif event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then
        local msg, sender = ...
        local name = ns.stripRealm(sender)
        local status = (event == "CHAT_MSG_AFK") and "AFK" or "DND"
        ns.setContactStatus(name, status)
    end
end)
