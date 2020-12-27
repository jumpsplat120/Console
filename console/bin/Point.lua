Point     = Object:extend()

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

function Point:clone()
	return Point(self.x, self.y)
end

function Point:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y
end