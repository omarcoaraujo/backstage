# Backstage

Live tuning panel for Roblox Studio: edit game values in real time.

[![Check](https://github.com/omarcoaraujo/backstage/actions/workflows/check.yml/badge.svg)](https://github.com/omarcoaraujo/backstage/actions/workflows/check.yml) [![Release](https://github.com/omarcoaraujo/backstage/actions/workflows/release.yml/badge.svg)](https://github.com/omarcoaraujo/backstage/actions/workflows/release.yml)

<p align="center">
  <img src="docs/window.png" alt="The Backstage window tuning a pet config" width="32%">
  <img src="docs/color-picker.png" alt="The color picker open on a color value" width="32%">
  <img src="docs/readonly.png" alt="Read-only values and expandable tables" width="32%">
</p>

The read-only rows and expandable tables are built and shown in the UI stories, but `config` does not produce them yet. They arrive with store support.

---

## Features

- Declare your game values once and tune them in a window while you play in Studio
- Sliders, toggles, text, choices, colors with a picker, vectors and buttons
- Limits per value: `min`, `max`, `step` and a list of choices
- Search bar that filters the tree by name
- Zero cost in production: outside Studio the config is a frozen copy and there is no UI, no remote and no listener

## Installation

Add it to your `pesde.toml`:

```toml
[dependencies]
backstage = { name = "omarcoaraujo/backstage", version = "^0.1.0" }
```

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

Read the values as plain fields, always through the returned table, so you see the latest edit:

```lua
const config = require(path.to.pets_config)

print(config.distance, config.trail.length)

config.respawn:connect(function()
	-- the button was pressed
end)
```

The game cannot write to the config. Only the window does, and writing from code raises an error.

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

A complete project is in [`example/`](example).

## Limitations

- Backstage is pre-1.0, so the API can still change between minor versions.
- Edits live in the play session and are lost when it ends. Values declared only on the client stay local to that client.
- Editing values of stores you already have (Vide, Charm) is not there yet.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
