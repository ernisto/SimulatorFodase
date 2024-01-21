--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)

--// Trait
return Entity.trait('PlayerItemSummon', function(self, player)
    
    self.luckBoost = self:_host(Booster.new('luck'))
    self.cooldown = 5
    
    --// Methods
    local cooldownFinish = 0
    function self:consumeCooldown()
        
        assert(os.clock() > cooldownFinish, `in cooldown`)
        cooldownFinish = os.clock() + self.cooldown
    end
end)