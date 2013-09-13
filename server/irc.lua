local socket = require "socket"
local acro = require "server/acro"

local settings = {
	server = "irc.xtil.net",
	port = 6667,
	nick = "acrobot-x",
	channel = "#acrosoda",
	verbose = false -- echos all messages back to IRC and terminal
}

local games = {}

function msg(s, channel, content)
	s:send("PRIVMSG " .. channel .. " :" .. content ..  "\r\n\r\n")
end

function connect(params)
	print("Connecting to " .. params.server .. ":" .. params.port .. "/" .. params.channel .. " as " .. params.nick)

	local s = socket.tcp()
	s:connect(socket.dns.toip(params.server), params.port)

	-- USER username hostname servername :realname
	s:send("USER " .. string.format("%s %s %s :%s\r\n\r\n", params.nick, params.nick, params.nick, params.nick))
	s:send("NICK " .. params.nick .. "\r\n\r\n")

	return s
end

function ping_reply(s, receive)
	if receive:find("PING :") then
		s:send("PONG :" .. receive:sub(receive:find("PING :") + 6) .. "\r\n\r\n")
		if settings.verbose then print("pong") end
	end
end

function process_channel(s, channel, nick, line)
	if line:find("!") == 1 then
		local command = line:sub(2)
		if command:find("debug") == 1 then
			debug.debug()
		end
		if command:find("help") == 1 then
			local help = {
				kill = "(admin) kill the bot",
				toggle_verbose = "(admin) toggle echoing everything back into the channel (debug)"
			}
			msg(s, channel, "Commands:")
			for k, v in pairs(help) do msg(s, channel, string.format("!%s: %s", k, v)) end
		end
		if nick == "shakesoda" then
			if command:find("kill") then
				return false
			end
			if command:find("toggle_verbose") then
				settings.verbose = not settings.verbose
				msg(s, channel, "settings.verbose = " .. tostring(settings.verbose))
			end
		end

		if command:find("start") == 1 then
			local mode = line:sub(7)
			if mode:len() < 1 then
				mode = nil
			end
			msg(s, channel, "/!\\ Game started /!\\")
			games[channel] = acro:new_game(mode)

			-- \t doesn't work well on all IRC clients.
			games[channel].tell = function(nick, ...)
				print(nick, ...)
				msg(s, nick, table.concat({...}, ", "))
			end
			games[channel].print = function(...)
				print(...)
				msg(s, channel, table.concat({...}, ", "))
			end
			acro:begin_round()
		end

		local game = games[channel]
		if game then
			if command:find("stop") == 1 then
				msg(s, channel, "/!\\ Game ended /!\\")
				games[channel] = nil
			end

			if command:find("next") == 1 and game.state == "submitting" then
				game:begin_round()
			end

			if command:find("continue") == 1 then
				if game.state == "new" then
					game:begin_round()
				elseif game.state == "submitting" then
					game:begin_vote()
				elseif game.state == "voting" then
					game:end_round()
				elseif game.state == "waiting" then
					game:begin_round()
				elseif game.state == "finished" then
					games[channel] = nil
					msg(s, channel, "There is no game currently running.")
				end
			end
		end

		return true
	end

	return true
end

function process_message(s, channel, nick, line)
	local game = games[settings.channel]
	if game then
		game:add_player(nick)
		game:submit_acro(nick, line)
		game:list_acros()
	end

	return true
end

function run(settings)
	local s = connect(settings)
	local joined = false

	while true do
		local receive = s:receive('*l')
		
		-- reply to ping
		ping_reply(s, receive)
		if receive:find(":End of /MOTD command.") then
			s:send("JOIN " .. settings.channel .. "\r\n\r\n")
			joined = true
		end

		-- https://github.com/davidshaw/ircbot.lua
		if joined and receive:find("PRIVMSG") then
			local line = nil
			local channel = channel
			if settings.verbose then msg(s, settings.channel, receive) end

			local start = receive:find("PRIVMSG ") + 8
			local channel = receive:sub(start, receive:find(" :") - 1)
			if receive:find(" :") then line = receive:sub((receive:find(" :") + 2)) end
			if receive:find(":") and receive:find("!") then lnick = receive:sub(receive:find(":")+1, receive:find("!")-1) end

			-- for private messages, we want to talk back to the sender.
			if channel == settings.nick then channel = lnick end
			if line then
				local process = (channel == settings.channel) and process_channel or process_message
				if not process(s, channel, lnick, line) then
					s:send("QUIT :Goodbye, cruel world!\r\n\r\n")
					s:close()
					return
				end
			end
		end

		if settings.verbose then print(receive) end
	end
end

run(settings)
