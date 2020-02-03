
const = {
	name = {
		item_prefix = "packing-tape-"
	}
}




function item_to_chest(item, chest)
	local chest_inventory = chest.get_inventory(defines.inventory.chest)
	local item_inventory = item.get_inventory(defines.inventory.item_main)
		
	local item_num = item.item_number
	for index,filter in pairs(global.items[item_num] and global.items[item_num].filters or {}) do
		chest_inventory.set_filter(index,filter)
	end

	for i=1,#item_inventory do
		chest_inventory.insert(item_inventory[i])
	end

	if global.items[item_num] then	
		-- paste entity settingsr
		if chest.prototype.logistic_mode == "storage" then
			chest.storage_filter = global.items[item_num].storage_filter
		elseif chest.prototype.logistic_mode == "requester" or chest.prototype.logistic_mode == "buffer" then
			for slot,filter in pairs(global.items[item_num].item_filter or {}) do
				chest.set_request_slot(filter,slot) 
			end
			chest.request_from_buffers = global.items[item_num].request_from_buffers
		end
		if global.items[item_num].bar then
			chest_inventory.set_bar(global.items[item_num].bar)
		end
	end
	 
	global.items[item.item_number] = nil

end

function chest_to_item(chest, item)
	local chest_inventory = chest.get_inventory(defines.inventory.chest)
	local item_inventory = item.get_inventory(defines.inventory.item_main)
	
	local item_num = item.item_number
	global.items[item_num] = {filters = {} }
	local is_filtered = chest_inventory.is_filtered()
	for i=1,#chest_inventory do
		item_inventory.insert(chest_inventory[i])
		if is_filtered then
			global.items[item_num].filters[i] = chest_inventory.get_filter(i)
		end
	end

	-- copy entity settings
	if chest.prototype.logistic_mode == "storage" then
		global.items[item.item_number].storage_filter = chest.storage_filter
	elseif chest.prototype.logistic_mode == "requester" or chest.prototype.logistic_mode == "buffer" then
		local item_num = item.item_number
		global.items[item_num].item_filter = {}
		for i = 1,chest.request_slot_count do
			global.items[item_num].item_filter[i] = chest.get_request_slot(i)
		end
		global.items[item_num].request_from_buffers = chest.request_from_buffers
	end
	global.items[item_num].bar = chest_inventory.supports_bar() and chest_inventory.get_bar()
end

function packing_tape(player, chest)
	if chest then
		if game.item_prototypes[const.name.item_prefix .. chest.name] then
			player.clean_cursor()
			if player.cursor_stack and player.cursor_stack.set_stack{name=const.name.item_prefix..chest.name} then
				chest_to_item(chest, player.cursor_stack)
				chest.destroy()
			end
		end
	end
end

script.on_event(defines.events.on_built_entity,function(event)
	if event.item and string.find(event.item.name,const.name.item_prefix,1,true) then
		item_to_chest(event.stack,event.created_entity)
	end
end,{{filter="ghost",invert=true}})

script.on_event("packing-tape-pickup", function(event)
	local player = game.get_player(event.player_index)
	local chest = player.selected
	packing_tape(player,chest)
end)

script.on_event(defines.events.on_pre_player_mined_item, function(event)
	packing_tape(game.get_player(event.player_index), event.entity)
end)

script.on_init(function(event)
	global.items = {}
end)
