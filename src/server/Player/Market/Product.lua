--// Packages
local MarketplaceService = game:GetService('MarketplaceService')
local Players = game:GetService('Players')

local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local Replicator = require(game.ServerStorage.Packages.Replicator)
local PlayerProfile = require(script.Parent.Parent.Profile)

--// Module
local Product = {}
local products = Cache.new(-1, 'k')

--// Data
local awaitData = PlayerProfile.subData('products', {})

--// Factory
function Product.new(player: Player, productId: number)
    
    local receipts = awaitData(player)
    
    local container = Instance.new("Folder")
    local self = wrapper(container, 'Product')
    self.queuedPurchaseDatas = {}
    self.queuedPrompts = {}
    self.receipts = receipts
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
    function self:bind(process: (receipt: receipt) -> ())
        
        self.process = process
    end
    function self:give()
        
        products[productId] = os.time()
    end
    function self:promptAsync(purchaseData: { [string]: any })
        
        purchaseData = purchaseData or {}
        purchaseData.fromClient = purchaseData.fromClient or false
        purchaseData.promptTimestamp = os.time()
        
        local promptResult = Promise.new(coroutine.yield)
        table.insert(self.queuedPrompts, promptResult)
        table.insert(self.queuedPurchaseDatas, purchaseData)
        
        MarketplaceService:PromptProductPurchase(player, productId)
        return promptResult
    end
    
    local client = Replicator.get(container)
    function client.Prompt(player, data)
        
        data.fromClient = true
        return self:promptAsync(data):expect()
    end
    
    --// End
    products:set(self, player, productId)
    return self
end
export type Product = typeof(Product.new(Instance.new("Player"), 0))

--// Functions
local isProcessing = {}
local function processReceipt(_receipt, player)
    
    local profile = PlayerProfile.findProfile(player) or error(`inative profile`)
    local playerProduct = products:find(player, _receipt.ProductId)
    
    assert(isProcessing[_receipt.PurchaseId], `already processing`)
    isProcessing[_receipt.PurchaseId] = true
    
    local receipt = {
        purchaseId = _receipt.PurchaseId,
        productId = _receipt.ProductId,
        placeId = _receipt.PurchasePlaceId,
        spent = _receipt.CurrencySpent,
        currency = _receipt.CurrencyType,
        timestamp = os.time(),
        data = table.remove(playerProduct.queuedPurchaseDatas),
    }
    playerProduct.process(receipt)
    table.insert(playerProduct.receipts, 1, receipt)
    
    assert(profile:IsActive(), `profile must to be active`)
    profile:awaitSave()
end
function MarketplaceService.ProcessReceipt(receipt)
    
    if isProcessing[receipt.PurchaseId] then return end
    isProcessing[receipt.PurchaseId] = true
    
    local player = Players:GetPlayerByUserId(receipt.PlayerId) or error(`player offline`)
    local playerProducts = products:find(player, receipt.ProductId) or error(`product doesnt exists`)
    local prompt = table.remove(playerProducts.queuedPrompts)
    
    local success, result = xpcall(processReceipt,
        function(message) isProcessing[receipt.PurchaseId] = nil; return message end,
        receipt, player
    )
    if prompt then
        
        if success then prompt:_resolve(result) else prompt:_reject(result) end
    end
    assert(success, result)
    
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

--// Types
export type receipt = {
    purchaseId: number,
    productId: number,
    timestamp: number,
    placeId: number,
    spent: number,
    currency: string,
    data: { promptTimestamp: number, fromClient: boolean } & { [string]: any },
}

--// End
return Product