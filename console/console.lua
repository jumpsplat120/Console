local console = {}
local env     = {}
local priv    = {}

local path   = ...
local folder = string.match(path, ".*/") or ""

local inspect = require(folder .. "inspect")
local socket  = require("socket")

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

-----STANDARD LOAD/UPDATE/CALLBACKS-----

function console.load()
	
	-----PRIVATE VARIABLES-----
	
	priv.cursor       = {}
	priv.pastkeys     = {}
	priv.notpressed   = {}
	priv.scroll       = {}
	priv.scroll.bg    = {}
	priv.lines        = {}
	priv.repeattimer  = 5
	priv.historyindex = 1
	priv.pausetimer   = 0
	priv.highlight    = false
	priv.mouseDown    = false
	
	-----CREATE CONSOLE DEFAULTS-----
		
	console.textColor  = {1,1,1,1}
	console.bgColor    = {.05,.05,.05,1}
	console.width      = 976
	console.height     = 480
	console.historyMax = 1000
	console.input      = ""
	console.history    = {}
	console.text       = {}
	console.flags      = {resizable = true, minwidth = 677, minheight = 343}
	
	-----SET FONT-----
	
	console.font = love.graphics.newFont(folder .. "terminal.ttf", console.fontSize)
	
	-----SET CONSOLE FONT HEIGHT-----
	
	console.fontHeight = console.font:getHeight()
	
	-----SET WINDOW SIZE-----
	
	love.window.setMode(console.width, console.height, console.flags)
	
	-----SET BG COLOR-----
	
	love.graphics.setBackgroundColor(console.bgColor)
	
	-----SET COLOR-----
	
	love.graphics.setColor(console.textColor)
	
	-----SET KEY REPEAT-----
	
	love.keyboard.setKeyRepeat(true)
	
	-----SET ENV DEFAULTS-----
	
	env.runtime           = 0
	env.width, env.height = love.window.getMode()
	env.prev              = {}
	env.keyconstants      = {["`"]      = {noshift = "`", shift = "~"},
							 ["1"]      = {noshift = "1", shift = "!"},
							 ["2"]      = {noshift = "2", shift = "@"},
							 ["3"]      = {noshift = "3", shift = "#"},
							 ["4"]      = {noshift = "4", shift = "$"},
							 ["5"]      = {noshift = "5", shift = "%"},
							 ["6"]      = {noshift = "6", shift = "^"},
							 ["7"]      = {noshift = "7", shift = "&"},
							 ["8"]      = {noshift = "8", shift = "*"},
							 ["9"]      = {noshift = "9", shift = "("},
							 ["0"]      = {noshift = "0", shift = ")"},
							 ["-"]      = {noshift = "-", shift = "_"},
							 ["="]      = {noshift = "=", shift = "+"},
							 ["q"]      = {noshift = "q", shift = "Q"},
							 ["w"]      = {noshift = "w", shift = "W"},
							 ["e"]      = {noshift = "e", shift = "E"},
							 ["r"]      = {noshift = "r", shift = "R"},
							 ["t"]      = {noshift = "t", shift = "T"},
							 ["y"]      = {noshift = "y", shift = "Y"},
							 ["u"]      = {noshift = "u", shift = "U"},
							 ["i"]      = {noshift = "i", shift = "I"},
							 ["o"]      = {noshift = "o", shift = "O"},
							 ["p"]      = {noshift = "p", shift = "P"},
							 ["["]      = {noshift = "[", shift = "{"},
							 ["]"]      = {noshift = "]", shift = "}"},
							 ["\\"]     = {noshift = "\\", shift = "|"},
							 ["a"]      = {noshift = "a", shift = "A"},
							 ["s"]      = {noshift = "s", shift = "S"},
							 ["d"]      = {noshift = "d", shift = "D"},
							 ["f"]      = {noshift = "f", shift = "F"},
							 ["g"]      = {noshift = "g", shift = "G"},
							 ["h"]      = {noshift = "h", shift = "H"},
							 ["j"]      = {noshift = "j", shift = "J"},
							 ["k"]      = {noshift = "k", shift = "K"},
							 ["l"]      = {noshift = "l", shift = "L"},
							 [";"]      = {noshift = ";", shift = ":"},
							 ["'"]      = {noshift = "'", shift = "\""},
							 ["z"]      = {noshift = "z", shift = "Z"},
							 ["x"]      = {noshift = "x", shift = "X"},
							 ["c"]      = {noshift = "c", shift = "C"},
							 ["v"]      = {noshift = "v", shift = "V"},
							 ["b"]      = {noshift = "b", shift = "B"},
							 ["n"]      = {noshift = "n", shift = "N"},
							 ["m"]      = {noshift = "m", shift = "M"},
							 [","]      = {noshift = ",", shift = "<"},
							 ["."]      = {noshift = ".", shift = ">"},
							 ["/"]      = {noshift = "/", shift = "?"},
							 ["return"] = {noshift = "return", shift = "return"},
							 ["space"]  = {noshift = " ", shift = " "},
							 ["left"]   = {noshift = "left", shift = "left"},
							 ["right"]  = {noshift = "right", shift = "right"},
							 ["up"]     = {noshift = "up", shift = "up"},
							 ["down"]   = {noshift = "down", shift = "down"}}
							 
	-----SETTING TABLE VALUES-----
							 
	env.prev.width  = 0
	env.prev.height = 0
	
	priv.scroll.index = 0
	priv.scroll.max   = 238
	priv.scroll.min   = 0
	
	priv.scroll.bg.width = 20
	
	priv.cursor.obj  = "_"
	priv.cursor.pos  = 0
	
	priv.lines.changed = false
	priv.lines.amount  = 0
end

function console.update(dt)

	----UPDATE ENV VARIABLES----
	
	env.width, env.height = love.window.getMode()
	console.width, console.height = env.width, env.height

	-----CUSTOM RESIZE CHECK-----
	
	if (env.prev.width ~= env.width) or (env.prev.height ~= env.height) then
		env.prev.width  = env.width
		env.prev.height = env.height
	end
	
	-----CTRL A CHECK-----
	
	local ctrla = priv.ctrlA()
	
	-----CUSTOM KEYISDOWN CHECK-----
	
	local keys = priv.keypressed(dt)
	
	if priv.contains(keys, "return") then
		local output, text = console.readwrite(console.input)
		text  = text or console.input
		
		if output == nil then
			console.text[#console.text + 1] = "> " .. text
			local func, err = loadstring(text)
			if err then
				console.text[#console.text + 1] = err
			else
				func()
			end
		else
			console.text[#console.text + 1] = output
		end
		console.history[#console.history + 1] = console.input
		
		priv.historyindex  = #console.history + 1
		priv.cursor.pos    = 0
		console.input      = ""
		priv.highlight     = false
		priv.lines.changed = true
	elseif priv.contains(keys, "left") then
		priv.cursor.pos = math.min(priv.cursor.pos + 1, console.input:len())
		priv.highlight  = false
	elseif priv.contains(keys, "right") then
		priv.cursor.pos = math.max(priv.cursor.pos - 1, 0)
		priv.highlight  = false
	elseif priv.contains(keys, "up") then
		if #console.history >= 1 then
			priv.historyindex = math.max(priv.historyindex - 1, 1)
			console.input     = console.history[priv.historyindex]
		end
	elseif priv.contains(keys, "down") then
		if #console.history >= 1 then 
			priv.historyindex = math.min(priv.historyindex + 1, #console.history)
			console.input     = console.history[priv.historyindex]
		end
	elseif not (keys[1] == nil) then
		for k, v in ipairs(keys) do
			if v == "space" then 
				console.input = console.input .. " "
			elseif v == "a" and ctrla then
				--DON'T WRITE THE LETTER A WHEN HIGHLIGHTING
			elseif priv.highlight then
				console.input  = v
				priv.highlight = false
			else
				if priv.cursor.pos >= 1 then
					local p1 = console.input:sub(1, -priv.cursor.pos - 1)
					local p2 = console.input:sub(-priv.cursor.pos)
					console.input = p1 .. v .. p2
				else
					console.input = console.input .. v
				end
			end
		end
		priv.highlight = false
	end
	
	-----CUSTOM BACKSPACE CHECK-----
	
	console.input = priv.backspace(dt, console.input, priv.cursor.pos, priv.highlight)
	
	-----BLINK TIMER-----
	
	if math.floor(env.runtime % 2) == 0 then priv.cursor.obj = "_" else priv.cursor.obj = "" end
	
	-----MOUSE ON SCROLLBAR CHECK-----
	
	if true then
		local mouse  = {}
		
		local mult   = env.height / 250
		local buffer = 2
		
		mouse.x, mouse.y = love.mouse.getPosition()
		
		-----SCROLLBAR BG-----
		
		if true then
			local rect = {}

			rect.w = env.width / 50
			rect.h = env.height
			
			rect.x = env.width - rect.w
			rect.y = 0
			
			if priv.isInRect(rect, mouse) and love.mouse.isDown(1) then 
				priv.scroll.index = math.min(math.max(mouse.y / 2, priv.scroll.min), priv.scroll.max) 
			end
		end
		
		-----SCROLLBAR-----
		
		if true then
			local rect  = {}
			
			rect.w = (env.width / 50) - (buffer * 2)
			rect.h = (env.height / 25) - (buffer * 2)
			
			rect.x = env.width - rect.w - buffer
			rect.y = (priv.scroll.index * mult) + buffer
			
			if priv.isInRect(rect, mouse) and love.mouse.isDown(1) then priv.mouseDown = true end
			if not love.mouse.isDown(1) then priv.mouseDown = false end
			if priv.mouseDown then priv.scroll.index = math.min(math.max(mouse.y / 2, priv.scroll.min), priv.scroll.max) end
		end
	end
	
	-----CALCULATE VISIBLE LINES-----
	
	if priv.lines.changed then
		local lines = 0
		local font  = console.font
		
		for i = 1, #console.text do
			local text = console.text[i]
			local wrap = env.width - priv.scroll.bg.width
			
			lines = lines + math.ceil(font:getWidth(text) / wrap)
		end
		
		lines = lines - math.ceil(priv.scroll.index)
		
		priv.lines.amount  = lines
		priv.lines.changed = false
	end
	
	-----ADJUST SCROLLINDEX BASED ON LINES-----
	
	if priv.scroll.index <= priv.scroll.max then
		local lines  = priv.lines.amount
		local font   = console.font
		local height = font:getHeight()
		local buffer = 2
		
		local wrap   = env.width - priv.scroll.bg.width - buffer
		
		local inputLines = math.ceil(font:getWidth(console.input) / wrap)
		
		local inputHeight = math.max(inputLines, 1) * height + buffer
		
		while lines * height > env.height - inputHeight do
			priv.scroll.index = priv.scroll.index + 1
			lines = lines - 1
			priv.lines.changed = true
		end
	else
		table.remove(console.text, 1)
		table.remove(console.text, 1)
		priv.scroll.index = priv.scroll.max
	end
	
	-----REMOVE ITEMS FROM HISTORY OVER 1000----
	
	if #console.history > 1000 then table.remove(console.history, 1) end
	
	env.runtime = env.runtime + dt
end

function console.draw()
	
	-----COMMONLY USED VALUES----
	
	local colorA = console.textColor
	local colorB = console.bgColor
	local mode   = "fill"
	local buffer = 2
	
	-----SET BACKGROUND COLOR-----
	
	love.graphics.setBackgroundColor(colorB)
	
	-----DRAW SCROLLBAR-----
	
	if true then
		
		-----DRAW BACKGROUND OF BAR-----
		
		if true then
			local h = env.height
			local w = priv.scroll.bg.width
			
			local x = env.width - w
			local y = 0
			
			love.graphics.setColor(colorA)
			love.graphics.rectangle(mode, x, y, w, h)
		end
		
		-----DRAW SCROLLBAR----
		
		if true then
			local w    = priv.scroll.bg.width - (buffer * 2)
			local h    = env.height / 25
			local mult = env.height / 250
			
			local x = env.width - w - buffer
			local y = (priv.scroll.index * mult) + buffer
			
			love.graphics.setColor(colorB)
			love.graphics.rectangle(mode, x, y, w, h)
		end
	end
	
	-----PRINT OUTPUT TEXT-----
	
	if true then
		local lines = 0
		local font  = console.font
		local wrap  = env.width - priv.scroll.bg.width - buffer
		local x     = 0 + buffer
		
		for i = 1, #console.text do
			local text = console.text[i]
			local y    = (lines * font:getHeight()) - (priv.scroll.index * font:getHeight()) + buffer
			
			lines = lines + math.ceil(font:getWidth(text) / wrap)
			
			love.graphics.setColor(colorA)
			love.graphics.printf(text, font, x, y, wrap)
		end
	end
	
	-----DRAW HIGHLIGHT RECTANGLE BOX-----
	
	if priv.highlight then
		local font = console.font
		local text = console.input
		local wrap = env.width - priv.scroll.bg.width - buffer
		
		local lines = math.ceil(font:getWidth(text) / wrap)
		
		local w = font:getWidth(text)
		local h = font:getHeight() * lines
		
		local x = 0 + buffer
		local y = env.height - h - buffer
	
		love.graphics.setColor(colorA)
		love.graphics.rectangle(mode, x, y, w, h)
	end
	
	-----DRAW CONSOLE INPUT TEXT-----
	
	if true then	
		local text = console.input
		local font = console.font
		local wrap = env.width - priv.scroll.bg.width - buffer
		
		local lines = math.ceil(font:getWidth(text) / wrap)
		
		local x = 0 + buffer
		local y = env.height - math.max(lines * font:getHeight(), font:getHeight()) - buffer
		
		-----BOX BEHIND TEXT-----
		
		if true then
			local mode = "fill"
			local w    = wrap
			local h    = math.max(lines * font:getHeight() + buffer, font:getHeight() + buffer)
			
			if priv.highlight then love.graphics.setColor(colorA) else love.graphics.setColor(colorB) end
			love.graphics.rectangle(mode, x, y, w, h)
		end
		
		-----DRAW TEXT-----
		
		if true then	
			if priv.highlight then love.graphics.setColor(colorB) else love.graphics.setColor(colorA) end
			
			love.graphics.printf(text, font, x, y, wrap)
		end
	end
	
	-----DRAW BLINKING CURSOR-----
	
	if true then
		local text   = priv.cursor.obj
		local input  = console.input
		local font   = console.font
		local wrap   = env.width
		
		local width = font:getWidth(input) - (priv.cursor.pos * font:getWidth(" "))

		local lines = math.floor(width / wrap)
		
		local x = (width + buffer) - (lines * (wrap - font:getWidth(text)))
		local y = env.height - console.fontHeight - buffer
		
		if priv.highlight then love.graphics.setColor(colorB) else love.graphics.setColor(colorA) end
		
		love.graphics.printf(text, font, x, y, wrap)
	end
end

function console.wheelmoved(x, y)
	local up   = y > 0
	local down = y < 0
	
	if     up   then
		priv.scroll.index = math.max(priv.scroll.index - 1, priv.scroll.min)
	elseif down then
		priv.scroll.index = math.min(priv.scroll.index + 1, priv.scroll.max)
	end
end

-----CUSTOM CALLBACKS-----

function console.print(str)
	local type = type(str)
	
	if     type == "string" then
		console.text[#console.text + 1] = str
	elseif type == "number" or type == "boolean" or type == "nil" then
		console.text[#console.text + 1] = tostring(str)
	elseif type == "table" then
		console.text[#console.text + 1] = inspect(str)
	end
end

function console.clear()
	console.text = {}
end

function console.setTextColor(color_or_R, G, B, A)
	local type = type(color_or_R)
	
	if     type == "table" then
		console.textColor = color_or_R
	elseif type == "number" then
		console.textColor = {color_or_R, G, B, A}
	end
end

function console.setBackgroundColor(color_or_R, G, B, A)
	local type = type(color_or_R)
	
	if     type == "table" then
		console.bgColor = color_or_R
	elseif type == "number" then
		console.bgColor = {color_or_R, G, B, A}
	end
end

function console.reset()
	console.load()
end

function console.readwrite(text)
	return text
end

-----TABLE COPY FUNCTION-----

function priv.copy(t)
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

-----KEY CHECKING FUNCTION-----

function priv.keypressed(dt)
	local keys = {}
	
	local leftshift   = love.keyboard.isDown("lshift")
	local rightshift  = love.keyboard.isDown("rshift")
	
	for constant, key in pairs(env.keyconstants) do
		local keyispressed  = love.keyboard.isDown(constant)
		local keywaspressed = priv.contains(priv.pastkeys, constant)
		local keynotpressed = priv.contains(priv.notpressed, constant)
		
		if keyispressed and not keywaspressed then
			if leftshift or rightshift then keys[#keys + 1] = key.shift else keys[#keys + 1] = key.noshift end
			priv.pastkeys[#priv.pastkeys + 1] = constant
			table.remove(priv.notpressed, priv.contains(priv.notpressed, constant))
		elseif keyispressed and keywaspressed then
			if priv.pausetimer > 1 then
				if leftshift or rightshift then keys[#keys + 1] = key.shift else keys[#keys + 1] = key.noshift end
				goto continue
			end
			priv.pausetimer = priv.pausetimer + dt
		elseif not keyispressed and not keynotpressed then
			priv.notpressed[#priv.notpressed + 1] = constant
			priv.pausetimer = 0
		elseif keynotpressed and keywaspressed then	
			table.remove(priv.pastkeys, priv.contains(priv.pastkeys, constant))
		end
		::continue::
	end
	
	return keys
end

-----CUSTOM BACKSPACE FUNCTION-----

function priv.backspace(dt, text, pos, highlight)
	if love.keyboard.isDown("backspace") then
		if highlight then
			priv.highlight = false
			return "" 
		end
		
		if priv.backspacetimer > .75 then
			priv.repeattimer = priv.repeattimer + 1
			if priv.repeattimer % 2 == 0 then
				if pos >= 1 then
					local p1 = text:sub(1, -pos - 1)
					local p2 = text:sub(-pos)
					
					return p1:sub(1, -2) .. p2
				else
					return text:sub(1, -2) 
				end
			end
		elseif priv.backspacetimer == 0 then
			priv.backspacetimer = priv.backspacetimer + dt
			if pos >= 1 then
				local p1 = text:sub(1, -pos - 1)
				local p2 = text:sub(-pos)
				
				return p1:sub(1, -2) .. p2
			else
				return text:sub(1, -2) 
			end
		else
			priv.backspacetimer = priv.backspacetimer + dt
		end
	else
		priv.backspacetimer = 0
	end
	
	return text
end

-----CTRL A FUNCTION-----

function priv.ctrlA()
	local lctrl = love.keyboard.isDown("lctrl")
	local a     = love.keyboard.isDown("a")
	
	if lctrl and a then 
		priv.highlight = true
		return true
	else
		return false
	end
end

-----TABLE CONTAINS ITEM FUNCTION-----

function priv.contains(table, element)
	for k, v in pairs(table) do
		if v == element then return k end
	end
	return false
end

-----ROUNDING FUNCTION-----

function priv.round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

-----MOUSE IN RECTANGLE FUNCTION-----

function priv.isInRect(rect, mouse)
	local p1 = {}
	local p2 = {}
	
	p1.x = rect.x
	p1.y = rect.y
	p2.x = rect.x + rect.w
	p2.y = rect.y + rect.h
	
	local xinbounds = p1.x <= mouse.x and mouse.x <= p2.x
	local yinbounds = p1.y <= mouse.y and mouse.y <= p2.y
	
	if xinbounds and yinbounds then return true else return false end
end

return console