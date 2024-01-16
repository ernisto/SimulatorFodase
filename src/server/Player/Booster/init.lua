--// Packages
local RunService = game:GetService('RunService')
local Entity = require(game.ReplicatedStorage.Packages.Entity)

--// Trait
local Booster = Entity.trait('Booster', function(container, self)
    
    local layerLifetimes = {}
    local layers = {}
    
    self.data = { layers = layers, lifetimes = layerLifetimes }
    self.lowestLifetime = 0
    
    --// Methods
    function self:add(layer: string, boost: number, duration: number?)
        
        layers[layer] = self:get(layer) + boost
        self[layer] = layers[layer]
        
        container.Value = self:get()
        if not duration then return end
        
        if not layerLifetimes[layer] then layerLifetimes[layer] = {} end
        table.insert(layerLifetimes[layer], { boost=boost, duration=duration })
    end
    function self:remove(layer: string, boost: number?)
        
        if not boost then
            
            layers[layer] = nil
            self[layer] = nil
        else
            
            layers[layer] = math.max(1.00, self:get(layer) + boost)
            self[layer] = layers[layer]
        end
        container.Value = self:get()
    end
    function self:get(layer: string?): number
        
        if layer then return layers[layer] or 1.00 end
        local total = 1.00
        
        for _,boost in layers do total *= boost end
        return total
    end
    function self:reset()
        
        for layer in layers do self:remove(layer) end
        table.clear(layerLifetimes)
    end
    
    --// Loop
    self:_host(RunService.Heartbeat:Connect(function(deltaTime)
        
        local allLifetimes = {}
        
        for layer, lifetimes in layerLifetimes do
                
            local index = 0
            repeat index += 1
                
                local lifetime = lifetimes[index]
                if not lifetime then break end
                
                lifetime.duration -= deltaTime
                if lifetime.duration > 0 then table.insert(allLifetimes, lifetime.duration); continue end
                
                table.remove(lifetimes, index)
                self:remove(layer, lifetime.boost)
                index -= 1
                
            until index >= #lifetimes
        end
        self.lowestLifetime = math.ceil(math.min(1/0, unpack(allLifetimes)))
    end))
end)

--// Factory
function Booster.new(name: string)
    
    local container = Instance.new("NumberValue")
    container.Value = 1.00
    container.Name = name
    
    return Booster.get(container)
end

--// End
return Booster