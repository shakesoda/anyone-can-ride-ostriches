require "common/utils"

acro = {}

function acro.new_game(self, mode, options)
	-- fix me
	setmetatable(self, acro)

	-- game settings
	self.settings = require "games/settings"

	-- make sure changes stick to this specific game
	self.settings = deepcopy(self.settings)
	if mode and self.settings[mode] then
		game.settings.mode = mode
	end

	self.round = 0

	-- name = player {}
	self.players = {}
	self.player_count = 0

	-- name = acro {}
	self.scores = {}

	self.state = "new"
	self.empty_rounds = 0

	self.log = print
	self.print = print

	self.tell = function(nick, ...)
		print(nick, ...)
	end

	return self
end

function acro:end_game(winner)
	self.state = "finished"
	self.print("/!\\ " .. winner.player .. " wins!")
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

function acro:set_option(key, value)
	local settings = self.settings[self.settings.mode]
	local valid_keys = {
		time_limit = "number",
		voting_time_limit = "number",
		time_between_rounds = "number",
		player_limit = "number",
		score_limit = "number",
		min_length = "number",
		max_length = "number",
		super_length = "number",
		allow_cockblock = "boolean",
		allow_communism = "boolean",
		allow_super = "boolean"
	}
	if valid_keys[key] == "number" then
		settings[key] = tonumber(value) or 1
	elseif valid_keys[key] == "boolean" then
		settings[key] = (value == "true")
	else
		self.print("Invalid key, probably.")
		return
	end
	self.print(key .. " is now " .. tostring(settings[key]) .. " for the rest of the game.")
end

function acro:add_player(name)
	local settings = self.settings[self.settings.mode]
	if self.player_count >= settings.player_limit then
		self.print("The game is full, sorry.")
		return
	end
	-- don't nuke a player if they join again (disconnects and shit)
	if self.players[name] then
		if self.players[name].active then
			return
		end
		self.players[name].active = true
		self.tell(name, "Welcome back!")
		return
	end

	self.tell(name, "Have fun! If you leave mid-game be sure to type !out into the channel (don't worry, your score will still be there if you come back).")

	self.players[name] = {
		active = true,
		score = 0,
		cockblocked = false
	}
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
		self:add_player(name)
		local submit_time = os.difftime(os.time(),self.round_start_time)
		self.tell(name, string.format("Your acro, \"%s\" is registered (%d seconds). You may change it at any time before voting begins.",text,submit_time))

		if self.acros[name] == nil then
			self.acro_count = self.acro_count + 1
			self.print("Acro #" .. self.acro_count .. " submitted")
		end

		self.acros[name] = { text=text, idx=0, score=0, player=name }

		if self.scores[name] == nil then
			self.scores[name] = 0
		end
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

	local weights = settings.weights
	local bag = {}

	for l,v in pairs(weights) do
		for i=1,v do
			table.insert(bag, l)
		end
	end

	math.randomseed(os.time())
	for i=1,math.random(settings.min_length, settings.max_length) do
		self.current_acro = self.current_acro .. bag[math.random(#bag)]
	end
end

function acro:begin_round(manual)
	local settings = self.settings[self.settings.mode]

	self.round = self.round + 1

	-- name = acro {}
	self.acros = {}
	self.acro_count = 0

	-- name = acro {}
	self.votes = {}

	self:generate_acro(manual)

	self.state = "submitting"

	self.print("The acro for this round is "..self.current_acro..". Voting begins in "..settings.time_limit.." seconds.")

	self.round_start_time = os.time()
end

function acro:end_round()
	local settings = self.settings[self.settings.mode]

	-- apply votes
	for player, vote in pairs(self.votes) do
		vote.score = vote.score + 1
	end

	local winner = { score = 0, text = "everyone loses", player = nil }
	for _, acro in pairs(self.acros) do
		local disqualified = self.votes[acro.player] == nil
		local message = ""

		if acro.score > winner.score then
			winner = acro
			winner.disqualified = disqualified
		end

		-- must vote if you entered, or no points!
		if not disqualified then
			self.scores[acro.player] = self.scores[acro.player] + acro.score
		else
			if acro.score == 0 then
				message = " and they also didn't vote."
			else
				message = " - but " .. acro.player .. " didn't vote!"
			end
		end

		local vote_message = " (votes: ".. acro.score .. ")"
		if acro.score == 0 then
			vote_message = " got no votes"
		end

		self.print(acro.player .. "'s acro: ".. acro.text .. vote_message .. message)
	end

	if winner.player == nil then
		self.print("Nobody won! What a bunch of losers!")
	else
		local message = ""
		if winner.disqualified then
			message = " But they didn't vote, so they get no points!"
		end
		self.print("The winner for round #"..self.round.." is "..winner.player.."!" .. message)
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

	if winner.player and self.scores[winner.player] >= settings.score_limit then
		self:end_game(winner)
	else
		self.print("The next round will begin in " .. settings.time_between_rounds .. " seconds.")
	end
end

function acro:list_acros(fixed_seed)
	local settings = self.settings[self.settings.mode]
	local idx = 1
	local name_order_initial = {}
	local name_order_final = {}
	math.randomseed(fixed_seed or os.time())
	for name, _ in pairs(self.acros) do table.insert(name_order_initial,name) end
	for _, name in ipairs(name_order_initial) do
		local random_val = 0
		repeat random_val = math.random(1,#name_order_initial)
		until not name_order_final[random_val]
		name_order_final[random_val] = name
	end
	name_order_initial = nil
	for _, name in ipairs(name_order_final) do
		local acro = self.acros[name]
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
		self.print("Nobody submitted anything!")
		self.empty_rounds = self.empty_rounds + 1
		if self.empty_rounds < 5 then
			self.state = "waiting"
		else
			self.print("Nobody submitted anything for 5 rounds in a row. I give up.")
			self.state = "finished"
		end
		return
	else
		self.empty_rounds = 0
		self.print("Time's up! You've got " .. settings.voting_time_limit .. " seconds to vote.")
	end

	for player, acro in pairs(self.acros) do
		-- TODO: shuffle acro list and store the IDs
	end

	self.state = "voting"

	self:list_acros()
end

function acro:vote(voter, line)
	local id = tonumber(line) or 0
	if id < 1 or id > self.acro_count then
		self.tell(voter, "That is not a valid acro.")
		return
	end
	for player, acro in pairs(self.acros) do
		if acro.idx == id then
			if acro.player == voter then
				self.tell(voter, "You can't vote for yourself!")
			else
				if self.votes[voter] == nil then
					self.votes[voter] = acro
				end
				self.tell(voter, "Your vote for acro " .. id .. " has been recorded.")
			end
			return
		end
	end
end

return acro