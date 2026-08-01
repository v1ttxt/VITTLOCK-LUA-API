# `timers`

A simple frame-driven scheduler for one-shot and repeating callbacks. Owned by the script that created them — timers only tick while their owning script is **enabled**.

---

## API

| Function | Returns | Description |
|---|---|---|
| `timers.after(ms, fn)` | `int` id | Fire `fn()` once after `ms` milliseconds |
| `timers.every(ms, fn)` | `int` id | Fire `fn()` every `ms` milliseconds until cancelled or script disabled |
| `timers.cancel(id)` | nil | Cancel a timer by id |

---

## Tick model

The timer scheduler ticks each frame after the cmd is sent:

```text
tick → after-cmd hook → timer tick → on_frame → entity/key poll → hot-reload poll
```

So timer fire time is **frame-aligned**, not hardwall time. A 5000 ms timer fires on the first frame after 5000 ms elapses since `now` — which on a 60 fps client is at most ~17 ms late. On a frame-dropped tick that could be later. There's no compensating the lag either — `nextFire += interval`, so missed fires do not catch up; the next fire happens one `interval` later than the current fire.

Owner gating: every timer carries a `ScriptHandle*`. The dispatching loop skips any timer whose `owner->enabled == false` — disabled scripts will queue but not execute. `CancelAllFor(owner)` is called on reload/shutdown.

---

## Examples

### One-shot after delay

```lua
timers.after(2000, function()
    log.info("2s elapsed")
end)
```

### Repeat + cancel

```lua
local heartbeat = timers.every(5000, function()
    log.info("still alive")
end)

m:button("Stop heartbeat", function()
    timers.cancel(heartbeat)
end)
```

### Initial-delay then steady interval

`timers.every(ms, fn)` fires after the first `ms`, not immediately. If you need an immediate fire + steady repetition, emulate:

```lua
local function fire()
    log.info("tick")
    if runState then timerId = timers.every(period, fire) end
end
runState = true
fire()  -- immediate first
```

Or just use `after` chaining:

```lua
local function step()
    log.info("tick")
    if not shouldStop then timers.after(period, step) end
end
timers.after(initialDelay, step)
```

### Real-time hour beacon

```lua
local count = 0
local hb = timers.every(3600000, function()
    count = count + 1
    log.info(string.format("hour %d @ curtime=%.1f", count, Engine.GetCurTime()))
end)
```

---

## Pitfalls

### Storing timer id across reload

When a script reloads all its timers are cancelled via `CancelAllFor(owner)`. The id captured into a `local` Lua variable at top-level becomes invalid after reload (next reload will have new ids — they reset on engine restart too? No: `m_Next` starts at 1 and is monotonic across the whole Lua state lifetime; so even an old id will not collide). Calling `timers.cancel(old_id)` simply no-ops because the timer is gone.

### Re-entrant `ReloadScripts` from a timer callback

Timer callbacks run under the engine lock. Calling `ReloadScripts` from inside a timer callback would deadlock. Don't.

### Heavy work in `every`

`Tick` runs serially over all timers — long callbacks stall everyone. Cap your work; heavy iteration should go in `on_frame`.

### Using `every` for `ImGui.*` — only works if it fires inside `on_render`

The ImGui frame is only live during `OnRender`. If your `every` callback hits while `on_render` isn't active (mostly true), your draw calls produce undefined behaviour or nothing.

---

## See also

- [callbacks-events.md](callbacks-events.md) — the per-frame timing
- [storage.md](storage.md) — pair `timers.every(fn) + storage` for stateful cycles