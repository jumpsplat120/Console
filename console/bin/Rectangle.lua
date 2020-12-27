local path = string.match(..., ".*/") or ""

local Color = require(path .. "Color")

local levels = {}

for level in path:gmatch("([^/]+)") do levels[#levels + 1] = level end

path = ""

for i, level in ipairs(levels) do if i ~= #levels then path = path .. "/" .. level end end

local Object = require(path .. "/third_party/classic")

Rectangle = Object:extend()

-- x, y, w, h and base_color are required, but do have defaults. hover and click can take a color or 'true'. Passing true
-- is basically saying that this rectangle doesn't have different colors for hovering or clicking. If attempting to access
-- the hover or click color after it's been set to not use one, it will instead return the base_color, since that is visually
-- what is happening, even though internally hover and click don't contain anything. Attempting to set and individual value
-- for hover or click when they do not exist, will clone the base color and change the expected value. Callback is required to
-- be passed as a function or true. True is if you don't want anything to happen on clicking the rectangle, and pass a callback
-- if you need there to be an action to happen on click. Valid arguments for the callback are self, dt, mouse in that order.
-- same for hover and hold callback. Callbacks can only happen one at a time, meaning if you are hovering and holding, only holding
-- runs. If you click, click runs without hover also running in the same tick. Pass false to visual to prevent any drawing checks
-- at all. Callbacks can return a value, which will be returned from the update function.
function Rectangle:new(click_callback, hover_callback, hold_callback, x, y, w, h, base_color, hover_color, click_color, mode, visual)
	assert(type(click_callback) == "function" or click_callback == true, "Missing valid click_callback.")
	assert(type(hover_callback) == "function" or hover_callback == true, "Missing valid hover_callback.")
	assert(type(hold_callback) == "function" or hold_callback == true, "Missing valid hold_callback.")
	
	self.meta = {
		x = x or 0,
		y = y or 0,
		w = w or 0,
		h = h or 0,
		base_color  = base_color  or Color(0, 0, 0, 1),
		hover_color = hover_color or Color(255, 255, 255, 1),
		click_color = click_color or Color(112, 112, 122, 1),
		mode  = mode or "fill",
		hover = false,
		click = false,
		callback = {
			click = click_callback,
			hover = hover_callback,
			hold  = hold_callback
		},
		visual = visual == nil and true or visual
	}
end

		--===|||GETTERS|||===--
	
function Rectangle:get_x() return self.meta.x end
function Rectangle:get_y() return self.meta.y end
function Rectangle:get_w() return self.meta.w end
function Rectangle:get_h() return self.meta.h end
function Rectangle:get_mode() return self.meta.mode end
function Rectangle:get_hover() return self.meta.hover end
function Rectangle:get_click() return self.meta.click end
function Rectangle:get_base_color() return self.meta.base_color end
function Rectangle:get_base_r() return self.meta.base_color.r end
function Rectangle:get_base_g() return self.meta.base_color.g end
function Rectangle:get_base_b() return self.meta.base_color.b end
function Rectangle:get_base_a() return self.meta.base_color.a end

function Rectangle:get_hover_color()
	local clr = self.meta.hover_color
	return clr == true and self.base_color or clr
end

function Rectangle:get_hover_r() return self.meta.hover_color.r end
function Rectangle:get_hover_g() return self.meta.hover_color.g end
function Rectangle:get_hover_b() return self.meta.hover_color.b end
function Rectangle:get_hover_a() return self.meta.hover_color.a end

function Rectangle:get_click_color()
	local clr = self.meta.click_color
	return clr == true and self.base_color or clr
end

function Rectangle:get_click_r() return self.meta.click_color.r end
function Rectangle:get_click_g() return self.meta.click_color.g end
function Rectangle:get_click_b() return self.meta.click_color.b end
function Rectangle:get_click_a() return self.meta.click_color.a end

		--===|||SETTERS|||===--
		
function Rectangle:set_x(val)
	assert(type(val) == "number", "Unable to set x to " .. tostring(val) .. " as value is not of type 'number'.")
	self.meta.x = val
end

function Rectangle:set_y(val)
	assert(type(val) == "number", "Unable to set y to " .. tostring(val) .. " as value is not of type 'number'.")
	self.meta.y = val
end

function Rectangle:set_w(val)
	assert(val >= 0, "Unable to set a width less than 0.")	
	self.meta.w = val
end

function Rectangle:set_h(val)
	assert(val >= 0, "Unable to set a height less than 0.")	
	self.meta.h = val
end

function Rectangle:set_mode(val)
	val = tostring(val):lower()
	
	assert(val == "fill" or val == "line", "DrawMode must be of type 'fill' or 'line'.")
	self.meta.mode = val
end

function Rectangle:set_base_color(val)
	assert(val:is(Color), "value must be of type 'color'.")
	self.meta.base_color = val
end

function Rectangle:set_base_r(val) self.meta.base_color.r = val end
function Rectangle:set_base_g(val) self.meta.base_color.g = val end
function Rectangle:set_base_b(val) self.meta.base_color.b = val end
function Rectangle:set_base_a(val) self.meta.base_color.a = val end

function Rectangle:set_hover_color(val)
	if val ~= true then assert(val:is(Color), "value must be of type 'color'.") end
	self.meta.hover_color = val		
end

function Rectangle:set_hover_r(val)
	local clr = self.meta.hover_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.r = val
		self.meta.hover_color = clr
	else
		self.meta.hover_color.r = val
	end
end

function Rectangle:set_hover_g(val)
	local clr = self.meta.hover_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.g = val
		self.meta.hover_color = clr
	else
		self.meta.hover_color.g = val
	end
end

function Rectangle:set_hover_b(val)
 	local clr = self.meta.hover_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.b = val
		self.meta.hover_color = clr
	else
		self.meta.hover_color.b = val
	end
end

function Rectangle:set_hover_a(val)
 	local clr = self.meta.hover_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.a = val
		self.meta.hover_color = clr
	else
		self.meta.hover_color.a = val
	end
end

function Rectangle:set_click_color(val)
	if val ~= true then assert(val:is(Color), "value must be of type 'color'.") end
	self.meta.click_color = val
end

function Rectangle:set_click_r(val)
	local clr = self.meta.click_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.r = val
		self.meta.click_color = clr
	else
		self.meta.click_color.r = val
	end
end

function Rectangle:set_click_g(val)
	local clr = self.meta.click_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.g = val
		self.meta.click_color = clr
	else
		self.meta.click_color.g = val
	end
end

function Rectangle:set_click_b(val)
 	local clr = self.meta.click_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.b = val
		self.meta.click_color = clr
	else
		self.meta.click_color.b = val
	end
end

function Rectangle:set_click_a(val)
 	local clr = self.meta.click_color
	
	if clr == true then 
		clr   = self.base_color:clone()
		clr.a = val
		self.meta.click_color = clr
	else
		self.meta.click_color.a = val
	end
end

function Rectangle:set_click_callback(val)
	assert(type(val) == "function" or val == true, "Passed callback is not a valid function.")
	self.meta.callback.click = val
end	

function Rectangle:set_hover_callback(val)
	assert(type(val) == "function" or val == true, "Passed callback is not a valid function.")
	self.meta.callback.hover = val
end	

function Rectangle:set_hold_callback(val)
	assert(type(val) == "function" or val == true, "Passed callback is not a valid function.")
	self.meta.callback.hold = val
end	

function Rectangle:set_visual(val)
	assert(type(val) == "boolean", "Visual can only be set to true or false.")
	self.meta.visual = val
end
		
function Rectangle:draw()
	if self.meta.visual then
		love.graphics.setColor(self[(self.click and "click" or (self.hover and "hover" or "base")) .. "_color"].to_love)
		love.graphics.rectangle(self.mode, self.x, self.y, self.w, self.h)
	end
end

function Rectangle:update(dt, mouse)
	local hover, callback
	
	hover = self:containsPoint(mouse.pos)

	if not hover then
		self.hover = false
		self.click = false
	elseif hover then
		callback = self.meta.callback.hover ~= true and self.meta.callback.hover or callback
		
		if mouse.held then
			self.hover = true
			callback = (self.click and self.meta.callback.hold ~= true) and self.meta.callback.hold or callback
		else
			self.hover = true
			callback = ((self.click and not mouse.down) and self.meta.callback.click ~= true) and self.meta.callback.click or callback
			self.click = mouse.down
		end
	end
	
	if callback then return callback(self, dt, mouse) end
end

function Rectangle:containsPoint(point)
	assert(point:is(Point), "Passed value was not of type 'point'.")
	return ((self.x <= point.x and point.x <= self.x + self.w) and (self.y <= point.y and point.y <= self.y + self.h))
end

function Rectangle:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y .. ", w: " .. self.w .. ", h: " .. self.h
end

return Rectangle