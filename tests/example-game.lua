require "./server/acro"

-- testing
acro:add_player("shakesoda")
acro:add_player("freem")

acro:begin_round("TIAP")

acro:submit_acro("freem", "turkeyslam ingests a penis")
--acro:submit_acro("shakesoda", "fatsune miku likes chocolate")
acro:submit_acro("shakesoda", "tv is a penis.")
acro:submit_acro("freem", "this is a personal_request_to_submit_a_second_acro")

acro:begin_vote()

acro:vote("freem", 2)
acro:vote("shakesoda", 2) -- you can't vote for your own acro!! check. (exactly)
acro:vote("xxxtaco", 2)

acro:end_round() -- should be called on timer and ignore further votes

-- round 2
acro:begin_round("DUPE")
acro:submit_acro("xxxtaco","d uck p enis")
acro:submit_acro("not_xxxtaco","d uck p enis")
-- you idiots submitted the same acro like a bunch of xxxtacos, minus some points

acro:begin_vote()

acro:end_round()
