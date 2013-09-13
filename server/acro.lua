local acro = {}

-- game settings
acro.settings = {
	mode = "normal",
	normal = {
		player_limit = 15,
		score_limit = 50,
		min_length = 2,
		max_length = 5,
		super_length = 10,
		allow_cockblock = false,
		allow_communism = false,
		allow_super = false
	},
	turkeyslam = {
		player_limit = 15,
		score_limit = 75,
		min_length = 2,
		max_length = 5,
		super_length = 10,
		allow_cockblock = true, -- you're not allowed to win
		allow_communism = true, -- fuck you! freem gets the point instead
		allow_super = true -- super 10 letter rounds
	}
}

acro.players = {}
acro.scores = {}
acro.acros = {}

--[[
-- some utf8 things that might be useful
-- http://stackoverflow.com/questions/13235091
-- get first letter
function firstLetter(str)
  return str:match("[%z\1-\127\194-\244][\128-\191]*")
end

-- utf8 iter
for code in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
  print(code)
end
]]

-- http://stackoverflow.com/questions/1426954
function string:split(pat)
	pat = pat or '%s+'
	local st, g = 1, self:gmatch("()("..pat..")")
	local function getter(segs, seps, sep, cap1, ...)
		st = sep and seps + #sep
		return self:sub(segs, (seps or 0) - 1), cap1 or sep, ...
	end
	return function() if st then return getter(st, g()) end end
end

function acro:validate(text)
	local count = 0
	local errors = {}
	for token in text:split() do
		count = count + 1
		--print(token:sub(1,1), self.current_acro:sub(count,count))
		if count > #self.current_acro then
			table.insert(errors, "too many words!")
			break
		elseif token:upper():sub(1,1) ~= self.current_acro:sub(count,count) then
			table.insert(errors, token .. " doesn't start with " .. self.current_acro:sub(count,count))
		end
	end
	if count < #self.current_acro then
		table.insert(errors, "not enough words")
	end

	return #errors == 0, errors
end

function acro:generate_acro()
	-- TODO: weight specific letters so you don't get bullshit acro's all the time
	local settings = self.settings[self.settings.mode]
	self.current_acro = ""

	math.randomseed(os.time())
	for i=1,math.random(settings.min_length, settings.max_length) do
		self.current_acro = self.current_acro .. string.char(math.random(65, 90))
	end
end

-- testing
acro:generate_acro()
local valid, errors = acro:validate("this answer is postmodern")
if valid then
	print "valid acro what do you know"
	-- acro.acros[player, text]
else
	for k,v in pairs(errors) do
		print(v)
	end
end

-- wait a while

-- judge round

-- distribute points

-- check if anyone passed point threshold
