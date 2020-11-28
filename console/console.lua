local path, classic, inspect, Object

path = string.match(..., ".*/") or ""

inspect  = require(path .. "inspect")
Object   = require(path .. "classic")
mouse    = require(path .. "global_mouse")

--[[
				   ____ ___  _   _ ____   ___  _     _____ 
				  / ___/ _ \| \ | / ___| / _ \| |   | ____|
				 | |  | | | |  \| \___ \| | | | |   |  _|  
				 | |__| |_| | |\  |___) | |_| | |___| |___ 
				  \____\___/|_| \_|____/ \___/|_____|_____|
													   
							by Jumsplat120
							
	MODIFIED UNLICENSE LICENSE		
	
	This is free and unencumbered software released into the public domain.

	Anyone is free to copy, modify, publish, use, compile, sell, or
	distribute this software, either in source code form or as a compiled
	binary, for any purpose, commercial or non-commercial, and by any
	means.

	In jurisdictions that recognize copyright laws, the author or authors
	of this software dedicate any and all copyright interest in the
	software to the public domain. We make this dedication for the benefit
	of the public at large and to the detriment of our heirs and
	successors. We intend this dedication to be an overt act of
	relinquishment in perpetuity of all present and future rights to this
	software under copyright law.
	
	WHILE NOT REQUIRED, if this code is used in any commercial project, I
	would love to be notified. You can reach me personally at @jumpsplat120
	on Twitter, jumpsplat120#0001 on Discord, or jumpsplat120@yahoo.com

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.

	For more information, please refer to <http://unlicense.org/>
]]--

-----DEFAULT VALUES-----

local def_width, def_height, def_min_width, def_min_width, def_font_size, def_font_color, dark_theme_active, file, def_theme

def_width  = 976
def_height = 480
def_min_width = 677
def_min_width = 343
def_font_size = 12

def_theme = {
	light = {
		windows_bar      = nil,
		text_and_icons   = nil,
		scrollbar_bg     = nil,
		scrollbar_bar    = nil,
		scrollbar_arrows = nil,
		border           = nil,
		exit_hover       = nil,
		other_hover      = nil
	},
	dark  = {
		windows_bar      = nil,
		text_and_icons   = nil,
		scrollbar_bg     = nil,
		scrollbar_bar    = nil,
		scrollbar_arrows = nil,
		border           = nil,
		exit_hover       = nil,
		other_hover      = nil
	}
}

file = io.popen("reg query HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v AppsUseLightTheme")

dark_theme_active = tonumber(file:read("*a"):match("%dx(%d)")) == 0

file:close()


-----BASIC FUNCTIONS-----

local round, map, constrain, stringify

function round(val)
    return math.floor(val + .5)
end

function map(from_min, from_max, to_min, to_max, val)
	return (val - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
end

function constrain(min, max, val)
	return (val < min and min) or (val > max and max) or val
end

function stringify(val)
	return type(val) == "table" and inspect(val) or tostring(val)
end

-----CLASSES-----

local Point, Rectangle, Console, Color

Point     = Object:extend()
Console   = Object:extend()
Color     = Object:extend()
Rectangle = Object:extend()

	--=========COLOR=========--

function Color:new(r, g, b, a)	
	self.r = r or 0
	self.g = g or 0
	self.b = b or 0
	self.a = a or 0
end

function Color:get_r() return rawget(self, "r") end
function Color:get_g() return rawget(self, "g") end
function Color:get_b() return rawget(self, "b") end
function Color:get_a() return rawget(self, "a") end

function Color:get_to_love() return { self.r / 255, self.g / 255, self.b / 255, self.a } end

function Color:set_r(val)
	assert(val >= 0, "Unable to set red less than zero.")
	assert(255 >= val, "Unable to set red to more than 255.")
	rawset(self, "r", val)
end

function Color:set_g(val)
	assert(val >= 0, "Unable to set green less than zero.")
	assert(255 >= val, "Unable to set green to more than 255.")
	rawset(self, "g", val)
end

function Color:set_b(val)
	assert(val >= 0, "Unable to set blue less than zero.")
	assert(255 >= val, "Unable to set blue to more than 255.")
	rawset(self, "b", val)
end

function Color:set_a(val)
	assert(val >= 0, "Unable to set alpha less than zero.")
	assert(1 >= val, "Unable to set alpha to more than 1.")
	rawset(self, "a", val)
end

function Color:__tostring()
	return "r: " .. self.r .. ", g: " .. self.g .. ", b: " .. self.b .. ", a: " .. self.a
end

def_background = Color(12, 12, 12, 1)

def_font_color = Color(204, 204, 204, 1)

def_theme.dark.windows_bar      = Color(43, 43, 43, 1)
def_theme.dark.text_and_icons   = Color(255, 255, 255, 1)
def_theme.dark.scrollbar_bg     = Color(23, 23, 23, 1)
def_theme.dark.scrollbar_bar    = Color(77, 77, 77, 1)
def_theme.dark.scrollbar_arrows = Color(103, 103, 103, 1)
def_theme.dark.border           = Color(121, 121, 121, 1)
def_theme.dark.exit_hover       = Color(232, 17, 35, 1)
def_theme.dark.other_hover      = Color(26, 26, 26, 1)

def_theme.light.windows_bar      = Color(255, 255, 255, 1)
def_theme.light.text_and_icons   = Color(0, 0, 0, 1)
def_theme.light.scrollbar_bg     = Color(240, 240, 240, 1)
def_theme.light.scrollbar_bar    = Color(205, 205, 205, 1)
def_theme.light.scrollbar_arrows = Color(96, 96, 96, 1)
def_theme.light.border           = Color(240, 240, 240, 1)
def_theme.dark.exit_hover       = Color(232, 17, 35, 1)
def_theme.dark.other_hover      = Color(229, 229, 229, 1)

	--=========POINT=========--

function Point:new(x, y)	
	self.x = x or 0
	self.y = y or 0
end

function Point:get_x() return rawget(self, "x") end
function Point:get_y() return rawget(self, "y") end

function Point:set_x(val)
	assert(type(val) == "number", "Unable to set x to " .. tostring(val) .. " as value is not of type 'number'.")
	rawset(self, "x", val)
end

function Point:set_y(val)
	assert(type(val) == "number", "Unable to set y to " .. tostring(val) .. " as value is not of type 'number'.")
	rawset(self, "y", val)
end

function Point:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y
end

	--=======RECTANGLE=======--
		
function Rectangle:new(x, y, w, h, color, mode)	
	self.x = x or 0
	self.y = y or 0
	self.w = w or 0
	self.h = h or 0
	self.color = color or Color(0, 0, 0, 1)	
	self.mode  = mode or "fill"
end

function Rectangle:get_x() return rawget(self, x) end
function Rectangle:get_y() return rawget(self, y) end
function Rectangle:get_w() return rawget(self, w) end
function Rectangle:get_h() return rawget(self, h) end
function Rectangle:get_mode() return rawget(self, mode) end
function Rectangle:get_r() return rawget(self.color, r) end
function Rectangle:get_g() return rawget(self.color, g) end
function Rectangle:get_b() return rawget(self.color, b) end
function Rectangle:get_a() return rawget(self.color, a) end

function Rectangle:set_r(val) rawset(self.color, r, val) end
function Rectangle:set_g(val) rawset(self.color, g, val) end
function Rectangle:set_b(val) rawset(self.color, b, val) end
function Rectangle:set_a(val) rawset(self.color, a, val) end

function Rectangle:set_x(val)
	assert(type(val) == "number", "Unable to set x to " .. tostring(val) .. " as value is not of type 'number'.")
	rawset(self, "x", val)
end

function Rectangle:set_y(val)
	assert(type(val) == "number", "Unable to set y to " .. tostring(val) .. " as value is not of type 'number'.")
	rawset(self, "y", val)
end

function Rectangle:set_color(val)
	assert(val:is(Color), "Value must be of type 'color'.")
	rawset(self, "color", val)
end

function Rectangle:set_mode(val)
	val = tostring(val):lower()
	
	assert(val == "fill" or val == "line", "DrawMode must be of type 'fill' or 'line'.")
	rawset(self, "mode", val)
end

function Rectangle:set_w(val)
	assert(val >= 0, "Unable to set a width less than 0.")	
	rawset(self, "w", val)
end

function Rectangle:set_h(val)
	assert(val >= 0, "Unable to set a height less than 0.")	
	rawset(self, "h", val)
end

function Rectangle:draw()
	love.graphics.setColor(self.color.to_love)
	love.graphics.rectangle(self.mode, self.x, self.x, self.w, self.h)
end

function Rectangle:update(dt)
end

function Rectangle:containsPoint(point)
	assert(point:is(Point), "Passed value was not of type 'point'.")
	return ((self.x <= point.x and point.x <= self.x + self.w) and (self.y <= point.y and point.y <= self.y + self.h))
end

function Rectangle:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y .. ", w: " .. self.w .. ", h: " .. self.h
end

	--========CONSOLE========--

--Called once on load. Used for non-love based loading.
function Console:new()
	self.color = {
		font             = def_font_color,
		background       = def_background,
		windows_bar      = def_theme[dark_theme_active and "dark" or "light"].windows_bar,
		text_and_icons   = def_theme[dark_theme_active and "dark" or "light"].text_and_icons,
		scrollbar_bg     = def_theme[dark_theme_active and "dark" or "light"].scrollbar_bg,
		scrollbar_bar    = def_theme[dark_theme_active and "dark" or "light"].scrollbar_bar,
		scrollbar_arrows = def_theme[dark_theme_active and "dark" or "light"].scrollbar_arrows,
		border           = def_theme[dark_theme_active and "dark" or "light"].border
	}
	
	self.window = {
		width  = def_width,
		height = def_height,
		flags  = { borderless = true, minwidth = def_min_width, minheight = def_min_height }
	}
	
	self.cursor = {
		showing = {
			timer = 0,
			is    = true
		},
		pos = 1
	}
	
	self.scrollbar = {
		background = Rectangle(0, 0, 0, 0),
		foreground = Rectangle(0, 0, 0, 0)
	}
	
	self.font = {
		size = def_font_size
	}
	
	self.input_history = {
		data = {}
	}
	
	self.input = ""
	self.highlight = false
	
end

--Placed in the love.load function.
function Console:load(ctype)
	--Whether the console is being used for an internal project (such as a text adventure),
	--or whether the console is being used externally as the console window for another
	--project. Accepted values are "internal" or "cmd"
	ctype = ctype or "internal"
	
	assert(ctype == "internal" or ctype == "cmd", "Console load type '" .. ctype .. "' was not valid.")
	
	love.window.setMode(self.window.width, self.window.height, self.window.flags)

	love.graphics.setBackgroundColor(self.color.background.to_love)

	love.keyboard.setKeyRepeat(true)
		
	self.font.type   = love.graphics.newFont(path .. "terminal.ttf", self.font.size)
	self.font.height = self.font.type:getHeight()
	self.font.width  = self.font.type:getWidth(" ")
	
	self.type = ctype
end

--Placed in the love.update function.
function Console:update(dt)
end

--Placed in the love.draw function.
function Console:draw()
end

--Placed in the love.resize function.
function Console:resize(w, h)
end

--Placed in the love.textinput function.
function Console:textinput(k)
end

--Placed in the love.keypressed function.
function Console:keypressed(key, scancode, isrepeat)	
end

--Placed in the love.wheelmoved function.
function Console:wheelmoved(x, y)
end

--Print plain white output to the console.
function Console:print()
end

--Print output to the console of a specified color, along with a timestamp.
function Console:log()
end

--Clear the output of the console.
function Console:clear()
end

--Set the accessory color of the console (The bakground of the scrollbar, the color of the cursor, and the text highlighter color.)
function Console:setAccessoryColor(color)
end

--Set the background color of the console.
function Console:setBackgroundColor(color)
end

--Resets the console to the original state upon load.
function Console:reset()
	self.color = {
		font             = def_font_color,
		background       = def_background,
		windows_bar      = def_theme[dark_theme_active and "dark" or "light"].windows_bar,
		text_and_icons   = def_theme[dark_theme_active and "dark" or "light"].text_and_icons,
		scrollbar_bg     = def_theme[dark_theme_active and "dark" or "light"].scrollbar_bg,
		scrollbar_bar    = def_theme[dark_theme_active and "dark" or "light"].scrollbar_bar,
		scrollbar_arrows = def_theme[dark_theme_active and "dark" or "light"].scrollbar_arrows,
		border           = def_theme[dark_theme_active and "dark" or "light"].border
	}
	
	self.window = {
		width  = def_width,
		height = def_height,
		flags  = { borderless = true, minwidth = def_min_width, minheight = def_min_height }
	}
	
	self.cursor = {
		showing = {
			timer = 0,
			is    = true
		},
		pos = 1
	}
	
	self.scrollbar = {
		background = Rectangle(0, 0, 0, 0),
		foreground = Rectangle(0, 0, 0, 0)
	}
	
	self.font = {
		size = def_font_size
	}
	
	self.input = ""
	self.highlight = false
	
	love.window.setMode(self.window.width, self.window.height, self.window.flags)

	love.graphics.setBackgroundColor(self.color.background.to_love)

	love.keyboard.setKeyRepeat(true)
		
	self.font.type   = love.graphics.newFont(path .. "terminal.ttf", self.font.size)
	self.font.height = self.font.type:getHeight()
	self.font.width  = self.font.type:getWidth(" ")
	
	--TODO: Reset clear all lines from console
	--      Clear history
end

return Console(), Color