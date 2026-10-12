# Contributing

Thanks for helping with Backstage.

## Setup

The tools are pinned in `rokit.toml` and `mise.toml` runs them:

```sh
rokit install
pesde install
```

## Layout

| Folder | What lives there |
|---|---|
| `src/core/` | Config, kinds, registry, buttons and `start`, with no UI |
| `src/ui/` | The window and its controls, built with Vide |
| `stories/` | UI Labs stories of the window |
| `tests/lib/` | Library specs, run inside Studio |
| `example/` | A small game that uses Backstage |

## Checks

```sh
mise run format
mise run analyze
mise run test
```

`analyze` needs the Roblox definitions, which it downloads once into `roblox.d.luau`. `test` builds a place and runs the specs with `run-in-roblox`, so Studio has to be installed.

## Style

Luau with the `const` dialect, formatted by StyLua. Files, folders and variables are `snake_case`, constants are `SCREAMING_SNAKE_CASE`, and a file only has section headers as comments.
