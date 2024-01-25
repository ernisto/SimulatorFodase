--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerPower = require(script.Parent.Parent.Power)
local PlayerProfile = require(script.Parent.Parent.Profile)
local Event = require(script.Parent.Event)

--// Data
local awaitData = PlayerProfile.subData('TotalPower', Event.baseData)

--// Handler
local TotalPower = {}
local cache = Cache.new(-1, 'k')
function TotalPower.get(player: Player) return cache:find(player) or TotalPower.wrap(player) end

--// Adapter
function TotalPower.wrap(player: Player)
    
    local data = awaitData(player)
    local playerPower = PlayerPower.get(player)
    
    --// Instance
    local self = Event.new(data, {})
    self:addTags('TotalPower')
    self.roblox.Name = 'TotalPower'
    self.roblox.Parent = player
    
    --// Detector
    playerPower:listenChange('basePower'):connect(function(new, last)
        
        if new > last then self:increase(new - last) end
    end)
    
    --// End
    cache[player] = self
    return self
end
Entity.query{ tag='LoadedPlayer' }:track(TotalPower.get)

--// End
return TotalPower