---@meta
-- Panorama UI: the panorama table, uipanel handles and file_spoofer.

---Find, create and change the game's Panorama UI panels.
---Every function except `sym2string` must run on the game thread (`on_frame` / `on_createmove`); elsewhere it raises an error.
---@class panorama
panorama = {}

---Returns the first panel whose id is exactly `id` (case-sensitive), searching every live panel.
---@param id string Panel id.
---@return uipanel? panel The panel, or nil when none matches.
function panorama.get_panel_by_id(id) end

---Returns the first panel of the given panel type (for example "Panel", "Label", "Image").
---@param panel_type string Panel type name.
---@return uipanel? panel The panel, or nil when none matches.
function panorama.get_panel_by_panel_type(panel_type) end

---Follows a path of ids: the first element is found like `get_panel_by_id`, each next one is a direct child id.
---@param path string[] Ids, outermost first. Non-string elements are skipped.
---@param log_error? boolean Accepted and ignored.
---@return uipanel? panel The panel at the end of the path, or nil when any step is missing or the path is empty.
function panorama.get_panel_by_path(path, log_error) end

---Creates a panel under `parent`.
---@param panel_type string Panel type, for example "Panel", "Label", "Image".
---@param id string Id of the new panel.
---@param parent uipanel Parent panel. Must be valid: check `parent:is_valid()` first.
---@param classes? string Space-separated classes to add.
---@param styles? string Inline style, for example "width: 10px; height: 10px;".
---@return uipanel? panel The new panel, or nil for an unknown panel type.
function panorama.create_panel(panel_type, id, parent, classes, styles) end

---Returns the name of a Panorama symbol id (class names, panel types). Does not check the thread.
---@param sym integer Symbol id (truncated to 16 bits).
---@return string name The name, or "" for an unknown or invalid id.
function panorama.sym2string(sym) end

---Shows the game's announcement banner with the default duration.
---@param title string Title text.
---@param message? string Description text (default "").
---@param class? string Class added to the announcement panel.
---@return boolean shown True when the announcement was created.
function panorama.show_game_announcement(title, message, class) end

---A handle to a Panorama panel. It goes invalid when the game deletes the panel.
---Every method except `is_valid` and `tostring` raises an error on a null, invalid or destroyed handle, when the UI engine is not available, or off the game thread.
---Two handles to the same panel are not `==`.
---@class uipanel
uipanel = {}

---True when the handle still points at a live panel. Never raises; false off the game thread.
---@return boolean valid
function uipanel:is_valid() end

---Returns the panel's id ("" when it has none).
---@return string id
function uipanel:get_id() end

---Sets the panel's id.
---@param id string
function uipanel:set_id(id) end

---True when the panel has a non-empty id.
---@return boolean
function uipanel:has_id() end

---Returns the panel type name, for example "Panel" or "Label".
---@return string panel_type
function uipanel:get_panel_type() end

---Returns the parent panel.
---@return uipanel? parent Nil for a root panel.
function uipanel:get_parent() end

---Finds a direct child by id.
---@param id string
---@return uipanel? child Nil when not found or `id` is empty.
function uipanel:find_child(id) end

---Finds a descendant (any depth) by id.
---@param id string
---@return uipanel? panel
function uipanel:find_child_traverse(id) end

---Finds the nearest ancestor with the given id.
---@param id string
---@return uipanel? panel
function uipanel:find_ancestor(id) end

---Finds a panel with the given id within this panel's layout file.
---@param id string
---@return uipanel? panel
function uipanel:find_child_in_layout_file(id) end

---Returns every descendant that has the class, in depth-first order (the panel itself excluded).
---@param class string
---@return uipanel[] panels 1-based array, empty when none.
function uipanel:find_children_with_class_traverse(class) end

---Follows a path of direct-child ids starting at this panel.
---@param path string[] Ids, outermost first. Non-string elements are skipped.
---@param with_logs? boolean When true, a warning naming the missing id goes to the script log.
---@return uipanel? panel Nil when any step is missing or the path is empty.
function uipanel:find_child_by_path(path, with_logs) end

---Returns the first direct child that has the class.
---@param class string
---@return uipanel? child
function uipanel:find_child_with_class(class) end

---Returns every descendant whose id is `id`, in depth-first order.
---@param id string
---@return uipanel[] panels 1-based array, empty when none.
function uipanel:find_children_with_id_traverse(id) end

---Returns the direct children in order.
---@return uipanel[] children 1-based array.
function uipanel:children() end

---Returns the number of direct children.
---@return integer count
function uipanel:get_child_count() end

---Returns a direct child by 0-based index.
---@param index integer 0-based index.
---@return uipanel? child Nil when out of range.
function uipanel:get_child(index) end

---Returns the first direct child.
---@return uipanel? child
function uipanel:get_first_child() end

---Returns the last direct child.
---@return uipanel? child
function uipanel:get_last_child() end

---Returns the 0-based index of a direct child.
---@param child uipanel
---@return integer index -1 when `child` is not a direct child.
function uipanel:get_child_index(child) end

---Returns the panel's laid-out width in pixels.
---@return number width
function uipanel:get_actual_layout_width() end

---Returns the panel's laid-out height in pixels.
---@return number height
function uipanel:get_actual_layout_height() end

---Shows or hides the panel.
---@param visible boolean
function uipanel:set_visible(visible) end

---Returns the panel's own visible flag (ancestors are not checked).
---@return boolean visible
function uipanel:is_visible() end

---Returns the panel's classes.
---@return string[] classes 1-based array.
function uipanel:get_class_list() end

---Adds one class.
---@param class string
function uipanel:add_class(class) end

---Removes one class.
---@param class string
function uipanel:remove_class(class) end

---Adds several classes.
---@param classes string Space-separated class names.
function uipanel:add_classes(classes) end

---Removes several classes.
---@param classes string Space-separated class names.
function uipanel:remove_classes(classes) end

---True when the panel has the class.
---@param class string
---@return boolean
function uipanel:has_class(class) end

---True when an ancestor of the panel has the class.
---@param class string
---@return boolean
function uipanel:ascendant_has_class(class) end

---Adds (`has` true) or removes (`has` false) a class.
---@param class string
---@param has boolean
function uipanel:set_has_class(class, has) end

---Removes the class and adds it again (restarts transitions or animations tied to it).
---@param class string
function uipanel:trigger_class(class) end

---Replaces the class previously set through `category` with `class`.
---@param category string Category name shared by the switched classes.
---@param class string The class to set.
function uipanel:switch_class(category, class) end

---Makes the panel draggable or not.
---@param draggable boolean
function uipanel:set_draggable(draggable) end

---True when the panel is draggable.
---@return boolean
function uipanel:is_draggable() end

---Returns a string attribute of the panel.
---@param name string Attribute name.
---@return string value "" when the attribute is not set.
function uipanel:get_attribute_string(name) end

---Sets a string attribute of the panel.
---@param name string Attribute name.
---@param value string
function uipanel:set_attribute_string(name, value) end

---Loads a layout file into the panel (replacing its children).
---@param path string Layout path, for example "file://{resources}/layout/....xml".
---@param override? boolean Allow replacing a layout that is already loaded (default false).
---@return boolean ok False when loading failed.
function uipanel:load_layout_file(path, override) end

---Applies an inline style string, like a `style` attribute in a layout file.
---@param style string For example "width: 10px; background-color: #ff00ff;".
---@return boolean ok
function uipanel:set_style(style) end

---Re-applies the panel's styles.
---@param traverse? boolean Also re-apply on the children (default false).
function uipanel:apply_styles(traverse) end

---Deletes all children of the panel. Their handles become invalid.
function uipanel:remove_and_delete_children() end

---Deletes the panel after `delay` seconds and clears this handle (later calls on it raise "null panel pointer").
---@param delay number Seconds; 0 deletes as soon as possible.
function uipanel:delete_async(delay) end

---Returns the text of a Label panel. Other panel types log a warning and return "".
---@return string text
function uipanel:get_text() end

---Sets the text of a Label panel. Other panel types log a warning and change nothing.
---@param text string
function uipanel:set_text(text) end

---Returns the image source of an Image, EconItemImage or CitadelHeroImage panel. Other types log a warning and return "".
---@return string src
function uipanel:get_image_src() end

---Returns the panel's top-left position in window pixels.
---@return Vec2 pos (0, 0) when unknown.
function uipanel:get_screen_position() end

---Returns the panel's position (window pixels) and laid-out size.
---@return Vec2 pos Top-left position, as `get_screen_position`.
---@return Vec2 size Width and height, as `get_actual_layout_width` / `get_actual_layout_height`.
function uipanel:get_bounds() end

---Runs Panorama JavaScript in the panel's JavaScript context. Nothing is returned.
---`$.GetContextPanel()` in the code is the layout root that owns the context, not necessarily this panel.
---@param code string JavaScript source.
function uipanel:run_script(code) end

---Supplies Panorama files (layouts, styles, scripts, SVGs) from memory: when the game opens a stored path, it reads the stored version.
---Paths are the compiled names with `/`, e.g. "panorama/layout/my_panel.vxml_c". Files stay until the game closes; adding a path again replaces it.
---@class file_spoofer
file_spoofer = {}

---Stores `content` (the source text, packed into the game's resource format for you) as the file `file_path`. `\` becomes `/`.
---Only affects what the game loads from then on; use `reload_resource` for a file already in use.
---@param file_path string The compiled path, e.g. "panorama/styles/my_panel.vcss_c".
---@param content string XML, CSS, JavaScript or SVG source.
---@return boolean ok Always true.
function file_spoofer.add_resource(file_path, content) end

---Adds every file under the folder, subfolders included, under its path relative to the folder.
---.xml / .css / .js / .svg become .vxml_c / .vcss_c / .vjs_c / .vsvg_c; other files keep their name; empty files are skipped.
---@param dir_path string Full path with a drive letter, e.g. "C:\\my_ui" (the folder that contains `panorama`).
---@return boolean ok False when the folder is missing or empty, or the path is not a full path.
function file_spoofer.add_folder(dir_path) end

---Makes the game reload a file it has already loaded (on the next frame), e.g. after `add_resource` replaced it.
---@param file_path string The compiled path, e.g. "panorama/layout/my_panel.vxml_c".
function file_spoofer.reload_resource(file_path) end
