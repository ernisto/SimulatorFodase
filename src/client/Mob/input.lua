--// Packages
local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService('UserInputService')

local Gameplay = require(game.ReplicatedStorage.Client.Gameplay)
local haptic = require(game.ReplicatedStorage.Shared.EZHaptic)

local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Mob = require(script.Parent)

--// Trait
return Entity.trait('Mob', function(self, model: Mob.entity)
    
    local mob = Mob.get(model)
    local proximity = mob.Proximity
    
    --// Functions
    local function attack(inputType: Enum.UserInputType, keyCode: Enum.KeyCode?)
        
        mob:requestAttackAsync()
            :catch(Gameplay.error)
            :expect()
        
        --// Haptic
        local intensity = if self.health <= 0 then 1.00 else 0.50
        local motor = if keyCode == Enum.KeyCode.ButtonL2 then Enum.VibrationMotor.LeftTrigger
            elseif keyCode == Enum.KeyCode.ButtonR2 then Enum.VibrationMotor.RightTrigger
            else Enum.VibrationMotor.Large
        
        haptic{ device=inputType, motor=motor, intensity=intensity }
    end
    
    --// Listeners
    local function clickHandler(_,state, input: InputObject)
        
        if state ~= Enum.UserInputState.Begin then return end
        attack(input.UserInputType, input.KeyCode)
    end
    
    --// Input
    proximity.Triggered:Connect(function() attack(UserInputService:GetLastInputType()) end)
    proximity.PromptShown:Connect(function()
        
        mob:requestPickupDropsAsync()
        
        if mob.health <= 0 then return end
        mob:focus()
        
        --// Input
        ContextActionService:BindAction('AttackMob', clickHandler, false,
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch,
            Enum.KeyCode.ButtonL2,
            Enum.KeyCode.ButtonR2
        )
        mob.unfocused:once(function()
            
            ContextActionService:UnbindAction('AttackMob')
        end)
        
        --// Cleaner
        proximity.PromptHidden:Wait()
        mob:unfocus()
    end)
end)