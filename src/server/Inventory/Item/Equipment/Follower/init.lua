--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local Item = require(script.Parent.Parent)
local Equipment = require(script.Parent)

local FollowersAllocator = require(script.FollowersAllocator)

--// Config
local baseConfig = {
    height = 0,
}
export type config = typeof(baseConfig)

--// Trait
local Following
local Follower = Entity.trait('Follower', function(self, model: Equipment.entity, syncs: config)
    
    local equipment = if model:HasTag('Equipment')
        then Equipment.Equipment.get(model)
        else error(`this entity cannot be equipped`)
    
    --// Config
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    --// Listeners
    equipment.unequipped:connect(function() Following.get(model):destroy() end)
    equipment.equipped:connect(function(equipped) Following.get(equipped.roblox.Parent) end)
end)

--// States
Following = Entity.trait('Following', function(self, model: Equipment.entity)
    
    local equipped = Equipment.Equipped.get(model) or error(`entity didnt equipped`)
    local _follower = Follower.get(model) or error(`entity cant follow`)
    local allocator = FollowersAllocator.get(equipped.handler.RootPart)
    local item = Item.find(model)
    
    --// Job
    local visual = item:visualize()
    visual.Parent = equipped.handler.Parent
    
    local allocated = allocator:allocate(visual)
    self:cleaner(function() allocated:deallocate() end)
end)

--// End
return { Follower = Follower, Following = Following }