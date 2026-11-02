# CarrotTime

**CarrotTime** is a Windower 4 addon for tracking and planning Final Fantasy XI chocobo raising.

It helps players keep track of their chocobo’s age, development path, stats, care tasks, abilities, egg-phase watches, and racing results.

> **Version:** 0.4.0  
> **Addon command:** `//crt`

## Features

- **Digging and racing paths**
  - Digging: track the Bore and Burrow goals.
  - Racing: track Gallop and Canter goals.
- **Chocobo age and stage tracking**
  - Set the hatch date or enter the current age manually.
- **Egg-phase watch tracking**
  - Enter the number of watches performed during the egg phase.
- **Stat tracking**
  - Record Strength, Endurance, Discernment, and Receptivity ranks.
- **Racing target advisor**
  - Configure target ranks for each stat.
  - Review which stat is furthest from its configured target.
- **Race history**
  - Record wins, losses, and finishing places.
- **Daily care checklist**
  - Log care tasks for the current day.
- **Notes**
  - Save reminders and observations.
- **On-screen display**
  - View your chocobo’s profile and current tracking information.

## Installation

1. Install [Windower 4](https://www.windower.net/) and ensure the Lua addon support is enabled.
2. Create a folder named `CarrotTime` inside your Windower addons directory.
3. Save `CarrotTime.lua` inside that folder.
4. In-game, load the addon:

   ```text
   //lua load CarrotTime
   ```

5. View the available commands:

   ```text
   //crt help
   ```

## Commands

### General

| Command | Description |
|---|---|
| `//crt` | Show the current chocobo profile |
| `//crt help` | Display the command list |
| `//crt show` | Show the CarrotTime display |
| `//crt hide` | Hide the CarrotTime display |
| `//crt reset` | Reset the saved profile |

### Chocobo profile

| Command | Description |
|---|---|
| `//crt type digging` | Set the chocobo path to digging |
| `//crt type racing` | Set the chocobo path to racing |
| `//crt hatch YYYY-MM-DD` | Set the hatch date |
| `//crt age <days>` | Set the age manually |
| `//crt watches <number>` | Record the number of egg-phase watches |

Examples:

```text
//crt hatch 2026-11-02
//crt age 12
//crt watches 3
```

The watch counter is intended for use during the egg phase.

### Stats and racing targets

Record a current stat rank:

```text
//crt stat strength A
//crt stat endurance B
//crt stat discernment A
//crt stat receptivity C
```

Configure a target rank:

```text
//crt target strength SS
//crt target endurance B
//crt target discernment A
//crt target receptivity C
```

Supported stat names:

- `strength`
- `endurance`
- `discernment`
- `receptivity`

Supported ranks:

`F`, `E`, `D`, `C`, `B`, `A`, `S`, `SS`, `SSS`

### Racing focus

Choose a racing focus:

```text
//crt focus official
//crt focus circuit
//crt focus custom
```

The focus is recorded with race results and can be used to distinguish the type of racing plan being tracked.

### Care tracking

Log a daily care task:

```text
//crt care feed
//crt care exercise
//crt care outing
//crt care care
//crt care story
```

`//crt done <task>` is an alias for `//crt care <task>`.

Supported tasks:

- `feed`
- `exercise`
- `outing`
- `care`
- `story`

### Race history

Record a race result:

```text
//crt race win
//crt race loss
//crt race place 2
```

View recorded race results:

```text
//crt race history
```

### Notes

Save a note:

```text
//crt note Try a different feeding plan tomorrow.
```

## Chocobo paths

### Digging

The digging path is intended for players working toward the **Bore** and **Burrow** abilities.

CarrotTime can track the selected path and recorded abilities. It does not automatically determine whether an in-game ability has been learned.

### Racing
