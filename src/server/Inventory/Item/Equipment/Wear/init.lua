--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local Item = require(script.Parent.Parent)
local Equipment = require(script.Parent)

--// Config
local baseConfig = {
    targetName = 'HumanoidRootPart',
    offset = CFrame.new(),
}
export type config = typeof(baseConfig)

--// Trait
local Weared
local Wear = Entity.trait('Wear', function(self, model: Equipment.entity, syncs: config)
    
    local equipment = if model:HasTag('Equipment')
        then Equipment.Equipment.get(model)
        else error(`this entity cannot be equipped`)
    
    --// Config
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    --// Listeners
    equipment.unequipped:connect(function() Weared.get(model):destroy() end)
    equipment.equipped:connect(function() Weared.get(model) end)
end)

--// States
Weared = Entity.trait('Weared', function(self, model: Equipment.entity)
    
    local equipped = Equipment.Equipped.get(model) or error(`entity didnt equipped`)
    local wear = Wear.get(model) or error(`entity cant be weared`)
    local item = Item.find(model) or error(`isnt a item`)
    
    local character = equipped.handler.Parent
    local targetPart = character:FindFirstChild(wear.targetName)
    
    --// Job
    local visual = item:visualize()
    local rootPart = visual.PrimaryPart
    rootPart.CFrame = equipped.handler.RootPart.CFrame * wear.offset
    visual.Parent = character
    
    local weld = Instance.new("WeldConstraint", rootPart)
    weld.Part0 = targetPart
    weld.Part1 = rootPart
    
    self:cleaner(function()
        
        visual:Destroy()
    end)
end)

--// End
return { Wear = Wear, Weared = Weared }