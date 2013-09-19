local acro = require "games/acro"

local game = acro:new_game()

-- testing
game:add_player("shakesoda")
game:add_player("freem")

game:begin_round("TIAP")

game:submit_acro("freem", "turkeyslam ingests a penis")
game:submit_acro("shakesoda", "tv is a penis.")
game:submit_acro("freem", "this is a personal_request_to_submit_a_second_acro")

game:begin_vote()

game:vote("freem", 2)
game:vote("shakesoda", 2) -- you can't vote for your own acro!! check. (exactly)
game:vote("xxxtaco", 1)
game:vote("nepgear", 1)

-- winner should be freem, shakesoda's acro should be disqualified
game:end_round()

-- round 2
game:begin_round("DUPE")
game:submit_acro("xxxtaco","d uck p enis")
game:submit_acro("not_xxxtaco","d uck p enis")
-- you idiots submitted the same acro like a bunch of xxxtacos, minus some points

game:begin_vote()

game:end_round()
