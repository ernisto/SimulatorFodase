--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local PlayerProfile = require(script.Parent.Profile)
local WorldBloodline = require(script.World)

--// Consts
local BLOOD_LINES = require(game.ReplicatedStorage.Config.Bloodlines)

--// Data
local worldDatas = {}
for name in BLOOD_LINES do worldDatas[name] = WorldBloodline.baseData end

local awaitData = PlayerProfile.subData('Bloodline', {
    worldDatas = worldDatas
})

--// Trait
return Entity.trait('PlayerBloodline', function(self, player: Player)
    
    --// Data
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    for worldName, worldData in self.worldDatas do
        
        self[worldName] = self:_host(WorldBloodline.new(player, worldName, worldData))
    end
end)