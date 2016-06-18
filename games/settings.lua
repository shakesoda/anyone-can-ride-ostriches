-- games/settings.lua - Settings and game rules

local settings = {
	game = "acro",
	mode = "normal",

	-- rulesets (Acro)
	normal = {
		time_limit = 60,
		voting_time_limit = 45,
		time_between_rounds = 30,
		player_limit = 15,
		score_limit = 31,
		min_length = 3,
		max_length = 5,
		super_length = 10,
		allow_cockblock = false,
		allow_communism = false,
		allow_super = false,
		weights = {
			A = 6, B = 4, C = 3, D = 2, E = 2, F = 3, G = 2, H = 3, I = 6,
			J = 2, K = 1, L = 2, M = 3, N = 2, O = 2, P = 2, Q = 1, R = 3,
			S = 6, T = 6, U = 1, V = 1, W = 3, X = 1, Y = 3, Z = 1
		}
	},
	super = {
		time_limit = 90,
		voting_time_limit = 60,
		time_between_rounds = 60,
		player_limit = 15,
		score_limit = 51,
		min_length = 3,
		max_length = 7,
		super_length = 10,
		allow_cockblock = false,
		allow_communism = false,
		allow_super = true,
		weights = {
			A = 6, B = 3, C = 3, D = 2, E = 2, F = 3, G = 2, H = 3, I = 6,
			J = 1, K = 2, L = 2, M = 3, N = 2, O = 3, P = 2, Q = 1, R = 3,
			S = 6, T = 6, U = 1, V = 2, W = 3, X = 1, Y = 3, Z = 1
		}
	},
	turkeyslam = {
		time_limit = 60,
		voting_time_limit = 45,
		time_between_rounds = 15,
		player_limit = 15,
		score_limit = 31,
		min_length = 2,
		max_length = 5,
		super_length = 10,
		allow_cockblock = true, -- you're not allowed to win
		allow_communism = true, -- fuck you! freem gets the point instead
		allow_super = true, -- super 10 letter rounds
		weights = {
			A = 10, B = 8, C = 6, D = 4, E = 5, F = 6, G = 4, H = 6, I = 9,
			J =  5, K = 5, L = 4, M = 6, N = 4, O = 1, P = 4, Q = 1, R = 6,
			S = 12, T = 9, U = 3, V = 3, W = 2, X = 1, Y = 2, Z = 2
		}
	}
}

setmetatable(settings, { __index = function(t, k) print("invalid setting! (attempt to access \"" .. k .. "\")") return 0 end })

return settings