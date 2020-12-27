local path = string.match(..., ".*/") or ""

local levels = {}

for level in path:gmatch("([^/]+)") do levels[#levels + 1] = level end

path = ""

for i, level in ipairs(levels) do if i ~= #levels then path = path .. "/" .. level end end

local Object = require(path .. "/third_party/classic")

Color = Object:extend()

function Color:new(r, g, b, a)
	self.meta = {
		r = r or 0,
		g = g or 0,
		b = b or 0,
		a = a or 0
	}
end

function Color:get_r() return self.meta.r end
function Color:get_g() return self.meta.g end
function Color:get_b() return self.meta.b end
function Color:get_a() return self.meta.a end

function Color:get_to_love() return { self.r / 255, self.g / 255, self.b / 255, self.a } end

function Color:set_r(val)
	assert(val >= 0, "Unable to set red less than zero.")
	assert(255 >= val, "Unable to set red to more than 255.")
	self.meta.r = math.floor(val + .5)
end

function Color:set_g(val)
	assert(val >= 0, "Unable to set green less than zero.")
	assert(255 >= val, "Unable to set green to more than 255.")
	self.meta.g = math.floor(val + .5)
end

function Color:set_b(val)
	assert(val >= 0, "Unable to set blue less than zero.")
	assert(255 >= val, "Unable to set blue to more than 255.")
	self.meta.b = math.floor(val + .5)
end

function Color:set_a(val)
	assert(val >= 0, "Unable to set alpha less than zero.")
	assert(1 >= val, "Unable to set alpha to more than 1.")
	self.meta.a = math.floor(val + .5)
end

function Color:clone()
	return Color(self.r, self.g, self.b, self.a)
end

function Color:__tostring()
	return "r: " .. self.r .. ", g: " .. self.g .. ", b: " .. self.b .. ", a: " .. self.a
end

return Color