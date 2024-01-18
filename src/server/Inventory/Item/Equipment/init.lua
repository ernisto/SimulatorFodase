--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Item = require(script.Parent)

--// Types
export type entity = Item.entity

--// Trait
local Equipped
local Equipment = Entity.trait('Equipment', function(self, model: entity)
    
    local equippedItem
    
    self.isEquipped = false
    self._handler = nil :: Humanoid?
    
    --// Signals
    self.unequipped = self:_signal('unequipped')
    self.equipped = self:_signal('equipped')
    
    --// Methods
    function self:getEquipped() return equippedItem end
    
    function self:unequip() if equippedItem then equippedItem:unwrap() end end
    function self:equip(handler: Humanoid)
        
        if self._handler then return end
        self._handler = handler
        
        equippedItem = Equipped.get(model)
        self.equipped:_emit(equippedItem)
        
        equippedItem:cleaner(function() self.unequipped:_emit(equippedItem) end)
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