require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

-- mimic player_api.player_attached
fixture('player_api')

function vector.copy(v) return { x = v.x or 0, y = v.y or 0, z = v.z or 0 } end

function vector.zero() return { x = 0, y = 0, z = 0 } end

function Player:hud_get_flags()
	return self._hud_flags or { hotbar = true, healthbar = true, crosshair = true,
		wielditem = true, breathbar = true, minimap = false, minimap_radar = false }
end
function Player:hud_set_flags(new_flags)
	if not self._hud_flags then self._hud_flags = self:hud_get_flags() end
	for flag, value in pairs(new_flags) do if nil ~= self._hud_flags[flag] then self._hud_flags[flag] = not not value end end
end

function ObjectRef:get_nametag_attributes()
	if not self._nametag_attributes then self._nametag_attributes = {
		text = self._nametag_text or '',
		color = self._nametag_color or { a = 255, r = 255, g = 255, b = 255 },
		bgcolor = self._nametag_bgcolor or { a = 0, r = 0, g = 0, b = 0 },
	}
	end
	return self._nametag_attributes
end

function Player:set_eye_offset(firstperson, thirdperson)
	self._eye_offset_first =
		firstperson and vector.copy(firstperson) or vector.zero()

	thirdperson = thirdperson and vector.copy(thirdperson) or vector.zero()
	thirdperson.x = math.max(-10, math.min(10, thirdperson.x))
	thirdperson.y = math.max(-10, math.min(15, thirdperson.y))
	thirdperson.z = math.max(-5, math.min(5, thirdperson.z))
	self._eye_offset_third = thirdperson
end

function ObjectRef:set_nametag_attributes(new_attributes)
	if not self._nametag_attributes then self:get_nametag_attributes() end
	for key, value in pairs(new_attributes) do
		if nil ~= self._nametag_attributes[key] then
			if 'name' == key then
				self._nametag_attributes.name = tostring(value)
			else
				for subkey, subvalue in pairs(new_attributes[key]) do
					if nil ~= self._nametag_attributes[key][subkey] then
						self._nametag_attributes[key][subkey] = tonumber(subvalue)
					end
				end
			end
		end
	end
end

function ObjectRef:set_attach(parent, bone, position, rotation, forced_visible)
	if not parent then return end
	if self._attach and self._attach.parent == parent then
		mineunit:info('Attempt to attach to parent that object is already attached to.')
		return
	end
	-- detach if attached
	self:set_detach()
	local obj = parent
	while true do
		if not obj._attach then break end
		if obj._attach.parent == self then
			mineunit:warning('Mod bug: Attempted to attach object to an object that '
				.. 'is directly or indirectly attached to the first object. -> '
				.. 'circular attachment chain.')
			return
		end
		obj = obj._attach.parent
	end
	mineunit:info(parent._children)
	if 'table' ~= type(parent._children) then parent._children = {} end
	mineunit:info(parent._children)
	table.insert(parent._children, self)
	self._attach = {
		parent = parent,
		bone = bone or '',
		position = position or vector.zero(),
		rotation = rotation or vector.zero(),
		forced_visible = not not forced_visible,
	}
	self:set_pos(vector.add(parent:get_pos(), self._attach.position))
	-- TODO: apply rotation
end
function ObjectRef:get_attach()
	return self._attach
end
function ObjectRef:get_children()
	return self._children or {}
end
function ObjectRef:set_detach()
	if not self._attach then return end
	local new_children = {}
	for _, child in ipairs(self._attach.parent._children) do
		if child ~= self then table.insert(new_children, child) end
	end
	self._attach.parent._children = new_children
	self._attach = nil
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

