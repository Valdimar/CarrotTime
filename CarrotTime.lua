--[[
    CarrotTime
    Windower 4 Chocobo Raising Assistant
    Version: 0.5.0

    Commands:
      //crt
      //crt help
      //crt type digging|racing
      //crt focus official|circuit|custom
      //crt target <stat> <rank>
      //crt hatch <YYYY-MM-DD>
      //crt age <days>
      //crt watches <number>
      //crt care <task>
      //crt done <task>
      //crt note <text>
      //crt race win
      //crt race loss
      //crt race place <number>
      //crt race history
      //crt reset
      //crt show
      //crt hide

    This addon is a manual tracker and advisor. It does not read
    chocobo status directly from the game client.
]]

_addon.name = 'CarrotTime'
_addon.author = 'ChatGPT'
_addon.version = '0.5.0'
_addon.command = 'crt'

require('logger')
local config = require('config')
local texts = require('texts')

local settings = config.load('data/settings.xml', defaults)

------------------------------------------------------------------------
-- Defaults and persistent settings
------------------------------------------------------------------------

local defaults = {
    chocobo_name = 'My Chocobo',
    chocobo_type = 'digging', -- digging or racing

    hatch_date = '',
    age_days = 0,

    -- Egg-phase watch count entered manually by the player.
    egg_watches = 0,

    racing_focus = 'official', -- official, circuit, custom
    racing_targets = {
        strength = 'SS',
        endurance = 'B',
        discernment = 'A',
        receptivity = 'C',
    },

    stats = {
        strength = 'F',
        endurance = 'F',
        discernment = 'F',
        receptivity = 'F',
    },

    abilities = {},
    stories = {},

    care_done = {},
    care_notes = {},

    race_history = {},
    notes = {},

    ui = {
        x = 200,
        y = 200,
        visible = true,
    },
}

local settings = config.load(defaults)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local STAT_NAMES = {
    'strength',
    'endurance',
    'discernment',
    'receptivity',
}

local STAT_LABELS = {
    strength = 'Strength',
    endurance = 'Endurance',
    discernment = 'Discernment',
    receptivity = 'Receptivity',
}

local RANKS = {
    'F',
    'E',
    'D',
    'C',
    'B',
    'A',
    'S',
    'SS',
    'SSS',
}

local RANK_VALUE = {}
for i, rank in ipairs(RANKS) do
    RANK_VALUE[rank] = i
end

local DIGGING_ABILITIES = {
    'Bore',
    'Burrow',
}

local RACING_ABILITIES = {
    'Gallop',
    'Canter',
}

local CARE_TASKS = {
    'feed',
    'exercise',
    'outing',
    'care',
    'story',
}

------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------

local function save()
    config.save(settings)
end

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function split_words(input)
    local result = {}
    for word in tostring(input or ''):gmatch('%S+') do
        result[#result + 1] = word
    end
    return result
end

local function lower(value)
    return tostring(value or ''):lower()
end

local function valid_number(value)
    local number = tonumber(value)
    if number and number >= 0 and number == math.floor(number) then
        return number
    end
    return nil
end

local function today()
    return os.date('%Y-%m-%d')
end

local function date_to_time(date_string)
    if type(date_string) ~= 'string' then
        return nil
    end

    local year, month, day =
        date_string:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')

    if not year then
        return nil
    end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 12,
        min = 0,
        sec = 0,
    })
end

local function calculate_age()
    local hatch_time = date_to_time(settings.hatch_date)

    if not hatch_time then
        return tonumber(settings.age_days) or 0
    end

    local now = date_to_time(today())
    if not now then
        return tonumber(settings.age_days) or 0
    end

    local days = math.floor((now - hatch_time) / 86400)
    return math.max(0, days)
end

local function current_age()
    if settings.hatch_date ~= '' then
        return calculate_age()
    end

    return tonumber(settings.age_days) or 0
end

local function current_stage()
    local age = current_age()

    if age < 4 then
        return 'Egg'
    elseif age < 11 then
        return 'Chick'
    elseif age < 29 then
        return 'Adolescent'
    elseif age < 64 then
        return 'Adult'
    end

    return 'Retired'
end

local function normalize_rank(rank)
    rank = tostring(rank or ''):upper()

    if RANK_VALUE[rank] then
        return rank
    end

    return nil
end

local function rank_value(rank)
    return RANK_VALUE[normalize_rank(rank) or 'F'] or 1
end

local function format_list(items)
    if not items or #items == 0 then
        return 'None recorded'
    end

    return table.concat(items, ', ')
end

------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------

local ui = texts.new(
    [[
CarrotTime v0.5.0
Chocobo: ${name}
Path: ${path}
Age: ${age} days (${stage})
Egg watches: ${watches}

Stats
  STR: ${strength}
  END: ${endurance}
  DSC: ${discernment}
  RCP: ${receptivity}

Abilities
  ${abilities}

Today's care
  ${care}

Racing focus: ${focus}
Next advice: ${advice}

Type //crt help for commands.
]],
    {
        pos = {
            x = settings.ui.x,
            y = settings.ui.y,
        },
        bg = {
            visible = true,
            alpha = 180,
            red = 20,
            green = 20,
            blue = 20,
        },
        text = {
            font = 'Consolas',
            size = 10,
            alpha = 255,
            red = 255,
            green = 240,
            blue = 220,
        },
        flags = {
            draggable = true,
            bold = false,
            italic = false,
        },
    }
)

local function active_abilities()
    local result = {}

    for ability, learned in pairs(settings.abilities or {}) do
        if learned then
            result[#result + 1] = ability
        end
    end

    table.sort(result)
    return result
end

local function daily_care_summary()
    local completed = {}
    local missing = {}

    for _, task in ipairs(CARE_TASKS) do
        if settings.care_done[task] == today() then
            completed[#completed + 1] = task
        else
            missing[#missing + 1] = task
        end
    end

    if #completed == 0 then
        return 'Not logged'
    end

    if #missing == 0 then
        return 'All tasks logged'
    end

    return table.concat(completed, ', ')
end

local function racing_advice()
    local target = settings.racing_targets or {}
    local current = settings.stats or {}

    local deficits = {}

    for _, stat in ipairs(STAT_NAMES) do
        local goal = rank_value(target[stat])
        local have = rank_value(current[stat])
        local gap = goal - have

        if gap > 0 then
            deficits[#deficits + 1] = {
                stat = stat,
                gap = gap,
            }
        end
    end

    table.sort(deficits, function(a, b)
        return a.gap > b.gap
    end)

    if #deficits == 0 then
        return 'Current stats meet configured targets'
    end

    local highest = deficits[1]
    return 'Prioritize ' .. STAT_LABELS[highest.stat]
        .. ' (' .. current[highest.stat]
        .. ' → ' .. target[highest.stat] .. ')'
end

local function path_abilities()
    if settings.chocobo_type == 'racing' then
        return format_list(RACING_ABILITIES)
    end

    return format_list(DIGGING_ABILITIES)
end

local function update_ui()
    if not ui then
        return
    end

    local age = current_age()

    ui.name = settings.chocobo_name
    ui.path = settings.chocobo_type
    ui.age = age
    ui.stage = current_stage()
    ui.watches = settings.egg_watches or 0

    ui.strength = settings.stats.strength or 'F'
    ui.endurance = settings.stats.endurance or 'F'
    ui.discernment = settings.stats.discernment or 'F'
    ui.receptivity = settings.stats.receptivity or 'F'

    ui.abilities = format_list(active_abilities())
    ui.care = daily_care_summary()
    ui.focus = settings.racing_focus
    ui.advice = racing_advice()

    if settings.ui.visible then
        ui:show()
    else
        ui:hide()
    end
end

------------------------------------------------------------------------
-- Chocobo profile and care tracking
------------------------------------------------------------------------

local function set_type(chocobo_type)
    chocobo_type = lower(chocobo_type)

    if chocobo_type ~= 'digging' and chocobo_type ~= 'racing' then
        windower.add_to_chat(123,
            'CarrotTime: type must be "digging" or "racing".')
        return
    end

    settings.chocobo_type = chocobo_type
    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: path set to ' .. chocobo_type .. '.')
end

local function set_focus(focus)
    focus = lower(focus)

    if focus ~= 'official'
        and focus ~= 'circuit'
        and focus ~= 'custom' then

        windower.add_to_chat(123,
            'CarrotTime: focus must be official, circuit, or custom.')
        return
    end

    settings.racing_focus = focus
    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: racing focus set to ' .. focus .. '.')
end

local function set_target(stat, rank)
    stat = lower(stat)
    rank = normalize_rank(rank)

    if not STAT_LABELS[stat] then
        windower.add_to_chat(123,
            'CarrotTime: stat must be strength, endurance, discernment, or receptivity.')
        return
    end

    if not rank then
        windower.add_to_chat(123,
            'CarrotTime: rank must be F, E, D, C, B, A, S, SS, or SSS.')
        return
    end

    settings.racing_targets[stat] = rank
    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: ' .. STAT_LABELS[stat]
        .. ' target set to ' .. rank .. '.')
end

local function set_stat(stat, rank)
    stat = lower(stat)
    rank = normalize_rank(rank)

    if not STAT_LABELS[stat] then
        windower.add_to_chat(123,
            'CarrotTime: unknown stat.')
        return
    end

    if not rank then
        windower.add_to_chat(123,
            'CarrotTime: invalid rank.')
        return
    end

    settings.stats[stat] = rank
    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: ' .. STAT_LABELS[stat]
        .. ' recorded as ' .. rank .. '.')
end

local function set_hatch_date(date)
    if not date_to_time(date) then
        windower.add_to_chat(123,
            'CarrotTime: hatch date must be YYYY-MM-DD.')
        return
    end

    settings.hatch_date = date
    settings.age_days = calculate_age()

    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: hatch date set to ' .. date .. '.')
end

local function set_age(days)
    days = valid_number(days)

    if not days then
        windower.add_to_chat(123,
            'CarrotTime: age must be a non-negative whole number.')
        return
    end

    settings.age_days = days
    settings.hatch_date = ''

    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: age set to ' .. days .. ' days.')
end

local function set_watches(count)
    count = valid_number(count)

    if not count then
        windower.add_to_chat(123,
            'CarrotTime: watches must be a non-negative whole number.')
        return
    end

    if current_stage() ~= 'Egg' then
        windower.add_to_chat(123,
            'CarrotTime: watch count is intended for the egg phase. '
            .. 'Current stage: ' .. current_stage() .. '.')
        return
    end

    settings.egg_watches = count
    save()
    update_ui()

    windower.add_to_chat(200,
        'CarrotTime: egg-phase watches recorded as ' .. count ..
