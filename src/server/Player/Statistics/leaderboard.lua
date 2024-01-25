--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Leaderboard = require(game.ServerScriptService.Leaderboard)

local Playtime = require(script.Parent.Playtime)
local PlayerPower = require(script.Parent.Parent.Power)
local PlayerCurrency = require(script.Parent.Parent.Currency)

--// Tag
Entity.query{ tag='LoadedPlayer' }:track(function(player)
    
    local playtimeLeaderboard = Leaderboard.get('PlaytimeLeaderboard'):wrap(player)
    local powerLeaderboard = Leaderboard.get('PowerLeaderboard'):wrap(player)
    local coinsLeaderboard = Leaderboard.get('CoinsLeaderboard'):wrap(player)
    
    local power = PlayerPower.get(player)
    power:listenChange('basePower'):connect(function(powerAmount) powerLeaderboard:queueUpdate(powerAmount) end)
    
    local currency = PlayerCurrency.get(player)
    currency:listenChange('amount'):connect(function(coins) coinsLeaderboard:queueUpdate(coins) end)
    
    local playtime = Playtime.get(player)
    playtime:listenChange('value'):connect(function(time) playtimeLeaderboard:queueUpdate(time) end)
end)

--// End
return nil