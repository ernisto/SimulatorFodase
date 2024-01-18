--// Packages
local parseAttributes = require(game.ReplicatedStorage.Config.ParseAttributes)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Equipment = require(script.Parent)

local PlayerCurrency = require(game.ServerScriptService.Player.Currency)
local PlayerPower = require(game.ServerScriptService.Player.Power)

--// Config
local baseConfig = {
    powerBoost = 0.00,
    coinBoost = 0.00,
}
export type config = typeof(baseConfig)

--// Trait
local Amplifing
local Amplifier = Entity.trait('Amplifier', function(self, model: Equipment.entity, syncs: config)
    
    local equipment = if model:HasTag('Equipment')
        then Equipment.Equipment.get(model)
        else error(`this entity cannot be equipped`)
    
    --// Config
    local config = parseAttributes(model, baseConfig)
    self:_syncAttributes(config)
    
    --// Listeners
    equipment.unequipped:connect(function() Amplifing.get(model):destroy() end)
    equipment.equipped:connect(function() Amplifing.get(model) end)
end)

--// States
Amplifing = Entity.trait('Amplifing', function(self, model: Equipment.entity)
    
    local equipped = Equipment.Equipped.get(model) or error(`entity didnt equipped`)
    local amplifier = Amplifier.get(model) or error(`entity cant amplify`)
    
    local player = game.Players:GetPlayerFromCharacter(equipped.handler.Parent)
    if not player then return end
    
    local currency = PlayerCurrency.get(player)
    local power = PlayerPower.get(player)
    
    --// Job
    if amplifier.coinBoost then currency.boost:add('item', amplifier.coinBoost) end
    if amplifier.powerBoost then power.boost:add('item', amplifier.powerBoost) end
    
    self:cleaner(function()
        
        if amplifier.coinBoost then currency.boost:remove('item', amplifier.coinBoost) end
        if amplifier.powerBoost then power.boost:remove('item', amplifier.powerBoost) end
    end)
end)

--// End
return { Amplifier = Amplifier, Amplifing = Amplifing }