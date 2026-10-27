--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Functions
const function fresh()
	registry.reset()
	mode.enable()
end

const function defaults()
	return {
		distance = 6,
		mode = "follow",
		respawn = backstage.button(),
		trail = { enabled = true, length = 1.5 },
	}
end

const function options()
	return {
		limits = {
			distance = { min = 0, max = 30, step = 0.1 },
			mode = { "follow", "orbit" },
			trail = { length = { min = 0.1, max = 6 } },
		},

		hints = {},
	}
end

--// Specs
return {
	studio_reads_current_values = function()
		fresh()
		const pets = backstage.config("pets", defaults(), options())

		assert(pets.distance == 6)
		assert(pets.trail.length == 1.5)

		registry.set("pets.distance", 12)
		registry.set("pets.trail.length", 3)

		assert(pets.distance == 12)
		assert(pets.trail.length == 3)
	end,

	studio_indexes_and_iterates_sparse_numeric_keys = function()
		fresh()
		const skins = backstage.config(
			"skins",
			{ [1] = { price = 1 }, [8] = { price = 8 }, [10] = { price = 10 }, [11] = { price = 11 } }
		)

		assert(skins[10].price == 10)
		assert(skins[9] == nil)
		assert(#skins == 0)

		const seen = {}
		for key, skin in skins do
			table.insert(seen, `{key}:{skin.price}`)
		end

		table.sort(seen)
		assert(table.concat(seen, ",") == "10:10,11:11,1:1,8:8")
		assert(registry.get "skins.10.price" == 10)
	end,

	studio_rejects_writes_from_game_code = function()
		fresh()
		const pets = backstage.config("pets", defaults(), options())

		assert(not pcall(function()
			(pets :: any).distance = 1
		end))

		assert(pets.distance == 6)
	end,

	studio_registers_every_value_by_path = function()
		fresh()

		backstage.config("pets", defaults(), options())
		const paths = {}

		for _, entry in registry.list() do
			table.insert(paths, entry.path)
		end

		assert(table.concat(paths, ",") == "pets.distance,pets.mode,pets.trail.enabled,pets.trail.length")
		assert(#registry.list_buttons() == 1)
	end,

	studio_keeps_hints_by_path = function()
		fresh()

		backstage.config("pets", defaults(), {
			hints = {
				distance = "How far behind",
				trail = { length = "Seconds to fade" },
			},
		})

		const hints = {}

		for _, entry in registry.list() do
			hints[entry.path] = entry.hint
		end

		assert(hints["pets.distance"] == "How far behind")
		assert(hints["pets.trail.length"] == "Seconds to fade")
		assert(hints["pets.mode"] == nil)
	end,

	studio_keeps_the_hint_of_a_button = function()
		fresh()
		backstage.config("pets", defaults(), { hints = { respawn = "Brings the pet back" } })

		assert(registry.list_buttons()[1].hint == "Brings the pet back")
	end,

	studio_ignores_a_hint_that_is_not_text = function()
		fresh()
		backstage.config("pets", defaults(), { hints = { distance = 5 } })

		for _, entry in registry.list() do
			assert(entry.hint == nil)
		end
	end,

	studio_applies_limits = function()
		fresh()

		backstage.config("pets", defaults(), options())
		assert(registry.set("pets.distance", 99))
		assert(registry.get "pets.distance" == 30)

		assert(not registry.set("pets.mode", "teleport"))
		assert(registry.get "pets.mode" == "follow")
	end,

	studio_passes_through_values_it_does_not_understand = function()
		fresh()

		const emote = Vector2.new(3, 4)
		const emotes = backstage.config("emotes", {
			[1] = { cooldown = 2, offset = emote },
		})

		assert(emotes[1].offset == emote)
		assert(registry.get "emotes.1.cooldown" == 2)
		assert(registry.get "emotes.1.offset" == nil)

		for _, entry in registry.list() do
			assert(entry.path ~= "emotes.1.offset")
		end
	end,

	studio_recognizes_a_catalog_by_the_shape_of_its_entries = function()
		fresh()

		backstage.config("shop", {
			skins = { [1] = { price = 100 }, [5] = { price = 500 } },
			prices = { [1] = 10, [5] = 20 },
			pet = { size = 1, mode = "follow" },
			solo = { [1] = { price = 100 } },
		})

		assert(registry.is_catalog "shop.skins")
		assert(registry.is_catalog "shop.prices")

		assert(not registry.is_catalog "shop.pet")
		assert(not registry.is_catalog "shop.solo")
	end,

	studio_adds_a_catalog_entry_with_the_shape_of_its_siblings = function()
		fresh()

		const shop = backstage.config("shop", {
			skins = { [1] = { rarity = "common", price = 100 }, [5] = { rarity = "rare", price = 500 } },
		}, {
			limits = backstage.each { price = { min = 0, max = 50 } },
		})

		assert(registry.add_item("shop.skins", "11"))
		assert(shop.skins[11].price == 100 or shop.skins[11].price == 500)
		assert(registry.get "shop.skins.11.rarity" ~= nil)

		assert(not registry.add_item("shop.skins", "11"))
		assert(not registry.add_item("shop.skins", "nope"))

		const seen = {}

		for key in shop.skins do
			table.insert(seen, key)
		end

		assert(#seen == 3)
	end,

	studio_says_why_a_catalog_entry_was_refused = function()
		fresh()

		backstage.config("shop", {
			skins = { [1] = { price = 100 }, [5] = { price = 500 } },
			moods = { calm = { speed = 1 }, wild = { speed = 9 } },
		})

		const _, repeated = registry.add_item("shop.skins", "5")
		const _, not_a_number = registry.add_item("shop.skins", "nope")
		const _, not_a_name = registry.add_item("shop.moods", "1bad")
		const _, taken = registry.add_item("shop.moods", "calm")

		assert(repeated == "already exists")
		assert(not_a_number == "needs a number")
		assert(not_a_name == "not a valid name")
		assert(taken == "already exists")
	end,

	studio_adds_a_scalar_catalog_entry = function()
		fresh()

		const shop = backstage.config("shop", { prices = { [1] = 10, [5] = 20 } })
		assert(registry.add_item("shop.prices", "9"))

		assert(shop.prices[9] ~= nil)
		assert(registry.get "shop.prices.9" ~= nil)
	end,

	studio_removes_a_catalog_entry = function()
		fresh()

		const shop = backstage.config("shop", {
			skins = { [1] = { price = 100 }, [5] = { price = 500 } },
		})

		assert(registry.remove_item("shop.skins", "5"))
		assert(shop.skins[5] == nil)

		assert(registry.get "shop.skins.5.price" == nil)
		assert(registry.get "shop.skins.1.price" == 100)
		assert(not registry.remove_item("shop.skins", "5"))
	end,

	studio_restoring_a_catalog_brings_back_removed_entries_with_their_own_values = function()
		fresh()
		const shop = backstage.config("shop", {
			skins = { [1] = { price = 100 }, [5] = { price = 500 } },
		})

		assert(not registry.dirty "shop.skins")
		registry.remove_item("shop.skins", "5")

		assert(registry.dirty "shop.skins")
		assert(registry.dirty())

		registry.restore_group "shop.skins"
		assert(shop.skins[5].price == 500)

		assert(registry.get "shop.skins.5.price" == 500)
		assert(not registry.dirty "shop.skins")
	end,

	studio_accepts_back_a_removed_entry_whose_name_is_not_an_identifier = function()
		fresh()
		const shop = backstage.config("shop", {
			moods = { calm = { speed = 1 }, ["my key"] = { speed = 9 } },
		})

		assert(registry.remove_item("shop.moods", "my key"))
		assert(shop.moods["my key"] == nil)

		assert(registry.add_item("shop.moods", "my key"))
		assert(shop.moods["my key"] ~= nil)

		const _, invented = registry.add_item("shop.moods", "other key")
		assert(invented == "not a valid name")
	end,

	studio_restoring_a_catalog_drops_the_entries_added_since = function()
		fresh()
		const shop = backstage.config("shop", {
			skins = { [1] = { price = 100 }, [5] = { price = 500 } },
		})

		registry.add_item("shop.skins", "9")
		assert(registry.dirty "shop.skins")

		registry.restore_group()
		assert(shop.skins[9] == nil)

		assert(registry.get "shop.skins.9.price" == nil)
		assert(not registry.dirty())
	end,

	studio_only_catalogs_accept_entries = function()
		fresh()
		backstage.config("shop", { pet = { size = 1, mode = "follow" } })

		assert(not registry.add_item("shop.pet", "color"))
		assert(not registry.remove_item("shop.pet", "size"))
	end,

	studio_announces_a_new_catalog_entry = function()
		fresh()
		backstage.config("shop", { prices = { [1] = 10, [5] = 20 } })

		local announced = 0
		registry.on_register(function()
			announced += 1
		end)

		registry.add_item("shop.prices", "9")
		registry.remove_item("shop.prices", "9")
		assert(announced == 2)
	end,

	studio_each_applies_limits_to_every_entry = function()
		fresh()

		backstage.config("skins", {
			[1] = { price = 100 },
			[10] = { price = 200 },
		}, {
			limits = backstage.each { price = { min = 0, max = 50 } },
		})

		assert(registry.set("skins.1.price", 999))
		assert(registry.get "skins.1.price" == 50)

		assert(registry.set("skins.10.price", 999))
		assert(registry.get "skins.10.price" == 50)
	end,

	studio_each_explicit_key_wins = function()
		fresh()

		backstage.config("skins", {
			[1] = { price = 100 },
			[2] = { price = 100 },
		}, {
			limits = backstage.each({ price = { min = 0, max = 50 } }, {
				[2] = { price = { max = 500 } },
			}),
		})

		assert(registry.set("skins.1.price", 999))
		assert(registry.get "skins.1.price" == 50)

		assert(registry.set("skins.2.price", 999))
		assert(registry.get "skins.2.price" == 500)
	end,

	studio_each_merges_explicit_into_shared = function()
		fresh()

		backstage.config("skins", {
			[1] = { price = 100 },
		}, {
			limits = backstage.each({ price = { min = 10, max = 50 } }, {
				[1] = { price = { max = 500 } },
			}),
		})

		assert(registry.set("skins.1.price", 1))
		assert(registry.get "skins.1.price" == 10)
	end,

	studio_each_works_in_a_nested_group = function()
		fresh()

		backstage.config("shop", {
			skins = { [1] = { price = 100 }, [2] = { price = 100 } },
		}, {
			limits = {
				skins = backstage.each { price = { min = 0, max = 50 } },
			},
		})

		assert(registry.set("shop.skins.2.price", 999))
		assert(registry.get "shop.skins.2.price" == 50)
	end,

	studio_each_applies_hints_to_every_entry = function()
		fresh()

		backstage.config("skins", {
			[1] = { price = 100 },
			[2] = { price = 100 },
		}, {
			hints = backstage.each { price = "Coins to buy" },
		})

		for _, entry in registry.list() do
			assert(entry.hint == "Coins to buy")
		end
	end,

	studio_iterates_in_key_order = function()
		fresh()

		const pets = backstage.config("pets", defaults(), options())
		const keys = {}

		for key in pets do
			table.insert(keys, key)
		end

		table.sort(keys)
		assert(table.concat(keys, ",") == "distance,mode,respawn,trail")
	end,

	studio_array_reports_its_length = function()
		fresh()

		const pets = backstage.config("pets", {
			tints = { Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1) },
		})

		assert(#pets.tints == 3)
	end,

	studio_group_with_text_keys_has_no_length = function()
		fresh()
		const pets = backstage.config("pets", defaults(), options())
		assert(#(pets.trail :: any) == 0)
	end,

	studio_empty_array_has_no_length = function()
		fresh()
		const pets = backstage.config("pets", { tints = {} })
		assert(#pets.tints == 0)
	end,

	studio_array_reads_by_index_and_iterates = function()
		fresh()
		const pets = backstage.config("pets", {
			tints = { Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1) },
		})

		assert(pets.tints[2] == Color3.new(0, 1, 0))
		registry.set("pets.tints.2", Color3.new(1, 1, 1))
		assert(pets.tints[2] == Color3.new(1, 1, 1))

		local seen = 0
		for _, color in pets.tints do
			assert(typeof(color) == "Color3")
			seen += 1
		end

		assert(seen == 3)
	end,

	button_fires_its_listeners = function()
		fresh()

		const pets = backstage.config("pets", defaults(), options())
		local fired = 0

		const connection = pets.respawn:connect(function()
			fired += 1
		end)

		registry.press "pets.respawn"
		assert(fired == 1)

		connection.disconnect()
		registry.press "pets.respawn"
		assert(fired == 1)
	end,

	change_listeners_get_old_and_new_value = function()
		fresh()
		backstage.config("pets", defaults(), options())

		local seen = nil :: string?
		const stop = registry.on_change(function(path, value, previous)
			seen = `{path} {previous}->{value}`
		end)

		registry.set("pets.distance", 8)
		assert(seen == "pets.distance 6->8")

		stop()
		registry.set("pets.distance", 9)
		assert(seen == "pets.distance 6->8")
	end,

	production_returns_a_frozen_copy = function()
		fresh()

		mode.disable()
		const pets = backstage.config("pets", defaults(), options())

		assert(pets.distance == 6)
		assert(pets.trail.length == 1.5)
		assert(table.isfrozen(pets))

		assert(table.isfrozen(pets.trail))
		assert(#registry.list() == 0)
		assert(not pcall(function()
			(pets :: any).distance = 1
		end))
	end,

	allowed_place_keeps_backstage_active = function()
		fresh()

		mode.restore()
		mode.allow { game.PlaceId + 1 }
		assert(mode.active() == game:GetService("RunService"):IsStudio())

		mode.allow { game.PlaceId }
		assert(mode.active())
		mode.restore()
	end,

	production_buttons_are_inert = function()
		fresh()

		mode.disable()
		const pets = backstage.config("pets", defaults(), options())

		pets.respawn:connect(function()
			error "never"
		end)

		pets.respawn:fire()
	end,
}
