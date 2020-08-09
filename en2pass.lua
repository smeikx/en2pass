#!/usr/bin/env lua

-- XXX REQUIRES LUA 5.4 (but can easily be adapted for older versions)
-- most probably won’t run on Windows

-- This script feeds a password database exported from Enpass in plain text to ‘pass’.
-- It takes a plain text file and assumes that each entry is separated by two blank lines.

-- Example Input
--[[
password : super-secret-password
title : My Favourite Website
url : https://gentoo.org/
username : xyz123foobar


email : what@ever.est
title : IDK
url : https://kernel.org/
password : you won't guess it
note: i luv it


]]--
-- XXX The two trailing blank lines are necessary to catch the last entry.

-- The name of the input file will be used as the name of the subdirectory in pass.
-- A field with the label ‘title’ will be used as the name of the output file.
-- The first line of each pass entry will contain the password, the rest comes afterwards.

-- an array containing tables with the keys ‘title’, ‘password’, ‘content’ (the other fields as string)
local entries <const> = {}

-- the content of the input file as one string
local content = ''

do
	local file <close> = assert(io.open(arg[1], 'r'))
	content = file:read('a')
end

for entry in string.gmatch(content, '(.-\n)\n\n') do
	entries[#entries+1] = {
		title = string.match(entry, '[Tt]itle ?: ([^\n]+)\n'),
		password = string.match(entry, '[Pp]assword ?: ([^\n]+)\n?') or ' ',
		content = ''
	}

	local content <const> = {}
	for line in string.gmatch(entry, '([^\n]+)') do
		if not string.find(line, '^[Tt]itle ?:') and not string.find(line, '^[Pp]assword ?:') then
			content[#content+1] = line
		end
	end
	entries[#entries].content = table.concat(content, '\n')..'\n'
end

local sub_dir = string.match(arg[1], '.*/(.+)%.')..'/'
for _,entry in ipairs(entries) do
	local pass <close> = assert(io.popen('pass insert -fm "'..sub_dir..entry.title..'"', 'w'), 'pass not working …')
	--local pass = io.stdout -- a dry run for debugging – prints passwords to stdout!
	pass:write(entry.password..'\n')
	pass:write(entry.content)
end
