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
