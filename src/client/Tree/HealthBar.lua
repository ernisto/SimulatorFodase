--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HealthBar = ReplicatedStorage.Assets.TreeHealthbar
local wrapper = require(ReplicatedStorage.Packages.Wrapper)
local Tween = require(ReplicatedStorage.Shared.Tween)

--// Factory
type params = { name: string, level: number, health: number, maxHealth: number, healthChanged: any }
return function(params: params)
    
    local healthbar = HealthBar:Clone()
    local self = wrapper(healthbar)
    local bar = healthbar.holder["hpbg-seprecisar"].hpfull
    local tween: any? -- promise
    
    bar.Size = UDim2.fromScale(params.health/params.maxHealth, 1.00)
    healthbar.holder.value.Text = `{math.ceil(params.health)}/{params.maxHealth}`
    healthbar.holder.namebg.name.Text = params.name
    healthbar.holder.namebg.lvl.Text = params.level
    
    --// Listeners
    local healthUpdater = params.healthChanged:connect(function(health)
        
        bar.Size = UDim2.fromScale(health/params.maxHealth, 1.00)
        healthbar.holder.value.Text = `{math.ceil(health)}/{params.maxHealth}`
    end)
    self:_host(healthUpdater)
    
    --// Method
    function self:awaitHide()
        
        if tween then tween:cancel() end
        
        local info = TweenInfo.new(.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
        local lTween = Tween.tweenAsync(healthbar.holder.Size.X.Scale, 0.00, info, function(width)
            
            healthbar.holder.Size = UDim2.fromScale(width, 1.00)
        end)
        self:_host(lTween)
        tween = lTween
        
        return lTween:await() and self
    end
    function self:show()
        
        if tween then tween:cancel() end
        
        local info = TweenInfo.new(.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
        local lTween = Tween.tweenAsync(healthbar.holder.Size.X.Scale, 1.00, info, function(width)
            
            healthbar.holder.Size = UDim2.fromScale(width, 1.00)
        end)
        self:_host(lTween)
        tween = lTween
        
        return self
    end
    
    --// End
    return self:show()
end