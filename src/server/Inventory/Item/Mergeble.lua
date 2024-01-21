--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local joinMap = require(game.ReplicatedStorage.Shared.JoinMap)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Item = require(script.Parent)

export type entity = Item.entity

--// Data
local baseData = {
    level = 0
}
export type data = typeof(baseData)

--// Config
local baseConfig = {
    mergeRequirement = 2,
    maxLevel = -1
}
export type config = typeof(baseConfig)

--// Trait
local Mergeble; Mergeble = Entity.trait('Mergeble', function(self, model: entity, syncs: data & config)
    
    local item = Item.find(model) or error(`this isnt a item`)
    
    local data = joinMap(baseData, item.data)
    self:_syncAttributes(data)
    
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    --// Methods
    function self:levelup()
        
        assert(self.level ~= self.maxLevel)
        self.level += 1
    end
    
    --// Clauses
    item:addStackClause(function(hoster) return self.level == Mergeble.get(hoster.roblox).level end)
end)
return Mergeble