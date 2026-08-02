# Widgets & menu

VITTLOCK scripts build their menu UI in Lua through three tiers: modern `ui.*`, legacy `UI.*`, and discovery/control `Menu.*`. All three resolve to the same widget store keyed by `(scriptName, label)`. This doc covers all three, the widget kinds, persistence, and how the master switch works.

---

## Three ways to declare a widget

| API | Style | Notes |
|---|---|---|
| `ui.script():switch(...)` | Modern, fluent, no script-name arg | New scripts |
| `UI.AddSwitch(script, ...)` | Legacy typed factory | Old scripts |
| `Menu.Switch / SliderInt / SliderFloat` | Shims in `BindLegacyShims.cpp` Lua shim | Pre-existing legacy scripts |

All result in the same widget store, keyed by `(scriptName, label)`.

---

## `ui` — modern fluent API

### `ui.script([name])` → menu handle

Returns a per-script menu handle. `name` defaults to `__SCRIPT_NAME__` and is rarely specified.

```lua
local m = ui.script()
```

### Handle methods — widget factories

All factories return a widget handle:

| Method | Signature | Description |
|---|---|---|
| `m:category(name)` | `m:category("Combat")` | Bucket the script under a tab; overrides subdir convention |
| `m:switch(label, default)` | `m:switch("Enabled", false)` → handle | Boolean toggle |
| `m:slider_int(label, min, max, default)` | `m:slider_int("Range", 0, 4096, 1200)` → handle | Integer slider |
| `m:slider_float(label, min, max, default)` | → handle | Float slider |
| `m:keybind(label, defaultVK)` | `m:keybind("Toggle", 0x2D)` → handle | Keybind capture |
| `m:combo(label, options, default)` | `m:combo("Mode", {"Safe","Fast","Insane"}, 0)` → handle | Dropdown — `default` is 0-indexed |
| `m:color(label, {r,g,b,a})` | `m:color("Tint", {1,0.4,0.2,1})` → handle | RGBA color picker; values 0..1 |
| `m:button(label, onClickFn)` | `m:button("Reset", function() ... end)` → handle | Click → fires fn |
| `m:input_text(label, capacity, [default])` | `m:input_text("Name", 32)` → handle | Text input |
| `m:group(label)` | nil | Header divider inside the popup body |
| `m:separator()` | nil | Thin horizontal rule |
| `m:tooltip(label, text)` | nil | Attach hover tooltip to a previously-created widget with that label |
| `m:find(label)` / `m:Find(label)` | handle | Same as `Menu.Find(label)` for this script |

### Full chain example

```lua
local m = ui.script()
m:category("Combat")

local enabled  = m:switch("Enabled", true)
local range    = m:slider_int("Range", 0, 4096, 1200)
local speed    = m:slider_float("Speed", 0.1, 5.0, 1.0)
local modeIdx  = m:combo("Mode", {"Safe", "Fast", "Insane"}, 0)
local tint     = m:color("Tint", {0.2, 1.0, 0.6, 1.0})
local toggleVK = m:keybind("Toggle key", 0x2D)   -- VK_INSERT
local buf      = m:input_text("Note", 64, "")
local labelFHx = m:button("Reset", function() storage.set("hits", 0) end)

m:separator()
m:group("Display")
m:tooltip("Tint", "RGBA in 0..1 range")
```

---

## Widget handle API

Every factory above returns a handle holding `(script, label)`. Store the local; reuse the value in every callback. Looking up by label via `Menu.Find` repeatedly works but is slower than storing the local.

### Getters

| Getter | Returns | Notes |
|---|---|---|
| `h:get()` / `h:Get()` | bool / int / float / string / color-table / nil | infers from `kind` |
| `h:get_bool()` / `h:GetBool()` | bool | always returns `bValue` |
| `h:get_int()` / `h:GetInt()` | int | `iValue` (combo index too) |
| `h:get_float()` / `h:GetFloat()` | number | `fValue` |
| `h:get_key()` / `h:GetKey()` | int | `iKey` (Win32 VK) |
| `h:get_string()` / `h:GetString()` | string | `strValue` |
| `h:get_color()` / `h:GetColor()` | table `{1,2,3,4}` | RGBA 0..1 |

### Setters

Inferring setter `h:set(val)` / `h:Set(val)`:

- `val.is<bool>` → sets `bValue`, mirrors `iValue`/`fValue` to `1`/`0`
- `val.is<int>` or `is<double>` → dispatches by `kind` (sliders clamp to known range, keybind writes `iKey`, generic writes `iValue` + `fValue`)
- `val.is<string>` → `strValue`
- `val` is a table → reads `key[1]..key[4]` as RGBA into the `color[4]` array
- Invokes `on_change` if set and the widget has it.

Explicit setters:

| Setter | Clamps |
|---|---|
| `h:set_bool(v)` | — |
| `h:set_int(v)` | to `min`/`max` *if both nonzero* |
| `h:set_float(v)` | to `minFloat`/`maxFloat` *if both nonzero* |
| `h:set_key(k)` | — |
| `h:set_string(s)` | — |
| `h:set_color({r,g,b,a})` | reads up to 4 entries, ignores missing |

⚠️ The `minInt!=0 && maxInt!=0` clamp gate means an int slider declared with `min=0, max=4096, default=10` will clamp correctly. But if you create a slider with both bounds set to zero (a degenerate case), the clamp is bypassed — corner case only.

### Reactive

| Reactive | Note |
|---|---|
| `h:on_change(fn)` | Sets the func; called after `set_*` and `set` whenever invokable. The function takes no args; read state via the getters. |

Use polling in `on_frame` rather than relying on `on_change` for now — it's dispatched synchronously from the setter, including from engine render, not from user input events.

---

## `UI` — legacy widget factory

Same widgets, first arg always the script name:

| Function | Returns |
|---|---|
| `UI.AddSwitch(script, label, default)` | factory only — handle via `UI.Find(script, label)` |
| `UI.AddSliderInt(script, label, min, max, default)` | factory only |
| `UI.AddSliderFloat(script, label, min, max, default)` | factory only |
| `UI.AddKeybind(script, label, defaultVK)` | factory only |
| `UI.AddCombo(script, label, optionsArray, default)` | factory only |
| `UI.AddColor(script, label, r, g, b, a)` | factory only |
| `UI.AddButton(script, label, onClickFn)` | factory only |
| `UI.AddText(script, label)` | factory only |
| `UI.AddSeparator(script)` | factory only |
| `UI.SetTooltip(script, label, text)` | setter |
| `UI.SetCategory(script, category)` | setter |
| `UI.Find(script, label)` / `UI.Find(label)` | handle |
| `UI.Get(script, label)` / `UI.Get(label)` | any |
| `UI.Set(script, label, val)` / `UI.Set(label, val)` | nil |
| `UI.GetBool/GetInt/GetFloat/GetKey(script, label)` | typed getters |
| `UI.SetBool/SetInt/SetFloat/SetKey/SetString/SetColor(script, label, val)` | typed setters |

Recorded example (matches what `CoordOverflow.lua` uses):

```lua
UI.SetCategory("CoordOverflow", "Movement")
UI.AddSwitch("CoordOverflow", "Enabled", false)
UI.AddKeybind("CoordOverflow", "Toggle Key", 0x56)

callbacks.on_frame(function("CoordOverflow", function()
    if not UI.GetBool("CoordOverflow", "Enabled") then return end
end))
```

---

## `Menu` — discovery & control

Find across any script and dynamically read/write widget state.

`Menu.Find` only searches widgets registered by Lua through `ui.script()` or `UI.Add*`. Native C++ controls such as pSilent FOV are not in this store; use the [native `aimbot` module](aimbot-settings.md) for those settings.

### Find & Get/Set

`Menu.Find(label)` is the primary discovery primitive. If only a label is passed, it first tries the current script, then falls back to `FindAny(label)` which scans all scripts. With two args `(script, label)` it scopes exactly.

```lua
local tl   = Menu.Find("Target Lock")  -- any script that defines a "Target Lock" widget
local dist = Menu.Find("Aimbot", "Max Distance")  -- explicit
local got  = Menu.Get("ESP", "Box Color")  -- read any value
Menu.Set("Movement", "Bhop Enabled", true)
Menu.Set("Auto Shoot", true)  -- finds any "Auto Shoot" widget across all scripts
```

### Typed getters & setters

Same as `UI.GetBool/...` (just different namespace):

```lua
Menu.GetBool(script, label)        → bool
Menu.GetInt(script, label)         → int
Menu.GetFloat(script, label)       → number
Menu.GetKey(script, label)         → int
Menu.GetString(script, label)      → string
Menu.GetColor(script, label)       → table {r,g,b,a}

Menu.SetBool(script, label, v)
Menu.SetInt(script, label, v)
Menu.SetFloat(script, label, v)
Menu.SetKey(script, label, k)
Menu.SetString(script, label, s)
Menu.SetColor(script, label, {r,g,b,a})
```

All of these also accept the single-label form for cross-script discovery — e.g. `Menu.SetBool("Auto Shoot", true)`.

### Legacy factories

```lua
Menu.Switch(cat, subcat, label, def)
Menu.SliderInt(cat, subcat, label, def, mn, mx)
Menu.SliderFloat(cat, subcat, label, def, mn, mx)
Menu.Slider = Menu.SliderInt
```

These shim the old `Menu.Switch(...)` style. The two `cat`/`subcat` args are accepted for legacy call compatibility but **ignored** — the script resolution uses `__SCRIPT_NAME__` directly:

```lua
-- Equivalent; both register under the current script
Menu.Switch("MyCategory", "MySubcat", "Auto Jump", false)
UI.AddSwitch(__SCRIPT_NAME__, "Auto Jump", false)
```

The original implementation hardcoded `"AutoCounterspell"` as the script name — that latent bug was fixed in the rewrite.

---

## Widget kinds

The widget types the engine recognises:

| Kind | Lua factory | Lua-side `h:get()` return |
|---|---|---|
| `Switch` | `m:switch`, `UI.AddSwitch` | bool |
| `SliderInt` | `m:slider_int`, `UI.AddSliderInt` | int |
| `SliderFloat` | `m:slider_float`, `UI.AddSliderFloat` | number |
| `Keybind` | `m:keybind`, `UI.AddKeybind` | int (VK) |
| `Combo` | `m:combo`, `UI.AddCombo` | int (selected index) |
| `Color3` / `Color4` | `m:color`, `UI.AddColor` | table `{r,g,b,a}` |
| `Button` | `m:button`, `UI.AddButton` | invoked fn (no value) |
| `InputText` | `m:input_text` | string |
| `Text` | `m:group`, `UI.AddText` (header labels use this via Header kind) | nil |
| `Header` | `m:group` | nil |
| `Separator` | `m:separator` | nil |
| `Tooltip` | `m:tooltip` | nil — attached to another widget by label |

`GroupBegin`/`GroupEnd` are listed in the enum but unused in the runtime today (no Lua factory).

---

## Master switch & gating

The script's master switch is whatever the **first** `Switch` widget added resolves to. After load, the engine reads the first switch's checked state and uses it as the script's enabled flag.

So when you do:

```lua
local enabled = m:switch("Enabled", false)
```

…your callbacks won't fire until `enabled` is `true`. If you skip a `Switch` widget entirely, the enabled flag defaults to `false` — meaning **no callbacks fire until one of your widgets is checked in the menu**. Always declare a master switch first.

When a user toggles the card in the menu, the runtime mirrors that toggle back into the script's enabled flag during the render pass — the next dispatch tick picks it up.

---

## Persistence

The engine saves:

- `LuaScriptsPath` (string)
- `LuaHotReload` (bool)
- `LuaScripts` object: per script's enabled state under `"Enabled"`
- The full widget set with all values (slider/combo/color/key/text)

That means widget values (sliders, combos, colors, keys, text) auto-persist across DLL restart. The keys are widget labels — so **renaming a label loses the saved value**. Definitions survive reload but the on-disk state for the old label becomes orphaned. If you want stable persistence across label renames in your own scripts, the engine doesn't expose a JSON-to-file loader — use the existing widget store, or pair `storage` with manual reload conventions on `on_script_loaded`.

---

## Runtime rendering pipeline

You don't call any render primitives for your widgets. The engine drives it:

1. The Lua Scripts menu lays out the header, status pills, controls row, and category tabs.
2. For each script, the render pass checks if the script has widgets:
   - **Has widgets** → card with accent bar + an expandable popup body lays out all the widgets.
   - **No widgets** → simple row with a single toggle bound to the script's enabled flag.
3. Right-click on the card opens a popup: **Reload** / **Open in editor**.
4. Errors panel collapses per-script errors at the bottom.

Inside the render, each widget is drawn by kind via the matching ImGui call (`Checkbox`, `SliderInt`, `SliderFloat`, `Combo`, `ColorEdit4`, `Button`, `InputText`, `Separator`, etc). `on_change` callbacks fire synchronously from set invocations during render; `on_click` fires when the button is pressed.

---

## Pitfalls

### Renaming a label

The widget store is keyed by `(scriptName, label)` pair. Renaming the label in your Lua code creates a new widget; the old persisted value is orphaned.

### First-widget-is-master surprise

If your first widget is a `slider_int` not a `switch`, the master switch defaults to `false` — no callbacks fire until you change a widget in the menu. Always start with a `switch` for the master enabled state.

### Cross-script label collisions

`m:switch("Enabled", false)` for two scripts in different categories collide in `Menu.Find("Enabled", ...)` (no script name qualifier, the search walks all scripts). Make labels unique across your own scripts if you want scripts to find each other's widgets.

### `on_change` not firing once per user click

It's wired through `set_*` calls — which all return `nil`. The runtime calls set during render, *then* `on_change`. So it does fire, but with no diff notion: `set_int(1200)` calling `set_int(1200)` still routes `on_change`. Filter for changes yourself inside the callback if you need deduplication.

### Calling `Menu.Set` from `on_pre_createmove`

Writes the widget's value, and `on_change` is dispatched synchronously *inside your cmd-pre callback*. That means the dispatched fn runs in your cmd-pre context, mid-lock. Keep `on_change` callbacks short and free of `cmd.*` writes.

### Combos store int

`combo` stored as `iValue`, which is the **0-indexed** selection. When you do `m:combo("Mode", {"A","B","C"}, 1)` the default is `{"A","B","C"}[1]` (zero-based → "B"). To convert back: `options[mode:get_int() + 1]`.

---

## See also

- [getting-started.md](getting-started.md) — first-script tutorial
- [examples/](../examples/) — runnable scripts using every widget kind
- [callbacks-events.md](callbacks-events.md) — gating & the master switch in detail
