--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)
local PlayerProfile = require(script.Parent.Profile)

--// Data
local awaitData = PlayerProfile.subData('ItemSummon', {
    bonus = 0
})

--// Trait
return Entity.trait('PlayerItemSummon', function(self, player)
    
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    self.luckBoost = self:_host(Booster.new('luck'))
    self.cooldown = 5
    
    --// Signals
    self.itemSummoned = self:_signal('itemSummoned')
    
    --// Methods
    local cooldownFinish = 0
    function self:consumeCooldown()
        
        assert(os.clock() > cooldownFinish, `in cooldown`)
        cooldownFinish = os.clock() + self.cooldown
    end
end)