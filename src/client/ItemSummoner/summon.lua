--// Packages
local LocalAnimator = require(game.ReplicatedStorage.Client.LocalCharacter.Animator)
local Collector = require(game.ReplicatedStorage.Packages.Collector)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Spring = require(game.ReplicatedStorage.Packages.Spring)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local emitAll = require(game.ReplicatedStorage.Shared.EmitAll)
local ItemSummoner = require(script.Parent)

local GainedParticle = game.ReplicatedStorage.Assets.Particles.ItemGained
export type entity = ItemSummoner.entity

--// Consts
local PETS_PADDING = math.pi/7

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local itemSummoner = ItemSummoner.get(model)
    local animator = LocalAnimator(model:FindFirstChildOfClass('Humanoid')):expect()
    local summonAnimation = animator:getTrack(script.Parent.SummonAnimation) :: AnimationTrack
    
    local originalColor = model.Star.Color
    local brightColor = model.Star:GetAttribute('LightColor')
    
    local lastTrash
    itemSummoner.itemSummoned:connect(function(petNames: {string})
        
        local trash = Collector{ lifetime=10 }
        
        --// Animation
        summonAnimation:Play()
        Spring.target(model.Star, 1.00, 30, { Color = brightColor })
        
        local emittions = trash:sub()
        for _,particle in model.Star.Particles:GetChildren() do
            
            if not particle:IsA('ParticleEmitter') then continue end
            Spring.target(particle, 1.00, 30, { Rate = particle:GetAttribute('Rate') })
            
            if particle:GetAttribute('EmitCount') then
                
                emittions:add(task.delay(particle:GetAttribute('EmitDelay'), function() particle:Emit(particle:GetAttribute('EmitCount')) end))
            end
        end
        
        --// Finish
        Promise.some({ Promise.fromEvent(summonAnimation.Stopped), Promise.try(function() itemSummoner.animationSkipped:await() end) }, 1):await()
        emittions:collect()
        
        if lastTrash then lastTrash:destroy() end
        lastTrash = trash
        
        summonAnimation:Stop()
        Spring.stop(model.Star)
        
        self:_renderItems(trash, petNames)
        model.Star.Color = originalColor
        
        for _,particle in model.Star.Particles:GetChildren() do
            
            if not particle:IsA('ParticleEmitter') then continue end
            Spring.stop(particle)
            particle.Rate = 0
        end
    end)
    function self:_renderItems(trash, petNames: {string})
        
        local playerPosition = game.Players.LocalPlayer.Character.PrimaryPart.Position
        local selfPosition = model.PrimaryPart.Position
        local position = Vector3.new(selfPosition.X, playerPosition.Y, selfPosition.Z)
        
        local range = PETS_PADDING * (#petNames-1)
        local rotation = CFrame.Angles(0, -range/2, 0)
        
        for count, petName in petNames do
            
            local petModel = game.ReplicatedStorage.Assets.Items[petName].Model:Clone() :: Model
            local originalScale = petModel:GetScale()
            local rootPart = petModel.PrimaryPart
            petModel.Parent = workspace
            
            local highlight = Instance.new('Highlight', petModel)
            highlight.FillColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 1.00
            highlight.FillTransparency = 0.00
            
            petModel:ScaleTo(0.50)
            rootPart.CFrame = CFrame.lookAt(position, playerPosition)
                * rotation * CFrame.Angles(0, PETS_PADDING * (count-1), 0)
                * CFrame.new(0, 50, -10)
            
            Spring.target(rootPart, 1.00, 10, { CFrame = rootPart.CFrame - Vector3.new(0, 52, 0) })
            Spring.target(petModel, 1.00, 10, { Scale = 0.80 })
            Spring.completed(rootPart, function()
                
                if trash.hasCollected then petModel:Destroy(); return end
                
                Spring.target(highlight, 1.00, 10, { FillTransparency = 1.00 })
                Spring.target(petModel, 0.80, 10, { Scale = originalScale })
                
                local particle = GainedParticle:Clone()
                particle.Parent = rootPart
                emitAll(particle)
                
                trash:add(function()
                    
                    Spring.target(petModel, 2.00, 5, { Scale = 1, Pivot = rootPart.CFrame - Vector3.new(0, 3, 0) })
                    Spring.completed(petModel, function() petModel:Destroy() end)
                end)
            end)
        end
    end
end)