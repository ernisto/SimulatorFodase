--// Packages
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Entity = require(game.ReplicatedStorage.Packages.Entity)
local PlayerProfile = require(script.Parent.Profile)

--// Types
export type receipt = {
    purchaseId: number,
    productId: number,
    timestamp: number,
    placeId: number,
    spent: number,
    currency: string,
}

--// Data
local awaitData = PlayerProfile.subData('Market', {
    receipts = {} :: {receipt}
})

--// Factory
local PlayerMarket = Entity.trait('PlayerMarket', function(self, player: Player, syncs: { receipts: {receipt} })
    
    --// Instance
    self.gamepasses = {} :: { [number]: () -> () }
    self.products = {} :: { [number]: (receipt) -> () }
    
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    --// Setters
    setmetatable(self.gamepasses, { __newindex = function(gamepasses, gamePassId, callback)
        
        task.defer(function()
            
            if MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId) then callback() end
        end)
        rawset(gamepasses, gamePassId, callback)
    end })
end)

--// Functions
local isProcessing = {}
local function processReceipt(receipt)
    
    local player = Players:GetPlayerByUserId(receipt.PlayerId) or error(`player offline`)
    local profile = PlayerProfile.findProfile(player) or error(`inative profile`)
    local playerMarket = PlayerMarket.get(player)
    
    assert(isProcessing[receipt.PurchaseId], `already processing`)
    isProcessing[receipt.PurchaseId] = true
    
    playerMarket.products[receipt.ProductId] {
        purchaseId = receipt.PurchaseId,
        productId = receipt.ProductId,
        placeId = receipt.PurchasePlaceId,
        spent = receipt.CurrencySpent,
        currency = receipt.CurrencyType,
        timestamp = os.time(),
    }
    assert(profile:IsActive(), `profile must to be active`)
    profile:awaitSave()
end

--// Listeners
function MarketplaceService.ProcessReceipt(receipt)
    
    assert(not isProcessing[receipt.PurchaseId], `already processing`)
    isProcessing[receipt.PurchaseId] = true
    
    assert(xpcall(processReceipt,
        function() isProcessing[receipt.PurchaseId] = nil end,
        receipt
    ))
    return Enum.ProductPurchaseDecision.PurchaseGranted
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
    
    if not wasPurchased then return end
    
    local market = PlayerMarket.find(player)
    if not market then return end
    
    local callback = market.gamepasses[gamepassId]
    if callback then callback() end
end)

--// End
return PlayerMarket