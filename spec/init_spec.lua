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

