--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerMarket = require(script.Parent.Parent.Market)
local PlayerPower = require(script.Parent)

--// Trait
return Entity.trait('PlayerPower', function(self, player: Player)
    
    local power = PlayerPower.get(player)
    local market = PlayerMarket.get(player)
    
    self.FastAutoClick = self:_host(market:getPass(690138579))
    self.MegaAutoClick = self:_host(market:getPass(690148531))
    self.DoublePower = self:_host(market:getPass(691785026))
    
    --// Binders
    self.FastAutoClick:bind(function()
        
        power.cooldown = math.min(power.cooldown, 2/4)
    end)
    self.MegaAutoClick:bind(function()
        
        power.cooldown = math.min(power.cooldown, 1/4)
    end)
    self.DoublePower:bind(function()
        
        power.boost:add('gamepass', 1.00)
    end)
end)