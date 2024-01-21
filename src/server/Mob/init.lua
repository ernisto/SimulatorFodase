--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local RandomOption = require(game.ReplicatedStorage.Packages.RandomOption)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

--// Types
export type entity = Model & {
    Humanoid: Humanoid,
    DropRates: Folder,
}

--// Config
local baseConfig = {
    coins = NumberRange.new(0, 0),
    respawnTime = 30,
    maxHealth = 0,
}
export type config = typeof(baseConfig)

--// Trait
return Entity.trait('Mob', function(self, model: entity, syncs: config)
    
    local randomItemName = RandomOption.new(model.DropRates:GetAttributes())
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    --// Methods
    function self:getItemName()
        
        return randomItemName:choice()
    end
    function self:getCoins(): number
        
        return math.random(self.coins.Min, self.coins.Max)
    end
end)