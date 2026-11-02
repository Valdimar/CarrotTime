--[[
    CarrotTime
    Windower 4 Chocobo Raising Assistant
    Version: 0.6.0

    Commands (//crt or //carrottime):
      //crt help                      List commands
      //crt show | hide | toggle      Show / hide the panel
      //crt pos <x> <y>               Move the panel (or just drag it)
      //crt name <name>               Chocobo's name
      //crt type digging|racing       Raising path
      //crt focus official|circuit|custom
      //crt stat <stat> <rank>        Record a current stat (F..SSS)
      //crt target <stat> <rank>      Set a target rank for a stat
      //crt hatch <YYYY-MM-DD>        Hatch date (age is worked out from it)
      //crt age <days>                Set age by hand (clears hatch date)
      //crt watch                     Add one egg-phase watch (also counted
                                      automatically when you watch the egg)
      //crt watches <number>          Set the egg-phase watch count
      //crt ability <name> [off]      Record a learned ability (or remove it)
      //crt care                      Show today's care checklist
      //crt care <task> | done <task> Log a care task for today
      //crt undo <task>               Un-log a care task for today
      //crt note <text>               Add a note
      //crt notes [clear]             List / clear notes
      //crt race win | loss | place <n>
      //crt race history              Last 10 races and totals
      //crt status                    Summary in chat
      //crt capture [off]             Save chat lines to data/capture.txt (10 min)
      //crt reset confirm             Wipe this character's chocobo data

    Stats: strength (str), endurance (end), discernment (dsc), receptivity (rcp)
    Care tasks: feed, exercise, outing, care, story

    This addon is a manual tracker and advisor. It does not read
    chocobo status directly from the game client.

    Data is saved per character in addons/CarrotTime/data/<Character>.lua
]]

_addon.name = 'CarrotTime'
_addon.author = 'ChatGPT'
_addon.version = '0.6.0'
_addon.commands = {'crt', 'carrottime'}

local texts = require('texts')

------------------------------------------------------------------------
-- Defaults
------------------------------------------------------------------------

local defaults = {
    chocobo_name = 'My Chocobo',
    chocobo_type = 'digging', -- digging or racing

    hatch_date = '',
    age_days = 0,

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
    care_done = {},
    race_history = {},
    notes = {},

    ui = {
        x = 200,
        y = 200,
        visible = true,
    },
}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local STAT_NAMES = {'strength', 'endurance', 'discernment', 'receptivity'}

local STAT_LABELS = {
    strength = 'Strength',
    endurance = 'Endurance',
    discernment = 'Discernment',
    receptivity = 'Receptivity',
}

local STAT_ALIASES = {
    str = 'strength', strength = 'strength',
    ['end'] = 'endurance', endurance = 'endurance',
    dsc = 'discernment', dis = 'discernment', discernment = 'discernment',
    rcp = 'receptivity', rec = 'receptivity', receptivity = 'receptivity',
}

local RANKS = {'F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS'}
local RANK_VALUE = {}
for i, rank in ipairs(RANKS) do
    RANK_VALUE[rank] = i
end

local DIGGING_ABILITIES = {'Bore', 'Burrow'}
local RACING_ABILITIES = {'Gallop', 'Canter'}

local CARE_TASKS = {'feed', 'exercise', 'outing', 'care', 'story'}
local CARE_SET = {}
for _, t in ipairs(CARE_TASKS) do
    CARE_SET[t] = true
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

local settings          -- current character's data
local char_name         -- nil until logged in
local ui                -- texts object

------------------------------------------------------------------------
-- Chat helpers
------------------------------------------------------------------------

local function say(msg)
    windower.add_to_chat(200, 'CarrotTime: ' .. msg)
end

local function err(msg)
    windower.add_to_chat(123, 'CarrotTime: ' .. msg)
end

------------------------------------------------------------------------
-- Table helpers and persistence
------------------------------------------------------------------------

local function deep_copy(t)
    if type(t) ~= 'table' then
        return t
    end
    local r = {}
    for k, v in pairs(t) do
        r[k] = deep_copy(v)
    end
    return r
end

-- Fill missing keys in `t` from `def`, recursively (keeps user values).
local function fill_defaults(t, def)
    for k, v in pairs(def) do
        if t[k] == nil then
            t[k] = deep_copy(v)
        elseif type(v) == 'table' and type(t[k]) == 'table' then
            fill_defaults(t[k], v)
        end
    end
    return t
end

local function serialize(value, indent)
    indent = indent or ''
    local kind = type(value)

    if kind == 'string' then
        return string.format('%q', value)
    elseif kind == 'number' or kind == 'boolean' then
        return tostring(value)
    elseif kind ~= 'table' then
        return 'nil'
    end

    local inner = indent .. '    '
    local lines = {'{'}

    -- Array part first, in order.
    local n = #value
    for i = 1, n do
        lines[#lines + 1] = inner .. serialize(value[i], inner) .. ','
    end

    -- Then the remaining keys, sorted so the file is stable.
    local keys = {}
    for k in pairs(value) do
        if not (type(k) == 'number' and k >= 1 and k <= n and k == math.floor(k)) then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for _, k in ipairs(keys) do
        local key
        if type(k) == 'string' and k:match('^[%a_][%w_]*$') then
            key = k
        else
            key = '[' .. serialize(k) .. ']'
        end
        lines[#lines + 1] = inner .. key .. ' = ' .. serialize(value[k], inner) .. ','
    end

    lines[#lines + 1] = indent .. '}'
    return table.concat(lines, '\n')
end

local function data_path(name)
    return windower.addon_path .. 'data/' .. name .. '.lua'
end

local function save()
    if not char_name or not settings then
        return
    end

    local dir = windower.addon_path .. 'data/'
    if not windower.dir_exists(dir) then
        windower.create_dir(dir)
    end

    local f, e = io.open(data_path(char_name), 'w')
    if not f then
        err('could not save data (' .. tostring(e) .. ').')
        return
    end
    f:write('-- CarrotTime data for ' .. char_name .. '\n')
    f:write('return ' .. serialize(settings) .. '\n')
    f:close()
end

local function load_data(name)
    local path = data_path(name)
    local loaded

    if windower.file_exists(path) then
        local chunk, e = loadfile(path)
        if chunk then
            local ok, result = pcall(chunk)
            if ok and type(result) == 'table' then
                loaded = result
            else
                err('data file for ' .. name .. ' is damaged; starting fresh.')
            end
        else
            err('could not read data file (' .. tostring(e) .. '); starting fresh.')
        end
    end

    return fill_defaults(loaded or {}, defaults)
end

------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------

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

    local year, month, day = date_string:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if not year then
        return nil
    end

    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if month < 1 or month > 12 or day < 1 or day > 31 then
        return nil
    end

    return os.time({year = year, month = month, day = day, hour = 12, min = 0, sec = 0})
end

local function current_age()
    local hatch_time = date_to_time(settings.hatch_date)
    if hatch_time then
        local now = date_to_time(today())
        return math.max(0, math.floor((now - hatch_time) / 86400 + 0.5))
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

local function normalize_stat(stat)
    return STAT_ALIASES[lower(stat)]
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

local function title_case(s)
    return (tostring(s):gsub('(%a)([%w\']*)', function(a, b)
        return a:upper() .. b:lower()
    end))
end

------------------------------------------------------------------------
-- Derived info for the panel
------------------------------------------------------------------------

local function active_abilities()
    local result = {}
    for ability, learned in pairs(settings.abilities) do
        if learned then
            result[#result + 1] = ability
        end
    end
    table.sort(result)
    return result
end

local function care_lists()
    local completed, missing = {}, {}
    local d = today()
    for _, task in ipairs(CARE_TASKS) do
        if settings.care_done[task] == d then
            completed[#completed + 1] = task
        else
            missing[#missing + 1] = task
        end
    end
    return completed, missing
end

local function daily_care_summary()
    local completed, missing = care_lists()
    if #completed == 0 then
        return 'Nothing logged yet'
    end
    if #missing == 0 then
        return 'All tasks logged'
    end
    return 'Done: ' .. table.concat(completed, ', ')
        .. '\n  Left: ' .. table.concat(missing, ', ')
end

local function stat_advice()
    local deficits = {}

    for _, stat in ipairs(STAT_NAMES) do
        local gap = rank_value(settings.racing_targets[stat]) - rank_value(settings.stats[stat])
        if gap > 0 then
            deficits[#deficits + 1] = {stat = stat, gap = gap}
        end
    end

    if #deficits == 0 then
        return 'Stats meet your targets'
    end

    table.sort(deficits, function(a, b) return a.gap > b.gap end)
    local s = deficits[1].stat
    return 'Raise ' .. STAT_LABELS[s] .. ' ('
        .. settings.stats[s] .. ' -> ' .. settings.racing_targets[s] .. ')'
end

local function next_advice()
    local stage = current_stage()
    if stage == 'Egg' then
        return 'Keep watching the egg until it hatches'
    end
    if stage == 'Retired' then
        return 'Chocobo has passed the tracked age range'
    end

    local _, missing = care_lists()
    if #missing > 0 then
        return 'Log today\'s care: ' .. missing[1]
    end
    return stat_advice()
end

local function race_totals()
    local wins, losses = 0, 0
    for _, r in ipairs(settings.race_history) do
        if r.place == 1 then
            wins = wins + 1
        else
            losses = losses + 1
        end
    end
    return wins, losses
end

------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------

local TEMPLATE = [[
CarrotTime
Chocobo: ${c_name}
Path: ${c_path}   Focus: ${c_focus}
Age: ${c_age} days (${c_stage})${c_watch}

Stats (now / target)
  STR: ${c_str}
  END: ${c_end}
  DSC: ${c_dsc}
  RCP: ${c_rcp}

Abilities: ${c_abil}
Races: ${c_races}

Today's care
  ${c_care}

Next: ${c_advice}]]

local function stat_line(stat)
    return string.format('%-3s / %s', settings.stats[stat] or 'F', settings.racing_targets[stat] or 'F')
end

local function update_ui()
    if not ui then
        return
    end

    if not settings or not char_name then
        ui:hide()
        return
    end

    local stage = current_stage()
    local wins, losses = race_totals()

    ui:update({
        c_name = settings.chocobo_name,
        c_path = title_case(settings.chocobo_type),
        c_focus = settings.racing_focus,
        c_age = current_age(),
        c_stage = stage,
        c_watch = stage == 'Egg' and ('\nEgg watches: ' .. (settings.egg_watches or 0)) or '',
        c_str = stat_line('strength'),
        c_end = stat_line('endurance'),
        c_dsc = stat_line('discernment'),
        c_rcp = stat_line('receptivity'),
        c_abil = format_list(active_abilities()),
        c_races = (#settings.race_history == 0) and 'None'
            or (wins .. ' won / ' .. losses .. ' other'),
        c_care = daily_care_summary(),
        c_advice = next_advice(),
    })

    ui:pos(settings.ui.x, settings.ui.y)

    if settings.ui.visible then
        ui:show()
    else
        ui:hide()
    end
end

local function create_ui()
    ui = texts.new(TEMPLATE, {
        pos = {x = defaults.ui.x, y = defaults.ui.y},
        bg = {visible = true, alpha = 180, red = 20, green = 20, blue = 20},
        text = {font = 'Consolas', size = 10, alpha = 255, red = 255, green = 240, blue = 220},
        flags = {draggable = true, bold = false, italic = false},
        padding = 4,
    })
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------

local function set_name(name)
    if name == '' then
        err('usage: //crt name <name>')
        return
    end
    settings.chocobo_name = name
    save()
    update_ui()
    say('name set to ' .. name .. '.')
end

local function set_type(chocobo_type)
    chocobo_type = lower(chocobo_type)
    if chocobo_type ~= 'digging' and chocobo_type ~= 'racing' then
        err('type must be "digging" or "racing".')
        return
    end
    settings.chocobo_type = chocobo_type
    save()
    update_ui()
    say('path set to ' .. chocobo_type .. '. Typical abilities for it: '
        .. format_list(chocobo_type == 'racing' and RACING_ABILITIES or DIGGING_ABILITIES) .. '.')
end

local function set_focus(focus)
    focus = lower(focus)
    if focus ~= 'official' and focus ~= 'circuit' and focus ~= 'custom' then
        err('focus must be official, circuit, or custom.')
        return
    end
    settings.racing_focus = focus
    save()
    update_ui()
    say('racing focus set to ' .. focus .. '.')
end

local function set_rank(which, stat, rank)
    local s = normalize_stat(stat)
    local r = normalize_rank(rank)

    if not s then
        err('stat must be strength, endurance, discernment or receptivity (or str/end/dsc/rcp).')
        return
    end
    if not r then
        err('rank must be one of ' .. table.concat(RANKS, ', ') .. '.')
        return
    end

    if which == 'target' then
        settings.racing_targets[s] = r
        say(STAT_LABELS[s] .. ' target set to ' .. r .. '.')
    else
        settings.stats[s] = r
        say(STAT_LABELS[s] .. ' recorded as ' .. r .. '.')
    end
    save()
    update_ui()
end

local function set_hatch_date(date)
    if not date_to_time(date) then
        err('hatch date must be YYYY-MM-DD.')
        return
    end
    settings.hatch_date = date
    settings.age_days = current_age()
    save()
    update_ui()
    say('hatch date set to ' .. date .. ' (age ' .. current_age() .. ' days).')
end

local function set_age(days)
    days = valid_number(days)
    if not days then
        err('age must be a non-negative whole number.')
        return
    end
    settings.age_days = days
    settings.hatch_date = ''
    save()
    update_ui()
    say('age set to ' .. days .. ' days.')
end

local function set_watches(count)
    -- No number (or "+"): add one watch to the current count.
    if count == nil or count == '' or count == '+' then
        count = (tonumber(settings.egg_watches) or 0) + 1
    end
    count = valid_number(count)
    if not count then
        err('watches must be a non-negative whole number.')
        return
    end
    if current_stage() ~= 'Egg' then
        err('watch count is for the egg phase. Current stage: ' .. current_stage() .. '.')
        return
    end
    settings.egg_watches = count
    save()
    update_ui()
    say('egg-phase watches recorded as ' .. count .. '.')
end

local function set_ability(words)
    if #words == 0 then
        say('abilities: ' .. format_list(active_abilities()))
        return
    end

    local remove = false
    if lower(words[#words]) == 'off' or lower(words[#words]) == 'remove' then
        remove = true
        table.remove(words)
    end

    local name = title_case(table.concat(words, ' '))
    if name == '' then
        err('usage: //crt ability <name> [off]')
        return
    end

    if remove then
        settings.abilities[name] = nil
        say(name .. ' removed.')
    else
        settings.abilities[name] = true
        say(name .. ' recorded as learned.')
    end
    save()
    update_ui()
end

local function show_care()
    local completed, missing = care_lists()
    say('today (' .. today() .. ') done: ' .. format_list(completed)
        .. ' | left: ' .. format_list(missing))
end

local function log_care(task, undo)
    task = lower(task)
    if task == '' then
        show_care()
        return
    end
    if task == 'all' then
        for _, t in ipairs(CARE_TASKS) do
            settings.care_done[t] = (not undo) and today() or nil
        end
    elseif CARE_SET[task] then
        settings.care_done[task] = (not undo) and today() or nil
    else
        err('task must be one of: ' .. table.concat(CARE_TASKS, ', ') .. ' (or all).')
        return
    end
    save()
    update_ui()
    show_care()
end

local function add_note(text)
    if text == '' then
        err('usage: //crt note <text>')
        return
    end
    settings.notes[#settings.notes + 1] = today() .. ' ' .. text
    save()
    say('note added (' .. #settings.notes .. ' total).')
end

local function list_notes(arg)
    if lower(arg) == 'clear' then
        settings.notes = {}
        save()
        say('notes cleared.')
        return
    end
    if #settings.notes == 0 then
        say('no notes.')
        return
    end
    for i, n in ipairs(settings.notes) do
        windower.add_to_chat(207, string.format('  %d. %s', i, n))
    end
end

local function add_race(place)
    settings.race_history[#settings.race_history + 1] = {date = today(), place = place}
    save()
    update_ui()
    local wins, losses = race_totals()
    say('race recorded (' .. (place == 1 and 'win' or ('place ' .. place)) .. '). Total: '
        .. wins .. ' won / ' .. losses .. ' other.')
end

local function race_command(sub, arg)
    sub = lower(sub)
    if sub == 'win' then
        add_race(1)
    elseif sub == 'loss' or sub == 'lose' then
        add_race(0)
    elseif sub == 'place' then
        local p = valid_number(arg)
        if not p or p < 1 then
            err('usage: //crt race place <number>')
            return
        end
        add_race(p)
    elseif sub == 'history' or sub == '' then
        local h = settings.race_history
        if #h == 0 then
            say('no races recorded.')
            return
        end
        local wins, losses = race_totals()
        say(#h .. ' races: ' .. wins .. ' won / ' .. losses .. ' other. Last 10:')
        for i = math.max(1, #h - 9), #h do
            local r = h[i]
            local result = r.place == 1 and 'win' or (r.place == 0 and 'loss' or ('place ' .. r.place))
            windower.add_to_chat(207, string.format('  %s  %s', r.date or '?', result))
        end
    elseif sub == 'clear' then
        settings.race_history = {}
        save()
        update_ui()
        say('race history cleared.')
    else
        err('usage: //crt race win | loss | place <n> | history | clear')
    end
end

local function status()
    say(settings.chocobo_name .. ' - ' .. settings.chocobo_type .. ', age '
        .. current_age() .. ' days (' .. current_stage() .. ')')
    for _, s in ipairs(STAT_NAMES) do
        windower.add_to_chat(207, string.format('  %-12s %-3s (target %s)',
            STAT_LABELS[s], settings.stats[s], settings.racing_targets[s]))
    end
    windower.add_to_chat(207, '  Abilities: ' .. format_list(active_abilities()))
    windower.add_to_chat(207, '  Next: ' .. next_advice())
end

------------------------------------------------------------------------
-- Capture: saves every chat / NPC dialogue line to a file, so the exact
-- wording of chocobo messages can be found and auto-detected later.
------------------------------------------------------------------------

local capture_until = 0          -- os.time() when capture switches off
local CAPTURE_MINUTES = 10
local last_watch_time = 0        -- os.time() of the last auto-counted watch

local function capture_path()
    return windower.addon_path .. 'data/capture.txt'
end

local function set_capture(arg)
    arg = lower(arg)
    if arg == 'off' then
        capture_until = 0
        say('capture off. Lines saved in addons/CarrotTime/data/capture.txt')
        return
    end

    local dir = windower.addon_path .. 'data/'
    if not windower.dir_exists(dir) then
        windower.create_dir(dir)
    end
    local f = io.open(capture_path(), 'a')
    if f then
        f:write('\n==== capture started ' .. os.date('%Y-%m-%d %H:%M:%S') .. ' ====\n')
        f:close()
    end

    capture_until = os.time() + CAPTURE_MINUTES * 60
    say('capture on for ' .. CAPTURE_MINUTES .. ' minutes. Talk to the NPC and have it '
        .. 'watch the egg, then type //crt capture off.')
end

windower.register_event('incoming text', function(original, modified, mode)
    -- Strip FFXI colour/auto-translate control bytes.
    local clean = tostring(original or '')
        :gsub('\30.', ''):gsub('\31.', ''):gsub('\127.', '')
        :gsub('[%z\1-\8\11\12\14-\31]', '')

    -- Egg watch: "Your egg feels the tender warmth of your gaze"
    if settings and clean:lower():find('tender warmth of your gaze', 1, true) then
        local now = os.time()
        if now - last_watch_time > 5 then   -- ignore the same line repeated
            last_watch_time = now
            settings.egg_watches = (tonumber(settings.egg_watches) or 0) + 1
            save()
            update_ui()
            say('egg watched - ' .. settings.egg_watches .. ' watches so far.')
        end
    end

    if capture_until == 0 then
        return
    end
    if os.time() > capture_until then
        capture_until = 0
        say('capture finished. Lines saved in addons/CarrotTime/data/capture.txt')
        return
    end

    local f = io.open(capture_path(), 'a')
    if f then
        f:write(string.format('[%s] mode=%s  %s\n', os.date('%H:%M:%S'), tostring(mode), clean))
        f:close()
    end
end)

local function show_help()
    local lines = {
        'CarrotTime commands (//crt):',
        '  show | hide | toggle | pos <x> <y> | status',
        '  name <name> | type digging|racing | focus official|circuit|custom',
        '  stat <stat> <rank> | target <stat> <rank>   (str/end/dsc/rcp, F..SSS)',
        '  hatch <YYYY-MM-DD> | age <days> | watch (adds 1) | watches <n>',
        '  ability <name> [off]',
        '  care | care <task> | done <task> | undo <task>   (feed exercise outing care story all)',
        '  note <text> | notes [clear]',
        '  race win | loss | place <n> | history | clear',
        '  capture | capture off   (save chat lines to data/capture.txt)',
        '  reset confirm',
    }
    for _, l in ipairs(lines) do
        windower.add_to_chat(207, l)
    end
end

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = lower(command or 'help')

    if not char_name or not settings then
        err('log in to a character first.')
        return
    end

    local rest = table.concat(args, ' ')

    if command == 'help' or command == '' then
        show_help()
    elseif command == 'show' then
        settings.ui.visible = true
        save()
        update_ui()
    elseif command == 'hide' then
        settings.ui.visible = false
        save()
        update_ui()
    elseif command == 'toggle' then
        settings.ui.visible = not settings.ui.visible
        save()
        update_ui()
    elseif command == 'pos' then
        local x, y = tonumber(args[1]), tonumber(args[2])
        if not x or not y then
            err('usage: //crt pos <x> <y>')
            return
        end
        settings.ui.x, settings.ui.y = x, y
        save()
        update_ui()
    elseif command == 'name' then
        set_name(rest)
    elseif command == 'type' then
        set_type(args[1])
    elseif command == 'focus' then
        set_focus(args[1])
    elseif command == 'stat' then
        set_rank('stat', args[1], args[2])
    elseif command == 'target' then
        set_rank('target', args[1], args[2])
    elseif command == 'hatch' then
        set_hatch_date(args[1])
    elseif command == 'age' then
        set_age(args[1])
    elseif command == 'watches' or command == 'watch' then
        set_watches(args[1])
    elseif command == 'ability' or command == 'abilities' then
        set_ability(args)
    elseif command == 'care' or command == 'done' then
        log_care(args[1] or '', false)
    elseif command == 'undo' then
        log_care(args[1] or '', true)
    elseif command == 'note' then
        add_note(rest)
    elseif command == 'notes' then
        list_notes(args[1])
    elseif command == 'race' then
        race_command(args[1] or '', args[2])
    elseif command == 'status' then
        status()
    elseif command == 'capture' then
        set_capture(args[1])
    elseif command == 'reset' then
        if lower(args[1]) ~= 'confirm' then
            err('this wipes all chocobo data for ' .. char_name .. '. Type //crt reset confirm to do it.')
            return
        end
        local keep = deep_copy(settings.ui)
        settings = deep_copy(defaults)
        settings.ui = keep
        save()
        update_ui()
        say('data reset.')
    else
        err('unknown command "' .. command .. '". Try //crt help')
    end
end)

------------------------------------------------------------------------
-- Character loading, dragging and day rollover
------------------------------------------------------------------------

local function load_character()
    local player = windower.ffxi.get_player()
    if not player or not player.name then
        return
    end
    char_name = player.name
    settings = load_data(char_name)
    save()  -- writes the file the first time, and fills in any new defaults
    update_ui()
end

local function unload_character()
    save()
    char_name = nil
    settings = nil
    update_ui()
end

windower.register_event('load', function()
    create_ui()
    if windower.ffxi.get_info().logged_in then
        load_character()
    end
end)

windower.register_event('login', function()
    -- Player data isn't always ready the instant login fires.
    coroutine.schedule(load_character, 2)
end)

windower.register_event('logout', unload_character)

windower.register_event('unload', function()
    save()
    if ui then
        ui:destroy()
    end
end)

-- Save the position after the panel is dragged (left button released).
windower.register_event('mouse', function(type)
    if type ~= 2 or not ui or not settings then
        return
    end
    local x, y = ui:pos()
    if x ~= settings.ui.x or y ~= settings.ui.y then
        settings.ui.x, settings.ui.y = x, y
        save()
    end
end)

-- Refresh every 30 s so age and today's care roll over at midnight.
local last_refresh = 0
windower.register_event('prerender', function()
    local now = os.clock()
    if now - last_refresh >= 30 then
        last_refresh = now
        if settings then
            update_ui()
        end
    end
end)
