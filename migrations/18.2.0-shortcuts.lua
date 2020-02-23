
local shortcut = "packing-tape-shortcut"

for _,player in pairs(game.players) do
    player.set_shortcut_toggled(shortcut, true)
end