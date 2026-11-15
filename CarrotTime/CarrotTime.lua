--[[
    CarrotTime
    Windower 4 Chocobo Raising Assistant
    Author: Valdimar @ Phoenix
    Version: 3.1

    Changelog
      v3.1  Care plans: the plan in use is read from the check-up
            ("Plan: Basic Care", right after the status report), so the
            panel's Set line fills in by itself. From the chick stage on, a
            plan that doesn't match the guide comes before the carrot reminder
            in the next step - plans raise stats every day without food.
            Basic Care is flagged as giving no stats (except in phase 3,
            where the guide uses it on purpose).
      v3.0  Energy, from the trainer's event data (found in Valdimar's logs):
            - The panel shows energy (0-100) with how many walks and watches
              are left; between visits it's estimated from the recovery rate
              (energy does not refill at the daily reset: ~1.4 an hour).
            - Walks and watches are counted from the game's own result data
              (action, energy before / after, refused), at any trainer. The
              older chat / menu-choice detection stays as a fallback.
            - The walk threshold is learned (seeded from the logs: refused at
              27, worked at 47); the care section and next step know when a
              walk isn't possible without waiting for a refusal.
            - Energy at the start / end of each day in the history and CSV.
            - Only story text (not linkshell or party chat) counts as a
              watch reaction. Debug records the chocobo's target-bar %.
      v2.9  Comments throughout: a file map at the top, a header for every
            section, a comment on every function, event handler, saved
            setting, data table and command. No change to how it works.
      v2.8  Fix: phantom walks. The menu-navigation choice 243 (sent every time
            the trainer's main menu opens) could be learned as a walk, so a
            walk was counted each time the menu came up - even with no energy.
            Only action choices (256 and up, like walk 10994 / watch 12530)
            can be learned now, and a wrongly learned choice is removed on
            load. A walk that goes through after "out of energy" (e.g. after
            a Chocolixir) clears the out-of-energy mark. //crt undo walk <n>
            takes back several at once.
      v2.7  Fix: "function at line 2975 has more than 60 upvalues" on load.
            The command handler is split into parts (Lua 5.1 / LuaJIT, which
            Windower uses, allows a function only 60 outside variables).
            Now checked with LuaJIT itself before release.
      v2.6  - Days follow the game's reset (Japanese midnight, 10 AM Eastern)
              instead of local midnight; today's counts were moved over.
            - Old commands from the original addon removed (care tasks
              feed/exercise/outing/story, capture, type, focus).
            - Walk menu choices are learned: at a new trainer, the first walk
              refused for energy teaches the addon that trainer's walk choice.
            - "Completely full" check-up: the plan says to skip the carrots
              today, and feeding while full warns about a stomachache.
            - Care plan tracking: //crt careplan <plan> [days]; the panel shows
              the plan you set, its day, and whether it matches the guide.
            - Stat changes: a ^ / v marks a stat that changed rank in the last
              2 days; //crt history lists the days and every rank change.
            - Walk finds ("found this on one of your walks") and walk friends
              ("getting along well with Chaos", 3 meetings = a story) are
              tracked; //crt finds, //crt friends.
            - Visit reminder: entering your trainer's town (or logging in) with
              today's care unfinished gives a chat reminder and shows the panel
              for 20 seconds. //crt reminder on|off.
            - README.md (install, panel, commands, guide, debug logs).
      v2.5  Lost chocobo chick tracker (owner lists from BG-Wiki): the
            trainer's clues (first letter, race / gender, job) are read
            as you get them on short walks, and the panel narrows down who
            the owner can be, with map positions. //crt chick.
      v2.4  Stories and conditions, from Valdimar's lists:
            - Story key items are recorded when obtained; the panel lists
              them with the ability each teaches (Burrow / Bore marked skip).
              //crt stories shows all six and how to get them in your nation.
            - The guide's phase 3 says which story to tell or still get:
              Treasure Finder plus a second ability (Canter by default;
              //crt guide ability canter|gallop|auto-regen).
            - Abilities are read from the check-up ("Last of all, ...").
            - Conditions (Injured, Stomachache, Happiness, Spoiled, ...) are
              read from the check-up and shown with their cure; a cure
              comes first in the next-step hint. //crt conditions lists all.
      v2.3  From the first debug log:
            - Walks are counted automatically (the walk menu choice, unless
              the NPC says the chocobo "needs more energy").
            - "Needs more energy" is tracked: the chick's daily care is now
              walks until it can't walk, then watches until it can't.
            - Feeding is counted from "<you> gives the chocobo a <food>."
              (the trade packet was sent twice per carrot, double counting).
            - "Your chocobo seems to be a male!" is no longer read as food.
      v2.2  Debug mode records everything to a file in data/debug/: every
            chat line (with its chat mode and hidden bytes), NPC conversation
            starts and ends, menu choices, trades, status changes and zoning,
            plus what the addon counted. Nothing extra is shown in chat.
      v2.1  Feeding: every food the raising NPCs take (greens, carrots,
            pastes, wildgrass, worms, Chocolixirs, salads, Potion) is counted
            when you trade it. The food line shows how many you've fed today,
            the plan counts your Vomp Carrots (x/3), and the history / CSV
            records what was fed. //crt feed shows or adds feedings.
      v2.0  Load message on two lines: author and version first, then the
            character profile and panel mode.
      v1.9  Load message styled like BirdUp / InfoGear: "[CarrotTime] ..." in
            the same light blue (chat colour 207; //crt chatcolor <n> to change).
      v1.8  Author is Valdimar @ Phoenix; the load message names the author.
      v1.7  Daily history of the chocobo's stats (and day, food, care,
            phase), exported with //crt export to a .csv file.
            Racing section: reads the VCS registration / chococard in your
            inventory for exact stat values (0-255), abilities, personality
            and weather, and works out riding speed and time. //crt card
            links a card; //crt paddock shows the chocobo you're viewing in
            the Chocobo Circuit paddocks. Card layout and riding formulas
            from Ivaar's chococard addon.
      v1.6  New raising guide in 4 phases: build STR/END to Outstanding
            (3 Vomp Carrots + a walk daily) -> racing stables, trade STR/END
            for DSC/RCP until DSC is Average (96+) -> learn Treasure Finder
            and one other ability (not Burrow/Bore) -> let DSC drop and raise
            END/RCP. The phase moves on by itself; targets follow the phase.
      v1.5  Built-in raising guide: a digger with racing stats raised first
            (//crt guide). The panel shows today's plan and what's next, and
            the default targets are STR SS, END C, DSC SS, RCP D.
            Watches and scolds are shown only when they happened and no
            longer count as care; walks are the daily care.
            Stage days corrected from the guides: Chick to day 19,
            Adolescent 19-28, Adult 29+, retires on day 129.
      v1.4  Panel height follows the content again; the width stays fixed.
            Long lines (abilities, food, NPC text) wrap or are shortened so
            nothing ever widens the panel.
      v1.3  Today's care for the chick on two rows: "Watch # Scold #", then
            "Walk #/#". Panel height is now 21 lines to fit it.
      v1.2  The panel is always the same size: fixed width (fits the
            longest stat, "Better than average | B") and a fixed number of
            lines, with the next step kept at the bottom.
      v1.1  Stats show the game's word and the letter, e.g. "Poor | F",
            on the panel, in //crt status and in the update message.
      v1.0  Short walks are limited to 3 a day: the panel shows walk 0/3 and
            the next-step hint counts the walks left. New //crt reload
            (saves this character's data first, then reloads the addon).
      v0.9  Reads the chocobo check-up: name ("Let's see how <name> is
            doing today"), food level, liked day type, and the four stats
            (Poor..First-Class -> F..SS). Food and liked days shown on the
            panel. Leisurely and brisk walks are now one "walk". Ranks go
            F..SS (SSS removed: the game tops out at First-Class).
      v0.8  Chick-stage care: watching, scolding and leisurely / brisk walks
            are counted per day and shown on the panel. Watches are still
            counted automatically. New: //crt scold, //crt walk leisurely|brisk.
            Debug now shows every line of a raising-NPC conversation.
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

    File layout (search for the section names):
      Defaults ................ everything saved per character
      Constants / State ....... stats, ranks, runtime variables
      Chat helpers, Table helpers and persistence, Utilities
                                save / load, the game day (Japanese midnight), age, stage
      Derived info for the panel care counts, energy, food, stat changes
      Stories and conditions .. story and condition lists from Valdimar
      Lost chocobo chick ...... owners per nation, clue reading
      Raising guide ........... the 4 phases, today's plan
      Chocobo cards ........... card decoding, riding speed / time, paddock
      Daily history and CSV ... snapshot per day, //crt export, next-step advice
      UI ...................... panel layout and drawing
      Commands ................ command helper functions
      Chat-detection state, NPC conversations, Debug log
      Feeding, walk and watch detection
      Chat parsing ............ every chat line is read here
      Help and the command handler (split in parts for Lua 5.1)
      Character loading ....... load / login / logout / every-frame refresh
      Visit reminder

    Commands (//crt or //carrottime):
      //crt help                      List commands
      //crt reload                    Save, then reload the addon (your data
                                      is kept per character)
      //crt mode npc | always         npc (default): the panel only appears while
                                      you talk to a chocobo raising NPC.
                                      always: the panel stays on screen.
      //crt show | hide | toggle      Show / hide the panel (in npc mode, show
                                      opens it until you hide it)
      //crt npc [add|remove <name>]   List / change the NPCs that open the panel
      //crt debug [on|off]            Record everything (chat lines, NPC
                                      menus, choices, trades) to a file in
                                      data/debug/ to send for troubleshooting
      //crt compact                   Toggle a smaller panel (stats + next step)
      //crt pos <x> <y>               Move the panel (or just drag it)
      //crt name <name>               Chocobo's name
      //crt stat <stat> <rank>        Record a current stat (F..SS, or the
                                      game's word: poor, average, ...)
      //crt target <stat> <rank>      Set a target rank for a stat
      //crt hatch <YYYY-MM-DD>        Hatch date (age is worked out from it)
      //crt age <days>                Set age by hand (clears hatch date)
      //crt watch                     Add one egg-phase watch (also counted
                                      automatically when you watch the egg)
      //crt watches <number>          Set the egg-phase watch count
      //crt stories                   All stories: ability, how to get, owned
      //crt story <name> [off]        Record a story key item by hand
      //crt conditions                All conditions, their effects and cures
      //crt chick                     Lost chick quest: clues and possible owners
      //crt chick <letter|race|job>   Add a clue by hand (e.g. chick merchant)
      //crt chick reset | done        Start over after a wrong owner / finish
      //crt feed                      Today's feedings (counted from trades)
      //crt feed <food> [n]           Add a feeding by hand (e.g. feed vomp 3)
      //crt unfeed <food> [n]         Take one back
      //crt scold                     Log a scold (Chick stage)
      //crt walk                      Log a short walk (Chick stage, 3 a day)
      //crt undo watch|scold|walk [n] Take one (or n) back off today
      //crt ability <name> [off]      Record a learned ability (or remove it)
      //crt care                      Today's care so far and time to reset
      //crt careplan [plan] [days]     Record the care plan you set at the trainer
      //crt history                   Last days and every stat rank change
      //crt finds | friends           Walk finds / walk friends (3 = a story)
      //crt reminder on|off           Visit reminder when care isn't done
      //crt note <text>               Add a note
      //crt notes [clear]             List / clear notes
      //crt race win | loss | place <n>
      //crt race history              Last 10 races and totals
      //crt status                    Summary in chat
      //crt guide [on|off]            Show the raising plan / show or hide it
                                      on the panel
      //crt guide phase <1-4>         Jump to a phase of the plan
      //crt guide ability <name>      Second ability: canter, gallop, auto-regen
      //crt energy                    Energy, walks / watches left, recovery rate
      //crt chatcolor <n>             Chat colour of the load message (207)
      //crt export                    Save the daily history to
                                      data/<Character>_history.csv
      //crt card [n]                  Read chocobo cards in your inventory /
                                      link card n to this chocobo
      //crt paddock                   Show the chocobo you're viewing in the
                                      Chocobo Circuit paddocks
      //crt reset confirm             Wipe this character's chocobo data

    Stats: strength (str), endurance (end), discernment (dsc), receptivity (rcp)
    Care tasks: feed, exercise, outing, care, story

    This addon is a manual tracker and advisor. It does not read
    chocobo status directly from the game client.

    Data is saved per character in addons/CarrotTime/data/<Character>.lua

    Credits: the chocobo card / paddock data layout and the riding speed
    and time formulas come from Ivaar's chococard addon
    (github.com/Ivaar/Windower-addons/tree/master/chococard).
]]

_addon.name = 'CarrotTime'
_addon.author = 'Valdimar @ Phoenix'
_addon.version = '3.2'
_addon.commands = {'crt', 'carrottime'}

-- Says in chat when a newer version is on GitHub (once per load; see update_check.lua)
require('update_check').start({
    name    = 'CarrotTime',
    version = _addon.version,
    url     = 'https://raw.githubusercontent.com/Valdimar/CarrotTime/main/CarrotTime/CarrotTime.lua',
    page    = 'github.com/Valdimar/CarrotTime',
})

-- Windower libraries: texts draws the panel, packets reads NPC menu / trade packets.
local texts = require('texts')
local packets = require('packets')

------------------------------------------------------------------------
-- Defaults
------------------------------------------------------------------------

-- Everything saved per character, with its starting value. A save file from an older
-- version gets any missing keys filled in from here when it loads.
local defaults = {
    chocobo_name = 'My Chocobo',

    hatch_date = '',
    age_days = 0,

    egg_watches = 0,
    last_watch_date = '',

    racing_targets = {          -- follow the raising guide's phase (GUIDE_PHASES)
        strength = 'S',
        endurance = 'S',
        discernment = 'F',
        receptivity = 'F',
    },

    stats = {
        strength = 'F',
        endurance = 'F',
        discernment = 'F',
        receptivity = 'F',
    },

    abilities = {},
    care_log = {},

    -- From the NPC check-up
    food_level = '',
    food_date = '',
    likes = '',        -- [YYYY-MM-DD] = {watch = n, scold = n, ...}
    race_history = {},
    notes = {},

    -- NPCs that open the panel in "npc" mode (the VCS raising NPCs).
    raising_npcs = {'Hantileon', 'Zopago', 'Pulonono'},

    ui = {
        x = 200,
        y = 200,
        visible = true,     -- used in "always" mode
        compact = false,
        load_color = 207,   -- chat colour of the load message (matches BirdUp / InfoGear)
        mode = 'npc',       -- 'npc' or 'always'
        reminder = true,    -- remind when entering the trainer's town with care left
        guide = true,       -- show the raising plan on the panel
    },
    guide_phase = 1,        -- current phase of the raising guide (1-4)
    second_ability = 'Canter',  -- the guide's second ability next to Treasure Finder
    stories = {},           -- [story name] = date obtained
    nation = '',            -- where it's raised (from the raising NPC)
    conditions = {},        -- condition names from the last check-up
    conditions_date = '',
    lost_chick = {active = false, done = false, initial = '', race = '', gender = '', job = ''},
    care_plan = {name = '', start = '', days = 0},   -- the plan set at the trainer
    stat_changes = {},      -- [stat] = {from, to, date, day}: last rank change
    walk_finds = {},        -- [item] = times found on walks
    energy = false,         -- last energy reading {value = 0-100, time = os.time()}
    energy_stats = {        -- learned from results; seeded from Valdimar's logs
        walk_ok_min = 47,       -- lowest energy a walk has gone through at
        walk_refused_max = 27,  -- highest energy a walk has been refused at
        walk_cost = 23.5,       -- average energy a walk uses
        watch_cost = 3.2,       -- average energy a watch uses
        rate = 1.37,            -- energy recovered per hour (measured between visits)
    },
    friends = {},           -- [name] = meetings on walks (3 = a story)
    learned_walk_options = {},  -- walk menu choices learned at other trainers
    history = {},           -- [YYYY-MM-DD] = snapshot of the day (see snapshot_today)
    card = false,           -- last read of this chocobo's card (see read_card)
    card_fingerprint = '',  -- which inventory card belongs to this chocobo
}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

-- The four chocobo stats, in panel order.
local STAT_NAMES = {'strength', 'endurance', 'discernment', 'receptivity'}

-- Display names for the stats.
local STAT_LABELS = {
    strength = 'Strength',
    endurance = 'Endurance',
    discernment = 'Discernment',
    receptivity = 'Receptivity',
}

-- Short names accepted in commands (//crt stat str average).
local STAT_ALIASES = {
    str = 'strength', strength = 'strength',
    ['end'] = 'endurance', endurance = 'endurance',
    dsc = 'discernment', dis = 'discernment', discernment = 'discernment',
    rcp = 'receptivity', rec = 'receptivity', receptivity = 'receptivity',
}

-- Stat ranks, lowest to highest (each is 32 points of 0-255).
local RANKS = {'F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS'}

-- The game's words for each rank (shown when checking on the chocobo).
local RANK_WORD = {
    F = 'Poor', E = 'Substandard', D = 'A bit deficient', C = 'Average',
    B = 'Better than average', A = 'Impressive', S = 'Outstanding', SS = 'First-Class',
}
-- Reverse lookup: the game's word (lower case) -> rank letter.
local WORD_RANK = {}
for rank, word in pairs(RANK_WORD) do
    WORD_RANK[word:lower()] = rank
end
WORD_RANK['oustanding'] = 'S'       -- common misspelling

-- "Poor | F": the game's word, then the letter.
local function rank_text(rank)
    return (RANK_WORD[rank] or '?') .. ' | ' .. tostring(rank)
end
WORD_RANK['first class'] = 'SS'
-- Rank letter -> 1..8, for comparing ranks.
local RANK_VALUE = {}
for i, rank in ipairs(RANKS) do
    RANK_VALUE[rank] = i
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

local settings          -- current character's data
local char_name         -- nil until logged in
local ui                -- texts object
local talking = false   -- currently in a conversation with a raising NPC
local talking_since = 0  -- os.time() talking last started / stopped
local peek = false      -- panel opened by hand while in npc mode
local peek_until = 0    -- os.clock() until which a reminder shows the panel
local debug = false     -- //crt debug: record everything to data/debug/<time>.txt
local debug_path = nil  -- the current debug log file
local event_npc = nil   -- name of the NPC the current conversation started with

------------------------------------------------------------------------
-- Chat helpers
------------------------------------------------------------------------

-- Chat helpers: say() for normal messages (colour 200), err() for problems (colour 123).
local function say(msg)
    windower.add_to_chat(200, 'CarrotTime: ' .. msg)
end

-- Error / warning message in chat (red-ish colour 123).
local function err(msg)
    windower.add_to_chat(123, 'CarrotTime: ' .. msg)
end

------------------------------------------------------------------------
-- Table helpers and persistence
------------------------------------------------------------------------

-- Copy a table and everything inside it (so defaults are never shared or changed).
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

-- Turn a Lua value into Lua source text, used to write data/<Character>.lua.
-- Arrays first (in order), then the other keys sorted, so the file is stable between saves.
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

-- Path of this character's save file: addons/CarrotTime/data/<Character>.lua.
local function data_path(name)
    return windower.addon_path .. 'data/' .. name .. '.lua'
end

local history_hook      -- set later: records today's snapshot before saving
local debug_log_hook    -- set later: writes a line to the debug file

-- Write this character's data to disk. Records today's history snapshot first
-- (history_hook) so the daily history is always up to date.
local function save()
    if not char_name or not settings then
        return
    end
    if history_hook then
        history_hook()
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

-- Read a character's save file. A missing or damaged file starts fresh; any setting
-- added in a newer version is filled in from `defaults`.
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

-- Lower-case any value as a string (nil -> '').
local function lower(value)
    return tostring(value or ''):lower()
end

-- A whole number 0 or above, or nil (for commands that take a count).
local function valid_number(value)
    local number = tonumber(value)
    if number and number >= 0 and number == math.floor(number) then
        return number
    end
    return nil
end

-- The game's day: it resets at Japanese midnight (15:00 UTC, 10 AM Eastern
-- standard time), so "today" is the date in Japan.
local function today()
    return os.date('!%Y-%m-%d', os.time() + 9 * 3600)
end

-- Seconds until the next reset.
local function seconds_to_reset()
    local t = os.time() + 9 * 3600
    local h, m, sec = tonumber(os.date('!%H', t)), tonumber(os.date('!%M', t)), tonumber(os.date('!%S', t))
    return 86400 - (h * 3600 + m * 60 + sec)
end

-- 'YYYY-MM-DD' -> os.time at noon that day (noon avoids daylight-saving edge cases).
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

-- The chocobo's age in days: worked out from the hatch date (which the status report
-- sets), or the age typed with //crt age when there's no hatch date.
local function current_age()
    local hatch_time = date_to_time(settings.hatch_date)
    if hatch_time then
        local now = date_to_time(today())
        return math.max(0, math.floor((now - hatch_time) / 86400 + 0.5))
    end
    return tonumber(settings.age_days) or 0
end

-- Growth stage from the age: Egg (0-3), Chick (4-18), Adolescent (19-28), Adult (29-128),
-- Retired (129+).
local function current_stage()
    local age = current_age()

    if age < 4 then
        return 'Egg'
    elseif age < 19 then
        return 'Chick'
    elseif age < 29 then
        return 'Adolescent'
    elseif age < 129 then
        return 'Adult'
    end
    return 'Retired'
end

-- Accepts a letter (F..SS, SSS is treated as SS) or the game's word ('Poor', 'Average')
-- and returns the letter, or nil.
local function normalize_rank(rank)
    local word = tostring(rank or ''):lower():gsub('^%s+', ''):gsub('[%s%.!]+$', '')
    if WORD_RANK[word] then
        return WORD_RANK[word]
    end
    rank = tostring(rank or ''):upper()
    if rank == 'SSS' then
        return 'SS'
    end
    if RANK_VALUE[rank] then
        return rank
    end
    return nil
end

-- 'str', 'end', 'dsc', 'rcp' or the full name -> the full stat name.
local function normalize_stat(stat)
    return STAT_ALIASES[lower(stat)]
end

-- Rank -> 1 (F) .. 8 (SS), for comparing ranks.
local function rank_value(rank)
    return RANK_VALUE[normalize_rank(rank) or 'F'] or 1
end

-- 'a, b, c', or 'None recorded' for an empty list.
local function format_list(items)
    if not items or #items == 0 then
        return 'None recorded'
    end
    return table.concat(items, ', ')
end

-- 'treasure finder' -> 'Treasure Finder'.
local function title_case(s)
    return (tostring(s):gsub('(%a)([%w\']*)', function(a, b)
        return a:upper() .. b:lower()
    end))
end

------------------------------------------------------------------------
-- Derived info for the panel
------------------------------------------------------------------------

-- Learned abilities, sorted, as a list.
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

-- Care you give at the raising NPC, counted per day.
local CARE_ACTIONS = {'watch', 'scold', 'walk'}
-- How each care action is named in chat.
local CARE_LABEL = {watch = 'watch', scold = 'scold', walk = 'walk'}
local CARE_LIMIT = {}                -- no fixed limits: energy decides (see energy_out)

-- Daily limit for an action at the current stage (nil = no known limit).
local function care_limit(action)
    if current_stage() == 'Chick' then
        return CARE_LIMIT[action]
    end
    return nil
end

-- The NPC said "needs more energy" for this action today.
local function energy_out(action)
    local t = settings.care_log[today()]
    return t and t[action .. '_out'] == true or false
end

-- Today's entry in the care log ({walk = n, watch = n, scold = n, fed = {...}, ...}).
local function care_today()
    return settings.care_log[today()] or {}
end

-- How many times an action (walk / watch / scold) was done today.
local function care_count(action)
    return tonumber(care_today()[action]) or 0
end

-- Egg stage: has the egg been watched today?
local function watched_today()
    return care_count('watch') > 0 or settings.last_watch_date == today()
end

-- Foods a raising NPC accepts (in-game item names).
local FOODS = {
    'Gysahl Greens', 'Sharug Greens', 'Azouph Greens',                 -- affection
    'Vomp Carrot', 'Zegham Carrot', "San d'Orian Carrot",              -- stats
    'Carrot Paste', 'Herb Paste', 'Vegetable Paste', 'Worm Paste',     -- chick food
    'Gausebit Wildgrass', 'Tokopekko Wildgrass', 'Garidav Wildgrass',  -- medicine
    'Cupid Worm', 'Gregarious Worm', 'Parasite Worm',                  -- worms
    'Chocolixir', 'Hi-Chocolixir', 'Celerity Salad', 'Tornado Salad',  -- energy / cures
    'Potion', 'Chocotonic',
}
-- Lower-case food name -> proper name, for matching chat text and commands.
local FOOD_BY_LOWER = {}
for _, f in ipairs(FOODS) do
    FOOD_BY_LOWER[f:lower()] = f
end

-- Match typed text ("vomp", "azouph greens") to a food name.
local function find_food(text)
    text = tostring(text or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then
        return nil
    end
    if FOOD_BY_LOWER[text] then
        return FOOD_BY_LOWER[text]
    end
    for _, f in ipairs(FOODS) do
        if f:lower():sub(1, #text) == text then
            return f
        end
    end
    return nil
end

-- Today's feedings: {['Vomp Carrot'] = 3, ...}.
local function fed_today()
    return care_today().fed or {}
end

-- Feedings today: of one food, or of everything when `name` is nil.
local function fed_count(name)
    local t = fed_today()
    if name then
        return tonumber(t[name]) or 0
    end
    local n = 0
    for _, v in pairs(t) do
        n = n + (tonumber(v) or 0)
    end
    return n
end

-- "Vomp Carrot x3, Azouph Greens x1"
-- The last check-up said "completely full": more food today is force-feeding.
local function full_today()
    return settings.food_date == today() and settings.food_level:lower():find('completely full', 1, true) ~= nil
end

------------------------------------------------------------------------
-- Energy (0-100). The trainer's menu data carries the exact value; walks
-- cost ~23-24 and watches ~3-4. It does not refill at the daily reset: it
-- recovers slowly (~1.4 an hour), so between readings it's estimated.
------------------------------------------------------------------------

-- Energy now: the last reading, or an estimate from the recovery rate if the
-- reading is older than a few minutes. Returns value, estimated (or nil).
local function energy_now()
    local e = settings.energy
    if not e then
        return nil
    end
    local hours = (os.time() - e.time) / 3600
    if hours < 0.05 then
        return e.value, false
    end
    local rate = tonumber(settings.energy_stats.rate) or 0
    return math.min(100, math.floor(e.value + rate * hours)), true
end

-- Can it walk at this energy? 'yes', 'no', or 'maybe' (between the learned limits).
local function walk_status(e)
    local st = settings.energy_stats
    if e >= st.walk_ok_min then
        return 'yes'
    elseif e <= st.walk_refused_max then
        return 'no'
    end
    return 'maybe'
end

-- Walks possible from this energy (each walk uses walk_cost).
local function walks_left(e)
    local st = settings.energy_stats
    if walk_status(e) ~= 'yes' then
        return 0
    end
    return 1 + math.floor((e - st.walk_ok_min) / st.walk_cost)
end

-- Watches possible from this energy (a watch needs 3+ and uses watch_cost).
local function watches_left(e)
    if e < 3 then
        return 0
    end
    return math.floor((e - 3) / settings.energy_stats.watch_cost) + 1
end

-- No more walks today: refused for energy, or too little energy for one.
local function walks_blocked()
    if energy_out('walk') then
        return true
    end
    local e = energy_now()
    return e ~= nil and walk_status(e) == 'no'
end

-- No more watches today: refused, or too little energy for one.
local function watches_blocked()
    if energy_out('watch') then
        return true
    end
    local e = energy_now()
    return e ~= nil and watches_left(e) == 0
end

-- Remember a stat's rank change for the panel marker and //crt history.
local function note_stat_change(stat, old, new)
    if old and new and old ~= new then
        settings.stat_changes[stat] = {from = old, to = new, date = today(), day = current_age()}
    end
end

-- '^' / 'v' when a stat changed rank in the last 2 game days.
local function stat_marker(stat)
    local ch = settings.stat_changes[stat]
    if not ch or not ch.date then
        return nil
    end
    local age = (date_to_time(today()) - date_to_time(ch.date)) / 86400
    if age > 1.5 then
        return nil
    end
    return rank_value(ch.to) > rank_value(ch.from) and '^' or 'v'
end

-- Feedings as text: 'Vomp Carrot x3, Azouph Greens x1'.
local function fed_text(t)
    t = t or fed_today()
    local names = {}
    for name in pairs(t) do
        names[#names + 1] = name
    end
    table.sort(names)
    local parts = {}
    for _, name in ipairs(names) do
        parts[#parts + 1] = name .. ' x' .. t[name]
    end
    return table.concat(parts, ', ')
end

------------------------------------------------------------------------
-- Stories (key items that teach abilities) and conditions.
-- From Valdimar's choco_stories / choco_conditions lists.
------------------------------------------------------------------------

-- Which nation each raising NPC is in (decides story walk types and owner lists).
local NPC_NATION = {zopago = 'Bastok', hantileon = "San d'Oria", pulonono = 'Windurst'}

-- The six stories: the ability each teaches, who tells it, and how to get it in each
-- nation ('all' = same everywhere).
local STORIES = {
    {key = 'happy', name = 'Story of a happy chocobo', ability = 'Auto-Regen', teller = 'Bashraf',
        how = {all = 'Win "Compete Against Others" 3 times'}},
    {key = 'youthful', name = 'Story of a youthful chocobo', ability = 'Bore', teller = 'Pulonono',
        how = {Bastok = 'Long walk', ["San d'Oria"] = 'Regular walk', Windurst = 'Short walk'}},
    {key = 'worrisome', name = 'Story of a worrisome chocobo', ability = 'Burrow', teller = 'Zopago',
        how = {Bastok = 'Short walk', ["San d'Oria"] = 'Regular walk', Windurst = 'Long walk'}},
    {key = 'curious', name = 'Story of a curious chocobo', ability = 'Canter', teller = 'Brutus',
        how = {all = 'Long walk'}},
    {key = 'impatient', name = 'Story of an impatient chocobo', ability = 'Gallop', teller = 'Hantileon',
        how = {Bastok = 'Regular walk', ["San d'Oria"] = 'Short walk', Windurst = 'Regular walk'}},
    {key = 'diligent', name = 'Story of a diligent chocobo', ability = 'Treasure Finder',
        teller = 'Owner of Lost Chick', how = {all = 'Lost chick quest'}},
}
local SKIP_ABILITY = {Burrow = true, Bore = true}   -- only add junk to the dig pool
-- Every ability a raised chocobo can learn (for reading the check-up).
local ABILITY_NAMES = {'Treasure Finder', 'Auto-Regen', 'Gallop', 'Canter', 'Burrow', 'Bore'}

-- The story that teaches an ability ('Canter' -> Story of a curious chocobo).
local function story_for_ability(ability)
    for _, st in ipairs(STORIES) do
        if st.ability:lower() == tostring(ability):lower() then
            return st
        end
    end
end

-- "worrisome", "story of a worrisome chocobo", "burrow" -> the story
local function find_story(text)
    text = tostring(text or ''):lower():gsub('^%s+', ''):gsub('[%s%.!]+$', '')
    if text == '' then
        return nil
    end
    for _, st in ipairs(STORIES) do
        if st.key == text or st.name:lower() == text or st.ability:lower() == text
            or st.key:sub(1, #text) == text then
            return st
        end
    end
end

-- Does the player hold this story key item?
local function has_story(st)
    return settings.stories[st.name] ~= nil
end

-- How to get a story where you're raising (the nation comes from the raising NPC).
local function story_how(st)
    if st.how.all then
        return st.how.all
    end
    local nation = settings.nation ~= '' and settings.nation or nil
    if nation and st.how[nation] then
        return st.how[nation] .. ' (' .. nation .. ')'
    end
    local parts = {}
    for _, n in ipairs({'Bastok', "San d'Oria", 'Windurst'}) do
        parts[#parts + 1] = n .. ': ' .. st.how[n]
    end
    return table.concat(parts, '; ')
end

-- Every condition: kind, effect, cure, and the words that show it in the check-up
-- (`match`). Good conditions have good = true and no cure.
local CONDITIONS = {
    {name = 'Injured', kind = 'Physical', effect = 'Physical care plans less effective',
        cure = 'Feed Gausebit Wildgrass', match = {'injur'}},
    {name = 'Stomachache', kind = 'Physical', effect = 'Physical care plans less effective',
        cure = 'Feed Garidav Wildgrass', match = {'stomach'}},
    {name = 'Minor Illness', kind = 'Physical', effect = 'Physical care plans less effective',
        cure = 'Feed Tokopekko Wildgrass or Celerity Salad', short = 'Feed Tokopekko Wildgrass',
        match = {'minor illness', 'slightly ill', 'a little sick', 'a bit sick'}},
    {name = 'Serious Illness', kind = 'Physical', effect = 'Physical care plans less effective',
        cure = 'Feed Tokopekko Wildgrass or Celerity Salad', short = 'Feed Tokopekko Wildgrass',
        match = {'serious illness', 'seriously ill', 'very sick'}},
    {name = 'Bursting with Vitality', kind = 'Physical', good = true,
        effect = 'Physical plans more effective; better chance to learn from "Tell a Story"',
        match = {'bursting with vitality'}},
    {name = 'Depressed', kind = 'Emotional', effect = 'Care plans less effective',
        cure = 'Raise affection', match = {'depress'}},
    {name = 'Happiness', kind = 'Emotional', good = true,
        effect = 'Care plans more effective; Vitality / Intelligence more likely',
        match = {'extremely happy', 'happiness'}},
    {name = 'Bored and Restless', kind = 'Mental', effect = 'Mental care plans less effective',
        cure = 'Race against others', match = {'bored', 'restless'}},
    {name = 'Spoiled', kind = 'Mental', effect = 'Mental care plans less effective',
        cure = 'Scold it', match = {'spoiled'}},
    {name = 'In Love', kind = 'Mental', effect = 'Mental care plans sometimes less (or more) effective',
        cure = 'Feed Celerity Salad', match = {'in love'}},
    {name = 'Sparkling with Intelligence', kind = 'Mental', good = true,
        effect = 'Mental plans more effective; better chance to learn from "Tell a Story"',
        match = {'sparkling with intelligence'}},
    {name = 'Crying at Night', kind = 'Other', effect = 'Not harmful: part of the Chocobo Whistle quest',
        cure = 'Carry the White Handkerchief, then return it to the trainer', short = 'Carry the White Handkerchief',
        match = {'crying at night', 'cries at night'}},
    {name = 'Asleep', kind = 'Stops development', effect = 'Care plans cannot be used',
        cure = 'Feed Chocotonic', match = {'asleep', 'fast sleep'}},
    {name = 'Run Away', kind = 'Stops development', effect = 'Care plans cannot be used',
        cure = 'Wait for its return', match = {'run away', 'ran away', 'runaway'}},
}
-- Condition name -> its entry.
local CONDITION_BY_NAME = {}
for _, c in ipairs(CONDITIONS) do
    CONDITION_BY_NAME[c.name] = c
end

------------------------------------------------------------------------
-- Lost chocobo chick mini-quest (owner lists from BG-Wiki). A short walk
-- turns up a lost chick; take it home, then later short walks give clues
-- from the trainer: the owner's first letter, race and gender, and job.
-- Ask the matching NPC: the right owner gives Story of a diligent chocobo
-- (Treasure Finder). A wrong guess means starting over at the trainer.
------------------------------------------------------------------------

-- Possible owners per nation: name, first letter, race, gender, job, map position.
local CHICK_OWNERS = {
    Bastok = {
        {'Abd-al-Raziq', 'A', 'hume', 'male', 'guild worker', 'J-7'},
        {'Azima', 'A', 'hume', 'female', 'guild worker', 'J-7'},
        {'Deegis', 'D', 'galka', 'male', 'merchant', 'H-6'},
        {'Drangord', 'D', 'galka', 'male', 'miner', 'D-7'},
        {'Galdeo', 'G', 'galka', 'male', 'merchant', 'E-6'},
        {'Gray Wolf', 'G', 'galka', 'male', 'watchman', 'H-7'},
        {'Gerbaum', 'G', 'galka', 'male', 'miner', 'F-8'},
        {'Griselda', 'G', 'hume', 'female', 'merchant', 'H-5'},
    },
    ["San d'Oria"] = {
        {'Carautia', 'C', 'elvaan', 'female', 'merchant', 'K-8'},
        {'Cletae', 'C', 'elvaan', 'female', 'merchant', 'D-8'},
        {'Coderiant', 'C', 'elvaan', 'male', 'information guide', 'F-8'},
        {'Cahaurme', 'C', 'elvaan', 'male', 'watchman', 'J-9'},
        {'Corua', 'C', 'elvaan', 'female', 'merchant', 'G-9'},   -- old Elvaan woman
        {'Luthiaque', 'L', 'elvaan', 'male', 'town information guide', 'G-9'},
        {'Lanqueron', 'L', 'elvaan', 'male', 'package deliverer', 'I-9'},
        {'Violitte', 'V', 'elvaan', 'female', 'merchant', 'G-10'},
        {'Valderotaux', 'V', 'elvaan', 'male', 'merchant', 'K-6'},
    },
    Windurst = {
        {'Gioh Ajihri', 'G', 'mithra', 'female', 'hunter', 'K-5'},
        {'Gottah Maporushanoh', 'G', 'mithra', 'female', 'adventurer', 'H-10'},
        {'Kyaa Taali', 'K', 'mithra', 'female', 'guild worker', 'H-13'},
        {'Kapeh Myohrye', 'K', 'mithra', 'female', 'hunter', 'K-7'},
        {'Kopuro-Popuro', 'K', 'tarutaru', 'male', 'ministry worker', 'H-10'},
        {'Kororo', 'K', 'tarutaru', 'female', 'ministry worker', 'H-9'},
        {'Ponono', 'P', 'tarutaru', 'female', 'guild worker', 'G-12'},
        {'Peshi Yohnts', 'P', 'mithra', 'female', 'guild worker', 'H-13'},
    },
}
-- Jobs the trainer's job clue can name (longest first so 'town information guide'
-- matches before 'information guide').
local CHICK_JOBS = {'town information guide', 'information guide', 'package deliverer', 'guild worker',
    'ministry worker', 'merchant', 'miner', 'watchman', 'hunter', 'adventurer'}
-- Races the race clue can name.
local CHICK_RACES = {'hume', 'elvaan', 'galka', 'mithra', 'tarutaru'}

-- Which nation's owner list to use: where the chocobo is raised (Bastok if unknown).
local function chick_nation()
    return (settings.nation ~= '' and CHICK_OWNERS[settings.nation]) and settings.nation or 'Bastok'
end

-- Owners that fit every clue so far.
local function chick_candidates()
    local c = settings.lost_chick
    local out = {}
    for _, o in ipairs(CHICK_OWNERS[chick_nation()]) do
        local name, initial, race, gender, job = o[1], o[2], o[3], o[4], o[5]
        if (c.initial == '' or c.initial == initial)
            and (c.race == '' or c.race == race)
            and (c.gender == '' or c.gender == gender)
            and (c.job == '' or job:find(c.job, 1, true) or c.job:find(job, 1, true)) then
            out[#out + 1] = o
        end
    end
    return out
end

-- The clues so far as text: 'name G..., female hume, merchant'.
local function chick_clue_text()
    local c = settings.lost_chick
    local parts = {}
    if c.initial ~= '' then parts[#parts + 1] = 'name ' .. c.initial .. '...' end
    if c.race ~= '' or c.gender ~= '' then
        parts[#parts + 1] = (c.gender ~= '' and (c.gender .. ' ') or '') .. (c.race ~= '' and c.race or '')
    end
    if c.job ~= '' then parts[#parts + 1] = c.job end
    return #parts > 0 and table.concat(parts, ', ') or 'no clues yet'
end

-- Read clues from one line of text. Returns true if anything was learned.
local function chick_read_clue(low)
    local c = settings.lost_chick
    local learned = false
    -- First letter: "begins with 'G'", "starts with G", "first letter ... is G".
    local initial = low:match('begins? with [\'"]?(%a)[\'"]?') or low:match('starts? with [\'"]?(%a)[\'"]?')
        or low:match('first letter[^%a]+%a*[^%a]*is [\'"]?(%a)[\'"]?')
    if initial and c.initial ~= initial:upper() then
        c.initial = initial:upper()
        learned = true
    end
    -- Race: any race name in the line.
    for _, r in ipairs(CHICK_RACES) do
        if low:find(r, 1, true) and c.race ~= r then
            c.race = r
            learned = true
        end
    end
    -- Gender: 'female' / 'woman' first, since 'female' contains 'male'.
    local gender = (low:find('female', 1, true) or low:find('woman', 1, true)) and 'female'
        or ((low:find('male', 1, true) or low:find(' man', 1, true)) and 'male') or nil
    if gender and c.gender ~= gender then
        c.gender = gender
        learned = true
    end
    -- Job: the first (longest) job name found.
    for _, j in ipairs(CHICK_JOBS) do
        if low:find(j, 1, true) then
            if c.job ~= j then
                c.job = j
                learned = true
            end
            break
        end
    end
    return learned
end

-- Conditions from the last check-up that need a cure (good ones are left out).
local function bad_conditions()
    local out = {}
    for _, name in ipairs(settings.conditions or {}) do
        local c = CONDITION_BY_NAME[name]
        if c and not c.good and c.cure then
            out[#out + 1] = c
        end
    end
    return out
end

-- Care plans the trainer offers (set at the trainer; recorded by hand).
local CARE_PLANS = {'Basic Care', 'Rest', 'Take a Walk', 'Listen to Music', 'Exercise Alone',
    'Exercise in a Group', 'Play with Children', 'Play with Chocobos', 'Carry Packages',
    'Exhibit to the Public', 'Deliver Messages', 'Dig for Treasure', 'Act in a Play'}

-- Match typed text ('carry', 'dig') to a care plan name.
local function find_care_plan(text)
    text = tostring(text or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then
        return nil
    end
    for _, pl in ipairs(CARE_PLANS) do
        if pl:lower() == text then
            return pl
        end
    end
    for _, pl in ipairs(CARE_PLANS) do
        if pl:lower():sub(1, #text) == text or pl:lower():find(text, 1, true) then
            return pl
        end
    end
    -- The game's wording may differ ('Taking a walk', 'Listening to music'):
    -- match on a key word. 'play' comes last (after play with children / chocobos).
    local words = {
        {'basic', 'Basic Care'}, {'rest', 'Rest'}, {'walk', 'Take a Walk'}, {'music', 'Listen to Music'},
        {'alone', 'Exercise Alone'}, {'group', 'Exercise in a Group'}, {'children', 'Play with Children'},
        {'chocobos', 'Play with Chocobos'}, {'package', 'Carry Packages'}, {'exhibit', 'Exhibit to the Public'},
        {'public', 'Exhibit to the Public'}, {'message', 'Deliver Messages'}, {'treasure', 'Dig for Treasure'},
        {'dig', 'Dig for Treasure'}, {'play', 'Act in a Play'},
    }
    for _, w in ipairs(words) do
        if text:find('%f[%a]' .. w[1]) then
            return w[2]
        end
    end
end

-- {name, day (1-based), days, ended} for the recorded plan, or nil.
local function care_plan_state()
    local cp = settings.care_plan
    if not cp or cp.name == '' then
        return nil
    end
    local day = 1
    if date_to_time(cp.start) then
        day = math.floor((date_to_time(today()) - date_to_time(cp.start)) / 86400 + 0.5) + 1
    end
    local days = tonumber(cp.days) or 0
    return {name = cp.name, day = day, days = days, ended = days > 0 and day > days}
end

-- Advice when nothing else is due: the stat furthest below its target.
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

------------------------------------------------------------------------
-- Raising guide: a digger built off a racing-stat base, in 4 phases.
--
--  1. Build STR/END. Physical plans, 3 Vomp Carrots and a walk every day,
--     until STR and END are Outstanding (S, 192+; aim for ~200).
--  2. Put it in the racing stables, then trade STR/END for DSC/RCP until
--     DSC is Average (C, 96+) - the level it needs to learn abilities.
--  3. Hold DSC there and teach Treasure Finder plus one other ability.
--     Not Burrow / Bore: they only add junk to the dig pool.
--  4. Let DSC drop again and raise END/RCP.
--
-- The phase moves on by itself when its goal is reached (or with
-- //crt guide phase <n>). Plan effects (approximate, per day):
--   Take a Walk STR+/END+/DSC-/RCP-    Carry Packages STR++/END++/DSC--/RCP--
--   Exercise Alone STR+                Exercise in a Group END+
--   Deliver Messages STR+++/RCP--      Listen to Music STR-/END-/DSC+/RCP+
--   Exhibit to the Public STR--/END--/DSC++/RCP++   Act in a Play RCP+++/STR--
------------------------------------------------------------------------

-- The four phases: name and the stat targets shown on the stat bars.
local GUIDE_PHASES = {
    {name = 'Build STR/END',
        targets = {strength = 'S', endurance = 'S', discernment = 'F', receptivity = 'F'}},
    {name = 'Trade STR/END for DSC/RCP',
        targets = {strength = 'F', endurance = 'F', discernment = 'C', receptivity = 'C'}},
    {name = 'Learn abilities',
        targets = {strength = 'F', endurance = 'F', discernment = 'C', receptivity = 'F'}},
    {name = 'Raise END/RCP',
        targets = {strength = 'F', endurance = 'SS', discernment = 'F', receptivity = 'SS'}},
}

-- Is a stat at or above a rank?
local function at_least(stat, rank)
    return rank_value(settings.stats[stat]) >= rank_value(rank)
end

-- The raising guide's current phase, kept between 1 and 4.
local function guide_phase()
    local p = tonumber(settings.guide_phase) or 1
    return math.max(1, math.min(#GUIDE_PHASES, p))
end

-- Set the stat targets (the arrows on the stat bars) to the current phase's targets.
local function apply_guide_targets()
    for k, v in pairs(GUIDE_PHASES[guide_phase()].targets) do
        settings.racing_targets[k] = v
    end
end

-- Move to the next phase when the current one's goal is met.
-- Returns true if the phase changed.
local function guide_advance()
    local p = guide_phase()
    local nextp = p
    if p == 1 and at_least('strength', 'S') and at_least('endurance', 'S') then
        nextp = 2
    elseif p == 2 and at_least('discernment', 'C') then
        nextp = 3
    elseif p == 3 and #active_abilities() >= 2 then
        nextp = 4
    end
    if nextp ~= p then
        settings.guide_phase = nextp
        apply_guide_targets()
        return true
    end
    return false
end

-- Today's plan: {plan, why, until_, daily, next}
local function guide_step()
    local stage = current_stage()
    local p = guide_phase()
    if stage == 'Egg' then
        return {plan = 'Basic Care', why = 'Watch over the egg every day',
            daily = 'Watch over the egg', next = 'Phase 1: build STR/END'}
    elseif stage == 'Retired' then
        return {plan = 'Retired', why = 'Raising is finished'}
    end
    -- Chicks have their own plans (Take a Walk, Listen to Music).
    local young = (stage == 'Chick')

    -- Phase 1: STR + END. Carry Packages raises both; once one is at S, a plan for the other.
    if p == 1 then
        local str_done, end_done = at_least('strength', 'S'), at_least('endurance', 'S')
        local plan
        if young then
            plan = 'Take a Walk'
        elseif not str_done and not end_done then
            plan = 'Carry Packages'
        elseif not str_done then
            plan = (stage == 'Adult') and 'Deliver Messages' or 'Exercise Alone'
        else
            plan = 'Exercise in a Group'
        end
        return {plan = plan, why = 'STR + END first, everything else waits',
            until_ = 'STR + END are S',
            daily = full_today() and '3 Vomp Carrots: full today - skip'
                or young and ('3 Vomp Carrots (' .. math.min(3, fed_count('Vomp Carrot')) .. '/3)')
                or ('3 Vomp Carrots (' .. math.min(3, fed_count('Vomp Carrot')) .. '/3) + a walk'),
            daily2 = young and 'Walks, then watches, until no energy' or nil,
            next = 'Racing stables, then DSC/RCP'}
    -- Phase 2: trade STR/END for DSC/RCP until DSC is Average (96+).
    elseif p == 2 then
        return {plan = young and 'Listen to Music' or 'Exhibit to the Public',
            why = 'Register for racing first, then trade', until_ = 'DSC is C (96+)',
            daily = 'A walk', next = 'Learn abilities'}
    -- Phase 3: hold DSC with Basic Care and teach the two abilities by story.
    elseif p == 3 then
        -- Treasure Finder first, then the chosen second ability.
        local lines = {}
        for _, ability in ipairs({'Treasure Finder', settings.second_ability}) do
            local st = story_for_ability(ability)
            if st and not settings.abilities[ability] then
                if has_story(st) then
                    lines[#lines + 1] = 'Tell ' .. st.key .. ' story (' .. ability .. ')'
                else
                    lines[#lines + 1] = 'Get ' .. ability .. ': ' .. (st.how.all or st.how[settings.nation] or 'see //crt stories')
                end
            end
        end
        return {plan = 'Basic Care', why = 'Hold DSC at 96+ while it learns',
            until_ = '2 abilities learned', daily = lines[1] or 'Treasure Finder + 1 more',
            daily2 = lines[2], next = 'Let DSC drop, raise END/RCP'}
    end
    -- Phase 4: raise whichever of END / RCP is lower; DSC may drop.
    local plan = (rank_value(settings.stats.endurance) <= rank_value(settings.stats.receptivity))
        and 'Exercise in a Group' or 'Act in a Play'
    return {plan = plan, why = 'DSC can drop; raise lower of END/RCP',
        daily = 'A walk; Chocobucks help too', next = nil}
end

-- //crt guide's full text.
local GUIDE_TEXT = {
    'Goal: a digger built off a racing-stat base. Abilities: Treasure',
    'Finder + one other - not Burrow/Bore (they only add junk to digs).',
    'From the chick stage on, always have a stat care plan set at the',
    'trainer: plans raise stats every day without food (Basic Care gives',
    'none). The plan in use is read from the check-up ("Plan: ...").',
    ' Phase 1  Build STR/END to Outstanding (S, 192+ - aim for ~200).',
    '          3 Vomp Carrots and a walk every day (3 short walks as a',
    '          chick). Plans: Take a Walk (chick), Carry Packages, then',
    '          Exercise Alone / Deliver Messages or Exercise in a Group',
    '          for whichever of STR/END is behind.',
    ' Phase 2  Put it in the racing stables. Then trade STR/END for',
    '          DSC/RCP (Exhibit to the Public; Listen to Music as a chick)',
    '          until DSC is Average (C, 96+) - enough to learn abilities.',
    ' Phase 3  Basic Care to hold DSC at 96+. Tell stories to teach',
    '          Treasure Finder (diligent story: lost chick quest, from a',
    '          short walk - //crt chick tracks the clues) and a',
    '          second ability (Canter by default: long walk). Never tell',
    '          the worrisome (Burrow) or youthful (Bore) stories.',
    '          Bursting with Vitality / Sparkling with Intelligence days',
    '          give a better chance to learn. //crt stories lists them.',
    ' Phase 4  Let DSC drop. Raise END/RCP: Exercise in a Group (END),',
    '          Act in a Play (RCP). Chocobucks can raise them too.',
    'Phases move on by themselves; //crt guide phase <n> jumps to one.',
    'Note: care plans are said to stop changing stats around day 65.',
}

-- //crt guide: the whole plan in chat, plus what to do right now.
local function show_guide()
    local step = guide_step()
    say('raising guide - phase ' .. guide_phase() .. '/4: ' .. GUIDE_PHASES[guide_phase()].name
        .. ' (day ' .. current_age() .. ', ' .. current_stage() .. ')')
    for _, l in ipairs(GUIDE_TEXT) do
        windower.add_to_chat(207, '  ' .. l)
    end
    windower.add_to_chat(200, '  Now: ' .. step.plan .. ' - ' .. step.why
        .. (step.until_ and (' (until ' .. step.until_ .. ')') or ''))
end

------------------------------------------------------------------------
-- Chocobo cards (VCS registration, CRA racing forms, chococards).
-- Data layout and riding formulas from Ivaar's chococard addon; this is
-- an independent implementation of that layout.
--   bytes 0-3  STR, END, DSC, RCP values (0-255; rank = value / 32)
--   byte 4+    DNA: three 3-bit colour genes
--   byte 5     bit 1: two 4-bit ability ids
--   byte 6     bit 1: temperament (3 bits), bit 4: weather (4 bits)
--   byte 7     bit 0: gender, bit 1: colour (3), bit 4: jockey size (3)
------------------------------------------------------------------------

-- Card codes and item ids, in one table (Lua 5.1's 200-local limit).
local CARD = {}
-- Item ids of cards that carry chocobo data in their extdata: VCS registration card,
-- chococards, CRA racing forms.
CARD.ITEMS = {[2313] = true, [2339] = true, [2342] = true, [2402] = true}
-- Card codes -> names (abilities, personality, colour, gender, weather like / dislike).
CARD.ABILITY = {[0] = 'None', 'Gallop', 'Canter', 'Burrow', 'Bore', 'Auto-Regen', 'Treasure Finder'}
CARD.TEMPERAMENT = {[0] = 'Very easygoing', 'Rather ill-tempered', 'Very patient',
    'Quite sensitive', 'Rather enigmatic'}
CARD.COLOR = {[0] = 'Yellow', 'Black', 'Blue', 'Red', 'Green'}
CARD.GENDER = {[0] = 'Male', 'Female'}
CARD.WEATHER = {
    [0] = {'Clear days', 'None'}, {'Hot, sunny days', 'Rainy days'},
    {'Rainy days', 'Thunderstorms'}, {'Sandstorms', 'Windy days'},
    {'Windy days', 'Snowy days'}, {'Snowy days', 'Hot, sunny days'},
    {'Thunderstorms', 'Sandstorms'}, {'Auroras', 'Dark days'},
    {'Dark days', 'Auroras'}, {'None', 'None'}, {'Cloudy days', 'None'},
}

-- Read `count` bits starting at byte `byte0` (0-based), bit `bit0`, LSB first.
local function read_bits(str, byte0, bit0, count)
    local v = 0
    for i = 0, count - 1 do
        local pos = byte0 * 8 + bit0 + i
        local b = str:byte(math.floor(pos / 8) + 1) or 0
        if math.floor(b / 2 ^ (pos % 8)) % 2 == 1 then
            v = v + 2 ^ i
        end
    end
    return v
end

-- Little-endian 16-bit number at a 0-based byte offset (for packet data).
local function read_u16(str, offset0)
    return (str:byte(offset0 + 1) or 0) + (str:byte(offset0 + 2) or 0) * 256
end

-- Card value 0-255 -> rank letter (32 points per rank: 0-31 F ... 224-255 SS).
local function value_rank(v)
    return RANKS[math.min(#RANKS, math.floor(v / 32) + 1)]
end

-- Decode a card's extdata (layout above) into values, abilities, personality, weather,
-- gender, colour and DNA.
local function decode_card(str)
    local c = {values = {}, abilities = {}}
    for i, stat in ipairs(STAT_NAMES) do
        c.values[stat] = str:byte(i) or 0
    end
    c.dna = {}
    for g = 0, 2 do
        c.dna[#c.dna + 1] = CARD.COLOR[read_bits(str, 4, g * 3, 3)] or '?'
    end
    for a = 0, 1 do
        local name = CARD.ABILITY[read_bits(str, 5, 1 + a * 4, 4)]
        if name and name ~= 'None' then
            c.abilities[#c.abilities + 1] = name
        end
    end
    c.temperament = CARD.TEMPERAMENT[read_bits(str, 6, 1, 3)] or '?'
    local w = CARD.WEATHER[read_bits(str, 6, 4, 4)] or {'?', '?'}
    c.prefers, c.dislikes = w[1], w[2]
    c.gender = CARD.GENDER[read_bits(str, 7, 0, 1)] or '?'
    c.color = CARD.COLOR[read_bits(str, 7, 1, 3)] or '?'
    c.jockey = read_bits(str, 7, 4, 3)
    return c
end

-- Traits that don't change while raising: used to recognise the same card.
local function card_fingerprint(c)
    return table.concat(c.dna, '/') .. ':' .. c.gender .. ':' .. c.color .. ':' .. c.jockey
end

-- Riding speed (%) and time (minutes), with and without race silks.
local function ride_stats(c)
    local speed_mod = math.floor(c.values.strength / 32)
    local time_mod = math.floor(c.values.endurance / 32)
    for _, a in ipairs(c.abilities) do
        if a == 'Gallop' then
            speed_mod = speed_mod + 1
        elseif a == 'Canter' then
            time_mod = time_mod + 1
        end
    end
    -- Riding speed %: 80% plus 2.5% per speed step, up to 8 steps (100%).
    local function speed(gear) return math.min(speed_mod + gear, 8) / 8 * 20 + 80 end
    -- Riding time in minutes: (4 + END steps, max 11, + gear) x 4 + 1.
    local function time(gear) return (math.min(time_mod + 4, 11) + gear) * 4 + 1 end
    return {speed = speed(0), speed_silks = speed(1), time = time(0), time_silks = time(1)}
end

-- Item name from Windower's resources (falls back to 'item <id>').
local function item_name(id)
    local ok, res = pcall(require, 'resources')
    if ok and res and res.items and res.items[id] then
        return res.items[id].en or res.items[id].name or ('item ' .. id)
    end
    return 'item ' .. id
end

-- All chocobo cards in the inventory: { {id, name, card}, ... }
local function inventory_cards()
    local found = {}
    local bag = windower.ffxi.get_items and windower.ffxi.get_items(0)
    if type(bag) ~= 'table' then
        return found
    end
    for _, it in ipairs(bag) do
        if type(it) == 'table' and CARD.ITEMS[it.id] and type(it.extdata) == 'string' and #it.extdata >= 8 then
            found[#found + 1] = {id = it.id, name = item_name(it.id), card = decode_card(it.extdata)}
        end
    end
    return found
end

-- Store a card read on this chocobo. Ranks and abilities are only taken
-- from the card when its contents are new (or it was linked by hand), so a
-- card that isn't updated in-game never overwrites newer check-up stats.
local function apply_card(c, update)
    if update and settings.card then
        for _, a in ipairs(settings.card.abilities or {}) do
            settings.abilities[a] = nil      -- the previous card's abilities
        end
    end
    settings.card = {
        date = today(), values = c.values, abilities = c.abilities,
        temperament = c.temperament, prefers = c.prefers, dislikes = c.dislikes,
        gender = c.gender, color = c.color, dna = c.dna,
    }
    settings.card_fingerprint = card_fingerprint(c)
    if update then
        for _, stat in ipairs(STAT_NAMES) do
            note_stat_change(stat, settings.stats[stat], value_rank(c.values[stat]))
            settings.stats[stat] = value_rank(c.values[stat])
        end
        for _, a in ipairs(c.abilities) do
            settings.abilities[a] = true
        end
    end
end

-- Find this chocobo's card in the inventory and read it. With no card linked
-- yet, a single card is linked automatically. Returns true if one was read.
local function read_card(quiet)
    local cards = inventory_cards()
    local pick
    for _, f in ipairs(cards) do
        if settings.card_fingerprint ~= '' and card_fingerprint(f.card) == settings.card_fingerprint then
            pick = f
        end
    end
    if not pick and settings.card_fingerprint == '' and #cards == 1 then
        pick = cards[1]
    end
    if not pick then
        return false, cards, false
    end
    local before = settings.card and serialize(settings.card.values) .. table.concat(settings.card.abilities, ',')
    local after = serialize(pick.card.values) .. table.concat(pick.card.abilities, ',')
    apply_card(pick.card, before ~= after)
    if not quiet and before ~= after then
        local v = settings.card.values
        say(string.format('card read: STR %d, END %d, DSC %d, RCP %d.',
            v.strength, v.endurance, v.discernment, v.receptivity))
    end
    return true, cards, before ~= after
end

-- Print one card's details in chat (used by //crt card and //crt paddock).
local function print_card(title, c)
    local v = c.values
    windower.add_to_chat(207, title .. ' - ' .. c.gender .. ', ' .. c.color
        .. ' (DNA ' .. table.concat(c.dna, ' ') .. ')')
    for _, stat in ipairs(STAT_NAMES) do
        windower.add_to_chat(207, string.format('  %-12s %3d  %s', STAT_LABELS[stat], v[stat],
            rank_text(value_rank(v[stat]))))
    end
    windower.add_to_chat(207, '  Abilities: ' .. (#c.abilities > 0 and table.concat(c.abilities, ' & ') or 'none'))
    windower.add_to_chat(207, '  Personality: ' .. c.temperament)
    windower.add_to_chat(207, '  Weather: likes ' .. c.prefers .. ', dislikes ' .. c.dislikes)
    local r = ride_stats(c)
    windower.add_to_chat(207, string.format('  Riding: %.1f%% speed, %d min (race silks: %.1f%%, %d min)',
        r.speed, r.time, r.speed_silks, r.time_silks))
end

-- //crt paddock: the chocobo being viewed at the Chocobo Circuit paddocks
-- (packet offsets per Ivaar's chococard).
local function show_paddock()
    local P = windower.packets
    if not P or not P.last_outgoing then
        err('packet access is not available.')
        return
    end
    -- The last menu choice (0x05B) must be in zone 70 (Chocobo Circuit); the menu it
    -- answered (0x033 or 0x034) says which kind of paddock screen it was.
    local o5b = P.last_outgoing(0x05B) or ''
    local i33 = P.last_incoming(0x033) or ''
    local i34 = P.last_incoming(0x034) or ''
    if #o5b < 0x14 or read_u16(o5b, 0x10) ~= 70 then
        err('open a paddock at the Chocobo Circuit first, then try again.')
        return
    end
    local option, menu = read_u16(o5b, 0x08), read_u16(o5b, 0x12)
    local i5c, i5d = P.last_incoming(0x05C) or '', P.last_incoming(0x05D) or ''
    local data, name
    -- Paddock options 6-8: card data in 0x05C, the name in 0x033 or 0x05D.
    -- Crystal stakes (option a multiple of 8): card data and name further along.
    if #i33 >= 0x0E and menu == read_u16(i33, 0x0C) and option > 5 and option < 9 then
        data = i5c:sub(0x04 + 1, 0x0B + 1)
        name = option > 6 and i5d:sub(0x38 + 1, 0x47 + 1) or i33:sub(0x10 + 1, 0x1F + 1)
    elseif #i34 >= 0x2E and menu == read_u16(i34, 0x2C) and option % 8 == 0 then
        data = i5c:sub(0x14 + 1, 0x1B + 1)
        name = i5d:sub(0x28 + 1, 0x37 + 1)
    end
    if not data or #data < 8 then
        err('no paddock chocobo found - view one in the paddock menu first.')
        return
    end
    -- Names are padded with zero bytes.
    name = (name or ''):gsub('%z.*$', '')
    print_card('Paddock: ' .. (name ~= '' and name or 'chocobo'), decode_card(data))
end

------------------------------------------------------------------------
-- Daily history and CSV export
------------------------------------------------------------------------

-- Today's row of the daily history: day, stage, phase, stats (and card values if read
-- today), food, likes, conditions, care counts, feedings, abilities, stories.
-- Called before every save, so the newest values for the day always win.
local function snapshot_today()
    if not settings or current_age == nil then
        return
    end
    settings.history = settings.history or {}
    local d = today()
    local t = care_today()
    local h = {
        day = current_age(), stage = current_stage(), phase = guide_phase(),
        food = settings.food_level ~= '' and settings.food_date == d and settings.food_level or '',
        likes = settings.likes,
        walks = tonumber(t.walk) or 0, watches = tonumber(t.watch) or 0, scolds = tonumber(t.scold) or 0,
        fed_count = fed_count(), fed_items = fed_text(),
        conditions = settings.conditions_date == d and table.concat(settings.conditions, ' & ') or '',
        care_plan = care_plan_state() and care_plan_state().name or '',
        finds = fed_text(t.finds or {}),
        stories = (function()
            local t = {}
            for _, st in ipairs(STORIES) do
                if has_story(st) then t[#t + 1] = st.ability end
            end
            return table.concat(t, ' & ')
        end)(),
        energy_start = t.energy_start or '', energy_end = t.energy_end or '',
        out_of_energy = (energy_out('walk') and 'walk' or '') .. ((energy_out('walk') and energy_out('watch')) and '+' or '')
            .. (energy_out('watch') and 'watch' or ''),
        abilities = table.concat(active_abilities(), ' & '),
    }
    for _, stat in ipairs(STAT_NAMES) do
        h[stat] = settings.stats[stat]
    end
    if settings.card and settings.card.date == d then
        h.values = {}
        for k, v in pairs(settings.card.values) do
            h.values[k] = v
        end
    end
    settings.history[d] = h
end
history_hook = snapshot_today

-- Quote a value for CSV if it contains a comma, quote or line break.
local function csv(v)
    v = tostring(v == nil and '' or v)
    if v:find('[,"\r\n]') then
        v = '"' .. v:gsub('"', '""') .. '"'
    end
    return v
end

-- //crt export: write the daily history to data/<Character>_history.csv, one row per day.
local function export_csv()
    snapshot_today()
    local dates = {}
    for d in pairs(settings.history) do
        dates[#dates + 1] = d
    end
    table.sort(dates)
    if #dates == 0 then
        say('no history yet.')
        return
    end

    local cols = {'date', 'chocobo', 'day', 'stage', 'guide_phase'}
    for _, stat in ipairs(STAT_NAMES) do
        cols[#cols + 1] = stat .. '_rank'
        cols[#cols + 1] = stat .. '_word'
        cols[#cols + 1] = stat .. '_value'
    end
    for _, c in ipairs({'care_plan', 'food', 'likes', 'conditions', 'walks', 'watches', 'scolds', 'out_of_energy', 'energy_start', 'energy_end', 'fed_count', 'fed_items', 'finds', 'abilities', 'stories'}) do
        cols[#cols + 1] = c
    end

    local lines = {table.concat(cols, ',')}
    for _, d in ipairs(dates) do
        local h = settings.history[d]
        local row = {d, settings.chocobo_name, h.day, h.stage, h.phase}
        for _, stat in ipairs(STAT_NAMES) do
            row[#row + 1] = h[stat] or ''
            row[#row + 1] = RANK_WORD[h[stat]] or ''
            row[#row + 1] = h.values and h.values[stat] or ''
        end
        for _, c in ipairs({'care_plan', 'food', 'likes', 'conditions', 'walks', 'watches', 'scolds', 'out_of_energy', 'energy_start', 'energy_end', 'fed_count', 'fed_items', 'finds', 'abilities', 'stories'}) do
            row[#row + 1] = h[c]
        end
        for i, v in ipairs(row) do
            row[i] = csv(v)
        end
        lines[#lines + 1] = table.concat(row, ',')
    end

    local dir = windower.addon_path .. 'data/'
    if not windower.dir_exists(dir) then
        windower.create_dir(dir)
    end
    local name = char_name .. '_history.csv'
    local f, e = io.open(dir .. name, 'w')
    if not f then
        err('could not write ' .. name .. ' (' .. tostring(e) .. ').')
        return
    end
    f:write(table.concat(lines, '\n') .. '\n')
    f:close()
    say('exported ' .. #dates .. (#dates == 1 and ' day' or ' days') .. ' to addons/CarrotTime/data/' .. name)
end

-- The '>' line at the bottom of the panel: the single most useful thing to do next.
-- Order: egg watch -> a cure -> lost chick owner -> walks -> watches -> handkerchief
-- event -> carrots (unless full) -> the guide's care plan.
local function next_advice()
    local stage = current_stage()
    if stage == 'Egg' then
        if watched_today() then
            return 'Watched today - back tomorrow'
        end
        return 'Watch the egg today'
    end
    if stage == 'Retired' then
        return 'Retired - raising is finished'
    end
    local lc = settings.lost_chick
    if lc.active and not lc.done then
        local cands = chick_candidates()
        if #cands == 1 and (lc.initial ~= '' or lc.job ~= '' or lc.race ~= '') then
            return 'Lost chick: ask ' .. cands[1][1] .. (cands[1][6] and (' (' .. cands[1][6] .. ')') or '')
        end
    end
    local bad = bad_conditions()
    if #bad > 0 and settings.conditions_date == today() then
        return 'Cure ' .. bad[1].name .. ': ' .. (bad[1].short or bad[1].cure)
    end
    local age = current_age()
    if stage == 'Chick' then
        -- Daily care: walk until it can't, then watch over it until it can't.
        local e = energy_now()
        if not walks_blocked() then
            if e and walk_status(e) == 'yes' then
                return 'Walk it: ' .. walks_left(e) .. ' walk' .. (walks_left(e) == 1 and '' or 's')
                    .. ' left (energy ' .. e .. ')'
            end
            return 'Walk until out of energy (' .. care_count('walk') .. ' so far)'
        end
        if not watches_blocked() then
            if e then
                return 'Now watch over it: ~' .. watches_left(e) .. ' watches left'
            end
            return 'Now watch over it until out of energy (' .. care_count('watch') .. ')'
        end
        if age == 7 then
            return 'Day 7: White Handkerchief event tonight'
        end
    elseif care_count('walk') == 0 then
        return 'Take your chocobo for a walk today'
    end
    -- Care plans raise stats every day without food, so from the chick stage on
    -- a plan that doesn't match the guide comes before the carrots.
    local step = guide_step()
    local cp = care_plan_state()
    if stage ~= 'Egg' and cp and (cp.ended or cp.name ~= step.plan) and step.plan ~= 'Retired' then
        if cp.ended then
            return 'Care plan ended: set ' .. step.plan
        elseif cp.name == 'Basic Care' then
            return 'Basic Care gives no stats: set ' .. step.plan
        end
        return 'Change care plan to ' .. step.plan
    end
    if guide_phase() == 1 then
        local left = 3 - fed_count('Vomp Carrot')
        if left > 0 and full_today() then
            return 'Completely full - skip the carrots today'
        elseif left > 0 then
            return 'Feed ' .. left .. ' more Vomp Carrot' .. (left == 1 and '' or 's') .. ' today'
        end
        return 'Plan: ' .. step.plan
    end
    return 'Plan: ' .. step.plan
end

-- Is today's care finished? (Egg: watched. Chick: walks and watches both
-- out of energy. Older: at least one walk.)
local function care_done_today()
    local stage = current_stage()
    if stage == 'Egg' then
        return watched_today()
    elseif stage == 'Chick' then
        return walks_blocked() and watches_blocked()
    elseif stage == 'Retired' then
        return true
    end
    return care_count('walk') > 0
end

-- Time left until the game's daily reset, as '5h 12m'.
local function reset_text()
    local sec = seconds_to_reset()
    return string.format('%dh %02dm', math.floor(sec / 3600), math.floor(sec % 3600 / 60))
end

-- Race record: wins and other placings.
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

-- Fixed panel size, so it never grows or shrinks with the text.
local STAT_TEXT_WIDTH = 23      -- #"Better than average | B", the longest stat text
local PANEL_WIDTH = 5 + STAT_TEXT_WIDTH + 2 + 8 + 7   -- STR, text, bar, "-> SS" = 45

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

-- Wrap text in a colour code (Windower texts: \cs(r,g,b) ... \cr).
local function col(c, s)
    s = tostring(s)
    if s == '' then
        return ''
    end
    return string.format('\\cs(%d,%d,%d)%s\\cr', c[1], c[2], c[3], s)
end

-- Pad text with spaces to a width (used for lining up columns).
local function pad(s, n)
    s = tostring(s)
    if #s >= n then
        return s
    end
    return s .. string.rep(' ', n - #s)
end

-- Separator between items on one panel line.
local SEP = ' | '

-- A full-width line of dashes (also keeps the panel at its fixed width).
local function rule()
    return col(C.dim, string.rep('-', PANEL_WIDTH))
end

-- A section title in capitals, with optional text right-aligned on the same line.
local function section(name, right)
    local left = col(C.label, name:upper())
    if right and right ~= '' then
        local plain_right = right:gsub('\\cs%(%d+,%d+,%d+%)', ''):gsub('\\cr', '')
        local space = math.max(1, PANEL_WIDTH - #name - #plain_right)
        return left .. string.rep(' ', space) .. right
    end
    return left
end

-- Stage -> {day the next stage starts, its name}, for the 'Adolescent in 13d' countdown.
local NEXT_STAGE = {
    Egg = {4, 'Chick'},
    Chick = {19, 'Adolescent'},
    Adolescent = {29, 'Adult'},
    Adult = {129, 'Retired'},
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


-- One stat row: 'STR  Poor | F ^  #---....  -> S' (rank, change marker, bar, target).
local function stat_row(short, stat, width)
    local cur = settings.stats[stat] or 'F'
    local tgt = settings.racing_targets[stat] or 'F'
    local met = rank_value(cur) >= rank_value(tgt)
    local status = met and col(C.good, 'ok')
        or (col(C.label, '-> ') .. col(C.warn, tgt))
    local base = rank_text(cur)
    local mark = stat_marker(stat)
    local shown_txt = col(met and C.good or C.text, base)
    local used = #base
    if mark and #base + 2 <= width then
        shown_txt = shown_txt .. col(mark == '^' and C.good or C.warn, ' ' .. mark)
        used = used + 2
    end
    return col(C.label, short) .. '  ' .. shown_txt .. string.rep(' ', width + 2 - used)
        .. rank_bar(cur, tgt) .. '  ' .. status
end

-- Shorten a line to `width` visible characters, ignoring colour codes.
local function clip(line, width)
    local out, shown, i, open = {}, 0, 1, false
    while i <= #line do
        local code = line:match('^\\cs%(%d+,%d+,%d+%)', i)
        if code then
            out[#out + 1] = code
            open = true
            i = i + #code
        elseif line:sub(i, i + 2) == '\\cr' then
            out[#out + 1] = '\\cr'
            open = false
            i = i + 3
        else
            if shown == width - 1 and #line:sub(i):gsub('\\cs%(%d+,%d+,%d+%)', ''):gsub('\\cr', '') > 1 then
                out[#out + 1] = '~'
                break
            end
            out[#out + 1] = line:sub(i, i)
            shown = shown + 1
            i = i + 1
        end
    end
    if open then
        out[#out + 1] = '\\cr'
    end
    return table.concat(out)
end

-- Build the whole panel text from the current data, section by section, top to bottom.
-- Every line is clipped to PANEL_WIDTH at the end, so nothing can widen the panel.
local function build_panel()
    local lines = {}
    -- Add one line to the panel.
    local function add(l) lines[#lines + 1] = l end

    -- "Label  text...", wrapping the text by words under the label.
    local function add_wrapped(label, text, colour, label_w)
        local room = PANEL_WIDTH - label_w
        local row, first = '', true
        -- Write out the current wrapped row under the label (the label only on the first row).
        local function flush()
            add(col(C.label, pad(first and label or '', label_w)) .. col(colour, row))
            row, first = '', false
        end
        for word in tostring(text):gmatch('%S+') do
            if row ~= '' and #row + 1 + #word > room then
                flush()
            end
            row = row == '' and word or (row .. ' ' .. word)
        end
        flush()
    end

    local stat_w = STAT_TEXT_WIDTH

    local stage = current_stage()
    local age = current_age()
    local compact = settings.ui.compact

    -- Header: name, path / focus
    local ver = 'v' .. _addon.version
    local gap = math.max(2, PANEL_WIDTH - #settings.chocobo_name - #ver)
    add(col(C.title, settings.chocobo_name) .. string.rep(' ', gap) .. col(C.dim, ver))
    add(col(C.text, settings.nation ~= '' and (settings.nation .. ' stables') or 'Chocobo raising')
        .. col(C.dim, SEP) .. col(C.label, 'digger plan'))
    add(rule())

    -- Age and stage
    -- Stage line: 'Chick | day 6 | Adolescent in 13d'.
    local nxt = NEXT_STAGE[stage]
    local stage_line = col(C.accent, stage) .. col(C.dim, SEP) .. col(C.text, 'day ' .. age)
    if nxt then
        local left = nxt[1] - age
        stage_line = stage_line .. col(C.dim, SEP)
            .. col(C.label, nxt[2] .. ' in ' .. left .. 'd')
    end
    add(stage_line)

    -- Energy: 'Energy 27  ##........  walks 0  watches 8' ('~' = estimated)
    local e, est = energy_now()
    if e then
        local filled = math.floor(e / 10 + 0.5)
        local ws = walk_status(e)
        local bar_col = (ws == 'yes' and C.good) or (ws == 'maybe' and C.text) or C.warn
        add(col(C.label, 'Energy ') .. col(est and C.dim or C.text, pad((est and '~' or '') .. e, 4))
            .. col(bar_col, string.rep('#', filled)) .. col(C.dim, string.rep('.', 10 - filled))
            .. col(C.label, '  walks ') .. col(C.text, ws == 'maybe' and '?' or walks_left(e))
            .. col(C.label, '  watches ') .. col(C.text, watches_left(e)))
    end

    -- Food line: level from the check-up (green full, orange hungry, grey if not checked
    -- today) and feedings today; wraps onto two lines if it's too long.
    local fed = fed_count()
    if stage ~= 'Egg' and (settings.food_level ~= '' or settings.likes ~= '' or fed > 0) then
        local fed_txt = 'fed ' .. fed .. ' today'
        local fed_col = fed > 0 and C.good or C.dim
        if settings.food_level ~= '' then
            local fresh = settings.food_date == today()
            local f = settings.food_level:lower()
            local fc = not fresh and C.dim
                or ((f:find('full', 1, true) or f:find('satisf', 1, true)) and C.good)
                or ((f:find('hungry', 1, true) or f:find('starv', 1, true) or f:find('empty', 1, true)) and C.warn)
                or C.text
            if 7 + #settings.food_level + #SEP + #fed_txt <= PANEL_WIDTH then
                add(col(C.label, pad('Food', 7)) .. col(fc, settings.food_level)
                    .. col(C.dim, SEP) .. col(fed_col, fed_txt))
            else
                add_wrapped('Food', settings.food_level, fc, 7)
                add(string.rep(' ', 7) .. col(fed_col, fed_txt))
            end
            if not fresh then
                add(string.rep(' ', 7) .. col(C.dim, '(not checked today)'))
            end
        else
            add(col(C.label, pad('Food', 7)) .. col(fed_col, fed_txt))
        end
        if settings.likes ~= '' then
            add_wrapped('Likes', settings.likes, C.text, 7)
        end
    end
    if stage ~= 'Egg' and settings.conditions_date ~= '' then
        local fresh = settings.conditions_date == today()
        if #settings.conditions == 0 then
            add(col(C.label, pad('Status', 7)) .. col(C.dim, 'nothing unusual'
                .. (fresh and '' or ' (old check-up)')))
        else
            for i, name in ipairs(settings.conditions) do
                local c = CONDITION_BY_NAME[name] or {}
                add_wrapped(i == 1 and 'Status' or '', name, not fresh and C.dim or (c.good and C.good or C.warn), 7)
                if c.cure and not c.good and fresh then
                    add_wrapped('', 'Cure: ' .. c.cure, C.text, 7)
                end
            end
        end
    end

    if stage == 'Egg' then
        local watched = watched_today()
        add(col(C.label, 'Watches ') .. col(C.text, settings.egg_watches or 0)
            .. col(C.dim, SEP)
            .. (watched and col(C.good, 'watched today') or col(C.warn, 'not watched today')))
    end

    -- Stats (not shown for an egg; there's nothing to raise yet)
    if stage ~= 'Egg' then
        add('')
        add(section('Stats', col(C.label, 'now') .. col(C.dim, ' / ') .. col(C.label, 'target')))
        add(stat_row('STR', 'strength', stat_w))
        add(stat_row('END', 'endurance', stat_w))
        add(stat_row('DSC', 'discernment', stat_w))
        add(stat_row('RCP', 'receptivity', stat_w))

        if not compact then
            -- Today's care: walks. Watches and scolds are shown only when
            -- they happened, and don't count as care.
            local function n(action, label)
                local c = care_count(action)
                local limit = care_limit(action)
                if limit then
                    local colour = (c >= limit and C.good) or (c > 0 and C.text) or C.dim
                    return col(colour, label .. ' ' .. c .. '/' .. limit)
                end
                return col(c > 0 and C.good or C.dim, label .. ' ' .. c)
            end
            local walks = care_count('walk')
            if stage == 'Chick' then
                -- Chick: walks until out of energy, then watches until out of energy.
                local function row(action, label)
                    local c = care_count(action)
                    local out = (action == 'walk') and walks_blocked() or watches_blocked()
                    return col(out and C.good or (c > 0 and C.text or C.dim), pad(label .. ' ' .. c, 10))
                        .. (out and col(C.dim, 'out of energy') or col(C.dim, 'keep going'))
                end
                local walk_out, watch_out = walks_blocked(), watches_blocked()
                local status = (walk_out and watch_out) and col(C.good, 'done')
                    or (walk_out and col(C.text, 'now watches')) or col(C.text, 'walks first')
                add('')
                add(section("Today's care", status))
                add(row('walk', 'Walk'))
                add(row('watch', 'Watch'))
                if care_count('scold') > 0 then
                    add(col(C.text, 'Scold ' .. care_count('scold')))
                end
            else
            local done = walks > 0
            add('')
            add(section("Today's care", col(done and C.good or C.text, done and 'done' or 'not done')))
            local seen = {}
            if care_count('watch') > 0 then
                seen[#seen + 1] = col(C.text, 'Watch ' .. care_count('watch'))
            end
            if care_count('scold') > 0 then
                seen[#seen + 1] = col(C.text, 'Scold ' .. care_count('scold'))
            end
            if #seen > 0 then
                add(table.concat(seen, '    '))
            end
            add(n('walk', 'Walk'))
            end
        end

        if not compact and settings.ui.guide then
            -- Raising guide: today's plan and what comes next
            local step = guide_step()
            local p = guide_phase()
            add('')
            add(section('Plan', col(C.dim, 'phase ' .. p .. '/4: ') .. col(C.text, GUIDE_PHASES[p].name)))
            add(col(C.label, 'Now   ') .. col(C.accent, step.plan))
            add(col(C.label, '      ') .. col(C.dim, step.why))
            if step.until_ then
                add(col(C.label, 'Until ') .. col(C.text, step.until_))
            end
            local cp = care_plan_state()
            if cp then
                local match = cp.name == step.plan
                local when = cp.ended and ' (ended)' or (cp.days > 0 and (', day ' .. cp.day .. '/' .. cp.days)
                    or (', day ' .. cp.day))
                local note = (cp.name == 'Basic Care' and not match) and ' - no stats' or ''
                add_wrapped('Set', cp.name .. when .. note, (match and not cp.ended) and C.good or C.warn, 6)
            else
                add(col(C.label, 'Set   ') .. col(C.dim, 'read at the next check-up'))
            end
            if step.daily then
                add_wrapped('Daily', step.daily, C.text, 6)
            end
            if step.daily2 then
                add_wrapped('', step.daily2, C.text, 6)
            end
            if step.next then
                add(col(C.label, 'Next  ') .. col(C.dim, step.next))
            end
        end

        if not compact then
            -- Abilities and races
            add('')
            local abil = active_abilities()
            if #abil == 0 then
                add(col(C.label, pad('Abilities', 10)) .. col(C.dim, 'none yet'))
            else
                -- wrap the list so it never runs past the panel width
                local row, first = '', true
                for i, a in ipairs(abil) do
                    local piece = a .. (i < #abil and ',' or '')
                    if row ~= '' and 10 + #row + 1 + #piece > PANEL_WIDTH then
                        add(col(C.label, pad(first and 'Abilities' or '', 10)) .. col(C.text, row))
                        row, first = '', false
                    end
                    row = row == '' and piece or (row .. ' ' .. piece)
                end
                add(col(C.label, pad(first and 'Abilities' or '', 10)) .. col(C.text, row))
            end
            local owned = {}
            for _, st in ipairs(STORIES) do
                if has_story(st) then
                    owned[#owned + 1] = st.ability .. (SKIP_ABILITY[st.ability] and ' (skip)' or '')
                end
            end
            if #owned > 0 then
                add_wrapped('Stories', table.concat(owned, ', '), C.text, 10)
            end
            local fr = {}
            for name, n in pairs(settings.friends) do
                if tonumber(n) and n < 3 then
                    fr[#fr + 1] = name .. ' ' .. n .. '/3'
                end
            end
            table.sort(fr)
            if #fr > 0 then
                add_wrapped('Friends', table.concat(fr, ', '), C.text, 10)
            end

            -- Lost chick quest in progress: clues and who it could be
            local lc = settings.lost_chick
            if lc.active and not lc.done then
                add('')
                add(section('Lost chick', col(C.dim, chick_nation())))
                add_wrapped('Clues', chick_clue_text(), C.text, 7)
                local names = {}
                for _, o in ipairs(chick_candidates()) do
                    names[#names + 1] = o[1] .. (o[6] and (' ' .. o[6]) or '')
                end
                add_wrapped('Owner', #names > 0 and table.concat(names, ', ') or 'no match - check clues',
                    #names == 1 and C.good or C.text, 7)
            end

            -- Racing: exact values from the chocobo's card, riding, race record
            local card = settings.card
            if card or #settings.race_history > 0 then
                add('')
                add(section('Racing', card and col(C.dim, 'card read ' .. card.date:sub(6))
                    or col(C.dim, 'no card read')))
                if card then
                    local v = card.values
                    add(col(C.label, 'STR ') .. col(C.text, pad(v.strength, 5))
                        .. col(C.label, 'END ') .. col(C.text, pad(v.endurance, 5))
                        .. col(C.label, 'DSC ') .. col(C.text, pad(v.discernment, 5))
                        .. col(C.label, 'RCP ') .. col(C.text, v.receptivity))
                    local r = ride_stats(card)
                    add(col(C.label, pad('Ride', 7)) .. col(C.text,
                        string.format('%.1f%% speed, %d min', r.speed, r.time)))
                    add(col(C.label, pad('', 7)) .. col(C.dim,
                        string.format('silks: %.1f%%, %d min', r.speed_silks, r.time_silks)))
                    add_wrapped('Nature', card.temperament, C.text, 7)
                end
                local wins, losses = race_totals()
                if #settings.race_history == 0 then
                    add(col(C.label, pad('Races', 7)) .. col(C.dim, 'none yet'))
                else
                    add(col(C.label, pad('Races', 7)) .. col(C.good, wins .. (wins == 1 and ' win' or ' wins'))
                        .. '  ' .. col(C.text, losses .. ' other'))
                end
            end
        end
    end

    -- Next step
    add(rule())
    add(col(C.title, '> ') .. col(C.text, next_advice()))

    for i, l in ipairs(lines) do
        lines[i] = clip(l, PANEL_WIDTH)
    end
    return table.concat(lines, '\n')
end

-- Redraw the panel and decide whether it's shown: in npc mode only while talking to a
-- raising NPC (or peeked open); in always mode when visible is on. Also moves the guide
-- to its next phase when the current goal is met.
local function update_ui()
    if not ui then
        return
    end

    if not settings or not char_name then
        ui:hide()
        return
    end

    if settings.ui.guide and guide_advance() then
        save()
        say('raising guide: phase ' .. guide_phase() .. '/4 - ' .. GUIDE_PHASES[guide_phase()].name
            .. '. Targets updated.')
    end

    ui:text(build_panel())
    ui:pos(settings.ui.x, settings.ui.y)

    local shown
    if settings.ui.mode == 'always' then
        shown = settings.ui.visible
    else
        shown = talking or peek or os.clock() < peek_until
    end

    if shown then
        ui:show()
    else
        ui:hide()
    end
end

-- Create the panel's text object (Windower texts library): dark background, Consolas.
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

-- //crt name <name>
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

-- //crt stat / //crt target: record a current rank, or set a target rank.
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
        note_stat_change(s, settings.stats[s], r)
        settings.stats[s] = r
        say(STAT_LABELS[s] .. ' recorded as ' .. rank_text(r) .. '.')
    end
    save()
    update_ui()
end

-- //crt hatch <YYYY-MM-DD>: the age is worked out from the hatch date from then on.
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

-- //crt age <days>: set the age by hand (clears the hatch date).
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

-- Add (n = 1) or take back (n = -1) one care action for today.
local function record_care(action, n)
    if debug_log_hook then
        debug_log_hook('counted ' .. action .. ' ' .. (n > 0 and '+' or '') .. n)
    end
    local d = today()
    settings.care_log[d] = settings.care_log[d] or {}
    local t = settings.care_log[d]
    local before = tonumber(t[action]) or 0
    if n > 0 and care_limit(action) and before >= care_limit(action) then
        return nil      -- already at the daily limit
    end
    t[action] = math.max(0, before + n)

    if action == 'watch' then
        if current_stage() == 'Egg' and t.watch ~= before then
            settings.egg_watches = math.max(0, (tonumber(settings.egg_watches) or 0) + n)
        end
        settings.last_watch_date = t.watch > 0 and d or ''
    end

    -- keep 30 days of history
    local cutoff = os.date('%Y-%m-%d', os.time() - 30 * 86400)
    for day in pairs(settings.care_log) do
        if day < cutoff then
            settings.care_log[day] = nil
        end
    end

    save()
    update_ui()
    return t[action]
end

-- The chat line after logging care: 'walk logged - 2 today.' (egg: total watches).
local function care_message(action)
    if action == 'watch' and current_stage() == 'Egg' then
        local w = tonumber(settings.egg_watches) or 0
        return 'egg watched - ' .. w .. (w == 1 and ' watch' or ' watches') .. ' so far.'
    end
    local c = care_count(action)
    local limit = care_limit(action)
    return CARE_LABEL[action] .. ' logged - ' .. c .. (limit and ('/' .. limit) or '') .. ' today.'
end

-- //crt watch (add one) / //crt watches <n> (set the egg's total).
local function set_watches(count)
    -- No number (or "+"): log one watch for today (egg or chick).
    if count == nil or count == '' or count == '+' then
        local stage = current_stage()
        if stage ~= 'Egg' and stage ~= 'Chick' then
            err('watching is tracked for the Egg and Chick stages. Current stage: ' .. stage .. '.')
            return
        end
        record_care('watch', 1)
        say(care_message('watch'))
        return
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

-- //crt ability <name> [off]: record or remove a learned ability.
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

-- //crt care: today's care so far and the time to the reset.
local function show_care()
    if current_stage() == 'Chick' or current_stage() == 'Egg' then
        local parts = {}
        for _, a in ipairs(CARE_ACTIONS) do
            parts[#parts + 1] = CARE_LABEL[a] .. ' ' .. care_count(a)
        end
        say('today (' .. today() .. ', reset in ' .. reset_text() .. '): ' .. table.concat(parts, ', '))
        return
    end
    say('today (' .. today() .. ', reset in ' .. reset_text() .. '): walks ' .. care_count('walk')
        .. ', watches ' .. care_count('watch') .. ', scolds ' .. care_count('scold') .. ', fed ' .. fed_count())
end

-- Care actions that can be logged by hand: watch, scold, walk.
local function care_action(task)
    if task == 'watch' or task == 'scold' or task == 'walk' then
        return task
    end
    return nil
end

-- //crt care / undo / walk / scold: log or take back care. `sub` can be a count
-- (//crt undo walk 3).
local function log_care(task, undo, sub)
    task = lower(task)
    if task == '' then
        show_care()
        return
    end

    local action = care_action(task)
    local times = tonumber(sub)
    if action and times and times > 1 and times == math.floor(times) then
        for _ = 1, times - 1 do
            record_care(action, undo and -1 or 1)
        end
    end
    if action then
        if record_care(action, undo and -1 or 1) == nil then
            say('already at ' .. care_limit(action) .. ' ' .. CARE_LABEL[action]
                .. 's today (the daily limit) - not counted.')
            return
        end
        if undo then
            say(CARE_LABEL[action] .. ' taken back - ' .. care_count(action) .. ' today.')
        else
            say(care_message(action))
        end
        return
    end

    err('care task must be watch, scold or walk (food: //crt feed).')
end

-- //crt note <text>: a dated note.
local function add_note(text)
    if text == '' then
        err('usage: //crt note <text>')
        return
    end
    settings.notes[#settings.notes + 1] = today() .. ' ' .. text
    save()
    say('note added (' .. #settings.notes .. ' total).')
end

-- //crt notes [clear]: list or clear the notes.
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

-- Record a race result (place 1 = win, 0 = loss).
local function add_race(place)
    settings.race_history[#settings.race_history + 1] = {date = today(), place = place}
    save()
    update_ui()
    local wins, losses = race_totals()
    say('race recorded (' .. (place == 1 and 'win' or ('place ' .. place)) .. '). Total: '
        .. wins .. ' won / ' .. losses .. ' other.')
end

-- //crt race win | loss | place <n> | history | clear
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

-- //crt status: a summary of the chocobo in chat.
local function status()
    say(settings.chocobo_name .. ' - ' .. (settings.nation ~= '' and settings.nation or 'raising') .. ', age '
        .. current_age() .. ' days (' .. current_stage() .. ')')
    for _, s in ipairs(STAT_NAMES) do
        windower.add_to_chat(207, string.format('  %-12s %-25s (target %s)',
            STAT_LABELS[s], rank_text(settings.stats[s]),
            rank_text(settings.racing_targets[s])))
    end
    if settings.food_level ~= '' then
        windower.add_to_chat(207, '  Food: ' .. settings.food_level
            .. (settings.food_date == today() and '' or ' (as of ' .. settings.food_date .. ')'))
    end
    if settings.likes ~= '' then
        windower.add_to_chat(207, '  Likes: ' .. settings.likes)
    end
    windower.add_to_chat(207, '  Abilities: ' .. format_list(active_abilities()))
    windower.add_to_chat(207, '  Next: ' .. next_advice())
end

------------------------------------------------------------------------
-- Chat-detection state
------------------------------------------------------------------------

local last_watch_time = 0        -- os.time() of the last auto-counted watch
local last_watch_line = ''       -- the egg line that was counted (to skip its copy)
local last_feed_line, last_feed_time = '', 0      -- last feeding line counted (to skip its copies)
local checkup_start = 0          -- os.time() the last check-up began
local walk_find_time = 0         -- os.time() the trainer said the chocobo found something
local last_find_line, last_find_time = '', 0      -- last walk find counted (to skip its copies)
local coincidence_time = 0       -- "Well, what a coincidence." (a walk meeting)
local last_friend, last_friend_line, last_friend_time = nil, '', 0  -- last walk friend meeting counted
local DUPLICATE_SECONDS = 5      -- same line again this soon = the game's copy
local watch_prompt_time = 0      -- os.time() Zopago & co. last confirmed a watch
local WATCH_WINDOW = 120         -- seconds after that line in which an egg line counts

------------------------------------------------------------------------
-- NPC conversations: open the panel while talking to a raising NPC
------------------------------------------------------------------------

-- Is this NPC one of the raising NPCs (Hantileon, Zopago, Pulonono, or ones added with
-- //crt npc add)?
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

-- Start / end 'talking to a raising NPC' (this is what opens and closes the panel).
local function set_talking(state)
    if talking ~= state then
        talking = state
        talking_since = os.time()
        update_ui()
    end
end

------------------------------------------------------------------------
-- Debug log (//crt debug)
------------------------------------------------------------------------

-- Debug log: one file per session in data/debug/, nothing in chat.
local function dbg(msg)
    if not debug or not debug_path then
        return
    end
    local f = io.open(debug_path, 'a')
    if f then
        f:write('[' .. os.date('%H:%M:%S') .. '] ' .. tostring(msg) .. '\n')
        f:close()
    end
end

-- Show hidden bytes (line breaks, colour codes) as <07> etc.
local function show_bytes(s)
    return (tostring(s or ''):gsub('[%z\1-\31\127]', function(c)
        return string.format('<%02X>', c:byte())
    end))
end

-- Debug-only packet helpers and logging, in a block so they don't count toward
-- Lua 5.1's 200 top-level locals.
do
-- Bytes as hex ('5B 0A 9D ...'), cut off after `max` bytes, for the debug log.
local function hex(data, max)
    data = tostring(data or '')
    local n = math.min(#data, max or 64)
    local out = {}
    for i = 1, n do
        out[i] = string.format('%02X', data:byte(i))
    end
    return table.concat(out, ' ') .. (#data > n and ' ...' or '')
end


-- Selected fields of a parsed packet as 'Name=value, ...' for the debug log.
local function packet_fields(dir, data, keys)
    local ok, p = pcall(packets.parse, dir, data)
    if not ok or type(p) ~= 'table' then
        return ''
    end
    local parts = {}
    for _, k in ipairs(keys) do
        if p[k] ~= nil then
            local v = p[k]
            if type(v) == 'string' then
                v = hex(v, 32)
            end
            parts[#parts + 1] = k .. '=' .. tostring(v)
        end
    end
    return table.concat(parts, ', ')
end

-- NPC name from a mob index ('?' if unknown).
local function mob_name_by_index(i)
    local m = i and windower.ffxi.get_mob_by_index(i)
    return m and m.name or '?'
end

-- Packets the debug log records, with a readable name (incoming / outgoing).
local DEBUG_IN = {
    [0x032] = 'event start', [0x034] = 'event start (params)', [0x052] = 'release',
    [0x05C] = 'event data', [0x05D] = 'event data 2', [0x00A] = 'zone in', [0x00B] = 'zone out',
    [0x02A] = 'message (id)', [0x036] = 'NPC message (id)', [0x027] = 'message', [0x053] = 'system message',
}
local DEBUG_OUT = {
    [0x05B] = 'menu choice', [0x036] = 'trade', [0x01A] = 'action (talk)', [0x05C] = 'event update',
}

-- Debug: log the incoming packets that matter for raising (event starts, releases,
-- messages, zoning) with their raw bytes.
windower.register_event('incoming chunk', function(id, data)
    if not debug or not DEBUG_IN[id] then
        return
    end
    local extra = ''
    if id == 0x032 or id == 0x034 then
        local ok, p = pcall(packets.parse, 'incoming', data)
        local npc = ok and p and mob_name_by_index(p['NPC Index']) or '?'
        extra = 'NPC ' .. npc .. ', ' .. packet_fields('incoming', data, {'Menu ID', 'Zone', 'Menu Parameters'})
    elseif id == 0x02A or id == 0x036 then
        extra = packet_fields('incoming', data, {'Message ID', 'Param 1', 'Param 2', 'Param 3', 'Param 4'})
    elseif id == 0x052 then
        extra = packet_fields('incoming', data, {'Type'})
    end
    dbg(string.format('IN  0x%03X %s %s | %s', id, DEBUG_IN[id], extra, hex(data)))
end)

-- Debug: log the outgoing packets that matter (menu choices, trades, talking to an NPC).
windower.register_event('outgoing chunk', function(id, data)
    if not debug or not DEBUG_OUT[id] then
        return
    end
    local extra = ''
    if id == 0x05B then
        local ok, p = pcall(packets.parse, 'outgoing', data)
        extra = 'NPC ' .. (ok and p and mob_name_by_index(p['Target Index']) or '?') .. ', '
            .. packet_fields('outgoing', data, {'Option Index', 'Menu ID', 'Automated Message', 'Zone'})
    elseif id == 0x01A then
        local ok, p = pcall(packets.parse, 'outgoing', data)
        extra = 'target ' .. (ok and p and mob_name_by_index(p['Target Index']) or '?') .. ', '
            .. packet_fields('outgoing', data, {'Category', 'Param'})
    elseif id == 0x036 then
        local ok, p = pcall(packets.parse, 'outgoing', data)
        extra = 'to ' .. (ok and p and mob_name_by_index(p['Target Index']) or '?')
    end
    dbg(string.format('OUT 0x%03X %s %s | %s', id, DEBUG_OUT[id], extra, hex(data)))
end)

debug_log_hook = function(msg) dbg(msg) end
end

-- //crt debug on: start a new log file in data/debug/ with a header describing the chocobo.
local function start_debug()
    local dir = windower.addon_path .. 'data/debug/'
    if not windower.dir_exists(windower.addon_path .. 'data/') then
        windower.create_dir(windower.addon_path .. 'data/')
    end
    if not windower.dir_exists(dir) then
        windower.create_dir(dir)
    end
    debug_path = dir .. os.date('%Y-%m-%d_%H%M%S') .. '.txt'
    debug = true
    dbg('==== CarrotTime v' .. _addon.version .. ' debug, ' .. os.date('%Y-%m-%d') .. ' ====')
    dbg('character ' .. tostring(char_name) .. ', chocobo ' .. settings.chocobo_name
        .. ', day ' .. current_age() .. ' (' .. current_stage() .. '), guide phase ' .. guide_phase())
    dbg('raising NPCs: ' .. table.concat(settings.raising_npcs, ', '))
end

------------------------------------------------------------------------
-- Feeding, walk and watch detection (trades, menu choices, conversation status)
------------------------------------------------------------------------

-- Add (n > 0) or take back (n < 0) feedings for today.
local function record_food(name, n)
    dbg('counted food ' .. name .. ' ' .. (n > 0 and '+' or '') .. n)
    local d = today()
    settings.care_log[d] = settings.care_log[d] or {}
    local day = settings.care_log[d]
    day.fed = day.fed or {}
    local v = math.max(0, (tonumber(day.fed[name]) or 0) + n)
    day.fed[name] = v > 0 and v or nil
    save()
    update_ui()
end

-- Trading items to a raising NPC (outgoing 0x036): count the foods.
windower.register_event('outgoing chunk', function(id, data)
    if id ~= 0x036 or not settings then
        return
    end
    local ok, p = pcall(packets.parse, 'outgoing', data)
    if not ok or not p then
        return
    end
    local npc = p['Target Index'] and windower.ffxi.get_mob_by_index(p['Target Index'])
    if not npc or not is_raising_npc(npc.name) then
        return
    end
    local given = {}
    for i = 1, 9 do
        local idx, cnt = p['Item Index ' .. i], p['Item Count ' .. i]
        if idx and idx > 0 and cnt and cnt > 0 then
            local item = windower.ffxi.get_items(0, idx)
            local name = item and item.id and item.id > 0 and item_name(item.id) or ''
            local food = FOOD_BY_LOWER[name:lower()]
            -- Not counted here: the game can send this packet twice per item.
            -- Feedings are counted from the "gives the chocobo" line instead.
            dbg('trade to ' .. npc.name .. ': ' .. cnt .. 'x ' .. name .. (food and ' (food)' or ''))
        end
    end
end)

-- Walks: the menu choice that starts a walk (seen in the debug log as option
-- 10994 at Zopago). It's counted a few seconds later unless the NPC says the
-- chocobo "needs more energy".
local WALK_OPTIONS = {[10994] = true}
local walk_prompt_time = 0      -- os.time() the trainer last described a walk
local walk_candidate = nil      -- {option, time}: an unknown choice made after that
-- Menu choice that confirms a watch (option 12530 at Zopago).
local WATCH_OPTIONS = {[12530] = true}
local pending_walk = nil        -- os.clock() of a walk waiting to be confirmed
local last_care_try = nil       -- 'walk' or 'watch': what the NPC is answering

-- Menu choices made while talking to a raising NPC: a known walk choice starts a
-- 'pending' walk (counted 3 seconds later unless the NPC refuses for energy); a known
-- watch choice marks that the NPC's next answer is about a watch. Unknown action choices
-- (256+) made just after the walk description are remembered so a refusal can teach
-- the addon this trainer's walk choice.
windower.register_event('outgoing chunk', function(id, data)
    if id ~= 0x05B or not settings or not talking then
        return
    end
    local ok, p = pcall(packets.parse, 'outgoing', data)
    if not ok or not p then
        return
    end
    local option = tonumber(p['Option Index'])
    -- Menu navigation (back, next page, open the main menu...) is always
    -- below 256; actions like walk 10994 / watch 12530 carry a high byte.
    if WALK_OPTIONS[option] or WATCH_OPTIONS[option] then
        walk_candidate = nil
    elseif option and option >= 256 and os.time() - walk_prompt_time <= 30 then
        walk_candidate = {option = option, time = os.time()}
    end
    if WALK_OPTIONS[option] then
        pending_walk = os.clock()
        last_care_try = 'walk'
        dbg('walk chosen (option ' .. option .. '); waiting for an energy refusal')
    elseif WATCH_OPTIONS[option] then
        last_care_try = 'watch'
    end
end)

-- Count a pending walk once 3 seconds pass with no 'needs more energy' reply.
local function confirm_pending_walk()
    if pending_walk and os.clock() - pending_walk >= 3 then
        pending_walk = nil
        local t = settings.care_log[today()]
        if t and t.walk_out then
            t.walk_out = nil        -- it walked after all (energy restored)
        end
        record_care('walk', 1)
        say(care_message('walk'))
    end
end

-- The trainer's event data (incoming 0x05C) while talking to a raising NPC:
--   menu opens:   bytes 4-7 = a menu mask ending in 7F, byte 8 = energy
--   action result: byte 4 = action (0x2A walk, 0x30 watch), byte 5 = 2,
--                  byte 8 = energy before, byte 9 = after,
--                  byte 11 has 0x80 set if refused ("needs more energy")
local ACTIONS = {[0x2A] = 'walk', [0x30] = 'watch'}
local last_packet_watch = 0     -- os.time() a watch was counted from a result

-- Store an energy reading; measure the recovery rate between visits, and
-- keep today's first / last reading for the history.
local function set_energy(v)
    local st, old = settings.energy_stats, settings.energy
    if old and v > old.value and v < 100 and os.time() - old.time > 3600 then
        local rate = (v - old.value) / ((os.time() - old.time) / 3600)
        st.rate = math.floor(((tonumber(st.rate) or rate) + rate) / 2 * 100 + 0.5) / 100
        dbg('energy recovered ' .. old.value .. ' -> ' .. v .. ': rate now ' .. st.rate .. '/h')
    end
    settings.energy = {value = v, time = os.time()}
    local d = today()
    settings.care_log[d] = settings.care_log[d] or {}
    local day = settings.care_log[d]
    day.energy_start = day.energy_start or v
    day.energy_end = v
end

-- Average a new cost into a running average (weights the new one by 1/5).
local function blend(avg, cost)
    return math.floor(((tonumber(avg) or cost) * 4 + cost) / 5 * 10 + 0.5) / 10
end

windower.register_event('incoming chunk', function(id, data)
    if id ~= 0x05C or not settings or not talking or #data < 12 then
        return
    end
    local function b(i) return data:byte(i + 1) or 0 end
    if b(7) == 0x7F then
        set_energy(b(8))
        dbg('energy (menu): ' .. b(8))
        save()
        update_ui()
        return
    end
    local action = ACTIONS[b(4)]
    if not action or b(5) ~= 0x02 or b(6) ~= 0 or b(7) ~= 0 then
        return
    end
    local st = settings.energy_stats
    local d = today()
    settings.care_log[d] = settings.care_log[d] or {}
    if b(11) >= 0x80 then
        -- Refused for energy.
        local e = energy_now()
        if action == 'walk' then
            pending_walk = nil
            if e then st.walk_refused_max = math.max(st.walk_refused_max, e) end
        end
        dbg('energy: ' .. action .. ' refused at ' .. tostring(e))
        if not settings.care_log[d][action .. '_out'] then
            settings.care_log[d][action .. '_out'] = true
            say('out of energy for ' .. action .. (action == 'watch' and 'es' or 's') .. ' today ('
                .. care_count(action) .. ' done).')
        end
        save()
        update_ui()
        return
    end
    local before, after = b(8), b(9)
    set_energy(after)
    dbg('energy: ' .. action .. ' ' .. before .. ' -> ' .. after)
    if action == 'walk' then
        pending_walk = nil          -- counted here, not by the timer
        st.walk_ok_min = math.min(st.walk_ok_min, before)
        st.walk_cost = blend(st.walk_cost, before - after)
        settings.care_log[d].walk_out = nil
        record_care('walk', 1)
    else
        last_packet_watch = os.time()
        watch_prompt_time = 0
        st.watch_cost = blend(st.watch_cost, before - after)
        record_care('watch', 1)
    end
    say(care_message(action) .. ' Energy ' .. after .. '.')
end)

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

-- Conversation polling. Status 4 = "Event": the game has you in a conversation or
-- cutscene.
local last_poll = 0             -- os.clock() of the last check (checked 4 times a second)
local last_status = nil         -- player status at the last check (for the debug log)
local last_target_hpp = nil     -- debug: the chocobo's target-bar % last logged
local reported_event = false    -- debug: already logged "not a raising NPC" for this event
-- Called every frame (a few times a second at most): opens the panel when you're in a
-- conversation (status 4) with a raising NPC, closes it when the conversation ends,
-- and confirms pending walks.
local function poll_conversation()
    confirm_pending_walk()
    local now = os.clock()
    if now - last_poll < 0.25 then
        return
    end
    last_poll = now

    -- Status 4 = in a conversation / cutscene.
    local player = windower.ffxi.get_player()
    local in_event = player and player.status == 4
    if debug and player and player.status ~= last_status then
        dbg('status ' .. tostring(last_status) .. ' -> ' .. tostring(player.status)
            .. ' (target: ' .. tostring((windower.ffxi.get_mob_by_target('t') or {}).name) .. ')')
    end
    last_status = player and player.status

    -- Debug: the chocobo's target bar (to compare with the energy readings).
    if debug then
        local t = windower.ffxi.get_mob_by_target('t')
        if t and settings.chocobo_name and t.name == settings.chocobo_name and t.hpp ~= last_target_hpp then
            last_target_hpp = t.hpp
            local e = energy_now()
            dbg('target ' .. t.name .. ' bar ' .. tostring(t.hpp) .. '% (energy ' .. tostring(e) .. ')')
        end
    end

    -- Conversation over: close the panel.
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

    -- In a conversation: is it with a raising NPC? (the NPC from the event packet, or
    -- whoever is targeted). Remember the nation for story walks and owner lists.
    local target = windower.ffxi.get_mob_by_target('t')
    local target_name = target and target.name or nil
    if is_raising_npc(event_npc) or is_raising_npc(target_name) then
        dbg('raising NPC conversation: ' .. tostring(event_npc or target_name))
        local nation = NPC_NATION[lower(event_npc or target_name)]
        if nation and settings.nation ~= nation then
            settings.nation = nation
            save()
        end
        set_talking(true)
    elseif debug and not reported_event then
        dbg('in a conversation, but not with a raising NPC (NPC: '
            .. tostring(event_npc) .. ', target: ' .. tostring(target_name) .. ')')
    end
    reported_event = true
end

------------------------------------------------------------------------
-- Chat parsing: everything read from chat lines
------------------------------------------------------------------------

-- Every chat line goes through here. In order:
--   - our own messages are skipped (add_to_chat output comes back through this event)
--   - the line is cleaned (colour codes removed, line-break bytes turned into spaces)
--   - debug logging
--   - feedings ('gives the chocobo a ...'), energy refusals ('needs more energy')
--   - lost chick clues, stories, abilities, conditions, name, food, likes, stats
--   - the status report day, walk finds and friends
--   - watches (the reaction after 'If you watch over ...')
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

    if debug then
        local player = windower.ffxi.get_player()
        dbg(string.format('TEXT mode %s%s status %s | %s', tostring(mode),
            talking and ' [raising NPC]' or '', tostring(player and player.status),
            show_bytes(original)))
    end

    -- Chocobo check-up lines from the raising NPC.
    local checkup_line = false
    if settings then
        local changed = false

        -- Lost chick quest: start, clues from the trainer, and the end.
        local lc = settings.lost_chick
        if not lc.done then
            local about_chick = low:find('lost chick', 1, true) or low:find('lost chocobo', 1, true)
                or low:find("chick's owner", 1, true)
            if about_chick and not lc.active and not low:find('picked it up', 1, true) then
                lc.active = true
                changed = true
                say('lost chick quest started - clues come from the trainer on later short walks.')
            end
            if lc.active and talking and low:find('owner', 1, true) and not low:find('picked it up', 1, true)
                and chick_read_clue(low) then
                changed = true
                local cands = chick_candidates()
                local names = {}
                for _, o in ipairs(cands) do
                    names[#names + 1] = o[1] .. (o[6] and (' (' .. o[6] .. ')') or '')
                end
                say('lost chick clue: ' .. chick_clue_text() .. ' -> ' .. (#names > 0 and table.concat(names, ', ') or 'no match - //crt chick'))
            end
        end
        if low:find("chick's owner came and picked it up", 1, true)
            or (clean:match('[Oo]btained key item: .*[Dd]iligent chocobo')) then
            if not lc.done then
                lc.done, lc.active = true, false
                changed = true
            end
        end

        -- "Obtained key item: Story of a worrisome chocobo."
        local key_item = clean:match('[Oo]btained key item: (.-)[%s%.!]*$')
        local st = key_item and find_story(key_item)
        if st and not has_story(st) then
            settings.stories[st.name] = today()
            changed = true
            say('story obtained: ' .. st.name .. ' (teaches ' .. st.ability .. ')'
                .. (SKIP_ABILITY[st.ability] and ' - don\'t tell this one, the plan skips ' .. st.ability or '') .. '.')
        end

        -- "Last of all, your animal does not seem to know any abilities." / knows ...
        local names_ability = false
        for _, ab in ipairs(ABILITY_NAMES) do
            if low:find(ab:lower(), 1, true) then names_ability = true end
        end
        if low:find('last of all', 1, true) and (low:find('abilit', 1, true) or names_ability) then
            checkup_line = true
            local known = {}
            if not low:find('not seem to know any', 1, true) then
                for _, a in ipairs(ABILITY_NAMES) do
                    if low:find(a:lower(), 1, true) then
                        known[a] = true
                    end
                end
            end
            local before = table.concat(active_abilities(), ',')
            settings.abilities = known
            if table.concat(active_abilities(), ',') ~= before then
                changed = true
            end
        end

        -- Conditions, during the check-up only (it starts with "Let's see how").
        if talking and os.time() - checkup_start <= 60 and not clean:match('^%s*[%(<%[]') then
            for _, c in ipairs(CONDITIONS) do
                for _, m in ipairs(c.match) do
                    if low:find(m, 1, true) then
                        local known = false
                        for _, n in ipairs(settings.conditions) do
                            if n == c.name then known = true end
                        end
                        if not known then
                            table.insert(settings.conditions, c.name)
                            changed = true
                            say('condition: ' .. c.name .. (c.good and ' (good)' or (c.cure and (' - cure: ' .. c.cure) or '')) .. '.')
                        end
                        break
                    end
                end
            end
        end

        -- "Let's see how <name> is doing today."
        local name = clean:match("[Ll]et's see how (.-) is doing today")
        if name then
            checkup_line = true
            if os.time() - checkup_start > 60 then
                checkup_start = os.time()
                settings.conditions = {}
                settings.conditions_date = today()
                changed = true
            end
            name = name:gsub('^%s+', ''):gsub('%s+$', '')
            if name ~= '' and name ~= settings.chocobo_name then
                settings.chocobo_name = name
                changed = true
                say('chocobo name: ' .. name .. '.')
            end
        end

        -- "Hmmm... Your chocobo seems to be completely full."
        local food = clean:match('[Hh]mm+%.*%s*[Yy]our chocobo seems to be (.-)[%s%.!]*$')
        if food and food ~= '' then
            checkup_line = true
            if food ~= settings.food_level or settings.food_date ~= today() then
                settings.food_level = food
                settings.food_date = today()
                changed = true
            end
        end

        -- "Your chocobo likes clear days."
        local likes = clean:match('[Yy]our chocobo likes (.-)[%s%.!]*$')
        if likes and likes ~= '' then
            checkup_line = true
            if likes ~= settings.likes then
                settings.likes = likes
                changed = true
            end
        end

        -- "Strength: Poor" etc. (one per line, or all on one joined line)
        local updated = {}
        for _, stat in ipairs(STAT_NAMES) do
            local _, e = low:find(stat .. '%s*:%s*')
            if e then
                local rest = low:sub(e + 1)
                local stop = rest:find('%a+%s*:')
                local word = (stop and rest:sub(1, stop - 1) or rest)
                local rank = WORD_RANK[word:gsub('^%s+', ''):gsub('[%s%.!]+$', '')]
                if rank then
                    checkup_line = true
                    if settings.stats[stat] ~= rank then
                        note_stat_change(stat, settings.stats[stat], rank)
                        settings.stats[stat] = rank
                        changed = true
                        updated[#updated + 1] = STAT_LABELS[stat] .. ' ' .. rank_text(rank)
                    end
                end
            end
        end
        if #updated > 0 then
            say('stats updated: ' .. table.concat(updated, ', ') .. '.')
        end

        if changed then
            save()
            update_ui()
        end
    end

    -- "Valdimar gives the chocobo a Vomp carrot." - count one feeding.
    -- (The game prints the line more than once; copies are skipped.)
    if settings then
        local given = clean:match('gives the chocobo (.-)[%s%.!]*$')
        if given then
            local n = tonumber(given:match('^(%d+)%s')) or 1
            given = given:gsub('^%d+%s+', ''):gsub('^an?%s+', ''):gsub('^some%s+', ''):gsub('^the%s+', '')
            local food = FOOD_BY_LOWER[given:lower()] or FOOD_BY_LOWER[given:lower():gsub('s$', '')]
            local now = os.time()
            if food and not (low == last_feed_line and now - last_feed_time <= DUPLICATE_SECONDS) then
                last_feed_line, last_feed_time = low, now
                local was_full = full_today()
                record_food(food, n)
                say('fed ' .. n .. 'x ' .. food .. ' - ' .. fed_count() .. ' today.')
                if was_full then
                    err('careful: it was completely full - force-feeding can give it a stomachache.')
                end
            end
        end

        -- "<name> needs more energy before you can take care of it."
        if low:find('needs more energy', 1, true) then
            -- A refused walk proves which menu choice starts a walk here.
            if walk_candidate and os.time() - walk_candidate.time <= 5 and last_care_try == 'walk'
                and walk_candidate.option >= 256 and not WATCH_OPTIONS[walk_candidate.option] then
                local opt = walk_candidate.option
                WALK_OPTIONS[opt] = true
                settings.learned_walk_options[tostring(opt)] = true
                walk_candidate = nil
                save()
                say('learned this trainer\'s walk menu choice (' .. opt .. ') - walks here count from now on.')
            end
            local what = last_care_try
            if pending_walk then
                what = 'walk'
                pending_walk = nil
            end
            watch_prompt_time = 0
            if what and not energy_out(what) then
                local d = today()
                settings.care_log[d] = settings.care_log[d] or {}
                settings.care_log[d][what .. '_out'] = true
                save()
                update_ui()
                say('out of energy for ' .. (what == 'walk' and 'walks' or 'watches') .. ' today ('
                    .. care_count(what) .. ' done).')
            end
            dbg('needs more energy (after ' .. tostring(what) .. ')')
        end
    end

    -- Walk finds: "Looks like your chocobo found this on one of your walks."
    -- then "Obtained: Quadav backplate!"   Walk friends: "Your chocobo seems to
    -- be getting along well with Chaos." (3 meetings with a friend = a story,
    -- announced with "Let me teach you a story").
    if settings then
        local now = os.time()
        -- Walk finds: the trainer says the chocobo found something, then 'Obtained: <item>'
        -- within 20 seconds is the find.
        if low:find('found this on one of your walks', 1, true) then
            walk_find_time = now
        end
        local item = clean:match('^%s*Obtained: (.-)[%s%.!]*$')
        if item and now - walk_find_time <= 20 and not (low == last_find_line and now - last_find_time <= DUPLICATE_SECONDS) then
            last_find_line, last_find_time = low, now
            walk_find_time = 0
            local d = today()
            settings.care_log[d] = settings.care_log[d] or {}
            local day = settings.care_log[d]
            day.finds = day.finds or {}
            day.finds[item] = (tonumber(day.finds[item]) or 0) + 1
            settings.walk_finds[item] = (tonumber(settings.walk_finds[item]) or 0) + 1
            save()
            say('walk find: ' .. item .. ' (found ' .. settings.walk_finds[item] .. 'x in all).')
        end
        if low:find('what a coincidence', 1, true) then
            coincidence_time = now
        end
        local friend = clean:match('getting along well with (.-)[%s%.!]') or clean:match('getting along well with (.-)$')
        if friend and friend ~= '' and not (low == last_friend_line and now - last_friend_time <= DUPLICATE_SECONDS) then
            last_friend_line, last_friend_time = low, now
            last_friend = friend
            settings.friends[friend] = math.min(3, (tonumber(settings.friends[friend]) or 0) + 1)
            save()
            update_ui()
            say('walk friend: ' .. friend .. ' ' .. settings.friends[friend] .. '/3.')
        end
        if low:find('teach you a story', 1, true) and not (low == last_friend_line and now - last_friend_time <= DUPLICATE_SECONDS) then
            last_friend_line, last_friend_time = low, now
            local who = (last_friend and now - last_friend_time <= 60 and last_friend)
                or (now - coincidence_time <= 30 and (event_npc or 'your trainer')) or nil
            if who then
                settings.friends[who] = 3
                save()
                update_ui()
            end
        end
    end

    -- "Plan: Basic Care" (right after the status report): the care plan in use.
    if settings then
        local shown = clean:match('^%s*Plan:%s*(.-)[%s%.!]*$')
        local plan = shown and find_care_plan(shown)
        if plan then
            local cp = settings.care_plan
            if cp.name ~= plan then
                settings.care_plan = {name = plan, start = today(), days = 0}
                save()
                update_ui()
                say('care plan in use: ' .. plan .. (plan == 'Basic Care' and ' (gives no stats)' or '') .. '.')
            end
            dbg('care plan from the check-up: ' .. shown .. ' -> ' .. plan)
        elseif shown then
            dbg('care plan line not recognised: ' .. shown)
        end
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

        if low:find('take your chocobo on a walk', 1, true) then
            walk_prompt_time = now
            last_care_try = 'walk'
        end
        if low:find('if you watch over', 1, true) then
            watch_prompt_time = now
            last_care_try = 'watch'
            dbg('watch confirmed by NPC; waiting for the reaction')
        else
            -- The reaction: the first narration line after the confirmation.
            -- For an egg it mentions the egg; for a chick, any narration line
            -- (not NPC speech, chat, or the status report) within 30 seconds.
            local stage = current_stage()
            local window = (stage == 'Egg') and WATCH_WINDOW or 30
            local reaction = not npc_speech
                and (mode == 151 or mode == 190)
                and now - watch_prompt_time <= window
                and now - last_packet_watch > 20
                and not clean:match('^%s*[%(<%[{]')
                and not low:find('>>', 1, true)
                and not low:find('status report', 1, true)
                and not checkup_line
                and not low:find('gives the chocobo', 1, true)
                and not low:find('munches', 1, true)
                and not low:find('needs more energy', 1, true)
                and not low:find('obtained', 1, true)
                and (stage ~= 'Egg' or low:find('egg', 1, true))
                and not (low == last_watch_line and now - last_watch_time <= DUPLICATE_SECONDS)
            if reaction and (stage == 'Egg' or stage == 'Chick') then
                last_watch_time = now
                last_watch_line = low
                watch_prompt_time = 0
                record_care('watch', 1)
                say(care_message('watch'))
            end
        end
    end

end)

------------------------------------------------------------------------
-- Help and the command handler
------------------------------------------------------------------------

-- //crt help: the command list in chat.
local function show_help()
    local lines = {
        'CarrotTime commands (//crt):',
        '  reload   (saves your data, then reloads the addon)',
        '  guide | guide on|off | guide phase <1-4>   (raising plan)',
        '  mode npc|always | show | hide | toggle | compact | pos <x> <y> | status',
        '  npc | npc add <name> | npc remove <name>   (NPCs that open the panel)',
        '  debug | debug on|off   (record everything to data/debug/ for troubleshooting)',
        '  name <name>',
        '  stat <stat> <rank> | target <stat> <rank>   (str/end/dsc/rcp, F..SS)',
        '  hatch <YYYY-MM-DD> | age <days> | watch (adds 1) | watches <n>',
        '  scold | walk | undo watch|scold|walk',
        '  feed | feed <food> [n] | unfeed <food> [n]   (feedings)  |  energy',
        '  stories | story <name> [off] | conditions | guide ability <name>',
        '  chick | chick <clue> | chick reset|done   (lost chick quest)',
        '  careplan [plan] [days] | history | finds | friends | reminder on|off',
        '  ability <name> [off]',
        '  care | care <task> | done <task> | undo <task>   (feed exercise outing care story all)',
        '  note <text> | notes [clear]',
        '  race win | loss | place <n> | history | clear',
        '  export   (daily history to data/<Character>_history.csv)',
        '  card | card <n>   (read / link a chocobo card)  |  paddock',
        '  reset confirm',
    }
    for _, l in ipairs(lines) do
        windower.add_to_chat(207, l)
    end
end

-- The command handler parts, tried in order (a list rather than separate variables:
-- Lua 5.1 allows a file only 200 top-level locals).
local COMMAND_PARTS = {}

-- Commands, part 1 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt help (or //crt alone): list the commands
    if command == 'help' or command == '' then
        show_help()
    -- //crt show: open the panel (npc mode: until //crt hide)
    elseif command == 'show' then
        if settings.ui.mode == 'always' then
            settings.ui.visible = true
            save()
        else
            peek = true
        end
        update_ui()
    -- //crt hide: close the panel
    elseif command == 'hide' then
        peek = false
        if settings.ui.mode == 'always' then
            settings.ui.visible = false
            save()
        end
        update_ui()
    -- //crt reload: save, then reload the addon
    elseif command == 'reload' or command == 'r' then
        save()
        say('saved ' .. char_name .. '\'s data; reloading...')
        windower.send_command('lua reload ' .. _addon.name)
    -- //crt debug [on|off]: record everything to a file in data/debug/
    elseif command == 'debug' then
        local a = lower(args[1])
        local turn_on = (a == 'on') or (a == '' and not debug)
        if turn_on then
            if not debug then
                start_debug()
            end
            say('debug on - recording everything to addons/CarrotTime/data/debug/'
                .. debug_path:match('[^/]+$') .. '. Do the things that aren\'t being counted, then //crt debug off.')
        else
            if debug then
                dbg('==== debug off ====')
            end
            debug = false
            say('debug off. Send me addons/CarrotTime/data/debug/'
                .. (debug_path and debug_path:match('[^/]+$') or '<newest file>') .. '.')
        end
    -- //crt mode npc|always: panel only while talking to a raising NPC, or always
    elseif command == 'mode' then
        local m = lower(args[1])
        if m ~= 'npc' and m ~= 'always' then
            say('mode is ' .. settings.ui.mode .. '. Use //crt mode npc or //crt mode always.')
            return true
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
    -- //crt npc [add|remove <name>]: the NPCs that open the panel
    elseif command == 'npc' or command == 'npcs' then
        local sub = lower(args[1])
        local name = title_case(table.concat(args, ' ', 2))
        if sub == 'add' and name ~= '' then
            for _, n in ipairs(settings.raising_npcs) do
                if lower(n) == lower(name) then
                    say(name .. ' is already on the list.')
                    return true
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
                    return true
                end
            end
            err(name .. ' is not on the list.')
        elseif sub == '' then
            say('panel opens for: ' .. format_list(settings.raising_npcs))
        else
            err('usage: //crt npc | npc add <name> | npc remove <name>')
        end
    else
        return false
    end
    return true
end

-- Commands, part 2 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt compact: smaller panel (stats and next step)
    if command == 'compact' then
        settings.ui.compact = not settings.ui.compact
        save()
        update_ui()
        say('compact view ' .. (settings.ui.compact and 'on' or 'off') .. '.')
    -- //crt toggle: show / hide the panel
    elseif command == 'toggle' then
        if settings.ui.mode == 'always' then
            settings.ui.visible = not settings.ui.visible
            save()
        else
            peek = not peek
        end
        update_ui()
    -- //crt pos <x> <y>: move the panel
    elseif command == 'pos' then
        local x, y = tonumber(args[1]), tonumber(args[2])
        if not x or not y then
            err('usage: //crt pos <x> <y>')
            return true
        end
        settings.ui.x, settings.ui.y = x, y
        save()
        update_ui()
    -- //crt name <name>: the chocobo's name
    elseif command == 'name' then
        set_name(rest)
    -- //crt stat <stat> <rank>: record a current rank
    elseif command == 'stat' then
        set_rank('stat', args[1], args[2])
    -- //crt target <stat> <rank> while the guide is on: set it, but warn the guide resets it
    elseif command == 'target' and settings.ui.guide then
        set_rank('target', args[1], args[2])
        say('note: the raising guide resets targets when its phase changes (//crt guide off to keep your own).')
    -- //crt target <stat> <rank>: set a target rank
    elseif command == 'target' then
        set_rank('target', args[1], args[2])
    else
        return false
    end
    return true
end

-- Commands, part 3 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt hatch <YYYY-MM-DD>: hatch date (age is worked out from it)
    if command == 'hatch' then
        set_hatch_date(args[1])
    -- //crt age <days>: set the age by hand
    elseif command == 'age' then
        set_age(args[1])
    -- //crt watch (add one) / //crt watches <n> (egg total)
    elseif command == 'watches' or command == 'watch' then
        set_watches(args[1])
    -- //crt ability <name> [off]: record or remove a learned ability
    elseif command == 'ability' or command == 'abilities' then
        set_ability(args)
    -- //crt care [watch|scold|walk [n]]: show today's care, or log some
    elseif command == 'care' or command == 'done' then
        log_care(args[1] or '', false, args[2])
    -- //crt undo watch|scold|walk [n]: take care back off today
    elseif command == 'undo' then
        log_care(args[1] or '', true, args[2])
    -- //crt careplan [plan] [days]: the care plan set at the trainer
    elseif command == 'careplan' or command == 'plan2' then
        local a = lower(args[1])
        if a == '' then
            local cp = care_plan_state()
            say(cp and ('care plan: ' .. cp.name .. ', day ' .. cp.day .. (cp.days > 0 and ('/' .. cp.days) or '')
                .. (cp.ended and ' (ended)' or '')) or 'no care plan recorded. //crt careplan <plan> [days]')
            say('the guide says: ' .. guide_step().plan .. '. Plans: ' .. table.concat(CARE_PLANS, ', '))
            return true
        elseif a == 'clear' or a == 'off' then
            settings.care_plan = {name = '', start = '', days = 0}
            save()
            update_ui()
            say('care plan cleared.')
            return true
        end
        local days = tonumber(args[#args])
        local words = {}
        for i = 1, (days and #args - 1 or #args) do
            words[#words + 1] = args[i]
        end
        local plan = find_care_plan(table.concat(words, ' '))
        if not plan then
            err('unknown care plan. Plans: ' .. table.concat(CARE_PLANS, ', '))
            return true
        end
        settings.care_plan = {name = plan, start = today(), days = days or 0}
        save()
        update_ui()
        local g = guide_step().plan
        say('care plan: ' .. plan .. (days and (' for ' .. days .. ' days') or '') .. ' from today'
            .. (plan == g and ' - matches the guide.' or (' - the guide says ' .. g .. '.')))
    else
        return false
    end
    return true
end

-- Commands, part 4 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt history: recent days and every stat rank change
    if command == 'history' then
        local dates = {}
        for d in pairs(settings.history) do
            dates[#dates + 1] = d
        end
        table.sort(dates)
        if #dates == 0 then
            say('no history yet.')
            return true
        end
        say('last days (STR/END/DSC/RCP):')
        for i = math.max(1, #dates - 9), #dates do
            local h = settings.history[dates[i]]
            windower.add_to_chat(207, string.format('  %s day %-3s %-2s/%-2s/%-2s/%-2s  walks %s watches %s fed %s%s',
                dates[i]:sub(6), tostring(h.day or '?'), h.strength or '?', h.endurance or '?',
                h.discernment or '?', h.receptivity or '?', tostring(h.walks or 0), tostring(h.watches or 0),
                tostring(h.fed_count or 0), (h.conditions and h.conditions ~= '') and ('  ' .. h.conditions) or ''))
        end
        local changes = {}
        local prev = {}
        for _, d in ipairs(dates) do
            local h = settings.history[d]
            for _, stat in ipairs(STAT_NAMES) do
                if prev[stat] and h[stat] and h[stat] ~= prev[stat] then
                    changes[#changes + 1] = string.format('  day %s (%s): %s %s -> %s', tostring(h.day or '?'),
                        d:sub(6), STAT_LABELS[stat], rank_text(prev[stat]), rank_text(h[stat]))
                end
                prev[stat] = h[stat] or prev[stat]
            end
        end
        say(#changes > 0 and 'rank changes:' or 'no rank changes yet.')
        for _, l in ipairs(changes) do
            windower.add_to_chat(207, l)
        end
    -- //crt finds: items found on walks
    elseif command == 'finds' then
        local items = {}
        for item, n in pairs(settings.walk_finds) do
            items[#items + 1] = item .. ' x' .. n
        end
        table.sort(items)
        local today_finds = fed_text(care_today().finds or {})
        say('walk finds: ' .. (#items > 0 and table.concat(items, ', ') or 'none yet')
            .. (today_finds ~= '' and (' | today: ' .. today_finds) or ''))
    -- //crt friends: walk friends met (3 meetings = a story)
    elseif command == 'friends' then
        local fr = {}
        for name, n in pairs(settings.friends) do
            fr[#fr + 1] = name .. ' ' .. n .. '/3' .. (n >= 3 and ' (story)' or '')
        end
        table.sort(fr)
        say('walk friends: ' .. (#fr > 0 and table.concat(fr, ', ') or 'none met yet')
            .. '. Meeting a friend 3 times on walks gives a story.')
    -- //crt reminder on|off: visit reminder when today's care isn't done
    elseif command == 'reminder' then
        local a = lower(args[1])
        if a == 'on' or a == 'off' then
            settings.ui.reminder = (a == 'on')
            save()
        end
        say('visit reminder ' .. (settings.ui.reminder and 'on' or 'off') .. '.')
    -- //crt chick [clue | reset | done | start]: lost chick quest
    elseif command == 'chick' then
        local lc = settings.lost_chick
        local a = lower(args[1])
        if a == 'reset' then
            settings.lost_chick = {active = true, done = false, initial = '', race = '', gender = '', job = ''}
            save()
            update_ui()
            say('lost chick clues cleared - get new clues from the trainer on short walks.')
            return true
        elseif a == 'done' then
            lc.done, lc.active = true, false
            save()
            update_ui()
            say('lost chick quest marked done.')
            return true
        elseif a == 'start' then
            lc.active, lc.done = true, false
            save()
            update_ui()
        elseif a ~= '' then
            local text = lower(table.concat(args, ' '))
            local before = chick_clue_text()
            if #text == 1 and text:match('%a') then
                lc.initial = text:upper()
            else
                chick_read_clue(' owner ' .. text)
            end
            lc.active = true
            save()
            update_ui()
            if chick_clue_text() == before then
                err('clue not understood. Use a letter, a race (hume, galka...), male/female, or a job (merchant, miner...).')
                return true
            end
        end
        local status_txt = lc.done and 'done' or (lc.active and 'in progress' or 'not started')
        say('lost chick (' .. chick_nation() .. ', ' .. status_txt .. '): ' .. chick_clue_text())
        for _, o in ipairs(chick_candidates()) do
            windower.add_to_chat(207, string.format('  %-20s %-2s %-6s %-7s %-22s %s',
                o[1], o[2], o[4], o[3], o[5], o[6] or ''))
        end
    -- //crt stories: all six stories, the ability each teaches, how to get it
    elseif command == 'stories' then
        say('stories (the ability each teaches, and how to get it' .. (settings.nation ~= '' and (' in ' .. settings.nation) or '') .. '):')
        for _, st in ipairs(STORIES) do
            local mark = settings.abilities[st.ability] and 'learned' or (has_story(st) and 'have it' or 'missing')
            local advice = SKIP_ABILITY[st.ability] and ' - skip (only adds junk to digs)'
                or ((st.ability == 'Treasure Finder' or st.ability == settings.second_ability) and ' - plan: tell this' or '')
            windower.add_to_chat(207, string.format('  %-16s %-8s %s%s', st.ability, mark, st.name, advice))
            windower.add_to_chat(207, '                            get: ' .. story_how(st))
        end
    -- //crt story <name> [off]: record a story key item by hand
    elseif command == 'story' then
        local off = lower(args[#args]) == 'off'
        local st = find_story(table.concat(args, ' ', 1, off and #args - 1 or #args))
        if not st then
            err('usage: //crt story <name> [off], e.g. //crt story worrisome. //crt stories lists them.')
            return true
        end
        settings.stories[st.name] = (not off) and today() or nil
        save()
        update_ui()
        say(st.name .. (off and ' removed.' or (' recorded (teaches ' .. st.ability .. ').')))
    else
        return false
    end
    return true
end

-- Commands, part 5 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt conditions: every condition, its effect and cure
    if command == 'conditions' or command == 'condition' then
        local cur = #settings.conditions > 0 and table.concat(settings.conditions, ', ') or 'nothing unusual'
        say('conditions - now: ' .. cur .. (settings.conditions_date ~= '' and (' (check-up ' .. settings.conditions_date .. ')') or ' (no check-up yet)'))
        for _, c in ipairs(CONDITIONS) do
            windower.add_to_chat(207, string.format('  %-28s %-17s %s', c.name, c.kind, c.effect))
            windower.add_to_chat(207, '      ' .. (c.good and 'Good - no cure needed' or ('Cure: ' .. c.cure)))
        end
    -- //crt feed / feed <food> [n] / unfeed <food> [n]: feedings
    elseif command == 'feed' or command == 'unfeed' then
        if #args == 0 then
            local n = fed_count()
            say('fed today: ' .. (n > 0 and (fed_text() .. ' (' .. n .. ' in all)') or 'nothing yet') .. '.')
            return true
        end
        local n = tonumber(args[#args])
        local words = {}
        for i = 1, (n and #args - 1 or #args) do
            words[#words + 1] = args[i]
        end
        n = n or 1
        local food = find_food(table.concat(words, ' '))
        if not food or n < 1 or n ~= math.floor(n) then
            err('usage: //crt ' .. command .. ' <food> [count], e.g. //crt feed vomp 3. Foods: '
                .. table.concat(FOODS, ', '))
            return true
        end
        record_food(food, command == 'feed' and n or -n)
        say((command == 'feed' and 'fed ' or 'took back ') .. n .. 'x ' .. food .. ' - '
            .. fed_count() .. ' today.')
    -- //crt scold: log a scold
    elseif command == 'scold' then
        log_care('scold', false)
    -- //crt walk [n]: log a walk
    elseif command == 'walk' then
        log_care('walk', false, args[1])
    -- //crt note <text>: add a note
    elseif command == 'note' then
        add_note(rest)
    -- //crt notes [clear]: list or clear notes
    elseif command == 'notes' then
        list_notes(args[1])
    -- //crt race win|loss|place <n>|history|clear: race record
    elseif command == 'race' then
        race_command(args[1] or '', args[2])
    else
        return false
    end
    return true
end

-- Commands, part 6 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt status: summary in chat
    if command == 'status' then
        status()
    -- //crt guide [on|off | phase <n> | ability <name>]: the raising guide
    elseif command == 'guide' or command == 'plan' then
        local a = lower(args[1])
        if a == 'ability' then
            local want = lower(table.concat(args, ' ', 2))
            local pick
            for _, ab in ipairs({'Canter', 'Gallop', 'Auto-Regen'}) do
                if ab:lower() == want or ab:lower():sub(1, #want) == want and want ~= '' then
                    pick = ab
                end
            end
            if not pick then
                err('usage: //crt guide ability canter|gallop|auto-regen  (now ' .. settings.second_ability .. ')')
                return true
            end
            settings.second_ability = pick
            save()
            update_ui()
            local st = story_for_ability(pick)
            say('second ability: ' .. pick .. ' (' .. st.name .. ' - ' .. story_how(st) .. ').')
        elseif a == 'phase' then
            local n = tonumber(args[2])
            if not n or n < 1 or n > #GUIDE_PHASES or n ~= math.floor(n) then
                err('usage: //crt guide phase <1-4>')
                return true
            end
            settings.guide_phase = n
            apply_guide_targets()
            save()
            update_ui()
            say('raising guide set to phase ' .. n .. '/4: ' .. GUIDE_PHASES[n].name .. '.')
        elseif a == 'on' or a == 'off' then
            settings.ui.guide = (a == 'on')
            save()
            update_ui()
            say('raising plan ' .. (settings.ui.guide and 'shown' or 'hidden') .. ' on the panel.')
        else
            show_guide()
        end
    -- //crt chatcolor <n>: colour of the load message
    elseif command == 'chatcolor' or command == 'chatcolour' then
        local n = tonumber(args[1])
        if not n or n < 0 or n > 255 or n ~= math.floor(n) then
            err('usage: //crt chatcolor <0-255>  (now ' .. tostring(settings.ui.load_color) .. ')')
            return true
        end
        settings.ui.load_color = n
        save()
        windower.add_to_chat(n, '[CarrotTime] load message colour set to ' .. n .. '.')
    -- //crt export: daily history to a .csv file
    elseif command == 'export' or command == 'csv' then
        export_csv()
    -- //crt card [n]: read chocobo cards in the inventory / link one
    elseif command == 'card' or command == 'cards' then
        local n = tonumber(args[1])
        local ok, cards = read_card(false)
        if n then
            local f = cards[n]
            if not f then
                err('no card ' .. n .. '. Type //crt card to list them.')
                return true
            end
            apply_card(f.card, true)
            save()
            update_ui()
            say('card ' .. n .. ' (' .. f.name .. ') linked to ' .. settings.chocobo_name .. '.')
            return true
        end
        if #cards == 0 then
            say('no chocobo card in your inventory (VCS registration, racing form or chococard).')
            return true
        end
        for i, f in ipairs(cards) do
            local mark = (settings.card_fingerprint == card_fingerprint(f.card)) and ' (linked)' or ''
            print_card(i .. '. ' .. f.name .. mark, f.card)
        end
        if ok then
            save()
            update_ui()
        else
            say('type //crt card <number> to link one to ' .. settings.chocobo_name .. '.')
        end
    -- //crt paddock: the chocobo being viewed in the Chocobo Circuit paddocks
    elseif command == 'paddock' or command == 'padock' then
        show_paddock()
    -- //crt capture: old command, points to //crt debug
    elseif command == 'capture' then
        say('capture was replaced by //crt debug on, which records everything.')
    else
        return false
    end
    return true
end

-- Commands, part 7 (split up: Lua 5.1 allows a function only 60 outside variables)
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    -- //crt reset confirm: wipe this character's chocobo data
    if command == 'reset' then
        if lower(args[1]) ~= 'confirm' then
            err('this wipes all chocobo data for ' .. char_name .. '. Type //crt reset confirm to do it.')
            return true
        end
        local keep = deep_copy(settings.ui)
        settings = deep_copy(defaults)
        settings.ui = keep
        save()
        update_ui()
        say('data reset.')
    else
        return false
    end
    return true
end

-- Commands, energy part: //crt energy
COMMAND_PARTS[#COMMAND_PARTS + 1] = function(command, args, rest)
    if command ~= 'energy' then
        return false
    end
    local e, est = energy_now()
    local st = settings.energy_stats
    if not e then
        say('no energy reading yet - open the trainer\'s menu once.')
        return true
    end
    local ws = walk_status(e)
    say('energy ' .. (est and '~' or '') .. e .. '/100' .. (est and ' (estimated from the last reading)' or '')
        .. ': ' .. (ws == 'maybe' and 'a walk may or may not go through' or (walks_left(e) .. ' walk(s)'))
        .. ', ~' .. watches_left(e) .. ' watch(es) left.')
    windower.add_to_chat(207, string.format('  walk: works at %d+, refused at %d or less; uses ~%.1f.  watch: uses ~%.1f.',
        st.walk_ok_min, st.walk_refused_max, st.walk_cost, st.watch_cost))
    local rate = tonumber(st.rate) or 0
    windower.add_to_chat(207, string.format('  recovers ~%.2f an hour (it does not refill at the daily reset).', rate))
    if ws ~= 'yes' and rate > 0 then
        windower.add_to_chat(207, string.format('  enough for a walk (%d) in about %.0f hours.',
            st.walk_ok_min, (st.walk_ok_min - e) / rate))
    end
    return true
end


-- //crt <command>: checks a character is loaded, then hands the command to each
-- commands_N part in turn until one handles it.
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = lower(command or 'help')

    if not char_name or not settings then
        err('log in to a character first.')
        return
    end

    local rest = table.concat(args, ' ')

    for _, part in ipairs(COMMAND_PARTS) do
        if part(command, args, rest) then
            return
        end
    end
    err('unknown command "' .. command .. '". Try //crt help')
end)

------------------------------------------------------------------------
-- Character loading, dragging and day rollover
------------------------------------------------------------------------

-- Load the logged-in character's data and apply one-time upgrades from older versions
-- (day key, learned walk choices, guide targets, walk / rank migrations), then show the
-- load message.
local function load_character()
    local player = windower.ffxi.get_player()
    if not player or not player.name then
        return
    end
    char_name = player.name
    settings = load_data(char_name)

    -- v0.9: one "walk" (leisurely / brisk were the same), ranks top out at SS
    for _, day in pairs(settings.care_log) do
        local w = (tonumber(day.walk) or 0) + (tonumber(day.walk_leisurely) or 0)
            + (tonumber(day.walk_brisk) or 0)
        day.walk_leisurely, day.walk_brisk = nil, nil
        day.walk = w > 0 and w or nil
    end
    -- v2.6: days follow the Japanese reset. Move today's entries from the
    -- local date to the game date, and keep the chocobo's age the same.
    -- v2.6, once: days used to start at local midnight; move today's care, history and
    -- dates over to the game day (Japanese midnight).
    if not settings.day_key_v26 then
        local local_day, game_day = os.date('%Y-%m-%d'), today()
        if local_day ~= game_day then
            if settings.care_log[local_day] and not settings.care_log[game_day] then
                settings.care_log[game_day], settings.care_log[local_day] = settings.care_log[local_day], nil
            end
            if settings.history[local_day] and not settings.history[game_day] then
                settings.history[game_day], settings.history[local_day] = settings.history[local_day], nil
            end
            for _, k in ipairs({'food_date', 'last_watch_date', 'conditions_date'}) do
                if settings[k] == local_day then
                    settings[k] = game_day
                end
            end
            if settings.card and settings.card.date == local_day then
                settings.card.date = game_day
            end
            local shift = (date_to_time(game_day) - date_to_time(local_day)) / 86400
            local hatch = date_to_time(settings.hatch_date)
            if hatch then
                settings.hatch_date = os.date('%Y-%m-%d', hatch + math.floor(shift + 0.5) * 86400)
            end
        end
        settings.day_key_v26 = true
    end
    for opt in pairs(settings.learned_walk_options) do
        local n = tonumber(opt)
        if n and n >= 256 and not WATCH_OPTIONS[n] then
            WALK_OPTIONS[n] = true
        else
            settings.learned_walk_options[opt] = nil   -- v2.8: navigation choices aren't walks
            say('removed a wrongly learned walk menu choice (' .. tostring(opt) .. ').')
        end
    end
    -- v1.6: targets follow the raising guide's phase
    if settings.ui.guide and not settings.guide_targets_v16 then
        apply_guide_targets()
        settings.guide_targets_v16 = true
    end
    for _, t in ipairs({settings.stats, settings.racing_targets}) do
        for k, v in pairs(t) do
            if v == 'SSS' then
                t[k] = 'SS'
            end
        end
    end
    pcall(read_card, true)
    save()  -- writes the file the first time, and fills in any new defaults
    update_ui()
    local load_color = tonumber(settings.ui.load_color) or 207
    windower.add_to_chat(load_color, '[CarrotTime] Author: ' .. _addon.author .. ' v' .. _addon.version)
    windower.add_to_chat(load_color, '[CarrotTime] Loaded profile for ' .. char_name
        .. ' (' .. settings.ui.mode .. ' mode).')
    if settings.ui.reminder and not care_done_today() then
        windower.add_to_chat(load_color, '[CarrotTime] Today: ' .. next_advice()
            .. ' (reset in ' .. reset_text() .. ').')
    end
end

------------------------------------------------------------------------
-- Visit reminder
------------------------------------------------------------------------

-- Towns with the raising NPCs: Southern San d'Oria, Bastok Mines, Windurst Woods.
local STABLE_ZONES = {[230] = "San d'Oria", [234] = 'Bastok', [241] = 'Windurst'}

-- Visit reminder: if today's care isn't finished, say what's next and show the panel
-- for 20 seconds.
local function remind(where)
    if not settings or not settings.ui.reminder or care_done_today() then
        return
    end
    local load_color = tonumber(settings.ui.load_color) or 207
    windower.add_to_chat(load_color, '[CarrotTime] ' .. where .. ': ' .. next_advice()
        .. ' (reset in ' .. reset_text() .. ').')
    peek_until = os.clock() + 20
    update_ui()
end

-- Entering the town of your raising NPC: remind 5 seconds later (after zoning settles).
windower.register_event('zone change', function(new_id)
    if not settings then
        return
    end
    local town = STABLE_ZONES[new_id]
    if town and (settings.nation == '' or settings.nation == town) then
        coroutine.schedule(function() remind(settings.chocobo_name .. ' needs care') end, 5)
    end
end)

-- Save and forget the character (logout): the panel hides until the next login.
local function unload_character()
    save()
    talking, peek = false, false
    char_name = nil
    settings = nil
    update_ui()
end

-- Addon loaded: create the panel and, if already logged in, load the character.
windower.register_event('load', function()
    create_ui()
    if windower.ffxi.get_info().logged_in then
        load_character()
    end
end)

-- Logged in: load the character after 2 seconds (player data isn't ready right away).
windower.register_event('login', function()
    -- Player data isn't always ready the instant login fires.
    coroutine.schedule(load_character, 2)
end)

-- Logged out: save and clear the character.
windower.register_event('logout', unload_character)

-- Addon unloaded (or reloaded): save and remove the panel.
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
-- Every frame: watch for raising-NPC conversations, and every 30 seconds refresh the
-- panel (day / reset rollover) and re-read the chocobo card.
windower.register_event('prerender', function()
    if settings then
        poll_conversation()
        if peek_until > 0 and os.clock() >= peek_until then
            peek_until = 0
            update_ui()
        end
    end
    local now = os.clock()
    if now - last_refresh >= 30 then
        last_refresh = now
        if settings then
            local ok, _, _, changed = pcall(read_card, false)
            if ok and changed then
                save()
            end
            update_ui()
        end
    end
end)
