local path = string.match(..., ".*/") or ""

local Color = require(path .. "Color")

local levels = {}

for level in path:gmatch("([^/]+)") do levels[#levels + 1] = level end

path = ""

for i, level in ipairs(levels) do if i ~= #levels then path = path .. "/" .. level end end

local Object = require(path .. "/third_party/classic")

local MultiLine

MultiLine = {}

function MultiLine:__call(...)
	local obj = setmetatable({}, self)
	local ret_val = obj:new(...)
	return ret_val
end

function MultiLine:new(con, text)
	local all_lines = self:parseText(con, {
		height = 0,
		time   = os.clock(),
		text   = { {1, 1, 1, 1} }
	}, text)
	
	for i, line in ipairs(all_lines) do all_lines[i] = SingleLine(line) end
	
	return all_lines
end

function MultiLine:parseText(con, line, text)

	local width, parsed_text, base_index, all_lines
	
	all_lines    = {}
	parsed_text  = ""
	base_index   = 1
	skip         = 0
	width        = 0
	
	for chr in text:gmatch(".") do
		if skip > 0 then --skip over color codes
			skip = skip - 1
		elseif chr == "\n" then
			line.text[#line.text + 1] = parsed_text
			
			all_lines[#all_lines + 1] = { 
				height = (math.floor(line.width / (con.keyboard.wrap_width_in_chars + 1)) + 1) * con.font.height,
				text   = line.text,
				time   = line.time
			}
			
			width       = 0
			line.height = 0
			line.text   = { line.text[#line.text - 1] }
		elseif chr == "c" and text:find("@", base_index + 1) then --color code parsing
			local tbl = {}
			
			for val in text:sub(base_index + 2):gmatch("(%d%d?%d?)|") do tbl[#tbl + 1] = val end
			
			if #tbl == 4 then
				-- the extra 5 is the @, and the four dividers. We're already skipping c on this loop
				skip = tbl[1]:len() + tbl[2]:len() + tbl[3]:len() + tbl[4]:len() + 5
				line.text[#line.text + 1] = parsed_text
				line.text[#line.text + 1] = { tonumber(tbl[1]), tonumber(tbl[2]), tonumber(tbl[3]), tonumber(tbl[4]) }
				parsed_text = ""
			else
				width       = width + 1
				parsed_text = parsed_text .. chr
			end
		else
			width       = width + 1
			parsed_text = parsed_text .. chr
		end
		
		base_index = base_index + 1
	end
	
	line.text[#line.text + 1] = parsed_text
	
	all_lines[#all_lines + 1] = { 
		height = (math.floor(width / (con.keyboard.wrap_width_in_chars + 1)) + 1) * con.font.height,
		text   = line.text,
		time   = line.time
	}
			
	return all_lines
end

SingleLine = Object:extend()

function SingleLine:new(parsed_line)
	self.meta = parsed_line
end

function SingleLine:get_time() return self.meta.time end
function SingleLine:get_formatted_text() return self.meta.text end
function SingleLine:get_height() return self.meta.height end

function SingleLine:get_str_text()
	local str = ""
	
	for i, item in ipairs(self.meta.text) do if type(item) == "string" then str = str .. item end end
	
	return str
end

function SingleLine:print(x, y, wrap)
	love.graphics.printf(self.formatted_text, x, y, wrap)
end

function SingleLine:recalculateSize(con)
	self.time   = os.clock()
	self.height = (math.floor(self.str_text:len() / (con.keyboard.wrap_width_in_chars + 1)) + 1) * con.font.height
end

return MultiLine