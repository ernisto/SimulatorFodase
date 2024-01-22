--// Packages
local LocalAnimator = require(game.ReplicatedStorage.Client.LocalCharacter.Animator)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Spring = require(game.ReplicatedStorage.Packages.Spring)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local ItemSummoner = require(script.Parent)

export type entity = ItemSummoner.entity

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local itemSummoner = ItemSummoner.get(model)
    local animator = LocalAnimator(model:FindFirstChildOfClass('Humanoid')):expect()
    local summonAnimation = animator:getTrack(script.Parent.SummonAnimation) :: AnimationTrack
    
    local trash = {}
    itemSummoner.itemSummoned:connect(function(...: Folder)
        
        for v in trash do if typeof(v) == 'Instance' then v:Destroy() elseif typeof(v) == 'thread' then task.cancel(v) end end
        trash = {}
        
        --// Animation
        summonAnimation:Play()
        Spring.target(model.Star, 1.00, 30,
            { Color = Color3.fromRGB(253, 234, 141) }
        )
        for _,particle in model.Star.Particles:GetChildren() do
            if not particle:IsA('ParticleEmitter') then continue end
            Spring.target(particle, 1.00, 30, { Rate = particle:GetAttribute('Rate') })
        end
        self:_renderPets({...})
        
        --// Finish
        Promise.some({ Promise.fromEvent(summonAnimation.Stopped), Promise.try(function() itemSummoner.animationSkipped:await() end) }, 1):await()
        summonAnimation:Stop()
        
        Spring.stop(model.Star)
        model.Star.Color = Color3.fromRGB(105, 64, 40)
        
        for _,particle in model.Star.Particles:GetChildren() do
            if not particle:IsA('ParticleEmitter') then continue end
            Spring.stop(particle)
            particle.Rate = 0
        end
        
        --// End
        local cleaner = task.delay(5, function() for v in trash do if typeof(v) == 'Instance' then v:Destroy() end end; trash = {} end)
        trash[cleaner] = true
    end)
    function self:_renderPets(petNames: {string})
        
        local playerPosition = game.Players.LocalPlayer.Character.PrimaryPart.Position
        local selfPosition = model.PrimaryPart.Position
        
        local range = math.pi/10 * #petNames
        local rotation = CFrame.Angles(0, -range/2, 0)
        
        for count, petName in petNames do
            
            local petModel = game.ReplicatedStorage.Assets.Items[petName].Model:Clone()
            local rootPart = petModel.PrimaryPart
            trash[petModel] = true
            
            petModel.Parent = workspace
            rootPart.CFrame = CFrame.lookAt(selfPosition, playerPosition)
                * rotation * CFrame.Angles(0, math.pi/10 * count, 0)
                * CFrame.new(0, 0, -5)
                - Vector3.new(0, selfPosition.Y - playerPosition.Y, 0)
        end
    end
end)