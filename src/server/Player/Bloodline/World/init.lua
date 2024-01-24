--// Packages
local RandomOption = require(game.ReplicatedStorage.Packages.RandomOption)
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local Booster = require(game.ServerScriptService.Booster)
local PlayerFarming = require(script.Parent.Parent.Farming)

--// Consts
local BLOOD_LINES = require(game.ReplicatedStorage.Config.Bloodlines)

--// Handler
local WorldBloodline = {}
local cache = Cache.new(-1, 'k')

function WorldBloodline.get(entity) return cache:find(entity) end

--// Data
WorldBloodline.baseData = {
    tokens = 0,
    bloodline = 'none',
}
export type data = typeof(WorldBloodline.baseData)

--// Component
function WorldBloodline.new(player: Player, worldName: string, data: data)
    
    local worldBloodlines = BLOOD_LINES[worldName]
    local randomBloodline = RandomOption.new()
    for name, info in worldBloodlines do randomBloodline:add(info.rate, name) end
    
    local farming = PlayerFarming.get(player)
    local container = Instance.new('Folder')
    container.Name = worldName
    
    --// Instance
    local self = wrapper(container, 'WorldBloodline')
    self:_syncAttributes(data)
    
    self.boost = self:_host(Booster.new('tokensBooster'))
    
    --// Methods
    function self:roll()
        
        self:consume(1)
        local bloodline = randomBloodline:choice()
        
        self:setBloodline(bloodline)
        return bloodline
    end
    function self:setBloodline(name: string)
        
        local info = worldBloodlines[name] or { damageBoost = 1.00 }
        
        self.bloodline = name
        farming.damageBoost:set(`bloodline-{worldName}`, info.damageBoost)
    end
    
    function self:add(amount: number)
        
        self.tokens += amount
    end
    function self:consume(amount: number)
        
        assert(self.tokens >= amount, `not enough tokens`)
        self.tokens -= amount
    end
    
    self:setBloodline(self.bloodline)
    
    --// End
    cache:set(self, container)
    return self
end

--// End
return WorldBloodline