--[[
    CarrotTime
    Windower 4 Chocobo Raising Assistant
    Version: 0.7

    Changelog
      v0.7  Watching the egg again soon after counts again (it used to be
            ignored for 2 minutes after a counted watch).
      v0.6  Day is read from the NPC's "Chocobo Status Report: Day #"
            line and keeps counting up daily from there.
      v0.5  First versioned release.
            - Panel shows only while talking to a raising NPC
              (Hantileon, Zopago, Pulonono); //crt mode always keeps it up.
            - Egg watches counted automatically from the egg's reaction
              after the NPC confirms the watch; "watched today" on the panel.
            - Coloured panel with stat bars (now vs target), stage countdown,
              care checklist, abilities, races and a next-step hint.
            - Compact view, per-character save files, draggable panel,
              debug mode and chat capture for troubleshooting.

    Each update adds 0.1 to the version and gets a line above.

    Commands (//crt or //carrottime):
      //crt help                      List commands
      //crt mode npc | always         npc (default): the panel only appears while
                                      you talk to a chocobo raising NPC.
                                      always: the panel stays on screen.
      //crt show | hide | toggle      Show / hide the panel (in npc mode, show
                                      opens it until you hide it)
      //crt npc [add|remove <name>]   List / change the NPCs that open the panel
      //crt debug                     Print what the addon sees (NPC talks,
                                      egg lines) to chat; again to turn off
      //crt compact                   Toggle a smaller panel (stats + next step)
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
_addon.version = '0.7'
_addon.commands = {'crt', 'carrottime'}

local texts = require('texts')
local packets = require('packets')

------------------------------------------------------------------------
-- Defaults
------------------------------------------------------------------------

local defaults = {
    chocobo_name = 'My Chocobo',
    chocobo_type = 'digging', -- digging or racing

    hatch_date = '',
    age_days = 0,

    egg_watches = 0,
    last_watch_date = '',

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

    -- NPCs that open the panel in "npc" mode (the VCS raising NPCs).
    raising_npcs = {'Hantileon', 'Zopago', 'Pulonono'},

    ui = {
        x = 200,
        y = 200,
        visible = true,     -- used in "always" mode
        compact = false,
        mode = 'npc',       -- 'npc' or 'always'
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
local talking = false   -- currently in a conversation with a raising NPC
local talking_since = 0
local peek = false      -- panel opened by hand while in npc mode
local debug = false     -- //crt debug: print detection info to chat
local event_npc = nil   -- name of the NPC the current conversation started with

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

local function stat_advice()
    local deficits = {}

    for _, stat in ipairs(STAT_NAMES) do
        local gap = rank_value(settings.racing_targets[stat]) - rank_value(settings.stats[stat])
        if gap > 0 then
            deficits[#deficits + 1] = {stat = stat, gap = gap}
        end
    end

    if #deficits == 0 then
        return 'All stats meet your targets'
    end

    table.sort(deficits, function(a, b) return a.gap > b.gap end)
    local s = deficits[1].stat
    return 'Raise ' .. STAT_LABELS[s] .. ' ('
        .. settings.stats[s] .. ' -> ' .. settings.racing_targets[s] .. ')'
end

local function next_advice()
    local stage = current_stage()
    if stage == 'Egg' then
        if settings.last_watch_date == today() then
            return 'Watched today - back tomorrow'
        end
        return 'Watch the egg today'
    end
    if stage == 'Retired' then
        return 'Past the tracked age range'
    end

    local _, missing = care_lists()
    if #missing > 0 then
        return 'Today\'s care left: ' .. missing[1]
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

local PANEL_WIDTH = 36   -- characters; keeps the rules and bars lined up

-- Colours (r, g, b)
local C = {
    title  = {255, 205,  95},   -- chocobo gold
    text   = {235, 232, 222},
    label  = {140, 150, 165},
    dim    = { 85,  90, 100},
    good   = {125, 215, 125},
    warn   = {255, 185,  80},
    gap    = {170, 120,  55},   -- rank still to gain
    accent = {125, 190, 255},
}

local function col(c, s)
    s = tostring(s)
    if s == '' then
        return ''
    end
    return string.format('\\cs(%d,%d,%d)%s\\cr', c[1], c[2], c[3], s)
end

local function pad(s, n)
    s = tostring(s)
    if #s >= n then
        return s
    end
    return s .. string.rep(' ', n - #s)
end

local SEP = ' | '

local function rule()
    return col(C.dim, string.rep('-', PANEL_WIDTH))
end

local function section(name, right)
    local left = col(C.label, name:upper())
    if right and right ~= '' then
        local plain_right = right:gsub('\\cs%(%d+,%d+,%d+%)', ''):gsub('\\cr', '')
        local space = math.max(1, PANEL_WIDTH - #name - #plain_right)
        return left .. string.rep(' ', space) .. right
    end
    return left
end

local NEXT_STAGE = {
    Egg = {4, 'Chick'},
    Chick = {11, 'Adolescent'},
    Adolescent = {29, 'Adult'},
    Adult = {64, 'Retired'},
}

-- 9-slot bar: '#' = current rank, '-' = still to gain for the target,
-- '.' = beyond the target.
local function rank_bar(cur, tgt)
    local c, t = rank_value(cur), rank_value(tgt)
    local met = c >= t
    return col(met and C.good or C.warn, string.rep('#', c))
        .. col(C.gap, string.rep('-', math.max(0, t - c)))
        .. col(C.dim, string.rep('.', #RANKS - math.max(c, t)))
end

local function stat_row(short, stat)
    local cur = settings.stats[stat] or 'F'
    local tgt = settings.racing_targets[stat] or 'F'
    local met = rank_value(cur) >= rank_value(tgt)
    local status = met and col(C.good, 'ok')
        or (col(C.label, '-> ') .. col(C.warn, tgt))
    return col(C.label, short) .. '  '
        .. col(met and C.good or C.text, pad(cur, 4))
        .. rank_bar(cur, tgt) .. '  ' .. status
end

local function build_panel()
    local lines = {}
    local function add(l) lines[#lines + 1] = l end

    local stage = current_stage()
    local age = current_age()
    local compact = settings.ui.compact

    -- Header: name, path / focus
    local ver = 'v' .. _addon.version
    local gap = math.max(2, PANEL_WIDTH - #settings.chocobo_name - #ver)
    add(col(C.title, settings.chocobo_name) .. string.rep(' ', gap) .. col(C.dim, ver))
    local path = col(C.text, title_case(settings.chocobo_type))
    if settings.chocobo_type == 'racing' then
        path = path .. col(C.dim, SEP) .. col(C.label, settings.racing_focus .. ' focus')
    end
    add(path)
    add(rule())

    -- Age and stage
    local nxt = NEXT_STAGE[stage]
    local stage_line = col(C.accent, stage) .. col(C.dim, SEP) .. col(C.text, 'day ' .. age)
    if nxt then
        local left = nxt[1] - age
        stage_line = stage_line .. col(C.dim, SEP)
            .. col(C.label, nxt[2] .. ' in ' .. left .. 'd')
    end
    add(stage_line)

    if stage == 'Egg' then
        local watched = settings.last_watch_date == today()
        add(col(C.label, 'Watches ') .. col(C.text, settings.egg_watches or 0)
            .. col(C.dim, SEP)
            .. (watched and col(C.good, 'watched today') or col(C.warn, 'not watched today')))
    end

    -- Stats (not shown for an egg; there's nothing to raise yet)
    if stage ~= 'Egg' then
        add('')
        add(section('Stats', col(C.label, 'now') .. col(C.dim, ' / ') .. col(C.label, 'target')))
        add(stat_row('STR', 'strength'))
        add(stat_row('END', 'endurance'))
        add(stat_row('DSC', 'discernment'))
        add(stat_row('RCP', 'receptivity'))

        if not compact then
            -- Today's care
            local completed = care_lists()
            local done_count = #completed
            add('')
            add(section("Today's care",
                col(done_count == #CARE_TASKS and C.good or C.text, done_count .. '/' .. #CARE_TASKS)))
            local words = {}
            local d = today()
            for _, task in ipairs(CARE_TASKS) do
                if settings.care_done[task] == d then
                    words[#words + 1] = col(C.good, task)
                else
                    words[#words + 1] = col(C.dim, task)
                end
            end
            add(table.concat(words, '  '))

            -- Abilities and races
            add('')
            local abil = active_abilities()
            add(col(C.label, pad('Abilities', 10))
                .. (#abil > 0 and col(C.text, table.concat(abil, ', ')) or col(C.dim, 'none yet')))

            if settings.chocobo_type == 'racing' or #settings.race_history > 0 then
                local wins, losses = race_totals()
                if #settings.race_history == 0 then
                    add(col(C.label, pad('Races', 10)) .. col(C.dim, 'none yet'))
                else
                    add(col(C.label, pad('Races', 10)) .. col(C.good, wins .. (wins == 1 and ' win' or ' wins'))
                        .. '  ' .. col(C.text, losses .. ' other'))
                end
            end
        end
    end

    -- Next step
    add(rule())
    add(col(C.title, '> ') .. col(C.text, next_advice()))

    return table.concat(lines, '\n')
end

local function update_ui()
    if not ui then
        return
    end

    if not settings or not char_name then
        ui:hide()
        return
    end

    ui:text(build_panel())
    ui:pos(settings.ui.x, settings.ui.y)

    local shown
    if settings.ui.mode == 'always' then
        shown = settings.ui.visible
    else
        shown = talking or peek
    end

    if shown then
        ui:show()
    else
        ui:hide()
    end
end

local function create_ui()
    ui = texts.new('', {
        pos = {x = defaults.ui.x, y = defaults.ui.y},
        bg = {visible = true, alpha = 210, red = 18, green = 20, blue = 28},
        text = {
            font = 'Consolas', size = 10, alpha = 255,
            red = C.text[1], green = C.text[2], blue = C.text[3],
            stroke = {width = 1, alpha = 160, red = 0, green = 0, blue = 0},
        },
        flags = {draggable = true, bold = false, italic = false},
        padding = 8,
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
        settings.last_watch_date = today()
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
    say('today (' .. today() .. ') done: '
        .. (#completed > 0 and table.concat(completed, ', ') or 'nothing yet')
        .. ' | left: ' .. (#missing > 0 and table.concat(missing, ', ') or 'nothing'))
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
local last_watch_line = ''       -- the egg line that was counted (to skip its copy)
local DUPLICATE_SECONDS = 5      -- same line again this soon = the game's copy
local watch_prompt_time = 0      -- os.time() Zopago & co. last confirmed a watch
local WATCH_WINDOW = 120         -- seconds after that line in which an egg line counts

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

------------------------------------------------------------------------
-- NPC conversations: open the panel while talking to a raising NPC
------------------------------------------------------------------------

local function is_raising_npc(name)
    if not name or not settings then
        return false
    end
    name = lower(name)
    for _, n in ipairs(settings.raising_npcs) do
        if lower(n) == name then
            return true
        end
    end
    return false
end

local function set_talking(state)
    if talking ~= state then
        talking = state
        talking_since = os.time()
        update_ui()
    end
end

local function dbg(msg)
    if debug then
        windower.add_to_chat(207, '[CarrotTime debug] ' .. msg)
    end
end

-- When a conversation (event) starts, remember which NPC it is with.
windower.register_event('incoming chunk', function(id, data)
    if not settings then
        return
    end
    if id == 0x032 or id == 0x034 then
        local ok, p = pcall(packets.parse, 'incoming', data)
        local mob
        if ok and p then
            mob = (p['NPC Index'] and windower.ffxi.get_mob_by_index(p['NPC Index']))
                or (p['NPC'] and windower.ffxi.get_mob_by_id(p['NPC']))
        end
        event_npc = mob and mob.name or nil
        dbg(string.format('conversation started (0x%03X) with %s', id, tostring(event_npc)))
    elseif id == 0x00A then
        event_npc = nil
        set_talking(false)
    end
end)

-- Status 4 = "Event": the game has you in a conversation / cutscene.
-- The panel shows while you're in one with a raising NPC, and closes
-- as soon as you aren't. Checked a few times a second.
local last_poll = 0
local reported_event = false
local function poll_conversation()
    local now = os.clock()
    if now - last_poll < 0.25 then
        return
    end
    last_poll = now

    local player = windower.ffxi.get_player()
    local in_event = player and player.status == 4

    if not in_event then
        if talking then
            dbg('conversation ended')
        end
        event_npc = nil
        reported_event = false
        set_talking(false)
        return
    end

    if talking then
        return
    end

    local target = windower.ffxi.get_mob_by_target('t')
    local target_name = target and target.name or nil
    if is_raising_npc(event_npc) or is_raising_npc(target_name) then
        dbg('raising NPC conversation: ' .. tostring(event_npc or target_name))
        set_talking(true)
    elseif debug and not reported_event then
        dbg('in a conversation, but not with a raising NPC (NPC: '
            .. tostring(event_npc) .. ', target: ' .. tostring(target_name) .. ')')
    end
    reported_event = true
end

windower.register_event('incoming text', function(original, modified, mode)
    -- add_to_chat output comes back through this event; ignore our own lines
    -- (this is what made the debug messages repeat themselves).
    local head = tostring(original or ''):sub(1, 40)
    if head:find('CarrotTime', 1, true) then
        return
    end

    -- Strip FFXI colour/auto-translate codes. NPC dialogue uses byte 7 as a
    -- line break, so control bytes become spaces (not nothing) to keep the
    -- words apart, then runs of spaces are collapsed.
    local clean = tostring(original or '')
        :gsub('\30.', ''):gsub('\31.', ''):gsub('\127.', '')
        :gsub('[%z\1-\31]', ' ')
        :gsub('%s+', ' ')
    local low = clean:lower()

    if debug and (low:find('egg', 1, true) or low:find('gaze', 1, true)) then
        dbg('line (mode ' .. tostring(mode) .. '): ' .. clean)
    end

    -- "--Chocobo Status Report: Day #12--": set the chocobo's day. Stored as
    -- a hatch date so the day keeps counting up until the next report.
    if settings then
        local day = tonumber(low:match('chocobo status report:%s*day%s*#?%s*(%d+)'))
        if day then
            local hatch = os.date('%Y-%m-%d', date_to_time(today()) - day * 86400)
            if hatch ~= settings.hatch_date then
                settings.hatch_date = hatch
                settings.age_days = day
                save()
                update_ui()
                say('status report: day ' .. day .. ' (' .. current_stage() .. ').')
            end
        end
    end

    -- Egg watch. The raising NPC first says "If you watch over <name>, it will
    -- gradually return your affection." The egg's reaction comes next and
    -- changes from day to day ("Your egg feels the tender warmth of your
    -- gaze", "The chick inside the egg seems to want out...", ...), so the
    -- first egg line after that confirmation counts as one watch. The game
    -- often prints each line twice (two chat modes); it's only counted once.
    if settings then
        local now = os.time()
        local npc_speech = clean:match('^%s*[%a][%a%-\' ]* : ') ~= nil

        if low:find('if you watch over', 1, true) then
            watch_prompt_time = now
            dbg('watch confirmed by NPC; waiting for the egg\'s reaction')
        elseif not npc_speech and low:find('egg', 1, true)
            and now - watch_prompt_time <= WATCH_WINDOW
            and not (low == last_watch_line and now - last_watch_time <= DUPLICATE_SECONDS) then
            last_watch_time = now
            last_watch_line = low
            watch_prompt_time = 0
            settings.egg_watches = (tonumber(settings.egg_watches) or 0) + 1
            settings.last_watch_date = today()
            save()
            update_ui()
            say('egg watched - ' .. settings.egg_watches
                .. (settings.egg_watches == 1 and ' watch' or ' watches') .. ' so far.')
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
        '  mode npc|always | show | hide | toggle | compact | pos <x> <y> | status',
        '  npc | npc add <name> | npc remove <name>   (NPCs that open the panel)',
        '  debug   (print what the addon detects)',
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
        if settings.ui.mode == 'always' then
            settings.ui.visible = true
            save()
        else
            peek = true
        end
        update_ui()
    elseif command == 'hide' then
        peek = false
        if settings.ui.mode == 'always' then
            settings.ui.visible = false
            save()
        end
        update_ui()
    elseif command == 'debug' then
        debug = not debug
        say('debug ' .. (debug and 'on: talk to the NPC and watch the egg, then send what appears in chat.' or 'off.'))
    elseif command == 'mode' then
        local m = lower(args[1])
        if m ~= 'npc' and m ~= 'always' then
            say('mode is ' .. settings.ui.mode .. '. Use //crt mode npc or //crt mode always.')
            return
        end
        settings.ui.mode = m
        peek = false
        if m == 'always' then
            settings.ui.visible = true
        end
        save()
        update_ui()
        if m == 'npc' then
            say('the panel now appears only while you talk to '
                .. table.concat(settings.raising_npcs, ', ') .. '.')
        else
            say('the panel now stays on screen.')
        end
    elseif command == 'npc' or command == 'npcs' then
        local sub = lower(args[1])
        local name = title_case(table.concat(args, ' ', 2))
        if sub == 'add' and name ~= '' then
            for _, n in ipairs(settings.raising_npcs) do
                if lower(n) == lower(name) then
                    say(name .. ' is already on the list.')
                    return
                end
            end
            table.insert(settings.raising_npcs, name)
            save()
            say(name .. ' added.')
        elseif sub == 'remove' and name ~= '' then
            for i, n in ipairs(settings.raising_npcs) do
                if lower(n) == lower(name) then
                    table.remove(settings.raising_npcs, i)
                    save()
                    say(name .. ' removed.')
                    return
                end
            end
            err(name .. ' is not on the list.')
        elseif sub == '' then
            say('panel opens for: ' .. format_list(settings.raising_npcs))
        else
            err('usage: //crt npc | npc add <name> | npc remove <name>')
        end
    elseif command == 'compact' then
        settings.ui.compact = not settings.ui.compact
        save()
        update_ui()
        say('compact view ' .. (settings.ui.compact and 'on' or 'off') .. '.')
    elseif command == 'toggle' then
        if settings.ui.mode == 'always' then
            settings.ui.visible = not settings.ui.visible
            save()
        else
            peek = not peek
        end
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
    say('v' .. _addon.version .. ' loaded for ' .. char_name .. ' ('
        .. settings.ui.mode .. ' mode).')
end

local function unload_character()
    save()
    talking, peek = false, false
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
    if settings then
        poll_conversation()
    end
    local now = os.clock()
    if now - last_refresh >= 30 then
        last_refresh = now
        if settings then
            update_ui()
        end
    end
end)
