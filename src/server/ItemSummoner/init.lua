--// Packages
local RandomOption = require(game.ReplicatedStorage.Packages.RandomOption)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerInventory = require(game.ServerScriptService.Player.Inventory)
local PaidPrompt = require(game.ServerScriptService.PaidPrompt)
local Item = require(game.ServerScriptService.Inventory.Item)

--// Types
export type entity = Model & {
    DropRates: Folder,
    PrimaryPart: BasePart & {
        Roll1: ProximityPrompt,
        Roll3: ProximityPrompt,
    }
}

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local rootPart = model.PrimaryPart
    local randomItemName = RandomOption.new(model.DropRates:GetAttributes())
    
    --// Methods
    function self:roll3(player)
        
        for count = 1, 3 do self:roll1(player) end
    end
    function self:roll1(player)
        
        local inventory = PlayerInventory.get(player)
        local itemName = randomItemName:choice()
        local item = Item.new{ name=itemName }
        
        inventory:addItem(item)
    end
    
    --// Prompts
    PaidPrompt.get(rootPart.Roll1)
        .activated:connect(function(player) self:roll1(player) end)
    
    PaidPrompt.get(rootPart.Roll3)
        .activated:connect(function(player) self:roll3(player) end)
end)