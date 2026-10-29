# Contributing

Thanks for helping with Backstage.

## Setup

The tools are pinned in `rokit.toml` and `mise.toml` runs them:

```sh
rokit install
pesde install
mise run install:cli
```

The CLI has its own `cli/pesde.toml`, with [tint](https://github.com/omarcoaraujo/tint) for the terminal colors, so it installs apart from the library.

## Layout

| Folder | What lives there |
|---|---|
| `src/core/` | Config, kinds, registry, buttons and `start`, with no UI |
| `src/ui/` | The window and its controls, built with Vide |
| `stories/` | UI Labs stories of the window |
| `tests/lib/` | Library specs, run inside Studio |
| `bench/` | Benchmarks of the library, run inside Studio, and the Lute tools that show and compare them |
| `example/` | A small game that uses Backstage |

## Checks

```sh
mise run format
mise run analyze
mise run test
```

`analyze` needs the Roblox definitions, which it downloads once into `roblox.d.luau`. `test` builds a place and runs the specs with `run-in-roblox`, so Studio has to be installed.

## Benchmarks

```sh
mise run bench
mise run bench:compare
mise run bench:save
```

`bench` builds a place, runs every case with 100, 1000 and 5000 entries, prints the medians and saves them to `bench/results/`, which git ignores. `bench:compare` sets the last run against `bench/baseline.txt` and fails when a case got more than 25% and half a millisecond slower. `bench:save` promotes the last run to the baseline, in a commit of its own. The numbers come from a headless Studio and only compare with each other, they say nothing about layout or rendering.

## Style

Luau with the `const` dialect, formatted by StyLua. Files, folders and variables are `snake_case`, constants are `SCREAMING_SNAKE_CASE`, and a file only has section headers as comments.
