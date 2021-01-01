-- desktop coordinate related functions
-- by zorg @ 2015-2016
-- license: ISC

-- This library implements a somewhat robust method of allowing the usage of desktop mouse coordinates in Löve.
-- Main usage would be the implementation of borderless dragging (in windows at least, where it's not possible otherwise)
-- This may not yet be perfect, since window dimensions and position and the inner canvas/frame/viewport dimensions and positioning
-- may be offset differently by different OS-es, so testing needed still. Also doesn't have that much use on android or ios.

-- Use LuaJIT FFI to load in SDL2.
local ffi = require("ffi")
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

-- We need this for borderless dragging, in windows at least; still need to test on nix and osx.
-- Note that for this to work, the user needs to give screen position hints to the application.
ffi.cdef([[
	typedef struct SDL_Rect
	{
    	int x, y;
    	int w, h;
	} SDL_Rect;

	uint32_t SDL_GetGlobalMouseState(int *x, int *y); /*needs SDL 2.0.4 or higher*/
	int SDL_GetNumVideoDisplays(void);
	int SDL_GetDisplayBounds(int displayIndex, SDL_Rect* rect);
]])

-- Function holder table
local t = {}

-- Given a display, and a coordinate inside that display, return a point in desktop-space.
t.toGlobalPosition = function(D,x,y,d) -- Displaylist, horizontal pos., vertical pos., display
	return D[d][1]+x, D[d][2]+y
end

-- Given a point in desktop-space, return display-local coordinates and the display's index.
t.toScreenPosition = function(D,x,y) -- Displaylist, horizontal pos., vertical pos.
	local X,Y,d = 0,0,0
	local minx, miny, maxx, maxy = 1/0,1/0,0,0

	-- Get width and height of the viewport, the area inside the window, because we will need it for the other bounds...
	-- TODO: Which to use...
	local w,h = love.graphics.getDimensions()
	--local w, h, _ = love.window.getMode()

	-- Check boundary conditions per-display.
	-- May not be perfectly sound, logically speaking (for non-convex arrangements)
	for i=1,#D do
		if minx > D[i][1] then minx = D[i][1] end
		if miny > D[i][2] then miny = D[i][2] end
		if maxx < D[i][1]+D[i][3] then maxx = D[i][1]+D[i][3] end
		if maxy < D[i][2]+D[i][4] then maxy = D[i][2]+D[i][4] end
	end

	-- If out of bounds, return false, and the bound we were near to.
	if x <  minx then
		return false, 'x', -1
	end
	if x+w > maxx then
		return false, 'x',  1
	end
	if y <  miny then
		return false, 'y', -1
	end
	if y+h > maxy then
		return false, 'y',  1
	end

	-- Check which display we're actually in, and return the coordinates as such.
	for i=1,#D do
		if x >= D[i][1] and x < D[i][1]+D[i][3] and y >= D[i][2] and y < D[i][2]+D[i][4] then
			return x-D[i][1], y-D[i][2], i
		end
	end

	-- Point doesn't exist on any screen; should not be possible to set to this anyway.
	return false, '0', 0
end

-- Return the mouse position on the desktop.
t.getGlobalMouseState = function()
	local x, y = ffi.new("int[1]", 0), ffi.new("int[1]", 0)
	local mousedown = sdl.SDL_GetGlobalMouseState(x, y)
	--if err ~= 1 then return false end -- Not on the desktop.
	return x[0], y[0], mousedown
end

-- Metatable for the above functions.
local mt = {__index = t}

-- Constructor; we could have just went with an init function and made the module stateful, but this works just as well.
local new = function()

	-- The array of displays (xOffset, yOffset,width,height)
	local D = {}

	-- How many displays the computer has.
	local n = sdl.SDL_GetNumVideoDisplays()

	-- Get the position and size data from all displays.
	for i = 1, n do
		local rect = ffi.new("SDL_Rect[1]")

		sdl.SDL_GetDisplayBounds(i-1, rect)

		D[i]    = {}
		D[i][1] = rect[0].x
		D[i][2] = rect[0].y
		D[i][3] = rect[0].w
		D[i][4] = rect[0].h
	end

	-- Allows to use the above 3 functions with the D displaylist. (with the colon (:) syntax)
	return setmetatable(D, mt)

end

return new()