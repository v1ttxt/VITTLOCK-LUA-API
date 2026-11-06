---@meta
-- Types: Vector, Angle, Vec2, Color.

------------------------------------------------------------------------------
-- Vector
------------------------------------------------------------------------------

---A 3D vector (world positions, directions, velocities). Values are 32-bit floats.
---Arithmetic: `+` and `-` accept a Vector, a Vec2 (z = 0) or a number (applied to all three);
---`*` and `/` work per component and accept a Vector, a Vec2 (z = 1) or a number.
---`==` is true only for two Vectors with exactly equal components. There is no unary minus.
---@class Vector
---@overload fun(x?: number, y?: number, z?: number): Vector
---@field x number
---@field y number
---@field z number
---@operator add(Vector|Vec2|number): Vector
---@operator sub(Vector|Vec2|number): Vector
---@operator mul(Vector|Vec2|number): Vector
---@operator div(Vector|Vec2|number): Vector
Vector = {}

---Distance to another point.
---@param other Vector
---@return number
function Vector:Distance(other) end

---Distance to another point, ignoring z.
---@param other Vector
---@return number
function Vector:Distance2D(other) end

---Squared distance to another point, ignoring z.
---@param other Vector
---@return number
function Vector:DistanceSqr2D(other) end

---True when `other` is within `range` units in the XY plane (inclusive).
---@param other Vector
---@param range number
---@return boolean
function Vector:IsInRange2D(other, range) end

---Returns a unit-length copy (zero vector when the length is 0).
---@return Vector
function Vector:Normalized() end

---Normalizes in place (zero vector when the length is 0).
function Vector:Normalize() end

---Dot product.
---@param other Vector
---@return number
function Vector:Dot(other) end

---Dot product of the x and y components.
---@param other Vector
---@return number
function Vector:Dot2D(other) end

---Returns a copy multiplied by `scale`.
---@param scale number
---@return Vector
function Vector:Scaled(scale) end

---Multiplies in place by `scale`.
---@param scale number
function Vector:Scale(scale) end

---Length.
---@return number
function Vector:Length() end

---Squared length.
---@return number
function Vector:LengthSqr() end

---Length of the x and y components.
---@return number
function Vector:Length2D() end

---Squared length of the x and y components.
---@return number
function Vector:Length2DSqr() end

---Returns a copy rotated counterclockwise around the Z axis. z is unchanged.
---@param angle number|Angle degrees, or an Angle (its yaw is used)
---@return Vector
function Vector:Rotated(angle) end

---Rotates in place counterclockwise around the Z axis. z is unchanged.
---@param angle number|Angle degrees, or an Angle (its yaw is used)
function Vector:Rotate(angle) end

---Linear interpolation from this vector to `other`.
---@param other Vector
---@param t number 0 = this vector, 1 = other
---@return Vector
function Vector:Lerp(other, t) end

---Cross product.
---@param other Vector
---@return Vector
function Vector:Cross(other) end

---Returns this point moved `distance` units along the forward direction of `angle`.
---@param angle Angle
---@param distance number
---@return Vector
function Vector:MoveForward(angle, distance) end

---Returns the view angles that look along this vector. Pitch and yaw are in [0, 360), roll is 0.
---@return Angle
function Vector:ToAngle() end

---Projects the world point to screen pixels.
---@return Vec2 screen screen position (may be outside the screen)
---@return boolean in_front true when the point is in front of the camera
function Vector:ToScreen() end

---True when the point is in front of the camera (same as the second result of ToScreen). Not a line-of-sight check.
---@return boolean
function Vector:IsVisible() end

---Returns the three components.
---@return number x
---@return number y
---@return number z
function Vector:Get() end

---@return number
function Vector:GetX() end

---@return number
function Vector:GetY() end

---@return number
function Vector:GetZ() end

---@param value number
function Vector:SetX(value) end

---@param value number
function Vector:SetY(value) end

---@param value number
function Vector:SetZ(value) end

---Adds in place and returns self (Vector, Vec2 with z = 0, or number).
---@param other Vector|Vec2|number
---@return Vector self
function Vector:AddInPlace(other) end

---Subtracts in place and returns self (Vector, Vec2 with z = 0, or number).
---@param other Vector|Vec2|number
---@return Vector self
function Vector:SubInPlace(other) end

---Multiplies per component in place and returns self (Vector, Vec2 with z = 1, or number).
---@param other Vector|Vec2|number
---@return Vector self
function Vector:MulInPlace(other) end

---Divides per component in place and returns self (Vector, Vec2 with z = 1, or number).
---@param other Vector|Vec2|number
---@return Vector self
function Vector:DivInPlace(other) end

---Sets all three components and returns self. Missing components become 0.
---@param x? number
---@param y? number
---@param z? number
---@return Vector self
function Vector:Set(x, y, z) end

---Interpolates in place toward `other` and returns self.
---@param other Vector
---@param t number
---@return Vector self
function Vector:LerpInPlace(other, t) end

---Copies the components of `other` and returns self.
---@param other Vector
---@return Vector self
function Vector:CopyFrom(other) end

---Returns a new Vector with the same components.
---@return Vector
function Vector:Clone() end

---Returns the unit direction from this point to `target`, multiplied by `distance`.
---@param target Vector
---@param distance? number default 1
---@return Vector
function Vector:DirectionTo(target, distance) end

---Angle in radians at `middle` between this point and `other`, in the XY plane. Range [0, pi]; 0 when a side has zero length.
---@param middle Vector
---@param other Vector
---@return number radians
function Vector:AngleBetween2D(middle, other) end

---Returns this point moved `distance` units toward `target` in the XY plane. z is kept.
---@param target Vector
---@param distance number
---@return Vector
function Vector:Extend2D(target, distance) end

---Returns (-y, x, z): the vector turned 90 degrees counterclockwise in the XY plane.
---@return Vector
function Vector:Perpendicular2D() end

---Negates all components in place and returns self.
---@return Vector self
function Vector:Negate() end

---True when every component is within `tolerance` of 0.
---@param tolerance? number default 0.01
---@return boolean
function Vector:IsZero(tolerance) end

---Returns this + direction * scale.
---@param direction Vector
---@param scale number
---@return Vector
function Vector:Extrapolate(direction, scale) end

---True when any component is NaN or infinite.
---@return boolean
function Vector:IsInvalid() end

---True when every component is finite.
---@return boolean
function Vector:IsValid() end

------------------------------------------------------------------------------
-- Angle
------------------------------------------------------------------------------

---Euler angles in degrees (view angles). Pitch is positive looking down.
---Arithmetic `+ - * /` works per component with an Angle or a number. `==` compares exactly.
---@class Angle
---@overload fun(pitch?: number, yaw?: number, roll?: number): Angle
---@field pitch number
---@field yaw number
---@field roll number
---@operator add(Angle|number): Angle
---@operator sub(Angle|number): Angle
---@operator mul(Angle|number): Angle
---@operator div(Angle|number): Angle
Angle = {}

---Unit forward direction.
---@return Vector
function Angle:GetForward() end

---Forward, right and up unit vectors.
---@return Vector forward
---@return Vector right
---@return Vector up
function Angle:GetVectors() end

---@return number
function Angle:GetPitch() end

---@return number
function Angle:GetYaw() end

---@return number
function Angle:GetRoll() end

---@param value number
function Angle:SetPitch(value) end

---@param value number
function Angle:SetYaw(value) end

---@param value number
function Angle:SetRoll(value) end

---Wraps each component into [-180, 180] in place.
function Angle:Normalize() end

---Clamps in place: pitch to [-89, 89], yaw to [-180, 180] (clamped, not wrapped), roll set to 0.
function Angle:Clamp() end

---True when every component is finite.
---@return boolean
function Angle:IsValid() end

------------------------------------------------------------------------------
-- Vec2
------------------------------------------------------------------------------

---A 2D vector (screen positions and sizes in pixels).
---Arithmetic `+ - * /` works per component with a Vec2 or a number. `==` compares exactly.
---@class Vec2
---@overload fun(x?: number, y?: number): Vec2
---@field x number
---@field y number
---@operator add(Vec2|number): Vec2
---@operator sub(Vec2|number): Vec2
---@operator mul(Vec2|number): Vec2
---@operator div(Vec2|number): Vec2
Vec2 = {}

---Length.
---@return number
function Vec2:Length() end

---Returns both components.
---@return number x
---@return number y
function Vec2:Get() end

---@return number
function Vec2:GetX() end

---@return number
function Vec2:GetY() end

---@param value number
function Vec2:SetX(value) end

---@param value number
function Vec2:SetY(value) end

---Adds in place and returns self.
---@param other Vec2|number
---@return Vec2 self
function Vec2:AddInPlace(other) end

---Subtracts in place and returns self.
---@param other Vec2|number
---@return Vec2 self
function Vec2:SubInPlace(other) end

---Multiplies per component in place and returns self.
---@param other Vec2|number
---@return Vec2 self
function Vec2:MulInPlace(other) end

---Divides per component in place and returns self.
---@param other Vec2|number
---@return Vec2 self
function Vec2:DivInPlace(other) end

---Sets both components and returns self. Missing components become 0.
---@param x? number
---@param y? number
---@return Vec2 self
function Vec2:Set(x, y) end

---Copies the components of `other` and returns self.
---@param other Vec2
---@return Vec2 self
function Vec2:CopyFrom(other) end

---Returns a new Vec2 with the same components.
---@return Vec2
function Vec2:Clone() end

---True when both components are within `tolerance` of 0.
---@param tolerance? number default 0.01
---@return boolean
function Vec2:IsZero(tolerance) end

------------------------------------------------------------------------------
-- Color
------------------------------------------------------------------------------

---An RGBA color. Channels are integers 0-255; assigning a field rounds and clamps.
---`Color()` is opaque white. `tostring` gives "#RRGGBBAA". `==` compares all four channels.
---Colors have no arithmetic operators.
---@class Color
---@overload fun(): Color
---@overload fun(hex: string): Color
---@overload fun(rgba: integer): Color
---@overload fun(rgb: integer, alpha: number): Color
---@overload fun(r: number, g: number, b: number, a?: number): Color
---@field r integer
---@field g integer
---@field b integer
---@field a integer
Color = {}

---Sets the color from 0-1 fractions and returns self.
---@param r number
---@param g number
---@param b number
---@param a number
---@return Color self
function Color:AsFraction(r, g, b, a) end

---Sets the color from a 0xRRGGBBAA integer and returns self.
---@param rgba integer
---@return Color self
function Color:AsInt(rgba) end

---Sets the color from HSV (all 0-1; hue wraps) and returns self.
---@param h number
---@param s number
---@param v number
---@param a? number default 1
---@return Color self
function Color:AsHsv(h, s, v, a) end

---Sets the color from HSL (all 0-1; hue wraps) and returns self.
---@param h number
---@param s number
---@param l number
---@param a? number default 1
---@return Color self
function Color:AsHsl(h, s, l, a) end

---Channels as 0-1 fractions.
---@return number r
---@return number g
---@return number b
---@return number a
function Color:ToFraction() end

---The color as a 0xRRGGBBAA integer.
---@return integer
function Color:ToInt() end

---Hue, saturation and value, each 0-1.
---@return number h
---@return number s
---@return number v
function Color:ToHsv() end

---Hue, saturation and lightness, each 0-1.
---@return number h
---@return number s
---@return number l
function Color:ToHsl() end

---The color as "#RRGGBBAA".
---@return string
function Color:ToHex() end

---Returns a new color interpolated toward `other` (all four channels).
---@param other Color
---@param t number 0 = this color, 1 = other
---@return Color
function Color:Lerp(other, t) end

---Returns a new color blended toward its luminance gray. Alpha is kept.
---@param weight? number 0-1, default 1 (fully gray)
---@return Color
function Color:Grayscale(weight) end

---Returns a new color with alpha multiplied by `alpha`.
---@param alpha number
---@return Color
function Color:AlphaModulate(alpha) end

---Returns a new Color with the same channels.
---@return Color
function Color:Clone() end

---Returns the four channels.
---@return integer r
---@return integer g
---@return integer b
---@return integer a
function Color:Unpack() end

---Sets the channels (0-255) and returns self.
---@param r number
---@param g number
---@param b number
---@param a? number default 255
---@return Color self
function Color:Set(r, g, b, a) end

---Interpolates in place toward `other` and returns self.
---@param other Color
---@param t number
---@return Color self
function Color:LerpInPlace(other, t) end

---True when all four channels (alpha too) are within `tolerance` of 0.
---@param tolerance? number default 0.01
---@return boolean
function Color:IsZero(tolerance) end

-- The table and math additions are declared in core.lua.
