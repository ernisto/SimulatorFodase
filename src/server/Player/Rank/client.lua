--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local PlayerPower = require(script.Parent.Parent.Power)
local PlayerRank = require(script.Parent)

--// Trait
return Entity.trait('PlayerRank', function(self, player: Player)
    
    local playerPower = PlayerPower.get(player)
    local rank = PlayerRank.get(player)
    
    --// Client
    local client = Replicator.get(self.roblox)
    
    function client.RankUp(player)
        
        playerPower:consume(rank.requiredPower)
        rank:rankup()
    end
end)