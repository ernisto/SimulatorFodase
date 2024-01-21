--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local PlayerPower = require(script.Parent.Power)

--// Trait
return Entity.trait('PlayerFarming', function(self, player: Player)
    
    local power = PlayerPower.get(player)
    
    self.cooldown = 4/4
    
    --// Methods
    local cooldownFinish = 0
    function self:consumeCooldown()
        
        assert(os.clock() > cooldownFinish, `in cooldown`)
        cooldownFinish = os.clock() + self.cooldown
    end
    
    local autoclick: thread?
    function self:toggleAutoclick(isToggled: boolean)
        
        if autoclick then autoclick = task.cancel(autoclick) end
        if not isToggled then return end
        
        autoclick = self:_host(task.spawn(function()
            
            repeat power:add(task.wait(self.cooldown)) until false
        end))
    end
end)