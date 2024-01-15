--// Packages
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Replication = require(ReplicatedStorage.Packages.Replication)
local wrapper = require(ReplicatedStorage.Packages.Wrapper)
local emitAll = require(ReplicatedStorage.Shared.EmitAll)
local haptic = require(ReplicatedStorage.Shared.EZHaptic)

local LocalAnimator = require(script.Parent:WaitForChild("LocalCharacter"):WaitForChild("Animator"))
local Gameplay = require(script.Parent:WaitForChild("Gameplay"))

local HealthBar = require(script.HealthBar)

--// Module
local Tree = {}
type treeModel = Model & {
    FocusHighlight: Highlight,
    PrimaryPart: BasePart & { Jump: Attachment },
    Model: Model,
}

--// Cache
local cache = setmetatable({}, { __mode = 'k' })
function Tree.get(model: treeModel) return cache[model] or Tree.wrap(model) end

--// Factory
function Tree.wrap(model: treeModel)
    
    model.Model:SetAttribute("Scale", model.Model:GetScale())
    model.Model:SetAttribute("scale", model.Model:GetScale())
    
    for _,part in model:GetDescendants() do
        
        if not part:IsA("BasePart") then continue end
        
        part:SetAttribute("Material", part.Material)
        part:SetAttribute("Color", part.Color)
    end
    
    local rootPart; local healthBar
        repeat rootPart = model.PrimaryPart
        until rootPart or not task.wait()
    
    local server = Replication.await(model)
    local proximity = Instance.new("ProximityPrompt", rootPart)
    proximity.GamepadKeyCode = Enum.KeyCode.ButtonY
    proximity.RequiresLineOfSight = false
    proximity.MaxActivationDistance = 15
    proximity.ObjectText = model.Name
    proximity.ActionText = "Chop (click)"
    proximity.UIOffset = Vector2.new(0, -200)
    
    --// Instance
    local self = wrapper(model)
    self.totalDroppedWoods = WoodStack.new{}
    self.health = self.maxHealth
    self.drops = {}
    
    --// Methods
    local chopFX
    function self:chopAsync()
        
        local axe = LocalChopping.equippedAxe or error(`equipped axe required`)
        
        assert(not axe:inCooldown(), `chop in cooldown`)
        axe:setLocalCooldown()
        
        local thisChopFX = if chopFX then nil else ChopFX(model)
        
        return server:invokeChopAsync():andThen(
            function(...)
                axe:setLocalCooldown()
                self:damage(...)
                
                if not thisChopFX then return end
                thisChopFX:awaitJump(.5 + .5*self.health/self.maxHealth)
                chopFX = nil
            end,
            function(err)
                
                if not thisChopFX then return end
                thisChopFX:cancel()
                chopFX = nil
            end
        )
    end
    function self:damage(damage: number, droppedWoods: WoodStack, pickedWoods: WoodStack)
        
        self.health -= damage
        if self.health <= 0 then self:kill() end
        
        self:dropWoods(droppedWoods)
        self:pickupWoods(pickedWoods)
    end
    function self:kill()
        
        self:unfocus()
        emitAll(rootPart.Fall)
        
        self.health = 0
        proximity.Style = Enum.ProximityPromptStyle.Custom
        
        task.defer(function()
            
            healthBar = healthBar and healthBar:awaitHide()
            awaitRespawnFX(model, self.respawnTime)
            
            self.health = self.maxHealth
            proximity.Style = Enum.ProximityPromptStyle.Default
        end)
    end
    
    function self:dropWoods(droppedWoods: WoodStack)
        
        local woodName, amounts = next(droppedWoods.data)
        if not woodName then return end
        
        self.totalDroppedWoods += droppedWoods
        local index = 0
        
        for sizeName, amount in amounts do
            
            for _ = 1, amount do
                
                local drop = DropFX{ woodName=woodName, sizeName=sizeName, position=rootPart.Position }
                
                self.drops[drop] = sizeName
                index += 1
            end
        end
    end
    function self:pickupWoods(pickingWoods: WoodStack)
        
        local _,amounts = next(pickingWoods.data)
        if not amounts then return end
        
        self.totalDroppedWoods -= pickingWoods
        local woodsToPick = table.clone(amounts)
        local count = 0
        
        for drop, sizeName in self.drops do
            
            if woodsToPick[sizeName] <= 0 then continue end
            woodsToPick[sizeName] -= 1
            
            drop:onReady(function()
                
                task.wait(count*.03)
                drop:awaitPickup(localPlayer.Character.PrimaryPart)
            end)
            self.drops[drop] = nil
            count += 1
        end
    end
    
    function self:focus()
        
        model.FocusHighlight.Enabled = true
        
        healthBar = if healthBar then healthBar:show()
            else self:_host(HealthBar{
                name = `{self.woodName} Tree`, level = self.tier or 1,
                health = self.health, maxHealth = self.maxHealth,
                healthChanged = self:listenChange('health')
            })
    end
    function self:unfocus()
        
        ContextActionService:UnbindAction('ChopTree')
        
        model.FocusHighlight.Enabled = false
        healthBar = healthBar and healthBar:awaitHide()
    end
    
    --// Interactions
    local function attack(inputType: Enum.UserInputType?, keyCode: Enum.KeyCode?)
        
        Gameplay.assert(LocalChopping.equippedAxe, `equipped axe required`, 0.50)
        Gameplay.assert(not LocalChopping.equippedAxe:inCooldown(), `axe in cooldown`, 0.50)
        Gameplay.assert(LocalChopping.equippedAxe.tier >= self.tier, `axe tier so low`, 0.50)
        
        local animator = LocalAnimator():expect()
        animator:getTrack(script.ChopAnimation):Play()
        
        self:chopAsync()
            :catch(function() haptic{ device=inputType, motor=Enum.VibrationMotor.Small } end)
            :expect()
        
        --// Haptic
        local intensity = if self.health <= 0 then 1.00 else 0.50
        local motor = if keyCode == Enum.KeyCode.ButtonL2 then Enum.VibrationMotor.LeftTrigger
            elseif keyCode == Enum.KeyCode.ButtonR2 then Enum.VibrationMotor.RightTrigger
            else Enum.VibrationMotor.Large
        
        haptic{ device=inputType, motor=motor, intensity=intensity }
    end
    
    --// Listeners
    proximity.Triggered:Connect(function() attack(UserInputService:GetLastInputType()) end)
    proximity.PromptShown:Connect(function()
        
        server:invokePickupWoodsAsync()
            :andThen(function(pickedWoods) self:pickupWoods(pickedWoods) end)
        
        if self.health <= 0 then return end
        self:focus()
        
        --// Input
        local function clickHandler(_,state, input: InputObject)
            
            if state ~= Enum.UserInputState.Begin then return end
            attack(input.UserInputType, input.KeyCode)
        end
        ContextActionService:BindAction('ChopTree', clickHandler, false,
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch,
            Enum.KeyCode.ButtonL2,
            Enum.KeyCode.ButtonR2
        )
        
        --// Cleaner
        proximity.PromptHidden:Wait()
        self:unfocus()
    end)
    
    --// End
    cache[model] = self
    return self
end

--// End
return Tree