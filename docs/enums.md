# Enums

Named integer constants. They come in two kinds:

- **`Enum.*`**: fixed groups that belong to the API itself (teams, key codes, draw flags, menu widget types, ...). Their values do not change.
- **Game enums**: globals named after the game's own enums (`EModifierState`, `EAbilitySlots_t`, `InputBitMask_t`, ...). They are read from the running game each time the script environment is built, so they always match the installed game build.

Always use the names in your code, never the numbers. Game enum values **can change with game updates**. The values on this page and in [`library/enums.lua`](../library/enums.lua) are a snapshot from the game build current when they were written. `library/enums.lua` has every value of every group for editor autocomplete.

```lua
local function is_stunned(pawn)
    return pawn:has_modifier_state(EModifierState.MODIFIER_STATE_STUNNED)
end

callback.on_key_event:set(function(data)
    if data.event == Enum.KeyEvent.KEY_DOWN and data.key == Enum.ButtonCode.KEY_F then
        print("F pressed")
    end
end)
```

General notes:
- Every value is a Lua integer. Bit-flag groups (`Enum.DrawFlags`, `Enum.FontCreate`, `InputBitMask_t`, `DamageTypes_t`) combine with `|` and test with `&`.
- Several names can share a value (for example `KEY_NONE` and `KEY_FIRST`), so a reverse lookup from a value to a name is not unique.
- A game enum the running build does not have is an **empty table**: indexing it gives `nil` and raises no error. Check for `nil` before you pass a value on if your script must survive game updates.
- Treat the tables as read-only.

---

## Enum

### `Enum.TeamNum`

Team numbers.

| Name | Value |
|---|---|
| `TEAM_NONE` | 0 |
| `TEAM_AMBER` | 2 |
| `TEAM_SAPPHIRE` | 3 |
| `TEAM_NEUTRAL` | 4 |

### `Enum.KeyEvent`

The `data.event` values of the `on_key_event` callback (see [callbacks](callbacks.md)).

| Name | Value |
|---|---|
| `SCROLL_DOWN` | 0 |
| `SCROLL_UP` | 1 |
| `KEY_DOWN` | 2 |
| `KEY_UP` | 3 |

### `Enum.ButtonCode`

Key and mouse button codes. These are the `data.key` values of `on_key_event` and the codes the [input](input.md) functions take.

| Names | Values |
|---|---|
| `BUTTON_CODE_INVALID` | -1 |
| `BUTTON_CODE_NONE`, `KEY_FIRST`, `KEY_NONE` | 0 |
| `KEY_0` ... `KEY_9` | 1 ... 10 |
| `KEY_A` ... `KEY_Z` | 11 ... 36 |
| `KEY_PAD_0` ... `KEY_PAD_9` | 37 ... 46 |
| `KEY_PAD_DIVIDE`, `KEY_PAD_MULTIPLY`, `KEY_PAD_MINUS`, `KEY_PAD_PLUS`, `KEY_PAD_ENTER`, `KEY_PAD_DECIMAL` | 47, 48, 49, 50, 51, 52 |
| `KEY_LBRACKET`, `KEY_RBRACKET`, `KEY_SEMICOLON`, `KEY_APOSTROPHE`, `KEY_BACKQUOTE` | 54, 55, 56, 57, 58 |
| `KEY_COMMA`, `KEY_PERIOD`, `KEY_SLASH`, `KEY_BACKSLASH`, `KEY_MINUS`, `KEY_EQUAL` | 59, 60, 61, 62, 63, 64 |
| `KEY_ENTER`, `KEY_SPACE`, `KEY_BACKSPACE`, `KEY_TAB` | 65, 66, 67, 68 |
| `KEY_CAPSLOCK`, `KEY_NUMLOCK`, `KEY_ESCAPE`, `KEY_SCROLLLOCK` | 69, 70, 71, 72 |
| `KEY_INSERT`, `KEY_DELETE`, `KEY_HOME`, `KEY_END`, `KEY_PAGEUP`, `KEY_PAGEDOWN`, `KEY_BREAK` | 73, 74, 75, 76, 77, 78, 79 |
| `KEY_LSHIFT`, `KEY_RSHIFT`, `KEY_LALT`, `KEY_RALT`, `KEY_LCONTROL`, `KEY_RCONTROL` | 80, 81, 82, 83, 84, 85 |
| `KEY_LWIN`, `KEY_RWIN`, `KEY_APP` | 86, 87, 88 |
| `KEY_UP`, `KEY_LEFT`, `KEY_DOWN`, `KEY_RIGHT` | 89, 90, 91, 92 |
| `KEY_F1` ... `KEY_F12` | 93 ... 104 |
| `KEY_CAPSLOCKTOGGLE`, `KEY_NUMLOCKTOGGLE`, `KEY_SCROLLLOCKTOGGLE` | 105, 106, 107 |
| `KEY_MOUSE1` (left), `KEY_MOUSE2` (right), `KEY_MOUSE3` (middle) | 314, 315, 316 |
| `KEY_MOUSE4`, `KEY_MOUSE5` (side buttons) | 317, 318 |
| `KEY_MWHEELUP`, `KEY_MWHEELDOWN` | 319, 320 |

### `Enum.DrawFlags`

Shape flags for [`Render.*`](render.md) drawing, mainly which corners are rounded. Bit flags.

| Name | Value |
|---|---|
| `None` | 0 |
| `Closed` | 1 |
| `RoundCornersTopLeft` | 16 |
| `RoundCornersTopRight` | 32 |
| `RoundCornersBottomLeft` | 64 |
| `RoundCornersBottomRight` | 128 |
| `RoundCornersNone` | 256 |
| `RoundCornersTop` | 48 |
| `RoundCornersBottom` | 192 |
| `RoundCornersLeft` | 80 |
| `RoundCornersRight` | 160 |
| `RoundCornersAll` | 240 |
| `RoundCornersDefault_` | 240 |
| `RoundCornersMask_` | 496 |
| `ShadowCutOutShapeBackground` | 512 |

```lua
local top_only = Enum.DrawFlags.RoundCornersTopLeft | Enum.DrawFlags.RoundCornersTopRight
-- same as Enum.DrawFlags.RoundCornersTop
```

### `Enum.FontCreate`

Font flags for [`Render.LoadFont(name [, flags [, weight]])`](render.md) and `Render.LoadGameFont`. Bit flags.

| Name | Value |
|---|---|
| `FONTFLAG_NONE` | 0 |
| `FONTFLAG_ITALIC` | 1 |
| `FONTFLAG_UNDERLINE` | 2 |
| `FONTFLAG_STRIKEOUT` | 4 |
| `FONTFLAG_SYMBOL` | 8 |
| `FONTFLAG_ANTIALIAS` | 16 |
| `FONTFLAG_GAUSSIANBLUR` | 32 |
| `FONTFLAG_ROTARY` | 64 |
| `FONTFLAG_DROPSHADOW` | 128 |
| `FONTFLAG_ADDITIVE` | 256 |
| `FONTFLAG_OUTLINE` | 512 |
| `FONTFLAG_CUSTOM` | 1024 |
| `FONTFLAG_BITMAP` | 2048 |

### `Enum.FontWeight`

Font weights for `Render.LoadFont` and `Render.LoadGameFont`. The default weight is 400.

| Name | Value |
|---|---|
| `THIN` | 100 |
| `ULTRALIGHT` | 200 |
| `LIGHT` | 300 |
| `NORMAL` | 400 |
| `MEDIUM` | 500 |
| `SEMIBOLD` | 600 |
| `BOLD` | 700 |
| `EXTRABOLD` | 800 |
| `HEAVY` | 900 |

### `Enum.ImageFilter`

Filters for `Render.LoadImage(path [, filter])`.

| Name | Value |
|---|---|
| `None` | 0 |
| `Negative` | 1 |
| `Grayscale` | 2 |
| `White` | 3 |
| `Black` | 4 |
| `LuminanceAlpha` | 5 |

### `Enum.WidgetType`

Menu widget types. A [menu](menu.md) widget's `:Type()` returns one of these.

| Name | Value |
|---|---|
| `MenuFirstTab` | 0 |
| `MenuSection` | 1 |
| `MenuSecondTab` | 2 |
| `MenuThirdTab` | 3 |
| `MenuGroup` | 4 |
| `MenuSwitch` | 5 |
| `MenuBind` | 6 |
| `MenuSliderFloat` | 7 |
| `MenuSliderInt` | 8 |
| `MenuColorPicker` | 9 |
| `MenuButton` | 11 |
| `MenuComboBox` | 12 |
| `MenuMultiComboBox` | 13 |
| `MenuGearAttachment` | 14 |
| `MenuInputBox` | 15 |
| `MenuMultiSelect` | 16 |
| `MenuSearch` | 17 |
| `MenuThemePicker` | 18 |
| `MenuLabel` | 19 |
| `MenuCustomBind` | 22 |
| `MenuTypesCount` | 25 |
| `MenuTypeInvalid` | 26 |

### `Enum.GroupSide`

The column a menu group goes in. Pass it as the optional second argument when you create a group.

| Name | Value |
|---|---|
| `Default` | -1 |
| `Left` | 1 |
| `Right` | 2 |
| `FullWidth` | 3 |

### `Enum.AbilityExecuteState`

Return values of `ability:can_be_executed()` (see [entities](entities.md)).

| Name | Value |
|---|---|
| `INVALID` | -1 |
| `READY` | 0 |
| `COOLDOWN` | 2 |
| `PASSIVE` | 3 |
| `UNSPECIFIED` | 7 |
| `BUSY` | 10 |

`ability:can_be_executed()` can return codes other than these. Compare against `READY` rather than listing every failure.

### `Enum.ParticleAttachment`

Particle attachment types.

| Name | Value |
|---|---|
| `PATTACH_INVALID` | -1 |
| `PATTACH_ABSORIGIN` | 0 |
| `PATTACH_ABSORIGIN_FOLLOW` | 1 |
| `PATTACH_CUSTOMORIGIN` | 2 |
| `PATTACH_CUSTOMORIGIN_FOLLOW` | 3 |
| `PATTACH_POINT` | 4 |
| `PATTACH_POINT_FOLLOW` | 5 |
| `PATTACH_EYES_FOLLOW` | 6 |
| `PATTACH_OVERHEAD_FOLLOW` | 7 |
| `PATTACH_WORLDORIGIN` | 8 |
| `PATTACH_ROOTBONE_FOLLOW` | 9 |
| `PATTACH_RENDERORIGIN_FOLLOW` | 10 |
| `PATTACH_MAIN_VIEW` | 11 |
| `PATTACH_WATERWAKE` | 12 |
| `PATTACH_CENTER_FOLLOW` | 13 |
| `PATTACH_CUSTOM_GAME_STATE_1` | 14 |
| `PATTACH_HEALTHBAR` | 15 |
| `MAX_PATTACH_TYPES` | 16 |

---

## Game enums

Globals, read from the running game. Values below are a snapshot and **can change with game updates**. Use the names.

| Global | Values | Used for |
|---|---|---|
| `EAbilitySlots_t` | 29 | Ability, item and weapon slots (`pawn:get_ability_by_slot(slot)`) |
| `EModifierState` | 356 | Modifier states (`has_modifier_state`, `has_any_modifier_state`, `get_modifier_state_remaining_duration`, `find_best_modifier_for_state`, `find_best_modifiers_for_states`) |
| `EModifierValue` | 256 | Modifier value ids (`get_modifier_value`, `get_sum_modifier_value`) |
| `EModifierEvent` | 112 | Modifier event ids |
| `InputBitMask_t` | 46 | Command button bits (`CUserCmd` button masks) |
| `DamageTypes_t` | 28 | Damage type bit flags |
| `CitadelNPCDamageState_t` | 0 | NPC damage states. Empty in current game builds. |
| `EStatsType` | 110 | Hero stat ids (`pawn:get_starting_stat`, `pawn:get_scaling_stat`) |
| `ECurrencyType` | 8 | Currency types (`pawn:get_currency(type)`) |
| `EAbilityTargetingLocation_t` | 11 | How an ability picks its target location |
| `EAbilityTargetingShape_t` | 7 | Ability targeting shapes |
| `ELOSCheck` | 8 | Line-of-sight check modes |
| `EBaseClientMessages` | 7 | Base client message ids |
| `EBaseUserMessages` | 53 | Base user message ids |
| `SVC_Messages` | 33 | Server-to-client net message ids |
| `EGCCitadelClientMessages` | 180 | Game Coordinator message ids |

### `EAbilitySlots_t`

| Name | Value |
|---|---|
| `ESlot_Invalid` | -1 |
| `ESlot_Signature_First`, `ESlot_Signature_1` | 0 |
| `ESlot_Signature_2` | 1 |
| `ESlot_Signature_3` | 2 |
| `ESlot_Signature_4` | 3 |
| `ESlot_ActiveItem_First`, `ESlot_ActiveItem_1` | 4 |
| `ESlot_ActiveItem_2` | 5 |
| `ESlot_ActiveItem_3` | 6 |
| `ESlot_ActiveItem_4`, `ESlot_ActiveItem_Last` | 7 |
| `ESlot_Ability_Held` | 8 |
| `ESlot_Ability_ZipLine` | 9 |
| `ESlot_Ability_Mantle` | 10 |
| `ESlot_Ability_ClimbRope` | 11 |
| `ESlot_Ability_Jump` | 12 |
| `ESlot_Ability_Slide` | 13 |
| `ESlot_Ability_Teleport` | 14 |
| `ESlot_Ability_ZipLineBoost` | 15 |
| `ESlot_Cosmetic_1` | 16 |
| `ESlot_Ability_Innate_1` | 17 |
| `ESlot_Ability_Innate_2` | 18 |
| `ESlot_Ability_Innate_3` | 19 |
| `ESlot_Weapon_Secondary` | 20 |
| `ESlot_Weapon_Primary` | 21 |
| `ESlot_Weapon_Melee` | 22 |
| `ESlot_None`, `EMaxAbilitySlots` | 23 |

```lua
local function ult_ready(pawn)
    local ult = pawn:get_ability_by_slot(EAbilitySlots_t.ESlot_Signature_4)
    return ult ~= nil and ult:can_be_executed() == Enum.AbilityExecuteState.READY
end
```

### `EModifierState`

States a modifier can put on an entity (stunned, silenced, invisible, ...). 356 values. Representative ones:

| Name | Value |
|---|---|
| `MODIFIER_STATE_BLIND` | 8 |
| `MODIFIER_STATE_NO_TARGET` | 11 |
| `MODIFIER_STATE_IMMOBILIZED` | 13 |
| `MODIFIER_STATE_DISARMED` | 14 |
| `MODIFIER_STATE_ITEMS_DISABLED` | 16 |
| `MODIFIER_STATE_SILENCED` | 17 |
| `MODIFIER_STATE_STUNNED` | 20 |
| `MODIFIER_STATE_INVULNERABLE` | 21 |
| `MODIFIER_STATE_TECH_INVULNERABLE` | 22 |
| `MODIFIER_STATE_STATUS_IMMUNE` | 26 |
| `MODIFIER_STATE_UNSTOPPABLE` | 28 |
| `MODIFIER_STATE_OUT_OF_GAME` | 29 |
| `MODIFIER_STATE_INVISIBLE_TO_ENEMY` | 34 |
| `MODIFIER_STATE_SLOWED` | 67 |
| `MODIFIER_STATE_BULLET_INVULNERABLE` | 96 |
| `MODIFIER_STATE_PARRY_DISABLED` | 114 |
| `MODIFIER_STATE_SLOW_IMMUNE` | 130 |
| `MODIFIER_STATE_PARRY_ACTIVE` | 231 |
| `MODIFIER_STATE_COUNT` | 354 |

The full list is in `library/enums.lua`.

```lua
local function is_disabled(pawn)
    return pawn:has_any_modifier_state(
        EModifierState.MODIFIER_STATE_STUNNED,
        EModifierState.MODIFIER_STATE_SILENCED,
        EModifierState.MODIFIER_STATE_IMMOBILIZED)
end
```

### `EModifierValue`

Numeric values that modifiers contribute (bonus health, fire rate, spirit power, ...). 256 values. Representative ones:

| Name | Value |
|---|---|
| `MODIFIER_VALUE_INCOMING_DAMAGE_PERCENTAGE_CHANGE` | 8 |
| `MODIFIER_VALUE_GRAVITY_SCALE` | 9 |
| `MODIFIER_VALUE_OUTGOING_DAMAGE_PERCENTAGE_CHANGE` | 12 |
| `MODIFIER_VALUE_WEAPON_DAMAGE_INCREASE` | 20 |
| `MODIFIER_VALUE_BULLET_DAMAGE_INCREASE` | 21 |
| `MODIFIER_VALUE_BULLET_ARMOR_DAMAGE_RESIST` | 36 |
| `MODIFIER_VALUE_HEALTH_MAX` | 46 |
| `MODIFIER_VALUE_HEALTH_REGEN_PER_SECOND` | 52 |
| `MODIFIER_VALUE_SPRINT_SPEED_BONUS` | 88 |
| `MODIFIER_VALUE_FIRE_RATE` | 96 |
| `MODIFIER_VALUE_COOLDOWN_REDUCTION_PERCENTAGE` | 103 |
| `MODIFIER_VALUE_PARRY_COOLDOWN_REDUCTION_FIXED` | 115 |
| `MODIFIER_VALUE_INVISIBILITY_LEVEL` | 148 |
| `MODIFIER_VALUE_TECH_POWER` | 169 |
| `MODIFIER_VALUE_TECH_POWER_PERCENT` | 170 |
| `MODIFIER_VALUE_BOON_COUNT` | 223 |
| `MODIFIER_VALUE_COUNT` | 254 |

The full list is in `library/enums.lua`.

### `EModifierEvent`

Modifier event ids. 112 values. Representative ones:

| Name | Value |
|---|---|
| `MODIFIER_EVENT_DAMAGE_TAKEN_BROADCAST` | 1 |
| `MODIFIER_EVENT_KILLED_BROADCAST` | 3 |
| `MODIFIER_EVENT_PLAYER_KILLED_BROADCAST` | 8 |
| `MODIFIER_EVENT_PLAYER_RESPAWNED_BROADCAST` | 9 |
| `MODIFIER_EVENT_ABILITY_EXECUTED_BROADCAST` | 16 |
| `MODIFIER_EVENT_MODIFIER_GAINED` | 21 |
| `MODIFIER_EVENT_MODIFIER_LOST` | 22 |
| `MODIFIER_EVENT_DAMAGE_TAKEN` | 25 |
| `MODIFIER_EVENT_KILLED` | 26 |
| `MODIFIER_EVENT_ABILITY_CAST_STARTED` | 36 |
| `MODIFIER_EVENT_ABILITY_EXECUTED` | 38 |
| `MODIFIER_EVENT_GUN_FIRED` | 43 |
| `MODIFIER_EVENT_BULLET_HIT` | 45 |
| `MODIFIER_EVENT_PROJECTILE_HIT` | 47 |
| `MODIFIER_EVENT_LANDED_ON_GROUND` | 54 |
| `MODIFIER_EVENT_CHECK_FOR_PARRY` | 79 |

The full list is in `library/enums.lua`.

### `InputBitMask_t`

Command button bits, as used in the [`CUserCmd`](usercmd.md) button masks. 64-bit values.

| Name | Value |
|---|---|
| `IN_NONE` | 0 |
| `IN_ALL` | -1 (all bits) |
| `IN_ATTACK` | 1 |
| `IN_JUMP` | 2 |
| `IN_DUCK` | 4 |
| `IN_FORWARD` | 8 |
| `IN_BACK` | 16 |
| `IN_USE` | 32 |
| `IN_TURNLEFT` | 128 |
| `IN_TURNRIGHT` | 256 |
| `IN_MOVELEFT` | 512 |
| `IN_MOVERIGHT` | 1024 |
| `IN_ATTACK2` | 2048 |
| `IN_RELOAD` | 8192 |
| `IN_SPEED` | 65536 |
| `IN_JOYAUTOSPRINT` | 131072 |
| `IN_FIRST_MOD_SPECIFIC_BIT`, `IN_WEAPON1` | 1 << 32 |
| `IN_ABILITY1` ... `IN_ABILITY4` | 1 << 33 ... 1 << 36 |
| `IN_ITEM1` ... `IN_ITEM5` | 1 << 37 ... 1 << 41 |
| `IN_ABILITY_HELD` | 1 << 42 |
| `IN_INNATE_1` ... `IN_INNATE_3` | 1 << 44 ... 1 << 46 |
| `IN_MANTLE` | 1 << 48 |
| `IN_SPEC_NEXT`, `IN_SPEC_PREV`, `IN_SPEC_MODE`, `IN_SPEC_TOGGLE_TEAM` | 1 << 49 ... 1 << 52 |
| `IN_ALT_CAST` | 1 << 53 |
| `IN_REPLAY_DEATH` | 1 << 54 |
| `IN_TELEPORT` | 1 << 55 |
| `IN_ZIPLINE` | 1 << 56 |
| `IN_MOVE_UP`, `IN_MOVE_DOWN` | 1 << 57, 1 << 58 |
| `IN_DUCK_TOGGLE` | 1 << 59 |
| `IN_CANCEL_ABILITY` | 1 << 60 |
| `IN_COSMETIC_1` | 1 << 61 |
| `IN_DOWN_DASH` | 1 << 62 |

```lua
local function is_shooting(mask)
    return mask & InputBitMask_t.IN_ATTACK ~= 0
end
```

### `DamageTypes_t`

Damage type bit flags.

| Name | Value |
|---|---|
| `DMG_GENERIC` | 0 |
| `DMG_CRUSH` | 1 |
| `DMG_BULLET` | 2 |
| `DMG_SLASH` | 4 |
| `DMG_BURN` | 8 |
| `DMG_VEHICLE` | 16 |
| `DMG_FALL` | 32 |
| `DMG_BLAST` | 64 |
| `DMG_CLUB` | 128 |
| `DMG_SHOCK` | 256 |
| `DMG_SONIC` | 512 |
| `DMG_ENERGYBEAM` | 1024 |
| `DMG_BUCKSHOT` | 2048 |
| `DMG_BLAST_SURFACE` | 4096 |
| `DMG_DISSOLVE` | 8192 |
| `DMG_DROWN` | 16384 |
| `DMG_POISON` | 32768 |
| `DMG_RADIATION` | 65536 |
| `DMG_DROWNRECOVER` | 131072 |
| `DMG_ACID`, `DMG_LASTGENERICFLAG` | 262144 |
| `DMG_HEADSHOT` | 524288 |
| `DMG_CRIT` | 1048576 |
| `DMG_BUFFED` | 2097152 |
| `DMG_DOT` | 4194304 |
| `DMG_GROUND_AURA` | 8388608 |
| `DMG_LETHAL` | 16777216 |
| `DMG_CITADEL_CORRECT_PATH` | 33554432 |

### `CitadelNPCDamageState_t`

NPC damage states. Current game builds do not have this enum, so the global is an empty table and every lookup gives `nil`.

### `EStatsType`

Hero stat ids. 110 values. Representative ones:

| Name | Value |
|---|---|
| `EWeaponDPS` | 0 |
| `EMaxHealth` | 2 |
| `EClipSize` | 3 |
| `EHealthRegen` | 6 |
| `EMaxMoveSpeed` | 7 |
| `ESprintSpeed` | 8 |
| `EBulletArmorDamageReduction` | 12 |
| `ETechArmorDamageReduction` | 14 |
| `ELightMeleeDamage` | 16 |
| `EHeavyMeleeDamage` | 17 |
| `EFireRate` | 20 |
| `EBulletDamage` | 23 |
| `ETechCooldown` | 32 |
| `ETechRange` | 34 |
| `EReloadSpeed` | 38 |
| `EStamina` | 50 |
| `ETechPower` | 59 |
| `EBulletSpeed` | 76 |
| `EParryCooldown` | 84 |
| `ECurrentHealth` | 102 |
| `EStatsCount`, `EStatsInvalid` | 108 |

The full list is in `library/enums.lua`.

### `ECurrencyType`

| Name | Value |
|---|---|
| `ECurrencyInvalid` | -1 |
| `EGold` | 0 |
| `EAbilityPoints` | 1 |
| `EAbilityUnlocks` | 2 |
| `EDeathPenaltyGold` | 3 |
| `EItemDraftRerolls` | 4 |
| `EItemEnhancements` | 5 |
| `ECurrencyCount` | 6 |

```lua
local function souls(pawn)
    return pawn:get_currency(ECurrencyType.EGold)
end
```

### `EAbilityTargetingLocation_t`

| Name | Value |
|---|---|
| `CITADEL_ABILITY_TARGETING_LOCATION_NONE` | 0 |
| `CITADEL_ABILITY_TARGETING_LOCATION_SELF` | 1 |
| `CITADEL_ABILITY_TARGETING_LOCATION_UNIT` | 2 |
| `CITADEL_ABILITY_TARGETING_LOCATION_GROUND` | 3 |
| `CITADEL_ABILITY_TARGETING_LOCATION_UNIT_OR_GROUND` | 4 |
| `CITADEL_ABILITY_TARGETING_LOCATION_FIXED_RANGE_GROUND` | 5 |
| `CITADEL_ABILITY_TARGETING_LOCATION_MINIMAP_GROUND` | 6 |
| `CITADEL_ABILITY_TARGETING_LOCATION_MINIMAP_UNIT` | 7 |
| `CITADEL_ABILITY_TARGETING_LOCATION_CUSTOM` | 8 |
| `CITADEL_ABILITY_TARGETING_LOCATION_DEPLOYED_OBJECT` | 9 |
| `CITADEL_ABILITY_TARGETING_LOCATION_COUNT` | 10 |

### `EAbilityTargetingShape_t`

| Name | Value |
|---|---|
| `CITADEL_ABILITY_TARGETING_SHAPE_NONE` | 0 |
| `CITADEL_ABILITY_TARGETING_SHAPE_SPHERE` | 1 |
| `CITADEL_ABILITY_TARGETING_SHAPE_LINE` | 2 |
| `CITADEL_ABILITY_TARGETING_SHAPE_CIRCLE` | 3 |
| `CITADEL_ABILITY_TARGETING_SHAPE_CONE` | 4 |
| `CITADEL_ABILITY_TARGETING_SHAPE_CAPSULE` | 5 |
| `CITADEL_ABILITY_TARGETING_SHAPE_COUNT` | 6 |

### `ELOSCheck`

Line-of-sight check modes.

| Name | Value |
|---|---|
| `None` | 0 |
| `Head` | 1 |
| `Head_IgnoreObscureBlockers` | 2 |
| `BodyCenter` | 3 |
| `BodyCenter_IgnoreObscureBlockers` | 4 |
| `Bounds` | 5 |
| `Bounds_IgnoreObscureBlockers` | 6 |
| `FibonacciSphere` | 7 |

### `EBaseClientMessages`

| Name | Value |
|---|---|
| `CM_CustomGameEvent` | 280 |
| `CM_CustomGameEventBounce` | 281 |
| `CM_ClientUIEvent` | 282 |
| `CM_DevPaletteVisibilityChanged` | 283 |
| `CM_WorldUIControllerHasPanelChanged` | 284 |
| `CM_RotateAnchor` | 285 |
| `CM_MAX_BASE` | 300 |

### `EBaseUserMessages`

Base user message ids. 53 values. Representative ones:

| Name | Value |
|---|---|
| `UM_AchievementEvent` | 101 |
| `UM_Fade` | 106 |
| `UM_HudMsg` | 110 |
| `UM_HudText` | 111 |
| `UM_SayText` | 117 |
| `UM_SayText2` | 118 |
| `UM_Shake` | 120 |
| `UM_TextMsg` | 124 |
| `UM_SendAudio` | 130 |
| `UM_CameraTransition` | 143 |
| `UM_AudioParameter` | 144 |
| `UM_ParticleManager` | 145 |
| `UM_HudError` | 146 |
| `UM_CustomGameEvent` | 148 |
| `UM_ServerFrameTime` | 154 |
| `UM_MAX_BASE` | 200 |

The full list is in `library/enums.lua`.

### `SVC_Messages`

Server-to-client net message ids. 33 values. Representative ones:

| Name | Value |
|---|---|
| `svc_ServerInfo` | 40 |
| `svc_ClassInfo` | 42 |
| `svc_SetPause` | 43 |
| `svc_CreateStringTable` | 44 |
| `svc_UpdateStringTable` | 45 |
| `svc_VoiceData` | 47 |
| `svc_Print` | 48 |
| `svc_Sounds` | 49 |
| `svc_SetView` | 50 |
| `svc_PacketEntities` | 55 |
| `svc_GetCvarValue` | 58 |
| `svc_UserMessage` | 72 |
| `svc_UserCmds` | 76 |

The full list is in `library/enums.lua`.

### `EGCCitadelClientMessages`

Game Coordinator message ids. 180 values. Representative ones:

| Name | Value |
|---|---|
| `k_EMsgClientToGCStartMatchmaking` | 9010 |
| `k_EMsgClientToGCStartMatchmakingResponse` | 9011 |
| `k_EMsgClientToGCStopMatchmaking` | 9012 |
| `k_EMsgGCToClientMatchmakingStopped` | 9014 |
| `k_EMsgClientToGCLeaveLobby` | 9015 |
| `k_EMsgClientToGCIsInMatchmaking` | 9017 |
| `k_EMsgClientToGCGetProfileCard` | 9024 |
| `k_EMsgClientToGCGetProfileCardResponse` | 9025 |
| `k_EMsgClientToGCSpectateLobby` | 9109 |
| `k_EMsgClientToGCGetMatchHistory` | 9112 |
| `k_EMsgClientToGCGetMatchHistoryResponse` | 9113 |
| `k_EMsgClientToGCSpectateUser` | 9116 |
| `k_EMsgClientToGCPartyCreate` | 9123 |

The full list is in `library/enums.lua`.
