--// Types
export type layout = {
	tops: { number },
	heights: { number },
	total: number,
}

export type range = {
	first: number,
	last: number,
}

--// Functions
const function measure(heights: { number }): layout
	const tops = table.create(#heights)
	local total = 0

	for index, height in heights do
		tops[index] = total
		total += height
	end

	return { tops = tops, heights = heights, total = total }
end

const function index_at(layout: layout, y: number): number
	const count = #layout.tops
	if count == 0 then return 0 end

	local low, high = 1, count
	while low < high do
		const middle = (low + high + 1) // 2

		if layout.tops[middle] <= y then
			low = middle
		else
			high = middle - 1
		end
	end

	return low
end

const function visible(layout: layout, scroll: number, extent: number, overscan: number)
	const count = #layout.tops
	if count == 0 then return { first = 1, last = 0 } end

	const top = math.max(scroll - overscan, 0)
	const bottom = scroll + extent + overscan

	return { first = index_at(layout, top), last = index_at(layout, bottom) }
end

const function top_of(layout: layout, index: number): number
	return layout.tops[index] or layout.total
end

--// End
return table.freeze {
	measure = measure,
	index_at = index_at,

	visible = visible,
	top_of = top_of,
}
