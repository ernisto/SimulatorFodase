--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerMarket = require(script.Parent.Parent.Market)
local PlayerCurrency = require(script.Parent)

--// Trait
return Entity.trait('PlayerCurrency', function(self, player: Player)
    
    local currency = PlayerCurrency.get(player)
    local market = PlayerMarket.get(player)
    
    self.DoublePower = self:_host(market:getPass(690374063))
    
    --// Binders
    self.DoublePower:bind(function()
        
        currency.boost:add('gamepass', 1.00)
    end)
end)