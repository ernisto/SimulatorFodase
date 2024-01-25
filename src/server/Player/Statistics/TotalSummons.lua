--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerItemSummoning = require(script.Parent.Parent.ItemSummon)
local PlayerProfile = require(script.Parent.Parent.Profile)
local Event = require(script.Parent.Event)

--// Data
local awaitData = PlayerProfile.subData('TotalSummons', Event.baseData)

--// Handler
local TotalSummons = {}
local cache = Cache.new(-1, 'k')
function TotalSummons.get(player: Player) return cache:find(player) or TotalSummons.wrap(player) end

--// Adapter
function TotalSummons.wrap(player: Player)
    
    local data = awaitData(player)
    local playerSummoning = PlayerItemSummoning.get(player)
    
    --// Instance
    local self = Event.new(data, {
        { goal = 200, claim = function() playerSummoning.bonus += 1 end },
        { goal = 500, claim = function() playerSummoning.bonus += 1 end },
        { goal = 1500, claim = function() playerSummoning.bonus += 1 end },
        { goal = 3000, claim = function() playerSummoning.bonus += 1 end },
    })
    self:addTags('TotalSummons')
    self.roblox.Name = 'TotalSummons'
    self.roblox.Parent = player
    
    --// Detector
    playerSummoning.itemSummoned:connect(function() self:increase(1) end)
    
    --// End
    cache[player] = self
    return self
end
Entity.query{ tag='LoadedPlayer' }:track(TotalSummons.get)

--// End
return TotalSummons