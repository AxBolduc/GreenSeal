--- STEAMODDED HEADER
--- MOD_NAME: AxUtil
--- MOD_ID: AxUtil
--- MOD_AUTHOR: [AxBolduc]
--- MOD_DESCRIPTION: Utility mod to facilitate adding seals
----------------------------------------------
------------MOD CODE -------------------------

function refresh_items()
    for k, v in pairs(G.P_SEALS) do
        table.sort(v, function(a, b) return a.order < b.order end)
    end

    -- Update localization
    for g_k, group in pairs(G.localization) do
        if g_k == 'descriptions' then
            for _, set in pairs(group) do
                for _, center in pairs(set) do
                    center.text_parsed = {}
                    for _, line in ipairs(center.text) do
                        center.text_parsed[#center.text_parsed + 1] = loc_parse_string(line)
                    end
                    center.name_parsed = {}
                    for _, line in ipairs(type(center.name) == 'table' and center.name or { center.name }) do
                        center.name_parsed[#center.name_parsed + 1] = loc_parse_string(line)
                    end
                    if center.unlock then
                        center.unlock_parsed = {}
                        for _, line in ipairs(center.unlock) do
                            center.unlock_parsed[#center.unlock_parsed + 1] = loc_parse_string(line)
                        end
                    end
                end
            end
        end
    end

    for k, v in pairs(G.P_JOKER_RARITY_POOLS) do
        table.sort(G.P_JOKER_RARITY_POOLS[k], function(a, b) return a.order < b.order end)
    end
end

-- REMEMBER TO CALL refresh_items AFTERWARDS
function add_seal(mod_id, sealId, locId, labelName, data, desc)
    -- Add Sprite
    SMODS.Sprite:new(mod_id .. locId, SMODS.findModByID(mod_id).path, locId .. ".png", 71, 95, "asset_atli"):register();
    SMODS.injectSprites()
    G.shared_seals[sealId] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[mod_id .. locId], { x = 0, y = 0 })

    data.key = sealId
    data.order = #G.P_CENTER_POOLS.Seal + 1
    G.P_SEALS[sealId] = data
    table.insert(G.P_CENTER_POOLS.Seal, data)

    G.localization.descriptions.Other[locId] = desc;
    G.localization.misc.labels[locId] = labelName
end

function add_item(mod_id, pool, id, data, desc)
    -- Add Sprite
    data.pos = { x = 0, y = 0 };
    data.key = id;
    data.atlas = mod_id .. id;
    SMODS.Sprite:new(mod_id .. id, SMODS.findModByID(mod_id).path, id .. ".png", 71, 95, "asset_atli"):register();

    data.key = id
    data.order = #G.P_CENTER_POOLS[pool] + 1
    G.P_CENTERS[id] = data
    table.insert(G.P_CENTER_POOLS[pool], data)

    if pool == "Joker" then
        table.insert(G.P_JOKER_RARITY_POOLS[data.rarity], data)
    end

    G.localization.descriptions[pool][id] = desc;
end

--https://github.com/Aurelius7309/SixSuits/blob/master/SixSuits.lua
function parse_save_for_new_cards()
    table.sort(G.P_CENTER_POOLS['Spectral'], function(a, b) return a.order < b.order end)

    if not love.filesystem.getInfo(G.SETTINGS.profile .. '') then
        love.filesystem.createDirectory(G.SETTINGS.profile ..
            '')
    end
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '/' .. 'meta.jkr') then
        love.filesystem.append(
            G.SETTINGS.profile .. '/' .. 'meta.jkr', 'return {}')
    end

    convert_save_to_meta()

    local data = get_compressed(G.SETTINGS.profile .. '/' .. 'meta.jkr') or 'return {}'
    sendDebugMessage(data)
    local meta = STR_UNPACK(data)
    meta.unlocked = meta.unlocked or {}
    meta.discovered = meta.discovered or {}
    meta.alerted = meta.alerted or {}

    for k, v in pairs(G.P_CENTERS) do
        if not v.wip and not v.demo then
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) then
                G.P_LOCKED[#G.P_LOCKED + 1] =
                    v
            end
            if not v.discovered and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^e_') or string.find(k, '^c_') or string.find(k, '^p_') or string.find(k, '^v_')) and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] or v.set == 'Back' or v.start_alerted then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
end

----------------------------------------------
------------MOD CODE END----------------------
