--// Packages
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Entity = require(ReplicatedStorage.Packages.Entity)
local Ray = require(ReplicatedStorage.Packages.Ray)

local FollowersAllocator = require(script.FollowersAllocator)
local AllocatedFollower = require(script.AllocatedFollower)
local Equipped = require(script.Parent.Equipped)

--// Factory
local Follower = Entity.trait('Follower', function(self, container: Instance) end)
return Entity.trait('Following', function(self, container: Instance)
    
    local asset = game.ReplicatedStorage.Assets.Items[container.Name]
    local owner = container:FindFirstAncestorOfClass('Player')
    local equipped = Equipped.await(container)
    local follower = Follower.await(container)
    
    local humanoid = equipped.handler :: Humanoid
    local allocation = AllocatedFollower.await(container)
    local allocator = FollowersAllocator.await(humanoid)
    
    --// Instance
    local model = asset.Model:Clone()
    local petRootPart = model.PrimaryPart
    model.Parent = workspace
    
    local alignOrientation = Instance.new('BodyGyro', petRootPart)
    local alignPosition = Instance.new('BodyPosition', petRootPart)
    alignOrientation.MaxTorque = Vector3.one * 40000
    alignPosition.MaxForce = Vector3.one * 40000
    
    petRootPart.CFrame = owner.Character.PrimaryPart.CFrame
    petRootPart.Anchored = false
    
    --// Jobs
    local physicJob = RunService.Heartbeat:Connect(function(deltaTime)
        
        local offset = CFrame.Angles(0, math.pi*2 * allocation.index / allocator.total, 0)
            * CFrame.new(0, 0, -10)
        
        local playerRootPart = humanoid.RootPart :: BasePart
        local petPosition = (playerRootPart.CFrame * offset).Position
        
        local hit = Ray.cast{
            from = petPosition + Vector3.new(0, 10, 0),
            plus = Vector3.new(0, -20, 0),
            respectCanCollide = false,
            collisionGroup = 'Pets'
        }
        local position = if hit
            then hit.cframe.Position + Vector3.new(0, follower.roblox:GetAttribute('height') or error(`invalid height of {follower}`) + math.sin(os.clock()), 0)
            else petPosition
        
        alignOrientation.CFrame = CFrame.new(Vector3.zero, playerRootPart.CFrame.LookVector)
        alignPosition.Position = position
    end)
    
    --// Listeners
    container.AncestryChanged:Connect(function() if not container:IsDescendantOf(owner) then self:unwrap() end end)
    self:_host(physicJob)
    self:_host(model)
end)