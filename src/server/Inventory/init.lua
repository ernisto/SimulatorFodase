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
        self.items[item] = nil
    end
    function self:addItem(item: Item)
        
        item.roblox.Parent = self.roblox
        self.items[item] = true
    end
end)