---@meta
-- Render: 2D drawing, text and fonts, images and SVG, render targets, notifications.

---A font handle from `Render.LoadFont` / `Render.LoadGameFont`. `0` (or `nil`) is the default font.
---@alias FontHandle integer

---An image handle from `Render.LoadImage`, `Render.LoadMaskedImage`, `Render.LoadSvg` or `Render.LoadSvgString`. `0` is "no image".
---@alias ImageHandle integer

---A render target handle from `Render.FindOrCreateRT`.
---@alias RenderTarget integer

---One corner of a `Render.TexturedPoly` polygon: a screen position and a texture coordinate.
---@class Vertex
---@field pos Vec2 Screen position in pixels.
---@field uv Vec2 Texture coordinate, 0-1 across the image.
---@overload fun(pos?: Vec2, uv?: Vec2): Vertex
Vertex = {}

---2D drawing on the screen. Drawing functions only draw inside `callback.on_draw`; anywhere else they do nothing.
---@class Render
Render = {}

-- ── Drawing primitives ──────────────────────────────────────────────────────

---Draws a filled rectangle between two corners.
---@param from Vec2 Top-left corner (screen pixels).
---@param to Vec2 Bottom-right corner (screen pixels).
---@param color Color Fill colour.
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits (default: all corners when rounded).
function Render.FilledRect(from, to, color, rounding, flags) end

---Draws a rectangle outline between two corners.
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param color Color Line colour.
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
---@param thickness? number Line thickness in pixels (default 1).
function Render.Rect(from, to, color, rounding, flags, thickness) end

---Draws part of a rounded rectangle's outline, starting at the top-left corner and going clockwise.
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param color Color Line colour.
---@param percent number How much of the outline to draw, 0-1.
---@param rounding number Corner radius in pixels.
---@param thickness? number Line thickness in pixels (default 1).
function Render.RoundedProgressRect(from, to, color, percent, rounding, thickness) end

---Draws a line.
---@param from Vec2 Start point.
---@param to Vec2 End point.
---@param color Color Line colour.
---@param thickness? number Line thickness in pixels (default 1).
function Render.Line(from, to, color, thickness) end

---Draws an open line through a list of points.
---@param points Vec2[] At least two points.
---@param color Color Line colour.
---@param thickness? number Line thickness in pixels (default 1).
function Render.PolyLine(points, color, thickness) end

---Draws a circle outline, or an arc when `percentage` is below 1.
---@param pos Vec2 Centre.
---@param radius number Radius in pixels.
---@param color Color Line colour.
---@param thickness? number Line thickness in pixels (default 1).
---@param start_deg? number Arc start angle in degrees, 0 = right, 90 = down (default 0).
---@param percentage? number Part of the circle to draw, 0-1 (default 1), clockwise from `start_deg`.
---@param rounded? boolean Round caps at the arc's ends (default false).
---@param segments? integer Segment count for a full circle (default 32, at least 3).
function Render.Circle(pos, radius, color, thickness, start_deg, percentage, rounded, segments) end

---Draws a filled circle, or a pie slice when `percentage` is below 1.
---@param pos Vec2 Centre.
---@param radius number Radius in pixels.
---@param color Color Fill colour.
---@param start_deg? number Slice start angle in degrees, 0 = right, 90 = down (default 0).
---@param percentage? number Part of the circle to fill, 0-1 (default 1), clockwise from `start_deg`.
---@param segments? integer Segment count for a full circle (default 32, at least 3).
function Render.FilledCircle(pos, radius, color, start_deg, percentage, segments) end

---Draws a triangle outline through the first three points.
---@param points Vec2[] Three points.
---@param color Color Line colour.
---@param thickness? number Line thickness in pixels (default 1).
function Render.Triangle(points, color, thickness) end

---Draws a filled triangle through the first three points.
---@param points Vec2[] Three points.
---@param color Color Fill colour.
function Render.FilledTriangle(points, color) end

---Draws a convex polygon textured with an image.
---@param vertices Vertex[] At least three vertices, in order around the polygon.
---@param image ImageHandle Image to map onto the polygon.
---@param color Color Tint (multiplied with the image).
---@param grayscale? number 0-1 blend towards gray (default 0).
function Render.TexturedPoly(vertices, image, color, grayscale) end

---Draws the round VITTLOCK mark with an optional soft shadow under it.
---@param pos Vec2 Centre.
---@param radius number Radius in pixels.
---@param unused? any Ignored.
---@param color? Color Circle colour (default `Color(239, 59, 59)`).
---@param mark_color? Color Letter colour (default `Color(227, 227, 224)`).
---@param shadow? boolean Draw the shadow (default true).
function Render.Logo(pos, radius, unused, color, mark_color, shadow) end

-- ── Gradients, shadows, blur ────────────────────────────────────────────────

---Draws a filled rectangle with a colour per corner, blended across it.
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param top_left Color
---@param top_right Color
---@param bottom_left Color
---@param bottom_right Color
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
function Render.Gradient(from, to, top_left, top_right, bottom_left, bottom_right, rounding, flags) end

---Draws a rectangle outline with a colour per corner, blended along it.
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param top_left Color
---@param top_right Color
---@param bottom_left Color
---@param bottom_right Color
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
---@param thickness? number Line thickness in pixels (default 1).
function Render.OutlineGradient(from, to, top_left, top_right, bottom_left, bottom_right, rounding, flags, thickness) end

---Draws a filled circle (or pie slice) blending from `inner` at the centre to `outer` at the rim.
---@param pos Vec2 Centre.
---@param radius number Radius in pixels.
---@param outer Color Colour at the rim.
---@param inner Color Colour at the centre.
---@param start_deg? number Start angle in degrees (default 0).
---@param percentage? number Part of the circle, 0-1 (default 1).
function Render.CircleGradient(pos, radius, outer, inner, start_deg, percentage) end

---Draws a soft shadow around a rectangle.
---@param from Vec2 Top-left corner of the shape.
---@param to Vec2 Bottom-right corner of the shape.
---@param color Color Shadow colour.
---@param thickness number Shadow size (blur distance) in pixels.
---@param rounding? number Corner radius of the shape (default 0).
---@param flags? integer `Enum.DrawFlags` (default `ShadowCutOutShapeBackground`).
---@param offset? Vec2 Shadow offset (default `Vec2(0, 0)`).
function Render.Shadow(from, to, color, thickness, rounding, flags, offset) end

---Draws a soft shadow around a circle.
---@param center Vec2 Centre.
---@param radius number Radius of the shape.
---@param color Color Shadow colour.
---@param thickness number Shadow size in pixels.
---@param segments? integer Segment count (default 12).
---@param flags? integer `Enum.DrawFlags` (default `ShadowCutOutShapeBackground`).
---@param offset? Vec2 Shadow offset.
function Render.ShadowCircle(center, radius, color, thickness, segments, flags, offset) end

---Draws a soft shadow around a convex polygon.
---@param points Vec2[] At least three points of a convex shape.
---@param color Color Shadow colour.
---@param thickness number Shadow size in pixels.
---@param flags? integer `Enum.DrawFlags` (default `ShadowCutOutShapeBackground`).
---@param offset? Vec2 Shadow offset.
function Render.ShadowConvexPoly(points, color, thickness, flags, offset) end

---Draws a soft shadow around a regular polygon.
---@param center Vec2 Centre.
---@param radius number Radius of the shape.
---@param color Color Shadow colour.
---@param thickness number Shadow size in pixels.
---@param segments integer Number of sides (at least 3).
---@param flags? integer `Enum.DrawFlags` (default `ShadowCutOutShapeBackground`).
---@param offset? Vec2 Shadow offset.
function Render.ShadowNGon(center, radius, color, thickness, segments, flags, offset) end

---Draws a blurred copy of the game image inside a rectangle (frosted glass).
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param strength? number Blur strength (default 1; five steps, below 0.5 lightest, 1.5 and above strongest).
---@param alpha? number Opacity, 0-1 (default 1).
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
function Render.Blur(from, to, strength, alpha, rounding, flags) end

-- ── Draw state ──────────────────────────────────────────────────────────────

---Restricts drawing to a rectangle until the matching `PopClip`.
---@param from Vec2 Top-left corner.
---@param to Vec2 Bottom-right corner.
---@param intersect? boolean Intersect with the current clip rectangle instead of replacing it (default false).
function Render.PushClip(from, to, intersect) end

---Removes the clip rectangle pushed last.
function Render.PopClip() end

---Starts a rotated block: everything drawn until `StopRotation` turns about its own centre.
---@param angle number Degrees, positive = clockwise on screen.
function Render.StartRotation(angle) end

---Ends the block started by the last `StartRotation` and applies the rotation.
function Render.StopRotation() end

---Multiplies the alpha of everything drawn after it (reset to 1 at the start of every `on_draw`).
---@param alpha number 0-1.
function Render.SetGlobalAlpha(alpha) end

---Sets the global alpha back to 1.
function Render.ResetGlobalAlpha() end

-- ── Text and fonts ──────────────────────────────────────────────────────────

---Loads a font: the built-in UI font, an icon font, a font file, or an installed Windows font family. Same arguments return the same handle.
---@param name string Font family name or font file path.
---@param flags? integer `Enum.FontCreate` bits (default 0).
---@param weight? integer `Enum.FontWeight` value, 100-900 (default 400).
---@return FontHandle font
function Render.LoadFont(name, flags, weight) end

---Loads one of the game's own fonts by family name (falls back to installed fonts, then the built-in font).
---@param name string Family name, e.g. "Radiance" or "VALVE Oracle".
---@param flags? integer `Enum.FontCreate` bits (default 0).
---@param weight? integer `Enum.FontWeight` value (default 400).
---@return FontHandle font
function Render.LoadGameFont(name, flags, weight) end

---Draws text with its top-left corner at `pos`.
---@param font FontHandle|nil Font handle; `0` or `nil` for the default font.
---@param size number Font size in pixels.
---@param text string|number Text to draw (`\n` starts a new line).
---@param pos Vec2 Top-left corner.
---@param color Color Text colour.
function Render.Text(font, size, text, pos, color) end

---Measures text drawn with `Render.Text`. Works outside `on_draw` too.
---@param font FontHandle|nil Font handle; `0` or `nil` for the default font.
---@param size number Font size in pixels.
---@param text string|number Text to measure.
---@return Vec2 size Width and height in pixels.
function Render.TextSize(font, size, text) end

-- ── Images and SVG ──────────────────────────────────────────────────────────

---Loads an image from the game (panorama path) or from a file. Same path and filter return the same handle.
---@param path string Panorama path ("panorama/images/....vtex_c", "file://{images}/...") or a file path.
---@param filter? integer `Enum.ImageFilter` value (default `None`).
---@return ImageHandle image `0` only for an empty path.
function Render.LoadImage(path, filter) end

---Loads an image cut out by a mask: the image's colour where the mask is white. Both are panorama paths.
---@param mask string Panorama path of the mask.
---@param image string Panorama path of the image.
---@param unused? any Ignored.
---@return ImageHandle image `0` when a path is empty.
function Render.LoadMaskedImage(mask, image, unused) end

---Draws an image with its top-left corner at `pos`.
---@param image ImageHandle
---@param pos Vec2 Top-left corner.
---@param size Vec2 Width and height in pixels.
---@param color Color Tint (multiplied with the image; white = unchanged).
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
---@param uv_min? Vec2 Top-left of the part of the image to draw, 0-1 (default `Vec2(0, 0)`).
---@param uv_max? Vec2 Bottom-right of the part to draw, 0-1 (default `Vec2(1, 1)`).
---@param grayscale? number 0-1 blend towards gray (default 0).
function Render.Image(image, pos, size, color, rounding, flags, uv_min, uv_max, grayscale) end

---Draws an image centred on `pos`.
---@param image ImageHandle
---@param pos Vec2 Centre.
---@param size Vec2 Width and height in pixels.
---@param color Color Tint.
---@param rounding? number Corner radius in pixels (default 0).
---@param flags? integer `Enum.DrawFlags` corner bits.
---@param uv_min? Vec2 Top-left of the part to draw, 0-1.
---@param uv_max? Vec2 Bottom-right of the part to draw, 0-1.
---@param grayscale? number 0-1 blend towards gray (default 0).
function Render.ImageCentered(image, pos, size, color, rounding, flags, uv_min, uv_max, grayscale) end

---Returns an image's size in pixels, or `Vec2(0, 0)` while it is still loading (or failed to load).
---@param image ImageHandle
---@return Vec2 size
function Render.ImageSize(image) end

---Loads an SVG file (rasterized at `size`) or a game `.vsvg` resource. `~/deadlock/<name>.svg` gives a built-in icon.
---@param path string File path, "~/..." path, or game `.vsvg_c` path.
---@param size? Vec2 Raster size in pixels (default: the SVG's own size).
---@param unused? any Ignored.
---@return ImageHandle image `0` when the file is missing.
function Render.LoadSvg(path, size, unused) end

---Rasterizes SVG markup into an image. Cached by `name` (or by the markup when no name) and size.
---@param text string SVG markup.
---@param size? Vec2 Raster size in pixels (default: the SVG's own size).
---@param name? string Cache name.
---@return ImageHandle image `0` for empty text.
function Render.LoadSvgString(text, size, name) end

-- ── Screen ──────────────────────────────────────────────────────────────────

---Projects a world position to the screen.
---@param pos Vector World position.
---@return Vec2 screen Screen position in pixels.
---@return boolean visible True when the point is in front of the camera (it may still be outside the screen edges).
function Render.WorldToScreen(pos) end

---Returns the screen size in pixels.
---@return Vec2 size
function Render.ScreenSize() end

---Returns the screen height divided by 1080 (1 at 1080p), for sizing HUD elements.
---@return number scale
function Render.UIScale() end

-- ── Render targets ──────────────────────────────────────────────────────────

---Finds a render target by name or creates it. Without both sizes it follows the screen size.
---@param name string Unique name; the same name always returns the same target.
---@param w? number Width in pixels.
---@param h? number Height in pixels.
---@return RenderTarget rt
function Render.FindOrCreateRT(name, w, h) end

---Gives a render target a fixed size and marks it for redrawing.
---@param rt RenderTarget
---@param w number Width in pixels.
---@param h number Height in pixels.
---@overload fun(rt: RenderTarget, size: Vec2)
function Render.ResizeRT(rt, w, h) end

---Marks a render target so the next `Render.RenderRT` runs its callback again.
---@param rt RenderTarget
function Render.MarkDirtyRT(rt) end

---Redraws the target with `fn` if it is dirty, then draws it on screen like `Render.ImageRT`.
---@param fn fun(): boolean? Draws the target's contents in target pixels ((0, 0) = its top-left).
---@param rt RenderTarget
---@param pos Vec2 Top-left corner on screen.
---@param color Color Tint.
---@param scale? number Drawn size = target size x scale (default 1).
---@param uv_min? Vec2 Top-left of the part to draw, in scaled pixels.
---@param uv_size? Vec2 Size of the part to draw, in scaled pixels.
---@return boolean result True when `fn` ran this call and returned true.
function Render.RenderRT(fn, rt, pos, color, scale, uv_min, uv_size) end

---Draws a render target's current contents.
---@param rt RenderTarget
---@param pos Vec2 Top-left corner on screen.
---@param color Color Tint.
---@param scale? number Drawn size = target size x scale (default 1).
---@param uv_min? Vec2 Top-left of the part to draw, in scaled pixels.
---@param uv_size? Vec2 Size of the part to draw, in scaled pixels.
function Render.ImageRT(rt, pos, color, scale, uv_min, uv_size) end

---Inside a `RenderRT` callback: keeps what was drawn so far only where the mask covers it.
---@param mask ImageHandle|RenderTarget Image or render target, stretched over the target.
---@param invert? boolean Keep only where the mask does not cover (default false).
function Render.ApplyMaskRT(mask, invert) end

-- ── Notifications ───────────────────────────────────────────────────────────

---Options for `Notification`.
---@class NotificationArgs
---@field id? string|number A card with the same id still on screen blocks a new one. Empty = always shown.
---@field duration? number Seconds on screen (default 5).
---@field timer? number Seconds for the card's progress bar to empty (0 = no bar).
---@field precise_timer? number Used as `timer` when `timer` is not set.
---@field rounding? number Corner radius of the image.
---@field primary_text? string First line. Supports colour markup.
---@field secondary_text? string Second line. Supports colour markup.
---@field primary_image? string|ImageHandle Panorama path, built-in icon name, icon-font glyph, or a `LoadImage` handle of a panorama image.
---@field primary_image_color? Color Image tint.
---@field hero? integer Hero id: shows that hero's portrait as a round image (replaces `primary_image`).
---@field hero_icon? string Panorama path or built-in icon name of a small badge on the image's corner.
---@field active? boolean Highlighted accent (true, default) or muted (false).

---Shows a notification card at the side of the screen.
---@param args NotificationArgs
---@return boolean shown False when a card with the same id is still up.
function Notification(args) end

---Notification helpers.
---@class Renderer
Renderer = {}

---Shows a line of text in the upper middle of the screen for a while (up to four at once).
---@param text string Text to show.
---@param duration? number Seconds (default 3, 0.1-60).
function Renderer.DrawCenteredNotification(text, duration) end
