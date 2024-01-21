--// Packages
local TweenService = game:GetService('TweenService')

local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Spring = require(game.ReplicatedStorage.Packages.Spring)
local Cache = require(game.ReplicatedStorage.Packages.Cache)
local Tween = require(game.ReplicatedStorage.Shared.Tween)

--// Consts
local STACK_RANGE = 1

--// Handler
local DropStack = {}
local idleDrops = Cache.new(-1)

--// Component
function DropStack.new(params: { asset: Model, model: Model?, amount: number, position: Vector3 })
    
    local model = params.model or params.asset:Clone()
    model.Parent = workspace
    
    local rootPart = model.PrimaryPart
    rootPart.Position = params.position
    rootPart.Anchored = true
    
    --// Instance
    local self = {
        motion = nil :: Promise.Promise?,
        position = params.position,
        amount = params.amount,
        asset = params.asset,
        model = model,
    }
    
    --// Methods
    function self:idle()
        
        if self.motion then self.motion:cancel() end
        
        local position = rootPart.Position // STACK_RANGE * STACK_RANGE
        self.position = position
        
        self:merge(idleDrops:find(params.asset, position))
        idleDrops:set(self, params.asset, position)
        
        self.motion = Promise.new(function(resolve, reject, onCancel)
            
            local cframe = CFrame.new(position)
            local lifetime = 0
            repeat
                lifetime += task.wait()
                rootPart.CFrame = cframe
                    * CFrame.new(0, math.sin(lifetime), 0)
                    * CFrame.Angles(0, lifetime, 0)
                    * rootPart.PivotOffset.Rotation
            until onCancel()
        end)
    end
    function self:followAsync(part: BasePart)
        
        if self.motion then self.motion:cancel() end
        
        local spring = Spring.target(
            rootPart, 0.50, 1.5,
            { Position=part.Position }
        ).Position
        
        for _,part in model:GetDescendants() do
            
            if not part:IsA('BasePart') then continue end
            
            TweenService:Create(part, TweenInfo.new(.6), { Color = Color3.new(1, 1, 1) }):Play()
            task.delay(.4, function() part.Material = Enum.Material.Neon end)
        end
        
        self.motion = Promise.new(function(resolve, reject, onCancel)
            
            repeat spring:setGoal(part.Position)
            until (part.Position - rootPart.Position).Magnitude < 4 or onCancel()
            or not task.wait()
            
            resolve()
        end)
        return self.motion
    end
    function self:throwToAsync(target: Vector3)
        
        if self.motion then self.motion:cancel() end
        local mid = rootPart.Position + Vector3.new(0, (self.position - target).Magnitude*0.50, 0)
        
        self.motion = Tween.tweenAsync(0, 1, TweenInfo.new(.5), function(fade)
            
            rootPart.Position = self.position:Lerp(mid, fade)
                :Lerp(mid:Lerp(target, fade), fade)
        end)
        return self.motion:finallyCall(self.idle, self)
    end
    
    function self:merge(...: DropStack)
        
        for _,stack in {...} do
            
            if not stack.amount then return end
            
            self.amount += stack.amount
            stack:destroy()
        end
    end
    function self:consume(amount: number)
        
        assert(amount > 0, `amount must to be > 0`)
        assert(self.amount >= amount, `not enough`)
        self.amount -= amount
        
        local newModel
        if self.amount == 0 then
            
            newModel = model
            model = nil
            
            self:destroy()
        end
        
        return DropStack.new{ asset=self.asset, model=newModel, amount=amount, position=self.position }
    end
    
    function self:pickup()
        
        if self.motion then self.motion:cancel() end
        for _,part in model:GetDescendants() do if part:IsA('BasePart') then part.Transparency = 1 end end
        
        task.wait(.8)
        self:destroy()
    end
    function self:destroy()
        
        if self.motion then self.motion:cancel() end
        if model then model = model:Destroy() end
        
        idleDrops:set(nil, self.asset, self.position)
    end
    
    --// End
    return self
end
export type DropStack = typeof(DropStack.new({} :: any))

--// End
return DropStack