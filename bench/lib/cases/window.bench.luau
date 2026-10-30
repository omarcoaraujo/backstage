--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const filter = require(ReplicatedStorage.backstage.ui.utils.filter)
const fixtures = require(ReplicatedStorage.bench.fixtures)
const harness = require(ReplicatedStorage.bench.harness)

--// Constants
const SCROLL_STEPS = 40
const SCROLL_STRIDE = 360
const SCROLL_PASSES = 3

--// Functions
const function mount(): (() -> (), Instance)
	if not workspace.CurrentCamera then workspace.CurrentCamera = Instance.new "Camera" end
	const app = require(ReplicatedStorage.backstage.ui.app)

	const destroy, root = vide.root(function()
		return app {
			title = "bench",
			visible = function()
				return true
			end,
			on_close = function() end,
		}
	end)

	return destroy, root
end

const function release(destroy: () -> ())
	destroy()
	filter.query ""
	filter.clear_texts()
	registry.reset()
end

const function mounted(size: number)
	fixtures.fresh()
	fixtures.declare(size, true)
	return mount()
end

--// End
return {
	mount_groups_closed = function(size)
		fixtures.fresh()
		fixtures.declare(size, true)
		local destroy = nil :: (() -> ())?

		return function()
			destroy = mount()
		end, function()
			release(assert(destroy))
		end
	end,

	search_opens_every_group = function(size)
		const destroy = mounted(size)

		return function()
			filter.query "g"
		end, function()
			release(destroy)
		end
	end,

	search_opens_groups_with_buttons = harness.deferred(function(size)
		fixtures.fresh()
		fixtures.declare(size, true)

		fixtures.declare_buttons(size)
		const destroy = mount()

		return function()
			filter.query "g"
		end, function()
			release(destroy)
		end
	end),

	scroll_through_rows = harness.deferred(function(size)
		fixtures.fresh()
		fixtures.declare(size, true)

		const destroy, root = mount()
		filter.query "g"
		task.wait()

		const list = assert(root:FindFirstChild("list", true)) :: ScrollingFrame
		const reach = math.max(list.CanvasSize.Y.Offset - SCROLL_STRIDE, SCROLL_STRIDE)

		return function()
			for pass = 1, SCROLL_PASSES do
				for step = 1, SCROLL_STEPS do
					list.CanvasPosition = Vector2.new(0, (step * SCROLL_STRIDE * pass) % reach)
					task.wait()
				end
			end
		end, function()
			release(destroy)
		end
	end),

	search_matches_nothing = function(size)
		const destroy = mounted(size)

		return function()
			filter.query "zzz"
		end, function()
			release(destroy)
		end
	end,

	rebuild_search_off = harness.deferred(function(size)
		const destroy = mounted(size)

		return function()
			fixtures.add_extra()
		end, function()
			release(destroy)
		end
	end),

	rebuild_search_on = harness.deferred(function(size)
		const destroy = mounted(size)
		filter.query "zzz"

		return function()
			fixtures.add_extra()
		end, function()
			release(destroy)
		end
	end),

	confirm_all = harness.deferred(function(size)
		const destroy = mounted(size)
		fixtures.edit_all(size)

		task.wait()
		return function()
			registry.commit()
		end, function()
			release(destroy)
		end
	end),

	union_switches_variant = harness.deferred(function(size)
		fixtures.fresh()
		backstage.config("pets", {
			pick = backstage.union("kind", fixtures.variant("a", size), fixtures.variant("b", size)),
		})

		const destroy = mount()
		return function()
			registry.set("pets.pick.kind", "b")
		end, function()
			release(destroy)
		end
	end),
} :: harness.suite
