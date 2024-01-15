--// Packages
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local wrapper = require(ReplicatedStorage.Packages.Wrapper)

local PlayerProfile = require(script.Parent.Profile)

--// Module
local Market = {}

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
Market.baseData = {
    receipts = {} :: {receipt}
}
local awaitMarketData = PlayerProfile.subData('Market', Market.baseData)
export type data = typeof(Market.baseData)

--// Cache
local onLoads = setmetatable({}, { __mode = 'k' })
local cache = setmetatable({}, { __mode = 'k' })
function Market.get(player: Player) return cache[player] or onLoads[player] and onLoads[player]:await() or Market.wrap(player) end

--// Factory
function Market.wrap(player: Player)
    
    local container = Instance.new("Folder", player)
    container.Name = "Market"
    
    --// Instance
    local self = wrapper(container, 'Market')
    self.gamepasses = {} :: { [number]: () -> () }
    self.products = {} :: { [number]: (receipt) -> () }
    
    onLoads[player] = self:_signal('onLoad')
    self.data = awaitMarketData(player)
    self:_syncAttributes(self.data)
    
    --// Setters
    setmetatable(self.gamepasses, { __newindex = function(gamepasses, gamePassId, callback)
        
        task.defer(function()
            
            if MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId) then callback() end
        end)
        rawset(gamepasses, gamePassId, callback)
    end })
    
    --// Gamepasses
    self.isVip = false
    self.gamepasses[675866684] = function() self.isVip = true end
    
    --// End
    onLoads[player]:_emit(self)
    cache[player] = self
    return self
end

--// Functions
local isProcessing = {}
local function processReceipt(receipt)
    
    local player = Players:GetPlayerByUserId(receipt.PlayerId) or error(`player offline`)
    local profile = PlayerProfile.findProfile(player) or error(`inative profile`)
    local playerMarket = Market.get(player)
    
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
    
    local market = cache[player]
    if not market then return end
    
    local callback = market.gamepasses[gamepassId]
    if callback then callback() end
end)

--// End
return Market