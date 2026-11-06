# VITTLOCK Lua API

Write Lua 5.4 scripts for Deadlock with VITTLOCK: build your own menu pages, draw on screen, read heroes, abilities and modifiers, act through the user command, trace the world, react to game events and talk to the game's UI and network.

This repository is the documentation, the editor type definitions, and a set of example scripts.

## Quick start

1. Put a `.lua` file in `C:\VITTLOCK\scripts\v2\`.
2. Start the game. Scripts load automatically, after every map change, and from **Reload** in the menu's **Lua** tab.

```lua
-- C:\VITTLOCK\scripts\v2\hello.lua
local group   = Menu.Create("Hello", "", "", "", "Main")
local enabled = group:Switch("Enabled", true)
local color   = group:ColorPicker("Text color", Color(255, 255, 255))

callback.on_draw:set(function()
    if not enabled:Get() then return end
    local me = entity_list.local_pawn()
    if not me then return end
    Render.Text(0, 18, ("Health: %d"):format(me.m_iHealth), Vec2(20, 200), color:Get())
end)
```

Read [Getting started](docs/getting-started.md) next: it explains this script line by line, sets up autocomplete in VS Code, and covers the rules every script follows.

## Reference

| Page | What's in it |
|---|---|
| [Getting started](docs/getting-started.md) | First script, editor setup, how scripts load and run. |
| [Callbacks](docs/callbacks.md) | `callback.*` events, their arguments and return values, `require`, load order. |
| [Menu](docs/menu.md) | `Menu` and every widget: tabs, groups, switches, sliders, binds, colour pickers, combos. |
| [Render](docs/render.md) | `Render.*`: shapes, text, fonts, images, SVG icons, blur, render targets, notifications. |
| [Types](docs/types.md) | `Vector`, `Angle`, `Vec2`, `Color`, and the `table` / `math` helpers. |
| [Enums](docs/enums.md) | `Enum.*` and the game enums (`EModifierState`, `InputBitMask_t`, ...). |
| [Entities](docs/entities.md) | `entity_list`, `entity`, `player_pawn`, `ability`, `modifier`, reading networked fields. |
| [User command](docs/usercmd.md) | `CUserCmd`: buttons, movement, camera, aim. |
| [Input](docs/input.md) | `input`: keys, mouse, cursor. |
| [Trace](docs/trace.md) | `trace`: line, hull and bullet traces. |
| [Utils](docs/utils.md) | `utils`: camera, ability data, hero helpers and more. |
| [Core](docs/core.md) | `global_vars`, `game_rules`, `net_channel`, `convar`, `chronos`, JSON. |
| [Storage](docs/storage.md) | `db` (saved to disk) and `global_ctx` (shared for the session). |
| [Targeting](docs/targeting.md) | `TargetSelection`, `hitscan`, `backtrack`. |
| [Game data](docs/gamedata.md) | `map_info` (camps, sinners, powerups, mid-boss, rifts, urn), `player_stats`, `meta`, localization, `sound`. |
| [Panorama](docs/panorama.md) | `panorama` and `uipanel`: find, create and change the game's own UI. |
| [Network](docs/network.md) | `http`, `protobuf`, `net_channel.send_net_message`, `gc`. |
| [HERO_LIB](docs/hero-lib.md) | The built-in hero helper library: status checks, abilities, casting, target selection, prediction, spirit damage, menu builders. |

## Autocomplete

The [`library/`](library) folder describes every function for the Lua language server. With VS Code and the **Lua** extension (sumneko), copy [`.luarc.json`](.luarc.json) into your scripts folder and point `workspace.library` at this repo's `library` folder. See [Getting started](docs/getting-started.md#3-editor-setup-autocomplete).

## Examples

The [`examples/`](examples) folder has complete scripts. Copy one into `C:\VITTLOCK\scripts\v2\` to try it. See [examples/README.md](examples/README.md) for the list.

## License

[MIT](LICENSE)
