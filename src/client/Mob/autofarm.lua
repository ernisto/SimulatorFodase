--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local LocalFarming = require(game.ReplicatedStorage.Client.LocalFarming)

local Mob = require(script.Parent)

--// Trait
return Entity.trait('Mob', function(self, model)
    
    local mob = Mob.get(model)
    
    task.spawn(function() while task.wait() do
        
        if not LocalFarming.isAutoclickToggled then continue end
        if not mob.isFocused then continue end
        
        mob:requestAttackAsync():await()
        task.wait(LocalFarming.cooldown)
    end end)
end)