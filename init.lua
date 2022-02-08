-- NOTE: in the output texts, the names are always in double quotes because some players have
--	names that can be confusing without the quotes.
-- WARNING: currently the states are only stored in runtime memory. If server crashes, some
--	players may be in weird states on relog!

spectator_mode = {
	version = 20220208,
	command_accept = 'smy', -- TODO: fetch these from settings
	command_deny = 'smn',
	command_detach = 'unwatch',
	command_invite = 'watchme',
	watchme_timeout = 1 * 60,
}
local sm = spectator_mode
local chat = minetest.chat_send_player

-- list of saved states indexed by player name
local original_state = {}
-- list of pending invites indexed by invited player name
-- each entry contains the name of the player who sent the invite
local invites = {}


minetest.register_privilege("watch", {
	description = "Player can watch other players",
	give_to_singleplayer = false,
	give_to_admin = true,
})


local function turn_off_hud_flags(player)
	local flags = player:hud_get_flags()
	local new_hud_flags = {}

	for flag in pairs(flags) do
		new_hud_flags[flag] = false
	end

	player:hud_set_flags(new_hud_flags)
end


-- called by the detach command '/unwatch'
-- also called on logout if player is attached at that time
local function detach(name)
	-- nothing to do
	if not player_api.player_attached[name] then return end

	local watcher = minetest.get_player_by_name(name)
	if not watcher then return end -- shouldn't ever happen

	watcher:set_detach()
	player_api.player_attached[name] = false
	watcher:set_eye_offset(vector.new(), vector.new())

	local saved_state = original_state[name]
	-- nothing else to do
	if not saved_state then return end

	watcher:set_nametag_attributes({ color = saved_state.nametag.color, bgcolor = saved_state.nametag.bgcolor })
	watcher:hud_set_flags(saved_state.hud_flags)
	watcher:set_properties({
		visual_size = saved_state.visual_size,
		makes_footstep_sound = true,
		collisionbox = saved_state.collisionbox,
	})

	local privs = minetest.get_player_privs(name)
	if not privs.interact and privs.watch then
		privs.interact = true
		minetest.set_player_privs(name, privs)
	end

	local pos = saved_state.pos
	if pos then
		-- set_pos seems to be very unreliable
		-- this workaround helps though
		minetest.after(0.1, function() watcher:set_pos(pos) end)
	end
	original_state[name] = nil
end


-- bothe players are online and all checks have been done when this
-- method is called
local function attach(name_watcher, name_target)

	-- detach from cart, horse, bike etc.
	if player_api.player_attached[name_watcher] then
		detach(name_watcher)
	end

	local watcher = minetest.get_player_by_name(name_watcher)
	-- back up some attributes
	local properties = watcher:get_properties()
	original_state[name_watcher] = {
		collisionbox = table.copy(properties.collisionbox),
		hud_flags = table.copy(watcher:hud_get_flags()),
		nametag = table.copy(watcher:get_nametag_attributes()),
		pos = vector.new(watcher:get_pos()),
		target = name_target,
		visual_size = table.copy(properties.visual_size),
	}

	-- set some attributes
	turn_off_hud_flags(watcher)
	watcher:set_properties({
		visual_size = { x = 0, y = 0 },
		makes_footstep_sound = false,
		collisionbox = { 0 },
	})
	watcher:set_nametag_attributes({ color = { a = 0 }, bgcolor = { a = 0 } })
	watcher:set_eye_offset(vector.new(0, -5, -20), vector.new())
	-- make sure watcher can't interact
	local privs_watcher = minetest.get_player_privs(name_watcher)
	privs_watcher.interact = nil
	minetest.set_player_privs(name_watcher, privs_watcher)
	-- and attach
	player_api.player_attached[name_watcher] = true
	local target = minetest.get_player_by_name(name_target)
	watcher:set_attach(target, "", vector.new(0, -5, -20), vector.new())
end


-- called by /watch command
local function watch(name_watcher, name_target)
	if name_watcher == name_target then return true, "You may not watch yourself." end

	local target = minetest.get_player_by_name(name_target)
	if not target then return true, 'Invalid target name "' .. name_target .. '"' end

	-- avoid infinite loops
	if original_state[name_target] then return true, '"' .. name_target .. '" is watching "'
		.. original_state[name_target].target .. '". You may not watch a watcher.' end

	attach(name_watcher, name_target)
	return true, 'Watching "' .. name_target .. '" at '
		.. minetest.pos_to_string(vector.round(target:get_pos()))
end


-- TODO: allow inviting multiple players
-- called by '/watchme' command
local function watchme(name_target, name_watcher)
	if name_watcher == name_target then return true, 'You may not watch yourself.' end

	if original_state[name_target] then
		return true, 'You are watching "' .. original_state[name_target].target .. '", no chain watching allowed.'
	end
	
	if original_state[name_watcher] then
		return true, '"' .. name_watcher .. '" is busy watching another player.'
	end

	if invites[name_watcher] then return true, '"' .. name_watcher .. '" has a pending invite, try again later.' end

	if not minetest.get_player_by_name(name_watcher) then return true, '"' .. name_watcher .. '" is not online.' end

	if not sm.is_permited_to_invite(name_target, name_watcher) then
		return true, 'You may not invite "' .. name_watcher .. '".'
	end
	
	invites[name_watcher] = name_target
	minetest.after(sm.watchme_timeout, invite_timed_out, name_watcher)
	-- notify invited
	chat(name_watcher, '"' .. name_target .. '" has invited you to observe them. Accept with /' .. 	sm.command_accept
		.. ', deny with /' .. command_deny .. '.\n'
		.. 'The invite expires in ' .. tostring(sm.watchme_timeout) .. ' seconds.')
	-- notify invitee
	return true, 'You have invited "' .. name_watcher .. '".\n'
		.. 'The invite expires in ' .. tostring(sm.watchme_timeout) .. ' seconds.'
end


-- this function only checks privs etc. Mechanics are already checked in watchme()
-- other mods can override and extend these checks
function spectator_mode.is_permited_to_invite(name_target, name_watcher)
	if minetest.get_player_privs(name_target).watch then
		return true
	end

	-- TODO: check chat and tpr mute if the mods are active
	return false
end


-- called by the accept command '/smy'
local function accept_invite(name_watcher)
	local name_target = invites[name_watcher]
	if not name_target then
		return true, 'There is no invite for you. Maybe it timed-out.'
	end

	attach(name_watcher, name_target)
	invites[name_watcher] = nil
	chat(name_target, '"' .. name_watcher .. '" is now attached to you.')
	return true, 'OK, you have been attached to "' .. name_target .. '". To disable type /unwatch'
end


-- called by the deny command '/smn'
local function decline_invite(name_watcher)
	if not invites[name_watcher] then
		return true, 'There is no invite for you. Maybe it timed-out.'
	end

	chat(invites[name_watcher], '"' .. name_watcher .. '" declined the invite."')
	invites[name_watcher] = nil
	return true, 'OK, declined invite.'
end


minetest.register_chatcommand("watch", {
	params = "<target name>",
	description = "Watch a given player",
	privs = { watch = true },
	func = watch,
})


minetest.register_chatcommand(sm.command_detach, {
	description = "Unwatch a player",
	privs = { },
	--luacheck: no unused args
	func = function(name, param) detach(name) end
})


minetest.register_chatcommand(sm.command_invite, {
	description = 'Invite a player to watch you',
	params = '<player name>',
	privs = { },
	func = watchme,
})


minetest.register_chatcommand(sm.command_accept, {
	description = 'Accept an invitation to watch another player',
	params = '',
	privs = { },
	func = accept_invite,
})


minetest.register_chatcommand(sm.command_deny, {
	description = 'Deny an invitation to watch another player',
	params = '',
	privs = { },
	func = decline_invite,
})


minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	detach(name)
end)
