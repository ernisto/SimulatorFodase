--// Packages
local Fusion = require(game.ReplicatedStorage.Shared.Fusion)
local shortNumber = require(game.ReplicatedStorage.Shared.shortNumber)
local shortTime = require(game.ReplicatedStorage.Shared.shortTime)

--// Scope
return Fusion:scoped{
    watch = function(scope, instance, name: string)
        
        local canRead = pcall(function() return instance[name] end)
        local output = scope:Value()
        
        scope:Hydrate(instance) {
            [if canRead then Fusion.Out(name) else Fusion.AttributeOut(name)] = output
        }
        return output
    end,
    shortNumber = function(scope, input)
        
        return scope:Computed(function(use) return shortNumber(use(input)) end)
    end,
    shortTime = function(scope, input)
        
        return scope:Computed(function(use) return shortTime(use(input)) end)
    end,
}