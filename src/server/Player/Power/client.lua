--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerPower = require(script.Parent)
local PowerMarket = require(script.Parent.market)

--// Trait
return Entity.trait('PlayerPower', function(self, player: Player)
    
    local power = PlayerPower.get(player)
    local market = PowerMarket.get(player)
    local client = Replicator.get(self.roblox)
    
    function client.Click(player)
        
        power:add(1)
    end
    function client.AutoClick(player, isToggled: boolean)
        
        market.FastAutoClick:expect()
        power:toggleAutoclick(isToggled)
    end
end)