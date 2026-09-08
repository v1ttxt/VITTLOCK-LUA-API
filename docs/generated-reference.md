# VITTLOCK Lua API Reference

_Auto-generated from the C++ binding registry. Do not edit._

## Namespaces

- [CUserCmd](#cusercmd)
- [Debugger](#debugger)
- [EModifierState](#emodifierstate)
- [Engine](#engine)
- [ImGui](#imgui)
- [InputBitMask_t](#inputbitmaskt)
- [Menu](#menu)
- [QAngle](#qangle)
- [UI](#ui)
- [Vector3](#vector3)
- [aimbot](#aimbot)
- [base64](#base64)
- [callbacks](#callbacks)
- [config](#config)
- [cvar](#cvar)
- [docs](#docs)
- [entity_list](#entitylist)
- [fs](#fs)
- [hash](#hash)
- [input](#input)
- [json](#json)
- [log](#log)
- [math](#math)
- [render](#render)
- [storage](#storage)
- [timers](#timers)
- [ui](#ui)

---

## CUserCmd

_Per-tick command sent to the server (movement, view, buttons)_

### `CUserCmd.GetCameraAngles`

```lua
fun():QAngle
```

Current camera angles this tick

**Returns:** `QAngle`

### `CUserCmd.SetCameraPosition`

```lua
fun(x:number, y:number, z:number):nil
```

Override camera position (x,y,z)

**Arguments:**
- `x` — `number`
- `y` — `number`
- `z` — `number`

### `CUserCmd.GetForwardMove`

```lua
fun():number
```

Forward move axis (units/s)

**Returns:** `number`

### `CUserCmd.SetForwardMove`

```lua
fun(v:number):nil
```

Set forward move axis

**Arguments:**
- `v` — `number`

### `CUserCmd.AddButtonState`

```lua
fun(bit:integer):nil
```

Hold a button (see InputBitMask_t)

**Arguments:**
- `bit` — `integer`


## Debugger

_Access to the in-app debug console_

### `Debugger.GetLogs`

```lua
fun():string
```

Full log buffer text

**Returns:** `string`

### `Debugger.ClearLogs`

```lua
fun():nil
```

Clear the debugger console

### `Debugger.SetClipboardText`

```lua
fun(text:string):nil
```

Copy text to system clipboard

**Arguments:**
- `text` — `string`


## EModifierState

_Modifier state ids (see Deadlock schema)_

### `EModifierState.<value>`

```lua
fun():integer
```

305 named integer constants — see Deadlock schema. Use e.g. EModifierState.MODIFIER_STATE_STUNNED.

**Returns:** `integer`


## Engine

_Game state accessors — local player, entities, screen, time_

### `Engine.GetLocalVelocity`

```lua
fun():Vector3
```

Local player velocity (units/s)

**Returns:** `Vector3`

### `Engine.GetLocalMoveType`

```lua
fun():integer
```

Local player MoveType_t

**Returns:** `integer`

### `Engine.GetLocalFlags`

```lua
fun():integer
```

Local player m_fFlags

**Returns:** `integer`

### `Engine.GetCameraAngles`

```lua
fun():QAngle
```

Local player camera angles

**Returns:** `QAngle`

### `Engine.HasModifierState`

```lua
fun(state:integer):boolean
```

Local player has EModifierState

**Arguments:**
- `state` — `integer`

**Returns:** `boolean`

### `Engine.EntityHasModifierState`

```lua
fun(handle:integer, state:integer):boolean
```

Entity has EModifierState

**Arguments:**
- `handle` — `integer`
- `state` — `integer`

**Returns:** `boolean`

### `Engine.IsOnWall`

```lua
fun():boolean
```

Local player is wall-jumping / wall-sliding

**Returns:** `boolean`

### `Engine.GetTickInterval`

```lua
fun():number
```

Server tick interval in seconds

**Returns:** `number`

### `Engine.GetCurTime`

```lua
fun():number
```

Game clock (seconds since server start)

**Returns:** `number`

### `Engine.GetLocalPlayerHandle`

```lua
fun():integer
```

Local player entity handle, -1 if none

**Returns:** `integer`

### `Engine.GetAirAccelerate`

```lua
fun():number
```

Air-accelerate convar value (hardcoded 10)

**Returns:** `number`

### `Engine.GetEntityAbility`

```lua
fun(handle:integer, name:string):table|nil
```

Fetch ability table by designer-name / subclass substring / hash

**Arguments:**
- `handle` — `integer`
- `name` — `string`

**Returns:** `table|nil`

### `Engine.IsAbilityReady`

```lua
fun(handle:integer, name:string):boolean
```

Check if ability or item is equipped and off cooldown

**Arguments:**
- `handle` — `integer`
- `name` — `string`

**Returns:** `boolean`

### `Engine.CastAbility`

```lua
fun(cmd:CUserCmd, name:string):boolean
```

Taps the exact button mask (IN_ABILITY1..4 / IN_ITEM1..4) for a named ability or item

**Arguments:**
- `cmd` — `CUserCmd`
- `name` — `string`

**Returns:** `boolean`

### `Engine.GetEntityAbilities`

```lua
fun(handle:integer):table[]|nil
```

Fetch all ability tables for an entity

**Arguments:**
- `handle` — `integer`

**Returns:** `table[]|nil`

### `Engine.GetProjectiles`

```lua
fun():table[]
```

Returns array of active projectile entities in the world

**Returns:** `table[]`

### `Engine.EntityHasModifier`

```lua
fun(handle:integer, name:string):boolean
```

Entity has a named modifier

**Arguments:**
- `handle` — `integer`
- `name` — `string`

**Returns:** `boolean`

### `Engine.GetModifierRemainingTime`

```lua
fun(handle:integer, name:string):number
```

Remaining seconds of active modifier on entity, -1 if absent

**Arguments:**
- `handle` — `integer`
- `name` — `string`

**Returns:** `number`

### `Engine.GetEntityModifiers`

```lua
fun(handle:integer):table[]
```

Get all active modifier objects for an entity

**Arguments:**
- `handle` — `integer`

**Returns:** `table[]`

### `Engine.GetEntityTeam`

```lua
fun(handle:integer):integer
```

Entity team, -1 if not found

**Arguments:**
- `handle` — `integer`

**Returns:** `integer`

### `Engine.GetEntityOrigin`

```lua
fun(handle:integer):Vector3
```

World origin of entity

**Arguments:**
- `handle` — `integer`

**Returns:** `Vector3`

### `Engine.GetEntityEyeAngles`

```lua
fun(handle:integer):QAngle
```

Eye angles of player pawn

**Arguments:**
- `handle` — `integer`

**Returns:** `QAngle`

### `Engine.GetEntityName`

```lua
fun(handle:integer):string
```

Designer-name of entity

**Arguments:**
- `handle` — `integer`

**Returns:** `string`

### `Engine.IsPlayer`

```lua
fun(handle:integer):boolean
```

Entity is a citadel player pawn

**Arguments:**
- `handle` — `integer`

**Returns:** `boolean`

### `Engine.GetPlayers`

```lua
fun():table
```

Array of player pawn handles

**Returns:** `table`

### `Engine.GetBonePosition`

```lua
fun(handle:integer, slot:string):Vector3
```

First hitbox bone position for slot

**Arguments:**
- `handle` — `integer`
- `slot` — `string`

**Returns:** `Vector3`

### `Engine.WorldToScreen`

```lua
fun(pos:Vector3):table
```

Project world position to screen (returns {x,y,visible})

**Arguments:**
- `pos` — `Vector3`

**Returns:** `table`

### `Engine.GetScreenSize`

```lua
fun():table
```

Viewport size {w=number,h=number}

**Returns:** `table`

### `Engine.AngleVectors`

```lua
fun(angles:QAngle):Vector3
```

Forward vector from QAngle

**Arguments:**
- `angles` — `QAngle`

**Returns:** `Vector3`

### `Engine.GetProp`

```lua
fun(handle:integer, class:string, prop:string):any
```

Read a schema field: GetProp(handle, class, prop) or GetProp(handle, prop) with class auto-resolved

**Arguments:**
- `handle` — `integer`
- `class` — `string`
- `prop` — `string`

**Returns:** `any`

### `Engine.TraceLine`

```lua
fun(start:Vector3, end:Vector3, skip_handle:integer):table
```

Ray-cast between two points

**Arguments:**
- `start` — `Vector3`
- `end` — `Vector3`
- `skip_handle` — `integer`

**Returns:** `table`


## ImGui

_Immediate-mode UI bindings — windows, widgets, input, drawing_

### `ImGui.Begin`

```lua
fun(name:string, flags:integer?):boolean
```

Push a window scope

**Arguments:**
- `name` — `string`
- `flags` — `integer?`

**Returns:** `boolean`

### `ImGui.End`

```lua
fun():nil
```

Pop the current window

### `ImGui.WindowFlags_NoTitleBar`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoResize`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoScrollbar`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoInputs`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoBackground`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_AlwaysAutoResize`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoNav`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoDecoration`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoFocusOnAppearing`

```lua
integer
```

**Returns:** `integer`

### `ImGui.WindowFlags_NoSavedSettings`

```lua
integer
```

**Returns:** `integer`

### `ImGui.Text`

```lua
fun(text:string):nil
```

Draw text

**Arguments:**
- `text` — `string`

### `ImGui.Button`

```lua
fun(label:string, w:number, h:number):boolean
```

Render a button, returns true when clicked

**Arguments:**
- `label` — `string`
- `w` — `number`
- `h` — `number`

**Returns:** `boolean`

### `ImGui.SameLine`

```lua
fun():nil
```

Stay on the same line as the previous widget

### `ImGui.Separator`

```lua
fun():nil
```

Horizontal rule

### `ImGui.Spacing`

```lua
fun():nil
```

Add vertical spacing

### `ImGui.Checkbox`

```lua
fun(label:string, value:boolean):boolean,boolean
```

Returns (changed, new_value)

**Arguments:**
- `label` — `string`
- `value` — `boolean`

**Returns:** `boolean,boolean`

### `ImGui.BeginChild`

```lua
fun(id:string, w:number, h:number, border:boolean):boolean
```

Push a scrolling child region

**Arguments:**
- `id` — `string`
- `w` — `number`
- `h` — `number`
- `border` — `boolean`

**Returns:** `boolean`

### `ImGui.EndChild`

```lua
fun():nil
```

Pop the current child region

### `ImGui.SetNextWindowPos`

```lua
fun(x:number, y:number):nil
```

**Arguments:**
- `x` — `number`
- `y` — `number`

### `ImGui.SetNextWindowSize`

```lua
fun(w:number, h:number):nil
```

**Arguments:**
- `w` — `number`
- `h` — `number`

### `ImGui.SetNextWindowBgAlpha`

```lua
fun(a:number):nil
```

**Arguments:**
- `a` — `number`

### `ImGui.SetScrollHereY`

```lua
fun(ratio:number):nil
```

**Arguments:**
- `ratio` — `number`

### `ImGui.TextColored`

```lua
fun(r:number, g:number, b:number, a:number, text:string):nil
```

Coloured text

**Arguments:**
- `r` — `number`
- `g` — `number`
- `b` — `number`
- `a` — `number`
- `text` — `string`

### `ImGui.GetTime`

```lua
fun():number
```

Seconds since ImGui context creation

**Returns:** `number`

### `ImGui.IsKeyPressed`

```lua
fun(vk:integer):boolean
```

Was this key pressed this frame

**Arguments:**
- `vk` — `integer`

**Returns:** `boolean`

### `ImGui.IsKeyDown`

```lua
fun(vk:integer):boolean
```

Is this key currently held down

**Arguments:**
- `vk` — `integer`

**Returns:** `boolean`


## InputBitMask_t

### `InputBitMask_t.IN_NONE`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ATTACK`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_JUMP`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_DUCK`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_FORWARD`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_BACK`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_USE`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_MOVELEFT`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_MOVERIGHT`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ATTACK2`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_RELOAD`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_SPEED`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_WEAPON1`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ABILITY1`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ABILITY2`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ABILITY3`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ABILITY4`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ITEM1`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ITEM2`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ITEM3`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ITEM4`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ITEM5`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_ABILITY_HELD`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_INNATE_1`

```lua
integer
```

**Returns:** `integer`

### `InputBitMask_t.IN_CANCEL_ABILITY`

```lua
integer
```

**Returns:** `integer`


## Menu

_Cross-script widget discovery + typed getters/setters_

### `Menu.Find`

```lua
fun(script_or_label:string, label:string?):table?
```

Resolve a widget handle: Menu.Find(label) scans all scripts; Menu.Find(script, label) scopes; 5-arg legacy form returns a script handle

**Arguments:**
- `script_or_label` — `string`
- `label` — `string?`

**Returns:** `table?`

### `Menu.Get`

```lua
fun(script_or_label:string, label:string?):any
```

Read any widget's current value (kind-dispatched)

**Arguments:**
- `script_or_label` — `string`
- `label` — `string?`

**Returns:** `any`

### `Menu.Set`

```lua
fun(script_or_label:string, label:string?, value:any):nil
```

Write any widget's value (bool/int/float/string/color)

**Arguments:**
- `script_or_label` — `string`
- `label` — `string?`
- `value` — `any`

### `Menu.GetBool`

```lua
fun():boolean
```

Read a switch (script?, label)

**Returns:** `boolean`

### `Menu.GetInt`

```lua
fun():integer
```

Read int slider/combo/keybind (script?, label)

**Returns:** `integer`

### `Menu.GetFloat`

```lua
fun():number
```

Read float slider (script?, label)

**Returns:** `number`

### `Menu.GetKey`

```lua
fun():integer
```

Read keybind VK (script?, label)

**Returns:** `integer`

### `Menu.GetString`

```lua
fun():string
```

Read input-text (script?, label)

**Returns:** `string`

### `Menu.GetColor`

```lua
fun():table
```

Read color {r,g,b,a} (script?, label)

**Returns:** `table`

### `Menu.SetBool`

```lua
fun():nil
```

Write a switch (script?, label, v)

### `Menu.SetInt`

```lua
fun():nil
```

Write slider/combo/keybind (script?, label, v)

### `Menu.SetFloat`

```lua
fun():nil
```

Write float slider (script?, label, v)

### `Menu.SetKey`

```lua
fun():nil
```

Write keybind (script?, label, v)

### `Menu.SetString`

```lua
fun():nil
```

Write input-text (script?, label, s)

### `Menu.SetColor`

```lua
fun():nil
```

Write color (script?, label, {r,g,b,a})


## QAngle

_Pitch/Yaw/Roll orientation triplet_

### `QAngle.Forward`

```lua
fun():Vector3
```

Forward direction vector

**Returns:** `Vector3`

### `QAngle.Normalize`

```lua
fun():nil
```

Wrap each axis to [-180, 180] in place


## UI

_Legacy widget-store API — first arg is script name_

### `UI.AddSwitch`

```lua
fun(script:string, label:string, default:boolean):nil
```

Add a boolean toggle to a script's menu

**Arguments:**
- `script` — `string`
- `label` — `string`
- `default` — `boolean`

### `UI.AddSliderInt`

```lua
fun(script:string, label:string, min:integer, max:integer, default:integer):nil
```

Add an integer slider

**Arguments:**
- `script` — `string`
- `label` — `string`
- `min` — `integer`
- `max` — `integer`
- `default` — `integer`

### `UI.AddSliderFloat`

```lua
fun(script:string, label:string, min:number, max:number, default:number):nil
```

Add a float slider

**Arguments:**
- `script` — `string`
- `label` — `string`
- `min` — `number`
- `max` — `number`
- `default` — `number`

### `UI.AddKeybind`

```lua
fun():nil
```

Add a virtual-key bind capture

### `UI.AddCombo`

```lua
fun(script:string, label:string, options:string[], default:integer):nil
```

Add a combo dropdown

**Arguments:**
- `script` — `string`
- `label` — `string`
- `options` — `string[]`
- `default` — `integer`

### `UI.AddColor`

```lua
fun():nil
```

Add an RGBA color picker

### `UI.AddButton`

```lua
fun():nil
```

Add a button with click handler

### `UI.SetCategory`

```lua
fun(script:string, category:string):nil
```

Assign the script to a category tab

**Arguments:**
- `script` — `string`
- `category` — `string`

### `UI.SetTooltip`

```lua
fun():nil
```

Attach a hover tooltip to a widget

### `UI.GetBool`

```lua
fun(script:string, label:string):boolean
```

Read a switch's current value

**Arguments:**
- `script` — `string`
- `label` — `string`

**Returns:** `boolean`

### `UI.GetInt`

```lua
fun():integer
```

Read a slider/combo/keybind int value

**Returns:** `integer`

### `UI.GetFloat`

```lua
fun():number
```

Read a float slider value

**Returns:** `number`

### `UI.GetKey`

```lua
fun():integer
```

Read a keybind's virtual-key

**Returns:** `integer`

### `UI.SetBool`

```lua
fun():nil
```

Write a switch value

### `UI.SetInt`

```lua
fun():nil
```

Write a slider/combo/keybind int value

### `UI.SetFloat`

```lua
fun():nil
```

Write a float slider value

### `UI.SetKey`

```lua
fun():nil
```

Write a keybind's virtual-key

### `UI.SetString`

```lua
fun():nil
```

Write an input-text value

### `UI.SetColor`

```lua
fun():nil
```

Write an RGBA color picker

### `UI.Find`

```lua
fun():table?
```

Alias for Menu.Find

**Returns:** `table?`

### `UI.Get`

```lua
fun():any
```

Alias for Menu.Get

**Returns:** `any`

### `UI.Set`

```lua
fun():nil
```

Alias for Menu.Set


## Vector3

_3D vector — position, direction, velocity_

### `Vector3.new`

```lua
fun(x:number, y:number, z:number):Vector3
```

Construct a Vector3

**Arguments:**
- `x` — `number`
- `y` — `number`
- `z` — `number`

**Returns:** `Vector3`

### `Vector3.Length`

```lua
fun():number
```

Magnitude

**Returns:** `number`

### `Vector3.Length2D`

```lua
fun():number
```

Magnitude ignoring z

**Returns:** `number`

### `Vector3.Dot`

```lua
fun(other:Vector3):number
```

Dot product

**Arguments:**
- `other` — `Vector3`

**Returns:** `number`

### `Vector3.Cross`

```lua
fun(other:Vector3):Vector3
```

Cross product

**Arguments:**
- `other` — `Vector3`

**Returns:** `Vector3`

### `Vector3.Distance`

```lua
fun(other:Vector3):number
```

Distance to another vector

**Arguments:**
- `other` — `Vector3`

**Returns:** `number`

### `Vector3.Normalized`

```lua
fun():Vector3
```

Unit-length copy (zero vector returns zero)

**Returns:** `Vector3`

### `Vector3.ToAngles`

```lua
fun():QAngle
```

Direction to angle triplet

**Returns:** `QAngle`


## aimbot

_Read and write native aimbot settings by stable key_

### `aimbot.get`

```lua
fun(name:string):any
```

Read a native aimbot setting; nil for unknown key

**Arguments:**
- `name` — `string`

**Returns:** `any`

### `aimbot.set`

```lua
fun(name:string, value:any):boolean
```

Write a native aimbot setting; clamps ranges and returns success

**Arguments:**
- `name` — `string`
- `value` — `any`

**Returns:** `boolean`

### `aimbot.keys`

```lua
fun():string[]
```

List supported native setting keys

**Returns:** `string[]`

### `aimbot.get_psilent_fov`

```lua
fun():number
```

Read native pSilent FOV

**Returns:** `number`


## base64

_Base64 encode/decode_

### `base64.encode`

```lua
fun(data:string):string
```

Encode a string to base64

**Arguments:**
- `data` — `string`

**Returns:** `string`

### `base64.decode`

```lua
fun(data:string):string
```

Decode base64 (invalid chars skipped)

**Arguments:**
- `data` — `string`

**Returns:** `string`


## callbacks

_Event bus. Every function accepts (fn) or (script_name, fn)._

### `callbacks.on_pre_createmove`

```lua
fun(cmd:CUserCmd)
```

Before user command is sent

### `callbacks.on_post_createmove`

```lua
fun(cmd:CUserCmd)
```

After user command is sent

### `callbacks.on_frame`

```lua
fun()
```

Every frame after cmd sent

### `callbacks.on_render`

```lua
fun()
```

Every render frame (UI space)

### `callbacks.on_render_world`

```lua
fun()
```

Every render frame (world space)

### `callbacks.on_add_modifier`

```lua
fun(mod:table, ent:table)
```

Modifier added to any entity

### `callbacks.on_remove_modifier`

```lua
fun(mod:table, ent:table)
```

Modifier removed

### `callbacks.on_particle_create`

```lua
fun(data:table)
```

Particle system spawned

### `callbacks.on_bullet_create`

```lua
fun(bullet:table)
```

Bullet fired

### `callbacks.on_entity_create`

```lua
fun(handle:integer)
```

Entity added to world

### `callbacks.on_entity_destroy`

```lua
fun(handle:integer)
```

Entity removed from world

### `callbacks.on_local_spawn`

```lua
fun()
```

Local player pawn appeared

### `callbacks.on_local_death`

```lua
fun()
```

Local player pawn destroyed

### `callbacks.on_menu_open`

```lua
fun()
```

Cheat menu opened

### `callbacks.on_menu_close`

```lua
fun()
```

Cheat menu closed

### `callbacks.on_key_pressed`

```lua
fun(vk:integer)
```

Key went from up→down

### `callbacks.on_key_released`

```lua
fun(vk:integer)
```

Key went from down→up

### `callbacks.on_script_loaded`

```lua
fun()
```

This script just loaded

### `callbacks.on_script_unloaded`

```lua
fun()
```

This script is about to unload

### `callbacks.on_game_event`

```lua
fun(e:table)
```

Named game event — e:get_int("attacker") etc; valid only inside the callback


## config

_Per-script widget-value profiles (saved under Scripts/<name>/cfg)_

### `config.save`

```lua
fun(profile:string):bool
```

Save the current script's widget values as a profile

**Arguments:**
- `profile` — `string`

**Returns:** `bool`

### `config.load`

```lua
fun(profile:string):bool
```

Load a profile into the current script's widgets (becomes active)

**Arguments:**
- `profile` — `string`

**Returns:** `bool`

### `config.delete`

```lua
fun(profile:string):bool
```

Delete a saved profile

**Arguments:**
- `profile` — `string`

**Returns:** `bool`

### `config.list`

```lua
fun():table
```

Saved profile names for the current script

**Returns:** `table`

### `config.active`

```lua
fun():string
```

Currently active profile name (nil if none)

**Returns:** `string`


## cvar

_Console variable access_

### `cvar.find`

```lua
fun(name:string):table
```

Find a convar: get_int/get_float/get_bool/get_string (direct reads) + set_* via console

**Arguments:**
- `name` — `string`

**Returns:** `table`


## docs

_Documentation generator — emits vittlock.d.lua + API.md_

### `docs.generate`

```lua
fun():boolean
```

Regenerate vittlock.d.lua + API.md under <ScriptsPath>/_docs. Returns true on success.

**Returns:** `boolean`

### `docs.output_dir`

```lua
fun():string
```

Path where docs will be written

**Returns:** `string`

### `docs.namespaces`

```lua
fun():table
```

List of registered API namespaces

**Returns:** `table`

### `docs.list`

```lua
fun(ns:string):table
```

List bindings for a namespace

**Arguments:**
- `ns` — `string`

**Returns:** `table`


## entity_list

_Query interface for game entities_

### `entity_list.by_handle`

```lua
fun(h:integer):table
```

Wrap an entity by handle

**Arguments:**
- `h` — `integer`

**Returns:** `table`

### `entity_list.local_pawn`

```lua
fun():table
```

Wrap the local player pawn

**Returns:** `table`

### `entity_list.by_class_name`

```lua
fun(cls:string):table
```

All entities of a class

**Arguments:**
- `cls` — `string`

**Returns:** `table`

### `entity_list.enemies`

```lua
fun():table
```

All players on the enemy team

**Returns:** `table`

### `entity_list.allies`

```lua
fun():table
```

All players on your team (excludes self)

**Returns:** `table`


## fs

_Filesystem access, sandboxed to the Scripts folder_

### `fs.read`

```lua
fun(path:string):string
```

Read a file as a string (nil if missing/escape)

**Arguments:**
- `path` — `string`

**Returns:** `string`

### `fs.write`

```lua
fun(path:string, data:string):bool
```

Write a file (creates parent dirs); false on sandbox escape

**Arguments:**
- `path` — `string`
- `data` — `string`

**Returns:** `bool`

### `fs.append`

```lua
fun(path:string, data:string):bool
```

Append to a file (creates it if missing)

**Arguments:**
- `path` — `string`
- `data` — `string`

**Returns:** `bool`

### `fs.exists`

```lua
fun(path:string):bool
```

Path exists inside the sandbox

**Arguments:**
- `path` — `string`

**Returns:** `bool`

### `fs.remove`

```lua
fun(path:string):bool
```

Delete a file or directory tree (sandboxed)

**Arguments:**
- `path` — `string`

**Returns:** `bool`

### `fs.mkdir`

```lua
fun(path:string):bool
```

Create a directory (and parents)

**Arguments:**
- `path` — `string`

**Returns:** `bool`

### `fs.list`

```lua
fun(path:string):table
```

List a directory's entry names (nil if not a dir)

**Arguments:**
- `path` — `string`

**Returns:** `table`

### `fs.size`

```lua
fun(path:string):integer
```

File size in bytes (nil if not a regular file)

**Arguments:**
- `path` — `string`

**Returns:** `integer`


## hash

_Hashing helpers_

### `hash.crc32`

```lua
fun(data:string):integer
```

CRC-32 (IEEE) of a string

**Arguments:**
- `data` — `string`

**Returns:** `integer`


## input

_Mouse / keyboard state queries (polling)_

### `input.get_cursor_position`

```lua
fun():table
```

OS cursor position {x, y} in screen coords

**Returns:** `table`

### `input.is_button_down`

```lua
fun(vk:integer):bool
```

Virtual key / mouse button held (0x01 LMB, 0x02 RMB, 0x04 MMB)

**Arguments:**
- `vk` — `integer`

**Returns:** `bool`

### `input.is_key_down`

```lua
fun(vk:integer):bool
```

Alias of is_button_down

**Arguments:**
- `vk` — `integer`

**Returns:** `bool`

### `input.get_scroll`

```lua
fun():number
```

Vertical wheel delta for the current frame

**Returns:** `number`

### `input.get_screen_size`

```lua
fun():table
```

Game window size {x, y}

**Returns:** `table`


## json

_JSON encode/decode_

### `json.encode`

```lua
fun(value:any):string
```

Encode a Lua value to a JSON string (sequential tables = arrays; Vector3/QAngle = {x,y,z})

**Arguments:**
- `value` — `any`

**Returns:** `string`

### `json.decode`

```lua
fun(data:string):any
```

Parse a JSON string (nil on parse error)

**Arguments:**
- `data` — `string`

**Returns:** `any`


## log

_Per-script structured logger_

### `log.info`

```lua
fun():nil
```

Log an info-level message

### `log.warn`

```lua
fun():nil
```

Log a warning

### `log.error`

```lua
fun():nil
```

Log an error


## math

### `math.angle_vectors`

```lua
fun(angles:QAngle):Vector3
```

Convert QAngle to forward vector

**Arguments:**
- `angles` — `QAngle`

**Returns:** `Vector3`


## render

_Screen-space drawing on the foreground draw list_

### `render.line`

```lua
fun(x1:number, y1:number, x2:number, y2:number, r:number, g:number, b:number, a:number, thick:number):nil
```

Draw a line

**Arguments:**
- `x1` — `number`
- `y1` — `number`
- `x2` — `number`
- `y2` — `number`
- `r` — `number`
- `g` — `number`
- `b` — `number`
- `a` — `number`
- `thick` — `number`

### `render.rect`

```lua
fun():nil
```

Draw a rectangle outline

### `render.filled_rect`

```lua
fun():nil
```

Draw a filled rectangle

### `render.circle`

```lua
fun():nil
```

Draw a circle outline

### `render.text`

```lua
fun():nil
```

Draw text at screen coords

### `render.measure_text`

```lua
fun(size:number (optional), text:string):number, number
```

Measure text with the active font — (w,h) = measure_text([size,] text)

**Arguments:**
- `size` — `number (optional)`
- `text` — `string`

**Returns:** `number, number`

### `render.line_3d`

```lua
fun(a:Vector3, b:Vector3, r:number, g:number, b:number, a:number, thick:number):nil
```

World-space line (drawn when both endpoints project on screen)

**Arguments:**
- `a` — `Vector3`
- `b` — `Vector3`
- `r` — `number`
- `g` — `number`
- `b` — `number`
- `a` — `number`
- `thick` — `number`

### `render.text_3d`

```lua
fun(pos:Vector3, r:number, g:number, b:number, a:number, text:string):nil
```

Text anchored to a world position

**Arguments:**
- `pos` — `Vector3`
- `r` — `number`
- `g` — `number`
- `b` — `number`
- `a` — `number`
- `text` — `string`


## storage

_Per-script in-memory key-value store_

### `storage.set`

```lua
fun(key:string, value:any):nil
```

Set a value in the current script's storage

**Arguments:**
- `key` — `string`
- `value` — `any`

### `storage.get`

```lua
fun(key:string):any
```

Read a value; nil if unset

**Arguments:**
- `key` — `string`

**Returns:** `any`

### `storage.clear`

```lua
fun():nil
```

Wipe this script's storage


## timers

_Frame-driven scheduler: one-shots and intervals_

### `timers.after`

```lua
fun(ms:number, fn:function):integer
```

Fire once after N milliseconds. Returns timer id.

**Arguments:**
- `ms` — `number`
- `fn` — `function`

**Returns:** `integer`

### `timers.every`

```lua
fun(ms:number, fn:function):integer
```

Fire every N milliseconds until cancelled

**Arguments:**
- `ms` — `number`
- `fn` — `function`

**Returns:** `integer`

### `timers.cancel`

```lua
fun(id:integer):nil
```

Cancel a scheduled timer by id

**Arguments:**
- `id` — `integer`


## ui

_Modern menu API — no script name argument, fluent chain_

### `ui.script`

```lua
fun(name:string?):table
```

Get a menu handle for a script (default: current)

**Arguments:**
- `name` — `string?`

**Returns:** `table`


