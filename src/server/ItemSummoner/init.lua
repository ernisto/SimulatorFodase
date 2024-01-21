--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)

local RandomOption = require(game.ReplicatedStorage.Packages.RandomOption)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerSummoningMarket = require(game.ServerScriptService.Player.ItemSummon.market)
local PlayerSummoning = require(game.ServerScriptService.Player.ItemSummon)
local PlayerInventory = require(game.ServerScriptService.Player.Inventory)
local PlayerMarket = require(game.ServerScriptService.Player.Market)

local Item = require(game.ServerScriptService.Inventory.Item)

--// Types
export type entity = Model & {
    DropRates: Folder,
    PrimaryPart: BasePart & {
        Summon1: ProximityPrompt,
        Summon3: ProximityPrompt,
    }
}

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local client = Replicator.get(model)
    local rootPart = model.PrimaryPart
    local randomItemName = RandomOption.new(model.DropRates:GetAttributes())
    
    --// Remotes
    function client.Summon3(player)
        
        local summoning = PlayerSummoning.get(player)
        summoning:consumeCooldown()
        
        local summonMarket = PlayerSummoningMarket.get(player)
        summonMarket.MultiSummonPass:expect()
        
        local productId = rootPart.Summon3:GetAttribute('productId')
        if productId then PlayerMarket.get(player):getProduct(productId):expect() end
        
        local items = {}
        for count = 1, 3 do items[count] = self:summon(player, summoning).roblox end
        
        return unpack(items)
    end
    function client.Summon1(player)
        
        local summoning = PlayerSummoning.get(player)
        summoning:consumeCooldown()
        
        local productId = rootPart.Summon1:GetAttribute('productId')
        if productId then PlayerMarket.get(player):getProduct(productId):expect() end
        
        return self:summon(player, summoning)
    end
    
    --// Methods
    function self:summon(player, playerSummoning)
        
        local inventory = PlayerInventory.get(player)
        local itemName = randomItemName:choice()
        local item = Item.new{ name=itemName }
        
        inventory:addItem(item)
        return item.roblox
    end
end)