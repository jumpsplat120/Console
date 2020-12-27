Rectangle = Object:extend()

-- x, y, w, h and base_color are required, but do have defaults. hover and click can take a color or 'true'. Passing true
-- is basically saying that this rectangle doesn't have different colors for hovering or clicking. If attempting to access
-- the hover or click color after it's been set to not use one, it will instead return the base_color, since that is visually
-- what is happening, even though internally hover and click don't contain anything. Attempting to set and individual value
-- for hover or click when they do not exist, will clone the base color and change the expected value.
function Rectangle:new(callback, x, y, w, h, base_color, hover_color, click_color, mode)
	assert(type(callback) == "function", "Missing valid callback.")
	
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
		callback = callback
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

function Rectangle:set_callback(val)
	assert(type(val) == "function", "Passed callback is not a valid function.")
	self.meta.callback = val
end	
		--===|||METHODS|||===--
		
function Rectangle:draw()
	love.graphics.setColor(self[(self.click and "click" or (self.hover and "hover" or "base")) .. "_color"].to_love)
	love.graphics.rectangle(self.mode, self.x, self.y, self.w, self.h)
end

function Rectangle:update(dt, mouse)
	local hover = self:containsPoint(mouse.pos)

	if not hover then
		self.hover = false
		self.click = false
	elseif hover then
		if mouse.held then 
			self.hover = true
		else
			self.hover = true
			self.click = mouse.down
		end
	end
	
	
end

function Rectangle:containsPoint(point)
	assert(point:is(Point), "Passed value was not of type 'point'.")
	return ((self.x <= point.x and point.x <= self.x + self.w) and (self.y <= point.y and point.y <= self.y + self.h))
end

function Rectangle:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y .. ", w: " .. self.w .. ", h: " .. self.h
end