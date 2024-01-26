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
    
    local equippedItem
    
    self.isEquipped = false
    self._handler = nil :: Humanoid?
    
    --// Signals
    self.unequipped = self:_signal('unequipped')
    self.equipped = self:_signal('equipped')
    
    --// Methods
    function self:getEquipped() return equippedItem end
    
    function self:unequip()
        
        if equippedItem then equippedItem:unwrap() end
        self.isEquipped = false
        self._handler = nil
    end
    function self:equip(handler: Humanoid)
        
        if self._handler then return end
        self._handler = handler
        self.isEquipped = true
        
        equippedItem = Equipped.get(model)
        self.equipped:_emit(equippedItem)
        
        equippedItem:cleaner(function() self.unequipped:_emit(equippedItem) end)
        handler.Destroying:Connect(function() self:unequip() end)
        
        return equippedItem
    end
end)

--// States
Equipped = Entity.trait('Equipped', function(self, model: entity)
    
    local equipment = Equipment.find(model) or error(`entity cannot be equipped`)
    self.handler = equipment._handler :: Humanoid
end)

--// End
return { Equipment = Equipment, Equipped = Equipped }