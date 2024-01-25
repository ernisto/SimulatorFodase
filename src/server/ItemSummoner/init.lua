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

local function getLuckTargets(dropRates)
    
    local luckTargets = {}
    for name, rate in dropRates do
        
        table.insert(luckTargets, { name=name, rate=rate })
    end
    table.sort(luckTargets, function(a, b) return a.rate < b.rate end)
    
    return { luckTargets[1].name, luckTargets[2].name }
end

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local dropRates = model.DropRates:GetAttributes()
    local luckTargets = getLuckTargets(dropRates)
    
    local client = Replicator.get(model)
    local rootPart = model.PrimaryPart
    
    --// Remotes
    function client.Summon3(player)
        
        local summoning = PlayerSummoning.get(player)
        summoning:consumeCooldown()
        
        local summonMarket = PlayerSummoningMarket.get(player)
        summonMarket.MultiSummonPass:expect()
        
        local productId = rootPart.Summon3:GetAttribute('productId')
        if productId then PlayerMarket.get(player):getProduct(productId):promptAsync():expect():complete() end
        
        return self:summon(player, summoning, 3+summoning.bonus)
    end
    function client.Summon1(player)
        
        local summoning = PlayerSummoning.get(player)
        summoning:consumeCooldown()
        
        local productId = rootPart.Summon1:GetAttribute('productId')
        if productId then PlayerMarket.get(player):getProduct(productId):promptAsync():expect():complete() end
        
        return self:summon(player, summoning, 1+summoning.bonus)
    end
    
    --// Methods
    function self:summon(player, playerSummoning, count: number)
        
        local buffedRates = table.clone(dropRates)
        for _,name in luckTargets do buffedRates[name] *= playerSummoning.luckBoost:get() end
        for name, rate in buffedRates do buffedRates[name] = rate*100 end   -- avoid fractional rates
        
        local randomItemName = RandomOption.new(buffedRates)
        local inventory = PlayerInventory.get(player)
        local itemNames = {}
        
        for index = 1, count do
            
            local itemName = randomItemName:choice()
            local item = Item.new{ name=itemName }
            
            inventory:addItem(item)
            itemNames[index] = itemName
            
            playerSummoning.itemSummoned:_emit(item)
        end
        
        return itemNames
    end
end)