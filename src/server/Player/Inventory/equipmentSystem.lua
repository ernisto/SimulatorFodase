--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)

local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Equipment = require(game.ServerScriptService.Inventory.Item.Equipment)
local PlayerInventory = require(script.Parent)

--// Trait
return Entity.trait('PlayerInventory', function(self, player: Player)
    
    local inventory = PlayerInventory.get(player)
    local client = Replicator.get(self.roblox)
    local data = inventory.data
    
    --// Remotes
    function client.ToggleEquip(_, itemEntity: Instance)
        
        assert(itemEntity:IsDescendantOf(player), `permission denied`)
        local equipment = Equipment.Equipment.find(itemEntity) or error(`this item cannot be equipped`)
        
        if equipment.isEquipped then
            
            data.equippedAmounts[itemEntity.Name] = -1 + (data.equippedAmounts[itemEntity.Name] or 0)
            equipment:unequip()
        else
            
            if #inventory.equippeds[equipment.slot] < inventory.slotLimits[equipment.slot] then
                
                data.equippedAmounts[itemEntity.Name] = 1 + (data.equippedAmounts[itemEntity.Name] or 0)
            end
            equipment:forkEquipped(assert(player.Character :: any).Humanoid)
        end
    end
    
    --// Listeners
    local function equipAll(character: Model & { Humanoid: Humanoid })
        
        local hasBeenEquippeds = {}
        for _,entity in self.roblox:GetChildren() do
            
            if entity:HasTag('Equipped') then hasBeenEquippeds[entity.Name] = 1 + (hasBeenEquippeds[entity.Name] or 0) end
        end
        
        for name, amount in inventory.equippedAmounts do
            
            local beenEquipped = hasBeenEquippeds[name] or 0
            
            for item in inventory.items do
                
                local equipment = Equipment.Equipment.find(item.roblox)
                if not equipment then continue end
                
                if item.name ~= name then continue end
                local itemAmount = item.amount
                
                for i = beenEquipped+1, math.min(itemAmount, amount) do equipment:forkEquipped(character.Humanoid) end
                beenEquipped += itemAmount
            end
        end
    end
    player.CharacterAdded:Connect(equipAll :: any)
    equipAll(player.Character :: any)
end)