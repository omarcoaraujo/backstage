--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Utils
const filter = require(ReplicatedStorage.backstage.ui.utils.filter)
const fixtures = require(ReplicatedStorage.bench.fixtures)
const harness = require(ReplicatedStorage.bench.harness)

--// Constants
const GROUP_SIZE = 10

--// Functions
const function texts_of(size: number)
	const values = {} :: { [string]: string }

	for index = 1, size do
		values[fixtures.path_of(index)] = `Value {index}`
	end

	return values
end

const function watch(size: number)
	const nodes = {}

	for group = 1, math.ceil(size / GROUP_SIZE) do
		const paths = {}

		for index = (group - 1) * GROUP_SIZE + 1, math.min(group * GROUP_SIZE, size) do
			table.insert(paths, fixtures.path_of(index))
		end

		table.insert(nodes, filter.branch(`g{group}`, {}, paths))
	end

	return vide.root(function()
		for _, node in nodes do
			vide.effect(function()
				node.shown()
			end)
		end
	end)
end

const function release(destroy: () -> ())
	destroy()
	filter.query ""
	filter.clear_texts()
end

--// End
return {
	replace_texts_no_search = function(size)
		const values = texts_of(size)
		const destroy = watch(size)

		return function()
			filter.replace_texts(values)
		end, function()
			release(destroy)
		end
	end,

	replace_texts_search_on = function(size)
		const values = texts_of(size)
		const destroy = watch(size)
		filter.query "zzz"

		return function()
			filter.replace_texts(values)
		end, function()
			release(destroy)
		end
	end,

	search_by_name = function(size)
		const destroy = watch(size)

		return function()
			filter.query "g1"
		end, function()
			release(destroy)
		end
	end,

	search_by_text = function(size)
		filter.replace_texts(texts_of(size))
		const destroy = watch(size)

		return function()
			filter.query "value 7"
		end, function()
			release(destroy)
		end
	end,

	clear_the_search = function(size)
		filter.replace_texts(texts_of(size))
		const destroy = watch(size)
		filter.query "value 7"

		return function()
			filter.query ""
		end, function()
			release(destroy)
		end
	end,
} :: harness.suite
