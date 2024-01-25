--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerItemSummoning = require(script.Parent.Parent.ItemSummon)
local PlayerProfile = require(script.Parent.Parent.Profile)
local Event = require(script.Parent.Event)

--// Data
local awaitData = PlayerProfile.subData('Playtime', Event.baseData)

--// Handler
local Playtime = {}
local cache = Cache.new(-1, 'k')
function Playtime.get(player: Player) return cache:find(player) or Playtime.wrap(player) end

--// Adapter
function Playtime.wrap(player: Player)
    
    local data = awaitData(player)
    local playerSummoning = PlayerItemSummoning.get(player)
    
    --// Instance
    local self = Event.new(data, {
        { goal = 1*60*60, claim = function() playerSummoning.luckBoost:add('achivement', 0.01) end },
        { goal = 5*60*60, claim = function() playerSummoning.luckBoost:add('achivement', 0.02) end },
        { goal = 10*60*60, claim = function() playerSummoning.luckBoost:add('achivement', 0.05) end },
        { goal = 25*60*60, claim = function() playerSummoning.luckBoost:add('achivement', 0.10) end },
        { goal = 50*60*60, claim = function() playerSummoning.luckBoost:add('achivement', 0.25) end },
    })
    self:addTags('Playtime')
    self.roblox.Name = 'Playtime'
    self.roblox.Parent = player
    
    --// Detector
    task.spawn(function() while player.Parent == game.Players do
        
        self:increase(task.wait(1))
    end end)
    
    --// End
    cache[player] = self
    return self
end
Entity.query{ tag='LoadedPlayer' }:track(Playtime.get)

--// End
return Playtime