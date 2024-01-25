--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerCurrency = require(script.Parent.Parent.Currency)
local PlayerProfile = require(script.Parent.Parent.Profile)
local Event = require(script.Parent.Event)

--// Data
local awaitData = PlayerProfile.subData('TotalCoins', Event.baseData)

--// Handler
local TotalCoins = {}
local cache = Cache.new(-1, 'k')
function TotalCoins.get(player: Player) return cache:find(player) or TotalCoins.wrap(player) end

--// Adapter
function TotalCoins.wrap(player: Player)
    
    local data = awaitData(player)
    local playerCurrency = PlayerCurrency.get(player)
    
    --// Instance
    local self = Event.new(data, {})
    self:addTags('TotalCoins')
    self.roblox.Name = 'TotalCoins'
    self.roblox.Parent = player
    
    --// Detector
    playerCurrency:listenChange('amount'):connect(function(new, last)
        
        if new > last then self:increase(new - last) end
    end)
    
    --// End
    cache[player] = self
    return self
end
Entity.query{ tag='LoadedPlayer' }:track(TotalCoins.get)

--// End
return TotalCoins