--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerMarket = require(script.Parent.Parent.Market)
local PlayerPower = require(script.Parent)

--// Trait
return Entity.trait('PlayerPower', function(self, player: Player)
    
    local power = PlayerPower.get(player)
    local market = PlayerMarket.get(player)
    
    self.DoublePower = self:_host(market:getPass(691785026))
    
    --// Binders
    self.DoublePower:bind(function()
        
        power.boost:add('gamepass', 1.00)
    end)
end)