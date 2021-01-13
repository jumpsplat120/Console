function table.pack(...)
	local t = {...}
    t.n = select("#", ...)

    return t
end