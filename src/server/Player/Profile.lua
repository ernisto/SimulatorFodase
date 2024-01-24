--// Packages
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local ProfileService = require(ServerStorage.Packages.ProfileService)

--// Module
local PlayerProfile = {}

--// Data
local baseData = {}
function PlayerProfile.subData<subData>(kind: string, template: subData)
    
    assert(baseData[kind] == nil, `kind '{kind}' already using`)
    baseData[kind] = template
    
    return function(player: Player): subData
        
        return PlayerProfile.awaitData(player)[kind]
    end
end
function PlayerProfile.awaitData(player: Player)
    
    local profile = PlayerProfile.awaitProfile(player)
    return profile.Data
end

--// Vars
local playerProfileStore = ProfileService.GetProfileStore("Players", baseData)

--// Cache
local loadingProfiles = setmetatable({}, { __mode = "k" })
local profiles = setmetatable({}, { __mode = "k" })

function PlayerProfile.awaitProfile(player: Player)
    
    while loadingProfiles[player] do task.wait() end
    return profiles[player] or PlayerProfile.wrap(player)
end
function PlayerProfile.findProfile(player: Player)
    
    return profiles[player]
end

--// Factory
function PlayerProfile.wrap(player: Player)
    
    loadingProfiles[player] = true
    
    --// Instance
    local profile = playerProfileStore:LoadProfileAsync(tostring(player.UserId), "ForceLoad")
    loadingProfiles[player] = nil
    
    assert(profile, `hasnt possible load profile`)
    
    --// Methods
    function profile:awaitSave()
        
        local release = Instance.new("BindableEvent")
        
        profile.KeyInfoUpdated:Connect(function() release:Fire() end)
        release.Event:Wait()
    end
    
    --// Listeners
    profile:ListenToRelease(function()
        
        profiles[player] = nil
        player:Kick()
    end)
    
    --// Setup
    profile:AddUserId(player.UserId) -- GDPR compliance
    profile:Reconcile()
    
    if player:IsDescendantOf(Players) == true then
        
        profiles[player] = profile
    else
        
        profile:Release()
        error(`already quited`)
    end
    
    --// Cleaner
    player.Destroying:Connect(function() profile:Release() end)
    
    --// End
    profiles[player] = profile
    return profile
end

--// End
return PlayerProfile