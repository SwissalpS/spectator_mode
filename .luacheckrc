--unused_args = false
--allow_defined_top = true

globals = {
	player_api = { fields = { "player_attached" } },
}

read_globals = {
	-- Stdlib
	table = { fields = { "copy" } },

	-- Minetest
	"minetest",
	"vector",

}
