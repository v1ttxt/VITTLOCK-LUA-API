-- vittlock.d.lua — auto-generated. Do not edit.
-- Provides EmmyLua type annotations for the VITTLOCK Lua API.
-- Point your Lua LSP `library` setting at the folder containing this file.

---@class CUserCmdNS
---@field GetCameraAngles fun():QAngle -- Current camera angles this tick
---@field GetCameraPosition fun():Vector3 -- Camera position in world space
---@field SetCameraPosition fun(x:number, y:number, z:number):nil -- Override camera position (x,y,z)
---@field GetForwardMove fun():number -- Forward move axis (units/s)
---@field SetForwardMove fun(v:number):nil -- Set forward move axis
---@field GetSideMove fun():number -- Lateral move axis (units/s)
---@field SetSideMove fun(v:number):nil -- Set lateral move axis
---@field SetUpMove fun(v:number):nil -- Set vertical impulse
---@field GetViewAngles fun():QAngle -- View angles for command tick
---@field SetViewAngles fun(ang:QAngle):nil -- Set view angles for command tick
---@field GetButtonState fun():integer -- Raw buttonstate1 bitmask (uint64)
---@field HasButtonState fun(bit:integer):boolean -- Test if button bit is held
---@field AddButtonState fun(bit:integer):nil -- Hold a button (see InputBitMask_t)
---@field RemoveButtonState fun(bit:integer):nil -- Clear a button
---@field HoldButton fun(bit:integer):nil -- Hold button for this tick
---@field PressButton fun(bit:integer):nil -- Press button this tick (cleared next frame)
---@field TapButton fun(bit:integer):nil -- Quick tap button
---@field ClearButton fun(bit:integer):nil -- Clear button
---@field add_buttonstate1 fun(bit:integer):nil -- Mutate button word 0 (Hold)
---@field add_buttonstate2 fun(bit:integer):nil -- Mutate button word 1
---@field add_buttonstate3 fun(bit:integer):nil -- Mutate button word 2
---@field buttonstate1 integer -- Button word 0 bitmask
---@field buttonstate2 integer -- Button word 1 bitmask
---@field buttonstate3 integer -- Button word 2 bitmask
---@field button_state0 integer -- Button word 0 bitmask
---@field button_state1 integer -- Button word 1 bitmask
---@field button_state2 integer -- Button word 2 bitmask
CUserCmd = {}

---@class DebuggerNS
---@field GetLogs fun():string -- Full log buffer text
---@field ClearLogs fun():nil -- Clear the debugger console
---@field SetClipboardText fun(text:string):nil -- Copy text to system clipboard
Debugger = {}

---@class EModifierStateNS
---@field <value> fun():integer -- 305 named integer constants — see Deadlock schema. Use e.g. EModifierState.MODIFIER_STATE_STUNNED.
EModifierState = {}

---@class EngineNS
---@field GetLocalVelocity fun():Vector3 -- Local player velocity (units/s)
---@field GetLocalMoveType fun():integer -- Local player MoveType_t
---@field GetLocalFlags fun():integer -- Local player m_fFlags
---@field GetCameraAngles fun():QAngle -- Local player camera angles
---@field HasModifierState fun(state:integer):boolean -- Local player has EModifierState
---@field EntityHasModifierState fun(handle:integer, state:integer):boolean -- Entity has EModifierState
---@field IsOnWall fun():boolean -- Local player is wall-jumping / wall-sliding
---@field GetTickInterval fun():number -- Server tick interval in seconds
---@field GetCurTime fun():number -- Game clock (seconds since server start)
---@field GetLocalPlayerHandle fun():integer -- Local player entity handle, -1 if none
---@field GetAirAccelerate fun():number -- Air-accelerate convar value (hardcoded 10)
---@field GetEntityAbility fun(handle:integer, name:string):table|nil -- Fetch ability table by designer-name / subclass substring / hash
---@field IsAbilityReady fun(handle:integer, name:string):boolean -- Check if ability or item is equipped and off cooldown
---@field CastAbility fun(cmd:CUserCmd, name:string):boolean -- Taps the exact button mask (IN_ABILITY1..4 / IN_ITEM1..4) for a named ability or item
---@field GetEntityAbilities fun(handle:integer):table[]|nil -- Fetch all ability tables for an entity
---@field GetProjectiles fun():table[] -- Returns array of active projectile entities in the world
---@field EntityHasModifier fun(handle:integer, name:string):boolean -- Entity has a named modifier
---@field GetModifierRemainingTime fun(handle:integer, name:string):number -- Remaining seconds of active modifier on entity, -1 if absent
---@field GetEntityModifiers fun(handle:integer):ModifierData[] -- Get all active modifier objects for an entity
---@field GetEntityTeam fun(handle:integer):integer -- Entity team, -1 if not found
---@field GetEntityOrigin fun(handle:integer):Vector3 -- World origin of entity
---@field GetEntityEyeAngles fun(handle:integer):QAngle -- Eye angles of player pawn
---@field GetEntityName fun(handle:integer):string -- Designer-name of entity
---@field IsPlayer fun(handle:integer):boolean -- Entity is a citadel player pawn
---@field GetEntityHealth fun(handle:integer):integer -- Current entity health
---@field GetEntityMaxHealth fun(handle:integer):integer -- Maximum entity health
---@field IsEntityAlive fun(handle:integer):boolean -- Check if entity is alive
---@field GetPlayers fun():table -- Array of player pawn handles
---@field GetBonePosition fun(handle:integer, slot:string):Vector3 -- First hitbox bone position for slot
---@field WorldToScreen fun(pos:Vector3):table -- Project world position to screen (returns {x,y,visible})
---@field GetScreenSize fun():table -- Viewport size {w=number,h=number}
---@field AngleVectors fun(angles:QAngle):Vector3 -- Forward vector from QAngle
---@field GetProp fun(handle:integer, class:string, prop:string):any -- Read a schema field: GetProp(handle, class, prop) or GetProp(handle, prop) with class auto-resolved
---@field TraceLine fun(start:Vector3, end:Vector3, skip_handle:integer):table -- Ray-cast between two points
Engine = {}

---@class ImGuiNS
---@field Begin fun(name:string, flags:integer?):boolean -- Push a window scope
---@field End fun():nil -- Pop the current window
---@field Text fun(text:string):nil -- Draw text
---@field Button fun(label:string, w:number, h:number):boolean -- Render a button, returns true when clicked
---@field SameLine fun():nil -- Stay on the same line as the previous widget
---@field Separator fun():nil -- Horizontal rule
---@field Spacing fun():nil -- Add vertical spacing
---@field Checkbox fun(label:string, value:boolean):boolean,boolean -- Returns (changed, new_value)
---@field BeginChild fun(id:string, w:number, h:number, border:boolean):boolean -- Push a scrolling child region
---@field EndChild fun():nil -- Pop the current child region
---@field SetNextWindowPos fun(x:number, y:number):nil
---@field SetNextWindowSize fun(w:number, h:number):nil
---@field SetNextWindowBgAlpha fun(a:number):nil
---@field SetScrollHereY fun(ratio:number):nil
---@field TextColored fun(r:number, g:number, b:number, a:number, text:string):nil -- Coloured text
---@field GetTime fun():number -- Seconds since ImGui context creation
---@field IsKeyPressed fun(vk:integer):boolean -- Was this key pressed this frame
---@field IsKeyDown fun(vk:integer):boolean -- Is this key currently held down
ImGui = {}

---@class InputBitMask_tNS
---@field IN_NONE integer
---@field IN_ATTACK integer
---@field IN_JUMP integer
---@field IN_DUCK integer
---@field IN_FORWARD integer
---@field IN_BACK integer
---@field IN_USE integer
---@field IN_MOVELEFT integer
---@field IN_MOVERIGHT integer
---@field IN_ATTACK2 integer
---@field IN_RELOAD integer
---@field IN_SPEED integer
---@field IN_WEAPON1 integer
---@field IN_ABILITY1 integer
---@field IN_ABILITY2 integer
---@field IN_ABILITY3 integer
---@field IN_ABILITY4 integer
---@field IN_ITEM1 integer
---@field IN_ITEM2 integer
---@field IN_ITEM3 integer
---@field IN_ITEM4 integer
---@field IN_ITEM5 integer
---@field IN_ABILITY_HELD integer
---@field IN_INNATE_1 integer
---@field IN_CANCEL_ABILITY integer
InputBitMask_t = {}

---@class MenuNS
---@field Create fun(tab:string, subtab:string?, section:string?, ...):MenuBuilder -- Fluent menu / category builder
---@field Switch fun(tab:string?, subtab:string?, label:string, default:boolean?, iconOrImage:string?):WidgetHandle
---@field SliderInt fun(tab:string?, subtab:string?, label:string, min:integer, max:integer, default:integer?):WidgetHandle
---@field SliderFloat fun(tab:string?, subtab:string?, label:string, min:number, max:number, default:number?):WidgetHandle
---@field Slider fun(tab:string?, subtab:string?, label:string, min:number, max:number, default:number?, fmt:string?):WidgetHandle
---@field Find fun(script_or_label:string, label:string?):WidgetHandle? -- Resolve a widget handle: Menu.Find(label) scans all scripts; Menu.Find(script, label) scopes
---@field Get fun(script_or_label:string, label:string?):any -- Read any widget's current value (kind-dispatched)
---@field Set fun(script_or_label:string, label:string?, value:any):nil -- Write any widget's value (bool/int/float/string/color)
---@field GetBool fun(script:string?, label:string):boolean -- Read a switch
---@field GetInt fun(script:string?, label:string):integer -- Read int slider/combo/keybind
---@field GetFloat fun(script:string?, label:string):number -- Read float slider
---@field GetKey fun(script:string?, label:string):integer -- Read keybind VK
---@field GetString fun(script:string?, label:string):string -- Read input-text
---@field GetColor fun(script:string?, label:string):table -- Read color {r,g,b,a}
---@field SetBool fun(script:string?, label:string, v:boolean):nil -- Write a switch
---@field SetInt fun(script:string?, label:string, v:integer):nil -- Write slider/combo/keybind
---@field SetFloat fun(script:string?, label:string, v:number):nil -- Write float slider
---@field SetKey fun(script:string?, label:string, v:integer):nil -- Write keybind
---@field SetString fun(script:string?, label:string, s:string):nil -- Write input-text
---@field SetColor fun(script:string?, label:string, c:table):nil -- Write color
Menu = {}

---@class QAngleNS
---@field Forward fun():Vector3 -- Forward direction vector
---@field Normalize fun():nil -- Wrap each axis to [-180, 180] in place
QAngle = {}

---@class UINS
---@field AddSwitch fun(script:string, label:string, default:boolean):nil -- Add a boolean toggle to a script's menu
---@field AddSliderInt fun(script:string, label:string, min:integer, max:integer, default:integer):nil -- Add an integer slider
---@field AddSliderFloat fun(script:string, label:string, min:number, max:number, default:number):nil -- Add a float slider
---@field AddKeybind fun():nil -- Add a virtual-key bind capture
---@field AddCombo fun(script:string, label:string, options:string[], default:integer):nil -- Add a combo dropdown
---@field AddColor fun():nil -- Add an RGBA color picker
---@field AddButton fun():nil -- Add a button with click handler
---@field SetCategory fun(script:string, category:string):nil -- Assign the script to a category tab
---@field SetTooltip fun():nil -- Attach a hover tooltip to a widget
---@field GetBool fun(script:string, label:string):boolean -- Read a switch's current value
---@field GetInt fun():integer -- Read a slider/combo/keybind int value
---@field GetFloat fun():number -- Read a float slider value
---@field GetKey fun():integer -- Read a keybind's virtual-key
---@field SetBool fun():nil -- Write a switch value
---@field SetInt fun():nil -- Write a slider/combo/keybind int value
---@field SetFloat fun():nil -- Write a float slider value
---@field SetKey fun():nil -- Write a keybind's virtual-key
---@field SetString fun():nil -- Write an input-text value
---@field SetColor fun():nil -- Write an RGBA color picker
---@field Find fun():table? -- Alias for Menu.Find
---@field Get fun():any -- Alias for Menu.Get
---@field Set fun():nil -- Alias for Menu.Set
UI = {}

---@class Vector3NS
---@field new fun(x:number, y:number, z:number):Vector3 -- Construct a Vector3
---@field Length fun():number -- Magnitude
---@field Length2D fun():number -- Magnitude ignoring z
---@field Dot fun(other:Vector3):number -- Dot product
---@field Cross fun(other:Vector3):Vector3 -- Cross product
---@field Distance fun(other:Vector3):number -- Distance to another vector
---@field Normalized fun():Vector3 -- Unit-length copy (zero vector returns zero)
---@field ToAngles fun():QAngle -- Direction to angle triplet
Vector3 = {}

---@class aimbotNS
---@field get fun(name:string):any -- Read a native aimbot setting; nil for unknown key
---@field set fun(name:string, value:any):boolean -- Write a native aimbot setting; clamps ranges and returns success
---@field keys fun():string[] -- List supported native setting keys
---@field get_psilent_fov fun():number -- Read native pSilent FOV
aimbot = {}

---@class base64NS
---@field encode fun(data:string):string -- Encode a string to base64
---@field decode fun(data:string):string -- Decode base64 (invalid chars skipped)
base64 = {}

---@class callbacksNS
---@field on_pre_createmove fun(cmd:CUserCmd) -- Before user command is sent
---@field on_post_createmove fun(cmd:CUserCmd) -- After user command is sent
---@field on_frame fun() -- Every frame after cmd sent
---@field on_render fun() -- Every render frame (UI space)
---@field on_render_world fun() -- Every render frame (world space)
---@field on_add_modifier fun(mod:table, ent:table) -- Modifier added to any entity
---@field on_remove_modifier fun(serial:integer) -- Modifier removed (serial number)
---@field on_particle_create fun(data:table) -- Particle system spawned
---@field on_bullet_create fun(bullet:table) -- Bullet fired
---@field on_entity_create fun(handle:integer) -- Entity added to world
---@field on_entity_destroy fun(handle:integer) -- Entity removed from world
---@field on_local_spawn fun() -- Local player pawn appeared
---@field on_local_death fun() -- Local player pawn destroyed
---@field on_menu_open fun() -- Cheat menu opened
---@field on_menu_close fun() -- Cheat menu closed
---@field on_key_pressed fun(vk:integer) -- Key went from up→down
---@field on_key_released fun(vk:integer) -- Key went from down→up
---@field on_script_loaded fun() -- This script just loaded
---@field on_script_unloaded fun() -- This script is about to unload
---@field on_game_event fun(e:table) -- Named game event — e:get_int("attacker") etc; valid only inside the callback
callbacks = {}

---@class configNS
---@field save fun(profile:string):bool -- Save the current script's widget values as a profile
---@field load fun(profile:string):bool -- Load a profile into the current script's widgets (becomes active)
---@field delete fun(profile:string):bool -- Delete a saved profile
---@field list fun():table -- Saved profile names for the current script
---@field active fun():string -- Currently active profile name (nil if none)
config = {}

---@class cvarNS
---@field find fun(name:string):table -- Find a convar: get_int/get_float/get_bool/get_string (direct reads) + set_* via console
cvar = {}

---@class docsNS
---@field generate fun():boolean -- Regenerate vittlock.d.lua + API.md under <ScriptsPath>/_docs. Returns true on success.
---@field output_dir fun():string -- Path where docs will be written
---@field namespaces fun():table -- List of registered API namespaces
---@field list fun(ns:string):table -- List bindings for a namespace
docs = {}

---@class entity_listNS
---@field by_handle fun(h:integer):EntityWrapper -- Wrap an entity by handle
---@field local_pawn fun():EntityWrapper -- Wrap the local player pawn
---@field by_class_name fun(cls:string, filter:any?):EntityWrapper[] -- All entities of a class
---@field enemies fun():EntityWrapper[] -- All players on the enemy team
---@field allies fun():EntityWrapper[] -- All players on your team (excludes self)
entity_list = {}
entities = entity_list

---@class game_rulesNS
---@field game_time fun():number -- Game clock seconds
game_rules = {}

---@class net_channelNS
---@field latency fun():number -- Current netchannel latency in seconds (0.03 default)
net_channel = {}

---@class fsNS
---@field read fun(path:string):string -- Read a file as a string (nil if missing/escape)
---@field write fun(path:string, data:string):bool -- Write a file (creates parent dirs); false on sandbox escape
---@field append fun(path:string, data:string):bool -- Append to a file (creates it if missing)
---@field exists fun(path:string):bool -- Path exists inside the sandbox
---@field remove fun(path:string):bool -- Delete a file or directory tree (sandboxed)
---@field mkdir fun(path:string):bool -- Create a directory (and parents)
---@field list fun(path:string):table -- List a directory's entry names (nil if not a dir)
---@field size fun(path:string):integer -- File size in bytes (nil if not a regular file)
fs = {}

---@class hashNS
---@field crc32 fun(data:string):integer -- CRC-32 (IEEE) of a string
hash = {}

---@class inputNS
---@field get_cursor_position fun():table -- OS cursor position {x, y} in screen coords
---@field is_button_down fun(vk:integer):bool -- Virtual key / mouse button held (0x01 LMB, 0x02 RMB, 0x04 MMB)
---@field is_key_down fun(vk:integer):bool -- Alias of is_button_down
---@field get_scroll fun():number -- Vertical wheel delta for the current frame
---@field get_screen_size fun():table -- Game window size {x, y}
input = {}

---@class jsonNS
---@field encode fun(value:any):string -- Encode a Lua value to a JSON string (sequential tables = arrays; Vector3/QAngle = {x,y,z})
---@field decode fun(data:string):any -- Parse a JSON string (nil on parse error)
json = {}

---@class logNS
---@field info fun():nil -- Log an info-level message
---@field warn fun():nil -- Log a warning
---@field error fun():nil -- Log an error
log = {}

---@class mathNS
---@field angle_vectors fun(angles:QAngle):Vector3 -- Convert QAngle to forward vector
math = {}

---@class renderNS
---@field line fun(x1:number, y1:number, x2:number, y2:number, r:number, g:number, b:number, a:number, thick:number):nil -- Draw a line
---@field rect fun():nil -- Draw a rectangle outline
---@field filled_rect fun():nil -- Draw a filled rectangle
---@field circle fun():nil -- Draw a circle outline
---@field text fun():nil -- Draw text at screen coords
---@field measure_text fun(size:number (optional), text:string):number, number -- Measure text with the active font — (w,h) = measure_text([size,] text)
---@field line_3d fun(a:Vector3, b:Vector3, r:number, g:number, b:number, a:number, thick:number):nil -- World-space line (drawn when both endpoints project on screen)
---@field text_3d fun(pos:Vector3, r:number, g:number, b:number, a:number, text:string):nil -- Text anchored to a world position
render = {}

---@class storageNS
---@field set fun(key:string, value:any):nil -- Set a value in the current script's storage
---@field get fun(key:string):any -- Read a value; nil if unset
---@field clear fun():nil -- Wipe this script's storage
storage = {}

---@class timersNS
---@field after fun(ms:number, fn:function):integer -- Fire once after N milliseconds. Returns timer id.
---@field every fun(ms:number, fn:function):integer -- Fire every N milliseconds until cancelled
---@field cancel fun(id:integer):nil -- Cancel a scheduled timer by id
timers = {}

---@class uiNS
---@field script fun(name:string?):table -- Get a menu handle for a script (default: current)
ui = {}

---@class Vector3
---@field x number
---@field y number
---@field z number
---@field Length fun(self:Vector3):number
---@field Length2D fun(self:Vector3):number

---@class QAngle
---@field x number
---@field y number
---@field z number

---@class EntityWrapper
---@field valid fun(self:EntityWrapper):boolean -- Valid entity handle (> 0)
---@field is_alive fun(self:EntityWrapper):boolean -- Life state == 0 and health > 0
---@field get_health fun(self:EntityWrapper):integer -- Current entity health
---@field get_max_health fun(self:EntityWrapper):integer -- Max entity health
---@field has_modifier_state fun(self:EntityWrapper, state:integer):boolean -- Checks EModifierState
---@field get_name fun(self:EntityWrapper):string -- Entity designer-name
---@field get_origin fun(self:EntityWrapper):Vector3 -- World origin
---@field get_handle fun(self:EntityWrapper):integer -- Raw integer handle
---@field get_ability fun(self:EntityWrapper, name:string):AbilityWrapper|nil -- Find ability table
---@field has_modifier fun(self:EntityWrapper, name:string):boolean -- Check active modifier by name
---@field get_modifiers fun(self:EntityWrapper):ModifierData[] -- Get all active modifier tables
---@field get_prop fun(self:EntityWrapper, propOrClass:string, maybeProp:string?):any -- Read schema field
---@field m_iHealth integer -- Current health
---@field m_iTeamNum integer -- Team number
---@field m_sPlayerDamageTaken table -- Damage taken info

---@class AbilityWrapper
---@field get_cooldown fun():number -- Binary cooldown (0 or 10)
---@field get_cooldown_end fun():number -- Cooldown end game time
---@field m_flCooldownEnd number -- Cooldown end time
---@field get_charges fun():integer -- Remaining charges
---@field get_stacks fun():integer -- Stacks (supports CItem_RestorativeLocket)
---@field m_nNumStacks integer -- Stack count
---@field get_toggle_state fun():boolean -- Active toggle state
---@field m_bToggleState boolean -- Toggle state
---@field get_slot fun():integer -- Slot index
---@field m_eAbilitySlot integer -- Slot enum value
---@field get_slot_name fun():string -- Human readable slot name
---@field get_button_name fun():string -- Button mask name ("IN_ABILITY1", etc.)
---@field get_button_mask fun():integer -- Button bitmask
---@field get_scaled_property fun(prop:string):number -- Read scaled ability property
---@field get_aoe_radius fun():number -- AoE radius
---@field cast fun(cmd:CUserCmd):boolean -- Cast via command buttons

---@class MenuBuilder
---@field Switch fun(self:MenuBuilder, label:string, default:boolean?, iconOrImage:string?):WidgetHandle
---@field Slider fun(self:MenuBuilder, label:string, min:number, max:number, default:number?, fmt:string?):WidgetHandle
---@field SliderInt fun(self:MenuBuilder, label:string, min:integer, max:integer, default:integer?):WidgetHandle
---@field SliderFloat fun(self:MenuBuilder, label:string, min:number, max:number, default:number?):WidgetHandle
---@field Combo fun(self:MenuBuilder, label:string, options:string[], default:integer?):WidgetHandle
---@field MultiCombo fun(self:MenuBuilder, label:string, options:string[], defaultMask:integer?):WidgetHandle
---@field Keybind fun(self:MenuBuilder, label:string, defaultVK:integer?):WidgetHandle
---@field Color fun(self:MenuBuilder, label:string, defaultColor:table?):WidgetHandle
---@field Button fun(self:MenuBuilder, label:string, fn:function):WidgetHandle
---@field Text fun(self:MenuBuilder, label:string):WidgetHandle
---@field Separator fun(self:MenuBuilder):nil

---@class WidgetHandle
---@field get fun(self:WidgetHandle):any
---@field Get fun(self:WidgetHandle):any
---@field set fun(self:WidgetHandle, val:any):nil
---@field Set fun(self:WidgetHandle, val:any):nil
---@field get_bool fun(self:WidgetHandle):boolean
---@field GetBool fun(self:WidgetHandle):boolean
---@field get_int fun(self:WidgetHandle):integer
---@field GetInt fun(self:WidgetHandle):integer
---@field get_float fun(self:WidgetHandle):number
---@field GetFloat fun(self:WidgetHandle):number
---@field get_key fun(self:WidgetHandle):integer
---@field GetKey fun(self:WidgetHandle):integer
---@field get_string fun(self:WidgetHandle):string
---@field GetString fun(self:WidgetHandle):string
---@field get_color fun(self:WidgetHandle):table
---@field GetColor fun(self:WidgetHandle):table
---@field ToolTip fun(self:WidgetHandle, text:string):WidgetHandle
---@field Tooltip fun(self:WidgetHandle, text:string):WidgetHandle
---@field tooltip fun(self:WidgetHandle, text:string):WidgetHandle
---@field Gear fun(self:WidgetHandle, label:string):MenuBuilder -- Adds settings gear sub-menu
---@field gear fun(self:WidgetHandle, label:string):MenuBuilder
---@field Icon fun(self:WidgetHandle, faGlyph:string):WidgetHandle -- FontAwesome icon
---@field icon fun(self:WidgetHandle, faGlyph:string):WidgetHandle
---@field Image fun(self:WidgetHandle, panoramaPath:string):WidgetHandle -- Panorama texture (e.g. panorama/images/items/...)
---@field image fun(self:WidgetHandle, panoramaPath:string):WidgetHandle
---@field SetCallback fun(self:WidgetHandle, fn:fun(w:WidgetHandle):nil, callImmediately:boolean?):WidgetHandle
---@field set_callback fun(self:WidgetHandle, fn:fun(w:WidgetHandle):nil, callImmediately:boolean?):WidgetHandle
---@field OnChange fun(self:WidgetHandle, fn:fun(w:WidgetHandle):nil):WidgetHandle
---@field on_change fun(self:WidgetHandle, fn:fun(w:WidgetHandle):nil):WidgetHandle
---@field On fun(self:WidgetHandle, fn:fun(w:WidgetHandle):nil):WidgetHandle
---@field Visible fun(self:WidgetHandle, visible:boolean):WidgetHandle
---@field visible fun(self:WidgetHandle, visible:boolean):WidgetHandle
---@field Depend fun(self:WidgetHandle, predicate:fun():boolean):WidgetHandle
---@field depend fun(self:WidgetHandle, predicate:fun():boolean):WidgetHandle

---@class ModifierVData
---@field m_eDebuffType integer -- Debuff type enum (1 = standard debuff)
---@field m_nAttributes integer -- Attribute bitmask flags

---@class ModifierData
---@field name string -- Modifier RTTI designer name
---@field creation number -- Creation time in game clock seconds
---@field duration number -- Total duration in seconds (<=0 if passive)
---@field elapsed number -- Elapsed seconds (curtime - creation)
---@field remaining number -- Remaining seconds (duration - elapsed)
---@field subclass_id integer -- Ability subclass ID
---@field m_iTeam integer -- Team number
---@field m_flDuration number -- Duration alias
---@field get_vdata fun():ModifierVData -- Debuff type and attribute information


