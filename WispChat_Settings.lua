local ADDON_NAME, ns = ...

-- ============================================================
--  WispChat Settings — Stub (v1.2 placeholder)
--  Full /wc config panel will be built in Session 2
-- ============================================================

function ns.initSettings()
    WispChatDB.settings = WispChatDB.settings or {
        hideInCombat = false,
        playSounds   = true,
        startPeeked  = false,
    }
end
