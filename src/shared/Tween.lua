--// Packages
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

--// Module
local Tween = {}

local function lerp(init, goal, fade)
    
    return if typeof(init) == 'number' then init + (goal-init)*fade else init:Lerp(goal, fade)
end

--// Functions
function Tween.tweenAsync(init: number, goal: number, info: TweenInfo, callback: (n: number) -> ())
    
    return Promise.try(function()
        
        local fade = 0
        repeat fade += task.wait()/info.Time
            if fade > 1 then fade = 1 end
            
            callback(lerp(init, goal, TweenService:GetValue(fade, info.EasingStyle, info.EasingDirection)))
        until fade == 1
    end)
end

--// End
return Tween