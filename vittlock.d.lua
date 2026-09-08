-- vittlock.d.lua — auto-generated. Do not edit.
-- Provides EmmyLua type annotations for the VITTLOCK Lua API.
-- Point your Lua LSP `library` setting at the folder containing this file.

---@class CUserCmdNS
---@field GetCameraAngles fun():QAngle -- Current camera angles this tick
---@field SetCameraPosition fun(x:number, y:number, z:number):nil -- Override camera position (x,y,z)
---@field GetForwardMove fun():number -- Forward move axis (units/s)
---@field SetForwardMove fun(v:number):nil -- Set forward move axis
---@field AddButtonState fun(bit:integer):nil -- Hold a button (see InputBitMask_t)
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
---@field GetEntityModifiers fun(handle:integer):table[] -- Get all active modifier objects for an entity
---@field GetEntityTeam fun(handle:integer):integer -- Entity team, -1 if not found
---@field GetEntityOrigin fun(handle:integer):Vector3 -- World origin of entity
---@field GetEntityEyeAngles fun(handle:integer):QAngle -- Eye angles of player pawn
---@field GetEntityName fun(handle:integer):string -- Designer-name of entity
---@field IsPlayer fun(handle:integer):boolean -- Entity is a citadel player pawn
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
---@field Find fun(script_or_label:string, label:string?):table? -- Resolve a widget handle: Menu.Find(label) scans all scripts; Menu.Find(script, label) scopes; 5-arg legacy form returns a script handle
---@field Get fun(script_or_label:string, label:string?):any -- Read any widget's current value (kind-dispatched)
---@field Set fun(script_or_label:string, label:string?, value:any):nil -- Write any widget's value (bool/int/float/string/color)
---@field GetBool fun():boolean -- Read a switch (script?, label)
---@field GetInt fun():integer -- Read int slider/combo/keybind (script?, label)
---@field GetFloat fun():number -- Read float slider (script?, label)
---@field GetKey fun():integer -- Read keybind VK (script?, label)
---@field GetString fun():string -- Read input-text (script?, label)
---@field GetColor fun():table -- Read color {r,g,b,a} (script?, label)
---@field SetBool fun():nil -- Write a switch (script?, label, v)
---@field SetInt fun():nil -- Write slider/combo/keybind (script?, label, v)
---@field SetFloat fun():nil -- Write float slider (script?, label, v)
---@field SetKey fun():nil -- Write keybind (script?, label, v)
---@field SetString fun():nil -- Write input-text (script?, label, s)
---@field SetColor fun():nil -- Write color (script?, label, {r,g,b,a})
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
---@field on_remove_modifier fun(mod:table, ent:table) -- Modifier removed
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
---@field by_handle fun(h:integer):table -- Wrap an entity by handle
---@field local_pawn fun():table -- Wrap the local player pawn
---@field by_class_name fun(cls:string):table -- All entities of a class
---@field enemies fun():table -- All players on the enemy team
---@field allies fun():table -- All players on your team (excludes self)
entity_list = {}

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

