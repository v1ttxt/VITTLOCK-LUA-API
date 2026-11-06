---@meta
-- Menu: script pages in the VITTLOCK menu (Lua tab): tabs, groups and widgets.

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared members (annotation-only base classes; not Lua globals)
-- ─────────────────────────────────────────────────────────────────────────────

---Members every menu object has (tabs, groups, widgets, attachments).
---Annotation helper only: there is no `MenuNode` table in Lua.
---@class MenuNode
local MenuNode = {}

---The node's name (the string it was created with; also its persistence key part).
---@return string name
function MenuNode:Name() end

---The parent node, or nil for a first tab.
---@return MenuNode? parent
function MenuNode:Parent() end

---The node kind as an `Enum.WidgetType` value. A colour attachment reports `MenuColorPicker`.
---@return Enum.WidgetType|integer type
function MenuNode:Type() end

---Selects this node's tabs in their selectors and switches the menu to the Lua tab page that holds it. Does not open a closed menu.
function MenuNode:Open() end

---Replaces the text shown in the menu. `Name()`, `Find` and saved values keep using the original name.
---@param text string
function MenuNode:ForceLocalization(text) end

---Shows or hides the node. Without an argument, returns whether it is visible.
---@param visible boolean
---@overload fun(self: MenuNode): boolean
function MenuNode:Visible(visible) end

---Greys out the node (groups, widgets, gear contents). Without an argument, returns the flag.
---@param disabled boolean
---@overload fun(self: MenuNode): boolean
function MenuNode:Disabled(disabled) end

---Members of nodes that take an image or icon.
---Annotation helper only.
---@class MenuImageNode : MenuNode
local MenuImageNode = {}

---Sets a panorama image path (for example `"panorama/images/heroes/haze_sm_psd.vtex_c"`). `size` is accepted and ignored.
---@param path string
---@param size? Vec2
function MenuImageNode:Image(path, size) end

---Sets an image loaded with `Render.LoadImage` (takes priority over `Image`). `size` is accepted and ignored.
---@param handle integer
---@param size? Vec2
function MenuImageNode:ImageHandle(handle, size) end

---Sets a font icon glyph, for example `"\u{f00c}"`. `size` is accepted and ignored.
---@param glyph string
---@param size? Vec2
function MenuImageNode:Icon(glyph, size) end

---Members every widget has (switch, bind, sliders, colour picker, button, combos, multi select, input, label).
---Annotation helper only.
---@class MenuWidget : MenuImageNode
local MenuWidget = {}

---Sets the tooltip shown for the widget. Without an argument, returns it.
---@param text string
---@overload fun(self: MenuWidget): string
function MenuWidget:ToolTip(text) end

---Stores an "unsafe" flag. Without an argument, returns it. The menu does not currently display it.
---@param unsafe boolean
---@overload fun(self: MenuWidget): boolean
function MenuWidget:Unsafe(unsafe) end

---Adds `fn(widget)`, called every time the user changes the widget in the menu. With `callNow` true, also calls it once right away.
---@param fn fun(widget: MenuWidget)
---@param callNow? boolean
function MenuWidget:SetCallback(fn, callNow) end

---Removes a function added with `SetCallback`.
---@param fn function
function MenuWidget:UnsetCallback(fn) end

---Finds or creates a colour picker attached to this widget (a colour row under it).
---@param name string
---@param default? Color defaults to white
---@return CMenuColorPickerAttachment
function MenuWidget:ColorPicker(name, default) end

---Finds or creates this widget's gear: a popup holding more widgets.
---@param name string popup title (and, for non-switch widgets, the label of the row that opens it)
---@param icon? string accepted and stored; not displayed
---@param smallFont? boolean accepted and stored; not displayed
---@return CMenuGearAttachment
function MenuWidget:Gear(name, icon, smallFont) end

---Widget constructors shared by groups and gears.
---Annotation helper only.
---@class MenuWidgetFactory : MenuNode
local MenuWidgetFactory = {}

---A direct child by name (widget, attachment or gear), or nil.
---@param name string
---@return MenuNode?
function MenuWidgetFactory:Find(name) end

---Finds or creates an on/off switch.
---@param name string
---@param default? boolean defaults to false
---@param icon? string font glyph or image path
---@return CMenuSwitch
function MenuWidgetFactory:Switch(name, default, icon) end

---Finds or creates a key bind.
---@param name string
---@param default? Enum.ButtonCode|integer defaults to -1 (no key)
---@param icon? string font glyph or image path
---@return CMenuBind
function MenuWidgetFactory:Bind(name, default, icon) end

---Finds or creates a slider. Integer `min`, `max` (and `default`) make an int slider, anything else a float slider. Range and format update on every call.
---@param name string
---@param min number
---@param max number
---@param default? number defaults to min
---@param format? string printf-style, e.g. "%d%%", "%.1f s"
---@return CMenuSliderInt|CMenuSliderFloat
function MenuWidgetFactory:Slider(name, min, max, default, format) end

---Finds or creates a colour picker row.
---@param name string
---@param default? Color defaults to white
---@param icon? string font glyph or image path
---@return CMenuColorPicker
function MenuWidgetFactory:ColorPicker(name, default, icon) end

---Finds or creates a button. Each call replaces the button's callbacks with `onClick`.
---@param name string
---@param onClick? fun(button: CMenuButton)
---@param altStyle? boolean accepted and stored; not displayed
---@param width? number fraction of the row, 0.05..1 (default 1); stored, not displayed
---@return CMenuButton
function MenuWidgetFactory:Button(name, onClick, altStyle, width) end

---Finds or creates a dropdown with one selected item. `default` is a 0-based index.
---@param name string
---@param items string[]
---@param default? integer 0-based, defaults to 0
---@return CMenuComboBox
function MenuWidgetFactory:Combo(name, items, default) end

---Finds or creates a dropdown where several items can be on.
---@param name string
---@param items string[]
---@param enabled? string[] items on by default
---@return CMenuMultiComboBox
function MenuWidgetFactory:MultiCombo(name, items, enabled) end

---@class MenuMultiSelectRow
---@field [1]? string item name
---@field [2]? string image path
---@field [3]? boolean on by default
---@field nameId? string item name (if [1] is nil)
---@field imagePath? string image path (if [2] is nil)
---@field isEnabled? boolean on by default (if [3] is nil)

---Finds or creates an image grid of toggleable items.
---@param name string
---@param rows MenuMultiSelectRow[]
---@param expanded? boolean accepted and stored; not displayed
---@return CMenuMultiSelect
function MenuWidgetFactory:MultiSelect(name, rows, expanded) end

---Finds or creates a text input.
---@param name string
---@param default? string defaults to ""
---@param icon? string font glyph or image path
---@return CMenuInputBox
function MenuWidgetFactory:Input(name, default, icon) end

---Finds or creates a line of text. The text is also the label's name.
---@param text string
---@param icon? string font glyph or image path
---@return CMenuLabel
function MenuWidgetFactory:Label(text, icon) end

-- ─────────────────────────────────────────────────────────────────────────────
-- Menu
-- ─────────────────────────────────────────────────────────────────────────────

---Script menus and menu state.
---@class Menu
Menu = {}

---Finds or creates a path of up to five levels (first tab, section, second tab, third tab, group) and returns the deepest one.
---@param firstTab string
---@return CFirstTab
---@overload fun(firstTab: string, section: string): CTabSection
---@overload fun(firstTab: string, section: string, secondTab: string): CSecondTab
---@overload fun(firstTab: string, section: string, secondTab: string, thirdTab: string): CThirdTab
---@overload fun(firstTab: string, section: string, secondTab: string, thirdTab: string, group: string): CMenuGroup
function Menu.Create(firstTab) end

---Looks up an existing node by its path of names (up to eight: first tab, section, second tab, third tab, group, widget, attachment, widget in a gear). Returns nil if any name is missing.
---@param ... string
---@return MenuNode?
function Menu.Find(...) end

---A menu theme colour by key, or nil for an unknown key. Without a key, a table of the eight main keys.
---@param key string
---@return Color?
---@overload fun(): table<string, Color>
function Menu.Style(key) end

---Whether the menu is open.
---@return boolean
function Menu.Opened() end

---The menu's open / close fade, 0 (hidden) to 1 (fully shown).
---@return number
function Menu.Alpha() end

---The menu window's top-left corner in screen pixels (last drawn position).
---@return Vec2
function Menu.Pos() end

---The menu window's width and height in pixels (last drawn size).
---@return Vec2
function Menu.Size() end

---The menu scale in percent (100..200).
---@return integer
function Menu.Scale() end

---Length of the menu's open / close fade in seconds (0.25).
---@return number
function Menu.AnimDuration() end

-- ─────────────────────────────────────────────────────────────────────────────
-- Tabs and groups
-- ─────────────────────────────────────────────────────────────────────────────

---A first tab: one page in the menu's Lua tab.
---@class CFirstTab : MenuNode
local CFirstTab = {}

---Finds or creates a section.
---@param name string
---@return CTabSection
function CFirstTab:Create(name) end

---A child section by name, or nil.
---@param name string
---@return CTabSection?
function CFirstTab:Find(name) end

---A section inside a first tab.
---@class CTabSection : MenuNode
local CTabSection = {}

---Finds or creates a second tab.
---@param name string
---@return CSecondTab
function CTabSection:Create(name) end

---A child second tab by name, or nil.
---@param name string
---@return CSecondTab?
function CTabSection:Find(name) end

---A second tab inside a section.
---@class CSecondTab : MenuImageNode
local CSecondTab = {}

---Finds or creates a third tab.
---@param name string
---@return CThirdTab
function CSecondTab:Create(name) end

---A child third tab by name, or nil.
---@param name string
---@return CThirdTab?
function CSecondTab:Find(name) end

---Stores a hero id (and attribute) for this tab. The menu does not currently use it.
---@param heroId integer
---@param attr? integer defaults to 0
function CSecondTab:LinkHero(heroId, attr) end

---A third tab inside a second tab; holds groups.
---@class CThirdTab : MenuImageNode
local CThirdTab = {}

---Finds or creates a group. `side` (when given) sets its column.
---@param name string
---@param side? Enum.GroupSide|integer
---@return CMenuGroup
function CThirdTab:Create(name, side) end

---A child group by name, or nil.
---@param name string
---@return CMenuGroup?
function CThirdTab:Find(name) end

---A group: a card on the page holding widgets.
---@class CMenuGroup : MenuWidgetFactory
local CMenuGroup = {}

---Stores a "hidden from search" flag. Without an argument, returns it. The menu does not currently use it.
---@param hidden boolean
---@overload fun(self: CMenuGroup): boolean
function CMenuGroup:SearchHidden(hidden) end

---A widget's gear: a popup holding more widgets. Has the same widget constructors as a group.
---@class CMenuGearAttachment : MenuWidgetFactory
local CMenuGearAttachment = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Widgets
-- ─────────────────────────────────────────────────────────────────────────────

---@class CMenuSwitch : MenuWidget
local CMenuSwitch = {}

---@return boolean on
function CMenuSwitch:Get() end

---Sets the value (no callback runs).
---@param on boolean
function CMenuSwitch:Set(on) end

---@class CMenuBind : MenuWidget
local CMenuBind = {}

---The first key (or the second with `index` 1), an `Enum.ButtonCode` value. -1 or 0 means no key.
---@param index? integer 0 (default) or 1
---@return integer code
function CMenuBind:Get(index) end

---Sets both keys (no callback runs).
---@param key1 Enum.ButtonCode|integer -1 for none
---@param key2? Enum.ButtonCode|integer defaults to 0 (none)
function CMenuBind:Set(key1, key2) end

---Both key codes.
---@return integer key1
---@return integer key2
function CMenuBind:Buttons() end

---True while either key is held.
---@return boolean
function CMenuBind:IsDown() end

---True on the frame either key went down.
---@return boolean
function CMenuBind:IsPressed() end

---A state that flips on every press. Saved with the widget's value.
---@return boolean
function CMenuBind:IsToggled() end

---@param toggled boolean
function CMenuBind:SetToggled(toggled) end

---Stores display properties for the bind. The menu does not currently display them.
---@param name? string
---@param value? string
---@param markToggle? boolean
function CMenuBind:Properties(name, value, markToggle) end

---Stores a flag (default true). Without an argument, returns it. The menu does not currently use it.
---@param show boolean
---@overload fun(self: CMenuBind): boolean
function CMenuBind:ShowInBindIsland(show) end

---Stores a flag (default true). Without an argument, returns it. The menu does not currently use it.
---@param allow boolean
---@overload fun(self: CMenuBind): boolean
function CMenuBind:MouseBinding(allow) end

---@class CMenuSliderInt : MenuWidget
local CMenuSliderInt = {}

---@return integer value
function CMenuSliderInt:Get() end

---Sets the value, rounded and clamped to the range (no callback runs).
---@param value number
function CMenuSliderInt:Set(value) end

---Changes the range; with `value`, also sets the value. The value is clamped to the new range.
---@param min number
---@param max number
---@param value? number
function CMenuSliderInt:Update(min, max, value) end

---@class CMenuSliderFloat : MenuWidget
local CMenuSliderFloat = {}

---@return number value
function CMenuSliderFloat:Get() end

---Sets the value, clamped to the range (no callback runs).
---@param value number
function CMenuSliderFloat:Set(value) end

---Changes the range; with `value`, also sets the value. The value is clamped to the new range.
---@param min number
---@param max number
---@param value? number
function CMenuSliderFloat:Update(min, max, value) end

---@class CMenuColorPicker : MenuWidget
local CMenuColorPicker = {}

---@return Color
function CMenuColorPicker:Get() end

---Sets the colour (no callback runs).
---@param color Color
function CMenuColorPicker:Set(color) end

---With true, alpha edits in the picker are ignored (the colour keeps its alpha).
---@param hide boolean
function CMenuColorPicker:HideAlphaBar(hide) end

---A colour picker attached to another widget (drawn as a colour row under it).
---@class CMenuColorPickerAttachment : MenuNode
local CMenuColorPickerAttachment = {}

---@return Color
function CMenuColorPickerAttachment:Get() end

---Sets the colour (no callback runs).
---@param color Color
function CMenuColorPickerAttachment:Set(color) end

---Adds `fn(attachment)`, called every time the user changes the colour. With `callNow` true, also calls it once right away.
---@param fn fun(attachment: CMenuColorPickerAttachment)
---@param callNow? boolean
function CMenuColorPickerAttachment:SetCallback(fn, callNow) end

---Removes a function added with `SetCallback`.
---@param fn function
function CMenuColorPickerAttachment:UnsetCallback(fn) end

---@class CMenuButton : MenuWidget
local CMenuButton = {}

---@class CMenuComboBox : MenuWidget
local CMenuComboBox = {}

---The selected item's 0-based index.
---@return integer index
function CMenuComboBox:Get() end

---Selects an item by 0-based index, clamped to the list (no callback runs).
---@param index integer
function CMenuComboBox:Set(index) end

---The item names in order.
---@return string[]
function CMenuComboBox:List() end

---Replaces the items. With `index`, also selects it (0-based); the selection is clamped to the new list.
---@param items string[]
---@param index? integer
function CMenuComboBox:Update(items, index) end

---@class CMenuMultiComboBox : MenuWidget
local CMenuMultiComboBox = {}

---Whether the item with this name is on (false for unknown names).
---@param item string
---@return boolean
function CMenuMultiComboBox:Get(item) end

---With a table: exactly these items are on. With a name: sets that item (default true). No callback runs.
---@param items string[]|string
---@param on? boolean
function CMenuMultiComboBox:Set(items, on) end

---All item names in order.
---@return string[]
function CMenuMultiComboBox:List() end

---The names of the items that are on, in item order.
---@return string[]
function CMenuMultiComboBox:ListEnabled() end

---Replaces the items. Items that were already in the list keep their state; new ones are on if listed in `enabled`.
---@param items string[]
---@param enabled? string[]
function CMenuMultiComboBox:Update(items, enabled) end

---@class CMenuMultiSelect : MenuWidget
local CMenuMultiSelect = {}

---Whether the item with this name is on (false for unknown names).
---@param item string
---@return boolean
function CMenuMultiSelect:Get(item) end

---With a table: exactly these items are on. With a name: sets that item (default true). No callback runs.
---@param items string[]|string
---@param on? boolean
function CMenuMultiSelect:Set(items, on) end

---All item names in display order.
---@return string[]
function CMenuMultiSelect:List() end

---The names of the items that are on, in display order.
---@return string[]
function CMenuMultiSelect:ListEnabled() end

---Replaces the rows (same row format as `MultiSelect`). Existing items keep their state and order. With `reapplySaved` true, the saved selection and order are applied again.
---@param rows MenuMultiSelectRow[]
---@param expanded? boolean stored; not displayed
---@param reapplySaved? boolean
function CMenuMultiSelect:Update(rows, expanded, reapplySaved) end

---With true, turning one item on turns the others off. Returns the flag (also when setting).
---@param one? boolean
---@return boolean
function CMenuMultiSelect:OneItemSelection(one) end

---With true, the user can drag items to reorder them. Returns the flag (also when setting).
---@param allowed? boolean
---@return boolean
function CMenuMultiSelect:DragAllowed(allowed) end

---Per-item tooltips: a list in item order or a map by item name. Shown only when the widget has more than 32 items.
---@param tips table<integer|string, string>
function CMenuMultiSelect:UpdateToolTips(tips) end

---Per-item image colours (list or map by name). Stored; not displayed.
---@param colors table<integer|string, Color>
function CMenuMultiSelect:UpdateImageColors(colors) end

---Per-item background colours (list or map by name). Stored; not displayed.
---@param colors table<integer|string, Color>
function CMenuMultiSelect:UpdateBackgroundColors(colors) end

---@class CMenuInputBox : MenuWidget
local CMenuInputBox = {}

---@return string text
function CMenuInputBox:Get() end

---Sets the text (no callback runs).
---@param text string
function CMenuInputBox:Set(text) end

---@class CMenuLabel : MenuWidget
local CMenuLabel = {}
