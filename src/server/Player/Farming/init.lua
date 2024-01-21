--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

--// Trait
return Entity.trait('PlayerFarming', function(self, player: Player)
    
    self.isAutoclickToggled = false
    self.cooldown = 4/4
    
    --// Signals
    self.mobKilled = self:_signal('mobKilled')
    self.clicked = self:_signal('clicked')
    
    --// Methods
    function self:click()
        
        self.clicked:_emit()
    end
    
    local cooldownFinish = 0
    function self:consumeCooldown()
        
        assert(os.clock() > cooldownFinish, `in cooldown`)
        cooldownFinish = os.clock() + self.cooldown
    end
    
    local autoclick: thread?
    function self:toggleAutoclick(isToggled: boolean)
        
        self.isAutoclickToggled = isToggled
        
        if autoclick then autoclick = task.cancel(autoclick) end
        if not isToggled then return end
        
        local quotient = 0
        autoclick = self:_host(task.spawn(function()
            
            repeat
                quotient += task.wait(self.cooldown - quotient)
                for _ = 1, quotient // self.cooldown do self:click() end
                
                quotient %= self.cooldown
            until false
        end))
    end
end)