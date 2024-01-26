--// Packages
local Replicator = require(game.ServerStorage.Packages.Replicator)
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)

--// Handler
local Event = {}

--// Types
export type goal = { goal: number, claim: () -> () }

--// Data
Event.baseData = {
    value = 0,
    pickedRewards = {} :: {boolean},
}
export type data = typeof(Event.baseData)

--// Trait
function Event.new(data: data, goals: {goal})
    
    local container = Instance.new('ObjectValue')
    container.Value = script
    
    local client = Replicator.get(container)
    local self = wrapper(container, 'Statistic')
    self:_syncAttributes(data)
    
    self.availableClaim = nil :: number?
    self.nextGoal = if goals[1] then goals[1].goal else 1/0
    self.goals = goals
    self.level = 1
    
    --// Methods
    function self:increase(increment: number)
        
        self.value += increment
        self:updateLevel()
    end
    function self:set(value: number)
        
        self.value = value
        self:updateLevel()
    end
    function self:claimReward(level: number)
        
        assert(self.level >= level, `reward not available`)
        assert(data.pickedRewards[tostring(level)] == nil, `reward already claimed`)
        
        data.pickedRewards[tostring(level)] = true
        self:updateClaim()
        
        goals[level].claim()
    end
    
    function self:updateClaim()
        
        for level in goals do
            
            if data.pickedRewards[tostring(level)] then continue end
            if level >= self.level then continue end
            
            self.availableClaim = level
            return
        end
        self.availableClaim = nil
    end
    function self:updateLevel()
        
        while self.value >= self.nextGoal do
            
            self.level += 1
            self.nextGoal = if goals[self.level] then goals[self.level].goal else math.huge
        end
    end
    self:updateClaim()
    self:updateLevel()
    
    --// Remotes
    function client.Claim(player, level: number)
        
        return self:claimReward(level or self.availableClaim or error(`not available rewards`))
    end
    
    --// End
    return self
end

--// End
return Event