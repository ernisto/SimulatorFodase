--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local Item = require(script.Item)
type Item = Item.Item

--// Trait
return Entity.trait('Inventory', function(self, entity: Instance)
    
    self.items = {}
    
    --// Signals
    self.itemRemoved = self:_signal('itemRemoved')
    self.itemAdded = self:_signal('itemAdded')
    
    --// Methods
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