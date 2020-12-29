local path, classic, inspect, Object, Color, Point, Rectangle, Console

path = string.match(..., ".*/") or ""

inspect  = require(path .. "third_party/inspect")
Object   = require(path .. "third_party/classic")
Mouse    = require(path .. "bin/global_mouse")

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

local def_width, def_height, def_min_width, def_min_width, def_font_size, def_font_color, dark_theme_active, file, def_theme, titlebar_size, scrollbar_width, scrollbar_height

def_width  = 976
def_height = 480
def_min_width = 677
def_min_width = 343
def_font_size = 12

file = io.popen("reg query HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v AppsUseLightTheme")

dark_theme_active = tonumber(file:read("*a"):match("%dx(%d)")) == 0

-- Did you know that you HAVE to use double quotes or this command fails?
file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v CaptionHeight')

titlebar_size = tonumber(file:read("*a"):match("-*%d+")) / -11

file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v ScrollWidth')

scrollbar_width = tonumber(file:read("*a"):match("-*%d+")) / -15

file = io.popen('reg query "HKCU\\Control Panel\\Desktop\\WindowMetrics" /v ScrollHeight')

scrollbar_height = tonumber(file:read("*a"):match("-*%d+")) / -15

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

-----CALLBACKS-----

local borderLeft, borderRight, borderTop, borderBot, borderTLeft, borderTRight, borderBLeft, borderBRight, scrollbarBG, scrollbarBar, scrollbarClickUp, scrollbarClickDown, scrollbarHoldUp, scrollbarHoldDown, titlebar, exitButton, maxButton, minButton

function borderHover(self, dt, mouse, args)
	print("Hovering over the border...")
	return true
end

function borderLeft(self, dt, mouse, args)
	print("Holding left border...")
	return true
end

function borderRight(self, dt, mouse, args)
	print("Holding right border...")
	return true
end

function borderTop(self, dt, mouse, args)
	print("Holding top border...")
	return true
end

function borderBot(self, dt, mouse, args)
	print("Holding bottom border...")
	return true
end

function borderTLeft(self, dt, mouse, args)
	print("Holding top-left corner...")
	return true
end

function borderTRight(self, dt, mouse, args)
	print("Holding top-right corner...")
	return true
end

function borderBLeft(self, dt, mouse, args)
	print("Holding bottom-left corner...")
	return true
end

function borderBRight(self, dt, mouse, args)
	print("Holding bottom-right corner...")
	return true
end

function scrollbarBG(self, dt, mouse, args)
	print("Holding scrollbar background...")
	return true
end

function scrollbarBar(self, dt, mouse, args)
	print("Holding scrollbar bar...")
	return true
end

function scrollbarClickUp(self, dt, mouse, args)
	print("Clicked scrollbar up arrow.")
	return true
end

function scrollbarClickDown(self, dt, mouse, args)
	print("Clicked scrollbar down arrow.")
	return true
end

function scrollbarHoldUp(self, dt, mouse, args)
	print("Holding scrollbar up arrow...")
	return true
end

function scrollbarHoldDown(self, dt, mouse, args)
	print("Holding scrollbar down arrow...")
	return true
end

function titlebarHold(self, dt, mouse, args)
	self.offset = self.offset == nil and mouse.loc.pos:clone() or self.offset
	love.window.setPosition(mouse.global.pos.x - self.offset.x, mouse.global.pos.y - self.offset.y, args[1])
	if not love.mouse.isDown(1) then
		self.offset = nil
		return nil
	else
		return "titlebarHold"
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

-----OTHER FUNCTIONS----- 

-----CLASSES-----

Console = Object:extend()

	--=========COLOR=========--

Color = require(path .. "bin/Color")

def_background = Color(12, 12, 12, 1)

def_font_color = Color(204, 204, 204, 1)

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

	--========CONSOLE========--
	
--Called once on load. Used for non-love based loading.
function Console:new()
	local theme = def_theme[dark_theme_active and "dark" or "light"]

	self.color = {
		font       = def_font_color,
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
		height  = def_height,
		focus   = true,
		display = 1,
		titlebar = {
			size       = titlebar_size,
			background = Rectangle(true, true, titlebarHold, {false, false, "titlebarHold"}, 0, 0, def_width, titlebar_size, self.color.titlebar.active.base, true, true),
			exit       = Rectangle(exitButton, true, true, {false, false, false}, def_width - (titlebar_size * 1.4), 0, titlebar_size * 1.4, titlebar_size, self.color.exit.active.base, self.color.exit.active.hover, self.color.exit.active.click),
			maximize   = Rectangle(maxButton, true, true, {false, false, false}, def_width - ((titlebar_size * 1.4) * 2), 0, titlebar_size * 1.4, titlebar_size, self.color.other.active.base, self.color.other.active.hover, self.color.other.active.click),
			minimize   = Rectangle(minButton, true, true, {false, false, false}, def_width - ((titlebar_size * 1.4) * 3), 0, titlebar_size * 1.4, titlebar_size, self.color.other.active.base, self.color.other.active.hover, self.color.other.active.click)
		},
		flags  = { borderless = true, minwidth = def_min_width, minheight = def_min_height }
	}
	
	self.cursor = {
		showing = {
			timer = 0,
			is    = true
		},
		pos = 1
	}
	
	self.window.border = {
		visual = Rectangle(true, true, true, {false, false, false}, 0, 0, self.window.width, self.window.height + self.window.titlebar.size, self.color.border.active.base, self.color.border.active.hover, self.color.border.active.click, "line"), 
		left   = Rectangle(true, borderHover, borderLeft, {false, false, false}, 0, 0, 4, self.window.height + self.window.titlebar.size, true, true, true, nil, false),
		right  = Rectangle(true, borderHover, borderRight, {false, false, false}, self.window.width - 4, 0, 4, self.window.height + self.window.titlebar.size, true, true, true, nil, false),
		bottom = Rectangle(true, borderHover, borderBot, {false, false, false}, 0, self.window.height + self.window.titlebar.size - 4, self.window.width, 4, true, true, true, nil, false),
		top    = Rectangle(true, borderHover, borderTop, {false, false, false}, 0, 0, self.window.width, 4, true, true, true, nil, false),
		corner = {
			top_left  = Rectangle(true, borderHover, borderTLeft, {false, false, false}, 0, 0, 6, 6, true, true, true, nil, false),
			top_right = Rectangle(true, borderHover, borderTRight, {false, false, false}, self.window.width - 6, 0, 6, 6, true, true, true, nil, false),
			bot_left  = Rectangle(true, borderHover, borderBLeft, {false, false, false}, 0, self.window.height + self.window.titlebar.size - 6, 6, 6, true, true, true, nil, false),
			bot_right = Rectangle(true, borderHover, borderBRight, {false, false, false}, self.window.width - 6, self.window.height + self.window.titlebar.size - 6, 6, 6, true, true, true, nil, false)
		}
	}
	
	self.scrollbar = {
		background = Rectangle(true, true, scrollbarBG, {false, false, false}, self.window.width - scrollbar_width, self.window.titlebar.size, scrollbar_width, self.window.height, self.color.scrollbar.background.active.base, self.color.scrollbar.background.active.hover, self.color.scrollbar.background.active.click),
		bar        = Rectangle(true, true, scrollbarBar, {false, false, false}, self.window.width - scrollbar_width, self.window.titlebar.size + scrollbar_height, scrollbar_width, scrollbar_height, self.color.scrollbar.bar.active.base, self.color.scrollbar.bar.active.hover, self.color.scrollbar.bar.active.click),
		arrow_up   = Rectangle(scrollbarClickUp, true, scrollbarHoldUp, {false, false, false}, self.window.width - scrollbar_width, self.window.height + self.window.titlebar.background.h - scrollbar_height, scrollbar_width, scrollbar_height, self.color.scrollbar.arrows_bg.active.base, self.color.scrollbar.arrows_bg.active.hover, self.color.scrollbar.arrows_bg.active.click),
		arrow_down = Rectangle(scrollbarClickDown, true, scrollbarHoldDown, {false, false, false}, self.window.width - scrollbar_width, self.window.titlebar.background.h, scrollbar_width, scrollbar_height, self.color.scrollbar.arrows_bg.active.base, self.color.scrollbar.arrows_bg.active.hover, self.color.scrollbar.arrows_bg.active.click)
	}
	
	self.font = {
		size = def_font_size
	}
	
	self.input_history = {
		data = {}
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
	
	self.running_callback = nil
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
	
	love.window.setMode(self.window.width, self.window.height + self.window.titlebar.size, self.window.flags)

	love.graphics.setBackgroundColor(self.color.background.to_love)

	love.keyboard.setKeyRepeat(true)
		
	self.font.type   = love.graphics.newFont(path .. "assets/terminal.ttf", self.font.size)
	self.font.height = self.font.type:getHeight()
	self.font.width  = self.font.type:getWidth(" ")
	
	self.window.titlebar.icon = love.graphics.newImage(path .. "assets/icon.png")
	
	assert(self.window.titlebar.icon:getWidth()  <= 256, "The icon must be a maximum of 256 wide!")
	assert(self.window.titlebar.icon:getHeight() <= 256, "The icon must be a maximum of 256 tall!")

	self.type = ctype
end

--Placed in the love.update function.
function Console:update(dt)
	local focus, result, x, y
	
	focus  = love.window.hasFocus()

	self.mouse.held = self.mouse.down
	self.mouse.down = love.mouse.isDown(1)
	
	result = self.window.border.corner.top_left:update(dt, self.mouse, self.running_callback)
	result = self.window.border.corner.top_right:update(dt, self.mouse, result)
	result = self.window.border.corner.bot_left:update(dt, self.mouse, result)
	result = self.window.border.corner.bot_right:update(dt, self.mouse, result)
	result = self.window.border.left:update(dt, self.mouse, result)
	result = self.window.border.top:update(dt, self.mouse, result)
	result = self.window.border.right:update(dt, self.mouse, result)
	result = self.window.border.bottom:update(dt, self.mouse, result)
	result = self.window.titlebar.exit:update(dt, self.mouse, result)
	result = self.window.titlebar.minimize:update(dt, self.mouse, result)
	result = self.window.titlebar.maximize:update(dt, self.mouse, result)
	result = self.window.titlebar.background:update(dt, self.mouse, result, self.window.display)
	result = self.scrollbar.bar:update(dt, self.mouse, result)
	result = self.scrollbar.arrow_down:update(dt, self.mouse, result)
	result = self.scrollbar.arrow_up:update(dt, self.mouse, result)
	self.running_callback = self.scrollbar.background:update(dt, self.mouse, result)
	
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
	
	x, y, self.window.display = Mouse.getGlobalMousePosition()
	self.mouse.global.dt:set(x - self.mouse.global.pos.x, y - self.mouse.global.pos.y)
	self.mouse.global.pos:set(x, y)
	self.mouse.loc.dt:set(0, 0)
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

--Placed in the love.mousemoved function.
function Console:mousemoved(x, y, dx, dy, istouch)
	self.mouse.loc.pos:set(x, y)
	self.mouse.loc.dt:set(dx, dy)
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

--Set the accessory color of the console (The background of the scrollbar, the color of the cursor, and the text highlighter color.)
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
	
	self.window.border = Rectangle(0, 0, self.window.width, self.window.height + self.window.titlebar.height, self.color.border, true, true, "line")
	
	self.window.titlebar.icon = love.graphics.newImage(path .. "icon.png")
	
	assert(self.window.titlebar.icon:getWidth()  <= 256, "The icon must be a maximum of 256 wide!")
	assert(self.window.titlebar.icon:getHeight() <= 256, "The icon must be a maximum of 256 tall!")
	
	--TODO: Reset clear all lines from console
	--      Clear history
end

return Console(), Color