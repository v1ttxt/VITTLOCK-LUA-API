# Render

`Render` draws 2D shapes, text and images on top of the game: HUD panels, ESP boxes, labels, icons. It also loads fonts, images and SVGs, caches drawings in render targets, and shows notification cards (`Notification`, `Renderer`).

## Rules

- **Draw only inside `callback.on_draw`.** Every drawing function does nothing when called anywhere else (no error, nothing appears). Drawing goes under the menu.
- **Load assets once.** Call `LoadFont`, `LoadGameFont`, `LoadImage`, `LoadMaskedImage`, `LoadSvg` and `LoadSvgString` at the top level of your script, keep the handle in a `local`, and reuse it every frame. Load functions work from anywhere; the same arguments return the same handle, but loading still costs a lookup.
- **`Vec2`, `Color` and number arguments that are not marked optional are required.** Passing `nil` (or the wrong type) raises an error. Optional arguments can be left out or passed as `nil`.
- **Coordinates are screen pixels**, `(0, 0)` at the top-left, `y` going down. Rectangles take two corners, `from` (top-left) and `to` (bottom-right). Images take a position and a size instead: `Image` uses the top-left corner, `ImageCentered` the centre. Text is placed by its top-left corner.
- **Angles are degrees**, `0` = right, `90` = down; positive angles turn clockwise on screen.
- **Colours** are [`Color`](types.md#color) values, 0-255 per channel. Every colour is multiplied by the global alpha (`SetGlobalAlpha`).
- **Point lists** (`PolyLine`, `Triangle`, `ShadowConvexPoly`) are Lua arrays of `Vec2`. Entries that are not `Vec2` are skipped.
- Clip rectangles, rotations and the global alpha are reset at the start of every `on_draw`. Clips you forget to pop are removed at the end of it.

Flag values come from [`Enum.DrawFlags`](enums.md), [`Enum.FontCreate`](enums.md), [`Enum.FontWeight`](enums.md) and [`Enum.ImageFilter`](enums.md).

```lua
local font = Render.LoadFont("Segoe UI", 0, Enum.FontWeight.SEMIBOLD)

callback.on_draw:set(function()
    local from, to = Vec2(20, 200), Vec2(220, 250)
    Render.FilledRect(from, to, Color(14, 16, 22, 200), 8)
    Render.Rect(from, to, Color(90, 170, 255), 8, Enum.DrawFlags.None, 1)
    Render.Text(font, 16, "Hello", Vec2(32, 214), Color(255, 255, 255))
end)
```

---

## Drawing primitives

### `Render.FilledRect(from, to, color [, rounding [, flags]])`

Draws a filled rectangle.

| Name | Type | Description |
|---|---|---|
| `from` | `Vec2` | Top-left corner. |
| `to` | `Vec2` | Bottom-right corner. |
| `color` | `Color` | Fill colour. |
| `rounding` | `number?` | Corner radius in pixels. Default `0`. |
| `flags` | `integer?` | `Enum.DrawFlags` corner bits (`RoundCornersTop`, `RoundCornersLeft`, ...). Without corner bits all four corners are rounded. |

### `Render.Rect(from, to, color [, rounding [, flags [, thickness]]])`

Draws a rectangle outline. Same parameters as `FilledRect`, plus `thickness` (pixels, default `1`).

### `Render.RoundedProgressRect(from, to, color, percent, rounding [, thickness])`

Draws part of a rounded rectangle's outline, starting at the top-left corner and going clockwise. Useful for progress borders.

| Name | Type | Description |
|---|---|---|
| `from`, `to` | `Vec2` | Corners. |
| `color` | `Color` | Line colour. |
| `percent` | `number` | How much of the outline to draw, `0`-`1`. Required. |
| `rounding` | `number` | Corner radius. Required. |
| `thickness` | `number?` | Line thickness. Default `1`. |

### `Render.Line(from, to, color [, thickness])`

Draws a line from `from` to `to`. `thickness` defaults to `1`.

### `Render.PolyLine(points, color [, thickness])`

Draws an open line through `points` (a `Vec2` array, at least two). The last point is not joined back to the first.

### `Render.Circle(pos, radius, color [, thickness [, start_deg [, percentage [, rounded [, segments]]]]])`

Draws a circle outline, or an arc when `percentage` is below `1`.

| Name | Type | Description |
|---|---|---|
| `pos` | `Vec2` | Centre. |
| `radius` | `number` | Radius in pixels. Nothing is drawn when `<= 0`. |
| `color` | `Color` | Line colour. |
| `thickness` | `number?` | Line thickness. Default `1`. |
| `start_deg` | `number?` | Where the arc starts. Default `0` (right). |
| `percentage` | `number?` | Part of the circle, `0`-`1`, drawn clockwise from `start_deg`. Default `1`. |
| `rounded` | `boolean?` | Round caps on the arc's ends. Default `false`. |
| `segments` | `integer?` | Segments for a full circle. Default `32`, minimum `3`. |

```lua
-- A cooldown ring that empties clockwise from the top.
local function cooldown_ring(center, fraction_left)
    Render.Circle(center, 20, Color(255, 255, 255, 40), 4)
    Render.Circle(center, 20, Color(90, 170, 255), 4, -90, fraction_left, true)
end
```

### `Render.FilledCircle(pos, radius, color [, start_deg [, percentage [, segments]]])`

Draws a filled circle, or a pie slice when `percentage` is below `1`. The parameters mean the same as in `Circle` (there is no thickness).

### `Render.Triangle(points, color [, thickness])`

Draws a triangle outline through the first three `Vec2` in `points`.

### `Render.FilledTriangle(points, color)`

Draws a filled triangle through the first three `Vec2` in `points`.

### `Render.TexturedPoly(vertices, image, color [, grayscale])`

Draws a convex polygon with an image mapped onto it. Each corner is a [`Vertex`](#vertex) with a screen position and a texture coordinate.

| Name | Type | Description |
|---|---|---|
| `vertices` | `Vertex[]` | At least three vertices, in order around the polygon. |
| `image` | `integer` | Image handle (see [Images and SVG](#images-and-svg)). |
| `color` | `Color` | Tint, multiplied with the image. |
| `grayscale` | `number?` | `0`-`1` blend towards gray. Default `0`. |

```lua
local icon = Render.LoadImage("panorama/images/hud/abilities/bull_drain_psd.vtex_c")

callback.on_draw:set(function()
    local c = Vec2(300, 300)
    -- The icon on a diamond.
    Render.TexturedPoly({
        Vertex(c + Vec2(0, -34), Vec2(0.5, 0)),
        Vertex(c + Vec2(34, 0),  Vec2(1, 0.5)),
        Vertex(c + Vec2(0, 34),  Vec2(0.5, 1)),
        Vertex(c + Vec2(-34, 0), Vec2(0, 0.5)),
    }, icon, Color(255, 255, 255))
end)
```

### `Render.Logo(pos, radius [, _ [, color [, mark_color [, shadow]]]])`

Draws the round VITTLOCK mark centred on `pos`. The third argument is ignored. `color` is the circle (default `Color(239, 59, 59)`), `mark_color` the letter (default `Color(227, 227, 224)`), `shadow` draws a soft shadow under it (default `true`).

### Vertex

A corner for `Render.TexturedPoly`.

#### `Vertex([pos [, uv]])`

Creates a vertex. Both default to `Vec2(0, 0)`.

| Field | Type | Description |
|---|---|---|
| `pos` | `Vec2` | Screen position in pixels. |
| `uv` | `Vec2` | Texture coordinate, `0`-`1` across the image (`Vec2(0, 0)` = top-left of the image). |

Both fields can be read and assigned.

---

## Text and fonts

Fonts are integer handles. `0` (or `nil`) is the default font, so `Render.Text(0, 18, "hi", pos, color)` works without loading anything. Any pixel size can be drawn with any font; each font keeps a limited number of distinct sizes ready, so stick to a few fixed sizes rather than animating the size.

### `Render.LoadFont(name [, flags [, weight]])`

Loads a font and returns its handle. The same `name`, `flags` and `weight` always return the same handle.

| Name | Type | Description |
|---|---|---|
| `name` | `string` | What to load (see below). |
| `flags` | `integer?` | `Enum.FontCreate` bits. Default `0`. |
| `weight` | `integer?` | `Enum.FontWeight` value (100-900). Default `400`. |

`name` can be:

- `""`, `"default"`, `"inter"` or a name containing `MuseoSans`: the built-in UI font (Inter). Weight 600 and above gives the semibold cut, lower weights the medium cut.
- A name containing `FontAwesome`: the built-in Font Awesome icon font. Draw icons by their code point, e.g. `"\u{f004}"` (heart).
- A path ending in `.ttf`, `.otf` or `.ttc`: that font file. Paths follow the [file path rules](#file-paths).
- Anything else: an installed Windows font family, e.g. `"Arial"` or `"Segoe UI"`. The installed face closest to `weight` (and italic, when `FONTFLAG_ITALIC` is set) is used. If the family is not installed, the game's fonts are tried.

When nothing matches (or a font file does not exist), the built-in UI font is used.

Of the `Enum.FontCreate` flags, these change how text looks:

| Flag | Effect |
|---|---|
| `FONTFLAG_ITALIC` | Picks the italic face of the family. |
| `FONTFLAG_UNDERLINE` | Line under the text. |
| `FONTFLAG_STRIKEOUT` | Line through the text. |
| `FONTFLAG_DROPSHADOW` | Dark shadow 1 pixel down-right. |
| `FONTFLAG_OUTLINE` | Dark 1-pixel outline. Takes priority over `FONTFLAG_DROPSHADOW`. |

The other flags are accepted and have no effect (text is always anti-aliased).

### `Render.LoadGameFont(name [, flags [, weight]])`

Like `LoadFont`, but looks in the game's own fonts first (for example `"Radiance"`, `"Retail Demo"`, `"VALVE Oracle"`), by family name and closest weight. Falls back to installed Windows fonts, then the built-in UI font.

```lua
local title = Render.LoadGameFont("Radiance", 0, Enum.FontWeight.BOLD)
local body  = Render.LoadFont("Segoe UI", Enum.FontCreate.FONTFLAG_OUTLINE, Enum.FontWeight.NORMAL)
```

### `Render.Text(font, size, text, pos, color)`

Draws text with its top-left corner at `pos`.

| Name | Type | Description |
|---|---|---|
| `font` | `integer?` | Font handle. `0` or `nil` for the default font. Unknown handles also draw with the default font. |
| `size` | `number` | Size in pixels. Nothing is drawn when `<= 0`. |
| `text` | `string\|number` | The text. Numbers are converted. Other types draw nothing. `\n` starts a new line. |
| `pos` | `Vec2` | Top-left corner. |
| `color` | `Color` | Text colour. Outline and shadow use black at the same alpha. |

### `Render.TextSize(font, size, text)`

Returns a `Vec2` with the width and height `Render.Text` would use for the same arguments. Works anywhere, not only in `on_draw`. Empty text returns `Vec2(0, 0)`.

```lua
local font = Render.LoadFont("default", 0, 600)

callback.on_draw:set(function()
    local text = "Centred"
    local size = Render.TextSize(font, 20, text)
    local screen = Render.ScreenSize()
    Render.Text(font, 20, text, Vec2((screen.x - size.x) / 2, 60), Color(255, 255, 255))
end)
```

---

## Images and SVG

Images, masked images and SVGs share one kind of integer handle. Loading the same path again returns the same handle.

### File paths

Paths that are not game (panorama) paths are files:

| Path | Resolves to |
|---|---|
| `~/icons/x.png` | `C:\VITTLOCK\scripts\v2\assets\icons\x.png` |
| `icons/x.png` (relative) | `C:\VITTLOCK\scripts\v2\icons\x.png` |
| `C:/some/folder/x.png` (absolute) | That file. |

Forward and back slashes both work.

### `Render.LoadImage(path [, filter])`

Loads an image and returns its handle.

| Name | Type | Description |
|---|---|---|
| `path` | `string` | A game image or an image file (see below). |
| `filter` | `integer?` | `Enum.ImageFilter` value. Default `None`. The same path with a different filter is a separate handle. |

- **Game images:** paths starting with `panorama/` or `file://`, or containing `.vtex`, e.g. `"panorama/images/hud/abilities/bull_drain_psd.vtex_c"` or `"file://{images}/hud/..."`. They load in the background: until they are ready they draw nothing and `ImageSize` returns `Vec2(0, 0)`.
- **Files:** PNG, JPEG, BMP, TGA and other common formats, loaded immediately. See [file paths](#file-paths).

Returns `0` only for an empty path. A file that can't be loaded still returns a handle; it just never draws.

| `Enum.ImageFilter` | Effect |
|---|---|
| `None` | The image as is. |
| `Negative` | Inverted colours. |
| `Grayscale` | Gray. |
| `White` | A white silhouette (alpha kept). |
| `Black` | A black silhouette (alpha kept). |
| `LuminanceAlpha` | White, with the image's brightness as alpha. |

Combine `White` with a tint colour in `Image` to draw an icon in any colour.

### `Render.LoadMaskedImage(mask, image [, _])`

Returns a handle for `image` cut out by `mask`: the image's colour where the mask is white, transparent where it is black. Both are game image paths. The result has the mask's size. The third argument is ignored. Returns `0` when either path is empty. Like other game images it draws nothing until both have loaded; its `ImageSize` is known once it has been drawn.

### `Render.Image(image, pos, size, color [, rounding [, flags [, uv_min [, uv_max [, grayscale]]]]])`

Draws an image with its top-left corner at `pos`.

| Name | Type | Description |
|---|---|---|
| `image` | `integer` | Image handle. Render target handles don't work here; use `ImageRT`. |
| `pos` | `Vec2` | Top-left corner. |
| `size` | `Vec2` | Width and height in pixels (not the bottom-right corner). |
| `color` | `Color` | Tint, multiplied with the image. `Color(255, 255, 255)` draws it unchanged. |
| `rounding` | `number?` | Corner radius. Default `0`. |
| `flags` | `integer?` | `Enum.DrawFlags` corner bits for the rounding. |
| `uv_min` | `Vec2?` | Top-left of the part of the image to draw, `0`-`1`. Default `Vec2(0, 0)`. |
| `uv_max` | `Vec2?` | Bottom-right of the part to draw, `0`-`1`. Default `Vec2(1, 1)`. |
| `grayscale` | `number?` | `0`-`1` blend towards gray, on top of the filter. Default `0`. |

```lua
local card = Render.LoadImage("panorama/images/shop/catalog/cards/card_backer_weapon_t4_psd.vtex_c")

callback.on_draw:set(function()
    Render.Image(card, Vec2(40, 300), Vec2(64, 96), Color(255, 255, 255), 6)
    -- The same, grayed out.
    Render.Image(card, Vec2(110, 300), Vec2(64, 96), Color(255, 255, 255), 6, nil, nil, nil, 1)
end)
```

### `Render.ImageCentered(image, pos, size, color [, rounding [, flags [, uv_min [, uv_max [, grayscale]]]]])`

Same as `Image`, but `pos` is the centre of the image.

### `Render.ImageSize(image)`

Returns the image's size in pixels as a `Vec2`, or `Vec2(0, 0)` while it is loading, when it failed, or for an unknown handle. For SVGs this is the raster size. Works anywhere.

### `Render.LoadSvg(path [, size [, _]])`

Loads an SVG and returns an image handle; draw it with `Image` / `ImageCentered`.

| Name | Type | Description |
|---|---|---|
| `path` | `string` | An `.svg` file ([file paths](#file-paths)), a game `.vsvg_c` path, or a built-in icon. |
| `size` | `Vec2?` | Raster size in pixels. Default: the SVG's own width and height. |

- **SVG files** are rasterized once at `size` (at most 4096 x 4096), scaled to fit with the aspect ratio kept and centred. Draw them at that size for sharp edges. The same path and size return the same handle; a different size is a new image. Plain SVG is supported (paths, shapes, fills, strokes, gradients); text, filters and embedded images are not drawn.
- **Game SVGs** (`"panorama/images/....vsvg_c"`) load like game images; `size` is ignored.
- **Built-in icons:** `"~/deadlock/<name>.svg"` gives a built-in icon when you have no file at that path. `ImageSize` reports the `size` you asked for.

Returns `0` when the file doesn't exist (and isn't a built-in icon) or `path` is empty.

#### Built-in icons

Names for `"~/deadlock/<name>.svg"` (and for notification images):

`bell`, `camp_large`, `camp_large_outlined`, `camp_medium`, `camp_medium_outlined`, `camp_small`, `camp_small_outlined`, `crates`, `crates_outline`, `headshot_skull`, `heart`, `offscreen_arrow_glow_v5`, `offscreen_arrow_plain_v5`, `offscreen_bar_glow_rounded_v4`, `offscreen_bar_glow_square_v4`, `offscreen_icon_shadow_v3`, `owl`, `rejuv`, `rune_casting`, `rune_gun`, `rune_movement`, `rune_survival`, `sack_dollar`, `sinner`, `soul_orb`, `tier_numbers_small_01`, `tier_numbers_small_02`, `tier_numbers_small_03`, `tier_numbers_small_04`, `tough_crate`, `troopers`

```lua
local camp = Render.LoadSvg("~/deadlock/camp_medium.svg", Vec2(32, 32))

callback.on_draw:set(function()
    Render.ImageCentered(camp, Vec2(400, 400), Vec2(32, 32), Color(255, 220, 120))
end)
```

### `Render.LoadSvgString(text [, size [, name]])`

Rasterizes SVG markup and returns an image handle. `size` works as in `LoadSvg`.

The result is cached by `name` and size when `name` is given, otherwise by the markup and size. With a name, a later call with the same name and size returns the first image even if the markup changed: use a new name for new markup. Returns `0` for empty text. Markup that can't be parsed still returns a handle that draws nothing.

```lua
local bar = Render.LoadSvgString(
    '<svg width="7" height="16" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="3" height="12" fill="white"/></svg>',
    Vec2(14, 32), "my_bar")
```

---

## Gradients, shadows, blur

### `Render.Gradient(from, to, top_left, top_right, bottom_left, bottom_right [, rounding [, flags]])`

Draws a filled rectangle with one colour per corner, blended across it. Rounding and corner flags work as in `FilledRect`.

```lua
-- Left-to-right fade.
local a, b = Color(255, 60, 60), Color(255, 60, 60, 0)
Render.Gradient(Vec2(20, 100), Vec2(220, 120), a, b, a, b, 4)
```

### `Render.OutlineGradient(from, to, top_left, top_right, bottom_left, bottom_right [, rounding [, flags [, thickness]]])`

The outline version of `Gradient`. `thickness` defaults to `1`.

### `Render.CircleGradient(pos, radius, outer, inner [, start_deg [, percentage]])`

Draws a filled circle (or pie slice) blending from `inner` at the centre to `outer` at the rim. Note the order: the rim colour comes first. `start_deg` and `percentage` work as in `FilledCircle`.

```lua
-- A glow: bright centre, transparent rim.
Render.CircleGradient(Vec2(500, 300), 40, Color(255, 200, 60, 0), Color(255, 200, 60, 200))
```

### `Render.Shadow(from, to, color, thickness [, rounding [, flags [, offset]]])`

Draws a soft shadow around the rectangle `from`-`to`. Draw the shape itself after it.

| Name | Type | Description |
|---|---|---|
| `from`, `to` | `Vec2` | The shape's corners. |
| `color` | `Color` | Shadow colour. |
| `thickness` | `number` | How far the shadow spreads, in pixels. Required. |
| `rounding` | `number?` | The shape's corner radius. Default `0`. |
| `flags` | `integer?` | `Enum.DrawFlags`. Default `ShadowCutOutShapeBackground`: no shadow inside the shape, so translucent shapes on top don't look darker. Passing your own flags replaces this; add `Enum.DrawFlags.ShadowCutOutShapeBackground` to keep it. |
| `offset` | `Vec2?` | Moves the shadow. Default `Vec2(0, 0)`. |

```lua
local from, to = Vec2(40, 500), Vec2(240, 560)
Render.Shadow(from, to, Color(0, 0, 0, 200), 24, 8, nil, Vec2(0, 4))
Render.FilledRect(from, to, Color(40, 44, 54), 8)
```

### `Render.ShadowCircle(center, radius, color, thickness [, segments [, flags [, offset]]])`

A shadow around a circle. `segments` defaults to `12`. `flags` and `offset` as in `Shadow`.

### `Render.ShadowConvexPoly(points, color, thickness [, flags [, offset]])`

A shadow around a convex polygon given as a `Vec2` array (at least three points). `flags` and `offset` as in `Shadow`.

### `Render.ShadowNGon(center, radius, color, thickness, segments [, flags [, offset]])`

A shadow around a regular polygon with `segments` sides (required, at least `3`). `flags` and `offset` as in `Shadow`.

### `Render.Blur(from, to [, strength [, alpha [, rounding [, flags]]]])`

Draws a blurred copy of the game image inside the rectangle, for frosted-glass panels. Draw a translucent fill on top to tint it.

| Name | Type | Description |
|---|---|---|
| `from`, `to` | `Vec2` | Corners. |
| `strength` | `number?` | Blur strength. Default `1`. There are five steps: below `0.5` is the lightest, `1.5` and above the strongest. |
| `alpha` | `number?` | Opacity, `0`-`1`. Default `1`. |
| `rounding` | `number?` | Corner radius. Default `0`. |
| `flags` | `integer?` | `Enum.DrawFlags` corner bits. |

Notes:

- The blurred image is prepared for the next frame when you call `Blur`. The first frame you call it (or the first after a frame without any `Blur` call) may draw nothing. Call it every frame the panel is visible.
- There is one blur strength per frame: the strength of the last `Blur` call applies to all of them.

```lua
callback.on_draw:set(function()
    local from, to = Vec2(20, 600), Vec2(260, 680)
    Render.Blur(from, to, 1.0, 1.0, 10)
    Render.FilledRect(from, to, Color(14, 16, 22, 120), 10)
end)
```

---

## Clipping, rotation, alpha

### `Render.PushClip(from, to [, intersect])`

Restricts all drawing to the rectangle until the matching `PopClip`. By default the new rectangle replaces the current one; pass `intersect = true` to clip to the overlap of both. Clips nest.

### `Render.PopClip()`

Removes the clip pushed last. Does nothing when there is none.

```lua
Render.PushClip(Vec2(20, 20), Vec2(120, 60))
Render.Text(0, 18, "This long line is cut off at 120 px", Vec2(20, 30), Color(255, 255, 255))
Render.PopClip()
```

### `Render.StartRotation(angle)`

Starts a rotated block. Everything drawn until `StopRotation` is turned by `angle` degrees (clockwise on screen) about the centre of the block's own bounding box. Blocks can nest.

### `Render.StopRotation()`

Ends the last block and applies its rotation. A block that is never stopped is not rotated.

```lua
Render.StartRotation(45)
Render.FilledRect(Vec2(300, 300), Vec2(340, 340), Color(255, 255, 255))   -- a diamond
Render.StopRotation()
```

### `Render.SetGlobalAlpha(alpha)`

Multiplies the alpha of everything drawn after it (shapes, text, images, blur) by `alpha` (`0`-`1`, clamped). Handy for fading a whole panel. It is reset to `1` at the start of every `on_draw`.

### `Render.ResetGlobalAlpha()`

Sets the global alpha back to `1`.

---

## Screen and world-to-screen

### `Render.WorldToScreen(pos)`

Projects a world position ([`Vector`](types.md#vector)) to the screen. Returns two values: the screen position (`Vec2`) and a boolean, `true` when the point is in front of the camera. When it is `false`, ignore the position. A `true` point can still lie outside the screen edges; compare with `ScreenSize()` if that matters.

```lua
callback.on_draw:set(function()
    local me = entity_list.local_pawn()
    if not me then return end
    local screen, visible = Render.WorldToScreen(me:get_origin() + Vector(0, 0, 90))
    if visible then
        Render.FilledCircle(screen, 4, Color(255, 60, 60))
    end
end)
```

### `Render.ScreenSize()`

Returns the screen size in pixels as a `Vec2`.

### `Render.UIScale()`

Returns the screen height divided by 1080: `1` at 1080p, `1.333` at 1440p. Multiply HUD sizes by it to keep them the same relative size at every resolution.

---

## Render targets

A render target (RT) is an off-screen image you draw into. Drawing many shapes once into an RT and then drawing the RT every frame is much cheaper than redrawing the shapes every frame. RTs are integer handles, but they are not image handles: draw them with `RenderRT` / `ImageRT`, not `Image`.

RTs are kept by name for the whole session, also across script reloads; after a reload every RT is redrawn on its next `RenderRT`.

### `Render.FindOrCreateRT(name [, w, h])`

Returns the RT called `name`, creating it if needed. With both `w` and `h` it has that fixed size (pixels, 1-8192); without them it always matches the screen size. For an existing name the size arguments are ignored (use `ResizeRT`). Works anywhere; call it at load time.

### `Render.ResizeRT(rt, w, h)` / `Render.ResizeRT(rt, size)`

Gives the RT a fixed size (two numbers or a `Vec2`) and marks it dirty. Sizes `<= 0` are ignored.

### `Render.MarkDirtyRT(rt)`

Marks the RT dirty: the next `RenderRT` runs its callback again. Call it when what the RT shows has changed.

### `Render.RenderRT(fn, rt, pos, color [, scale [, uv_min [, uv_size]]])`

If the RT is dirty (or new, or its size changed), clears it and calls `fn` to draw its contents; then draws the RT on screen like `ImageRT`. Returns `true` when `fn` ran in this call and returned `true`, otherwise `false`.

| Name | Type | Description |
|---|---|---|
| `fn` | `function` | Draws the RT's contents with the normal `Render.*` functions. |
| `rt` | `integer` | RT handle. |
| `pos` | `Vec2` | Where to draw the RT on screen (top-left). |
| `color` | `Color` | Tint. |
| `scale` | `number?` | Drawn size = RT size x `scale`. Default `1`. |
| `uv_min`, `uv_size` | `Vec2?` | Draw only part of the RT, see `ImageRT`. |

Inside `fn`:

- Coordinates are RT pixels: `(0, 0)` is the RT's top-left, not the screen's.
- Clipping and global alpha start fresh, and are restored afterwards. Clips left open are removed.
- An error in `fn` is written to the script's log; `RenderRT` still draws the RT and returns `false`.

```lua
local font = Render.LoadFont("default", 0, 600)
local card = Render.FindOrCreateRT("my_card", 200, 60)
local kills, shown = 0, -1

local function draw_card()
    Render.FilledRect(Vec2(0, 0), Vec2(200, 60), Color(30, 34, 46, 230), 10)
    Render.Text(font, 18, "Kills: " .. kills, Vec2(14, 18), Color(255, 255, 255))
    return true
end

callback.on_draw:set(function()
    if shown ~= kills then          -- redraw the card only when the value changed
        shown = kills
        Render.MarkDirtyRT(card)
    end
    Render.RenderRT(draw_card, card, Vec2(40, 400), Color(255, 255, 255))
end)
```

### `Render.ImageRT(rt, pos, color [, scale [, uv_min [, uv_size]]])`

Draws the RT's current contents without redrawing it.

| Name | Type | Description |
|---|---|---|
| `rt` | `integer` | RT handle. |
| `pos` | `Vec2` | Top-left corner on screen (rounded to whole pixels). |
| `color` | `Color` | Tint. |
| `scale` | `number?` | Drawn size = RT size x `scale`. Default `1`. |
| `uv_min` | `Vec2?` | Top-left of the part to draw, **in scaled pixels** (not 0-1). |
| `uv_size` | `Vec2?` | Size of the part to draw, in scaled pixels. Both components must be `> 0`. |

A part is drawn where it sits in the full RT: at `pos + uv_min`, `uv_size` big. For example `ImageRT(rt, pos, color, 1, Vec2(50, 25), Vec2(100, 50))` shows only the 100 x 50 area starting 50 px right and 25 px down, at that same place.

### `Render.ApplyMaskRT(mask [, invert])`

Only inside a `RenderRT` callback (does nothing elsewhere). Keeps what has been drawn into the RT so far only where `mask` covers it: white, opaque parts keep the content, black or transparent parts clear it. With `invert = true` it is the other way round. `mask` is an image handle or another RT handle, stretched over the RT (over the current clip rectangle if one is set).

```lua
local mask = Render.LoadImage("panorama/images/hud/objectives/healthbar_mask_png.vtex_c")
local bar = Render.FindOrCreateRT("my_bar", 200, 40)

callback.on_draw:set(function()
    if Render.ImageSize(mask).x == 0 then Render.MarkDirtyRT(bar) end   -- mask still loading
    Render.RenderRT(function()
        Render.Gradient(Vec2(0, 0), Vec2(200, 40), Color(255, 60, 60), Color(255, 220, 60), Color(255, 60, 60), Color(255, 220, 60))
        Render.ApplyMaskRT(mask)
    end, bar, Vec2(40, 460), Color(255, 255, 255))
end)
```

---

## Notifications

Both kinds of notification can be shown outside `on_draw` too.

### `Notification(args)`

Shows a notification card at the side of the screen. Cards stack, slide in and out, and follow the user's notification position and scale settings in the menu. Returns `false` when a card with the same `id` is still on screen (or waiting to appear), `true` otherwise.

`args` is a table; every field is optional:

| Field | Type | Description |
|---|---|---|
| `id` | `string\|number` | Duplicate guard: a new card with the id of a card still up is dropped. Leave empty to always show. |
| `duration` | `number` | Seconds on screen. Default `5`. |
| `timer` | `number` | Seconds for the card's progress bar to empty. `0` (default) = no bar. |
| `precise_timer` | `number` | Used as `timer` when `timer` isn't set. |
| `primary_text` | `string` | First line. |
| `secondary_text` | `string` | Second line. |
| `primary_image` | `string\|integer` | The image: a game image path (`"panorama/..."`, `"file://..."`), a [built-in icon](#built-in-icons) name such as `"camp_small"`, or a `LoadImage` handle of a game image. Any other string is drawn as a Font Awesome glyph (e.g. `"\u{f005}"`). |
| `primary_image_color` | `Color` | Image tint. Default white. |
| `rounding` | `number` | Corner radius of the image. |
| `hero` | `integer` | A hero id: shows that hero's portrait as a round image instead of `primary_image`. |
| `hero_icon` | `string` | A small badge over the image's bottom-right corner: a game image path or built-in icon name. |
| `active` | `boolean` | `true` (default) draws the card with the accent colour, `false` muted. |

Text colour markup: `\x07` starts a coloured run.

| Markup | Effect |
|---|---|
| `\x07RRGGBBAA` + one character | The following text in that colour (hex). The one character after the code (usually a space) is not shown. |
| `\x07DEFAULT` | Back to the default text colour. |
| `\x07{primary}` | The following text in the accent colour. |

```lua
local shown = Notification({
    id = "camp_up",
    duration = 6,
    timer = 6,
    primary_text = "\x07FFDF40FF Camp\x07DEFAULT is up",
    secondary_text = "Medium camp, \x07{primary}mid lane",
    primary_image = "camp_medium",
})
```

### `Renderer.DrawCenteredNotification(text [, duration])`

Shows `text` in a dark box in the upper middle of the screen, fading in and out. `duration` is in seconds (default `3`, clamped to `0.1`-`60`). Up to four lines show at once, stacked; a fifth removes the oldest. Empty text is ignored.

```lua
Renderer.DrawCenteredNotification("Script loaded", 2)
```
