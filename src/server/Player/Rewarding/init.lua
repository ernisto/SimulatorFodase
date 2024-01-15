--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RandomOption = require(ReplicatedStorage.Packages.RandomOption)
local WoodStack = require(ReplicatedStorage.Shared.WoodStack)
local wrapper = require(ReplicatedStorage.Packages.Wrapper)
local SpinRewards = require(ReplicatedStorage.Config.Spin)
local Gifts = require(ReplicatedStorage.Config.Gifts)

local ServerStorage = game:GetService("ServerStorage")
local Replicator = require(ServerStorage.Packages.Replicator)

local PlayerChopping = require(script.Parent.ChoppingSystem)
local Axe = require(script.Parent.ChoppingSystem.Axe)
local PlayerProfile = require(script.Parent.Profile)
local PlayerMarket = require(script.Parent.Market)

--// Module
local Rewarding = {}

--// Vars
local spinOption = RandomOption.new(SpinRewards)

--// Consts
local CODES = {
    lumberlegends = { { kind='Money', amount=1500 } },
    welcome = { { kind='Money', amount=250 }, { kind='Woods', amount=250 } },
    woodman = { { kind='Woods', amount=500 } }
}

--// Data
Rewarding.baseData = {
    usedCodes = {},
    spins = 0,
}
local awaitRewardingData = PlayerProfile.subData('Rewarding', Rewarding.baseData)
export type data = typeof(Rewarding.baseData)

--// Cache
local cache = setmetatable({}, { __mode = 'k' })
local onLoad = setmetatable({}, { __mode = 'k' })
function Rewarding.get(player: Player) return cache[player] or onLoad[player] and onLoad[player]:await() or Rewarding.wrap(player) end

--// Factory
function Rewarding.wrap(player: Player)
    
    local container = Instance.new("Folder", player)
    container.Name = "Rewarding"
    
    --// Instance
    local client = Replicator.get(container)
    
    local self = wrapper(container, 'Rewarding')
    self.availableGifts = {}
    self.availableSpins = 0
    
    onLoad[player] = self:_signal("onLoad")
    self.data = awaitRewardingData(player)
    self:_syncAttributes(self.data)
    
    local function randomAxeName()
        
        local children = game.ReplicatedStorage.Assets.AxeModels:GetChildren()
        return children[math.random(1, #children)].Name
    end
    
    local chopping = PlayerChopping.get(player)
    local market = PlayerMarket.get(player)
    local givers = {
        GiveAxe = function(amount, duration, name)
            
            name = name or randomAxeName()
            
            chopping:addAxe(Axe.deserialize{ name=name })
            return `a '{name}'`
        end,
        PowerBoost = function(amount, duration) chopping.powerBooster:add('rewarding', amount, duration) end,
        MoneyBoost = function(amount, duration) chopping.moneyBooster:add('rewarding', amount, duration) end,
        WoodsBoost = function(amount, duration) chopping.woodsBooster:add('rewarding', amount, duration) end,
        Woods = function(amount) chopping:forceStoreWoods(WoodStack.deserialize{ Oak = { stick = amount } }) end,
        Power = function(amount) chopping:addBasePower(amount) end,
        Money = function(amount) chopping:addMoney(amount) end,
        Spin = function(amount) self.spins += amount end,
    }
    
    function client.RedeemCode(player, code: string)
        
        assert(not self.usedCodes[code], `already used`)
        
        for _,reward in CODES[code] or error('invalid code') do
            
            givers[reward.kind](reward.amount, reward.duration, reward.name)
        end
        self.usedCodes[code] = true
    end
    
    --// Market
    market.products[1722935148] = function() self.spins += 10 end
    market.products[1722934939] = function() self.spins += 1 end
    
    --// Spins
    function client.Spin()
        
        if self.availableSpins > 0 then self.availableSpins -= 1
        elseif self.spins > 0 then self.spins -= 1
        else error(`not enough spins`) end
        
        local reward = spinOption:choice()
        return reward, givers[reward.kind](reward.amount, reward.duration, reward.name)
    end
    task.spawn(function()
        
        while task.wait(30*60) do
            
            self.availableSpins += 1
        end
    end)
    
    --// Gifts
    function client.ClaimGift(_,giftIndex: number)
        
        assert(type(giftIndex) == "number", `bad argument #1 (giftIndex)`)
        assert(self.availableGifts[giftIndex] == 'available', `unavailable gift`)
        
        local gift = Gifts[giftIndex]
        givers[gift.kind](gift.amount, gift.duration)
        
        self.availableGifts[giftIndex] = 'claimed'
    end
    task.spawn(function()
        
        local totalTime = 0
        
        for index, gift in Gifts do
            
            totalTime += task.wait(gift.time - totalTime)
            self.availableGifts[index] = 'available'
        end
    end)
    
    --// End
    onLoad[player]:_emit(self)
    cache[player] = self
    return self
end

--// End
return Rewarding