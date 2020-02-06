
data:extend{
	{
		name = "packing-tape-pickup",
		type = "custom-input",
		key_sequence = "J",
		action = "lua",
	}
}

local function get_item(entity)
	local item = data.raw.item[container.minable and (container.minable.result or container.minable.results[1] or container.minable.results.name)]

	return item
end

local function is_placeable(tags)
	local flags = {["placeable-player"] = true,["player-creation"]=true}
	for _,tag in pairs(tags) do
		if flags[tag] then
			return true
		end
	end
	return false
end


--[[
local function create_pickup_chest(container)
	local item = data.raw.item[container.minable and (container.minable.result or container.minable.results[1] or container.minable.results.name)]
	if item then
		local prototype = util.table.deepcopy(item)
		prototype.name = "chest-pickup-" .. item.name
		prototype.type = "item-with-inventory"
		prototype.inventory_size = container.inventory_size
		prototype.stack_size = 1
		
		data:extend{prototype}
		log(prototype)
	end
end
]]

local function add_icons(container)
	local icons = container.icons or {{}}
	icons[1].icon = icons[1].icon or container.icon
	icons[1].icon_size = icons[1].icon_size or container.icon_size
	icons[1].icon_mipmaps = icons[1].icon_mipmaps or container.icon_mipmaps
	--local size = icons[1].icon_size
	icons[#icons+1] = {
		icon = "__packing-tape__/graphics/icons/packing-tape-50.png",
		icon_size = 64,
		scale = 0.5, --size/64,
		--shift = --{8,8},--{size/8,size/8},
	}
	return icons
end

local function create_pickup_chest(container)
	-- not_inventory_moveable is an optional flag mods can set to have their chest excluded
	if not container.not_inventory_moveable and is_placeable(container.flags or {}) then
		data:extend{
		{
			name = "packing-tape-" .. container.name,
			type = "item-with-inventory",
			localised_name = {"item-name.packing-tape",{"entity-name."..container.name}},
			icons = add_icons(container),
			stack_size = 1,
			flags = {"hidden"},
			place_result = container.name,
			inventory_size = container.inventory_size,
			order = "z[packing]-" .. (container.order or ""),
		}
	}
	end
end

local container_types = {"container","logistic-container","cargo-wagon","car"}
for _,type in pairs(container_types) do
	for _,proto in pairs(data.raw[type]) do
		create_pickup_chest(proto)
	end
end
