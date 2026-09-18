local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Events â€” Listeners for Whispers & Combat (v1.1)
--  WoW Forever / Midnight Â· Build 12.1.0 (120100)
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

-- v1.6: P2P
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "WispCraft" then
            if ns.initFactionTheme then ns.initFactionTheme() end
            
            -- Hide default whisper tabs/frames
            local function hideWisp() return true end
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", hideWisp)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", hideWisp)
            SetCVar("whisperMode", "inline") -- Prevent popout frames
            C_ChatInfo.RegisterAddonMessagePrefix("WISPCRAFT")
            if ns.initSettings then ns.initSettings() end
            if ns.initTemplates then ns.initTemplates() end
            ns.buildUI()
            
            if WispCraftDB.width and WispCraftDB.height then
                ns.phoneFrame:SetSize(WispCraftDB.width, WispCraftDB.height)
                ns.BMAX = WispCraftDB.width * 0.4
            end

            ns.buildMinimapButton()
            if WispCraftDB.settings and WispCraftDB.settings.startPeeked then
                ns.setPeekMode(true)
            end
            print("|cff25d366WispCraft v1.2|r loaded. Type /wc to open.")
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix == "WISPCRAFT" and channel == "WHISPER" then
            local name = ns.stripRealm(sender)
            if msg == "HELLO" then
                ns.wispPeers[name] = true
                if ns.active == name then
                    if ns.selectContact then ns.selectContact(ns.active) end
                end
            elseif msg == "TYPING" then
                ns.isTyping[name] = true
                if ns.active == name then
                    ns.hdrStatus:SetText("escribiendo...")
                    ns.hdrStatus:SetTextColor(0.145, 0.855, 0.561)
                end
            elseif msg == "STOPPED" then
                ns.isTyping[name] = nil
                if ns.active == name then
                    if ns.selectContact then ns.selectContact(ns.active) end
                end
            elseif msg == "READ" then
                if ns.convos[name] then
                    for _, m in ipairs(ns.convos[name]) do
                        if m.out then m.read = true end
                    end
                    if ns.active == name then
                        if ns.renderChat then ns.renderChat() end
                    end
                end
            end
        end

    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local name = ns.stripRealm(sender)
        ns.pushMessage(name, msg, false)

        -- Play standard whisper sound
        local muted = WispCraftDB.muted and WispCraftDB.muted[name]
        if not muted then
            if ns.doShake then ns.doShake() end
            if WispCraftDB.settings and WispCraftDB.settings.playSounds then
                PlaySound(SOUNDKIT and SOUNDKIT.IG_CHAT_WHISPER_NOTIFY or 566)
            end
            if (ns.peekMode or not ns.phoneFrame:IsShown()) and UIFrameFlash and ns.peekBar then
                UIFrameFlash(ns.peekBar, 0.5, 0.5, 3, true, 0, 0)
            end
        end

        -- Update UI if it's the active conversation
        if ns.active == name then
            ns.unread[name] = 0 -- Mark read
            if ns.sendP2P then ns.sendP2P(name, "READ") end
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
            if ns.active == name then
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


