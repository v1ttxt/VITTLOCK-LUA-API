# Panorama UI

`panorama` finds and creates panels in the game's Panorama UI (the HUD, menus, scoreboard). Each panel comes back as a `uipanel` handle that you use to read the panel tree, change classes, styles, text and attributes, run Panorama JavaScript, or delete panels you made. Use it to add small UI elements to the HUD or change existing ones. [`file_spoofer`](#file_spoofer) supplies your own layout, style and script files for them.

## Rules

### Threading
Panorama calls work only on the game thread: call them from `on_frame` or `on_createmove`. Anywhere else, `on_draw` included, every `panorama.*` function (except `sym2string`) and every `uipanel` method raises:

```
attempt to call '<name>' off the game thread (use on_frame / on_createmove)
```

`uipanel:is_valid()` returns false off the game thread, and `tostring(panel)` returns `"<invalid panel>"`.

### Panel lifetime
A `uipanel` points at a panel that the game owns. The handle goes invalid when the game deletes that panel or one of its ancestors. This happens when the HUD is rebuilt, on map change, when you go between the main menu and a match, and when you call `delete_async` or `remove_and_delete_children` on it or a parent.

- `panel:is_valid()` never raises. Check it before you use a handle you kept from an earlier frame.
- Every other method checks the handle first and raises one of these errors:

| Error | Cause |
|---|---|
| `attempt to call '<name>' on null panel pointer` | The handle was cleared, for example by `delete_async`. |
| `attempt to call '<name>': UI Engine not available` | The UI is not available yet. |
| `attempt to call '<name>' on invalid or destroyed panel` | The game deleted the panel. |

- `panel:delete_async(delay)` clears the handle you called it on right away. Other handles to the same panel go invalid once the game deletes it.
- Validity is checked by address. Rarely, a stale handle can pass `is_valid()` because the game created a new panel in the old one's place. After a map change, look your panels up again instead of reusing old handles.

### Comparing handles
Each lookup returns a new handle, so two handles to the same panel are **not** `==`:

```lua
local a = panorama.get_panel_by_id("Hud")
local b = panorama.get_panel_by_id("Hud")
print(a == b)                      -- false
print(a:get_id() == b:get_id())    -- true: compare ids instead
```

### Indexes
`get_child` and `get_child_index` use 0-based indexes. Tables returned by `children`, `get_class_list` and the `find_children_*` methods are ordinary 1-based Lua arrays.

## panorama

### `panorama.get_panel_by_id(id)`
Searches every live panel and returns the first one whose id is exactly `id` (case-sensitive). Returns `nil` when none matches. If several panels share the id, which one you get is not defined.

```lua
callback.on_frame:set(function()
    local hud = panorama.get_panel_by_id("Hud")
    if hud then print(tostring(hud)) end
end)
```

### `panorama.get_panel_by_panel_type(panel_type)`
Returns the first live panel of the given type (for example `"Panel"`, `"Label"`, `"Image"`), or `nil`.

### `panorama.get_panel_by_path(path [, log_error])`
Finds `path[1]` the same way `get_panel_by_id` does, then each later element as a **direct** child id of the previous panel.

| Name | Type | Description |
|---|---|---|
| `path` | `string[]` | Ids, outermost first. Non-string elements are skipped. |
| `log_error` | `boolean?` | Accepted and ignored. |

Returns the last panel, or `nil` if any step is missing or the path is empty.

### `panorama.create_panel(panel_type, id, parent [, classes [, styles]])`
Creates a panel and attaches it to `parent`.

| Name | Type | Description |
|---|---|---|
| `panel_type` | `string` | Panel type: `"Panel"`, `"Label"`, `"Image"`, ... |
| `id` | `string` | Id of the new panel. |
| `parent` | `uipanel` | Parent panel. Required. |
| `classes` | `string?` | Space-separated classes to add. |
| `styles` | `string?` | Inline style, applied like `set_style`. |

Returns the new `uipanel`, or `nil` for an unknown panel type.

Notes:
- `parent` must be a live panel: a destroyed parent raises an error (`create_panel: parent panel is invalid or destroyed`). `nil` is not accepted.
- Panels you create stay until you delete them or the game deletes their parent. Use `delete_async` to clean up, for example when your script's menu option is turned off.

```lua
local box, label

callback.on_frame:set(function()
    if box and box:is_valid() then return end
    local hud = panorama.get_panel_by_id("Hud")
    if not hud then return end
    box = panorama.create_panel("Panel", "my_box", hud, "",
        "width: 200px; height: 40px; background-color: #00000099;")
    if not box then return end
    label = panorama.create_panel("Label", "my_label", box, "",
        "color: white; font-size: 20px; horizontal-align: center; vertical-align: center;")
    if label then label:set_text("Hello from Lua") end
end)
```

### `panorama.sym2string(sym)`
Returns the name of a Panorama symbol id (symbols name classes and panel types). `sym` is truncated to 16 bits. Unknown ids and `0xFFFF` return `""`. This is the only `panorama` function that does not check the thread.

### `panorama.show_game_announcement(title [, message [, class]])`
Shows the game's announcement banner for its default duration.

| Name | Type | Description |
|---|---|---|
| `title` | `string` | Title line. |
| `message` | `string?` | Description line (default `""`). |
| `class` | `string?` | Class added to the announcement panel, so you can style it. |

Returns `true` when the announcement was created, `false` when it could not be shown.

```lua
callback.on_frame:set(function()
    if input.is_pressed(Enum.ButtonCode.KEY_J) then
        panorama.show_game_announcement("Heads up", "Midboss is up")
    end
end)
```

## uipanel

You never construct a `uipanel` yourself. Lookups, `create_panel` and the tree methods return them. Call methods with `:`.

`tostring(panel)` gives a short description such as `<Panel id="my_box" class="a b">`, or `"<invalid panel>"` for a dead handle or off the game thread.

### `panel:is_valid()`
Returns `true` while the handle points at a live panel. Never raises. Returns `false` for a cleared or destroyed handle and off the game thread.

### Identity

#### `panel:get_id()`
Returns the panel id, or `""` when the panel has none.

#### `panel:set_id(id)`
Sets the panel id.

#### `panel:has_id()`
Returns `true` when the panel has a non-empty id.

#### `panel:get_panel_type()`
Returns the panel type name, for example `"Panel"`, `"Label"`, `"Image"`.

### Tree

#### `panel:get_parent()`
Returns the parent panel, or `nil` for a root.

#### `panel:find_child(id)`
Returns the **direct** child with that id, or `nil`. An empty `id` returns `nil`.

#### `panel:find_child_traverse(id)`
Searches all descendants (any depth) and returns the panel with that id, or `nil`.

#### `panel:find_ancestor(id)`
Walks up the parents and returns the nearest one with that id, or `nil`.

#### `panel:find_child_in_layout_file(id)`
Returns the panel with that id within this panel's layout file, or `nil`.

#### `panel:find_child_by_path(path [, with_logs])`
Starting at this panel, follows `path` one **direct** child id at a time.

| Name | Type | Description |
|---|---|---|
| `path` | `string[]` | Ids, outermost first. Non-string elements are skipped. |
| `with_logs` | `boolean?` | When `true`, a missing step writes a warning with that id to the script log. |

Returns the last panel, or `nil` if any step is missing or the path is empty.

#### `panel:find_child_with_class(class)`
Returns the first **direct** child that has `class`, or `nil`.

#### `panel:find_children_with_class_traverse(class)`
Returns every descendant that has `class`, depth-first, as a 1-based array. The panel itself is not included. The array is empty when nothing matches.

#### `panel:find_children_with_id_traverse(id)`
Returns every descendant whose id is `id`, depth-first, as a 1-based array.

#### `panel:children()`
Returns the direct children in order, as a 1-based array.

#### `panel:get_child_count()`
Returns the number of direct children.

#### `panel:get_child(index)`
Returns the direct child at the **0-based** `index`, or `nil` when the index is out of range.

#### `panel:get_first_child()` / `panel:get_last_child()`
Return the first or the last direct child, or `nil`.

#### `panel:get_child_index(child)`
Returns the 0-based index of `child` among this panel's direct children, or `-1` when it is not a direct child. `child` must be a `uipanel` (not `nil`).

```lua
-- Print the HUD's top-level children.
local done = false
callback.on_frame:set(function()
    if done then return end
    local hud = panorama.get_panel_by_id("Hud")
    if not hud then return end
    done = true
    for i, child in ipairs(hud:children()) do
        print(i - 1, child:get_panel_type(), child:get_id())
    end
end)
```

### Visibility, size and position

#### `panel:set_visible(visible)` / `panel:is_visible()`
Show or hide the panel, or read its visible flag. `is_visible` reads only this panel's own flag. It does not check whether an ancestor is hidden.

#### `panel:get_actual_layout_width()` / `panel:get_actual_layout_height()`
Return the laid-out size in pixels, as computed by Panorama's layout.

#### `panel:get_screen_position()`
Returns the top-left corner in window pixels as a `Vec2`, or `(0, 0)` when the position is not known.

#### `panel:get_bounds()`
Returns two `Vec2` values: the position (as `get_screen_position`) and the size (as the two layout getters).

```lua
local pos, size = panel:get_bounds()
print(("at %.0f,%.0f size %.0fx%.0f"):format(pos.x, pos.y, size.x, size.y))
```

#### `panel:set_draggable(draggable)` / `panel:is_draggable()`
Set or read whether the panel can be dragged.

### Classes

| Method | Description |
|---|---|
| `panel:get_class_list()` | Returns the panel's classes as a 1-based array of strings. |
| `panel:add_class(class)` | Adds one class. |
| `panel:remove_class(class)` | Removes one class. |
| `panel:add_classes(classes)` | Adds several space-separated classes. |
| `panel:remove_classes(classes)` | Removes several space-separated classes. Other classes stay. |
| `panel:has_class(class)` | Returns `true` when the panel has the class. |
| `panel:ascendant_has_class(class)` | Returns `true` when an ancestor of the panel has the class. |
| `panel:set_has_class(class, has)` | Adds the class when `has` is `true`, removes it when `false`. |
| `panel:trigger_class(class)` | Removes the class and adds it again, which restarts transitions or animations tied to it. |
| `panel:switch_class(category, class)` | Replaces the class previously set through `category` with `class`. |

### Attributes, style and layout

#### `panel:get_attribute_string(name)`
Returns the string attribute `name`, or `""` when it is not set.

#### `panel:set_attribute_string(name, value)`
Sets the string attribute `name` to `value`.

#### `panel:set_style(style)`
Applies an inline style string, the same way a `style="..."` attribute in a layout file does, for example `"width: 10px; background-color: #ff00ff;"`. Returns `true` on success.

#### `panel:apply_styles([traverse])`
Re-applies the panel's styles. Pass `true` to re-apply them on the children as well.

#### `panel:load_layout_file(path [, override])`
Loads a layout file into the panel and replaces its children.

| Name | Type | Description |
|---|---|---|
| `path` | `string` | Layout path, for example `"file://{resources}/layout/....xml"`. |
| `override` | `boolean?` | Must be `true` to replace a layout that is already loaded. |

Returns `false` when the file could not be loaded, or when a layout is already loaded and `override` is not `true`.

### Text and images

#### `panel:get_text()` / `panel:set_text(text)`
Read or set the text of a **Label** panel. On any other panel type they write a warning to the script log. `get_text` then returns `""` and `set_text` changes nothing.

#### `panel:get_image_src()`
Returns the image source of an `Image`, `EconItemImage` or `CitadelHeroImage` panel. Other types write a warning and return `""`.

### Deleting

#### `panel:remove_and_delete_children()`
Deletes every child of the panel. Handles to those children go invalid.

#### `panel:delete_async(delay)`
Deletes the panel after `delay` seconds (`0` = as soon as possible) and clears this handle at once: a later method call on it raises `... on null panel pointer`, and `is_valid()` returns `false`. Other handles to the panel go invalid once the game deletes it.

```lua
if box and box:is_valid() then
    box:delete_async(0)
end
box = nil
```

### JavaScript

#### `panel:run_script(code)`
Runs Panorama JavaScript in this panel's JavaScript context. Nothing is returned to Lua.

Inside the code, `$.GetContextPanel()` is the **layout root that owns the JavaScript context**, not the panel you called `run_script` on. This matters most for panels you created from Lua, which have no context of their own. To reach your panel from the script, look it up by id from the context panel:

```lua
-- box was created with id "my_box" somewhere under the HUD.
box:run_script("$.GetContextPanel().FindChildTraverse('my_box').AddClass('flash');")
```

## file_spoofer

`file_spoofer` lets a script supply its own Panorama files: layouts, styles, scripts and SVGs. A file you add is kept in memory, and whenever the game opens that path it reads your version instead of its own. Use it to give your panels their own layouts and stylesheets, or to replace one of the game's files.

Paths are the compiled names the game opens, with `/`: `panorama/layout/my_panel.vxml_c`, `panorama/styles/my_panel.vcss_c`. Here is how the game maps the URLs layouts use to those names:

- `panel:load_layout_file("file://{resources}/layout/my_panel.xml")` reads `panorama/layout/my_panel.vxml_c`.
- A stylesheet the layout includes as `file://{resources}/styles/my_panel.css` is read from `panorama/styles/my_panel.vcss_c`.

Added files stay until the game closes. Reloading scripts doesn't remove them, and adding a path again replaces its file. A replaced game file is replaced whole, so copy the original's content into yours if you only want to change part of it.

### `file_spoofer.add_resource(file_path, content)`

Stores `content` as the file `file_path`. `\` in the path becomes `/`. Pass the source text (XML, CSS, JavaScript or SVG) as you would write it; it is packed into the game's resource format for you. Returns `true`.

It only changes what the game loads from then on. A layout or stylesheet that is already loaded keeps its old version until it is loaded again or you call `reload_resource`.

| Name | Type | Description |
|---|---|---|
| `file_path` | `string` | The compiled path, e.g. `"panorama/styles/my_panel.vcss_c"`. |
| `content` | `string` | The source text. |

### `file_spoofer.add_folder(dir_path)`

Adds every file under a folder on disk, subfolders included.
- Each file's path in the game is its path relative to `dir_path`, with `/`.
- `.xml`, `.css`, `.js` and `.svg` become `.vxml_c`, `.vcss_c`, `.vjs_c` and `.vsvg_c`. Other files are added under their own name.
- Empty files are skipped, and so are files that can't be read (for example, ones another program has open for writing).

To get `panorama/...` paths, point `dir_path` at the folder that contains `panorama`:

```
C:\my_ui\panorama\layout\my_panel.xml   ->  panorama/layout/my_panel.vxml_c
C:\my_ui\panorama\styles\my_panel.css   ->  panorama/styles/my_panel.vcss_c
```

Returns `true` when the folder has at least one entry. Returns `false` when it is missing or empty, or when `dir_path` is not a full path.

| Name | Type | Description |
|---|---|---|
| `dir_path` | `string` | Full path of the folder, with a drive letter, e.g. `"C:\\my_ui"` (`/` works too). |

### `file_spoofer.reload_resource(file_path)`

Makes the game reload a file it has already loaded, so the panels built from it pick up the new version. Call it after `add_resource` to update a layout or stylesheet that is in use. The reload happens on the next frame. Returns nothing.

| Name | Type | Description |
|---|---|---|
| `file_path` | `string` | The compiled path, e.g. `"panorama/layout/my_panel.vxml_c"`. |

```lua
file_spoofer.add_resource("panorama/styles/my_panel.vcss_c", [[
.MyPanel { width: 300px; height: 48px; horizontal-align: center; margin-top: 140px; background-color: #202020dd; }
.MyLabel { color: white; font-size: 22px; horizontal-align: center; vertical-align: center; }
]])

local function layout(text)
    return ([[
<root>
    <styles><include src="file://{resources}/styles/my_panel.css" /></styles>
    <Panel class="MyPanel"><Label id="MyLabel" class="MyLabel" text="%s" /></Panel>
</root>]]):format(text)
end
file_spoofer.add_resource("panorama/layout/my_panel.vxml_c", layout("Hello"))

local host
callback.on_frame:set(function()
    if host and host:is_valid() then return end
    local hud = panorama.get_panel_by_id("Hud")
    if not hud then return end
    host = panorama.create_panel("Panel", "my_panel_host", hud, "", "width: 100%; height: 100%;")
    if host then
        host:load_layout_file("file://{resources}/layout/my_panel.xml", true)
    end
end)

-- Later: new text for the same layout.
local function retitle(text)
    file_spoofer.add_resource("panorama/layout/my_panel.vxml_c", layout(text))
    file_spoofer.reload_resource("panorama/layout/my_panel.vxml_c")
end
```
