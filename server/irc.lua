local socket = require "socket"

local settings = {
	server = "irc.freenode.net",
	port = 6667,
	nick = "ride-an-ostrich",
	channel = "##shakesoda",
	verbose = false -- echos all messages back to IRC and terminal
}

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

function process(s, channel, nick, line)
	if line:find("!kill") and nick == "shakesoda" then
		return false
	end

	return true
end

function run(settings)
	local s = connect(settings)
	local channel = settings.channel
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
			if settings.verbose then msg(s, channel, receive) end
			if receive:find(channel .. " :") then line = string.sub(receive, (string.find(receive, channel .. " :") + (#channel) + 2)) end
			if receive:find(":") and receive:find("!") then lnick = string.sub(receive, (string.find(receive, ":")+1), (string.find(receive, "!")-1)) end
			if line then
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
