--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

--// Trait
return Entity.trait('PlayerCharacter', function(self, entity)
    
    for _,part in entity:GetDescendants() do
        
        if part:IsA('BasePart') then part.CollisionGroup = 'Characters' end
    end
end)