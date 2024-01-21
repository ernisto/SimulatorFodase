--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Booster = require(game.ServerScriptService.Booster)

local PlayerProfile = require(script.Parent.Profile)
local PlayerFarming = require(script.Parent.Farming)

--// Data
local awaitData = PlayerProfile.subData('Power', {
    basePower = 0,
})

--// Trait
return Entity.trait('PlayerPower', function(self, player: Player, syncs: { basePower: number })
    
    local farming = PlayerFarming.get(player)
    
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
    
    --// Listeners
    farming.clicked:connect(function() self:add(1) end)
end)