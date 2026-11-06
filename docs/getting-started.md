# Getting started

This page takes you from an empty file to a working script, then covers the rules every script lives by.

## 1. Where scripts go

Put any `.lua` file in:

```
C:\VITTLOCK\scripts\v2\
```

Subfolders are fine. Every `.lua` file in the folder is loaded when the game starts, after a map change, and when you press **Reload** in the menu's **Lua** tab.

## 2. Your first script

Create `C:\VITTLOCK\scripts\v2\hello.lua`:

```lua
-- A page in the menu's Lua tab: first tab > section > second tab > third tab > group.
-- Empty levels show no selector, so this is one page with one group.
local group = Menu.Create("Hello", "", "", "", "Main")

local enabled = group:Switch("Enabled", true)
local color   = group:ColorPicker("Text color", Color(255, 255, 255))

callback.on_draw:set(function()
    if not enabled:Get() then return end

    local me = entity_list.local_pawn()
    if not me then return end          -- not in a match yet

    local text = ("Health: %d / %d"):format(me.m_iHealth, me:get_max_health())
    Render.Text(0, 18, text, Vec2(20, 200), color:Get())
end)
```

Load the game, join the hideout, and open the menu's **Lua** tab: your script has its own page, **Hello**. Your health is drawn on the left of the screen.

What happened:

- `Menu.Create` found or created the page and returned a group to put widgets in. Widget values are saved between sessions automatically. See [menu](menu.md).
- `callback.on_draw:set(fn)` registered a function that runs every rendered frame. See [callbacks](callbacks.md).
- `entity_list.local_pawn()` returned your hero, and `me.m_iHealth` read a networked field by its name. See [entities](entities.md).
- `Render.Text` drew text. Drawing only works inside `on_draw`. See [render](render.md).

## 3. Editor setup (autocomplete)

The [`library/`](../library) folder of this repo describes the whole API for the Lua language server.

1. Install VS Code and the **Lua** extension by sumneko.
2. Copy [`.luarc.json`](../.luarc.json) next to your scripts (into `C:\VITTLOCK\scripts\v2\`), and set `workspace.library` to wherever you put this repo's `library` folder.
3. Open the scripts folder in VS Code. You get autocomplete, parameter hints and type warnings for every function on these pages.

## 4. The rules

### Callbacks drive everything
A script runs its top level once when it loads. After that, it only runs from callbacks:

| Callback | Use it for |
|---|---|
| `on_frame` | Game logic every frame: reading entities, timers, panorama UI. |
| `on_pre_createmove` / `on_createmove` / `on_post_createmove` | Changing what your player does this tick (buttons, movement, aim) through the [user command](usercmd.md). |
| `on_draw` | Drawing with `Render.*`. |
| Event callbacks | Things that happen: entities spawning, modifiers applied and removed, particles, bullets, sounds, keys, network messages. |

See [callbacks](callbacks.md) for the full list, arguments and return values.

### One shared environment
All scripts share one global environment, loaded in file-name order (case-insensitive; names starting with a symbol such as `_` load first). A global set by one script is visible to every script loaded after it. Declare everything `local` unless you mean to share it.

To split code into modules, put them in `scripts\v2\lib\` and load them with `require`. Files in `lib\` are not run as scripts on their own; they only run when something requires them.

```lua
-- scripts\v2\lib\mathx.lua
local M = {}
function M.clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
return M
```

```lua
-- scripts\v2\my_script.lua
local mathx = require("lib.mathx")   -- dots become folders, loaded once per session
```

### Errors don't stop your script
If a callback raises an error, the error is shown in your script's log in the menu's **Lua** tab, and the callback keeps being called on later frames. `print(...)` also goes to that log. Use `pcall` around code that is expected to fail.

### Game objects are short-lived
Entity, ability, modifier and panel objects refer to live game objects. Get them fresh each frame (or check `valid()` / `is_valid()` before using a stored one). Never assume your hero exists: `entity_list.local_pawn()` is `nil` in the main menu and between maps.

### Saving data
- Widget values save themselves.
- For your own data, use the persistent [`db`](storage.md) table (saved to disk) or [`global_ctx`](storage.md) (shared between scripts for this session only).

### Performance
Callbacks run inside the game's frame. Keep them light:
- Load fonts and images once at the top level, not every frame.
- Cache lists you need several times in one frame.
- Throttle expensive work by checking the time (`global_vars.curtime()` or `chronos.nanotime()`) and running it only every so often. See [core](core.md).

## 5. Where next

- [Callbacks](callbacks.md), [Menu](menu.md), [Render](render.md): the three things almost every script uses.
- [Entities](entities.md): heroes, abilities, items, modifiers and networked fields.
- [User command](usercmd.md) and [Input](input.md): acting on the game.
- The [examples](../examples) folder: complete scripts you can copy and change.
