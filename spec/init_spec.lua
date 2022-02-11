require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

-- mimic player_api.player_attached
fixture('player_api')
-- add some not yet included functions
fixture('mineunit_extensions')

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
	local start_positions = {}

	setup(function()
		local i, pos = 1
		for name, player in pairs(players) do
			mineunit:execute_on_joinplayer(player)
			pos = vector.new(10 * i, 20 * i, 30 * i)
			start_positions[name] = pos
			player:set_pos(pos)
			i = i + 1
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
		local pos = players.boss:get_pos()
		assert.equals(start_positions.dude1.x, pos.x)
		assert.equals(start_positions.dude1.y - 5, pos.y)
		assert.equals(start_positions.dude1.z - 20, pos.z)
	end)

	it('invitations expire', function()
		spy.on(minetest, "chat_send_player")
		players.dude2:send_chat_message('/watchme dude1 SX')
		assert.spy(minetest.chat_send_player).was.called()
		mineunit:execute_globalstep(62)
		mineunit:execute_globalstep(62)
		players.SX:send_chat_message('/smy')
		local pos = players.SX:get_pos()
		assert.equals(start_positions.SX.x, pos.x)
		assert.equals(start_positions.SX.y, pos.y)
		assert.equals(start_positions.SX.z, pos.z)
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

