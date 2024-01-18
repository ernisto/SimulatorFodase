--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Equipment = require(script.Parent)

--// Trait
return Entity.trait('Equipment', function(self, entity: Equipment.entity)
    
    local equipment = Equipment.Equipment.get(entity)
    local client = Replicator.get(entity)
    
    function client.Equip(player)
        
        if equipment.isEquipped then equipment:unequip()
        else equipment:equip(player.Character.Humanoid) end
    end
end)