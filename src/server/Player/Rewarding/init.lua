--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RandomOption = require(ReplicatedStorage.Packages.RandomOption)
local Entity = require(ReplicatedStorage.Packages.Entity)
local SpinRewards = require(ReplicatedStorage.Config.Spin)
local Gifts = require(ReplicatedStorage.Config.Gifts)

local ServerStorage = game:GetService("ServerStorage")
local Replicator = require(ServerStorage.Packages.Replicator)

local PlayerProfile = require(script.Parent.Profile)
local PlayerMarket = require(script.Parent.Market)

--// Constsn
local CODES = require(script.CODES)

--// Vars
local spinOption = RandomOption.new(SpinRewards)

--// Data
local awaitRewardingData = PlayerProfile.subData('Rewarding', {
    usedCodes = {},
    spins = 0,
})

--// Trait
return Entity.trait('Rewarding', function(self, player: Player)
    
    --// Instance
    local data = awaitRewardingData(player)
    self:_syncAttributes(data)
    
    self.availableGifts = {}
    self.availableSpins = 0
    
    --// Givers
    local givers = {
        Spin = function(amount) self.spins += amount end,
    }
    
    --// Market
    local market = PlayerMarket.get(player)
    
    market.products[1722935148] = function() self.spins += 10 end
    market.products[1722934939] = function() self.spins += 1 end
    
    --// Client
    local client = Replicator.get(self.roblox)
    
    function client.RedeemCode(player, code: string)
        
        assert(not self.usedCodes[code], `already used`)
        
        for _,reward in CODES[code] or error('invalid code') do
            
            givers[reward.kind](reward.amount, reward.duration, reward.name)
        end
        self.usedCodes[code] = true
    end
    function client.ClaimGift(player, giftIndex: number)
        
        assert(type(giftIndex) == "number", `bad argument #1 (giftIndex)`)
        assert(self.availableGifts[giftIndex] == 'available', `unavailable gift`)
        
        local gift = Gifts[giftIndex]
        givers[gift.kind](gift)
        
        self.availableGifts[giftIndex] = 'claimed'
    end
    function client.Spin(player)
        
        if self.availableSpins > 0 then self.availableSpins -= 1
        elseif self.spins > 0 then self.spins -= 1
        else error(`not enough spins`) end
        
        local reward = spinOption:choice()
        return reward, givers[reward.kind](reward.amount, reward.duration, reward.name)
    end
    
    --// Loop
    task.spawn(function()
        
        while task.wait(30*60) do
            
            self.availableSpins += 1
        end
    end)
    task.spawn(function()
        
        local totalTime = 0
        
        for index, gift in Gifts do
            
            totalTime += task.wait(gift.time - totalTime)
            self.availableGifts[index] = 'available'
        end
    end)
end)