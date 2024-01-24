--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local WorldBloodline = require(script.Parent)

--// Trait
return Entity.trait('WorldBloodline', function(self, entity)
    
    local bloodline = WorldBloodline.get(entity)
    local client = Replicator.get(entity)
    
    function client.Roll(player)
        
        return bloodline:roll()
    end
end)