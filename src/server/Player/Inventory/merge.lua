--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Mergeble = require(game.ServerScriptService.Inventory.Item.Mergeble)

local Item = require(game.ServerScriptService.Inventory.Item)
type Item = Item.Item

local PlayerInventory = require(script.Parent)

Entity.query{ tag='ItemGiver' }:track(function(prompt)
    
    prompt.Triggered:Connect(function(player)
        
        local item = Item.new{ name='Cavalo' }
        PlayerInventory.get(player):addItem(item)
    end)
end)

--// Trait
return Entity.trait('PlayerInventory', function(self, player)
    
    local inventory = PlayerInventory.get(player)
    local client = Replicator.get(self.roblox)
    
    --// Functions
    local function consumeItems(consumptionGoal: number, items: {Item})
        
        local rest = table.clone(items)
        local remaining = consumptionGoal
        
        for _,item in items do
            
            local consumption = math.min(item.amount, remaining)
            remaining -= consumption
            
            item:consume(consumption)
            if not next(item) or item.amount == 0 then table.remove(rest, table.find(rest, item)) end -- if has destroyed
            if remaining == 0 then break end
        end
        return rest
    end
    function client.Merge(player, baseItemEntity: Mergeble.entity,...: Mergeble.entity)
        
        local baseItem = Item.find(baseItemEntity) or error(`entity #1 isnt a Item`)
        local baseMergeble = Mergeble.find(baseItemEntity) or error(`entity #1 cant merge`)
        local level = baseMergeble.level
        local name = baseItem.name
        
        local consumingItems = {}
        local totalAmount = 0
        
        for index, entity in {baseItemEntity,...} do
            
            local item = Item.find(entity) or error(`entity #{index} isnt a Item`)
            local mergeble = Mergeble.find(entity) or error(`item #{index} cant merge`)
            assert(mergeble.level == level, `item items must to be the same level`)
            assert(item.name == name, `all items must to be the same kind`)
            
            totalAmount += item.amount
            table.insert(consumingItems, item)
            
            local requirement = mergeble.mergeRequirement
            while totalAmount >= requirement do
                
                inventory:addItem(
                    Item.new{ name = item.name, level=mergeble.level + 1 }
                )
                consumingItems = consumeItems(requirement, consumingItems)
                totalAmount -= requirement
            end
        end
    end
end)