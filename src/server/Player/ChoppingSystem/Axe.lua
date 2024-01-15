--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AxeModels = ReplicatedStorage.Assets.AxeModels

local parseAttributes = require(ReplicatedStorage.Config.ParseAttributes)
local reconcile = require(ReplicatedStorage.Shared.Reconcile)
local wrapper = require(ReplicatedStorage.Packages.Wrapper)

--// Module
local Axe = {}

--// Consts
local DAMAGE_LEVEL_MULTIPLIER = 1.20

--// Config
Axe.baseConfig = {
    baseDamage = 0,
    cooldown = 0,
    tier = 0,
}
export type axeConfig = typeof(Axe.baseConfig)

--// Data
Axe.baseData = {
    name = 'undefined',
    isEquipped = false,
    level = 1,
}
export type axeData = typeof(Axe.baseData)

--// Cache
local cache = setmetatable({}, { __mode = 'k' })
function Axe.find(container: Instance) return cache[container] end

--// Factory
function Axe.deserialize(data: axeData)
    
    reconcile(data, Axe.baseData)
    
    local asset = AxeModels:FindFirstChild(data.name) or error(`invalid axe '{data.name}'`)
    local config = parseAttributes(asset, Axe.baseConfig, `Axe '{data.name}'`)
    
    local container = Instance.new("Folder")
    container.Name = data.name
    
    --// Instance
    local self = wrapper(container, 'Axe')
    local model: Model?, rewelder: RBXScriptConnection?
    self.damage = config.baseDamage * (1 + data.level*DAMAGE_LEVEL_MULTIPLIER)
    self.model = nil :: Model?
    self.asset = asset
    
    self:_syncAttributes(config)
    self.config = config
    
    self:_syncAttributes(data)
    self.data = data
    
    self.player = nil :: Player?
    function self:setPlayer(player: Player)
        
        self.player = player
        container.Parent = if player then player:FindFirstChild("AxeInventory") else nil
    end
    
    --// Methods
    local cooldownFinished = 0
    function self:useCooldown()
        
        assert(os.clock() > cooldownFinished, `axe in cooldown`)
        cooldownFinished = os.clock() + self.cooldown
    end
    
    function self:unequip()
        
        if not self.isEquipped then return end
        self.isEquipped = false
        
        if rewelder then rewelder = rewelder:Disconnect() end
        if model then model = model:Destroy() end
    end
    function self:equip()
        
        assert(self.player, `axe must to be owned`)
        
        if self.isEquipped and rewelder then return end
        self.isEquipped = true
        
        local function weldUp()
            
            if model then model:Destroy() end
            
            model = asset:Clone(); assert(model)
            local rootPart = model.PrimaryPart
            
            local character = self.player.Character or error(`owner must to be spawned`)
            local rightHand = character.RightHand
            
            local weld = Instance.new("WeldConstraint", rootPart)
            rootPart.CFrame = rightHand.CFrame * rootPart.PivotOffset
            model.Parent = character
            weld.Part0 = rightHand
            weld.Part1 = rootPart
            
            model:AddTag('EquippedAxe')
            self.model = model
        end
        
        rewelder = self.player.CharacterAdded:Connect(weldUp)
        if self.player.Character then weldUp() end
    end
    
    self:cleaner(function() self:unequip() end)
    
    --// End
    cache[container] = self
    return self :: Axe
end
export type Axe = axeConfig & axeData & {
    config: axeConfig,
    damage: number,
    data: axeData,
    
    player: Player?,
    setPlayer: (player: Player?) -> (),
    
    useCooldown: () -> (),
    unequip: () -> (),
    equip: () -> (),
}

--// End
return Axe