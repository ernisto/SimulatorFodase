--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local Product = require(script.Product)
type Product = Product.Product

local Pass = require(script.Pass)
type Pass = Pass.Pass

--// Trait
return Entity.trait('PlayerMarket', function(self, player: Player)
    
    --// Instance
    self.products = {} :: { [number]: Product }
    self.passes = {} :: { [number]: Pass }
    
    --// Methods
    function self:getProduct(productId: number)
        
        if not self.products[productId] then
            
            self.products[productId] = Product.new(player, productId)
        end
        return self.products[productId]
    end
    function self:getPass(passId: number)
        
        if not self.passes[passId] then
            
            self.passes[passId] = Pass.new(player, passId)
        end
        return self.passes[passId]
    end
end)