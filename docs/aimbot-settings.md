# Native Aimbot Settings

Native controls rendered by `CAimbot::RenderMenu` are not Lua widgets. `Menu.Find` and `UI.Find` only search widgets created through `ui.script()` or `UI.Add*`, so IDs such as `##Psilent.Fov` are deliberately not searchable.

Use the stable `aimbot` module instead:

```lua
local current = aimbot.get("psilent_fov")
local changed = aimbot.set("psilent_fov", 170)

if not changed then
    log.error("failed to set psilent_fov")
end
```

`aimbot.get(name)` returns the setting's natural Lua type or `nil` for an unknown key. `aimbot.set(name, value)` returns `true` on success and `false` for an unknown key, unavailable feature, or wrong value type. Numeric values are clamped to the same ranges used by config loading and the native menu.

## Supported Keys

| Key | Type | Range / values |
|---|---|---|
| `active` | boolean | |
| `mode` | integer | `0` Normal, `2` Hybrid |
| `aim_key` | integer | Win32 VK `0..254` |
| `sensitivity_x` | number | `1..30` |
| `sensitivity_y` | number | `1..30` |
| `inertia_scale` | number | `0..2` |
| `drift_scale` | number | `0..2` |
| `feed_forward_scale` | number | `0..1` |
| `fov` | number | `10..500` |
| `show_fov` | boolean | |
| `fov_color` | table | `{r,g,b}`, each `0..1` |
| `show_target` | boolean | |
| `show_target_color` | table | `{r,g,b}`, each `0..1` |
| `bones_mask` | integer | `0..31` |
| `anti_frog` | boolean | |
| `hs_threshold` | number | `0..100` |
| `psilent_active` | boolean | |
| `psilent_key` | integer | Win32 VK `0..255` |
| `psilent_fov` | number | `10..500` |
| `psilent_closest_bone` | boolean | |

`aimbot.keys()` returns these names as an array. Dedicated helpers are also available for the most common integration:

```lua
local fov = aimbot.get_psilent_fov()
aimbot.set_psilent_fov(170) -- returns boolean; clamps to 10..500
```

## pSilent FOV Override

```lua
local menu = ui.script()
menu:category("Aimbot Scripts")

local enabled = menu:switch("Override pSilent FOV", false)
local target = menu:slider_float("Target pSilent FOV", 10, 500, 170)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    aimbot.set("psilent_fov", target:get_float())
end)
```

Do not write the setting every frame unless the value can change every frame. A cached comparison avoids redundant writes:

```lua
local last = nil
callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    local wanted = target:get_float()
    if wanted ~= last and aimbot.set("psilent_fov", wanted) then
        last = wanted
    end
end)
```

Native setting changes participate in normal VITTLOCK config save because the module writes the same `CAimbot` fields used by `CAimbot::Save`.
