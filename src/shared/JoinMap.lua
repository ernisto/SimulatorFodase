--// Module
local function joinMap<template, target>(template: template, target: target): target & template
    
    assert(type(target) == 'table')
    assert(type(template) == 'table')
    
    for index, default in template do
        
        local value = target[index]
        
        if type(default) == "table" then target[index] = joinMap(default, if typeof(value) == "table" then value else {})
        elseif value == nil then target[index] = default
        end
    end
    
    return target
end
return joinMap