--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerMarket = require(script.Parent.Parent.Market)
local PlayerFarming = require(script.Parent)

--// Trait
return Entity.trait('PlayerFarming', function(self, player: Player)
    
    local farming = PlayerFarming.get(player)
    local market = PlayerMarket.get(player)
    
    self.FastAutoClick = self:_host(market:getPass(690138579))
    self.MegaAutoClick = self:_host(market:getPass(690148531))
    
    --// Binders
    self.FastAutoClick:bind(function()
        
        farming.cooldown = math.min(farming.cooldown, 2/4)
    end)
    self.MegaAutoClick:bind(function()
        
        farming.cooldown = math.min(farming.cooldown, 1/4)
    end)
end)