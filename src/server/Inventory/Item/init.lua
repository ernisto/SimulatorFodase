--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local joinMap = require(game.ReplicatedStorage.Shared.JoinMap)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local ItemAssets = game.ReplicatedStorage.Assets.Items

--// Types
export type entity = Folder

--// Data
local baseData = {
    name = 'invalid',
    amount = 1,
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
    
    joinMap(baseData, data)
    
    local asset = ItemAssets[data.name]
    local config = parseAttributes(asset, baseConfig)
    local modelAsset = asset.Model
    
    local tags = asset:GetTags()
    table.remove(tags, table.find(tags, 'asset'))
    
    --// Instance
    local self = wrapper(Instance.new("Folder"), 'Item', unpack(tags))
    self.roblox.Name = data.name
    
    self:_syncAttributes(asset:GetAttributes())
    self:_syncAttributes(config)
    self.config = config
    
    self:_syncAttributes(data)
    self.data = data
    
    --// Methods
    local clauses = {
        [function(hoster) return self.name == hoster.name end] = true
    }
    function self:addStackClause(clause: (hoster: Item) -> boolean)
        
        clauses[clause] = true
    end
    function self:canStack(hoster: Item)
        
        for clause in clauses do if not clause(hoster) then return false end end
        return true
    end
    
    function self:visualize()
        
        return modelAsset:Clone()
    end
    function self:consume(amount: number)
        
        assert(self.amount >= amount, `not enough amount`)
        self.amount -= amount
        
        if self.amount > 0 then return end
        
        self.roblox.Parent = nil
        self:destroy()
    end
    
    --// End
    cache:set(self, self.roblox)
    
    self.roblox.Parent = game.ServerStorage -- trigger CollectionService InstaceAdded
    for _,tag in tags do if tag ~= 'Item' then self.roblox:WaitForChild(tag) end end
    
    return self
end
export type Item = wrapper.wrapper<entity>
    & config & { config: config }
    & data & { data: data }
    & {
        addStackClause: (any, clause: (hoster: Item) -> boolean) -> (),
        consume: (any, amount: number) -> (),
        canStack: (any, hoster: Item) -> (),
        visualize: (any) -> Model,
    }

--// End
return Item