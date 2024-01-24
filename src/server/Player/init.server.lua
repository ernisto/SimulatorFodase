--// Packages
local Players = game:GetService("Players")
local PlayerProfile = require(script.Profile)

--// Vars
local SystemModules = {}
for _,Module in script:GetChildren() do
    
    if not Module:IsA('ModuleScript') then continue end
    if Module.Name == "Profile" then continue end
    
    SystemModules[Module.Name] = require(Module)
end

--// Listeners
Players.PlayerAdded:Connect(function(player)
    
    --// Profile
    local success, profile = pcall(PlayerProfile.wrap, player)
    if not success then player:Kick(`hasnt possible load ur data`); return end
    
    --// Character
    player:LoadCharacter()
    local character = player.Character
    
    local humanoid
        repeat humanoid = character:FindFirstChildOfClass("Humanoid")
        until humanoid
        or not task.wait()
    
    --// Features
    warn("initializing player mechanics")
    print(`humanoid: {humanoid:GetFullName()}, data:`, profile.Data)
    
    for _,SystemModule in SystemModules do
        
        if SystemModule.get then task.spawn(SystemModule.get, player) end
    end
    
    --// End
    repeat
        character.Destroying:Wait()
        if not player.Parent then break end
        
        player:LoadCharacter()
    until false
end)