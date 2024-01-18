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
        
        self:_host(item)
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