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
    self.cooldown = 4/4
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
    
    local autoclick: thread?
    function self:toggleAutoclick(isToggled: boolean)
        
        if autoclick then autoclick = task.cancel(autoclick) end
        if not isToggled then return end
        
        autoclick = self:_host(task.spawn(function()
            
            repeat self:add(task.wait(self.cooldown)) until false
        end))
    end
end)