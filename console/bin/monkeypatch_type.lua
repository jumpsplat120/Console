--Simple function that checks a table to see if it has a __type
--entry in the metatable, and returns that value if it does.
local o_type = type

function type(obj)
	local res = o_type(obj)
	return (res == "table" and obj.__type) and obj:__type() or res
end