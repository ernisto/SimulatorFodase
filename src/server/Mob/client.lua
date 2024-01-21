--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerFarming = require(game.ServerScriptService.Player.Farming)
local PlayerPower = require(game.ServerScriptService.Player.Power)
local PlayerState = require(script.Parent.PlayerState)
local Mob = require(script.Parent)

--// Trait
return Entity.trait('Mob', function(self, model: Mob.entity)
    
    local client = Replicator.get(model)
    local prompt = Instance.new('ProximityPrompt', model.Humanoid.RootPart)
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.RequiresLineOfSight = false
    
    --// Signals
    self.coinsDropped = client:_signal('coinsDropped')
    self.itemsDropped = client:_signal('itemsDropped')
    
    --// Functions
    function client.Attack(player)
        
        local farming = PlayerFarming.get(player)
        farming:consumeCooldown()
        
        local state = PlayerState.get(model, player)
        assert(state:isAlive(), `mob is died`)
        
        self:_listenState(state)
        
        local power = PlayerPower.get(player)
        local damage = power.basePower
        
        local damageDealed = state:takeDamage(damage)
        local pickups = state:pickupDrops()
        
        return damageDealed, pickups
    end
    function client.PickupDrops(player)
        
        local state = PlayerState.get(model, player)
        return state:pickupDrops()
    end
    
    --// Methods
    local listened = Cache.new(-1, 'k')
    function self:_listenState(state)
        
        if listened:find(state) then return end
        listened:set(true, state)
        
        state.coinsDropped:connect(function(amount)
            
            self.coinsDropped:_emitOn({ state.player }, amount)
        end)
        state.itemsDropped:connect(function(name)
            
            self.itemsDropped:_emitOn({ state.player }, name)
        end)
    end
end)