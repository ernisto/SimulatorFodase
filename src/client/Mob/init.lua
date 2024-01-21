--// Packages
local SoundService = game:GetService('SoundService')
local PickupItemSound = SoundService.PickupItem
local DropItemSound = SoundService.DropItem

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemAssets = ReplicatedStorage.Assets.Items
local CoinAsset = ReplicatedStorage.Assets.Coin

local Replication = require(ReplicatedStorage.Packages.Replication)
local Entity = require(ReplicatedStorage.Packages.Entity)
local emitAll = require(ReplicatedStorage.Shared.EmitAll)
local Cache = require(ReplicatedStorage.Packages.Cache)
local Ray = require(ReplicatedStorage.Packages.Ray)

local LocalAnimator = require(script.Parent:WaitForChild("LocalCharacter"):WaitForChild("Animator"))
local DropStack = require(script.DropStack)

--// Consts
local STACK_RANGE = 5
local DROP_RANGE = 15

--// Types
export type entity = Model & {
    PrimaryPart: BasePart & { Respawned: Attachment, Damaged: Attachment, Died: Attachment },
    Humanoid: Humanoid,
    Model: Model,
}

--// Trait
return Entity.trait('Mob', function(self, model: entity)
    
    local server = Replication.await(model)
    local animator = LocalAnimator(model.Humanoid):expect()
    
    --// Instance
    self.Proximity = Entity.query{ root=model, class='ProximityPrompt' }:await()
    self.maxHealth = model:GetAttribute('maxHealth')
    self.health = self.maxHealth
    self.isFocused = false
    
    self.unfocused = self:_signal('unfocused')
    self.focused = self:_signal('focused')
    
    --// Methods
    function self:requestPickupDropsAsync()
        
        return server:invokePickupDropsAsync()
            :tap(function(pickups)
                
                self:_pickupItems(pickups.items)
                self:_pickupCoins(pickups.coins)
            end)
    end
    function self:requestAttackAsync()
        
        local animator = LocalAnimator():expect()
        local attackTrack = animator:getTrack(script.PlayerAttackAnimations)
        attackTrack:Play()
        
        return server:invokeAttackAsync():andThen(
            function(damage, pickups)
                
                self:_damage(damage)
                task.wait(.5)
                
                self:_pickupItems(pickups.items)
                self:_pickupCoins(pickups.coins)
            end,
            function(err) attackTrack:Stop(0) end
        )
    end
    
    function self:unfocus()
        
        self.isFocused = false
        self.unfocused:_emit()
    end
    function self:focus()
        
        self.isFocused = true
        self.focused:_emit()
    end
    
    --// Actions
    function self:_damage(damage: number)
        
        animator:getTrack(script.DamagedAnimations):Play()
        emitAll(model.PrimaryPart.Damaged)
        
        self.health -= damage
        if self.health <= 0 then self:_kill() end
    end
    function self:_kill()
        
        self:unfocus()
        
        animator:getTrack(script.DiedAnimations):Play()
        emitAll(model.PrimaryPart.Died)
        
        self.health = 0
        task.delay(self.respawnTime, function() self:_respawn() end)
    end
    function self:_respawn()
        
        animator:getTrack(script.RespawnedAnimations):Play()
        emitAll(model.PrimaryPart.Respawned)
        
        self.health = self.maxHealth
    end
    
    --// Coin Dropping
    local coinDropStacks = Cache.new(-1)
    function self:_dropCoins(amount: number)
        
        for count = 1, amount do
            
            local origin = model.PrimaryPart.Position
            local dropStack = DropStack.new{ asset=CoinAsset, amount=1, position=origin }
            coinDropStacks:set(true, dropStack)
            
            local planePosition = origin + Vector3.new(
                math.random(-DROP_RANGE, DROP_RANGE),
                0,
                math.random(-DROP_RANGE, DROP_RANGE)
            )
            local hit = Ray.cast{ from=planePosition, plus=Vector3.new(0, -50, 0) }
            
            dropStack:throwToAsync(if hit then hit.cframe.Position else planePosition)
            DropItemSound:Play()
        end
    end
    function self:_pickupCoins(amount: number)
        
        if amount <= 0 then return end
        local remaining = amount
        
        for dropStack in coinDropStacks:find() :: {[DropStack.DropStack]: boolean} do
            
            if dropStack.amount == 0 then coinDropStacks:set(nil, dropStack); continue end
            
            local consuming = math.min(remaining, dropStack.amount)
            remaining -= consuming
            
            task.delay(game.Players.LocalPlayer:DistanceFromCharacter(dropStack.position)/DROP_RANGE, function()
                
                local travellingDrop = dropStack:consume(consuming)
                travellingDrop:followAsync(game.Players.LocalPlayer.Character.PrimaryPart)
                    :tap(function() travellingDrop:pickup() end)
                    :tap(function() PickupItemSound:Play() end)
            end)
            if remaining == 0 then return end
        end
    end
    server.coinsDropped:connect(function(amount)
        
        self:_dropCoins(amount)
    end)
    
    --// Item Dropping
    local itemDropStacks = Cache.new(-1, 'k')
    function self:_dropItems(...: string)
        
        for count, itemName in {...} do
            
            local origin = model.PrimaryPart.Position
            local ItemAsset = ItemAssets[itemName].Model
            
            local dropStack = DropStack.new{ asset=ItemAsset, amount=1, position=origin }
            itemDropStacks:set(true, itemName, dropStack)
            
            local planePosition = origin + Vector3.new(
                math.random(-DROP_RANGE, DROP_RANGE),
                3,
                math.random(-DROP_RANGE, DROP_RANGE)
            ) // STACK_RANGE * STACK_RANGE
            local hit = Ray.cast{ from=planePosition, plus=Vector3.new(0, -50, 0) }
            
            dropStack:throwToAsync(if hit then hit.cframe.Position else planePosition)
            DropItemSound:Play()
        end
    end
    function self:_pickupItems(itemNames: {string})
        
        if #itemNames <= 0 then return end
        
        local counters = {}
        for _,itemName in itemNames do counters[itemName] = 1+(counters[itemName] or 0) end
        
        for itemName, remaining in counters do
            
            for dropStack in itemDropStacks:find(itemName) or {} do
                
                if dropStack.amount == 0 then itemDropStacks:set(nil, dropStack); continue end
                
                local consuming = math.min(remaining, dropStack.amount)
                remaining -= consuming
                
                local travellingDrop = dropStack:consume(consuming)
                travellingDrop:followAsync(game.Players.LocalPlayer.Character.PrimaryPart)
                    :andThen(function() PickupItemSound:Play() end)
                    :andThen(function() travellingDrop:pickup() end)
                
                if remaining == 0 then break end
            end
        end
    end
    server.itemsDropped:connect(function(...: string)
        
        self:_dropItems(...)
    end)
end)