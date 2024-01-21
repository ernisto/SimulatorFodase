--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)

--// Trait
return Entity.trait('PlayerItemSummon', function(self, player)
    
    self.luckBoost = self:_host(Booster.new('luck'))
end)