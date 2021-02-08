local ffi, sdl, tbl

ffi = require("ffi")
sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C
tbl = {}

ffi.cdef([[
	typedef struct SDL_Window SDL_Window; //https://github.com/spurious/SDL-mirror/blob/master/include/SDL_video.h#L94
	SDL_Window* SDL_GL_GetCurrentWindow(void);
	void SDL_SetWindowSize(SDL_Window* window, int w, int h);
	void SDL_SetWindowPosition(SDL_Window* window, int x, int y);
	int SDL_GetDisplayUsableBounds(int displayIndex, SDL_Rect* rect);
]])

function tbl:getUsableBounds(display)
	local rectangle = ffi.new("SDL_Rect[1]")
	local err = sdl.SDL_GetDisplayUsableBounds(display - 1, rectangle)
	return rectangle[0].x, rectangle[0].y, rectangle[0].w, rectangle[0].h
end

function tbl:resize(w, h)
	if not self.win then self.win = sdl.SDL_GL_GetCurrentWindow() end
	sdl.SDL_SetWindowSize(self.win, w, h)
end

function tbl:move(x, y)
	if not self.win then self.win = sdl.SDL_GL_GetCurrentWindow() end
	sdl.SDL_SetWindowPosition(self.win, x, y)
end

return tbl