# Backstage

Live tuning panel for Roblox Studio: edit game values in real time.

Stop editing a number, pressing play and waiting to see it. Declare a value once, drag a slider while the game runs, watch the game change on the spot, and keep what feels right.

[![Check](https://github.com/omarcoaraujo/backstage/actions/workflows/check.yml/badge.svg)](https://github.com/omarcoaraujo/backstage/actions/workflows/check.yml) [![Release](https://github.com/omarcoaraujo/backstage/actions/workflows/release.yml/badge.svg)](https://github.com/omarcoaraujo/backstage/actions/workflows/release.yml)

<p align="center">
  <img src="docs/window.png" alt="The Backstage window tuning a pet config" width="32%">
  <img src="docs/color-picker.png" alt="The color picker open on a color value" width="32%">
  <img src="docs/readonly.png" alt="Read-only values and expandable tables" width="32%">
</p>

The read-only rows and expandable tables are built and shown in the UI stories, but `config` does not produce them yet. They arrive with store support.

---

## Features

**Tune while you play**

- One declaration per value, and the kind comes from its default: number, boolean, string, `Color3` or `Vector3`
- Sliders, toggles, text boxes, choices, a color picker, vector fields and buttons
- Limits per value: `min`, `max`, `step` and a list of `choices`, enforced on every edit
- Hints: a tooltip on hover that explains what a value does
- Nested tables become collapsible groups with a line showing the nesting
- Search bar that filters the tree by name
- A reset button on every changed value
- A draggable, resizable window opened with `Ctrl + B` or a key you choose

**Fits your code**

- Plain reads: `config.speed`, no wrapper and no `.get()`
- Reactive reads: a read inside a Vide scope or a Charm effect tracks itself and reruns when you tune the value
- `on_change`: run a callback when a value changes, so code that caches a value stays live without a per-frame loop
- Works across the network: a value on the server is tuned from the same window, validated by the server and sent to every player
- Buttons you press in the window and listen to in code

**Keeps what you tuned: the Backstage tool**

- Tuning is only half of it. The tool writes every change back into the default of its `backstage.config` call, in place, so the next session starts from what you tuned and you never copy a number by hand
- It is part of Backstage, not an add-on: install it once with Rokit and keep it running while you work. Without it, everything you tune is lost when the play session ends

**Costs nothing in production**

- Outside Studio there is no UI, no remote, no listener and no signal, and `config` is a frozen copy of your defaults
- The game can never write to the config, only the window can

## How it works

```
 your code                 Studio only
┌──────────────┐        ┌──────────────────────────┐
│ config.speed │◀───────│ registry (validated)     │◀── window (sliders, picker...)
└──────────────┘        └──────────────────────────┘
   plain read              │             │
   or tracked by           ▼             ▼
   Vide / Charm        server ⇄ clients  saving tool ──▶ your config script
```

Every value lives in a registry keyed by path, like `pets.trail.length`. The window writes to it, the registry validates against the limits, and your code reads the latest value through the table `config` returns.

## Installation

Add it to your `pesde.toml`:

```toml
[dependencies]
backstage = { name = "omarcoaraujo/backstage", version = "^0.1.0" }
```

## Quick start

Declare the values:

```lua
const backstage = require(path.to.backstage)

return backstage.config("pets", {
	speed = 8,
	tint = Color3.fromRGB(255, 200, 80),
}, {
	limits = { speed = { min = 0.5, max = 40 } },
})
```

Start the window, once on the client:

```lua
backstage.start()
```

Install the tool and leave it running next to Studio, so what you tune is saved into your scripts:

```sh
rokit add omarcoaraujo/backstage
backstage serve
```

Press play and open the window with `Ctrl + B`. Everything below goes deeper.

## Usage

### Declaring values

```lua
const backstage = require(path.to.backstage)

return backstage.config("pets", {
	distance = 6,
	tint = Color3.fromRGB(255, 200, 80),
	mode = "follow",
	respawn = backstage.button(),
	trail = {
		enabled = true,
		length = 1.5,
	},
}, {
	limits = {
		distance = { min = 0, max = 30, step = 0.1 },
		mode = { choices = { "follow", "orbit" } },
		trail = {
			length = { min = 0.1, max = 6, step = 0.1 },
		},
	},
})
```

The kind of each value comes from its default: number, boolean, string, `Color3` or `Vector3`. A `choices` limit turns a string into a choice. Nested tables become groups.

Add a `hints` table, shaped like `limits`, to explain a value. The text shows as a tooltip when you hover the row:

```lua
{
	limits = { distance = { min = 0, max = 30, step = 0.1 } },
	hints = {
		distance = "How far behind the player the pet stays",
		trail = { length = "Seconds the trail takes to fade" },
	},
}
```

Read the values as plain fields, always through the returned table, so you see the latest edit:

```lua
const config = require(path.to.pets_config)

print(config.distance, config.trail.length)

config.respawn:connect(function()
	-- the button was pressed
end)
```

The game cannot write to the config. Only the window does, and writing from code raises an error.

### Reactive reads

A read inside a Vide scope or a Charm effect is tracked, so it runs again when the window changes the value:

```lua
vide.create "Part" {
	Size = function()
		return Vector3.one * config.size
	end,
}

charm.effect(function()
	print(config.size)
end)
```

Vide works with the copy Backstage installs. If your game uses another copy of Vide, or uses Charm, hand them to `start` so the copy that tracks is the one your code uses:

```lua
backstage.start { vide = vide, charm = charm }
```

Charm is never required: without it a read inside a Charm effect is a plain read. Fusion does not track plain reads.

This is what lets you tune things a per-frame loop could never reach, like a HUD that rebuilds only when a value changes. [`example/client/hud.luau`](example/client/hud.luau) is a Vide card whose corner, scale, colors, title and rows all follow the window.

### Reacting to a change

For code that caches a value instead of reading it again every frame, hook a callback to a path. It works in any script, so you can use it right in your game code:

```lua
const function apply_size(size: number)
	pet.Size = Vector3.one * size
end

apply_size(config.size)
backstage.on_change(config.size, apply_size)
```

It is a signal, so the first argument is always the config read itself, with the path written out (`config.size`, `config.trail.length`), and the second is the callback. It finds the path from that read, so a typo is a type error. Anything else, a variable, a literal, an expression or a string, raises an error in Studio.

It fires on every change, from the window, from a restore and from the other side of the network, with the new and the previous value. It never fires for the value you start with, so apply that one yourself, as above. It returns a function that disconnects it.

Outside Studio it does nothing, and since nothing changes there, the game ships with the value you applied first. Code written this way, setting a property when it changes and not on every frame, is cheaper than a loop anyway. [`example/client/pets.luau`](example/client/pets.luau) does it for the pet's size and color, and keeps reading the rest every frame.

### Opening the window

Call `start` on the client, and on the server if you want to tune server values too:

```lua
const backstage = require(path.to.backstage)

backstage.start()
```

A config declared in a shared module shows up once in the window. The server owns its value: an edit goes to the server, which validates it and tells every client. A config declared only on the server shows up in the window too, and its buttons run on the server.

`Ctrl + B` opens and closes the window. Pass `key` and `ctrl` to change it:

```lua
backstage.start { key = Enum.KeyCode.F4, ctrl = false }
```

### Production

`start` does nothing outside Studio, and `config` returns a frozen copy of the defaults, so the values you declared are the ones the game ships with. Use `backstage.disable()` to test that mode inside Studio, and `backstage.enable()` to force the Studio mode.

### Team Test

Team Test is not supported. Its server runs on Roblox's machines, so it cannot reach the tool on your computer and your edits would never be saved to the scripts. If the server does not start Backstage there, the client gives up after a few seconds and never opens the window. Play, and Clients and Servers with more than one player, run the server on your computer and work normally.

A complete project is in [`example/`](example).

### The Backstage tool

This is where Backstage pays off. Every change you make in the window is written back into the default of the matching `backstage.config` call, in place, so you tune by feel, close Studio and the numbers are already in your code. No export button, no JSON, no copying values.

Without it, edits live in the play session and are lost when it ends. Treat it as a required part of the workflow and keep it running whenever you tune.

Install it with [Rokit](https://github.com/rojo-rbx/rokit) and serve your project folder while Studio is open:

```sh
rokit add omarcoaraujo/backstage
backstage serve --port 34891
```

Enable **Allow HTTP Requests** in the game settings of the place. The tool listens only on `127.0.0.1`, finds each config by name across the project, and refuses a name that is declared in two files or a value that is not a literal. The folder defaults to the current one, and `backstage serve path/to/project` picks another. `--port` is optional, and the same number goes to `backstage.start { port = 34891 }` if you change it.

## Limitations

- Backstage is pre-1.0, so the API can still change between minor versions.
- Edits are lost when the play session ends unless the Backstage tool is running. Values declared only on the client stay local to that client.
- Editing values of stores you already have (Vide, Charm) is not there yet.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
