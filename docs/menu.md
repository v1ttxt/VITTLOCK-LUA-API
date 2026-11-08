# Menu

The `Menu` table lets a script build its own settings page inside the VITTLOCK menu: tabs, groups (cards) and widgets such as switches, sliders, key binds, dropdowns and colour pickers. Widget values are saved with the VITTLOCK config, so a script's settings survive restarts. Use it for anything the user should be able to configure; read the values from `on_frame` / `on_createmove` / `on_draw` with `widget:Get()`.

- [Where script menus appear](#where-script-menus-appear)
- [The tree](#the-tree)
- [Names, find-or-create and reloads](#names-find-or-create-and-reloads)
- [Saved values](#saved-values)
- [Callbacks](#callbacks)
- [Icons and images](#icons-and-images)
- [Tooltips, visibility and disabling](#tooltips-visibility-and-disabling)
- [Menu functions](#menu-functions)
- [Members of every node](#members-of-every-node)
- [Tabs](#tabs)
- [Groups and gears: widget constructors](#groups-and-gears-widget-constructors)
- [Members of every widget](#members-of-every-widget)
- [Widget classes](#widget-classes)
- [Menu.Style keys](#menustyle-keys)
- [Stored but not displayed](#stored-but-not-displayed)
- [Complete example](#complete-example)

## Where script menus appear

Every **first tab** a script creates becomes a page in the menu's **Lua** tab, listed next to the other Lua pages. Several scripts can add to the same first tab (for example two scripts both using `Menu.Create("Heroes", ...)` share one "Heroes" page). If another Lua page already has the same title, a suffix is added to the title.

A first tab named `"SettingsHidden"` gets no page. Widgets under it work and save their values, but the user never sees them: use it for hidden, persisted settings.

On a page:

- Sections, second tabs and third tabs are rows of selector pills (up to six per row; longer lists wrap). A level whose only entry has an empty name (`""`) shows no selector, so `Menu.Create("My Script", "", "", "", "Main")` gives a page with just one group and no selector rows. When a level has several entries, an empty name is shown as "General".
- The selected third tab's groups are cards in two columns. `Enum.GroupSide.Left` and `Enum.GroupSide.FullWidth` go to the left column, `Enum.GroupSide.Right` to the right; groups with the default side alternate left / right in creation order.
- Widgets are drawn in creation order. The menu's search box filters them by name and tooltip, like every other page.
- A page with no visible group shows a "No loaded script has a menu here." card.

## The tree

```
first tab          CFirstTab           Menu.Create("A")
 └ section         CTabSection         first:Create("B")
    └ second tab   CSecondTab          section:Create("C")
       └ third tab CThirdTab           second:Create("D")
          └ group  CMenuGroup          third:Create("E" [, side])
             └ widget                  group:Switch(...), group:Slider(...), ...
                ├ colour attachment    widget:ColorPicker("F")
                └ gear                 widget:Gear("G")
                   └ widget            gear:Switch(...), ...
```

Widgets can only be created in a group or a gear. Every level has a name; all five container levels must exist before a widget can be added, but you can name the levels you don't need `""` (see above).

`Menu.Create` builds several levels in one call and returns the deepest one:

```lua
local group = Menu.Create("My Script", "Main", "General", "Settings", "Options")
-- same as
local group = Menu.Create("My Script"):Create("Main"):Create("General"):Create("Settings"):Create("Options")
```

## Names, find-or-create and reloads

Every `Create` and every widget constructor is **find-or-create**: if a node with that name already exists under the same parent, it is returned unchanged (with its current value) instead of a new one. This is what makes reloads work: when a script runs again, its calls get back the same widgets and values.

- Names must be unique among the children of one parent, across all widget types. Creating a widget with the name of a sibling of another type turns that node into the new type (it loses its old value and callbacks).
- `Label(text)` uses its text as the name, so two labels with the same text in one group are the same label. Use `ForceLocalization` to change a label's text later.
- `Menu.Find(...)` and `node:Find(name)` only look up, never create. They see every node created by any script during this game session, including nodes from scripts that were unloaded.
- When all scripts reload (Reload All, the Reload Bind), only nodes created again by the new run are drawn. A removed script's page disappears; its saved values stay.
- Reloading a single script removes its callbacks; its widgets stay and are returned again when the script re-runs.
- Objects returned by the menu stay valid for the whole session; keeping them in upvalues across frames is safe. `==` compares two references to the same node, and `tostring(node)` gives its name.

On an existing widget, the constructor's default value is ignored. Some other arguments are applied on every call: slider range and format, combo / multi combo / multi select items (see each widget), icons, a group's side.

## Saved values

Widget values are stored in the VITTLOCK config, keyed by the widget's **path of names** from the first tab down (gear and attachment names included). They are written when the config is saved and read when it is loaded.

- A new widget first takes its default, then the saved value for its path if there is one. Renaming any level of the path starts over from the default.
- Saved values of widgets that don't exist (yet) are kept, so removing a script and adding it back restores its settings.
- Loading a config changes the values of existing widgets **without** running their callbacks. At game start the config can load after your script has run, so read `widget:Get()` when you need the value instead of copying it once at load time. If your script shows / hides widgets based on other values, re-apply that from `on_frame` too (see the example).
- Saved: switch state, slider value, colour, bind keys and toggle state, combo index, multi combo selection, multi select selection and order, input text. Buttons and labels have no value.
- `Set()` from Lua changes the value that will be saved, and runs no callback.

## Callbacks

`widget:SetCallback(fn [, callNow])` adds `fn`, which is called with the widget as its only argument every time **the user** changes the widget in the menu:

| Widget | Called when |
|---|---|
| Switch | toggled |
| Bind | a key is assigned or cleared |
| Slider | the value changes (an int slider only when the rounded value changes) |
| Colour picker / attachment | the colour is edited |
| Button | clicked |
| Combo, multi combo | the selection changes |
| Multi select | an item is toggled or the items are reordered |
| Input | the text is edited (every keystroke) |

- `Set()`, `Update()` and config loads never run callbacks.
- A widget can have several callbacks (from one or several scripts); they run in the order they were added. `UnsetCallback(fn)` removes one; pass the same function value.
- With `callNow` true the function also runs once immediately, which is handy to apply the initial state.
- Errors are caught and shown in the script's log; the menu keeps working.
- Callbacks run while the menu is being drawn, outside `on_frame` / `on_createmove`. Panorama functions are only allowed in those two callbacks, so set a flag in the menu callback and do Panorama work in `on_frame`.
- Callbacks of a disabled script are skipped.
- `Button(name, onClick)` replaces all of the button's callbacks each time it is called, including ones added with `SetCallback`.

## Icons and images

Widget constructors with an `icon` argument, and the `Icon` / `Image` / `ImageHandle` methods, accept two kinds of value:

- **A font icon glyph:** a single Font Awesome code point written as a Lua escape, for example `"\u{f00c}"` (check), `"\u{f013}"` (cog), `"\u{f05e}"` (ban). A string holding one character from U+0800 upward (every Font Awesome code point is) is treated as an icon.
- **An image:** anything else is an image path, usually a panorama path such as `"panorama/images/heroes/haze_sm_psd.vtex_c"` or `"panorama/images/icons/properties/melee.vsvg_c"`. `ImageHandle(handle)` takes an image loaded with [`Render.LoadImage`](render.md) and takes priority over a path.

Where they show in the current menu:

| Widget | Font icon | Image |
|---|---|---|
| Switch | yes | yes |
| Bind | yes | no |
| Button | yes (`Icon`) | no |
| Multi select items | no | yes (row image) |
| Other widgets, tabs | stored, not shown | stored, not shown |

The optional `size` argument of `Icon`, `Image` and `ImageHandle` is accepted and ignored.

## Tooltips, visibility and disabling

- `widget:ToolTip(text)` sets the tooltip; the menu shows it for switches, binds, sliders, combos, multi combos and multi selects. The search box also matches tooltip text.
- `node:Visible(false)` hides a tab (from its selector), a group, a widget, a gear or an attachment. A hidden widget's value still works and is still saved.
- `node:Disabled(true)` greys out a group (all its widgets), a widget, or a gear's contents. It has no effect on tabs.
- Both are getter / setter pairs: called with an argument they set and return nothing, called without one they return the current flag.

---

## Menu functions

### `Menu.Create(firstTab [, section [, secondTab [, thirdTab [, group]]]])`

Finds or creates each level of the path in turn and returns the deepest one. Also makes the first tab's page appear in the Lua tab.

| Name | Type | Description |
|---|---|---|
| firstTab | string | First tab (page) name |
| section | string? | Section name |
| secondTab | string? | Second tab name |
| thirdTab | string? | Third tab name |
| group | string? | Group name |

Returns `CFirstTab`, `CTabSection`, `CSecondTab`, `CThirdTab` or `CMenuGroup` depending on how many names were given; `nil` with no arguments. Arguments after the fifth, and everything from the first non-string argument on, are ignored.

Start your tree with `Menu.Create`; it is what registers the page. To set a group's column, create the group from its third tab: `third:Create("Options", Enum.GroupSide.Right)`.

```lua
local group = Menu.Create("My Script", "", "", "", "Main")
local on = group:Switch("Enabled", true)
```

### `Menu.Find(...)`

Looks up an existing node by its path of names: first tab, section, second tab, third tab, group, widget, attachment or gear, widget in a gear (up to eight names). Returns the node, or `nil` if any name along the path doesn't exist. Never creates anything.

```lua
local sw = Menu.Find("My Script", "", "", "", "Main", "Enabled")
if sw then print(sw:Get()) end
-- a widget inside the gear "Advanced" of the switch "Enabled"
local dbg = Menu.Find("My Script", "", "", "", "Main", "Enabled", "Advanced", "Debug Log")
```

### `Menu.Style([key])`

Returns the current menu theme colour for `key` as a [`Color`](types.md#color), or `nil` for an unknown key. Without a key, returns a table with the keys `primary`, `primary_widgets_text`, `shadow`, `main_background`, `outline`, `group_background`, `widget` and `text`. Colours follow the user's theme, so read them when drawing rather than once at load. See [Menu.Style keys](#menustyle-keys).

```lua
callback.on_draw:set(function()
    local accent = Menu.Style("accent")
    -- draw your HUD with accent ...
end)
```

### `Menu.Opened()`

Returns `true` while the menu is open.

### `Menu.Alpha()`

The menu's open / close fade from 0 (hidden) to 1 (fully shown). Multiply your own overlay's alpha by it to fade with the menu.

### `Menu.Pos()`

The menu window's top-left corner in screen pixels, as a `Vec2`. This is the position it was last drawn at.

### `Menu.Size()`

The menu window's width and height in pixels, as a `Vec2` (last drawn size).

### `Menu.Scale()`

The menu scale in percent, an integer from 100 to 200.

### `Menu.AnimDuration()`

The length of the menu's open / close fade in seconds (0.25).

---

## Members of every node

Every menu object (tabs, groups, gears, widgets and colour attachments) has these methods.

### `node:Name()`

The name the node was created with. This is the name used by `Find` and by saved values, even after `ForceLocalization`.

### `node:Parent()`

The parent node, or `nil` for a first tab. A gear's or attachment's parent is its widget.

### `node:Type()`

The node kind as an [`Enum.WidgetType`](enums.md) value: `MenuFirstTab`, `MenuSection`, `MenuSecondTab`, `MenuThirdTab`, `MenuGroup`, `MenuSwitch`, `MenuBind`, `MenuSliderFloat`, `MenuSliderInt`, `MenuColorPicker`, `MenuButton`, `MenuComboBox`, `MenuMultiComboBox`, `MenuGearAttachment`, `MenuInputBox`, `MenuMultiSelect`, `MenuLabel`. A colour attachment reports `MenuColorPicker`.

```lua
local function value_text(w)
    local t = w:Type()
    if t == Enum.WidgetType.MenuMultiComboBox or t == Enum.WidgetType.MenuMultiSelect then
        return table.concat(w:ListEnabled(), ", ")
    end
    return tostring(w:Get())
end
```

### `node:Open()`

Selects this node's section / second tab / third tab in their selectors and switches the menu to the Lua tab page that holds it. It does not open the menu if it is closed.

### `node:ForceLocalization(text)`

Shows `text` instead of the name (for a group: its card title; for a tab: its selector pill). The name used by `Find` and saved values doesn't change. A first tab's page title in the Lua tab always uses the name.

### `node:Visible([visible])`

With an argument, shows or hides the node and returns nothing. Without one, returns whether it is visible. See [Tooltips, visibility and disabling](#tooltips-visibility-and-disabling).

### `node:Disabled([disabled])`

With an argument, greys out the node and returns nothing. Without one, returns the flag. Affects groups, widgets and gears, not tabs.

---

## Tabs

### `CFirstTab`

A page in the Lua tab. Created by `Menu.Create(firstTab)`.

#### `first:Create(name)`

Finds or creates a section and returns its `CTabSection`.

#### `first:Find(name)`

The section with that name, or `nil`.

### `CTabSection`

#### `section:Create(name)`

Finds or creates a second tab and returns its `CSecondTab`.

#### `section:Find(name)`

The second tab with that name, or `nil`.

### `CSecondTab`

#### `second:Create(name)`

Finds or creates a third tab and returns its `CThirdTab`.

#### `second:Find(name)`

The third tab with that name, or `nil`.

#### `second:Image(path [, size])`, `second:ImageHandle(handle [, size])`, `second:Icon(glyph [, size])`

Store an image or icon for the tab. The current menu draws tab selectors as text only, so these have no visible effect yet.

#### `second:LinkHero(heroId [, attr])`

Stores a hero id (and attribute, default 0) for the tab. Not used by the current menu.

### `CThirdTab`

#### `third:Create(name [, side])`

Finds or creates a group and returns its `CMenuGroup`.

| Name | Type | Description |
|---|---|---|
| name | string | Group name (its card title) |
| side | integer? | `Enum.GroupSide.Default` (-1), `Left` (1), `Right` (2) or `FullWidth` (3). Applied on every call that passes it. |

`FullWidth` is currently placed in the left column like `Left`.

#### `third:Find(name)`

The group with that name, or `nil`.

#### `third:Image(path [, size])`, `third:ImageHandle(handle [, size])`, `third:Icon(glyph [, size])`

Same as on `CSecondTab`: stored, not displayed.

---

## Groups and gears: widget constructors

`CMenuGroup` (a card on the page) and `CMenuGearAttachment` (a widget's popup, see [`widget:Gear`](#widgetgearname--icon--smallfont)) have the same constructors. Each one finds or creates the widget by name and returns it.

### `group:Find(name)`

The widget (or gear / attachment, for a widget) with that name directly under this group or gear, or `nil`.

### `group:Switch(name [, default [, icon]])`

An on/off switch. Returns [`CMenuSwitch`](#cmenuswitch).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| default | boolean? | Initial value for a new switch (default `false`) |
| icon | string? | Font icon glyph or image path |

### `group:Bind(name [, default [, icon]])`

A key bind. Returns [`CMenuBind`](#cmenubind).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| default | integer? | An [`Enum.ButtonCode`](enums.md) value for a new bind (default -1, no key). Mouse buttons are `KEY_MOUSE1` to `KEY_MOUSE5`. |
| icon | string? | Font icon glyph or image path |

### `group:Slider(name, min, max [, default [, format]])`

A slider. If `min` and `max` are Lua integers (and `default` is an integer or omitted) it is an int slider ([`CMenuSliderInt`](#cmenusliderint)), otherwise a float slider ([`CMenuSliderFloat`](#cmenusliderfloat)). `Slider("X", 0, 10, 4)` is an int slider; `Slider("X", 0, 1, 0.5)` and `Slider("X", 0.0, 1.0)` are float sliders.

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| min | number | Lowest value (if `min > max` they are swapped) |
| max | number | Highest value |
| default | number? | Initial value for a new slider (default `min`) |
| format | string? | printf-style value text: `"%d"`, `"%d%%"`, `"%.1f s"`. Default shows whole numbers for int sliders, two decimals for float sliders. |

The range and format are applied on every call, and the value is clamped to the range.

### `group:ColorPicker(name [, default [, icon]])`

A colour picker row. Returns [`CMenuColorPicker`](#cmenucolorpicker).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| default | Color? | Initial colour for a new picker (default white, alpha 255) |
| icon | string? | Stored, not displayed |

### `group:Button(name [, onClick [, altStyle [, width]]])`

A button. Returns [`CMenuButton`](#cmenubutton).

| Name | Type | Description |
|---|---|---|
| name | string | Button text |
| onClick | function? | `fn(button)`, called on click. Replaces the button's callbacks on every call. |
| altStyle | boolean? | Stored, not displayed |
| width | number? | Fraction of the row, clamped to 0.05..1 (default 1). Stored, not displayed. |

Give a button an icon with `button:Icon("\u{f2f1}")`.

### `group:Combo(name, items [, default])`

A dropdown with one selected item. Returns [`CMenuComboBox`](#cmenucombobox).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| items | string[] | Item names |
| default | integer? | 0-based index selected in a new combo (default 0) |

If `items` differs from the current list, the list is replaced and the selected index is kept (clamped). A combo with no items is not drawn.

### `group:MultiCombo(name, items [, enabled])`

A dropdown where several items can be on. Returns [`CMenuMultiComboBox`](#cmenumulticombobox).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| items | string[] | Item names (the menu shows the first 32) |
| enabled | string[]? | Names of the items that start on |

If `items` differs from the current list, items that were already there keep their state and new ones are on if they are in `enabled`.

### `group:MultiSelect(name, rows [, expanded])`

A grid of toggleable items with images; the user clicks items to turn them on or off and, if allowed, drags them to reorder. Returns [`CMenuMultiSelect`](#cmenumultiselect).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| rows | table[] | One row per item: `{ name, imagePath, enabled }` or `{ nameId = ..., imagePath = ..., isEnabled = ... }` |
| expanded | boolean? | Stored, not displayed |

`enabled` / `isEnabled` must be a boolean `true` to start on. If the item names differ from the current list, existing items keep their state and position and new items are added at the end. With more than 32 items the grid becomes one checkbox row per item.

```lua
local heroes = group:MultiSelect("Track", {
    { "Haze", "panorama/images/heroes/haze_sm_psd.vtex_c", true },
    { nameId = "Infernus", imagePath = "panorama/images/heroes/inferno_sm_psd.vtex_c", isEnabled = false },
})
heroes:DragAllowed(true)
```

### `group:Input(name [, default [, icon]])`

A text field. Returns [`CMenuInputBox`](#cmenuinputbox).

| Name | Type | Description |
|---|---|---|
| name | string | Label |
| default | string? | Initial text for a new field (default `""`) |
| icon | string? | Stored, not displayed |

The menu edits up to 255 characters.

### `group:Label(text [, icon])`

A line of text. Returns [`CMenuLabel`](#cmenulabel). The text is also the label's name (see [Names](#names-find-or-create-and-reloads)).

### `group:SearchHidden([hidden])`

`CMenuGroup` only. Stores a flag and returns it when called without an argument. Not used by the current menu.

---

## Members of every widget

Switch, bind, sliders, colour picker, button, combo, multi combo, multi select, input and label all have the [node members](#members-of-every-node) plus these.

### `widget:ToolTip([text])`

With `text`, sets the tooltip and returns nothing. Without it, returns the current tooltip (`""` if none).

### `widget:Icon(glyph [, size])`, `widget:Image(path [, size])`, `widget:ImageHandle(handle [, size])`

Set the widget's icon or image. See [Icons and images](#icons-and-images) for which widgets show them.

### `widget:SetCallback(fn [, callNow])`

Adds `fn(widget)`, called every time the user changes the widget. See [Callbacks](#callbacks).

| Name | Type | Description |
|---|---|---|
| fn | function | Called with the widget |
| callNow | boolean? | Also call `fn` once right now (default `false`) |

```lua
local fov = group:Slider("FOV", 1, 30, 10, "%d deg")
fov:SetCallback(function(w)
    print("FOV is now " .. w:Get())
end)
```

### `widget:UnsetCallback(fn)`

Removes `fn` (the same function value passed to `SetCallback`).

### `widget:ColorPicker(name [, default])`

Finds or creates a colour picker attached to this widget, drawn as a colour row right under it. Returns [`CMenuColorPickerAttachment`](#cmenucolorpickerattachment). `default` is used for a new attachment (default white).

```lua
local box = group:Switch("Box", true)
local box_color = box:ColorPicker("Box Color", Color(255, 80, 80, 255))
```

### `widget:Gear(name [, icon [, smallFont]])`

Finds or creates this widget's gear: a popup holding more widgets. Returns [`CMenuGearAttachment`](#groups-and-gears-widget-constructors), which has the same constructors as a group.

| Name | Type | Description |
|---|---|---|
| name | string | Popup title. For widgets other than a switch, also the text of the row that opens the popup (the widget's name if empty). |
| icon | string? | Stored, not displayed |
| smallFont | boolean? | Stored, not displayed |

On a switch, the gear opens from a gear button at the end of the switch row. Only one gear per widget is drawn (the first visible one).

```lua
local esp = group:Switch("ESP", true)
local opts = esp:Gear("ESP Options")
local dist = opts:Slider("Max Distance", 10, 200, 80, "%d m")
```

### `widget:Unsafe([unsafe])`

Stores a flag and returns it when called without an argument. Not displayed by the current menu.

---

## Widget classes

### `CMenuSwitch`

#### `switch:Get()`

Returns `true` or `false`.

#### `switch:Set(on)`

Sets the value. No callback runs.

### `CMenuBind`

The bind's state (`IsDown`, `IsPressed`, `IsToggled`) is updated from the physical keys once per frame, right before `on_frame` runs, whether or not the menu is open. The menu assigns the first key; the second key can only be set from Lua.

#### `bind:Get([index])`

The first key's [`Enum.ButtonCode`](enums.md) value, or the second key's with `index` 1. -1 or 0 means no key.

#### `bind:Set(key1 [, key2])`

Sets both keys (`key2` defaults to 0, none). No callback runs.

#### `bind:Buttons()`

Returns both key codes: `key1, key2`.

#### `bind:IsDown()`

`true` while either key is held.

#### `bind:IsPressed()`

`true` on the frame either key went down, `false` otherwise. Poll it every frame (in `on_frame`) or you will miss presses.

#### `bind:IsToggled()`

A state that flips on every press. It is saved with the bind, so a toggle survives restarts.

#### `bind:SetToggled(toggled)`

Sets the toggle state.

```lua
local key = group:Bind("Activate", Enum.ButtonCode.KEY_LALT)
callback.on_frame:set(function()
    if key:IsPressed() then
        print("toggle is now " .. tostring(key:IsToggled()))
    end
end)
```

#### `bind:Properties([name [, value [, markToggle]]])`, `bind:ShowInBindIsland([show])`, `bind:MouseBinding([allow])`

Store display settings for the bind (`ShowInBindIsland` and `MouseBinding` default to `true` and return the flag when called without an argument). The current menu does not use them.

### `CMenuSliderInt`

#### `slider:Get()`

The value as a Lua integer.

#### `slider:Set(value)`

Sets the value, rounded and clamped to the range. No callback runs.

#### `slider:Update(min, max [, value])`

Changes the range (swapped if `min > max`). With `value`, also sets the value. The value is then clamped to the new range.

### `CMenuSliderFloat`

#### `slider:Get()`

The value as a number.

#### `slider:Set(value)`

Sets the value, clamped to the range. No callback runs.

#### `slider:Update(min, max [, value])`

Same as on `CMenuSliderInt`, without rounding.

### `CMenuColorPicker`

#### `picker:Get()`

The colour as a [`Color`](types.md#color).

#### `picker:Set(color)`

Sets the colour. No callback runs.

#### `picker:HideAlphaBar(hide)`

With `true`, alpha changes made in the picker are ignored: the colour keeps its current alpha.

### `CMenuColorPickerAttachment`

A colour row attached to a widget with `widget:ColorPicker`. It has the [node members](#members-of-every-node) and:

#### `attachment:Get()` / `attachment:Set(color)`

Read or set the colour (`Set` runs no callback).

#### `attachment:SetCallback(fn [, callNow])` / `attachment:UnsetCallback(fn)`

As on widgets: `fn(attachment)` runs when the user edits the colour. An error in the immediate `callNow` call is not reported in the log.

Attachments have no tooltip, icon, gear or nested attachments.

### `CMenuButton`

Has only the [widget members](#members-of-every-widget). Its callbacks run on click; set them with the `onClick` argument of `group:Button` or with `SetCallback`.

### `CMenuComboBox`

#### `combo:Get()`

The selected item's **0-based** index. Use `combo:List()[combo:Get() + 1]` for its name.

#### `combo:Set(index)`

Selects an item by 0-based index, clamped to the list. No callback runs.

#### `combo:List()`

The item names, in order.

#### `combo:Update(items [, index])`

Replaces the items. With `index`, also selects it. The selection is clamped to the new list.

### `CMenuMultiComboBox`

#### `multi:Get(item)`

`true` if the item with that name is on; `false` for items that are off or don't exist.

#### `multi:Set(items)` / `multi:Set(item [, on])`

With a table of names: exactly those items are on, all others off. With one name: sets that item (`on` defaults to `true`). Unknown names are ignored. No callback runs.

#### `multi:List()`

All item names in order.

#### `multi:ListEnabled()`

The names of the items that are on, in item order.

#### `multi:Update(items [, enabled])`

Replaces the items. Items that were already in the list keep their state; new ones are on if they are in `enabled`.

```lua
local targets = group:MultiCombo("Targets", { "Heroes", "Troopers", "Bosses" }, { "Heroes" })
if targets:Get("Bosses") then
    -- ...
end
```

### `CMenuMultiSelect`

Same `Get`, `Set`, `List` and `ListEnabled` as `CMenuMultiComboBox`, except that `List` and `ListEnabled` return items in **display order** (the order the user dragged them into). Use that order as a priority list.

#### `select:Update(rows [, expanded [, reapplySaved]])`

Replaces the rows (same format as `group:MultiSelect`). Existing items keep their state and position; new items are added at the end. With `reapplySaved` true, the selection and order saved in the config are applied again on top.

#### `select:OneItemSelection([one])`

With `true`, turning an item on turns the others off. Returns the flag, also when setting it.

#### `select:DragAllowed([allowed])`

With `true`, the user can drag items to reorder them (off by default). Returns the flag, also when setting it.

#### `select:UpdateToolTips(tips)`

Per-item tooltips: a list in item order (`{ "tip 1", "tip 2" }`) or a map by item name (`{ Haze = "..." }`). Shown only when the widget has more than 32 items (one row per item).

#### `select:UpdateImageColors(colors)`, `select:UpdateBackgroundColors(colors)`

Per-item colours, as a list or a map by name. Stored; not displayed by the current menu.

### `CMenuInputBox`

#### `input:Get()`

The text.

#### `input:Set(text)`

Sets the text. No callback runs.

### `CMenuLabel`

Has only the [widget members](#members-of-every-widget). Change the shown text with `label:ForceLocalization(text)`.

---

## Menu.Style keys

`Menu.Style(key)` returns the theme colour for any of these keys. Keys in the same row return the same colour.

| Keys | Colour |
|---|---|
| `primary`, `accent`, `slider_grab`, `slider_grab_active`, `slider_background_active`, `keybind_background_active`, `enabled_switch_background`, `button_active_background`, `indication_active`, `multiselect_item_selected`, `combo_item_active`, `selected_tabs_background`, `healthbar_roshan`, `healthbar_self` | Accent colour |
| `primary_widgets_text`, `white`, `primary_first_tab_text`, `primary_second_tab_text`, `active_widgets_text`, `search_text` | Bright text |
| `text`, `third_tab_text`, `section_group_text`, `indication_inactive`, `disabled_switch_circle` | Dim text |
| `shadow`, `widgets_shadow` | Black, about 42 % alpha |
| `text_shadow` | Black, about 70 % alpha |
| `main_background`, `background`, `left_tabs_background`, `additional_background`, `popup_background`, `hero_tab_filter_background` | Window background |
| `group_background`, `child` | Group card background |
| `widget`, `widget_background`, `slider_background`, `keybind_background`, `disabled_switch_background`, `button_background`, `input_text_bg`, `multiselect_item`, `combo_item`, `combo_frame`, `scrollbar_bg` | Widget background |
| `outline`, `border`, `group_outline`, `separator`, `popup_border`, `search_outline`, `hero_tab_filter_separator` | Outlines |
| `healthbar_enemy` | Fixed red `Color(222, 62, 62)` |
| `healthbar_ally` | Fixed green `Color(74, 196, 92)` |
| `manabar` | Fixed blue `Color(72, 132, 230)` |

Any other key returns `nil`.

## Stored but not displayed

These calls are accepted and remember their value (getters return it), but the current menu does not show them: `Icon` / `Image` / `ImageHandle` on tabs; images on widgets other than switches; icons on widgets other than switches, binds and buttons; `CSecondTab:LinkHero`; `CMenuGroup:SearchHidden`; `widget:Unsafe`; the `icon` and `smallFont` arguments of `Gear`; the `altStyle` and `width` arguments of `Button`; the `expanded` argument of `MultiSelect`; `CMenuMultiSelect:UpdateImageColors` / `UpdateBackgroundColors`; `CMenuBind:Properties` / `ShowInBindIsland` / `MouseBinding`. Scripts can call them safely.

---

## Complete example

A small settings page: one page whose section and second tab are left unnamed (no selector rows), two groups, a gear and an attached colour, plus the usual "show options only when they apply" logic.

```lua
-- scripts/v2/my_settings.lua
local page = Menu.Create("My Script", "", "", "Settings")
local main = page:Create("Main", Enum.GroupSide.Left)
local look = page:Create("Appearance", Enum.GroupSide.Right)

-- Main group
local enabled = main:Switch("Enabled", true, "\u{f00c}")
enabled:ToolTip("Turns the whole script on or off.")

local key = main:Bind("Hold Key", Enum.ButtonCode.KEY_LALT)
key:ToolTip("Only active while this key is held.")

local mode = main:Combo("Mode", { "Closest", "Lowest Health" }, 0)
local fov = main:Slider("FOV", 1, 30, 10, "%d deg")              -- int slider
local smooth = main:Slider("Smoothing", 0.0, 1.0, 0.25, "%.2f")  -- float slider
local targets = main:MultiCombo("Targets", { "Heroes", "Troopers", "Bosses" }, { "Heroes" })

-- A gear on the switch for rarely used options
local advanced = enabled:Gear("Advanced")
local debug_log = advanced:Switch("Debug Log", false)

-- Appearance group
local text_color = look:ColorPicker("Text Color", Color(255, 255, 255, 255))
local outline = enabled:ColorPicker("Outline", Color(0, 0, 0, 180))   -- colour row under "Enabled"
local prefix = look:Input("Prefix", "[My Script]")
look:Label("Changes apply immediately.")
look:Button("Reset", function()
    fov:Set(10)
    smooth:Set(0.25)
    mode:Set(0)
    targets:Set({ "Heroes" })
end):Icon("\u{f2f1}")

-- Show / grey out options depending on other options.
local function sync()
    local on = enabled:Get()
    for _, w in ipairs({ key, mode, fov, smooth, targets }) do
        w:Disabled(not on)
    end
    smooth:Visible(mode:Get() == 0)   -- smoothing only for "Closest"
end
enabled:SetCallback(sync, true)       -- also runs once now
mode:SetCallback(sync)

callback.on_frame:set(function()
    -- A config load changes values without callbacks: keep the page in sync while it is visible.
    if Menu.Opened() then
        sync()
    end

    if not enabled:Get() or not key:IsDown() then
        return
    end
    if key:IsPressed() and debug_log:Get() then
        local mode_name = mode:List()[mode:Get() + 1]
        print(prefix:Get() .. " active: " .. mode_name .. ", fov " .. fov:Get()
            .. ", targets " .. table.concat(targets:ListEnabled(), "/"))
    end
end)
```

All of these values (switches, bind, combo, sliders, multi combo, colours, text) are saved with the VITTLOCK config and come back after a restart.
