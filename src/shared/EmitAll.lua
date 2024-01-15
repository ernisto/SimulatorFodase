--// Module
local function emit(container: Instance)
    
    if container:IsA("ParticleEmitter") then task.delay(container:GetAttribute("EmitDelay") or 0, container.Emit, container, container:GetAttribute("EmitCount"))
    elseif container:IsA("Sound") then task.delay(container:GetAttribute("PlayDelay") or 0, container.Play, container)
    elseif container:HasTag("Random") then
        
        local shouldBeUnique = container:GetAttribute("ShouldBeUnique")
        local options = container:GetChildren()
        local choices = {}
        
        for _ = 1, container:GetAttribute("Choices") or 1 do
            
            local key = math.random(1, #options)
            while shouldBeUnique and choices[key] do key = (key+1) % #options end
            
            choices[key] = true
            emit(options[key])
        end
        return
    end
    
    for _,child in container:GetChildren() do emit(child) end
end

--//  End
return emit