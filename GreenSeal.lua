--- STEAMODDED HEADER
--- MOD_NAME: Green Seal
--- MOD_ID: GreenSeal
--- MOD_AUTHOR: [AxBolduc]
--- MOD_DESCRIPTION: Adds a Green Seal to the game

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = 'GreenSeal'

function SMODS.INIT.RatSeal()
    _RELEASE_MODE = false

    add_seal(
        MOD_ID,
        'Green',
        'green_seal',
        'Green Seal',
        {
            discovered = false,
            set = 'Seal',
            config = { Xmult = 1.9 }
        },
        {
            name = "Green Seal",
            text = {
                "Increases round hand size",
                "by 1 when {C:attention}discarded",
                "{X:red,C:white} X0.75 {} mult when played",
            }
        }
    )

    refresh_items()
end

-- Add in the seal functionality
local calculate_seal_ref = Card.calculate_seal
function Card:calculate_seal(context)
    local fromRef = calculate_seal_ref(self, context)

    if context.scoring_hand and not context.repetition_only then
        if self.seal == 'Green' then
            return {
                x_mult = 0.75
            }
        end
    end

    if context.discard then
        if self.seal == 'Green' then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.0,
                func = (function()
                    if not G.GAME.round_resets.temp_handsize then
                        G.GAME.round_resets.temp_handsize = 0
                    end

                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.hand.config.real_card_limit = (G.hand.config.real_card_limit or G.hand.config.card_limit) +
                                1
                            G.hand.config.card_limit = math.max(0, G.hand.config.real_card_limit)
                            check_for_unlock({ type = 'min_hand_size' })
                            return true
                        end
                    }))
                    G.GAME.round_resets.temp_handsize = G.GAME.round_resets.temp_handsize + 1
                    return true
                end)
            }))
        end
    end

    return fromRef
end

-- Applies x_mult when card played
local eval_card_ref = eval_card
function eval_card(card, context)
    local fromRef = eval_card_ref(card, context)

    if context.scoring_hand then
        local seal = card:calculate_seal(context)
        if seal then
            fromRef.x_mult = (fromRef.x_mult or 1) * seal.x_mult
        end
    end

    return fromRef
end

-- Add the seal to be randomly generated in standard packs
-- This is bad because we have to reimplement the seal generation logic for standard packs
-- for my seal to be randomly generated. BEcause of how the logic is implemented in the base
-- game we cannot call the base function or else we'll end up with twice the amount of cards in the pack.
-- This means that any other mod that touches the standard pack may be wiped out
local card_open_ref = Card.open
function Card:open()
    if self.ability.set == "Booster" and not self.ability.name:find('Standard') then
        return card_open_ref(self)
    else
        stop_use()
        G.STATE_COMPLETE = false
        self.opening = true

        if not self.config.center.discovered then
            discover_card(self.config.center)
        end
        self.states.hover.can = false
        G.STATE = G.STATES.STANDARD_PACK
        G.GAME.pack_size = self.ability.extra

        G.GAME.pack_choices = self.config.center.config.choose or 1

        if self.cost > 0 then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    inc_career_stat('c_shop_dollars_spent', self.cost)
                    self:juice_up()
                    return true
                end
            }))
            ease_dollars(-self.cost)
        else
            delay(0.2)
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                self:explode()
                local pack_cards = {}

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        local _size = self.ability.extra

                        for i = 1, _size do
                            local card = nil
                            card = create_card(
                                (pseudorandom(pseudoseed('stdset' .. G.GAME.round_resets.ante)) > 0.6) and
                                "Enhanced" or
                                "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                            local edition_rate = 2
                            local edition = poll_edition('standard_edition' .. G.GAME.round_resets.ante,
                                edition_rate,
                                true)
                            card:set_edition(edition)
                            local seal_rate = 10
                            local seal_poll = pseudorandom(pseudoseed('stdseal' .. G.GAME.round_resets.ante))
                            if seal_poll > 1 - 0.02 * seal_rate then
                                -- This is basically the only code that is changed
                                local seal_type = pseudorandom(
                                    pseudoseed('stdsealtype' .. G.GAME.round_resets.ante),
                                    1,
                                    #G.P_CENTER_POOLS['Seal']
                                )


                                local sealName
                                for k, v in pairs(G.P_SEALS) do
                                    if v.order == seal_type then sealName = k end
                                end

                                if sealName == nil then sendDebugMessage("SEAL NAME IS NIL") end

                                card:set_seal(sealName)
                                -- End changed code
                            end
                            card.T.x = self.T.x
                            card.T.y = self.T.y
                            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.5 * G.SETTINGS.GAMESPEED)
                            pack_cards[i] = card
                        end
                        return true
                    end
                }))

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        if G.pack_cards then
                            if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then
                                for k, v in ipairs(pack_cards) do
                                    G.pack_cards:emplace(v)
                                end
                                return true
                            end
                        end
                    end
                }))

                for i = 1, #G.jokers.cards do
                    G.jokers.cards[i]:calculate_joker({ open_booster = true, card = self })
                end

                if G.GAME.modifiers.inflation then
                    G.GAME.inflation = G.GAME.inflation + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            for k, v in pairs(G.I.CARD) do
                                if v.set_cost then v:set_cost() end
                            end
                            return true
                        end
                    }))
                end

                return true
            end
        }))
    end
end

-- UI code for seal
local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    local fromRef = generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
        main_end)

    local info_queue = {}

    if not (_c.set == 'Edition') and badges then
        for k, v in ipairs(badges) do
            if v == 'green_seal' then info_queue[#info_queue + 1] = { key = 'green_seal', set = 'Other' } end
        end
    end

    for _, v in ipairs(info_queue) do
        generate_card_ui(v, fromRef)
    end

    return fromRef
end

-- Add the background color of the box that says "Green Seal"
local get_badge_colour_ref = get_badge_colour
function get_badge_colour(key)
    local fromRef = get_badge_colour_ref(key)

    if key == 'green_seal' then
        return G.C.GREEN
    end

    return fromRef
end

-- debug mode keybinds for adding seal
local controller_key_press_update_ref = Controller.key_press_update
function Controller:key_press_update(key, dt)
    controller_key_press_update_ref(self, key, dt)

    if not _RELEASE_MODE then
        if self.hovering.target and self.hovering.target:is(Card) then
            local _card = self.hovering.target
            if key == 'e' then
                if (_card.ability.set == 'Joker' or _card.playing_card or _card.area) then
                    _card:set_seal('Green', true, true)
                end
            end
        end
    end
end

----------------------------------------------
------------MOD CODE END----------------------
