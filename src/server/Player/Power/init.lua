--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)
local PlayerProfile = require(script.Parent.Profile)

--// Data
local awaitData = PlayerProfile.subData('Power', {
    basePower = 0,
})

--// Trait
return Entity.trait('PlayerPower', function(self, player: Player, syncs: { basePower: number })
    
    --// Data
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    self.boost = self:_host(Booster.new('powerBooster'))
    self.bonus = 0
    
    --// Methods
    function self:addBonus(bonus: number)
        
        self.bonus += bonus
    end
    function self:add(amount: number, ignoreBoost: 'ignore boost'?)
        
        if not ignoreBoost then
            
            amount *= self.boost:get()
            amount += self.bonus
        end
        self.basePower += amount
    end
    function self:consume(amount: number)
        
        assert(self.basePower >= amount, `not enough power`)
        self.basePower -= amount
    end
end)