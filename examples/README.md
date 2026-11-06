# Examples

Complete scripts you can copy into `C:\VITTLOCK\scripts\v2\` and change. Each one adds its own page under **Examples** in the menu's **Lua** tab and starts with a comment listing the API it shows.

| File | What it does | Shows |
|---|---|---|
| [01-hello.lua](01-hello.lua) | Draws your health on screen. | Menu basics, `on_draw`, `Render.Text`, reading a field |
| [02-enemy-esp.lua](02-enemy-esp.lua) | Boxes, health bars and distance on enemy heroes. | Gathering in `on_frame`, drawing in `on_draw`, `WorldToScreen`, bones |
| [03-ability-cooldowns.lua](03-ability-cooldowns.lua) | Your four abilities and their cooldowns under the crosshair. | Abilities by slot, fonts |
| [04-rapid-fire-key.lua](04-rapid-fire-key.lua) | Taps fire repeatedly while a key is held. | `Bind`, `on_createmove`, `cmd:pulse` |
| [05-visible-enemies.lua](05-visible-enemies.lua) | Marks enemies whose head you can see. | `trace.line`, line of sight, throttling |
| [06-camp-timers.lua](06-camp-timers.lua) | Respawn countdowns over neutral camps. | `map_info`, built-in SVG icons, images |
| [07-status-alerts.lua](07-status-alerts.lua) | A notification when you get stunned, silenced or immobilized. | Modifier states, `Notification`, `on_add_modifier` |
| [08-accuracy-tracker.lua](08-accuracy-tracker.lua) | Shots, hits, accuracy, and your best accuracy ever. | `player_stats`, the persistent `db`, buttons |
| [09-http-json.lua](09-http-json.lua) | Fetches data from a web API and shows it in the menu. | `http`, JSON, labels |
| [10-panorama-label.lua](10-panorama-label.lua) | Adds a label to the game's own HUD. | `panorama`, `uipanel`, panel lifetime |
| [11-modules.lua](11-modules.lua) + [lib/example_draw.lua](lib/example_draw.lua) | Health and souls panel built from a helper module. | `require`, the `lib\` folder |
| [12-parry-warning.lua](12-parry-warning.lua) | Warns when an enemy in front of you is parrying. | Enemy modifier states, facing checks |

## Tips

- Load fonts and images at the top of the script, never inside a callback.
- Read game state in `on_frame` (or the createmove callbacks), store plain values, and only draw them in `on_draw`.
- Always handle `entity_list.local_pawn()` being `nil`: it is, in the main menu and while a map loads.
- `print` and errors go to your script's log in the menu's **Lua** tab.
- Put shared code in `scripts\v2\lib\` and `require` it; files there don't run as scripts on their own.
