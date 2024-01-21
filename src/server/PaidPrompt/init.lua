--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerCurrency = require(game.ServerScriptService.Player.Currency)
local PlayerMarket = require(game.ServerScriptService.Player.Market)

--// Types
export type entity = ProximityPrompt

--// Config
local baseConfig = {
    passId = nil :: number?,
    productId = nil :: number?,
}

--// Trait
return Entity.trait('PaidPrompt', function(self, prompt: entity)
    
    local config = parseAttributes(prompt, baseConfig)
    self:_syncAttributes(config)
    
    --// Signals
    self.activated = self:_signal('activated')
    
    --// Listeners
    prompt.Triggered:Connect(function(player)
        
        local currency = PlayerCurrency.get(player)
        local market = PlayerMarket.get(player)
        
        if self.passId then market:getPass(self.passId):expect() end
        if self.price then currency:consume(self.price) end
        if self.productId then market:getProduct(self.productId):promptAsync():expect() end
        
        self.activated:_emit(player)
    end)
end)