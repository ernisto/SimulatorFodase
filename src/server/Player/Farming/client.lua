--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local FarmingMarket = require(script.Parent.market)
local PlayerFarming = require(script.Parent)

--// Consts
local GROUP_ID = 33720963

--// Trait
return Entity.trait('PlayerFarming', function(self, player: Player)
    
    local farming = PlayerFarming.get(player)
    local market = FarmingMarket.get(player)
    local client = Replicator.get(self.roblox)
    
    --// Remotes
    function client.Click(player)
        
        farming:consumeCooldown()
        farming:click()
    end
    function client.AutoClick(player, isToggled: boolean)
        
        assert(self:canAutoClick(), `you havent auto clicker\njoin in the group or purchase one`)
        farming:toggleAutoclick(isToggled)
    end
    
    --// Methods
    function self:canAutoClick()
        
        return player:IsInGroup(GROUP_ID)
            or market.FastAutoClick.isOwned
            or market.MegaAutoClick.isOwned
    end
end)