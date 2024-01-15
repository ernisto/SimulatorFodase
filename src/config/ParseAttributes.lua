--// Module
return function<config>(container: Instance, baseConfig: config, label: string?): config
    
    local config = container:GetAttributes()
    
    for index, baseValue in baseConfig do
        
        if typeof(config[index]) == typeof(baseValue) then continue end
        
        warn(`invalid {label or container:GetFullName()}, setting '{index}' (type {typeof(baseValue)})`)
        config[index] = baseValue
    end
    
    return config
end