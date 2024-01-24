--// Packages
local MarketplaceService = game:GetService('MarketplaceService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local Promise = require(game.ReplicatedStorage.Packages.Promise)
type Promise<data... = ()> = Promise.TypedPromise<data...>

local Replicator = require(game.ServerStorage.Packages.Replicator)
local PlayerProfile = require(script.Parent.Parent.Profile)

--// Module
local Product = {}
local products = Cache.new(-1, 'k')

--// Data
local awaitReceipts = PlayerProfile.subData('products', {
    queuedProcessIds = {},
    purchaseIds = {},
    receipts = {} :: {receipt},
})

--// Factory
function Product.new(player: Player, productId: number)
    
    local data = awaitReceipts(player)
    local profile = PlayerProfile.awaitProfile(player)
    local queuedProcessIds = data.queuedProcessIds
    local purchaseIds = data.purchaseIds
    local pendingPromise, pendingParams
    
    local container = Instance.new("Folder")
    local self = wrapper(container, 'Product')
    
    --// Sub Classes
    local Receipt = {}
    Receipt.__index = Receipt
    
    function Receipt.complete(receipt) return self:complete(receipt) end
    function Receipt.processAsync(receipt) return self:processAsync(receipt) end
    
    for _,receipt in data.receipts do setmetatable(receipt, Receipt) end
    
    --// Properties
    self.receipts = data.receipts
    self.id = productId
    
    self.purchased = self:_signal('purchased')
    self.process = function() error(`any processor setted for product {self.name}(#{self.id}) of player {player}`) end
    
    --// Product Info
    local info = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
    container.Name = info.Name
    
    self.minimunMembershipLevel = info.MinimunMembershipLevel
    self.iconId = info.IconImageAssetId
    self.description = info.Description
    self.isPublic = info.IsPublicDomain
    self.price = info.PriceInRobux
    self.name = info.Name
    
    --// Methods
    function self:bind(process: (params: { [string]: any }, receipt: Receipt) -> ())
        
        self.process = process
        
        for _,receiptId in queuedProcessIds do
            
            local receipt = self.receipts[receiptId]
            if not receipt then continue end
            
            receipt:processAsync()
        end
    end
    
    function self:complete(receipt: Receipt)
        
        local index = table.find(queuedProcessIds, receipt.id)
        if index then table.remove(queuedProcessIds, index) end
        
        receipt.processedTimestamp = os.time()
        return receipt
    end
    function self:processAsync(receipt: Receipt): Promise
        
        return Promise.try(self.process, receipt.params, receipt)
            :tap(function() receipt:complete() end)
    end
    
    function self:_awaitSaveReceipt(receipt: Receipt)
        
        assert(profile:IsActive(), `profile isnt active (probably player left the game)`)
        
        table.insert(queuedProcessIds, receipt.id)
        self.receipts[receipt.id] = receipt
        
        receipt:processAsync()
        return profile:awaitSave()
    end
    function self:awaitSavePurchase(rawReceipt)
        
        local promise = pendingPromise
        local purchaseReceiptId = purchaseIds[rawReceipt.PurchaseId] or HttpService:GenerateGUID()
        
        local receipt = self.receipts[purchaseReceiptId] or setmetatable({
            placeId = rawReceipt.PlaceId or game.PlaceId,
            jobId = rawReceipt.JobId or game.JobId,
            currency = rawReceipt.CurrencyType.Name,
            purchaseId = rawReceipt.PurchaseId,
            productId = rawReceipt.ProductId,
            spent = rawReceipt.CurrencySpent,
            purchasedTimestamp = os.time(),
            processedTimestamp = nil,
            params = pendingParams,
            id = purchaseReceiptId,
        }, Receipt)
        purchaseIds[rawReceipt.PurchaseId] = receipt.id
        
        local success, error = pcall(function() self:_awaitSaveReceipt(receipt) end)
        if success then promise:_resolve(receipt) else promise:_reject(error) end
    end
    function self:awaitSaveGive(params): Promise
        
        local receipt = setmetatable({
            id = HttpService:GenerateGUID(),
            purchasedTimestamp = os.time(),
            processedTimestamp = nil,
            productId = productId,
            placeId = game.PlaceId,
            jobId = game.JobId,
            currency = 'None',
            params = params or { promptTimestamp = os.time(), fromClient = false },
            spent = 0,
        }, Receipt)
        return self:_awaitSaveReceipt(receipt)
    end
    
    function self:promptAsync(params: { [string]: any }): Promise<Receipt>
        
        assert(not pendingPromise, `a prompt already pending`)
        
        params = params or {}
        params.fromClient = params.fromClient or false
        params.promptTimestamp = os.time()
        
        local promise = Promise.try(MarketplaceService.PromptProductPurchase, MarketplaceService, player, productId)
            :andThen(coroutine.yield)
        
        pendingPromise = promise
        pendingParams = params
        promise:finally(function()
            
            pendingPromise = nil
            pendingParams = nil
        end)
        return promise
    end
    
    --// Remotes
    local client = Replicator.get(container)
    function client.Prompt(player, params)
        
        params.fromClient = true
        return self:promptAsync(params):expect()
    end
    
    --// End
    products:set(self, player, productId)
    return self
end
export type Product = typeof(Product.new(Instance.new("Player"), 0))

--// Functions
local isProcessing = {}
function MarketplaceService.ProcessReceipt(rawReceipt)
    
    if isProcessing[rawReceipt.PurchaseId] then return end
    isProcessing[rawReceipt.PurchaseId] = true
    
    local player = Players:GetPlayerByUserId(rawReceipt.PlayerId) or error(`player offline`)
    local playerProduct = products:find(player, rawReceipt.ProductId) or error(`product doesnt exists`)
    
    playerProduct:awaitSavePurchase(rawReceipt)
    isProcessing[rawReceipt.PurchaseId] = nil
    
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

--// Types
export type receipt = {
    params: { promptTimestamp: number, fromClient: boolean } & { [string]: any },
    purchasedTimestamp: number,
    processedTimestamp: number,
    purchaseId: number,
    productId: number,
    currency: string,
    placeId: number,
    spent: number,
    id: string,
}
export type Receipt = receipt & {
    processAsync: (Receipt) -> Promise,
    complete: (Receipt) -> (),
}

--// End
return Product