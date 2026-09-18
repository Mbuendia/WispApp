local ADDON_NAME, ns = ...

-- ============================================================
--  WispCraft Settings — Stub (v1.2 placeholder)
--  Full /wc config panel will be built in Session 2
-- ============================================================

function ns.initSettings()
    WispCraftDB.settings = WispCraftDB.settings or {
        hideInCombat = false,
        playSounds   = true,
        startPeeked  = false,
    }
end
