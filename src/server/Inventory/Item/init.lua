--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local ItemAssets = game.ReplicatedStorage.Assets.Items

--// Types
export type entity = Folder

--// Data
local baseData = {
    name = 'invalid',
    amount = 0,
}
export type data = typeof(baseData)

--// Config
local baseConfig = {
    maxAmount = 1,
    rarity = 1,
    display = 'undefined'
}
export type config = typeof(baseConfig)

--// Handler
local Item = {}

local cache = Cache.new(-1, 'k')
function Item.find(entity: entity): Item return cache:find(entity) end

--// Component
function Item.new(data: data)
    
    local asset = ItemAssets[data.name]
    local config = parseAttributes(asset, baseConfig)
    
    local tags = asset:GetTags()
    table.remove(tags, table.find(tags, 'asset'))
    
    --// Instance
    local self = wrapper(Instance.new("Folder"), 'Item', unpack(tags))
    self.roblox.Name = data.name
    self.modelAsset = asset.Model
    
    self:_syncAttributes(config)
    self.config = config
    
    self:_syncAttributes(data)
    self.data = data
    
    --// Methods
    function self:visualize()
        
        return self.modelAsset:Clone()
    end
    
    --// End
    cache:set(self, self.roblox)
    return self
end
export type Item = wrapper.wrapper<entity> & data & config

--// End
return Item