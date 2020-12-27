--[[
(get)Classic

Copyright (c) 2014, rxi, modified by Jumpsplat120

This module is free software; you can redistribute it and/or modify it under the terms of the MIT license. See LICENSE for details.

--]]

local Object = {}

Object.__index = Object

function Object:extend()
	local cls = {}
	for k, v in pairs(self) do
		if k:find("__") then cls[k] = v end
	end
	
	cls.__index = function(self, key)
		local getter = rawget(cls, "get_" .. key)
		if getter then return getter(self) else return cls[key] end
	end
	
	cls.__newindex = function(self, key, value)
		local setter = rawget(cls, "set_" .. key)
		if setter then setter(self, value) else rawset(self, key, value) end
	end
	
	cls.super = self
	setmetatable(cls, self)
	return cls
end

function Object:implement(...)
	for _, cls in pairs({...}) do for k, v in pairs(cls) do
		if self[k] == nil and type(v) == "function" then self[k] = v end
    end end
end

function Object:is(T)
	local mt = getmetatable(self)
	
	while mt do
		if mt == T then return true end
		mt = getmetatable(mt)
	end
	
	return false
end

function Object:__tostring()
	return "Object"
end

function Object:__call(...)
	local ins = setmetatable({}, self)
	ins:new(...)
	return ins
end

return Object