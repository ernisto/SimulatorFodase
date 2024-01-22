--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local PlayerItemSummon = require(script.Parent)
local PlayerMarket = require(script.Parent.Parent.Market)

--// Trait
return Entity.trait('PlayerItemSummon', function(self, player)
    
    local playerItemSummon = PlayerItemSummon.get(player)
    local market = PlayerMarket.get(player)
    
    self.LuckyPass = self:_host(market:getPass(690116553))
    self.SuperLuckyPass = self:_host(market:getPass(689961949))
    self.MegaLuckyPass = self:_host(market:getPass(689942914))
    
    self.SkipSummonPass = self:_host(market:getPass(689889889))
    self.MultiSummonPass = self:_host(market:getPass(689892916))
    
    --// Binders
    self.SkipSummonPass:bind(function() print('can skip'); playerItemSummon.cooldown = 0 end)
    
    self.LuckyPass:bind(function() playerItemSummon.luckBoost:add('pass', 1/6) end)
    self.SuperLuckyPass:bind(function() playerItemSummon.luckBoost:add('pass', 2/6) end)
    self.MegaLuckyPass:bind(function() playerItemSummon.luckBoost:add('pass', 3/6) end)
end)