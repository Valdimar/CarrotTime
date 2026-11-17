# CarrotTime

A chocobo raising assistant for **Windower 4**. A panel that appears while you talk to your raising
NPC (Hantileon, Zopago or Pulonono) and tracks your chocobo's day, stats, care, food, stories and
conditions, with a built-in raising guide for a digger built off a racing-stat base.

**Author:** Valdimar @ Phoenix  **Version:** 3.5  **Commands:** `//crt`, `//carrottime`

> Status: tested against a recorded play session and simulated game data, not every feature live in
> game. If something isn't counted, turn on `//crt debug` (see below) and send the log.

## Install

1. Unzip `CarrotTime-v<version>.zip` into `Windower4/addons/`. You get `addons/CarrotTime/`.
2. In game: `//lua load CarrotTime`. To load it every time, add `lua load CarrotTime` to
   `Windower4/scripts/init.txt`.
3. Talk to your raising NPC. Chat shows:

   ```
   [CarrotTime] Author: Valdimar @ Phoenix v3.5
   [CarrotTime] Loaded profile for Valdimar (npc mode).
   ```

**Updating:** unzip over the old copy and run `//crt reload`. Your data in `data/` is kept.

## Update check

A few seconds after you log in, CarrotTime checks GitHub once and always says the result in chat:

```
[CarrotTime] Up to date (version 3.5).
[CarrotTime] UPDATE AVAILABLE: version X.Y is out (you have 3.5). Get it from github.com/Valdimar/CarrotTime
[CarrotTime] Version 3.5 is newer than GitHub (X.Y), so it hasn't been released yet.
[CarrotTime] Couldn't check for updates (GitHub didn't answer). Try again with a reload.
```

An available update is shown in a different colour so it stands out. If the game has no HTTPS
support, it says it couldn't check. The game can pause for a moment while it checks (at most 3
seconds, usually much less). `//lua reload CarrotTime` checks again.

## The panel

The panel opens when a conversation with a raising NPC starts and closes when it ends (or when you
zone). `//crt show` / `//crt hide` open or close it by hand; `//crt mode always` keeps it on screen.
It's always 45 characters wide; long text wraps.

| Section | Shows |
| --- | --- |
| Header | Chocobo name, version, stage, day, days to the next stage |
| Energy | Energy 0-100 with a bar, walks and watches left (`~` = estimated since the last reading) |
| Food / Likes / Status | Food level from the check-up, feedings today, liked day type, conditions with their cure |
| Stats | Each stat as `Poor \| F` with a bar towards its target; `^` / `v` marks a rank change in the last 2 days |
| Today's care | Chick: walks until out of energy, then watches until out of energy. Older: walks |
| Plan | Guide phase, care plan to use, the goal, what to do daily, what's next, and the plan you set |
| Abilities / Stories | Learned abilities, stories you hold (Burrow / Bore marked skip), walk friends |
| Lost chick | Clues so far and who the owner can still be, with map positions |
| Racing | Exact stat values from your chocobo card, riding speed and time, race record |
| `>` line | The next thing to do: a cure, walks, watches, carrots, the plan |

Days follow the game's reset: Japanese midnight (10 AM Eastern standard time).

## What's counted automatically

| Thing | How |
| --- | --- |
| Day | `--Chocobo Status Report: Day #--`; counts up daily between visits |
| Care plan | `Plan: Basic Care` (right after the status report); `//crt careplan` still sets it by hand |
| Name | `Let's see how <name> is doing today` |
| Food level / likes | `Hmmm... Your chocobo seems to be ...` / `Your chocobo likes ...` |
| Stats | `Strength: Poor` and the other three lines (Poor F, Substandard E, A bit deficient D, Average C, Better than average B, Impressive A, Outstanding S, First-Class SS) |
| Abilities | `Last of all, your animal ...` |
| Conditions | Key words in the check-up (Happiness, Stomachache, Injured, Spoiled, ...) |
| Walks / watches | The game's result data for each walk or watch (works at any trainer). Fallbacks: the walk menu choice, and the line after `If you watch over ...` |
| Out of energy | `... needs more energy before you can take care of it.` |
| Energy | The trainer's menu data (exact value); walk / watch results (energy before and after, or refused) |
| Feedings | `<you> gives the chocobo a <food>.` (all greens, carrots, pastes, wildgrass, worms, Chocolixirs, salads, Potion, Chocotonic, Lethe soups, including names like `a bunch of gysahl greens` or `a ball of herb paste`). If you trade a food to the trainer and the conversation ends with no such line (a cure for a sick chick, say), it's counted from the trade |
| Stories | `Obtained key item: Story of ...` |
| Walk finds / friends | `found this on one of your walks` / `getting along well with <friend>` |
| Lost chick clues | The trainer's clues on short walks |
| Card values | A VCS registration card, racing form or chococard in your inventory |

Scolds and story-telling aren't detected yet: use `//crt scold`.

## Energy

Read from the trainer's menu data every time the menu opens. From Valdimar's logs:

- Energy runs 0-100. A walk uses about 23-24, a watch about 3-4.
- A walk needs more than 27 energy (refused at 24 and 27, went through at 47). The addon learns
  these limits from your chocobo's results.
- Energy **does not refill at the daily reset**: it recovers about 1.4 an hour. Spending it all on
  watches leaves too little for walks the next day.
- Between visits the panel estimates energy from the measured recovery rate (shown with `~`).

`//crt energy` shows the current value, walks / watches left, the learned limits and recovery rate,
and how long until there's enough for a walk.

## Raising guide

A digger built off a racing-stat base, in 4 phases. The phase moves on by itself.

| Phase | Goal | Care |
| --- | --- | --- |
| 1. Build STR/END | STR and END Outstanding (S, 192+) | Take a Walk (chick), Carry Packages, then whichever of STR/END is behind. 3 Vomp Carrots and walks daily (skip the carrots on a "completely full" day) |
| 2. Trade STR/END for DSC/RCP | DSC Average (C, 96+) | Register at the racing stables, then Exhibit to the Public (Listen to Music as a chick) |
| 3. Learn abilities | 2 abilities | Basic Care. Tell the diligent story (Treasure Finder) and the second ability's story (Canter by default). Never tell the worrisome (Burrow) or youthful (Bore) stories |
| 4. Raise END/RCP | As high as possible | Exercise in a Group or Act in a Play, whichever of END/RCP is lower |

From the chick stage on, always have a stat care plan set at the trainer: plans raise stats every
day without food, and Basic Care gives none (phase 3 uses it on purpose). The next step flags a plan
that doesn't match the guide before the carrot reminder. Care plans are said to stop changing stats
around day 65. `//crt guide` prints the full plan.

## Commands

| Command | Does |
| --- | --- |
| `help` / `reload` | List commands / save and reload |
| `show` / `hide` / `toggle` / `mode npc\|always` / `compact` / `pos <x> <y>` | Panel |
| `npc [add\|remove <name>]` | NPCs that open the panel |
| `status` / `care` / `energy` | Summary / today's care and time to the reset / energy, walks and watches left |
| `watch` / `watches <n>` / `scold` / `walk [n]` / `undo watch\|scold\|walk [n]` | Care by hand |
| `feed` / `feed <food> [n]` / `unfeed <food> [n]` | Feedings (`feed vomp 3`) |
| `food` / `food <name>` / `food inv` | What a food does for the chocobo (`food zegham`): stats, affection, energy, what it cures, notes and where it fits the raising guide. `food` lists every food; `food inv` lists the chocobo food you're carrying |
| `stat <stat> <rank>` / `target <stat> <rank>` | Stats by hand (`stat str average`) |
| `age <days>` / `hatch <YYYY-MM-DD>` / `name <name>` | Day and name by hand |
| `ability <name> [off]` | Abilities by hand |
| `guide [on\|off]` / `guide phase <1-4>` / `guide ability canter\|gallop\|auto-regen` | Raising guide |
| `careplan [plan] [days]` | The care plan you set at the trainer |
| `stories` / `story <name> [off]` | All stories and how to get them / record one |
| `conditions` | Every condition, its effect and cure |
| `chick` / `chick <clue>` / `chick reset\|done` | Lost chocobo chick quest |
| `finds` / `friends` | Walk finds / walk friends (3 meetings = a story) |
| `history` / `export` | Rank changes by day / daily history to `data/<Character>_history.csv` |
| `card [n]` / `paddock` | Chocobo card values / the chocobo you're viewing in the paddocks |
| `race win\|loss\|place <n>` / `race history` | Race record |
| `reminder on\|off` | Reminder in your trainer's town when today's care isn't done |
| `note <text>` / `notes [clear]` | Notes |
| `chatcolor <n>` | Colour of the load message (207) |
| `debug [on\|off]` | Record everything to `data/debug/` |
| `reset confirm` | Wipe this character's chocobo data |

## Debug logs

If something isn't counted: `//crt debug on`, do it in game, `//crt debug off`, and send the file
named in chat from `addons/CarrotTime/data/debug/`. It records every chat line (with hidden bytes),
NPC conversation starts and ends, menu choices, trades, status changes and what the addon counted.

## Files

| File | Holds |
| --- | --- |
| `data/<Character>.lua` | That character's chocobo, care, history and settings |
| `data/<Character>_history.csv` | Written by `//crt export` |
| `data/debug/<date_time>.txt` | Debug logs |

## Credits

- Chocobo card / paddock layout and riding formulas from Ivaar's
  [chococard](https://github.com/Ivaar/Windower-addons/tree/master/chococard) addon
  (independent implementation).
- Story and condition lists from Valdimar; lost chick owners from the
  [BG-Wiki](https://www.bg-wiki.com/ffxi/Lost_Chocobo_Chick_Mini-Quest) page plus Valdimar's map
  positions.
- Food effects from BG-Wiki's Chocobo Raising page, FFXIclopedia's raising guide and the FFXIAH
  "demystifying chocobo raising plans and food" thread.
- Raising and care plan information from FFXIclopedia, BG-Wiki, FFXIAH, FFXIOnline and Allakhazam.
