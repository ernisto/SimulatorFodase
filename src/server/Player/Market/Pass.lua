--// Packages
local MarketplaceService = game:GetService('MarketplaceService')
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerProfile = require(script.Parent.Parent.Profile)

--// Module
local Pass = {}
local passes = Cache.new(-1, 'k')

--// Data
local awaitData = PlayerProfile.subData('gamepasses', {})

--// Factory
function Pass.new(player: Player, gamepassId: number)
    
    local gamepasses = awaitData(player)
    
    local container = Instance.new("Folder")
    local self = wrapper(container, 'Pass')
    self.id = gamepassId
    
    --// Pass Owning
    self.isOwned = table.find(gamepasses, gamepassId) or false
    Promise.retry(function() if gamepasses[gamepassId] or MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) then self.isOwned = true end end, -1)
    
    --// Pass Info
    local info = MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
    container.Name = info.Name
    
    self.minimunMembershipLevel = info.MinimunMembershipLevel
    self.iconId = info.IconImageAssetId
    self.description = info.Description
    self.isPublic = info.IsPublicDomain
    self.price = info.PriceInRobux
    self.name = info.Name
    
    --// Methods
    function self:expect(message: string?)
        
        if not self.isOwned then self:prompt() end
        assert(self.isOwned, message or `gamepass '{self.name}' (#{self.id}) expected`)
    end
    function self:bind(binder: () -> ())
        
        if self.isOwned then binder() end
        self:listenChange('ísOwned'):connect(binder)
    end
    function self:give()
        
        gamepasses[gamepassId] = os.time()
        self.isOwned = true
    end
    function self:prompt()
        
        MarketplaceService:PromptGamePassPurchase(player, gamepassId)
    end
    
    --// End
    passes:set(self, player, gamepassId)
    return self
end
export type Pass = typeof(Pass.new(Instance.new("Player"), 0))

--// Listeners
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
    
    if not wasPurchased then return end
    
    local pass = passes:find(player, gamepassId)
    if pass then pass.isOwned = true end
end)

--// End
return Pass