--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerFarming = require(script.Parent.Parent.Farming)
local PlayerProfile = require(script.Parent.Parent.Profile)
local Event = require(script.Parent.Event)

--// Data
local awaitData = PlayerProfile.subData('TotalKills', Event.baseData)

--// Handler
local TotalKills = {}
local cache = Cache.new(-1, 'k')
function TotalKills.get(player: Player) return cache:find(player) or TotalKills.wrap(player) end

--// Adapter
function TotalKills.wrap(player: Player)
    
    local data = awaitData(player)
    local playerFarming = PlayerFarming.get(player)
    
    --// Instance
    local self = Event.new(data, {
        { goal = 500, claim = function() playerFarming.damageBoost:add('achivement', 0.05) end },
        { goal = 1500, claim = function() playerFarming.damageBoost:add('achivement', 0.05) end },
        { goal = 3000, claim = function() playerFarming.damageBoost:add('achivement', 0.07) end },
        { goal = 5000, claim = function() playerFarming.damageBoost:add('achivement', 0.10) end }
    })
    self:addTags('TotalKills')
    self.roblox.Name = 'TotalKills'
    self.roblox.Parent = player
    
    --// Setup
    for level, goal in self.goals do
        
        if self.value >= goal.goal and self.pickedRewards[level] then goal.claim() end
    end
    
    --// Detector
    playerFarming.mobKilled:connect(function() self:increase(1) end)
    
    --// End
    cache[player] = self
    return self
end
Entity.query{ tag='LoadedPlayer' }:track(TotalKills.get)

--// End
return TotalKills