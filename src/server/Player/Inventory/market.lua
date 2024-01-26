--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerMarket = require(script.Parent.Parent.Market)
local PlayerInventory = require(script.Parent)

--// Trait
return Entity.trait('PlayerInventory', function(self, player: Player)
    
    local inventory = PlayerInventory.get(player)
    local market = PlayerMarket.get(player)
    
    self.SmallStorage = self:_host(market:getPass(691785026))
    self.BigStorage = self:_host(market:getPass(691785026))
    self.EquipSlot = self:_host(market:getPass(691785026))
    
    --// Binders
    self.EquipSlot:bind(function() inventory.limitSlots.Pets += 3 end)
end)