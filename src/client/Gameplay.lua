--// Packages
local UserInputService = game:GetService("UserInputService")
local notify = require(script.Parent:WaitForChild("notify"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local haptic = require(ReplicatedStorage.Shared.EZHaptic)

--// Module
local Gameplay = {}

--// Functions
function Gameplay.error(message: string, intensity: number?)
    
    notify(message, Color3.new(1, .3, .4))
    haptic{ device=UserInputService:GetLastInputType(), motor=Enum.VibrationMotor.Small, intensity=intensity }
    error(message)
end
function Gameplay.assert<value>(value: value, message: string, intensity: number?): value
    
    return value or Gameplay.error(message, intensity)
end

--// End
return Gameplay