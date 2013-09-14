local settings = {
	game = "acro",
	mode = "normal",

	-- rulesets
	normal = {
		time_limit = 60,
		voting_time_limit = 30,
		time_between_rounds = 15,
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
		time_limit = 60,
		voting_time_limit = 30,
		time_between_rounds = 15,
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

setmetatable(settings, { __index = function(t, k) print("invalid setting! (attempt to access \"" .. k .. "\")") return 0 end })

return settings