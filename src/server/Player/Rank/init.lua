--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local PlayerProfile = require(script.Parent.Profile)
local PlayerPower = require(script.Parent.Power)

--// Consts
local RANKS = require(game.ReplicatedStorage.Config.Ranks)
local MAX_LEVEL = 5

--// Data
local awaitData = PlayerProfile.subData('Rank', {
    rank = 1,
})

--// Trait
return Entity.trait('PlayerRank', function(self, player: Player, syncs: { rank: number })
    
    local playerPower = PlayerPower.get(player)
    
    --// Data
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    self.requiredPower = RANKS[self.rank+1].requiredPower
    playerPower.boost:set('rank', RANKS[self.rank].powerBoost)
    
    --// Methods
    function self:rankup()
        
        assert(self.rank < MAX_LEVEL, `rank max exceeded`)
        self.rank += 1
        
        self.requiredPower = RANKS[self.rank+1].requiredPower
        playerPower.boost:set('rank', RANKS[self.rank].powerBoost)
    end
end)