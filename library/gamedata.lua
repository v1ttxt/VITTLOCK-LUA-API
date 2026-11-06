---@meta
-- Game data: map_info, midboss, player_stats, meta, Localizer, GameLocalizer, sound.

-- ── map_info: shared shapes ──────────────────────────────────────────────────

---A spawn window. Times are match-clock seconds; the `_in` values are measured from the table's `sampled_at`.
---@class MapInfoWindow
---@field earliest_at number Earliest match time the event can happen.
---@field latest_at number Latest match time the event can happen.
---@field earliest_in number Seconds until `earliest_at` (0 when passed).
---@field latest_in number Seconds until `latest_at` (0 when passed).
---@field exact boolean True when `earliest_at == latest_at`.

---Header fields shared by most map_info tables.
---@class MapInfoHeader
---@field generation integer Changes on every reset (map change, disconnect).
---@field revision integer Change counter: grows only when this data changed.
---@field sampled_at number Match time of the last update (seconds).

-- ── map_info: return tables ──────────────────────────────────────────────────

---@class MapInfoMap: MapInfoHeader
---@field name string Map profile name, "" when the map is not supported.
---@field supported boolean True when the map is known.
---@field objectives_enabled boolean False in modes without objectives.

---@class MapInfoDistrict
---@field id integer 1-based index.
---@field district string District name.
---@field building string Building name, may be "".

---@class MapInfoDistricts
---@field generation integer
---@field items MapInfoDistrict[]

---@class MapInfoHotel
---@field start_position Vector
---@field exit_position Vector

---@class MapInfoBell: MapInfoHeader
---@field position Vector
---@field last_ring_at number|nil Match time of the last ring.
---@field ready_at number|nil Match time the bell can ring again.
---@field ready_in number|nil Seconds until `ready_at` (live clock, 0 when passed); nil when `ready_at` is nil.

---@class MapInfoCampUnit
---@field kind string "weak", "normal", "strong" or "sinner".
---@field max_health integer
---@field base_soul_value number
---@field soul_value_per_minute number

---@class MapInfoCamp
---@field id string Camp name.
---@field position Vector
---@field kind integer map_info.CampKind
---@field state integer map_info.CampState
---@field minimap_x integer
---@field minimap_y integer
---@field visible boolean
---@field initialized boolean
---@field next_spawn MapInfoWindow|nil
---@field initial_spawn_delay number
---@field default_initial_spawn_delay number
---@field respawn_interval integer Seconds.
---@field live_state_only boolean
---@field max_health integer Sum of the camp's units.
---@field current_max_health integer
---@field current_health integer
---@field live_units_observed boolean
---@field has_missing_health boolean
---@field last_damage_at number|nil
---@field damage_wave_started_at number|nil
---@field soul_value integer Estimated souls for clearing the camp.
---@field units MapInfoCampUnit[]

---@class MapInfoCamps: MapInfoHeader
---@field items MapInfoCamp[]

---@class MapInfoSinner
---@field handle integer Entity handle.
---@field camp_id string|nil Id of the camp it belongs to.
---@field position Vector
---@field health integer
---@field max_health integer
---@field alive boolean
---@field visible boolean
---@field jackpot_valid boolean
---@field jackpot_active boolean
---@field jackpot_fast boolean
---@field jackpot_in_window boolean
---@field jackpot_phase number Seconds into the current loop (0 when not valid).
---@field jackpot_loop number Loop length in seconds (0 when not valid).
---@field jackpot_window number Jackpot window length in seconds (0 when not valid).

---@class MapInfoSinners: MapInfoHeader
---@field items MapInfoSinner[]

---@class MapInfoPowerup
---@field id integer 1-based.
---@field position Vector
---@field state integer map_info.PowerupState
---@field enabled boolean|nil
---@field kind integer map_info.PowerupKind
---@field spawner_kind integer map_info.PowerupSpawnerKind
---@field active_handle integer|nil Handle of the spawned powerup.
---@field active_position Vector|nil
---@field next_spawn MapInfoWindow|nil
---@field initial_spawn_delay number
---@field default_initial_spawn_delay number
---@field respawn_interval number
---@field default_respawn_interval number

---@class MapInfoPowerups: MapInfoHeader
---@field items MapInfoPowerup[]

---@class MapInfoMidboss: MapInfoHeader
---@field position Vector
---@field state integer map_info.MidbossState
---@field health integer|nil
---@field max_health integer|nil
---@field health_fraction number|nil 0 to 1.
---@field next_spawn MapInfoWindow|nil

---@class MapInfoRiftLocation
---@field id integer 1-based.
---@field position Vector
---@field lane integer map_info.RiftLane

---@class MapInfoRifts: MapInfoHeader
---@field phase integer map_info.RiftPhase
---@field enabled boolean|nil
---@field active_location_id integer|nil
---@field warning_location_id integer|nil
---@field last_spawn_at number|nil
---@field next_early_warning MapInfoWindow|nil
---@field next_warning MapInfoWindow|nil
---@field next_open MapInfoWindow|nil
---@field initial_delay number|nil
---@field respawn_interval number|nil
---@field spawn_variance number|nil
---@field early_warning_time number|nil
---@field warning_time number|nil
---@field next_cycle integer|nil
---@field scoring_team integer|nil
---@field capture_timeout_started_at number|nil
---@field expires_at number|nil
---@field expire_warning_at number|nil
---@field capture_timeout_duration number|nil
---@field expire_warning_duration number|nil
---@field capture_duration number|nil
---@field favored_capture_duration number|nil
---@field unfavored_capture_duration number|nil
---@field capture_progress number|nil
---@field capture_progress_owner integer|nil
---@field actively_capturing_team integer|nil
---@field active_capturers integer|nil
---@field locations MapInfoRiftLocation[]

---@class MapInfoUrn: MapInfoHeader
---@field state integer map_info.UrnState
---@field position Vector|nil Live position of the carrier or the urn; nil in other states.
---@field handle integer|nil
---@field carrier_handle integer|nil
---@field carrier_team integer|nil
---@field last_transition_at number|nil
---@field next_spawn MapInfoWindow|nil
---@field respawn_interval number|nil
---@field next_spawn_cycle integer|nil
---@field spawn_location_id integer|nil
---@field dropoff_location_id integer|nil
---@field auto_walk_wait_duration number|nil
---@field auto_walk_starts_at number|nil
---@field auto_walk_duration number|nil
---@field scheduled_relocation_at number|nil
---@field auto_walking boolean|nil
---@field auto_walk_speed number|nil
---@field ground_lifetime_duration number|nil
---@field ground_decay_delay number|nil
---@field ground_decay_duration number|nil
---@field ground_started_at number|nil
---@field ground_decay_starts_at number|nil
---@field ground_expires_at number|nil
---@field held_lifetime_duration number|nil
---@field held_started_at number|nil
---@field held_expires_at number|nil
---@field held_time number|nil
---@field reveal_after number|nil
---@field damage_after number|nil
---@field instant_return_after number|nil
---@field damage_tick_interval number|nil
---@field damage_max_health_fraction number|nil
---@field juggle_time_add number|nil
---@field held_time_radius number|nil

---@class MapInfoUrnDelivery
---@field id integer 1-based.
---@field position Vector
---@field team integer
---@field active boolean

---@class MapInfoUrnDeliveries: MapInfoHeader
---@field items MapInfoUrnDelivery[]

---@class MapInfoBreakables: MapInfoHeader
---@field state integer map_info.BreakableSpawnState
---@field initial_spawn MapInfoWindow|nil
---@field initial_override number|nil
---@field spawn_spread number|nil

-- ── map_info ─────────────────────────────────────────────────────────────────

---World objectives and timers: camps, sinners, powerups, mid boss, rift, urn, bell, breakables.
---@class map_info
map_info = {}

---@enum map_info.CampKind
map_info.CampKind = {
    SMALL = 34,
    MEDIUM = 35,
    LARGE = 36,
    SINNER = 37,
}

---@enum map_info.CampState
map_info.CampState = {
    UNKNOWN = 0,
    WAITING_INITIAL = 1,
    ALIVE = 2,
    DEAD = 3,
}

---@enum map_info.PowerupState
map_info.PowerupState = {
    UNKNOWN = 0,
    DISABLED = 1,
    WAITING = 2,
    ACTIVE = 3,
}

---@enum map_info.PowerupKind
map_info.PowerupKind = {
    UNKNOWN = 0,
    GUN = 1,
    MOVEMENT = 2,
    SURVIVAL = 3,
    CASTING = 4,
}

---@enum map_info.PowerupSpawnerKind
map_info.PowerupSpawnerKind = {
    STANDARD = 0,
    REFRESH = 1,
    CHANGE_TEAM = 2,
}

---@enum map_info.MidbossState
map_info.MidbossState = {
    UNKNOWN = 0,
    WAITING = 1,
    ALIVE = 2,
    DEAD = 3,
}

---@enum map_info.RiftPhase
map_info.RiftPhase = {
    UNKNOWN = 0,
    WAITING = 1,
    EARLY_WARNING = 2,
    WARNING = 3,
    SPAWN_WINDOW = 4,
    ACTIVE = 5,
    SCORING = 6,
    COOLDOWN = 7,
}

---@enum map_info.RiftLane
map_info.RiftLane = {
    UNKNOWN = 0,
    YELLOW = 1,
    GREEN = 2,
}

---@enum map_info.UrnState
map_info.UrnState = {
    UNKNOWN = 0,
    UNAVAILABLE = 1,
    ON_GROUND = 2,
    CARRIED = 3,
    DROPPED = 4,
    RETURNING = 5,
}

---@enum map_info.BreakableSpawnState
map_info.BreakableSpawnState = {
    UNKNOWN = 0,
    WAITING_INITIAL = 1,
    SPAWNED = 2,
}

---The current map and the global revision. Always a table.
---@return MapInfoMap
function map_info.map() end

---Every district of the map. Always a table (`items` is empty on unsupported maps).
---@return MapInfoDistricts
function map_info.districts() end

---One district by 1-based index, or nil when out of range. Raises an error when `index` is not an integer.
---@param index integer
---@return MapInfoDistrict|nil
function map_info.district(index) end

---The hotel's start and exit positions, or nil when the map has none.
---@return MapInfoHotel|nil
function map_info.hotel() end

---The bell, or nil when the map has none.
---@return MapInfoBell|nil
function map_info.bell() end

---Every neutral camp. Always a table.
---@return MapInfoCamps
function map_info.camps() end

---Every sinner (vault creature) with its jackpot timing. Always a table.
---@return MapInfoSinners
function map_info.sinners() end

---Every powerup spawner. Always a table.
---@return MapInfoPowerups
function map_info.powerups() end

---The mid boss, or nil when the map has none.
---@return MapInfoMidboss|nil
function map_info.midboss() end

---The rift objective (a single table, despite the name). Always a table.
---@return MapInfoRifts
function map_info.rifts() end

---The urn, or nil when the map has none.
---@return MapInfoUrn|nil
function map_info.urn() end

---Every urn delivery point. Always a table.
---@return MapInfoUrnDeliveries
function map_info.urn_deliveries() end

---The breakables' spawn state (a single table). Always a table.
---@return MapInfoBreakables
function map_info.breakables() end

-- ── midboss ──────────────────────────────────────────────────────────────────

---Control over the game's own Mid-Boss objective panel.
---@class midboss
midboss = {}

---@enum midboss.panel_mode
midboss.panel_mode = {
    ---The game decides.
    game_default = 0,
    ---Always shown.
    show = 1,
    ---Always hidden.
    hide = 2,
}

---Sets how the game's Mid-Boss objective panel is shown. Values outside 0-2 are ignored. Raises an error when `mode` is not an integer. Lasts until scripts reload.
---@param mode integer A `midboss.panel_mode` value.
function midboss.set_panel_mode(mode) end

-- ── player_stats ─────────────────────────────────────────────────────────────

---One player's record from `player_stats.all()`.
---@class PlayerStatsRecord
---@field steam_id string Steam id as decimal digits, "" when unknown.
---@field name string Player name.
---@field hero_name string Hero code name, e.g. "hero_inferno".
---@field hero_id integer Hero id, -1 until a hero was seen.
---@field team integer
---@field player_slot integer
---@field is_local boolean True for you.
---@field beam_weapon boolean True when the hero's gun is a beam weapon.
---@field shots integer
---@field hits integer
---@field misses integer
---@field headshots integer
---@field damage_total integer Damage dealt to heroes.
---@field discarded integer Shots that hit something other than a hero.
---@field orphans integer Damage events that matched no pending shot.
---@field pending integer Shots still waiting for a hit or a miss.
---@field accuracy number Percent: 100 * hits / shots (0 with no shots).
---@field headshot_percentage number Percent: 100 * headshots / hits (0 with no hits).
---@field entity? entity The player's pawn; absent when it can't be resolved.

---Counters from `player_stats.diagnostics()`.
---@class PlayerStatsDiagnostics
---@field fire_seen integer
---@field fire_not_gun integer
---@field fire_no_shooter integer
---@field flash_seen integer
---@field flash_zero_value integer
---@field flash_wrong_type integer
---@field flash_no_attacker integer
---@field flash_remote_pair integer
---@field discarded integer
---@field orphans integer

---Per-player gun accuracy for the current match.
---@class player_stats
player_stats = {}

---One record per player seen shooting or dealing damage (unsorted).
---@return PlayerStatsRecord[]
function player_stats.all() end

---Global counters of what the tracker has seen.
---@return PlayerStatsDiagnostics
function player_stats.diagnostics() end

---Clears every record and counter.
function player_stats.reset() end

-- ── meta ─────────────────────────────────────────────────────────────────────

---Period key of `meta.get`.
---@alias MetaPeriod "7d"|"14d"|"1m"

---Bracket key of `meta.get`.
---@alias MetaBracket
---| "eternus"
---| "ascendant-plus"
---| "ascendant"
---| "phantom-plus"
---| "phantom"
---| "oracle-plus"
---| "oracle"
---| "archon-plus"
---| "archon"
---| "emissary-plus"
---| "emissary"
---| "ritualist-plus"
---| "ritualist"
---| "arcanist"
---| "alchemist"
---| "seeker"
---| "initiate"

---One hero row of `meta.get`.
---@class MetaRow
---@field hero_id integer
---@field hero_name string Display name, e.g. "Lady Geist".
---@field winrate number Percent.
---@field pickrate number Percent of matches the hero is in.

---Hero win and pick rates by rank bracket.
---@class meta
meta = {}

---True when the last selection asked for with `meta.get` (or the menu's selection, before any call) has data.
---@return boolean
function meta.ready() end

---True when that selection's download failed.
---@return boolean
function meta.failed() end

---Hero rows for a period and bracket. Starts the download when needed and raises an error until the data is ready.
---@param period MetaPeriod
---@param bracket MetaBracket
---@return MetaRow[]
function meta.get(period, bracket) end

-- ── Localizer / GameLocalizer ────────────────────────────────────────────────

---A string table shared by all scripts for your own translations.
---@class Localizer
Localizer = {}

---The stored text for a token, or the token itself when none is stored.
---@param token string
---@return string
function Localizer.Get(token) end

---Registers a token (stored as itself) when it is not stored yet.
---@param token string
function Localizer.RegToken(token) end

---Stores (or replaces) the text for a token.
---@param token string
---@param value string
function Localizer.SetToken(token, value) end

---The game's own localization strings.
---@class GameLocalizer
GameLocalizer = {}

---The game's localized string for a token. Never nil.
---@param token string
---@return string
function GameLocalizer.Find(token) end

-- ── sound ────────────────────────────────────────────────────────────────────

---Sound event names and hashes.
---@class sound
sound = {}

---The hash of a sound event name (any string, registered or not), or nil when the sound system is unavailable.
---@param name string
---@return integer|nil
function sound.hash(name) end

---The registered sound event name for a hash, or nil when unknown.
---@param hash integer
---@return string|nil
function sound.name(hash) end

---True when the hash belongs to a registered sound event.
---@param hash integer
---@return boolean
function sound.is_valid_hash(hash) end
