# Logging & debugger

VITTLOCK has a three-level structured logger — `print`, `log.*` — plus the `Debugger` schema for the in-app console buffer.

---

## `print(...)` & `log.*`

All variadic; args are stringified into a space-separated message and source-tagged with the current script name via `__SCRIPT_NAME__`.

| Function | Level | Routes to |
|---|---|---|
| `print(...)` | info | Debugger console + DevLog |
| `log.info(...)` | info | ScriptLogEntry::LOG_INFO + Debugger |
| `log.warn(...)` | warn | ScriptLogEntry::LOG_WARN + Debugger (with `[WARN]` prefix) |
| `log.error(...)` | error | ScriptLogEntry::LOG_ERROR + Debugger (with `[ERROR]` prefix) |

### Example

```lua
log.info("range =", range:get_int())
log.warn("weird state detected")
log.error("entity handle", handle, "should be dead but isn't")
```

Both `print` and `log.info` are equivalent functionally. The naming convention is for code style — pick whichever feels right.

---

## Stringification rules

`StringifyVarArgs` walks through the variadic args:

| Lua type | Rendered as |
|---|---|
| `string` | verbatim |
| `int` | the integer rendered as a string |
| `double` / `float` | full-precision render |
| `bool` | `"true"` or `"false"` |
| any other | `"?"` |

So passing a table or `Vector3` to `log.info` prints `"?"` — stringify them first:

```lua
local p = Engine.GetEntityOrigin(handle)
log.info(string.format("pos=(%.2f, %.2f, %.2f)", p.x, p.y, p.z))
```

The args are space-separated, so multiple args give you a natural log line format. Trailing or multiple spaces are not collapsed.

---

## `Debugger`

The `Debugger` namespace is the in-app console buffer interface.

| Function | Returns | Description |
|---|---|---|
| `Debugger.GetLogs()` | string | Full log buffer text |
| `Debugger.ClearLogs()` | nil | Clear the console |
| `Debugger.SetClipboardText(text)` | nil | Copy text to system clipboard |

### Example: copy recent logs

```lua
callbacks.on_render(function()
    if ImGui.Begin("Logs##debug") then
        if ImGui.Button("Copy", 100, 25) then
            Debugger.SetClipboardText(Debugger.GetLogs())
        end
        ImGui.SameLine()
        if ImGui.Button("Clear", 100, 25) then
            Debugger.ClearLogs()
        end
    end
    ImGui.End()
end)
```

The clipboard helper uses `ImGui::SetClipboardText` (Win32 wrapped). Capable of holding multi-MB strings — but be careful in tight loops, the system clipboard will paste fast.

---

## Where the logs go

Output streams:

1. **`ScriptLogger` (per-script)** — `ScriptHandle::log::Push(Level, msg)`. Bounded ring buffer (256 entries). Visible in `RenderErrorPanel` only when the script has a current error — informational logs not currently surfaced in the UI.
2. **`CDebugger` console** — `GetDebugger()->AddLog()` — printed with the script tag. Bounded by `GetLogBuffer()`.
3. **`GetDevLog()`** — on-disk `debug.log` (file) — printed with `[Lua/<script>]` prefix. Persistent across runs.

All three are routed inside the `print` / `log.*` bindings — you get all three with a single call.

---

## Common patterns

### Throttled log

```lua
local lastWarn = 0
callbacks.on_frame(function()
    if bad_condition and ImGui.GetTime() - lastWarn > 1.0 then
        log.warn("throttled warning")
        lastWarn = ImGui.GetTime()
    end
end)
```

### Bullet-tracking log

```lua
callbacks.on_bullet_create(function(b)
    log.info(string.format("bullet: shooter=%d weapon=%s range=%.0f",
        b.shooter_handle, b.weapon_name or "?", b.range))
end)
```

### Lua-trace log + counter

```lua
local errors = 0
local function log_guard(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            errors = errors + 1
            log.error(string.format("guard #%d: %s", errors, tostring(err)))
        end
    end
end

local safe_callback = log_guard(function(cmd)
    cmd:AddButtonState(InputBitMask_t.IN_JUMP)
end)
callbacks.on_pre_createmove(safe_callback)
```

---

## Pitfalls

### `print(myTable)`

Prints `"?"` because tables aren't stringified. Convert via:

```lua
print("table=" .. tostring(myTable))  -- gives "table: 0xADDR-like"
print(jsonish(myTable))                 -- implement your own
```

### Calling `print` from `on_pre_createmove`

Each call writes to `DevLog` synchronously, which may open the file if not already open. Spill 200 print calls per tick and your ngôi I/O will cap the tick rate. Aggregate into a single message:

```lua
local msgs = {}
for i = 1, 10 do
   msgs[i] = i * i
end
log.info(table.concat(msgs, " "))
```

### Log buffer growth

`ScriptLogger` ring buffer is 256 entries — overflow drops the oldest entry and pushes the new one. `Debugger` and `DevLog` are bounded at the engine level too, but their write rate is unbounded by you — heavy logging will spike file I/O.

### `log.error` is not a raise

It does not pause execution, does not propagate exceptions. Just a label on the line. To abort your callback, wrap in `pcall` and stack-unwind:

```lua
local function safe_a()
    if critical_failure then
        log.error("cancelling work")
        return
    end
    -- continue
end
```

---

## See also

- [examples/](../examples/) — most examples use `log.*` for status lines