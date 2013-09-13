acro = {}

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

function acro.new_game(self, mode, options)
	setmetatable(self, acro)
	-- game settings
	self.settings = require "games/settings"
	if mode and self.settings[mode] then
		game.settings.mode = mode
	end
	self.players = {}
	self.player_count = 0
	self.scores = {}
	self.state = "new"

	self.log = print
	self.print = print

	self.tell = function(nick, ...)
		print(nick, ...)
	end

	return self
end

function acro:end_game(winner)
	self.print(winner.player .. " wins!")
end

function acro:set_hook(callback, time)
	self.deadline = time
	self.callback = callback
end

function acro:process_hook(time)
	if time > self.deadline then
		self:callback()
	end
end

function acro:add_player(name)
	local settings = self.settings[self.settings.mode]
	if self.player_count > settings.player_limit then
		self.print("The room is full, sorry.")
		return
	end
	-- don't nuke a player if they join again (disconnects and shit)
	if self.players[name] then
		self.players[name].active = true
		return
	end

	self.players[name] = {}
	self.players[name].active = true
	self.players[name].score = 0
	self.player_count = self.player_count + 1
end

function acro:remove_player(name)
	-- don't clear score until end of round in case they disconnected
	if self.players[name] then
		self.players[name].active = false
		self.player_count = self.player_count - 1
	end
end

function acro:validate(player, text)
	local count = 0
	local errors = {}
	-- TODO: probably use some error codes and let the various modes change messages
	-- also needed for penalties.
	for _, acro in pairs(self.acros) do
		if text == acro.text then
			self.acros[acro.player] = nil -- filthy casuals
			self.tell(player, "you idiot, you and " .. acro.player .. " submitted the same acros like a bunch of xxxtacos!")
			self.print(player .. " and " .. acro.player .. " submitted the same things like a bunch of xxxtacos!")
			return false, {}
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
	self.log(name .. " submitted: " .. text)
	local valid, errors = acro:validate(name, text)
	if valid then
		self.acro_count = self.acro_count + 1
		self.tell(name, "Your acro \"" .. text .."\" has been registered. You may change it at any time before voting begins.")
		self.print("Acro #" .. self.acro_count .. " submitted")
		self.acros[name] = { text=text, idx=0, score=0, player=name }
	else
		if #errors > 0 then
			self.tell(name, "Look how many ways you've fucked up:")
			for i, v in ipairs(errors) do
				self.tell(name, i .. ": "..v)
			end
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
	self.acro_count = 0

	self.votes = {}

	self:generate_acro(manual)

	self.state = "submitting"

	self.print("The acro for this round is "..self.current_acro..". Voting begins in "..settings.time_limit.." seconds.")
end

function acro:end_round()
	local settings = self.settings[self.settings.mode]

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
		self.print(acro.player .. "'s acro: "..acro.text.." (".. acro.score .." votes)")
	end

	if winner.player == nil then
		self.print("Nobody won! What a bunch of losers!")
	else
		self.print("The winner for this round is "..winner.player.."!")
	end

	local scores = ""
	for player, score in pairs(self.scores) do
		if scores:len() > 0 then
			scores = scores .. ", "
		end
		scores = scores .. player .. ": " .. score
	end
	self.print("Scores: " .. scores)

	self.state = "waiting"

	if winner.score > settings.score_limit then
		self:end_game()
		self.state = "finished"
	else
		self.print("The next round will begin in " .. settings.time_between_rounds .. " seconds.")
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
		self.print(outLine)
		idx = idx + 1
	end
end

function acro:begin_vote()
	local settings = self.settings[self.settings.mode]
	if next(self.acros) == nil then
		self.print "Nobody submitted anything!"
		return
	else
		self.print ("Time to vote! You've got " .. settings.voting_time_limit .. " seconds.")
	end

	for player, acro in pairs(self.acros) do
		-- TODO: shuffle acro list and store the IDs
	end

	self.state = "voting"

	self:list_acros()
end

function acro:vote(voter, id)
	-- TODO: players should only get one vote per round (but they can change their mind)
	id = tonumber(id)
	for player, acro in pairs(self.acros) do
		if acro.idx == id then
			if acro.player == voter then
				self.tell(voter, "You can't vote for yourself!")
			else
				if not self.votes[id] then
					self.votes[id] = acro
				end
				self.tell(voter, "Your vote for acro " .. id .. " has been recorded.")
				self.votes[id].score = self.votes[id].score + 1
			end
			return
		end
	end
	self.tell(voter, id .. " is not a valid acro.")
end

return acro