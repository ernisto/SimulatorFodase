--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)
local PlayerProfile = require(script.Parent.Profile)

--// Data
local awaitData = PlayerProfile.subData('Currency', {
    amount = 0
})

--// Trait
return Entity.trait('PlayerCurrency', function(self, player: Player)
    
    --// Data
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    self.boost = self:_host(Booster.new('moneyBooster'))
    
    --// Methods
    function self:add(amount: number, ignoreBoost: 'ignore boost'?)
        
        if not ignoreBoost then amount *= self.boost:get() end
        self.amount += amount
    end
    function self:consume(amount: number)
        
        assert(self.amount >= amount, `not enough money`)
        self.amount -= amount
    end
end)