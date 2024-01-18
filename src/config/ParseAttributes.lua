--// Module
return function<config>(container: Instance, baseConfig: config, label: string?): config
    
    local attributes = container:GetAttributes()
    local config = table.clone(baseConfig :: any)
    
    for index, baseValue in baseConfig :: any do
        
        local attribute = attributes[index]
        if typeof(attribute) == typeof(baseValue) then config[index] = attribute
        else warn(`invalid {label or container:GetFullName()}, setting '{index}' (type {typeof(baseValue)})`)
        end
    end
    
    return config
end