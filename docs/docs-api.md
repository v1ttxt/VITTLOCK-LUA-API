# `docs` API

Programmatic access to the binding registry + the documentation generator. The engine auto-runs `docs.generate()` on init and after every `ReloadScripts`; you can also call it at runtime.

---

## API

| Function | Returns | Description |
|---|---|---|
| `docs.generate()` | bool | Regenerate `vittlock.d.lua` + `API.md` under `<ScriptsPath>/_docs` |
| `docs.output_dir()` | string | Where the docs will be written (`<ScriptsPath>/_docs`) |
| `docs.namespaces()` | string[] | All registered API namespaces (`Engine`, `UI`, `Menu`, `callbacks`, etc.) |
| `docs.list(ns)` | table[] | Entries in a namespace: `{name, signature, description}` |

---

## Pipeline

The binding registry is a static store maintained by the engine. Every API module is registered with its functions, signatures, and arg lists — that's what powers the auto-generated docs.

On engine init:

```text
init → bind all APIs → write docs to <ScriptsPath>/_docs → load scripts → after reload, regen docs
```

`GenerateAll` writes two files atomically (write tmp + rename):

- `vittlock.d.lua` — EmmyLua `---@class` / `---@field` annotations grouped by namespace. Point Sumneko/Lua Language Server's `library` setting at this folder for autocomplete.
- `API.md` — auto-summary markdown grouped by namespace.

Both files are written under `<ScriptsPath>/_docs`. Hot-reload won't pick up scripts under `_docs` (they're explicitly excluded from the recursive iterator).

---

## Examples

### Force a regen

```lua
m:button("Refresh docs", function()
    if docs.generate() then
        log.info("docs regenerated at", docs.output_dir())
    else
        log.error("doc generation failed")
    end
end)
```

### List all namespaces

```lua
callbacks.on_script_loaded(function()
    for _, ns in ipairs(docs.namespaces()) do
        log.info("namespace", ns)
    end
end)
```

### Inspect one namespace

```lua
for _, row in ipairs(docs.list("Engine")) do
    print(row.name, "::", row.signature)
    if row.description and row.description ~= "" then
        print("   " .. row.description)
    end
end
```

### Build a side reference table at script load

```lua
local engineFns = {}
for _, row in ipairs(docs.list("Engine")) do
    engineFns[row.name] = row.signature
end
log.info("loaded", #docs.namespaces(), "namespaces /", #engineFns, "Engine fns")
```

---

## Output files

### `vittlock.d.lua` (excerpt)

```lua
---@class EngineNS
---@field GetLocalVelocity fun():Vector3 -- Local player velocity (units/s)
---@field GetLocalMoveType fun():integer -- Local player MoveType_t
...
Engine = {}

---@class callbacksNS
---@field on_pre_createmove fun(cmd:CUserCmd) -- Before user command is sent
...
callbacks = {}

---@class Vector3
---@field x number
---@field y number
---@field z number
---@field Length fun(self:Vector3):number
---@field Length2D fun(self:Vector3):number
```

To wire this into your IDE:

**VS Code + Lua Language Server (Sumneko):** add to `.luarc.json`:

```json
{
  "workspace.library": [
    "C:/VITTLOCK/Scripts/_docs"
  ]
}
```

After that, autocomplete and hover-docs light up for the VITTLOCK namespaces.

### `API.md` (excerpt)

```markdown
## Engine

### `Engine.GetLocalVelocity`
```lua
fun():Vector3
```
Local player velocity (units/s)

### `Engine.GetLocalMoveType`
...
```

---

## Pitfalls

### Generated docs reflect the **loaded** binding state

If you call `docs.list("Engine")` at script load time before the engine has populated the registry, you get an empty table. The registry is fully populated before any script's top-level runs, so by the time your code executes, the registry is complete.

### `EModifierState` namespace reports only a summary

The full 305-entry enum is registered as one entry `"EModifierState.<value>"` — not 305 separate entries. This avoids drowning the docgen with metadata. Iterate the live Lua table directly:

```lua
for k, v in pairs(EModifierState) do
    print(k, "=", v)
end
```

### `docs.generate` does synchronous disk I/O

It writes two files (EmmyLua stubs + Markdown). Disk writes are atomic via `.tmp + rename`, but on slow drives a 200KB write may take long enough to hitch a frame. Don't call it inside `on_pre_createmove`.

---

## See also

- [getting-started.md](getting-started.md) — script anatomy
- [modifiers-states.md](modifier-states.md) — the largest enum registered with the registry