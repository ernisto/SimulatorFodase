--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local Equipment = require(script.Item.Equipment)
type Equipment = Equipment.Equipment

local Item = require(script.Item)
type Item = Item.Item

--// Trait
return Entity.trait('Inventory', function(self, entity: Instance)
    
    self.slotLimits = {
        Morph = 1,
        Relic = 1,
        Head = 1,
        Pet = 4,
    }
    self.equippeds = {
        Morph = {},
        Relic = {},
        Head = {},
        Pet = {},
    }
    self.items = {}
    
    --// Signals
    self.itemRemoved = self:_signal('itemRemoved')
    self.itemAdded = self:_signal('itemAdded')
    
    --// Methods
    function self:_itemEquipped(equipped)
        
        local equipment = Equipment.Equipment.get(equipped.roblox.Parent)
        local slot = equipment.slot
        
        local slotEquippeds = self.equippeds[slot] or error(`invalid slot '{slot}' of item {equipment}`)
        if #slotEquippeds >= self.slotLimits[slot] then slotEquippeds[1]:unequip() end
        
        table.insert(slotEquippeds, equipment)
        equipment.unequipped:once(function()
            
            local index = table.find(slotEquippeds, equipment)
            if index then table.remove(slotEquippeds, index) end
        end)
    end
    
    function self:removeItem(item: Item)
        
        item.roblox.Parent = nil
    end
    function self:addItem(item: Item)
        
        for storedItem in self.items do
            
            if not storedItem:canStack(item) then continue end
            
            local stacking = if storedItem.maxAmount > 0 then math.min(item.amount, storedItem.maxAmount - storedItem.amount) else item.amount
            if stacking <= 0 then continue end
            
            storedItem.amount += stacking
            item:consume(stacking)
            
            if item.amount <= 0 then return end
        end
        item.roblox.Parent = self.roblox
        
        local equipment = Equipment.Equipment.find(item.roblox)
        if not equipment then return end
        
        local equippedListener = equipment.equipped:connect(function(equipped)
            
            local equippedItem = Item.find(equipped.roblox.Parent) or error(`isnt a item`)
            if equippedItem ~= item then self:addItem(equippedItem) end
            
            self:_itemEquipped(equipped)
        end)
        item.roblox.AncestryChanged:Connect(function() equippedListener:disconnect() end)
    end
    
    --// Listeners
    self.roblox.ChildAdded:Connect(function(entity)
        
        local item = Item.find(entity)
        if not item then return end
        
        self.itemAdded:_emit(item)
        self.items[item] = true
    end)
    self.roblox.ChildRemoved:Connect(function(entity)
        
        local item = Item.find(entity)
        if not item then return end
        
        if not self.items[item] then return end
        self.items[item] = nil
        
        self.itemRemoved:_emit(item)
    end)
end)