--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BagModels = ReplicatedStorage.Assets.BagModels

local parseAttributes = require(ReplicatedStorage.Config.ParseAttributes)
local reconcile = require(ReplicatedStorage.Shared.Reconcile)
local wrapper = require(ReplicatedStorage.Packages.Wrapper)

--// Module
local Bag = {}

--// Config
Bag.baseConfig = {
    requiredPower = 0,
    capacity = 0,
}
export type bagConfig = typeof(Bag.baseConfig)

--// Data
Bag.baseData = {
    name = 'Bag',
}
export type bagData = typeof(Bag.baseData)

--// Cache
local cache = setmetatable({}, { __mode = 'k' })
function Bag.find(container: Instance) return cache[container] end

--// Factory
function Bag.deserialize(data: bagData)
    
    reconcile(data, Bag.baseData)
    
    local asset = BagModels:FindFirstChild(data.name) or error(`invalid bag '{data.name}'`)
    local config = parseAttributes(asset, Bag.baseConfig, `Bag '{data.name}'`)
    
    local container = Instance.new("Folder")
    container.Name = data.name
    
    --// Instance
    local self = wrapper(container, 'Bag')
    self.asset = asset
    
    self:_syncAttributes(config)
    self.config = config
    
    self:_syncAttributes(data)
    self.data = data
    
    self.player = nil :: Player?
    function self:setPlayer(player: Player) self.player = player end
    
    --// End
    cache[container] = self
    return self :: Bag
end
export type Bag = bagConfig & bagData & {
    config: bagConfig,
    data: bagData,
    
    player: Player?,
    setPlayer: (player: Player?) -> (),
}

--// End
return Bag