local Console, path, folder
local inspect, Object

path   = ...
folder = string.match(path, ".*/") or ""

inspect = require(folder .. "inspect")
Object  = require(folder .. "classic")

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

Console = Object:extend()

Console.buffer = 2
Console.mode   = "fill"

function Console:new(w, h, f, accClr, bgClr, fntSize, maxLines)
	self.color = {
		accessory  = accClr or {1,1,1,1},
		background = bgClr  or {.05,.05,.05,1}
	}
	
	self.window = {
		width  = w or 976,
		height = h or 480,
		flags  = f or {resizable = true, minwidth = 677, minheight = 343}
	}
	
	self.cursor = {
		char  = "_",
		pos  = 0
	}
	
	self.scrollbar = {
		index = 0,
		max   = 250,
		min   = 0,
		background = {
			width  = self.window.width / 50,
			height = self.window.height,
			y      = 0
		}
	}
	
	self.scrollbar.background.x = self.window.width - self.scrollbar.background.width
	self.scrollbar.obj = {
		width  = self.scrollbar.background.width - Console.buffer * 2,
		height = self.window.height / 25
	}
	self.scrollbar.obj.x = self.window.width - self.scrollbar.obj.width - Console.buffer
	self.scrollbar.obj.y = self.scrollbar.index * (self.window.height / self.scrollbar.max) + Console.buffer
	
	self.font        = { size = fntSize or 12 }
	self.font.type   = love.graphics.newFont(folder .. "terminal.ttf", self.font.size)
	self.font.height = self.font.type:getHeight()
	
	self.mouse   = {
		down = false,
		x = 0,
		y = 0
	}
	
	self.history = {
		lines    = {},
		max      = 1000,
		index    = 1
	}
	
	self.lines   = {
		changed = false,
		visible = 0,
		max     = maxLines or 5000,
		text    = {}
	}
	
	self.input     = ""
	self.runtime   = 0
	self.highlight = false
	self.textWidth = self.window.width - self.scrollbar.background.width - Console.buffer
	
	love.window.setMode(self.window.width, self.window.height, self.window.flags)
	
	love.graphics.setBackgroundColor(self.color.background)
	
	love.graphics.setColor(self.color.accessory)
	
	love.keyboard.setKeyRepeat(true)
end

function Console:update(dt)
	local w, m

	self.window.width, self.window.height, self.window.flags = love.window.getMode()
	
	self.mouse.x, self.mouse.y = love.mouse.getPosition()
	self.mouse.down            = love.mouse.isDown(1)
	
	w = self.window
	m = self.mouse
	
	--Blinking Cursor--
	
	self.cursor.char = math.floor(self.runtime) % 2 == 0 and "_" or ""
	
	--Scrollbar--
	
	do
		local scroll, sb
		
		scroll = self.scrollbar
		sb     = scroll.background
			
		if isInRect({w = sb.width, h = sb.height, x = sb.x, y = sb.y}, m) and m.down then 
			self.scrollbar.index = constrain(scroll.min, scroll.max, m.y / 2)
		end
	end

	--Calc Visible Lines--
	if self.lines.changed then
		local lines, font
		
		lines = 0
		font  = self.font.type
		
		for i = 1, #self.lines.text do
			local text, wrap
			
			text = self.lines.text[i].string
			wrap = w.width - self.scrollbar.background.width
			
			lines = lines + math.ceil(font:getWidth(text) / wrap)
		end
		
		lines = lines - math.ceil(self.scrollbar.index)
		
		self.lines.visible = lines
		self.lines.changed = false
	end
	
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
	
	if #self.history.lines > self.history.max then table.remove(self.history.lines, 1) end
	
	self.runtime = self.runtime + dt
end

function Console:draw()
	local clrA, clrB, mode, buffer
	local w
	
	clrA   = self.color.accessory
	clrB   = self.color.background
	mode   = Console.mode
	buffer = Console.buffer
	
	w = self.window
	
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
		local font, wrap, x, buffer
		
		font   = self.font
		wrap   = self.textWidth
		x      = Console.buffer
		buffer = Console.buffer
		
		--Output Text--
		do
			local lines = 0
			
			for i = 1, #self.lines.text do
				local text, line, color, y
				
				text   = self.lines.text[i]
				string = text.string
				color  = text.color
				y      = (lines * font.height) - (self.scrollbar.index * font.height) + buffer
				
				love.graphics.setColor(color)
				love.graphics.printf(string, font.type, x, y, wrap)
				
				lines = lines + math.ceil(font.type:getWidth(string) / wrap)
			end
		end
		
		-----Input Text-----
		do
			local lines, y, text, _
			
			lines = math.ceil(font.type:getWidth(self.input) / wrap)
			text  = self.input
			y     = self.window.height - font.height
			
			--Text Box--	
			love.graphics.setColor(clrB)
			love.graphics.rectangle(Console.mode, 0, y, wrap, lines == 0 and font.height + buffer or lines * font.height + buffer)
			
			--Highlight Box--
			if self.highlight then
				local lines, y
				
				lines = math.ceil(font.type:getWidth(self.input) / wrap)
				y     = self.window.height - buffer - font.height * lines 

				love.graphics.setColor(clrA)
				love.graphics.rectangle(Console.mode, x, y, font.type:getWidth(self.input), font.height * lines)
			end
			
			--Text--
			do
				local y = lines == 0 and font.height or self.window.height - lines * font.height - buffer
				
				if self.highlight then love.graphics.setColor(clrB) else love.graphics.setColor(clrA) end
				love.graphics.printf(text, font.type, x, y, wrap)
			end
		end
	end
	
	--Cursor--
	do
		local cursor, font, wrap, buffer
		local width, lines, x, y, _
		
		cursor = self.cursor
		font   = self.font
		wrap   = self.window.width
		buffer = Console.buffer

		width = font.type:getWidth(self.input) - (cursor.pos * font.type:getWidth(" "))	
		lines = math.floor(width / wrap)
		x     = (width + buffer) - (lines * (wrap - font.type:getWidth(cursor.char)))
		y     = self.window.height - font.height - buffer
		
		_ = self.highlight and love.graphics.setColor(clrB) or love.graphics.setColor(clrA)
		love.graphics.printf(cursor.char, font.type, x, y, wrap)
	end
end

function Console:textinput(k)
	if self.highlight then
		self.input     = k
		self.highlight = false
		return
	end
	
	if self.cursor.pos > 0 then
		local h1, h2
		
		h1 = self.input:sub(1, -self.cursor.pos - 1)
		h2 = self.input:sub(-self.cursor.pos)
		
		self.input = h1 .. k .. h2
	else 
		self.input = self.input .. k
	end
end

function Console:keypressed(key, scancode, isrepeat)
	local actions, k
	
	actions = {
		["return"] = function()
			local text, response = self:readwrite(self.input)
			
			local function newline(self, str, clr)
				self.lines.text[#self.lines.text + 1] = {
					string = str or "",
					color  = clr or {1,1,1,1}
				}
			end
	
			text = text or self.input
			
			newline( self, text, {1,1,1,1})

			if not response then
				local func, err, success
				
				func, err = loadstring(text)
				
				if err then
					newline(self, err, {1,1,0,1})
				else
					success, err = pcall(function() func() end)
					if err then newline(self, err, {1,1,0,1}) end
				end
			else
				newline(self, response, {1,1,1,1})
			end
			
			self.history.lines[#self.history.lines + 1] = self.input
			
			self.history.index = #self.history.lines + 1
			self.cursor.pos    = 0
			self.input         = ""
			self.lines.changed = true
			self.highlight     = false
			
			return ""
		end,
		left       = function()
			self.cursor.pos = math.min(self.cursor.pos + 1, self.input:len())
			self.highlight = false
			
			return ""
		end,
		right      = function()
			self.cursor.pos = math.max(self.cursor.pos - 1, 0)
			self.highlight = false
			
			return ""
		end,
		up         = function()
			if #self.history.lines >= 1 then
				self.history.index = math.max(self.history.index - 1, 1)
				self.input         = self.history.lines[self.history.index]
			end
			self.highlight = false
			
			return ""
		end,
		down       = function()
			if #self.history.lines >= 1 then 
				self.history.index = math.min(self.history.index + 1, #self.history.lines)
				self.input         = self.history.lines[self.history.index]
			end
			self.highlight = false
			
			return ""
		end,
		backspace  = function()		
			if self.highlight then
				self.highlight  = false
				self.cursor.pos = 0
				self.input      = "" 
			end
			
			do
				local h1, h2
				
				h1 = self.input:sub(1, -self.cursor.pos - 1)
				h2 = self.input:sub(-self.cursor.pos)
				
				self.input = self.cursor.pos > 0 and h1:sub(1, -2) .. h2 or h1:sub(1, -2)
			end
			
			return ""
		end,
		a          = function()
			if love.keyboard.isDown("lctrl") or love.keyboard.isDown("lctrl") then
				self.highlight = true
			end
		end,
		c          = function()
			if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
				love.system.setClipboardText(self.input)
				self.cursor.pos = 0
			end
		end,
		v          = function()
			if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
				local text = love.system.getClipboardText()
				
				if self.highlight then
					self.input      = love.system.getClipboardText()
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
	
	if not actions[key] then return else actions[key]() end
end

function Console:wheelmoved(x, y)
	local sb = self.scrollbar
	
	sb.index = y > 0 and math.max(sb.index - 1, sb.min) or y < 0 and math.min(sb.index + 1, sb.max) or sb.index
	
	self.scrollbar = sb
end

-----CUSTOM CALLBACKS-----
function Console:print(str, clr)
	str = str or ""
	clr = clr or {1,1,1,1}
	
	local type = type(str)
	
	self.lines.text[#self.lines.text + 1] = {
		string = type == "string" and str or (type == "number" or (type == "boolean" or type == "nil")) and tostring(str) or type == "table" and inspect(str) or "ERROR",
		color  = clr
	}
	
	self.lines.changed = true
end

function Console:log(str, level)
	local clr, colors, time, timestamp, type
	
	type = type(str)
	time = os.date("*t")
	timestamp = "[" .. string.format("%02d", time.month) .. "-" .. string.format("%02d", time.day) .. "-" .. time.year .. " " .. string.format("%02d", time.hour) .. ":" .. string.format("%02d", time.min) .. ":" .. string.format("%02d", time.sec) .. "] "
	
	colors = {
		{0,1,0,1}, --green
		{1,1,0,1}, --yellow
		{1,0,0,1}  --red
	}
	
	clr = colors[level] or {1,1,1,1}
	
	self.lines.text[#self.lines.text + 1] = {
		string = type == "string" and str or (type == "number" or (type == "boolean" or type == "nil")) and tostring(str) or type == "table" and inspect(str) or "ERROR",
		color  = clr
	}
	
	self.lines.changed = true
end

function Console:clear()
	self.lines.text = {}
end

function Console:setAccessoryColor(color_or_R, G, B, A)
	local type = type(color_or_R)
	
	self.color.accessory = type == "table" and color_or_R or type == "number" and {color_or_R, G, B, A}
end

function Console:setLineColor(color_or_R, line_or_G, B, A, line)
	local type = type(color_or_R)
	
	if     type == "table" then
		self.lines.text[line_or_G].color = color_or_R
	elseif type == "number" then
		self.lines.text[line].color = {color_or_R, line_or_G, B, A}
	end
end

function Console:setAllLinesColor(color_or_R, G, B, A)
	local color, type
	
	type  = type(color_or_R)	
	color = type == "table" and color_or_R or type == "number" and {color_or_R, line_or_G, B, A}
	
	for i = 1, #self.lines.text do
		self.lines.text[i].color = color
	end
end

function Console:setBackgroundColor(color_or_R, G, B, A)
	local type = type(color_or_R)
	
	self.color.background = type == "table" and color_or_R or type == "number" and {color_or_R, G, B, A}
end

function Console:reset()
	Console:load()
end

function Console:readwrite(text)
	return text
end

-----TABLE COPY FUNCTION-----

function copy(t)
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

-----TABLE CONTAINS ITEM FUNCTION-----

function contains(table, element)
	for k, v in pairs(table) do if v == element then return k end end
	return false
end

-----ROUNDING FUNCTION-----

function round(n)
    return math.floor(n + .5)
end

-----MOUSE IN RECTANGLE FUNCTION-----

function isInRect(rect, mouse)
	local p1, p2
	
	p1 = {x = rect.x, y = rect.y}
	p2 = {x = rect.x + rect.w, y = rect.y + rect.h}
	
	return ((p1.x <= mouse.x and mouse.x <= p2.x) and (p1.y <= mouse.y and mouse.y <= p2.y)) and true or false
end

-----CONSTRAIN NUMBER FUNCTION-----
function constrain(min, max, input)
	return (input < min and min) or (input > max and max) or input
end

return Console