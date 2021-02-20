local reg, ffi, Object, sub_path

sub_path = string.match(..., ".*/") or ""

ffi    = require("ffi")
Object = require(sub_path .. "classic")

reg = Object:extend()

	--===|||WINREG CLASS|||===--

function reg:new()
	self.data = {}
end

		--===LOVE FUNCTIONS===--

function reg:load()
	local source = love.filesystem.getSource()

	self.data.reg = ffi.load(love.filesystem.isFused() and (source:match("(.+)\\.+$") .. "/WinReg.dll") or (source .. "/" .. sub_path .. "WinReg.dll"))
	
	ffi.cdef(" char * reg(const char * args); ")
end
	
		--===METHODS===--

--[[
	Delete a key/value pair from a registry entry. If the key does not
	exist, returns false, otherwise on a successful delete will return
	true.
--]]
function reg:deleteKey(root, path, key)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|delete_val|" .. key .."|"))
	type, message = result:match("(.+)=(.+)")
	
	if type == "OUT" then
		return message == "true"
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
end

--[[
	Delete an entry from the registry. If the entry does not exist,
	returns false, otherwise on a successful delete will return
	true.
--]]
function reg:deleteEntry(root, path, key)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|delete_key|" .. key .."|"))
	type, message = result:match("(.+)=(.+)")
	
	if type == "OUT" then
		return message == "true"
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
end

--[[
	Set a key/value pair for a registry entry. If the value already exists,
	overwrites the existing key/value pair. Currently only sets REG_SZ type
	entries, mainly because I'm lazy and don't really know what or why there
	are different types for. Returns true on success.
--]]
function reg:setKey(root, path, key, value)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|set_val|" .. key .."|" .. value))
	type, message = result:match("(.+)=(.+)")
	
	if type == "OUT" then
		return message == "true"
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
end

--[[
	Set a registry entry. If the current registry entry already exists, then
	nothing happens. Returns true on success.
--]]
function reg:setEntry(root, path, key)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|set_key|" .. key .."|"))
	type, message = result:match("(.+)=(.+)")
	
	if type == "OUT" then
		return message
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
end

--[[
	Gets a value from a key from a registry entry. If the key/value pair
	doesn't exist, then it returns nil, otherwise will return the value.
--]]
function reg:getValue(root, path, key)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|get_val|" .. key .."|"))
	type, message = result:match("(.+)=(.+)")
	
	if type == "OUT" then
		if message == "nil" then 
			return nil
		elseif tonumber(message) ~= nil then
			return tonumber(message)
		elseif message:lower() == "true" or message:lower() == "false" then
			return message:lower() == "true"
		else
			return message
		end
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
end

--[[
	Returns a table of all key names under a specific registry entry.
	If the entry has no key/value pairs, then returns an empty table.
--]]
function reg:getKeys(root, path)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|get_all_vals||"))
	type, message = result:match("(.+)=(.*)")
	ret_val       = {}
	
	if type == "OUT" then
		for match in message:gmatch("([^|]+)|") do ret_val[#ret_val + 1] = match end
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
	
	return ret_val
end

--[[
	Returns a table of all sub entries under a specific root/path. Returns
	an empty table if there is nothing below this.
--]]
function reg:getSubEntries(root, path)
	local result, type, message, ret_val
	
	result        = ffi.string(self.data.reg.reg(root .. "|" .. path .. "|get_subkeys||"))
	type, message = result:match("(.+)=(.*)")
	ret_val       = {}
	
	if type == "OUT" then
		for match in message:gmatch("([^|]+)|") do ret_val[#ret_val + 1] = match end
	elseif type == "ERR" then
		error(message)
	else
		error(result)
	end
	
	return ret_val
end

return reg()