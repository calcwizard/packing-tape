
local const = {
    item_prefix = "packing-tape-",
    item_prefix_pattern = "^packing%-tape%-",
    shortcut = "packing-tape-shortcut",
    chest_types = { -- the main inventory of each chest type
        ['container'] = defines.inventory.chest,
        ['logistic-container'] = defines.inventory.chest,
        ['cargo-wagon'] = defines.inventory.cargo_wagon,
        ['car'] = defines.inventory.car_trunk,
    },
    entity_filters = {
        {filter="type",type="container"},
        {filter="type",type="logistic-container"},
        {filter="type",type="cargo-wagon"},
        {filter="type",type="car"}
    }
}

-- in case anyone is still using the old filters format
local function filters_deprecated(inventory, filters)
	for index,filter in pairs(filters) do
		inventory.set_filter(index,filter)
	end
end

-- returns the first empty item stack in this inventory that the given item
-- can be inserted into or nil if it's full
-- NOTE: This inventory slot IS NOT valid_for_read
local function find_empty_item_stack(inventory,item_spec)
	if inventory.can_insert(item_spec) then
		for i = 1,#inventory do
			if not inventory[i].valid_for_read and inventory[i].can_set_stack(item_spec) then
				return inventory[i]
			end
		end
	end
	return nil
end

local function transfer_inventory(source, destination)
    local filtered = source.is_filtered()
    local destination_filterable = destination.supports_filters()
    for i = 1, math.min(#destination, #source) do
        destination[i].transfer_stack(source[i])
        if filtered and destination_filterable then
            destination.set_filter(i, source.get_filter(i))
        end
    end
end

-- transfers items from a dictionary of items (like that returned by get_contents) into an inventory
local function transfer_simple_inventory(destination, source)
    if destination and source then
        for name,amount in pairs(source) do
            destination.insert{name=name,count=amount}
        end
    end
end

local function move_to_container(event)
    local stack = event.stack
    if stack and stack.valid_for_read and stack.name:find(const.item_prefix_pattern) then

		local chest = event.created_entity
        local item_inventory = event.stack.get_inventory(defines.inventory.item_main)
        local chest_inventory = chest.get_inventory(const.chest_types[chest.type])

        transfer_inventory(item_inventory, chest_inventory)
      
        local data = global.items[stack.item_number]
        if data then
            if data.filters then -- deprecated filter method
                filters_deprecated(item_inventory, data.filters)
            end
            if data.bar then 
                chest_inventory.set_bar(data.bar)
            end
            local proto = chest.prototype
            if proto.logistic_mode == 'storage' then
                chest.storage_filter = data.storage_filter
            elseif proto.logistic_mode == 'requester' or proto.logistic_mode == 'buffer' then
                for slot, filter in pairs(data.item_filter or {}) do
                    chest.set_request_slot(filter, slot)
                end
                chest.request_from_buffers = data.request_from_buffers
            end
            if chest.type == "car" then
                local ammo_inv = chest.get_inventory(defines.inventory.car_ammo)
                transfer_simple_inventory(ammo_inv, data.ammo)
                local fuel_inv = chest.get_inventory(defines.inventory.fuel)
                transfer_simple_inventory(fuel_inv, data.fuel)
                if data.fuel_burning and data.fuel_remaining and chest.burner  then
                    chest.burner.currently_burning = data.fuel_burning
                    chest.burner.remaining_burning_fuel = data.fuel_remaining
                end
            end
        end
        global.items[stack.item_number] = nil
    end
end

-- Move the contents from the chest into an item in our inventory
local function move_to_inventory(event)
    local chest = event.entity
    local item_name = const.item_prefix .. chest.name
    if const.chest_types[chest.type] and game.item_prototypes[item_name] then
        if chest.has_items_inside() then
            local player = game.get_player(event.player_index)
            local p_inv = player.get_main_inventory()

            -- Create an item-with-inventory in an available slot
            local stack = find_empty_item_stack(p_inv, item_name)
            -- Should have stack since we can insert but check anyway.
            if player.is_shortcut_toggled(const.shortcut) and stack and stack.set_stack(item_name) then
                -- Set health in case the chest is pre-damaged
                stack.health = chest.get_health_ratio()
                local proto = chest.prototype

                local chest_inventory = chest.get_inventory(const.chest_types[chest.type])
                local item_inventory = stack.get_inventory(defines.inventory.item_main)
                transfer_inventory(chest_inventory, item_inventory)

                -- Low overhead call
                global.items = global.items or {}
                global.items[stack.item_number] = {}
                local data = global.items[stack.item_number]

                data.bar = chest_inventory.supports_bar() and chest_inventory.get_bar()
                data.storage_filter = proto.logistic_mode == 'storage' and chest.storage_filter
                if proto.logistic_mode == 'requester' or proto.logistic_mode == 'buffer' then
                    data.item_filter = {}
                    for i = 1, chest.request_slot_count do
                        data.item_filter[i] = chest.get_request_slot(i)
                    end
                    data.request_from_buffers = chest.request_from_buffers
                end
                if chest.type == "car" then
                    local ammo_inv = chest.get_inventory(defines.inventory.car_ammo)
                    data.ammo = ammo_inv and ammo_inv.get_contents()
                    local fuel_inv = chest.get_inventory(defines.inventory.fuel)
                    data.fuel = fuel_inv and fuel_inv.get_contents()
                    if chest.burner then
                        data.fuel_burning = chest.burner.currently_burning
                        data.fuel_remaining = chest.burner.remaining_burning_fuel
                    end
                end
                chest.destroy{raise_destroy=true}
            end
        end
    end
end

function toggle_shortcut(event)
    if event.prototype_name == nil or event.prototype_name == const.shortcut then
        local player = game.get_player(event.player_index)
        player.set_shortcut_toggled(const.shortcut, not player.is_shortcut_toggled(const.shortcut))
    end
end

function unpack_item(player, item_stack)
    if item_stack.get_inventory(defines.inventory.item_main) and item_stack.get_inventory(defines.inventory.item_main).is_empty() then
        local item_prototype = item_stack.prototype
        local entity_prototype = item_prototype.place_result
        if entity_prototype and entity_prototype.type ~= "car" then -- ignore cars, they only stack to 1 anyway and have other data stored with them
            local target_items = entity_prototype.items_to_place_this --find the items that normally place this item (it should hopefully not be this item again)
            if target_items and target_items[1] then
                global.items[item_stack.item_number] = nil --remove the item from global to prevent data leaks
                item_stack.clear() --remove the item first to ensure space in the inventory for the new item
                player.insert(target_items[1])
            end            
        end
    end
end

script.on_event(defines.events.on_built_entity,move_to_container,const.entity_filters)
script.on_event(defines.events.on_pre_player_mined_item, move_to_inventory,const.entity_filters)
script.on_event({defines.events.on_lua_shortcut,"packing-tape-pickup"}, toggle_shortcut)

-- set it to toggled on when first loading
script.on_event(defines.events.on_player_created, function(event)
    game.get_player(event.player_index).set_shortcut_toggled(const.shortcut,true)
end)

script.on_event(defines.events.on_gui_closed, function(event) 
    if event.gui_type == defines.gui_type.item then
        local item = event.item
        if item and item.valid_for_read and string.find(item.name, const.item_prefix_pattern) then
            unpack_item(game.get_player(event.player_index), item)
        end
    end
end)

script.on_init(function()
	global.items = {}
end)
