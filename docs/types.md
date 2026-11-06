# Types

The value types used across the API: `Vector` (3D world points and directions), `Angle` (view angles in degrees), `Vec2` (screen positions and sizes in pixels) and `Color` (RGBA). All four are global constructors. This page also covers what the script environment adds to the standard `table` and `math` libraries.

Values of these types are userdata. Assigning one to another variable does not copy it: both names point to the same object, so in-place methods (`Normalize`, `AddInPlace`, `Set`, ...) change it for both. Use `:Clone()` when you need a separate copy.

```lua
local a = Vector(1, 2, 3)
local b = a          -- same object
local c = a:Clone()  -- independent copy
a:SetX(10)
print(b.x, c.x)      -- 10.0  1.0
```

Methods come in two styles:

- **Returning a new value:** `Normalized`, `Scaled`, `Rotated`, `Lerp`, `Clone`, ... The receiver is not changed.
- **Changing the receiver:** `Normalize`, `Scale`, `Rotate`, `SetX` return nothing. `AddInPlace`, `SubInPlace`, `MulInPlace`, `DivInPlace`, `Set`, `LerpInPlace`, `CopyFrom` and `Negate` return the same object, so calls can be chained.

```lua
local v = Vector(1, 2, 3):Clone():AddInPlace(Vector(1, 0, 0)):MulInPlace(2)
print(v)  -- Vector(4.000000, 4.000000, 6.000000)
```

---

## Vector

A 3D vector of 32-bit floats. Z is up.

### `Vector([x [, y [, z]]])`

Creates a vector. Missing components are 0.

```lua
local origin = Vector()          -- 0, 0, 0
local p = Vector(100, 200, 50)
```

### Fields

| Name | Type | Description |
|---|---|---|
| `x` | number | X component (read / write) |
| `y` | number | Y component (read / write) |
| `z` | number | Z component (read / write) |

### Operators

| Expression | Result |
|---|---|
| `a + b`, `a - b` | Per component. `b` can be a Vector, a Vec2 (its z counts as 0) or a number (applied to all three). |
| `a * b`, `a / b` | Per component. `b` can be a Vector, a Vec2 (its z counts as 1) or a number. |
| `2 * v`, `10 - v` | A number on the left works too. |
| `a == b` | True only when both are Vectors with exactly equal components. Comparing with another type gives `false` (no error). |
| `tostring(v)` | `"Vector(1.000000, 2.000000, 3.000000)"` |

Notes:
- There is no unary minus: `-v` raises an error. Use `v * -1` or `v:Clone():Negate()`.
- Put the Vector on the left when mixing it with a Vec2. `Vec2 + Vector` raises an error, because the Vec2 operator only accepts a Vec2 or a number.
- Any other operand raises `Vector: bad operand (Vector, Vec2 or number expected)`.
- `==` compares floats exactly. Use `a:Distance(b) < 0.01` for "close enough".

### `v:Distance(other)`

Distance between the two points. Returns a number.

### `v:Distance2D(other)`

Distance ignoring z. Returns a number.

### `v:DistanceSqr2D(other)`

Squared distance ignoring z. Cheaper than `Distance2D` when you only compare distances. Returns a number.

### `v:IsInRange2D(other, range)`

True when `other` is at most `range` units away in the XY plane.

| Name | Type | Description |
|---|---|---|
| `other` | Vector | The other point |
| `range` | number | Maximum distance (inclusive) |

### `v:Length()`, `v:LengthSqr()`, `v:Length2D()`, `v:Length2DSqr()`

The length, the squared length, and the same two for the x and y components only. Each returns a number.

### `v:Normalized()`

Returns a unit-length copy. A zero-length vector returns `Vector(0, 0, 0)`.

### `v:Normalize()`

Normalizes in place. Returns nothing.

### `v:Dot(other)`, `v:Dot2D(other)`

The dot product, and the dot product of the x and y components. Each returns a number.

### `v:Cross(other)`

Returns the cross product as a new Vector.

### `v:Scaled(scale)`

Returns a copy multiplied by `scale`.

### `v:Scale(scale)`

Multiplies in place. Returns nothing.

### `v:Rotated(angle)`

Returns a copy rotated counterclockwise around the Z axis. z is unchanged.

| Name | Type | Description |
|---|---|---|
| `angle` | number or Angle | Degrees, or an Angle (only its yaw is used) |

Any other argument raises `Vector: Rotate needs a number or an Angle`.

### `v:Rotate(angle)`

Same as `Rotated`, but in place. Returns nothing.

### `v:Lerp(other, t)`

Returns `v + (other - v) * t`: `t = 0` gives `v`, `t = 1` gives `other`. `t` is not clamped.

### `v:LerpInPlace(other, t)`

Same as `Lerp`, but in place. Returns `v`.

### `v:MoveForward(angle, distance)`

Returns the point `distance` units from `v` along the forward direction of `angle`.

| Name | Type | Description |
|---|---|---|
| `angle` | Angle | Direction (pitch and yaw) |
| `distance` | number | Units to move |

```lua
-- A point 500 units ahead of a position, along some view angles.
local function point_ahead(pos, view)
    return pos:MoveForward(view, 500)
end
```

### `v:ToAngle()`

Returns the Angle that looks along `v`, with roll 0.

Notes:
- Pitch and yaw come back in **[0, 360)**: looking 45 degrees up gives pitch 315, not -45. Call `:Normalize()` on the result to get [-180, 180].
- For a vector straight up or down (x = y = 0), yaw is 0 and pitch is 270 (up) or 90 (down).

```lua
local function aim_angle(from, to)
    local ang = (to - from):ToAngle()
    ang:Normalize()
    return ang
end
```

### `v:DirectionTo(target [, distance])`

Returns the unit direction from `v` to `target`, multiplied by `distance`. Returns a zero vector when the points are equal.

| Name | Type | Description |
|---|---|---|
| `target` | Vector | Point to aim at |
| `distance` | number, optional | Length of the result. Default 1. |

### `v:Extend2D(target, distance)`

Returns `v` moved `distance` units toward `target` in the XY plane. z is kept from `v`. If both points have the same x and y, the result is a copy of `v`.

| Name | Type | Description |
|---|---|---|
| `target` | Vector | Point to move toward |
| `distance` | number | Units to move (negative moves away) |

### `v:Extrapolate(direction, scale)`

Returns `v + direction * scale`.

| Name | Type | Description |
|---|---|---|
| `direction` | Vector | Direction (usually a velocity or a unit vector) |
| `scale` | number | Multiplier, for example a time in seconds |

```lua
-- Where a target will be in 0.2 s if it keeps its velocity.
local function predict(pos, velocity)
    return pos:Extrapolate(velocity, 0.2)
end
```

### `v:AngleBetween2D(middle, other)`

The angle in radians at `middle` between the lines to `v` and to `other`, measured in the XY plane. The result is in [0, pi], with no sign. Returns 0 when either line has zero length.

| Name | Type | Description |
|---|---|---|
| `middle` | Vector | The vertex |
| `other` | Vector | The third point |

```lua
local a = Vector(1, 0, 0):AngleBetween2D(Vector(0, 0, 0), Vector(0, 1, 0))
-- a == math.pi / 2
```

### `v:Perpendicular2D()`

Returns `Vector(-y, x, z)`: `v` turned 90 degrees counterclockwise in the XY plane.

### `v:Negate()`

Negates all three components in place. Returns `v`.

### `v:ToScreen()`

Projects the world point to screen pixels.

Returns two values:
- `Vec2`: the screen position. It can be outside the screen.
- `boolean`: true when the point is in front of the camera.

Notes:
- Call it in `on_draw` (see [callbacks](callbacks.md)). The projection uses the current frame's camera.
- `true` does not mean the point is inside the screen. Check the position against the screen size yourself if you need that.

```lua
callback.on_draw:set(function()
    local pos, in_front = Vector(0, 0, 0):ToScreen()
    if in_front then
        -- draw at pos.x, pos.y with Render.*
    end
end)
```

### `v:IsVisible()`

Returns the second result of `ToScreen` only: true when the point is in front of the camera. This is **not** a line-of-sight or occlusion check.

### `v:Get()`

Returns `x, y, z` as three numbers.

### `v:GetX()`, `v:GetY()`, `v:GetZ()`

Return one component.

### `v:SetX(value)`, `v:SetY(value)`, `v:SetZ(value)`

Set one component. Return nothing.

### `v:AddInPlace(other)`, `v:SubInPlace(other)`, `v:MulInPlace(other)`, `v:DivInPlace(other)`

The arithmetic operators done in place, with the same operand rules: a Vector, a Vec2 (z counts as 0 for add and subtract, 1 for multiply and divide) or a number. Return `v`.

### `v:Set([x [, y [, z]]])`

Sets all three components. Returns `v`.

Note: missing arguments become **0**, not "unchanged". `v:Set(5)` gives `Vector(5, 0, 0)`. Use `SetX` to change a single component.

### `v:CopyFrom(other)`

Copies the components of `other` into `v`. Returns `v`.

### `v:Clone()`

Returns a new Vector with the same components.

### `v:IsZero([tolerance])`

True when every component is within `tolerance` of 0. The default `tolerance` is 0.01.

### `v:IsValid()`, `v:IsInvalid()`

`IsValid` is true when all components are finite. `IsInvalid` is true when any component is NaN or infinite. Use them to check game reads before doing math with them.

---

## Angle

Euler angles in degrees: `pitch` (positive looks down), `yaw` (rotation around Z) and `roll`.

### `Angle([pitch [, yaw [, roll]]])`

Creates an angle. Missing components are 0.

### Fields

| Name | Type | Description |
|---|---|---|
| `pitch` | number | Pitch in degrees (read / write) |
| `yaw` | number | Yaw in degrees (read / write) |
| `roll` | number | Roll in degrees (read / write) |

### Operators

| Expression | Result |
|---|---|
| `a + b`, `a - b`, `a * b`, `a / b` | Per component. Each side can be an Angle or a number. |
| `a == b` | Exact comparison of all three components. False for other types. |
| `tostring(a)` | `"Angle(0.000000, 90.000000, 0.000000)"` |

Arithmetic does not wrap the result. Call `Normalize()` afterwards when you need [-180, 180]. Any other operand raises `Angle: bad operand (Angle or number expected)`. There is no unary minus.

### `a:GetForward()`

Returns the unit forward direction as a Vector.

```lua
local fwd = Angle(0, 90, 0):GetForward()  -- about Vector(0, 1, 0)
```

### `a:GetVectors()`

Returns three Vectors: `forward, right, up`.

### `a:GetPitch()`, `a:GetYaw()`, `a:GetRoll()`

Return one component.

### `a:SetPitch(value)`, `a:SetYaw(value)`, `a:SetRoll(value)`

Set one component. Return nothing.

### `a:Normalize()`

Wraps each component into [-180, 180] in place. Returns nothing.

### `a:Clamp()`

Clamps in place to valid view angles: pitch to [-89, 89], yaw to [-180, 180] and roll to 0. Returns nothing.

Note: yaw is **clamped**, not wrapped, so a yaw of 190 becomes 180. Call `Normalize()` first.

```lua
local function safe_view(ang)
    local a = Angle(ang.pitch, ang.yaw, ang.roll)
    a:Normalize()
    a:Clamp()
    return a
end
```

### `a:IsValid()`

True when all three components are finite.

---

## Vec2

A 2D vector of floats, used for screen positions and sizes in pixels.

### `Vec2([x [, y]])`

Creates a Vec2. Missing components are 0.

### Fields

| Name | Type | Description |
|---|---|---|
| `x` | number | X (read / write) |
| `y` | number | Y (read / write) |

### Operators

| Expression | Result |
|---|---|
| `a + b`, `a - b`, `a * b`, `a / b` | Per component. Each side can be a Vec2 or a number. |
| `a == b` | Exact comparison. False for other types. |
| `tostring(v)` | `"Vec2(1.000000, 2.000000)"` |

Any other operand, including a Vector, raises `Vec2: bad operand (Vec2 or number expected)`. There is no unary minus.

```lua
local center = Vec2(1920, 1080) / 2
local box_min = center - Vec2(50, 50)
local box_max = center + 50
```

### `v:Length()`

Returns the length.

### `v:Get()`

Returns `x, y`.

### `v:GetX()`, `v:GetY()`, `v:SetX(value)`, `v:SetY(value)`

Read or set one component. The setters return nothing.

### `v:AddInPlace(other)`, `v:SubInPlace(other)`, `v:MulInPlace(other)`, `v:DivInPlace(other)`

The arithmetic operators done in place. `other` is a Vec2 or a number. Return `v`.

### `v:Set([x [, y]])`

Sets both components. Missing arguments become 0. Returns `v`.

### `v:CopyFrom(other)`

Copies `other` into `v`. Returns `v`.

### `v:Clone()`

Returns a new Vec2 with the same components.

### `v:IsZero([tolerance])`

True when both components are within `tolerance` of 0. The default is 0.01.

---

## Color

An RGBA color. Each channel is an integer from 0 to 255.

### `Color(...)`

| Call | Result |
|---|---|
| `Color()` | Opaque white (255, 255, 255, 255) |
| `Color(r, g, b)` | The given channels with alpha 255 |
| `Color(r, g, b, a)` | The given channels |
| `Color("#RRGGBB")` / `Color("RRGGBB")` | From a hex string, alpha 255 |
| `Color("#RRGGBBAA")` / `Color("RRGGBBAA")` | From a hex string with alpha |
| `Color(0xRRGGBBAA)` | From a packed integer |
| `Color(0xRRGGBB, a)` | From a packed RGB integer and an alpha of 0-255 |

Channel values are rounded and clamped to 0-255 (NaN becomes 0). A hex string that is not 6 or 8 hex digits raises `Color: bad hex string`.

```lua
local red   = Color(255, 0, 0)
local green = Color("00FF0080")          -- g = 255, a = 128
local blue  = Color(0x0000FFFF)
local dim   = Color(0xFFFFFF, 100)       -- white, a = 100
```

Note: `Color()` is white, not black or transparent.

### Fields

| Name | Type | Description |
|---|---|---|
| `r` | integer | Red, 0-255 |
| `g` | integer | Green, 0-255 |
| `b` | integer | Blue, 0-255 |
| `a` | integer | Alpha, 0-255 |

Assigning a field rounds and clamps the value: `c.r = 300` stores 255.

### Operators

| Expression | Result |
|---|---|
| `a == b` | True when all four channels match. False for other types. |
| `tostring(c)` | `"#RRGGBBAA"`, for example `"#01020304"` |

Colors have no arithmetic operators. Use `Lerp`, `AlphaModulate` or the fields.

### `c:Set(r, g, b [, a])`

Sets the channels (0-255). `a` defaults to 255. Returns `c`.

### `c:AsFraction(r, g, b, a)`

Sets the color from four 0-1 fractions. All four are required. Returns `c`.

### `c:AsInt(rgba)`

Sets the color from a 0xRRGGBBAA integer. Returns `c`.

```lua
local packed = Color(10, 20, 30, 40):ToInt()
local back = Color():AsInt(packed)   -- == Color(10, 20, 30, 40)
```

### `c:AsHsv(h, s, v [, a])`

Sets the color from HSV. Returns `c`.

| Name | Type | Description |
|---|---|---|
| `h` | number | Hue, 0-1. Wraps around, so 1.25 is the same as 0.25. |
| `s` | number | Saturation, 0-1 |
| `v` | number | Value, 0-1 |
| `a` | number, optional | Alpha, 0-1. Default 1. |

```lua
-- Rainbow color that cycles every 4 seconds.
local function rainbow(time)
    return Color():AsHsv(time / 4, 1, 1)
end
```

### `c:AsHsl(h, s, l [, a])`

Same as `AsHsv`, but with hue, saturation and lightness (all 0-1, hue wraps). Returns `c`.

### `c:ToFraction()`

Returns `r, g, b, a` as 0-1 numbers.

### `c:ToInt()`

Returns the color as a 0xRRGGBBAA integer (from 0 to 4294967295).

### `c:ToHsv()`

Returns `h, s, v`, each 0-1. Alpha is not included.

### `c:ToHsl()`

Returns `h, s, l`, each 0-1. Alpha is not included.

### `c:ToHex()`

Returns `"#RRGGBBAA"` (the same as `tostring(c)`).

### `c:Unpack()`

Returns `r, g, b, a` as four integers.

### `c:Lerp(other, t)`

Returns a new color between `c` (`t = 0`) and `other` (`t = 1`). All four channels are blended and the result is clamped.

### `c:LerpInPlace(other, t)`

Same as `Lerp`, but in place. Returns `c`.

### `c:Grayscale([weight])`

Returns a new color blended toward its gray (0.299 R + 0.587 G + 0.114 B). `weight` (0-1, default 1) sets how far to blend. Alpha is kept.

### `c:AlphaModulate(alpha)`

Returns a new color with alpha multiplied by `alpha`, for example 0.5 for half as opaque.

```lua
local base = Color(255, 200, 0)
local faded = base:AlphaModulate(0.25)   -- a = 64
```

### `c:Clone()`

Returns a new Color with the same channels.

### `c:IsZero([tolerance])`

True when all four channels, alpha included, are within `tolerance` of 0. The default is 0.01. Channels are whole numbers, so with the default this means fully transparent black.

---

## table extensions

`table` has every standard Lua 5.4 function (`insert`, `remove`, `sort`, `concat`, `unpack`, `pack`, `move`) plus the helpers below.

The iteration order of `pairs` is unspecified. Helpers built on it (`Keys`, `Values`, `Map`, `Filter`, ...) return results in no particular order.

### `table.IsEmpty(t)`

True when `t` has no keys at all.

### `table.Clear(t)`

Removes every key from `t` in place.

### `table.Length(t)`

Counts all keys, not only the array part. `table.Length({1, 2, x = 3})` is 3.

### `table.Keys(t)`, `table.Values(t)`

Return a new array of the keys or of the values.

### `table.Sum(t)`

Adds up the numeric values. Non-number values are skipped.

### `table.Reverse(t)`

Returns a new array with the array part of `t` in reverse order.

### `table.CopyShallow(t [, ignore_mt])`

Returns a one-level copy. The copy keeps the metatable of `t` unless `ignore_mt` is true.

### `table.Copy(t)`

Returns a deep copy: nested tables in keys and values are copied too, and cycles are handled. Metatables are shared with the original, not copied. Userdata such as a Vector is not duplicated.

### `table.KvSwap(t [, v_to_true])`

Returns a new table that maps each value of `t` to its key. With `v_to_true`, it maps each value to `true`, which gives a lookup set.

```lua
local set = table.KvSwap({ "a", "b" }, true)   -- { a = true, b = true }
```

### `table.Merge(...)`

Returns a new array with the array parts of all arguments appended in order. `nil` arguments are skipped.

```lua
local all = table.Merge({ 1, 2 }, { 3 })   -- { 1, 2, 3 }
```

### `table.MergeHm(...)`

Returns a new table with the key/value pairs of all arguments. Later arguments overwrite earlier ones. `nil` arguments are skipped.

### `table.Diff(new_t, old_t)`

Returns the pairs of `new_t` whose value is not identical (`rawequal`) to `old_t[key]`. Keys that exist only in `old_t` are not reported. Userdata values such as a Vector are compared by identity, so two equal but separate Vectors count as different.

### `table.Equals(a, b)`

Deep comparison. True when both have the same keys and every value is equal, using `==` for non-tables (so Vector, Angle, Vec2 and Color compare by value) and recursing into nested tables.

### `table.Sorted(t [, comp])`

Sorts `t` in place with `table.sort` and returns the same table.

### `table.Map(t, fn)`

Calls `fn(value, key)` for every pair and returns a new array of the results. Keys are not kept, and `nil` results leave no entry.

### `table.Filter(t, fn)`

Returns a new array of the values for which `fn(value, key)` returns a truthy value. Keys are not kept.

```lua
local big = table.Filter({ 1, 5, 10 }, function(v) return v > 3 end)   -- { 5, 10 } in some order
```

### `table.Any(t, fn)`, `table.All(t, fn)`

`Any` is true when `fn(value, key)` is truthy for at least one pair. `All` is true when it is truthy for every pair, and also for an empty table.

### `table.Find(t, element)`

Searches by identity (`rawequal`). Returns `value, key` for the first match (in `pairs` order), or `nil`.

```lua
local _, key = table.Find({ a = 5 }, 5)   -- key == "a"
```

### `table.RemoveElement(t, element)`

Removes the first array element that matches and shifts the rest down. Returns `true` if something was removed.

| Name | Type | Description |
|---|---|---|
| `t` | table | An array |
| `element` | any or function | A value (compared with `rawequal`) or a predicate `fn(value, index)` |

```lua
local list = { 1, 2, 3 }
table.RemoveElement(list, 2)                              -- list is { 1, 3 }
table.RemoveElement(list, function(v) return v > 2 end)   -- list is { 1 }
```

---

## math extensions

`math` has every standard Lua 5.4 function, plus these older functions that Lua 5.4 dropped. They are only added when the standard library does not already have them, so they behave the same either way.

| Function | Returns |
|---|---|
| `math.pow(x, y)` | x raised to the power y |
| `math.atan2(y, x)` | Arc tangent of y / x in radians, using the signs of both to pick the quadrant (same as `math.atan(y, x)`) |
| `math.log10(x)` | Base-10 logarithm |
| `math.cosh(x)`, `math.sinh(x)`, `math.tanh(x)` | Hyperbolic functions |
| `math.ldexp(m, e)` | m * 2^e |
| `math.frexp(x)` | `m, e` with x = m * 2^e and 0.5 <= abs(m) < 1 |

`string`, `utf8` and `coroutine` are the standard Lua 5.4 libraries, unchanged.
