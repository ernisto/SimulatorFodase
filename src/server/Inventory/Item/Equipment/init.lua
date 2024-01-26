--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Item = require(script.Parent)

--// Types
export type entity = Item.entity

--// Config
local baseConfig = {
    slot = 'undefined'
}

--// Trait
local Equipped, Equipment
Equipment = Entity.trait('Equipment', function(self, model: entity)
    
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    local item = Item.find(model) or error(`this isnt a Item`)
    local equippedItem
    
    self.isEquipped = false
    self._handler = nil :: Humanoid?
    
    --// Signals
    self.unequipped = self:_signal('unequipped')
    self.equipped = self:_signal('equipped')
    
    --// Callbacks
    item:addStackClause(function(target)
        
        local targetEquipment = Equipment.find(target.roblox)
        if not targetEquipment then return false end
        
        return not self.isEquipped and not targetEquipment.isEquipped
    end)
    
    --// Methods
    function self:getEquipped() return equippedItem end
    
    function self:unequip()
        
        if equippedItem then equippedItem:unwrap() end
        equippedItem = nil
        
        self.isEquipped = false
        self._handler = nil
    end
    function self:equip(handler: Humanoid): Equipped
        
        if equippedItem then return equippedItem end
        
        self._handler = handler
        self.isEquipped = true
        
        equippedItem = Equipped.get(model)
        self.equipped:_emit(equippedItem)
        
        equippedItem:cleaner(function() self.unequipped:_emit(equippedItem) end)
        handler.Destroying:Connect(function() self:unequip() end)
        
        return equippedItem
    end
end)
export type Equipment = typeof(Equipment.get())

--// States
Equipped = Entity.trait('Equipped', function(self, model: entity)
    
    local equipment = Equipment.find(model) or error(`entity cannot be equipped`)
    self.handler = equipment._handler :: Humanoid
end)
export type Equipped = typeof(Equipped.get())

--// End
return { Equipment = Equipment, Equipped = Equipped }