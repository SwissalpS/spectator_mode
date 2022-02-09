require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

-- mimic player_api.player_attached
fixture('player_api')

function Player:hud_get_flags()
	return self._hud_flags or { hotbar = true, healthbar = true, crosshair = true,
		wielditem = true, breathbar = true, minimap = false, minimap_radar = false }
end
function Player:hud_set_flags(new_flags)
	if not self._hud_flags then self._hud_flags = self:hud_get_flags() end
	for flag, value in pairs(new_flags) do if nil ~= self._hud_flags[flag] then self._hud_flags[flag] = not not value end end
end
describe("Mod initialization", function()

	it("Wont crash", function()
		sourcefile("init")
	end)

end)

describe("Watching", function()

	local players = {
		SX = Player("SX", { interact = 1 }),
		boss = Player("boss", { interact = 1, watch = 1 }),
		dude1 = Player("dude1", { interact = 1, }),
		dude2 = Player("dude2", { interact = 1, }),
		dude3 = Player("dude3", { interact = false, }),
	}

	setup(function()
		for _, player in pairs(players) do
			mineunit:execute_on_joinplayer(player)
		end
	end)

	teardown(function()
		for _, player in pairs(players) do
			mineunit:execute_on_leaveplayer(player)
		end
	end)

	it("boss attaches to dude1", function()
		spy.on(minetest, "chat_send_player")
		players.boss:send_chat_message("/watch dude1")
		assert.spy(minetest.chat_send_player).was.called()
	end)
--[[

	it("creates channel", function()
		SX:send_chat_message("/cc foo")
		assert.not_nil(beerchat.channels["foo"])
	end)

	it("switches channels", function()
		SX:send_chat_message("#foo")
		assert.equals("foo", SX:get_meta():get_string("beerchat:current_channel"))
		SX:send_chat_message("Everyone ignore me, this is just a test")
	end)

	it("deletes channel", function()
		SX:send_chat_message("/dc foo")
		assert.is_nil(beerchat.channels["foo"])
	end)
--]]
end)

