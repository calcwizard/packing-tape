
data:extend{
	{
		name = "packing-tape-pickup",
		type = "custom-input",
		key_sequence = "J",
		action = "lua",
		localised_name = {"shortcut-name.packing-tape-shortcut"},
	},
	{
		name = "packing-tape-shortcut",
		type = "shortcut",
		action = "lua",
		associated_control_input = "packing-tape-pickup",
		toggleable = true,
		icon = {
			filename = "__packing-tape__/graphics/icons/shortcut.png",
			priority = "extra-high-no-scale",
			size = 200,
			scale = 1,
			flags = {"icon"},
		},
		--[[disabled_icon = {
			filename = "__packing-tape__/graphics/icons/shortcut.png",
			priority = "extra-high-no-scale",
			size = 32,
			scale = 1,
			flags = {"icon"},
		},]]
	}
}
