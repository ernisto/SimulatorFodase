--// Packages
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cache = require(ReplicatedStorage.Packages.Cache)

--// Vars
local animators = Cache.async(-1, 'k')

--// Component
return function(_humanoid: Humanoid?)
    
    local humanoid = _humanoid or localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    
    return animators:findFirstPromise(humanoid) or animators:promise(function(resolve)
        
        local animator; repeat animator = humanoid:FindFirstChildWhichIsA("Animator")
        until animator or not humanoid.ChildAdded:Wait()
        
        --// Instance
        local self = {}
        local tracks = Cache.new(-1)
        
        --// Methods
        function self:getTrack(animation: Animation): AnimationTrack
            
            return tracks:find(animation.AnimationId)
            or tracks:set(animator:LoadAnimation(animation),
                animation.AnimationId
            )
        end
        
        resolve(self)
    end, humanoid)
end