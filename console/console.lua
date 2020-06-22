local Console, path, folder
local inspect

path   = ...
folder = string.match(path, ".*/") or ""

inspect = require(folder .. "inspect")

Console = {}

------------------------

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
	on Twitter, jumpsplat120#9317 on Discord, or jumpsplat120@yahoo.com

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.

	For more information, please refer to <http://unlicense.org/>
]]--

-----LOCAL FUNCTIONS-----

local function copy(t)
	local newTable = {}
    local ghost = {}
	
	if type(t) ~= "table" then return t end
	
	for k, v in pairs(t) do
		newTable[priv.copy(k, ghost)] = priv.copy(v, ghost)
	end
	
	ghost[t] = newTable
	
	setmetatable(newTable, priv.copy(getmetatable(t), ghost))
	
    return newTable
end

local function contains(table, element)
	for k, v in pairs(table) do if v == element then return k end end
	return false
end

local function round(n)
    return math.floor(n + .5)
end

local function isInRect(rect, mx, my)
	local p1, p2
	
	p1 = {x = rect.x, y = rect.y}
	p2 = {x = rect.x + rect.w, y = rect.y + rect.h}
	
	return ((p1.x <= mx and mx <= p2.x) and (p1.y <= my and my <= p2.y)) and true or false
end

local function constrain(min, max, input)
	return (input < min and min) or (input > max and max) or input
end

local function map(from_min, from_max, to_min, to_max, input)
	return (input - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
end

local function clickedScrollbar(self, mx, my)
	local sb = self.scrollbar.obj
	
	return isInRect({w = sb.width, h = sb.height, x = sb.x, y = sb.y}, mx, my) and love.mouse.isDown(1)
end

local function clickedScrollbarBG(self, mx, my)
	local sb = self.scrollbar.background
	
	return isInRect({w = sb.width, h = sb.height, x = sb.x, y = sb.y}, mx, my) and love.mouse.isDown(1)
end

local function updateScrollbar(self, my)
	local s, adjust_start, adjust_end, half
	
	s = self.scrollbar
	
	half         = s.obj.height / 2
	adjust_start = s.background.y + half + self.buffer
	adjust_end   = s.background.height - half - self.buffer
	
	self.scrollbar.index = math.floor(constrain(s.min, s.max, map(adjust_start, adjust_end, s.min, s.max, my)))
	self.scrollbar.obj.y = map(s.min, s.max, adjust_start, adjust_end, s.index) - half
end

local function newline(self, str, clr)
	local typeof = type(str)
	
	clr = clr or {1, 1, 1, 1}
	
	self.lines.text[#self.lines.text + 1] = {
		string = typeof == "string" and str or ((typeof == "number" or typeof == "boolean" or typeof == "nil") and tostring(str) or (typeof == "table" and inspect(str) or "ERROR")),
		color  = clr
	}
end

-----LOCAL STATIC VALUES-----

local key_actions = {
		["return"] = function(self)
			local rw = self:readwrite(self.input)
	
			text = rw[1] or self.input
			
			newline(self, text, {1,1,1,1})

			if rw[2] then
				newline(self, rw[2], {1,1,1,1})
			else
				local func, err, success
				
				func, err = loadstring(text)
				
				if err then
					newline(self, err, {1,1,0,1})
				else
					success, err = pcall(func)
					if err then newline(self, err, {1,1,0,1}) end
				end
			end
			
			self.history.lines[#self.history.lines + 1] = self.input
			
			self.history.index = #self.history.lines + 1
			self.cursor.pos    = 0
			self.input         = ""
			self.highlight     = false
		end,
		left       = function(self)
			self.cursor.pos = math.min(self.cursor.pos + 1, self.input:len())
			self.highlight = false
		end,
		right      = function(self)
			self.cursor.pos = math.max(self.cursor.pos - 1, 0)
			self.highlight = false
		end,
		up         = function(self)
			if #self.history.lines >= 1 then
				self.history.index = math.max(self.history.index - 1, 1)
				self.input         = self.history.lines[self.history.index]
			end
			self.highlight = false
		end,
		down       = function(self)
			if #self.history.lines >= 1 then 
				self.history.index = math.min(self.history.index + 1, #self.history.lines)
				self.input         = self.history.lines[self.history.index]
			end
			self.highlight = false
		end,
		backspace  = function(self)		
			if self.highlight then
				self.highlight  = false
				self.cursor.pos = 0
				self.input      = "" 
			else
				local h1, h2
				
				h1 = self.input:sub(1, -self.cursor.pos - 1)
				h2 = self.input:sub(-self.cursor.pos)
				
				self.input = self.cursor.pos > 0 and h1:sub(1, -2) .. h2 or h1:sub(1, -2)
			end
		end,
		a          = function(self)
			if love.keyboard.isDown("lctrl") then self.highlight = true end
		end,
		c          = function(self)
			if love.keyboard.isDown("lctrl") and self.highlight then
				love.system.setClipboardText(self.input)
				self.cursor.pos = 0
			end
		end,
		v          = function(self)
			if love.keyboard.isDown("lctrl") then
				local text = love.system.getClipboardText()
				
				if self.highlight then
					self.input      = text
					self.highlight  = false
					self.cursor.pos = 0
				else
					if self.cursor.pos > 0 then
						local h1, h2
						
						h1 = self.input:sub(1, -self.cursor.pos - 1)
						h2 = self.input:sub(-self.cursor.pos)
						
						self.input = h1 .. text .. h2
					else 
						self.input = self.input .. text
					end
				end
			end
		end
	}

-----CONSOLE LOVE FUNCTIONS-----

function Console:load()
	love.window.setMode(976, 480, {resizable = true, minwidth = 677, minheight = 343})

	love.graphics.setBackgroundColor({.05, .05, .05, 1})

	love.graphics.setColor({1, 1, 1, 1})

	love.keyboard.setKeyRepeat(true)
	
	Console.color = {
		background = {.05, .05, .05, 1},
		accessory  = {1, 1, 1, 1}
	}

	Console.window = {
		width  = 976,
		height = 480,
		flags  = {resizable = true, minwidth = 677, minheight = 343}
	}

	Console.cursor = {
		showing = true,
		pos     = 0,
		timer   = 0
	}

	Console.scrollbar = {
		index = 0,
		max   = 417,
		min   = 0
	}

	Console.scrollbar.background = {
		width  = 20,
		height = 480,
		y      = 0,
		x      = 956
	}
		
	Console.scrollbar.obj = {
		width  = 16,
		height = 30,
		x      = 958,
		y      = 2
	}
		
	Console.font = { 
		size = 12,
		type = love.graphics.newFont(folder .. "terminal.ttf", 12)
	}

	Console.font.height = Console.font.type:getHeight()
	Console.font.width  = Console.font.type:getWidth(" ")
	
	Console.history = {
		lines    = {},
		max      = 1000,
		index    = 1
	}
		
	Console.lines = {
		max     = 5000,
		text    = {}
	}
		
	Console.input     = ""
	Console.highlight = false
	Console.textWidth = 954
	Console.buffer    = 2
end

function Console:update(dt)
	local w, mx, my
	
	w = self.window
	
	self.cursor.showing = math.floor(self.cursor.timer) % 2 == 0 and true or false
	
	mx, my = love.mouse.getPosition()
	
	if clickedScrollbar(self, mx, my) or clickedScrollbarBG(self, mx, my) then updateScrollbar(self, my) end
	
	--[[ I dunno what this does
	--Adjust Scroll Index--
	if self.scrollbar.index <= self.scrollbar.max then
		local lines, font, height, buffer
		local wrap, inputLines, inputHeight
		
		lines  = self.lines.visible
		font   = self.font.type
		height = self.font.height
		buffer = Console.buffer
		wrap   = self.textWidth
		
		inputLines  = math.ceil(font:getWidth(self.input) / wrap)
		inputHeight = math.max(inputLines, 1) * height + buffer
		
		while lines * height > w.height - inputHeight do
			self.scrollbar.index = self.scrollbar.index + 1
			lines                = lines - 1
			self.lines.changed   = true
		end
	else
		table.remove(self.lines.text, 1)
		table.remove(self.lines.text, 1)
		self.scrollbar.index = self.scrollbar.max
	end
	--]]
	
	if #self.history.lines > self.history.max then table.remove(self.history.lines, 1) end
	
	self.cursor.timer = self.cursor.timer + dt
	
	if self.cursor.timer >= 4 then self.cursor.timer = 0 end
end

function Console:draw()
	local clrA, clrB, mode, buffer, win
	
	clrA   = self.color.accessory
	clrB   = self.color.background
	mode   = "fill"
	buffer = self.buffer
	win    = self.window
	
	love.graphics.setBackgroundColor(clrB)
	
	--Scrollbar--
	do	
		local sb, sobj
		
		sb     = self.scrollbar.background
		sobj   = self.scrollbar.obj
		
		--Background--
		love.graphics.setColor(clrA)
		love.graphics.rectangle(mode, sb.x, sb.y, sb.width, sb.height)
		
		--Obj--	
		love.graphics.setColor(clrB)
		love.graphics.rectangle(mode, sobj.x, sobj.y, sobj.width, sobj.height)
	end
	
	--Texts--
	do
		local font, wrap, x
		
		font = self.font
		wrap = self.textWidth
		x    = self.buffer
		
		--Output Text--
		do
			local visible_lines, iter, start, finish

			visible_lines = constrain(0, math.floor(win.height / font.height) - 2, #self.lines.text)
			iter          = 0
			start         = #self.lines.text - visible_lines + self.scrollbar.index + 1
			finish        = constrain(0, #self.lines.text, #self.lines.text + self.scrollbar.index)

			for i = start, finish, 1 do
				local text, y
				
				text = self.lines.text[i]
				y    = iter * font.height + buffer

				love.graphics.setColor(text.color)
				love.graphics.printf(text.string, font.type, x, y, wrap)
				iter = iter + 1
			end
		end
		
		-----Input Text-----
		do
			local y, input_line_height
			
			input_line_height = math.ceil(font.type:getWidth(self.input) / wrap) * font.height
			y                 = self.window.height - input_line_height - buffer
			
			--HIGHLIGHT--
			if self.highlight then
				love.graphics.setColor(clrA)
				love.graphics.rectangle("fill", x, y, font.type:getWidth(self.input), input_line_height)
			end
			
			--INPUT--
			do	
				if self.highlight then love.graphics.setColor(clrB) else love.graphics.setColor(clrA) end
				love.graphics.printf(self.input, font.type, x, y, wrap)
			end
		end
	end
	
	--Cursor--
	if self.cursor.showing then
		local font, wrap, x, y
		
		font = self.font
		x    = (#self.input - self.cursor.pos) * font.width
		y    = self.window.height - font.height - self.buffer
		
		if self.highlight then love.graphics.setColor(clrB) else love.graphics.setColor(clrA) end
		
		love.graphics.printf("_", font.type, x, y, self.window.width)
	end
end

function Console:resize(w, h)
	self.window.width  = w
	self.window.height = h
	
	self.scrollbar.background.width  = w / 48.8
	self.scrollbar.background.height = h
	self.scrollbar.background.x = w - (w / 48.8)
		
	self.scrollbar.obj.width  = self.scrollbar.background.width - self.buffer * 2
	self.scrollbar.obj.height = h / 16
	self.scrollbar.obj.x = self.scrollbar.background.x + self.buffer
	self.scrollbar.obj.y = self.buffer
	
	self.scrollbar.index = 0
	
	self.textWidth = self.scrollbar.background.x - self.buffer
end

function Console:textinput(k)
	if self.highlight then
		self.input     = k
		self.highlight = false
		return	
	elseif self.cursor.pos > 0 then
		local h1, h2
		
		h1 = self.input:sub(1, -self.cursor.pos - 1)
		h2 = self.input:sub(-self.cursor.pos)
		
		self.input = h1 .. k .. h2
	else 
		self.input = self.input .. k
	end
end

function Console:keypressed(key, scancode, isrepeat)	
	if key_actions[key] then key_actions[key](self) end
end

function Console:wheelmoved(x, y)	
	local s, adjust_start, adjust_end, half
	
	s            = self.scrollbar
	half         = s.obj.height / 2
	adjust_start = s.background.y + half + self.buffer
	adjust_end   = s.background.height - half - self.buffer
	
	self.scrollbar.index = y > 0 and math.max(s.index - 1, s.min) or (y < 0 and math.min(s.index + 1, s.max) or s.index)
	self.scrollbar.obj.y = map(s.min, s.max, adjust_start, adjust_end, s.index) - half
end

-----CUSTOM METHODS-----

function Console:print(str, clr)
	--No using malformed color tables
	if clr then
		if #clr == 4 then
			for i = 1, 4, 1 do
				if not (type(clr[i]) == "number" and clr[i] <= 1 and clr[1] >= 0) then 
					self:print("MALFORMED COLOR VALUE", {1, 0, 0, 1})
					clr = nil
				end
			end
		else
			self:print("MALFORMED COLOR VALUE", {1, 0, 0, 1})
			clr = nil
		end
	end
	
	newline(self, str, clr)
end

function Console:log(str, level)
	local clr, colors, time, timestamp, typeof
	
	typeof = type(str)
	time = os.date("*t")
	timestamp = "[" .. string.format("%02d", time.month) .. "-" .. string.format("%02d", time.day) .. "-" .. time.year .. " " .. string.format("%02d", time.hour) .. ":" .. string.format("%02d", time.min) .. ":" .. string.format("%02d", time.sec) .. "] "
	
	colors = {
		{0, 1, 0, 1}, --green
		{1, 1, 0, 1}, --yellow
		{1, 0, 0, 1}  --red
	}
	
	clr = colors[level] or nil
	
	newline(self, str, clr)
end

function Console:clear()
	self.lines.text = {}
	self.scrollbar.index = 0
end

function Console:setAccessoryColor(color_or_R, G, B, A)
	local typeof = type(color_or_R)
	
	self.color.accessory = typeof == "table" and color_or_R or typeof == "number" and {color_or_R, G, B, A}
end

function Console:setLineColor(color_or_R, line_or_G, B, A, line)
	local typeof = type(color_or_R)
	
	if     typeof == "table" then
		self.lines.text[line_or_G].color = color_or_R
	elseif typeof == "number" then
		self.lines.text[line].color = {color_or_R, line_or_G, B, A}
	end
end

function Console:setAllLinesColor(color_or_R, G, B, A)
	local color, typeof
	
	typeof = type(color_or_R)	
	color  = typeof == "table" and color_or_R or typeof == "number" and {color_or_R, line_or_G, B, A}
	
	for i = 1, #self.lines.text do self.lines.text[i].color = color end
end

function Console:setBackgroundColor(color_or_R, G, B, A)
	local typeof = type(color_or_R)
	
	self.color.background = typeof == "table" and color_or_R or typeof == "number" and {color_or_R, G, B, A}
end

function Console:reset()
	self:load()
end

function Console:readwrite(text)
	return {text, response}
end

-----MONKEY PATCH-----

local o_print, o_log

local function stringify(val)
	return type(val) == "table" and inspect(val) or tostring(val)
end

print = function(...)
	local args, new_table, result, clr
	
	args      = {...}
	new_table = {}
	
	for i = 1, #args, 1 do 
		if i == #args then
			--If the last argument is a table for colors, use that for color
			if type(args[i]) == "table" then
				if #args[i] == 4 then
					local color = true
					
					for j = 1, 4, 1 do if type(args[i][j]) ~= "number" then color = false end end
					
					if color then
						clr = args[i]
					else
						new_table[i] = stringify(args[i])
					end
				else
					new_table[i] = stringify(args[i])
				end
			else
				new_table[i] = stringify(args[i])
			end
		else
			new_table[i] = stringify(args[i])
		end
	end
	
	result = new_table[1]
	
	for i = 2, #new_table, 1 do result = result .. ",    " .. new_table[i] end
	
	Console:print(result, clr)
end

log = function(...)
	local args, new_table, result, clr
	
	args      = {...}
	new_table = {}
	
	for i = 1, #args, 1 do 
		if i == #args then
			--If the last argument is a number for log color, use that for color
			if type(args[i]) == "number" then
				clr = args[i]
			else
				new_table[i] = stringify(args[i])
			end
		else
			new_table[i] = stringify(args[i])
		end
	end
	
	result = new_table[1]
	
	for i = 2, #new_table, 1 do result = result .. ",    " .. new_table[i] end
	
	Console:log(result, clr)
end

return Console