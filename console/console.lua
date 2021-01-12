local path, classic, inspect, Object, Color, Point, Rectangle, Line, Console, Window

path = string.match(..., ".*/") or ""

inspect = require(path .. "third_party/inspect")
Object  = require(path .. "third_party/classic")
Mouse   = require(path .. "bin/global_mouse")
Window  = require(path .. "bin/window_manipulation")

require(path .. "bin/monkeypatch_type")

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

local def_width, def_height, def_min_width, def_min_height, def_font_size, def_font_color, dark_theme_active, file, def_theme, titlebar_size, scrollbar_width, scrollbar_height, scroll_amt

def_width  = 976
def_height = 480
def_min_width = 677
def_min_height = 343
def_font_size = 14

--NOTE ALL THE COLORS ARE IN THE REGISTRY TOO IF I FEEL LIKE UPDATING THAT AT ANY POINT

file = io.popen("reg query HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v AppsUseLightTheme")

dark_theme_active = tonumber(file:read("*a"):match("%dx(%d)")) == 0

-- Did you know that you HAVE to use double quotes or this command fails?
file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v CaptionHeight')

titlebar_size = tonumber(file:read("*a"):match("-*%d+")) / -11

file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v ScrollWidth')

scrollbar_width = tonumber(file:read("*a"):match("-*%d+")) / -15

file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v ScrollHeight')

scrollbar_height = tonumber(file:read("*a"):match("-*%d+")) / -15

file = io.popen('reg query "HKCU\\Control Panel\\Desktop" /v WheelScrollLines')

--negative 1 means "one screen at a time" which means nothing on a console
scroll_amt = tonumber(file:read("*a"):match("-*%d+"))
scroll_amt = scroll_amt == -1 and 1 or scroll_amt

file:close()

-----BASIC FUNCTIONS-----

local round, map, constrain, stringify, cycle

do

function round(val)
    return math.floor(val + .5)
end

function map(from_min, from_max, to_min, to_max, val)
	return (val - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
end

function constrain(min, max, val)
	return (val < min and min) or (val > max and max) or val
end

function cycle(min, max, val)
	local res
	if val < min or val > max then
		local is_more, dt1, dt2
		is_more = val > max
		dt1 = max - min
		dt2 = math.ceil(math.abs((val - (is_more and max or min)) / dt1)) * dt1
		res = is_more and (val - dt2) or (val + dt2)
	else
		res = val
	end
	
	return res
end

function stringify(val)
	return type(val) == "table" and inspect(val) or tostring(val)
end

end
-----CALLBACKS-----

local noPassthrough, borderLeft, borderRight, borderTop, borderBot
local borderTLeft, borderTRight, borderBLeft, borderBRight
local scrollbarBG, scrollbarBar, scrollbarMath, scrollbarClickUp
local scrollbarClickDown, scrollbarHoldUp, scrollbarHoldDown, titlebar
local exitButton, maxButton, minButton, control

do

function noPassthrough()
	return true
end

--Some of the border extends visually "wiggle" the drawn elements. I have no idea where that's coming from because
--the elements draw based on their own internal idea of the coord system. It's possible since Love is running 
--during the resize, it's one loop behind kind of like with the drawn window, which means there's nothing to do
--about it short of recompiling love to reorder when certain things happen. So for now, wiggly windows are a feature.
function borderInit(self, dt, mouse, args)
	if not self.initial_click_pos or not self.initial_win_size then 
		self.initial_click_pos = mouse.global.pos:clone()
		self.initial_win_size = { 
		x = args.window.x, 
		y = args.window.y, 
		w = args.window.width, 
		h = args.window.height }
	end
	
	return mouse.global.pos - self.initial_click_pos
end

function borderMath(self, new, old)
	if self.window.flags.minwidth < new.w and self.window.flags.minheight < new.h then
		local pos_match, size_match = new.x ~= old.x or new.y ~= old.y, new.w ~= old.w or new.h ~= old.h
		if pos_match then Window:move(new.x, new.y) end
		if size_match then Window:resize(new.w, new.h) end
		if pos_match or size_match then self:resize(new.w, new.h) end
	end
end

function borderLeftHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x + diff.x
		new.y = self.initial_win_size.y
		
		new.w = self.initial_win_size.w - diff.x
		new.h = self.initial_win_size.h
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "leftHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderRightHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x
		new.y = self.initial_win_size.y
		
		new.w = self.initial_win_size.w + diff.x
		new.h = self.initial_win_size.h
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "rightHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderTopHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x
		new.y = self.initial_win_size.y + diff.y
		
		new.w = self.initial_win_size.w
		new.h = self.initial_win_size.h - diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "topHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderBotHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x
		new.y = self.initial_win_size.y
		
		new.w = self.initial_win_size.w
		new.h = self.initial_win_size.h + diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "botHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderTLeftHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x + diff.x
		new.y = self.initial_win_size.y + diff.y
		
		new.w = self.initial_win_size.w - diff.x
		new.h = self.initial_win_size.h - diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "tLeftHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderTRightHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x
		new.y = self.initial_win_size.y + diff.y
		
		new.w = self.initial_win_size.w + diff.x
		new.h = self.initial_win_size.h - diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "tRightHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderBLeftHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x + diff.x
		new.y = self.initial_win_size.y
		
		new.w = self.initial_win_size.w - diff.x
		new.h = self.initial_win_size.h + diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()
		
		borderMath(args[1], new, old)
		
		return "bLeftHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderBRightHold(self, dt, mouse, args)
	local diff = borderInit(self, dt, mouse, args[1])
	
	if mouse.held then
		local new, old, _ = {}, {}
		
		new.x = self.initial_win_size.x
		new.y = self.initial_win_size.y
		
		new.w = self.initial_win_size.w + diff.x
		new.h = self.initial_win_size.h + diff.y
		
		old.w, old.h, _ = love.window.getMode()
		old.x, old.y = love.window.getPosition()

		borderMath(args[1], new, old)
		
		return "bRightHold"
	else
		self.initial_click_pos = nil
		self.initial_win_size  = nil
		
		local w, h, _ = love.window.getMode()
		
		love.resize(w, h)
		
		return true
	end
end

function borderHorizontalHover(self, dt, mouse, args)
	love.mouse.setCursor(mouse.system.size_hor)
	return true
end

function borderVerticalHover(self, dt, mouse, args)
	love.mouse.setCursor(mouse.system.size_vert)
	return true
end

function borderLeftUpHover(self, dt, mouse, args)
	love.mouse.setCursor(mouse.system.size_lup)
	return true
end

function borderRightUpHover(self, dt, mouse, args)
	love.mouse.setCursor(mouse.system.size_rup)
	return true
end

function borderResetHover(self, dt, mouse, args)
	if love.mouse.getCursor() ~= mouse.system.pointer then love.mouse.setCursor(mouse.system.pointer) end
end

function scrollbarBG(self, dt, mouse, args)
	args[1].scrollbar.bar.y = mouse.loc.pos.y - (args[1].scrollbar.bar.h / 2)
	args[1].window.scroll_offset = round(map(args[1].scrollbar.min, args[1].scrollbar.max, 0, args[1].keyboard.max_output, args[1].scrollbar.bar.y))
	return "scrollbarHold"
end

function scrollbarBar(self, dt, mouse, args)	
	if mouse.held then
		if not self.mouse_offset then self.mouse_offset = self.y - mouse.loc.pos.y end
		self.y = constrain(args[1].scrollbar.min, args[1].scrollbar.max, mouse.loc.pos.y + self.mouse_offset)
		args[1].window.scroll_offset = round(map(args[1].scrollbar.min, args[1].scrollbar.max, 0, args[1].keyboard.max_output, self.y))
		return "scrollbarHold"
	else
		self.mouse_offset = nil
		
		return true
	end
end

function scrollbarMath(self, console, adjust)
	console.window.scroll_offset = constrain(0, console.keyboard.max_output, console.window.scroll_offset + adjust)
	console.scrollbar.bar.y = round(map(0, console.keyboard.max_output, console.scrollbar.min, console.scrollbar.max, console.window.scroll_offset))
end

function scrollbarClickUp(self, dt, mouse, args)
	scrollbarMath(self, args[1], 1)
	return true
end

function scrollbarClickDown(self, dt, mouse, args)
	scrollbarMath(self, args[1], -1)
	return true
end

function scrollbarHoldUp(self, dt, mouse, args)
	if not self.timeout then self.timeout = 0 end
	self.timeout = self.timeout + dt
	
	if self.timeout > .75 then
		if mouse.held then
			scrollbarMath(self, args[1], 1)
		else
			self.timeout = nil
			return true
		end
	end
end

function scrollbarHoldDown(self, dt, mouse, args)
	if not self.timeout then self.timeout = 0 end
	self.timeout = self.timeout + dt
	
	if self.timeout > .75 then
		if mouse.held then
			scrollbarMath(self, args[1], -1)
		else
			self.timeout = nil
			return true
		end
	end
end

function titlebarGrab(self, dt, mouse, args)
	return "titlebarHold"
end

function titlebarHold(self, dt, mouse, args)
	self.offset = self.offset == nil and mouse.loc.pos:clone() or self.offset
	if not mouse.held then
		self.offset = nil
	else
		local x, y = mouse.global.pos.x - self.offset.x, mouse.global.pos.y - self.offset.y
		love.window.setPosition(x, y, args[1].window.display) --Display is not being dynamically calc'd! Needs testing on multi monitor setups
		return "titlebarHold", x, y
	end
end

function exitButton(self, dt, mouse, args)
	love.event.quit(0)
	return true
end

function maxButton(self, dt, mouse, args)
	if love.window.isMaximized() then 
		print("Unmaximizing!")
		love.window.restore() 
	else
		print("Maximizing!")
		love.window.maximize()
	end
	return true
end

function minButton(self, dt, mouse, args)
	print("Minimizing!")
	love.window.minimize()
	return true
end

control = {
	backspace = function(self)
		local text_len, decrease, text
		
		text     = self.keyboard.input.data
		text_len = text:len()
		decrease = self.keyboard.input.current_width - self.font.width
		
		if self.keyboard.highlight then
			self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset - math.floor(self.keyboard.input.data:len() / self.keyboard.wrap_width_in_chars))
			self.keyboard.input.data = ""
			self.keyboard.input.current_width = 0
			self.cursor.pos = 0
			self.keyboard.highlight = false
		else
			self.keyboard.input.data = self.cursor.pos == text_len and text:sub(1, text_len - 1) or text:sub(1, self.cursor.pos - 1) .. text:sub(self.cursor.pos + 1, text_len)
			self.keyboard.input.current_width = decrease < 0 and (self.keyboard.wrap_width_in_chars - 1) * self.font.width or decrease
			self.cursor.pos = constrain(0, self.keyboard.input.data:len(), self.cursor.pos - 1)
			self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset - ((self.keyboard.input.current_width == (self.keyboard.wrap_width_in_chars - 1) * self.font.width) and 1 or 0))
		end
		
		self.cursor.timer = 0
		self.cursor.showing = true
	end,
	enter = function(self)
		local input, multiline
		
		input = self.keyboard.input
		
		multiline = Line(self, input.data)

		for i, line in ipairs(multiline) do
			local res = self:submit(line)
			
			if res then
				local output, res_type
				
				res_type = type(res)
				output   = res_type == "Line" and res or (res_type == "string" and Line(self, res) or Line(self, stringify(res)))
				self.keyboard.output[#self.keyboard.output + 1] = output
				self.keyboard.input.history[#self.keyboard.input.history + 1] = {data = output, cur_width = cycle(0, self.keyboard.wrap_width_in_chars, output:len()) }
				self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset + 1)
				self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
			end
		end
		
		self.keyboard.input.data          = ""
		self.keyboard.input.current_width = 0
		self.cursor.pos                   = 0
		self.keyboard.highlight           = false
	end,
	shift_enter = function(self)
	end,
	up = function(self)
		local input, history_len
		
		input       = self.keyboard.input
		history_len = #input.history
		
		if history_len > 0 then
			self.keyboard.input.history_index = constrain(1, history_len, input.history_index + 1)
			self.keyboard.input.data          = input.history[input.history_index].data
			self.keyboard.input.current_width = input.history[input.history_index].cur_width
			self.keyboard.highlight           = false
			self.cursor.pos                   = self.keyboard.input.data:len()
		end
	end,
	down = function(self) 
		local input, history_len
		
		input       = self.keyboard.input
		history_len = #input.history
		
		if history_len > 0 then
			self.keyboard.input.history_index = constrain(1, history_len, input.history_index - 1)
			self.keyboard.input.data          = input.history[input.history_index].data
			self.keyboard.input.current_width = input.history[input.history_index].cur_width
			self.keyboard.highlight           = false
			self.cursor.pos                   = self.keyboard.input.data:len()
		end 
	end,
	left = function(self)
		self.cursor.pos = constrain(0, self.keyboard.input.data:len(), self.cursor.pos - 1)
		self.cursor.timer = 0
		self.cursor.showing = true
	end,
	right = function(self)
		self.cursor.pos = constrain(0, self.keyboard.input.data:len(), self.cursor.pos + 1)
		self.cursor.timer = 0
		self.cursor.showing = true
	end,
	shift_left = function(self)
		self.cursor.pos = 0
		self.cursor.timer = 0
		self.cursor.showing = true
		self.keyboard.highlight = false
	end,
	shift_right = function(self)
		self.cursor.pos = self.keyboard.input.data:len()
		self.cursor.timer = 0
		self.cursor.showing = true
		self.keyboard.highlight = false
	end,
	shift_up = function(self)
		local input, history_len
		
		input       = self.keyboard.input
		history_len = #input.history
		
		if history_len > 0 then
			self.keyboard.input.history_index = constrain(1, history_len, input.history_index + 10)
			self.keyboard.input.data          = input.history[input.history_index].data
			self.keyboard.input.current_width = input.history[input.history_index].cur_width
			self.keyboard.highlight           = false
			self.cursor.pos                   = self.keyboard.input.data:len()
		end
	end,
	shift_down = function(self)
		local input, history_len
		
		input       = self.keyboard.input
		history_len = #input.history
		
		if history_len > 0 then
			self.keyboard.input.history_index = constrain(1, history_len, input.history_index - 10)
			self.keyboard.input.data          = input.history[input.history_index].data
			self.keyboard.input.current_width = input.history[input.history_index].cur_width
			self.keyboard.highlight           = false
			self.cursor.pos                   = self.keyboard.input.data:len()
		end 
	end,
	ctrl_c = function(self)
		if self.keyboard.highlight then
			love.system.setClipboardText(self.keyboard.input.data)
		end
	end,
	ctrl_v = function(self)
		local paste = love.system.getClipboardText()
		
		if self.keyboard.highlight then
			if paste:find("\n") then
				for text in paste:gmatch("([^\n]*)\n") do
					text = self:submit(text)
					if text then
						self.keyboard.input.history[#self.keyboard.input.history + 1] = {data = text, cur_width = cycle(0, self.keyboard.wrap_width_in_chars, text:len())}
						multiline = Line(self, text)
						self.keyboard.output[#self.keyboard.output + 1] = multiline[1]
						self.window.scroll_offset = self.window.scroll_offset + 1
						self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
					end
				end
				paste = paste:match("\n([^\n]*)$")
			end
			
			self.keyboard.input.data = paste
			self.keyboard.input.current_width = cycle(0, self.keyboard.wrap_width_in_chars, self.keyboard.input.data:len()) * self.font.width
			self.window.scroll_offset = self.window.scroll_offset + math.floor(self.keyboard.input.data:len() / self.keyboard.wrap_width_in_chars)
			self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
			self.cursor.pos = self.keyboard.input.data:len()
			self.keyboard.highlight = false
		else
			if paste:find("\n") then
				for text in paste:gmatch("([^\n]*)\n") do
					self.keyboard.input.data = self.keyboard.input.data ~= "" and (self.cursor.pos == self.keyboard.input.data:len() and self.keyboard.input.data .. text or self.keyboard.input.data:sub(1, self.cursor.pos) .. text .. self.keyboard.input.data:sub(self.cursor.pos + 1, self.keyboard.input.data:len())) or text
					self.keyboard.input.data = self:submit(self.keyboard.input.data)
					if self.keyboard.input.data then
						self.keyboard.input.history[#self.keyboard.input.history + 1] = {data = self.keyboard.input.data, cur_width = cycle(0, self.keyboard.wrap_width_in_chars, self.keyboard.input.data:len())}
						multiline = Line(self, self.keyboard.input.data)
						self.keyboard.output[#self.keyboard.output + 1] = multiline[1]
						self.window.scroll_offset = self.window.scroll_offset + 1
						self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
					end
					self.keyboard.input.data = ""
				end
				paste = paste:match("\n([^\n]*)$")
				self.cursor.pos = 0
			end
			
			local cur_height = math.floor(self.keyboard.input.data:len() / self.keyboard.wrap_width_in_chars)
			self.keyboard.input.data = self.cursor.pos == self.keyboard.input.data:len() and self.keyboard.input.data .. paste or self.keyboard.input.data:sub(1, self.cursor.pos) .. paste .. self.keyboard.input.data:sub(self.cursor.pos + 1, self.keyboard.input.data:len())
			self.keyboard.input.current_width = cycle(0, self.keyboard.wrap_width_in_chars, self.keyboard.input.data:len()) * self.font.width
			self.cursor.pos = self.cursor.pos + paste:len()
			self.window.scroll_offset = self.window.scroll_offset + (math.floor(self.keyboard.input.data:len() / self.keyboard.wrap_width_in_chars) - cur_height)
			self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
			self.cursor.timer = 0
			self.cursor.showing = true
		end
	end,
	ctrl_x = function(self)
		if self.keyboard.highlight then
			love.system.setClipboardText(self.keyboard.input.data)
			self.keyboard.input.data = ""
			self.keyboard.input.current_width = 0
			self.cursor.pos = 0
			self.keyboard.highlight = false
		end
	end,
	ctrl_a = function(self)
		self.keyboard.highlight = true
	end
}

end
-----CLASSES-----

Console = Object:extend()

	--=========COLOR=========--

Color = require(path .. "bin/Color")

def_background = Color(12, 12, 12, 1)

def_font_color = Color(204, 204, 204, 1)

def_font_invert = Color(51, 51, 51, 1)

def_theme = {
	dark = {
		titlebar = {
			active = {
				base  = Color(0, 0, 0, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(43, 43, 43, 1),
				hover = true,
				click = true
			}
		},
		icons = {
			active = {
				base  = Color(255, 255, 255, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(128, 128, 128, 1),
				hover = Color(255, 255, 255, 1),
				click = true
			}
		},
		scrollbar = {
			background = {
				active = {
					base  = Color(23, 23, 23, 1),
					hover = true,
					click = true
				},
				inactive = {
					base  = Color(23, 23, 23, 1),
					hover = true,
					click = true
				}
			},
			bar = {
				active = {
					base  = Color(77, 77, 77, 1),
					hover = Color(122, 122, 122, 1),
					click = true 
				},
				inactive = {
					base  = Color(77, 77, 77, 1),
					hover = Color(122, 122, 122, 1),
					click = true
				}
			},
			arrows = {
				active = {
					base  = Color(103, 103, 103, 1),
					hover = true,
					click = Color(23, 23, 23, 1)
				},
				inactive = {
					base  = Color(103, 103, 103, 1),
					hover = true,
					click = Color(23, 23, 23, 1)
				}
			},
			arrows_bg = {
				active = {
					base  = Color(23, 23, 23, 1),
					hover = Color(55, 55, 55, 1),
					click = Color(166, 166, 166, 1)
				},
				inactive = {
					base  = Color(23, 23, 23, 1),
					hover = Color(55, 55, 55, 1),
					click = Color(166, 166, 166, 1)
				}
			}
		},
		border = {
			active = {
				base  = Color(125, 125, 125, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(170, 170, 170, 1),
				hover = true,
				click = true
			}
		},
		exit = {
			active = {
				base  = Color(0, 0, 0, 1),
				hover = Color(232, 17, 35, 1),
				click = Color(139, 10, 20, 1)
			},
			inactive = {
				base  = Color(43, 43, 43, 1),
				hover = Color(232, 17, 35, 1),
				click = Color(139, 10, 20, 1)
			}
		},
		other = {
			active = {
				base  = Color(0, 0, 0, 1),
				hover = Color(26, 26, 26, 1),
				click = Color(51, 51, 51, 1)
			},
			inactive = {
				base  = Color(43, 43, 43, 1),
				hover = Color(65, 65, 65, 1),
				click = Color(51, 51, 51, 1)
			}
		}
	},
	light = {
		titlebar = {
			active = {
				base  = Color(255, 255, 255, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(255, 255, 255, 1),
				hover = true,
				click = true
			}
		},
		icons = {
			active = {
				base  = Color(0, 0, 0, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(153, 153, 153, 1),
				hover = Color(0, 0, 0, 1),
				click = true
			}
		},
		scrollbar = {
			background = {
				active = {
					base  = Color(240, 240, 240, 1),
					hover = true,
					click = true
				},
				inactive = {
					base  = Color(240, 240, 240, 1),
					hover = true,
					click = true
				}
			},
			bar = {
				active = {
					base  = Color(205, 205, 205, 1),
					hover = Color(166, 166, 166, 1),
					click = true
				},
				inactive = {
					base  = Color(192, 192, 192, 1),
					hover = Color(166, 166, 166, 1),
					click = true
				}
			},
			arrows = {
				active = {
					base  = Color(96, 96, 96, 1),
					hover = Color(0, 0, 0, 1),
					click = Color(255, 255, 255, 1)
				},
				inactive = {
					base  = Color(96, 96, 96, 1),
					hover = Color(0, 0, 0, 1),
					click = Color(255, 255, 255, 1)
				}
			},
			arrows_bg = {
				active = {
					base  = Color(240, 240, 240, 1),
					hover = Color(218, 218, 218, 1),
					click = Color(96, 96, 96, 1)
				},
				inactive = {
					base  = Color(240, 240, 240, 1),
					hover = Color(218, 218, 218, 1),
					click = Color(96, 96, 96, 1)
				}
			}
		},
		border = {
			active = {
				base  = Color(128, 128, 128, 1),
				hover = true,
				click = true
			},
			inactive = {
				base  = Color(128, 128, 128, 1),
				hover = true,
				click = true 
			}
		},
		exit = {
			active = {
				base  = Color(255, 255, 255, 1),
				hover = Color(229, 229, 229, 1),
				click = Color(202, 202, 202, 1)
			},
			inactive = {
				base  = Color(255, 255, 255, 1),
				hover = Color(229, 229, 229, 1),
				click = Color(202, 202, 202, 1)
			}
		},
		other = {
			active = {
				base  = Color(255, 255, 255, 1),
				hover = Color(232, 17, 35, 1),
				click = Color(241, 112, 122, 1)
			},
			inactive = {
				base  = Color(255, 255, 255, 1),
				hover = Color(232, 17, 35, 1),
				click = Color(241, 112, 122, 1)
			}
		}
	}
}

	--=========POINT=========--

Point = require(path .. "bin/Point")

	--=======RECTANGLE=======--

Rectangle = require(path .. "bin/Rectangle")

	--=======RECTANGLE=======--

Line = require(path .. "bin/Line")

	--========CONSOLE========--
	
--Called once on load. Used for non-love based loading.
function Console:new()
	local theme = def_theme[dark_theme_active and "dark" or "light"]

	self.color = {
		font       = { base = def_font_color, inverted = def_font_invert },
		background = def_background,
		titlebar   = theme.titlebar,
		icons      = theme.icons,
		scrollbar  = theme.scrollbar,
		border     = theme.border,
		exit       = theme.exit,
		other      = theme.other
	}

	self.window = {
		width   = def_width,
		height  = def_height + titlebar_size,
		focus   = true,
		display = 1,
		scroll_offset = 0,
		full_line_amount = 0,
		last_resize = os.clock(),
		titlebar = {
			size       = titlebar_size,
			text       = "Custom Console",
			background = Rectangle(titlebarGrab, true, titlebarHold, {false, false, "titlebarHold"}, 0, 0, def_width, titlebar_size, self.color.titlebar.active.base, true, true),
			exit       = Rectangle(exitButton, noPassthrough, true, {false, false, false}, def_width - (titlebar_size * 1.4), 0, titlebar_size * 1.4, titlebar_size, self.color.exit.active.base, self.color.exit.active.hover, self.color.exit.active.click),
			maximize   = Rectangle(maxButton, noPassthrough, true, {false, false, false}, def_width - ((titlebar_size * 1.4) * 2), 0, titlebar_size * 1.4, titlebar_size, self.color.other.active.base, self.color.other.active.hover, self.color.other.active.click),
			minimize   = Rectangle(minButton, noPassthrough, true, {false, false, false}, def_width - ((titlebar_size * 1.4) * 3), 0, titlebar_size * 1.4, titlebar_size, self.color.other.active.base, self.color.other.active.hover, self.color.other.active.click)
		},
		flags  = { borderless = true, minwidth = def_min_width, minheight = def_min_height }
	}
	
	self.cursor = {
		timer = 0,
		pos = 0,
		showing = true
	}
	
	self.window.border = {
		visual = Rectangle(true, true, true, {false, false, false}, 0, 0, self.window.width, self.window.height, self.color.border.active.base, self.color.border.active.hover, self.color.border.active.click, "line"), 
		reset  = Rectangle(true, borderResetHover, true, {false, false, false}, 6, 6, self.window.width - 12, self.window.height - 12, true, true, true, nil, false),
		left   = Rectangle(true, borderHorizontalHover, borderLeftHold, {false, false, "leftHold"}, 0, 0, 4, self.window.height, true, true, true, nil, false),
		right  = Rectangle(true, borderHorizontalHover, borderRightHold, {false, false, "rightHold"}, self.window.width - 4, 0, 4, self.window.height, true, true, true, nil, false),
		bottom = Rectangle(true, borderVerticalHover, borderBotHold, {false, false, "botHold"}, 0, self.window.height - 4, self.window.width, 4, true, true, true, nil, false),
		top    = Rectangle(true, borderVerticalHover, borderTopHold, {false, false, "topHold"}, 0, 0, self.window.width, 4, true, true, true, nil, false),
		corner = {
			top_left  = Rectangle(true, borderLeftUpHover, borderTLeftHold, {false, false, "tLeftHold"}, 0, 0, 6, 6, true, true, true, nil, false),
			top_right = Rectangle(true, borderRightUpHover, borderTRightHold, {false, false, "tRightHold"}, self.window.width - 6, 0, 6, 6, true, true, true, nil, false),
			bot_left  = Rectangle(true, borderRightUpHover, borderBLeftHold, {false, false, "bLeftHold"}, 0, self.window.height - 6, 6, 6, true, true, true, nil, false),
			bot_right = Rectangle(true, borderLeftUpHover, borderBRightHold, {false, false, "bRightHold"}, self.window.width - 6, self.window.height - 6, 6, 6, true, true, true, nil, false)
		}
	}
	
	self.scrollbar = {
		background = Rectangle(scrollbarBG, true, true, {false, false, false}, self.window.width - scrollbar_width, self.window.titlebar.size, scrollbar_width, self.window.height, self.color.scrollbar.background.active.base, self.color.scrollbar.background.active.hover, self.color.scrollbar.background.active.click),
		bar        = Rectangle(true, noPassthrough, scrollbarBar, {false, false, "scrollbarHold"}, self.window.width - scrollbar_width, self.window.titlebar.size + scrollbar_height, scrollbar_width, scrollbar_height, self.color.scrollbar.bar.active.base, self.color.scrollbar.bar.active.hover, self.color.scrollbar.bar.active.click),
		arrow_up   = Rectangle(scrollbarClickUp, noPassthrough, scrollbarHoldUp, {false, false, false}, self.window.width - scrollbar_width, self.window.height - scrollbar_height, scrollbar_width, scrollbar_height, self.color.scrollbar.arrows_bg.active.base, self.color.scrollbar.arrows_bg.active.hover, self.color.scrollbar.arrows_bg.active.click),
		arrow_down = Rectangle(scrollbarClickDown, noPassthrough, scrollbarHoldDown, {false, false, false}, self.window.width - scrollbar_width, self.window.titlebar.background.h, scrollbar_width, scrollbar_height, self.color.scrollbar.arrows_bg.active.base, self.color.scrollbar.arrows_bg.active.hover, self.color.scrollbar.arrows_bg.active.click)
	}
	
	self.font = {
		size = def_font_size
	}
	
	self.keyboard = {
		mod = {},
		input = {
			data = "",
			current_width = 0,
			wrap_width_in_chars = 0,
			history_index = 0,
			history = {}
		},
		output = {},
		max_output = 10000,
		highlight = false
	}
	
	self.mouse = {
		global = {
			pos = Point(0, 0),
			dt  = Point(0, 0)
		},
		loc = {
			pos = Point(0, 0),
			dt  = Point(0, 0)
		},
		down = false,
		held = false
	}
	
	self.scrollbar.max = self.window.height - self.scrollbar.bar.h - self.scrollbar.arrow_up.h
	self.scrollbar.min = self.window.titlebar.size + self.scrollbar.arrow_down.h
	
	self.running_callback = nil
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
		
	self.font.type   = love.graphics.newFont(path .. "assets/text.ttf", self.font.size)
	self.font.height = self.font.type:getHeight()
	self.font.width  = self.font.type:getWidth(" ")
	
	self.window.titlebar.icon = love.graphics.newImage(path .. "assets/icon.png")
	
	self.window.titlebar.icon_imageData = love.image.newImageData(path .. "assets/icon.png")
	
	self.window.titlebar.font = love.graphics.newFont(path .. "assets/ui.ttf", self.window.titlebar.size * .45)

	self.window.x, self.window.y = love.window.getPosition()
	
	self.window.full_line_amount = round((self.window.height - self.window.titlebar.size) / self.font.height)
	
	self.keyboard.wrap_width_in_chars = math.floor((self.window.width - self.scrollbar.background.w - self.font.width - 4) / self.font.width)

	self.mouse.system = {
		pointer   = love.mouse.getSystemCursor("arrow"),
		hand      = love.mouse.getSystemCursor("hand"),
		move      = love.mouse.getSystemCursor("sizeall"),
		size_vert = love.mouse.getSystemCursor("sizens"),
		size_hor  = love.mouse.getSystemCursor("sizewe"),
		size_lup  = love.mouse.getSystemCursor("sizenwse"),
		size_rup  = love.mouse.getSystemCursor("sizenesw")
	}
		
	love.window.setTitle(self.window.titlebar.text)
	
	love.window.setIcon(self.window.titlebar.icon_imageData)
		
	assert(self.window.titlebar.icon:getWidth()  <= 256, "The icon must be a maximum of 256 wide!")
	assert(self.window.titlebar.icon:getHeight() <= 256, "The icon must be a maximum of 256 tall!")

	self.type = ctype
end

--Placed in the love.update function.
function Console:update(dt)
	local focus, result, x, y, is_down, win_x, win_y
	
	focus = love.window.hasFocus()

	x, y, is_down = Mouse.getGlobalMouseState()
	
	self.mouse.down = is_down == 1 and not self.mouse.held
	self.mouse.held = is_down == 1

	result = self.window.border.reset:update(dt, self.mouse, self.running_callback)
	result = self.window.border.corner.top_left:update(dt, self.mouse, result, self)
	result = self.window.border.corner.top_right:update(dt, self.mouse, result, self)
	result = self.window.border.corner.bot_left:update(dt, self.mouse, result, self)
	result = self.window.border.corner.bot_right:update(dt, self.mouse, result, self)
	result = self.window.border.left:update(dt, self.mouse, result, self)
	result = self.window.border.top:update(dt, self.mouse, result, self)
	result = self.window.border.right:update(dt, self.mouse, result, self)
	result = self.window.border.bottom:update(dt, self.mouse, result, self)
	result = self.window.titlebar.exit:update(dt, self.mouse, result, self)
	result = self.window.titlebar.minimize:update(dt, self.mouse, result)
	result = self.window.titlebar.maximize:update(dt, self.mouse, result)
	result, win_x, win_y = self.window.titlebar.background:update(dt, self.mouse, result, self)
	result = self.scrollbar.bar:update(dt, self.mouse, result, self)
	result = self.scrollbar.arrow_down:update(dt, self.mouse, result, self)
	result = self.scrollbar.arrow_up:update(dt, self.mouse, result, self)
	self.running_callback = self.scrollbar.background:update(dt, self.mouse, result, self)
	
	if win_x and win_y then self.window.x, self.window.y = win_x, win_y end
	
	--Pass true if you don't want passthrough on rects, but don't want to hold that callback continuously
	if self.running_callback == true then self.running_callback = nil end

	if focus ~= self.window.focus then
		local focus_state, colors, entries, states
		
		focus_state = (focus and "" or "in") .. "active"
		self.window.focus = focus
		
		--entries and colors need to line up!
		entries = {self.window.titlebar.background, self.window.titlebar.minimize, self.window.titlebar.maximize, self.window.titlebar.exit, self.window.border}
		colors  = {self.color.titlebar[focus_state], self.color.other[focus_state], self.color.other[focus_state], self.color.exit[focus_state], self.color.border[focus_state] }
		states  = {"base", "hover", "click"}
		
		for i, entry in ipairs(entries) do
			for j, state in ipairs(states) do
				entry[state .. "_color"] = colors[i][state]
			end
		end
	end
	
	self.mouse.global.dt:set(x - self.mouse.global.pos.x, y - self.mouse.global.pos.y)
	self.mouse.global.pos:set(x, y)
	self.mouse.loc.dt:set(0, 0)
	
	self.keyboard.mod = {}
	
	self.cursor.timer = self.cursor.timer + dt
	
	if self.cursor.timer > .5 then
		self.cursor.timer = 0
		self.cursor.showing = not self.cursor.showing
	end
	
	if love.keyboard.isDown("rctrl")  or love.keyboard.isDown("lctrl")  then self.keyboard.mod[#self.keyboard.mod + 1] = "ctrl"  end
	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then self.keyboard.mod[#self.keyboard.mod + 1] = "shift" end
end

--Placed in the love.draw function.
function Console:draw()
	self.window.titlebar.background:draw()
	self.window.titlebar.exit:draw()
	self.window.titlebar.minimize:draw()
	self.window.titlebar.maximize:draw()
	self.scrollbar.background:draw()
	self.scrollbar.bar:draw()
	self.scrollbar.arrow_down:draw()
	self.scrollbar.arrow_up:draw()
	self.window.border.visual:draw()
	
	love.graphics.setColor(1, 1, 1, 1)
	
	--Titlebar icon
	love.graphics.draw(self.window.titlebar.icon, 0, 0, 0, self.window.titlebar.size / 256, self.window.titlebar.size / 256)
	
	love.graphics.setFont(self.window.titlebar.font)
	
	love.graphics.setColor(self.color.icons[(self.window.focus and "" or "in") .. "active"].base.to_love)

	--Titlebar text
	love.graphics.print(self.window.titlebar.text, self.window.titlebar.size, math.floor((self.window.titlebar.size / 2) - (self.window.titlebar.font:getHeight() / 2)))

	--Minimize icon
	local sx, sy = 1, .5
	love.graphics.scale(sx, sy)
	--Note for the y on this translate; for some reason, even though it's an integer, the line gets fuzzy on a specific pixel. Adding or subtracting 1 pixel moves it into a clearer range. Prolly a love bug
	love.graphics.translate((self.window.titlebar.minimize.x + (self.window.titlebar.minimize.w * .4)) / sx, math.ceil((self.window.titlebar.minimize.y + (self.window.titlebar.minimize.h * .5)) / sy) - 1)
	
	if not self.window.focus then love.graphics.setColor(self.color.icons.inactive[self.window.titlebar.minimize.hover and "hover" or "base"].to_love) end
	
	love.graphics.line(0, 0, self.window.titlebar.exit.w * .2, 0)
	
	love.graphics.origin()
	
	--Maximize icon	
	sx, sy = .3, .3
	love.graphics.scale(sx, sy)
	
	love.graphics.translate(math.floor((self.window.titlebar.maximize.x + (self.window.titlebar.maximize.w / 2) - ((self.window.titlebar.maximize.h * sx) / 2)) / sx), math.floor(((self.window.titlebar.maximize.h / 2) - ((self.window.titlebar.maximize.h * sy) / 2)) / sy))
	
	if not self.window.focus then love.graphics.setColor(self.color.icons.inactive[self.window.titlebar.maximize.hover and "hover" or "base"].to_love) end
	
	love.graphics.rectangle("line", 0, 0, self.window.titlebar.maximize.h, self.window.titlebar.maximize.h)
	
	love.graphics.origin()
	
	--Exit icon
	sx, sy = .3, .3
	love.graphics.scale(sx, sy)
	
	love.graphics.translate(math.floor((self.window.titlebar.exit.x + (self.window.titlebar.exit.w / 2) - ((self.window.titlebar.exit.h * sx) / 2)) / sx), math.floor(((self.window.titlebar.exit.h / 2) - ((self.window.titlebar.exit.h * sy) / 2)) / sy))
	
	if not self.window.focus then love.graphics.setColor(self.color.icons.inactive[self.window.titlebar.exit.hover and "hover" or "base"].to_love) end
	
	love.graphics.line(0, 0, self.window.titlebar.maximize.h, self.window.titlebar.maximize.h)
	love.graphics.line(self.window.titlebar.maximize.h, 0, 0, self.window.titlebar.maximize.h)
	
	love.graphics.origin()
	
	--up arrow
	love.graphics.translate(self.window.width - (self.scrollbar.arrow_up.w / 2) - 3.5, self.window.titlebar.size + (self.scrollbar.arrow_up.h / 2) - 4)
	
	love.graphics.setColor(self.color.scrollbar.arrows[(self.window.focus and "" or "in") .. "active"][self.scrollbar.arrow_down.click and "click" or (self.scrollbar.arrow_down.held and "click" or "base")].to_love)

	--At some point consider using imageData for this instead of points
	love.graphics.points(4, 1, 3, 2, 4, 2, 5, 2, 2, 3, 3, 3, 4, 3, 5, 3, 6, 3, 1, 4, 2, 4, 3, 4, 5, 4, 6, 4, 7, 4, 1, 5, 2, 5, 6, 5, 7, 5, 1, 6, 7, 6)
	
	--down arrow
	love.graphics.origin()
	
	love.graphics.translate(self.window.width - (self.scrollbar.arrow_up.w / 2) - 3.5, self.window.height - (self.scrollbar.arrow_up.h / 2) - 4)
	
	love.graphics.setColor(self.color.scrollbar.arrows[(self.window.focus and "" or "in") .. "active"][self.scrollbar.arrow_up.click and "click" or (self.scrollbar.arrow_up.held and "click" or "base")].to_love)

	love.graphics.points(1, 1, 7, 1, 1, 2, 2, 2, 6, 2, 7, 2, 1, 3, 2, 3, 3, 3, 5, 3, 6, 3, 7, 3, 2, 4, 3, 4, 5, 4, 6, 4, 3, 5, 4, 5, 5, 5, 4, 6)
	
	love.graphics.origin()
		
	--output text
	local height, wrap
		
	--magic numbers here are padding
	height = 1
	wrap   = self.keyboard.wrap_width_in_chars * self.font.width
	
	if #self.keyboard.output > 0 then
		local visible_lines = {}
		
		love.graphics.setColor(self.color.font.base.to_love)
		
		love.graphics.setFont(self.font.type)
		
		for i = self.window.scroll_offset + 1, constrain(1, self.window.scroll_offset + self.window.full_line_amount - 1, #self.keyboard.output), 1 do
		
			if self.keyboard.output[i].time < self.window.last_resize then self.keyboard.output[i]:recalculateSize(self) end
			
			visible_lines[#visible_lines + 1] = self.keyboard.output[i]
			height = height + self.keyboard.output[i].height
		end

		height = self.window.titlebar.size + 1
		
		for i = 1, #visible_lines, 1 do
			visible_lines[i]:print(2, round(height), wrap)
			height = height + visible_lines[i].height
		end
	end
	
	--input text highlight
	local input_width, input_line_breaks
	
	input_line_breaks = math.floor(self.font.type:getWidth(self.keyboard.input.data) / wrap)
	ilb_in_pixels     = input_line_breaks * wrap
	
	if self.keyboard.highlight then
		local x, y, h
		
		x = 2
		y = self.window.height - self.font.height - 4
		h = self.font.height + 2
		
		love.graphics.setColor(self.color.font[self.keyboard.highlight and "base" or "inverted"].to_love)
		
		love.graphics.rectangle("fill", x, y, self.keyboard.input.current_width, h)
		
		for i = 1, input_line_breaks, 1 do
			love.graphics.rectangle("fill", x, y - (i * self.font.height), wrap, h)
		end
	end
	
	--input text		
	love.graphics.setColor(self.color.font[self.keyboard.highlight and "inverted" or "base"].to_love)
	
	love.graphics.setFont(self.font.type)
		
	love.graphics.printf(self.keyboard.input.data, 2, (self.window.height - self.font.height) - (input_line_breaks * self.font.height), wrap)
	
	--cursor
	if self.cursor.showing then
		local x, y, cursor_pixel_pos, str_len
		
		cursor_pixel_pos = self.cursor.pos * self.font.width
		str_len = self.keyboard.input.data:len() * self.font.width
		
		x = cursor_pixel_pos - ilb_in_pixels + 2
		y = self.window.height - (self.font.height / 2)
		
		if input_line_breaks > 0 and cursor_pixel_pos < ilb_in_pixels then
			local lines_moved_up = math.ceil((str_len - cursor_pixel_pos) / (wrap + self.keyboard.input.current_width))

			x = x + (lines_moved_up * wrap)
			y = y - (lines_moved_up * self.font.height)
		end

		love.graphics.setColor(self.color.font[(self.keyboard.highlight and cursor_pixel_pos < str_len) and "inverted" or "base"].to_love)
		
		love.graphics.rectangle("fill", x, y, self.font.width, self.font.height / 4)
	end
end

--Placed in the love.resize function.
function Console:resize(w, h)
	local tb_size, corner_size, border_size, button_width

	tb_size = self.window.titlebar.size
	
	--magic numbers
	button_width = tb_size * 1.4
	corner_size = 4
	border_size = 6
	
	self.window.width, self.window.height = w, h
	self.window.x, self.window.y = love.window.getPosition()

	self.window.border.visual:setDimensions(0, 0, w, h)
	self.window.border.reset:setDimensions(border_size, border_size, w - (border_size * 2), h - (border_size * 2))
	self.window.border.corner.top_left:setDimensions(0, 0, border_size, border_size)
	self.window.border.corner.top_right:setDimensions(w - border_size, 0, border_size, border_size)
	self.window.border.corner.bot_left:setDimensions(0, h - border_size, border_size, border_size)
	self.window.border.corner.bot_right:setDimensions(w - border_size, h - border_size, border_size, border_size)
	self.window.border.left:setDimensions(0, 0, corner_size, h)
	self.window.border.top:setDimensions(0, 0, w, corner_size)
	self.window.border.right:setDimensions(w - corner_size, 0, corner_size, h)
	self.window.border.bottom:setDimensions(0, h - corner_size, w, corner_size)
	self.window.titlebar.exit:setDimensions(w - button_width, 0, button_width, tb_size)
	self.window.titlebar.minimize:setDimensions(w - (button_width * 3), 0, button_width, tb_size)
	self.window.titlebar.maximize:setDimensions(w - (button_width * 2), 0, button_width, tb_size)
	self.window.titlebar.background:setDimensions(0, 0, w, titlebar_size)
	self.scrollbar.bar:setDimensions(w - scrollbar_width, self.scrollbar.bar.y, scrollbar_width, scrollbar_height)
	self.scrollbar.arrow_down:setDimensions(w - scrollbar_width, tb_size, scrollbar_width, scrollbar_height)
	self.scrollbar.arrow_up:setDimensions(w - scrollbar_width, h - scrollbar_height, scrollbar_width, scrollbar_height)
	self.scrollbar.background:setDimensions(w - scrollbar_width, tb_size, scrollbar_width, h)
	
	self.scrollbar.max = h - tb_size - (self.scrollbar.arrow_up.h * 2)
	
	self.window.full_line_amount = round((self.window.height - self.window.titlebar.size) / self.font.height)
	
	self.window.last_resize = os.clock()
	
	self.keyboard.wrap_width_in_chars = math.floor((self.window.width - self.scrollbar.background.w - self.font.width - 4) / self.font.width)
end

--Placed in the love.textinput function.
function Console:textinput(k)
	if self.keyboard.highlight then
		self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset - math.floor(self.keyboard.input.data:len() / self.keyboard.wrap_width_in_chars))
		self.keyboard.input.data = k
		self.keyboard.input.current_width = 1
		self.cursor.pos = 1
		self.timer = 0
		self.cursor.showing = true
		self.keyboard.highlight = false
	else	
		self.keyboard.input.data = self.cursor.pos == self.keyboard.input.data:len() and self.keyboard.input.data .. k or self.keyboard.input.data:sub(1, self.cursor.pos) .. k .. self.keyboard.input.data:sub(self.cursor.pos + 1, self.keyboard.input.data:len())
		self.keyboard.input.current_width = cycle(0, self.keyboard.wrap_width_in_chars, self.keyboard.input.data:len()) * self.font.width
		self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset + ((self.keyboard.input.current_width == self.keyboard.wrap_width_in_chars * self.font.width) and 1 or 0))
		self.cursor.pos = self.cursor.pos + 1
		self.cursor.timer = 0
		self.cursor.showing = true
	end
end

--Placed in the love.keypressed function.
function Console:keypressed(key, scancode)
	--Can't use return, it's a reserved keyword
	key = key == "return" and "enter" or key
	if #self.keyboard.mod == 1 then key = self.keyboard.mod[1] .. "_" .. key end
	if control[key] then control[key](self) end
end

--Placed in the love.wheelmoved function.
function Console:wheelmoved(x, y)
	self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset + (y > 0 and -scroll_amt or (y < 0 and scroll_amt or 0)))
	self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
end

--Placed in the love.mousemoved function.
function Console:mousemoved(x, y, dx, dy, istouch)
	self.mouse.loc.pos:set(x, y)
	self.mouse.loc.dt:set(dx, dy)
end

		--====++CALLBACKS++====--
	
--Callback for when text is submitted. Any value that is returned will be displayed on the console.
--If nothing is returned, no value will be displayed.
function Console:submit(input)
	return input
end

		--====++METHODS++====--

--Print plain white output to the console.
function Console:print(text)
	local multiline = Line(self, text)

	for i, line in ipairs(multiline) do
		local res = self:submit(line)
		
		if res then
			local output, res_type
			
			res_type = type(res)
			output   = res_type == "Line" and res or (res_type == "string" and Line(self, res) or Line(self, stringify(res)))

			self.keyboard.output[#self.keyboard.output + 1] = output
			self.keyboard.input.history[#self.keyboard.input.history + 1] = {data = output, cur_width = cycle(0, self.keyboard.wrap_width_in_chars, output:len()) }
			if self.keyboard.input.data == "" then
				self.window.scroll_offset = constrain(0, self.keyboard.max_output, self.window.scroll_offset + 1)
				self.scrollbar.bar.y      = round(map(0, self.keyboard.max_output, self.scrollbar.min, self.scrollbar.max, self.window.scroll_offset))
			end
		end
	end
end

--Print output to the console with a timestamp, and a color for the timestamp.
function Console:log(text, color)
end

--Clear the output of the console.
function Console:clear()
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
	
	self.window.border = Rectangle(0, 0, self.window.width, self.window.height, self.color.border, true, true, "line")
	
	self.window.titlebar.icon = love.graphics.newImage(path .. "icon.png")
	
	assert(self.window.titlebar.icon:getWidth()  <= 256, "The icon must be a maximum of 256 wide!")
	assert(self.window.titlebar.icon:getHeight() <= 256, "The icon must be a maximum of 256 tall!")
	
	--TODO: Reset clear all lines from console
	--      Clear history
end

return Console(), Color