acro = {}

-- game settings
acro.settings = require "./server/settings"
acro.hooks = { normal = {} }
acro.players = {}
acro.scores = {}

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

function acro:add_player(name)
	-- don't nuke a player if they join again (disconnects and shit)
	if self.players[name] then
		self.players[name].active = true
		return
	end

	self.players[name] = {}
	self.players[name].active = true
	self.players[name].score = 0
end

function acro:remove_player(name)
	-- don't clear score until end of round in case they disconnected
	if self.players[name] then
		self.players[name].active = false
	end
end

function acro:validate(text)
	local count = 0
	local errors = {}
	-- TODO: probably use some error codes and let the various modes change messages
	-- also needed for penalties.
	for player, acro in pairs(self.acros) do
		if text == acro.text then
			self.acros[acro.player] = nil -- filthy casuals
			table.insert(errors, "you idiots submitted the same acros like a bunch of xxxtacos!")
		end
	end
	for token in text:split() do
		count = count + 1
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

function acro:submit_acro(name, text)
	local valid, errors = acro:validate(text)
	if valid then
		self.acros[name] = { text=text, idx=0, score=0, player=name }
	else
		print ("Look how many ways you've fucked up, " .. name .. ":")
		for i, v in ipairs(errors) do
			print(i .. ": "..v)
		end
	end
end

function acro:generate_acro(manual)
	-- mostly for debugging
	if manual then
		self.current_acro = manual
		return
	end

	-- TODO: weight specific letters so you don't get bullshit acro's all the time
	local settings = self.settings[self.settings.mode]
	self.current_acro = ""

	math.randomseed(os.time())
	for i=1,math.random(settings.min_length, settings.max_length) do
		self.current_acro = self.current_acro .. string.char(math.random(65, 90))
	end
end

function acro:begin_round(manual)
	local settings = self.settings[self.settings.mode]

	self.acros = {}
	self.votes = {}

	self:generate_acro(manual)
	-- TODO: put begin vote on timer

	print() -- gimme some space
	print("The acro for this round is "..self.current_acro..". Voting begins in "..settings.time_limit.." seconds.")
end

function acro:end_round()
	-- TODO: declare winner, fuck with points.
	local winner = { score = 0, text = "everyone loses" }
	for _, acro in pairs(self.acros) do
		if acro.score > winner.score then
			winner = acro
		end
		if not self.scores[acro.player] then
			self.scores[acro.player] = 0
		end
		self.scores[acro.player] = self.scores[acro.player] + acro.score
		print(acro.player .. "'s acro: "..acro.text.." (".. acro.score .." votes)")
	end

	if winner.player == nil then
		print("Nobody won! What a bunch of losers!")
	else
		print("The winner for this round is "..winner.player.."!")
	end

	print("Scores:")
	for player, score in pairs(self.scores) do
		print(player .. ": " .. score)
	end
end

function acro:list_acros()
	local settings = self.settings[self.settings.mode]
	local idx = 1
	for name, acro in pairs(self.acros) do
		local player = self.players[name]
		acro.idx = idx
		local outLine = idx .. ": " .. acro.text
		if player.score > settings.score_limit * 0.9 and math.random(1,3) == 2 then
			outLine = outLine .. " (btw this is "..player.."'s acro)"
		end
		print(outLine)
		idx = idx + 1
	end
end

function acro:begin_vote()
	if next(self.acros) == nil then
		print "Nobody submitted anything!"
		return
	end

	for player, acro in pairs(self.acros) do
		-- TODO: shuffle acro list and store the IDs
	end


	self:list_acros()

	-- TODO: put end round on timer
end


function acro:vote(voter, id)
	-- TODO: dq acro if someone votes for themselves like an asshole
	-- usually it's just a message and no DQ, but it could be an option
	for player, acro in pairs(self.acros) do
		if acro.idx == id then
			if acro.player == voter then
				print "You can't vote for yourself!"
			else
				if not self.votes[id] then
					self.votes[id] = acro
				end
				self.votes[id].score = self.votes[id].score + 1
			end
			break
		end
	end
end
