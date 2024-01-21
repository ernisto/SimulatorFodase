--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local FarmingMarket = require(script.Parent.market)
local PlayerFarming = require(script.Parent)

--// Trait
return Entity.trait('PlayerFarming', function(self, player: Player)
    
    local farming = PlayerFarming.get(player)
    local market = FarmingMarket.get(player)
    local client = Replicator.get(self.roblox)
    
    function client.Click(player)
        
        farming:consumeCooldown()
        farming:click()
    end
    function client.AutoClick(player, isToggled: boolean)
        
        market.FastAutoClick:expect()
        farming:toggleAutoclick(isToggled)
    end
end)