local path = string.match(..., ".*/") or ""

local levels = {}

for level in path:gmatch("([^/]+)") do levels[#levels + 1] = level end

path = ""

for i, level in ipairs(levels) do if i ~= #levels then path = path .. "/" .. level end end

local Object = require(path .. "/third_party/classic")

Point = Object:extend()

function Point:new(x, y)
	self.meta = {
		x = x or 0,
		y = y or 0
	}
end

function Point:get_x() return self.meta.x end
function Point:get_y() return self.meta.y end

function Point:set_x(val)
	assert(type(val) == "number", "Unable to set x to " .. tostring(val) .. " as value is not of type 'number'.")
	self.meta.x = val
end

function Point:set_y(val)
	assert(type(val) == "number", "Unable to set y to " .. tostring(val) .. " as value is not of type 'number'.")
	self.meta.y = val
end

function Point:set(x, y)
	assert(type(x) == "number", "Unable to set x to " .. tostring(val) .. " as value is not of type 'number'.")
	assert(type(y) == "number", "Unable to set y to " .. tostring(val) .. " as value is not of type 'number'.")
	self.meta.x = x
	self.meta.y = y
end

function Point:clone()
	return Point(self.x, self.y)
end

function Point:get()
	return self.x, self.y
end

function Point:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y
end

function Point:__sub(val)
	return Point(self.x - val.x, self.y - val.y)
end

function Point:__add(val)
	return Point(self.x + val.x, self.y + val.y)
end

function Point:__div(val)
	return Point(self.x / val.x, self.y / val.y)
end

function Point:__mul(val)
	return Point(self.x * val.x, self.y * val.y)
end

function Point:__unm()
	return Point(-self.x, -self.y)
end

function Point:__eq(val)
	return self.x == val.x and self.y == val.y
end

function Point:__type()
	return "Point"
end

return Point