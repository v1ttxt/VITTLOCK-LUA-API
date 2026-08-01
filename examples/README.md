# Examples

Runnable VITTLOCK Lua scripts — drop them into `C:\VITTLOCK\Scripts\<SubDir>\` and play with the toggle. Each file is self-contained and uses only documented API surface.

| # | Script | Demonstrates |
|---|---|---|
| 01 | `01-minimal.lua` | Smallest possible script — one switch + on_frame + on_render |
| 02 | `02-toggle-keypress.lua` | Toggle on keypress with on-screen notification overlay |
| 03 | `03-enemy-esp-box.lua` | ESP boxes around enemies using WorldToScreen + bone positions |
| 04 | `04-auto-parry-event.lua` | Modifier event → storage handoff → cmd button on next tick |
| 05 | `05-velocity-hud.lua` | HUD readout of velocity, time, tick rate |
| 06 | `06-periodic-heartbeat.lua` | `timers.every` + storage-backed counter + reset button |
| 07 | `07-combo-color-multi.lua` | Every widget kind — combo, color, sliders, group, separator, button |
| 08 | `08-input-key-tracker.lua` | `callbacks.on_key_pressed/released` worldwide |
| 09 | `09-bullet-tracker.lua` | `callbacks.on_bullet_create` rich payload + on-screen feed |
| 10 | `10-full-template.lua` | Comprehensive template covering every subsystem — copy as your starting point |

## How to load these

The VITTLOCK script directory is `C:\VITTLOCK\Scripts\`, scanned recursively for `.lua` files. The first subdirectory below `Scripts\` becomes the **category** for the card. So if you copy them as:

```
C:\VITTLOCK\Scripts\Examples\
    ├── 01-minimal.lua
    ├── 02-toggle-keypress.lua
    ├── ...
    └── 10-full-template.lua
```

…each will land under the `Examples` category tab in the **Lua Scripts** menu.

## Workflow

1. Edit the file in your editor (VS Code with the Lua Language Server pointed at `__STORAGE__/_docs` for autocomplete).
2. Toggle **Hot-reload** on the menu's **Lua Scripts** tab.
3. Save the file in your editor — the engine picks up the mtime change within 1 second and reloads just that one script.
4. Watch for compile errors in the **Errors** panel of the Lua Scripts tab; right-click the card → **Open in editor** for quick navigation.

## Lessons by category

- **Menu** ([docs/widgets-menu.md](../docs/widgets-menu.md)) — see 07 for every widget, 06 for buttons that mutate state, 10 for tooltips.
- **Callbacks** ([docs/callbacks-events.md](../docs/callbacks-events.md)) — 04 demonstrates modifier-event-driven behaviour with cross-callback handoff.
- **Entity** ([docs/entity-wrappers.md](../docs/entity-wrappers.md)) — 03 uses `entity_list:enemies()`, 09 uses bullet payloads, 10 uses modifier payloads.
- **Rendering** ([docs/render-imgui.md](../docs/render-imgui.md)) — 02 is an ImGui popup; 05, 09 use `render.*` HUD.
- **Timers + storage** ([docs/timers.md](../docs/timers.md), [docs/storage.md](../docs/storage.md)) — 06 shows the canonical pairing.

## License

See [LICENSE](../LICENSE) at repo root.