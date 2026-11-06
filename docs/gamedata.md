# Game data

Read-only information about the match and the game: world objectives and their timers (`map_info`), the game's Mid-Boss panel (`midboss`), per-player gun accuracy (`player_stats`), hero win and pick rates (`meta`), string tables (`Localizer`, `GameLocalizer`) and sound event hashes (`sound`). Use these for timers, overlays and HUD panels instead of scanning entities yourself.

- [map_info](#map_info)
- [midboss](#midboss)
- [player_stats](#player_stats)
- [meta](#meta)
- [Localizer](#localizer)
- [GameLocalizer](#gamelocalizer)
- [sound](#sound)

## map_info

A tracker of the map's objectives: neutral camps, sinners, powerups, the mid boss, the rift, the urn and its delivery points, the bell, breakables, plus static map data (districts, hotel).

How it works:

- The tracker updates about every 0.25 s, and right away after entities are added or removed. Every function returns a **fresh plain Lua table** built from the last update: change it freely, it is yours. There are no methods; `Vector` values are the only userdata inside.
- All times (`*_at`, `sampled_at`) are **match-clock seconds**: seconds since the match started.
- Fields documented as "or nil" are absent from the table when the value is unknown.
- Handles (`handle`, `active_handle`, `carrier_handle`) are raw entity handle integers. Look them up with the entity functions on the [entities](entities.md) page.
- Check `map_info.map().supported` first: without a known map there is little or no data.

### Header fields

Most tables start with these fields:

| Field | Type | Description |
|---|---|---|
| `generation` | integer | Changes when the tracker resets (map change, disconnect). |
| `revision` | integer | A change counter. `map()` carries the global one, which grows whenever any part changed. Every other function carries its own, which grows only when that part's data changed. A reset bumps them all. |
| `sampled_at` | number | Match time of the last update. |

`districts()` has only `generation`; `district()` and `hotel()` have none of them.

To avoid rebuilding tables every frame, poll `map()` and re-read a list only when `generation` or its `revision` changed (see the [example](#example-camp-timers)).

### Spawn windows

`next_spawn`, `next_early_warning`, `next_warning`, `next_open` and `initial_spawn` are either `nil` (unknown) or a window table:

| Field | Type | Description |
|---|---|---|
| `earliest_at` | number | Earliest match time the event can happen. |
| `latest_at` | number | Latest match time the event can happen. |
| `earliest_in` | number | `earliest_at - sampled_at`, never below 0. |
| `latest_in` | number | `latest_at - sampled_at`, never below 0. |
| `exact` | boolean | `true` when `earliest_at == latest_at`. |

The `_in` values are measured from the update time (`sampled_at`), not from the moment you call. For a smooth countdown, subtract the live match time from `earliest_at` yourself.

### Enum tables

All values are integers.

| Table | Values |
|---|---|
| `map_info.CampKind` | `SMALL` 34, `MEDIUM` 35, `LARGE` 36, `SINNER` 37 |
| `map_info.CampState` | `UNKNOWN` 0, `WAITING_INITIAL` 1, `ALIVE` 2, `DEAD` 3 |
| `map_info.PowerupState` | `UNKNOWN` 0, `DISABLED` 1, `WAITING` 2, `ACTIVE` 3 |
| `map_info.PowerupKind` | `UNKNOWN` 0, `GUN` 1, `MOVEMENT` 2, `SURVIVAL` 3, `CASTING` 4 |
| `map_info.PowerupSpawnerKind` | `STANDARD` 0, `REFRESH` 1, `CHANGE_TEAM` 2 |
| `map_info.MidbossState` | `UNKNOWN` 0, `WAITING` 1, `ALIVE` 2, `DEAD` 3 |
| `map_info.RiftPhase` | `UNKNOWN` 0, `WAITING` 1, `EARLY_WARNING` 2, `WARNING` 3, `SPAWN_WINDOW` 4, `ACTIVE` 5, `SCORING` 6, `COOLDOWN` 7 |
| `map_info.RiftLane` | `UNKNOWN` 0, `YELLOW` 1, `GREEN` 2 |
| `map_info.UrnState` | `UNKNOWN` 0, `UNAVAILABLE` 1, `ON_GROUND` 2, `CARRIED` 3, `DROPPED` 4, `RETURNING` 5 |
| `map_info.BreakableSpawnState` | `UNKNOWN` 0, `WAITING_INITIAL` 1, `SPAWNED` 2 |

### `map_info.map()`

Returns a table, always. Header fields (with the global `revision`) plus:

| Field | Type | Description |
|---|---|---|
| `name` | string | The map's profile name (for example `"dl_midtown"`), `""` when the map is not supported. |
| `supported` | boolean | `true` when the map is known. Without it, expect little or no data from the other functions. |
| `objectives_enabled` | boolean | `false` in modes without objectives. |

### `map_info.districts()`

Returns `{ generation = <integer>, items = { <district>, ... } }`, always. `items` is empty on an unsupported map. Each district:

| Field | Type | Description |
|---|---|---|
| `id` | integer | 1-based index. |
| `district` | string | District name. |
| `building` | string | Building name, `""` for some districts. |

### `map_info.district(index)`

Returns the district with that 1-based index (same table as in `districts().items`), or `nil` when `index` is out of range. `index` must be an integer: `district(1.5)`, `district("1")` and `district()` raise an error.

### `map_info.hotel()`

Returns `{ start_position = <Vector>, exit_position = <Vector> }`, or `nil` when the map has no hotel. No header fields.

### `map_info.bell()`

Returns `nil` when the map has no bell. Otherwise header fields plus:

| Field | Type | Description |
|---|---|---|
| `position` | Vector | Bell position. |
| `last_ring_at` | number or nil | Match time of the last ring. |
| `ready_at` | number or nil | Match time the bell can ring again (30 s after a ring). |
| `ready_in` | number or nil | Seconds until `ready_at` on the **live** match clock, never below 0. `nil` when `ready_at` is nil. |

### `map_info.camps()`

Returns header fields plus `items`, an array of camps, always.

| Field | Type | Description |
|---|---|---|
| `id` | string | Camp name. |
| `position` | Vector | Camp position. |
| `kind` | integer | `map_info.CampKind`. |
| `state` | integer | `map_info.CampState`. |
| `minimap_x`, `minimap_y` | integer | Camp position on the minimap grid (0-255). |
| `visible` | boolean | The camp is currently visible to your team. |
| `initialized` | boolean | The camp has been seen at least once, so `state` is based on observation. |
| `next_spawn` | window or nil | Next spawn window. |
| `initial_spawn_delay` | number | First spawn time in seconds. |
| `default_initial_spawn_delay` | number | The game's default first spawn time. |
| `respawn_interval` | integer | Respawn interval in seconds. |
| `live_state_only` | boolean | The camp has no spawn timer: its state comes only from its live unit. |
| `max_health` | integer | Total health of the camp's units. |
| `current_max_health` | integer | Current total max health of the live units. |
| `current_health` | integer | Current total health of the live units. |
| `live_units_observed` | boolean | The camp's units are currently being observed. |
| `has_missing_health` | boolean | Some of the camp's health is missing (it has been damaged). |
| `last_damage_at` | number or nil | Match time the camp was last damaged. |
| `damage_wave_started_at` | number or nil | Match time the current round of damage started. |
| `soul_value` | integer | Estimated souls for clearing the camp: from the live units while they are observed, otherwise from the unit list scaled by match minutes. Never nil. |
| `units` | array | The camp's units (below). |

Each unit:

| Field | Type | Description |
|---|---|---|
| `kind` | string | `"weak"`, `"normal"`, `"strong"` or `"sinner"`. |
| `max_health` | integer | Base max health. |
| `base_soul_value` | number | Souls at minute 0. |
| `soul_value_per_minute` | number | Souls added per match minute. |

### `map_info.sinners()`

Returns header fields plus `items`, an array of sinners, always. The jackpot fields are computed from the **live** match clock at call time.

| Field | Type | Description |
|---|---|---|
| `handle` | integer | Entity handle. |
| `camp_id` | string or nil | `id` of the camp it belongs to. |
| `position` | Vector | Position. |
| `health`, `max_health` | integer | Health. |
| `alive` | boolean | Alive. |
| `visible` | boolean | Visible to your team. |
| `jackpot_valid` | boolean | The jackpot timing is known. |
| `jackpot_active` | boolean | Valid, and the sinner's jackpot game is running. |
| `jackpot_fast` | boolean | Valid, and the cycle runs faster than normal. |
| `jackpot_in_window` | boolean | Active, and the jackpot window is open right now. |
| `jackpot_phase` | number | Seconds into the current cycle (0 when not valid). |
| `jackpot_loop` | number | Cycle length in seconds (0 when not valid). |
| `jackpot_window` | number | Length of the jackpot window at the start of each cycle, in seconds (0 when not valid). |

### `map_info.powerups()`

Returns header fields plus `items`, an array of powerup spawners, always.

| Field | Type | Description |
|---|---|---|
| `id` | integer | 1-based id. |
| `position` | Vector | Spawner position. |
| `state` | integer | `map_info.PowerupState`. |
| `enabled` | boolean or nil | Whether the spawner is enabled. |
| `kind` | integer | `map_info.PowerupKind`. |
| `spawner_kind` | integer | `map_info.PowerupSpawnerKind`. |
| `active_handle` | integer or nil | Handle of the spawned powerup. |
| `active_position` | Vector or nil | Position of the spawned powerup. |
| `next_spawn` | window or nil | Next spawn window. |
| `initial_spawn_delay` | number | First spawn time in seconds. |
| `default_initial_spawn_delay` | number | The game's default first spawn time. |
| `respawn_interval` | number | Respawn interval in seconds in effect. |
| `default_respawn_interval` | number | The game's default respawn interval. |

### `map_info.midboss()`

Returns `nil` when the map has no mid boss. Otherwise header fields plus:

| Field | Type | Description |
|---|---|---|
| `position` | Vector | Position. |
| `state` | integer | `map_info.MidbossState`. |
| `health` | integer or nil | Current health. |
| `max_health` | integer or nil | Max health. |
| `health_fraction` | number or nil | Health from 0 to 1. |
| `next_spawn` | window or nil | Next spawn window. |

### `map_info.rifts()`

Returns a single table (not a list), always: header fields plus the fields below. Location ids are 1-based indexes into `locations`.

| Field | Type | Description |
|---|---|---|
| `phase` | integer | `map_info.RiftPhase`. |
| `enabled` | boolean or nil | Whether the rift is enabled. |
| `active_location_id` | integer or nil | Location of the open rift. |
| `warning_location_id` | integer or nil | Location announced by the warning. |
| `last_spawn_at` | number or nil | Match time of the last spawn. |
| `next_early_warning` | window or nil | Next early warning. |
| `next_warning` | window or nil | Next warning. |
| `next_open` | window or nil | Next opening. |
| `initial_delay` | number or nil | First spawn delay in seconds. |
| `respawn_interval` | number or nil | Respawn interval in seconds. |
| `spawn_variance` | number or nil | Spawn time variance in seconds. |
| `early_warning_time` | number or nil | Early warning lead time in seconds. |
| `warning_time` | number or nil | Warning lead time in seconds. |
| `next_cycle` | integer or nil | Number of the next cycle. |
| `scoring_team` | integer or nil | Team currently scoring. |
| `capture_timeout_started_at` | number or nil | Match time the capture timeout started. |
| `expires_at` | number or nil | Match time the rift expires. |
| `expire_warning_at` | number or nil | Match time of the expiry warning. |
| `capture_timeout_duration` | number or nil | Seconds. |
| `expire_warning_duration` | number or nil | Seconds. |
| `capture_duration` | number or nil | Seconds. |
| `favored_capture_duration` | number or nil | Seconds. |
| `unfavored_capture_duration` | number or nil | Seconds. |
| `capture_progress` | number or nil | Capture progress. |
| `capture_progress_owner` | integer or nil | Team that owns the capture progress. |
| `actively_capturing_team` | integer or nil | Team capturing right now. |
| `active_capturers` | integer or nil | Number of players capturing. |
| `locations` | array | `{ id = <integer>, position = <Vector>, lane = <map_info.RiftLane> }` per location. |

### `map_info.urn()`

Returns `nil` when the map has no urn. Otherwise header fields plus the fields below. Location ids are 1-based.

| Field | Type | Description |
|---|---|---|
| `state` | integer | `map_info.UrnState`. |
| `position` | Vector or nil | Read **live** at call time: the carrier's position while `CARRIED` or `RETURNING`, the urn's while `ON_GROUND` or `DROPPED`, otherwise `nil`. |
| `handle` | integer or nil | Handle of the urn entity. |
| `carrier_handle` | integer or nil | Handle of the carrier. |
| `carrier_team` | integer or nil | Carrier's team. |
| `last_transition_at` | number or nil | Match time of the last state change. |
| `next_spawn` | window or nil | Next spawn window. |
| `respawn_interval` | number or nil | Seconds. |
| `next_spawn_cycle` | integer or nil | Number of the next spawn cycle. |
| `spawn_location_id` | integer or nil | Spawn location. |
| `dropoff_location_id` | integer or nil | Drop-off location. |
| `auto_walk_wait_duration`, `auto_walk_starts_at`, `auto_walk_duration`, `scheduled_relocation_at` | number or nil | Auto-walk timing (durations in seconds, `_at` in match time). |
| `auto_walking` | boolean or nil | The urn is walking on its own. |
| `auto_walk_speed` | number or nil | Auto-walk speed. |
| `ground_lifetime_duration`, `ground_decay_delay`, `ground_decay_duration` | number or nil | Ground timing in seconds. |
| `ground_started_at`, `ground_decay_starts_at`, `ground_expires_at` | number or nil | Ground timing in match time. |
| `held_lifetime_duration` | number or nil | Seconds. |
| `held_started_at`, `held_expires_at` | number or nil | Match time. |
| `held_time` | number or nil | Seconds held. |
| `reveal_after`, `damage_after`, `instant_return_after` | number or nil | Carrier timing thresholds in seconds. |
| `damage_tick_interval` | number or nil | Seconds. |
| `damage_max_health_fraction` | number or nil | Fraction of max health. |
| `juggle_time_add` | number or nil | Seconds. |
| `held_time_radius` | number or nil | Radius. |

### `map_info.urn_deliveries()`

Returns header fields plus `items`, always. Each item: `{ id = <integer, 1-based>, position = <Vector>, team = <integer>, active = <boolean> }`.

### `map_info.breakables()`

Returns a single table, always: header fields plus:

| Field | Type | Description |
|---|---|---|
| `state` | integer | `map_info.BreakableSpawnState`. |
| `initial_spawn` | window or nil | First spawn window. |
| `initial_override` | number or nil | Overridden first spawn time, when set. |
| `spawn_spread` | number or nil | Spawn time spread in seconds. |

### Example: camp timers

```lua
local MI = map_info
local cache = { gen = -1, rev = -1, camps = {} }

callback.on_frame:set(function()
    local m = MI.map()
    if not m.supported then return end
    local c = MI.camps()
    if c.generation == cache.gen and c.revision == cache.rev then return end
    cache.gen, cache.rev = c.generation, c.revision
    cache.camps = {}
    for _, camp in ipairs(c.items) do
        if camp.kind ~= MI.CampKind.SINNER and camp.state == MI.CampState.DEAD and camp.next_spawn then
            cache.camps[#cache.camps + 1] = { id = camp.id, at = camp.next_spawn.earliest_at, souls = camp.soul_value }
        end
    end
    for _, e in ipairs(cache.camps) do
        print(("%s respawns at %.0f s (%d souls)"):format(e.id, e.at, e.souls))
    end
end)
```

## midboss

Controls the game's own Mid-Boss objective panel (the one in the game's HUD).

### `midboss.panel_mode`

A table of mode values, not functions:

| Key | Value | Effect |
|---|---|---|
| `game_default` | 0 | The game decides when to show the panel. |
| `show` | 1 | The panel is always shown. |
| `hide` | 2 | The panel is always hidden. |

### `midboss.set_panel_mode(mode)`

Sets the panel mode. Values outside 0-2 are ignored. `mode` must be an integer: `set_panel_mode(0.5)` or `set_panel_mode("1")` raises an error. Returns nothing.

The mode is shared by all scripts and lasts until scripts reload. While a script has set one, it takes priority over the menu's own Mid-Boss panel setting (even `game_default`). There is no getter.

```lua
-- Hide the game's Mid-Boss panel while this script is loaded.
midboss.set_panel_mode(midboss.panel_mode.hide)
```

## player_stats

Per-player gun accuracy for the current match. Every gun shot a hero fires is held as pending until a damage event from that player resolves it (a hit) or its time runs out (a miss, after the bullet's flight time plus your latency, at most a few seconds). Records are cleared when you join or leave a match, and with `reset()`.

### `player_stats.all()`

Returns an array of records, one per player seen shooting or dealing damage, in no particular order (sort them yourself, e.g. by `team` then `player_slot`). Each record is a plain table:

| Field | Type | Description |
|---|---|---|
| `steam_id` | string | Steam id as decimal digits, `""` when unknown. |
| `name` | string | Player name. |
| `hero_name` | string | Hero code name, e.g. `"hero_inferno"`. |
| `hero_id` | integer | Hero id, `-1` until a hero was seen. |
| `team` | integer | Team number. |
| `player_slot` | integer | Player slot (0-based). |
| `is_local` | boolean | `true` for you. |
| `beam_weapon` | boolean | `true` when the player's gun is a beam weapon. |
| `shots` | integer | Resolved shots (hits + misses). Pending shots are not counted yet. |
| `hits` | integer | Shots that damaged a hero. |
| `misses` | integer | Shots that ran out of time. |
| `headshots` | integer | Hits on the head. |
| `damage_total` | integer | Damage dealt to heroes. |
| `discarded` | integer | Shots whose damage went to something other than a hero (not counted as shots). |
| `orphans` | integer | Damage events that had no pending shot to match. |
| `pending` | integer | Shots still waiting to resolve. |
| `accuracy` | number | `100 * hits / shots`, 0 with no shots. |
| `headshot_percentage` | number | `100 * headshots / hits`, 0 with no hits. |
| `entity` | entity or absent | The player's pawn. The key is missing when it can't be resolved. |

### `player_stats.diagnostics()`

Returns a table of integer counters over all players, useful when the numbers look wrong:

| Field | Counts |
|---|---|
| `fire_seen` | Bullet fire events seen. |
| `fire_not_gun` | Fire events not from a gun (ignored). |
| `fire_no_shooter` | Gun fire events whose shooter isn't a hero (ignored). |
| `flash_seen` | Damage events seen. |
| `flash_zero_value` | Damage events with zero damage (ignored). |
| `flash_wrong_type` | Damage events of a type that isn't counted (ignored). |
| `flash_no_attacker` | Damage events whose attacker isn't a hero (ignored). |
| `flash_remote_pair` | Damage events where neither attacker nor victim is you (still counted). |
| `discarded` | Total of all records' `discarded`. |
| `orphans` | Total of all records' `orphans`. |

### `player_stats.reset()`

Clears every record and every diagnostics counter.

```lua
local next_print = 0

callback.on_frame:set(function()
    local now = global_vars.curtime()
    if now < next_print then return end
    next_print = now + 10
    for _, r in ipairs(player_stats.all()) do
        if r.is_local then
            print(("accuracy %.1f%% (%d/%d), headshots %.1f%%, damage %d"):format(
                r.accuracy, r.hits, r.shots, r.headshot_percentage, r.damage_total))
        end
    end
end)
```

## meta

Hero win and pick rates from recent public matches, per rank bracket and time period. Data is downloaded in the background the first time a selection is asked for, refreshed after an hour, and retried a minute after a failure.

Period keys:

| Key | Period |
|---|---|
| `"7d"` | Last 7 days |
| `"14d"` | Last 14 days |
| `"1m"` | Last 30 days |

Bracket keys, highest first: `"eternus"`, `"ascendant-plus"`, `"ascendant"`, `"phantom-plus"`, `"phantom"`, `"oracle-plus"`, `"oracle"`, `"archon-plus"`, `"archon"`, `"emissary-plus"`, `"emissary"`, `"ritualist-plus"`, `"ritualist"`, `"arcanist"`, `"alchemist"`, `"seeker"`, `"initiate"`. A `-plus` key means that rank and above; a plain key means that rank only. Keys are case-sensitive.

### `meta.get(period, bracket)`

Returns an array of hero rows for that selection:

| Field | Type | Description |
|---|---|---|
| `hero_id` | integer | Hero id. |
| `hero_name` | string | Display name, e.g. `"Lady Geist"`. |
| `winrate` | number | Win rate in percent. |
| `pickrate` | number | Percent of matches the hero appears in. |

Errors (raised as Lua errors, so use `pcall`):

- An unknown period or bracket: `failed to find specified bracket`.
- Data not ready: `data is not ready, current status: <status>`, where status is `Idle`, `Updating` or `Failed`. The first call starts the download, so expect this error until it finishes. It is raised again while the hourly refresh runs.

The selection asked for becomes the one `meta.ready()` and `meta.failed()` report on.

### `meta.ready()`

Returns `true` when the selection last asked for with `meta.get` has data. Before any `get` call, it reports on the selection chosen in the menu's Meta Tracker settings.

### `meta.failed()`

Returns `true` when that selection's last download failed. While downloading, both `ready()` and `failed()` are `false`.

```lua
local rows = nil
local next_try = 0

callback.on_frame:set(function()
    if rows then return end
    local now = global_vars.curtime()
    if now < next_try then return end
    next_try = now + 2
    local ok, res = pcall(meta.get, "7d", "eternus")
    if not ok then return end   -- not ready yet; try again in 2 s
    rows = res
    table.sort(rows, function(a, b) return a.winrate > b.winrate end)
    for i = 1, math.min(5, #rows) do
        print(("%d. %s  W %.1f%%  P %.1f%%"):format(i, rows[i].hero_name, rows[i].winrate, rows[i].pickrate))
    end
end)
```

## Localizer

A string table for your own translations. It is shared by all scripts and kept across script reloads for the whole session. Tokens are any strings you choose, typically the English text itself.

### `Localizer.Get(token)`

Returns the text stored for `token`, or `token` itself when nothing is stored. Never `nil`.

### `Localizer.RegToken(token)`

Stores `token` as its own text, only when nothing is stored for it yet. Returns nothing.

### `Localizer.SetToken(token, value)`

Stores `value` for `token`, replacing any previous text. Returns nothing.

| Name | Type | Description |
|---|---|---|
| token | string | The key. |
| value | string | The text to return from `Get`. |

```lua
Localizer.SetToken("Enemy in pit", "Gegner in der Grube")
print(Localizer.Get("Enemy in pit"))   -- Gegner in der Grube
print(Localizer.Get("Unknown text"))   -- Unknown text
```

## GameLocalizer

### `GameLocalizer.Find(token)`

Returns the game's own localized string for a token (for example a hero, item or ability name). The token is passed to the game unchanged. Never `nil`: `""` when the game returns nothing. For an unknown token the game typically returns the token text itself, so a result equal to the token means "not found".

```lua
local text = GameLocalizer.Find("upgrade_clip_size")
if text ~= "" and text ~= "upgrade_clip_size" then
    print("item name: " .. text)
end
```

## sound

Converts between sound event names and the hashes the game uses for them.

### `sound.hash(name)`

Returns the integer hash of a sound event name. Any string can be hashed, registered or not; `""` gives `0xFFFFFFFF`. Returns `nil` only when the sound system is unavailable.

### `sound.name(hash)`

Returns the registered sound event name for a hash, or `nil` when the hash is unknown or the sound system is unavailable.

### `sound.is_valid_hash(hash)`

Returns `true` when the hash belongs to a registered sound event, `false` otherwise (also when the sound system is unavailable).

```lua
local ring = sound.hash("ChinatownBell.Ring")
if ring and sound.is_valid_hash(ring) then
    print(("bell ring hash: %d, name back: %s"):format(ring, sound.name(ring)))
end
```
