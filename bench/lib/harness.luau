--// Constants
const REPEATS = 7
const DEFAULT_SIZES = { 100, 1000, 5000 } :: { number }
const MILLISECONDS = 1000

--// Types
export type prepare = (size: number) -> (() -> (), (() -> ())?)
export type case = { prepare: prepare, sizes: { number }?, deferred: boolean? }
export type suite = { [string]: prepare | case }

export type result = {
	name: string,
	size: number,

	median: number,
	fastest: number,
	slowest: number,
}

--// Functions
const function flush()
	local settled = 0

	task.defer(function()
		settled = os.clock()
	end)

	while settled == 0 do
		task.wait()
	end

	return settled
end

const function sample(case: case, size: number)
	const run, finish = case.prepare(size)
	task.wait()

	const started = os.clock()
	run()

	const stopped = if case.deferred then flush() else os.clock()
	const elapsed = stopped - started

	if finish then finish() end
	return elapsed * MILLISECONDS
end

const function measure(name: string, case: case, size: number): result
	sample(case, size)
	const samples = {}

	for _ = 1, REPEATS do
		table.insert(samples, sample(case, size))
	end

	table.sort(samples)

	return {
		name = name,
		size = size,

		median = samples[math.ceil(REPEATS / 2)],
		fastest = samples[1],
		slowest = samples[REPEATS],
	}
end

const function deferred(prepare: prepare): case
	return { prepare = prepare, deferred = true }
end

const function normalized(entry: prepare | case): case
	if type(entry) == "function" then return { prepare = entry } end
	return entry
end

const function run(
	suite: suite,
	report: (result: result) -> (),
	fail: (name: string, size: number, reason: unknown) -> ()
)
	const names = {}

	for name in suite do
		table.insert(names, name)
	end

	table.sort(names)

	for _, name in names do
		const case = normalized(suite[name])

		for _, size in case.sizes or DEFAULT_SIZES do
			const ok, outcome = pcall(measure, name, case, size)

			if ok then
				report(outcome)
			else
				fail(name, size, outcome)
			end
		end
	end
end

--// End
return table.freeze {
	run = run,
	deferred = deferred,
}
