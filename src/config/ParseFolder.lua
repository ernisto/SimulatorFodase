--// Packages
local parseAttributes = require(script.Parent.ParseAttributes)

--// Module
return function<config>(folder: Folder, baseConfig: config, kind: string?): { [string]: config }
    
    local configs = {}
    
    for _,container in folder:GetChildren() do
        
        configs[container.Name] = parseAttributes(container, baseConfig, `{kind or "config"} '{container.Name}'`)
    end
    
    return configs
end