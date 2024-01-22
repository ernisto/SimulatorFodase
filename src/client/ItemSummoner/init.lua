--// Packages
local MarketplaceService = game:GetService('MarketplaceService')

local Replication = require(game.ReplicatedStorage.Packages.Replication)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Entity = require(game.ReplicatedStorage.Packages.Entity)

local LocalSummon = require(game.ReplicatedStorage.Client.LocalSummon)
local Gameplay = require(game.ReplicatedStorage.Client.Gameplay)

--// Types
export type entity = Model & {
    DropRates: Folder,
    PrimaryPart: BasePart & {
        Skip: ProximityPrompt,
        Summon1: ProximityPrompt,
        Summon3: ProximityPrompt,
        SummonAuto: ProximityPrompt?,
        Stop: ProximityPrompt?
    },
    Star: BasePart & {
        Particles: Attachment,
    },
}

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local server = Replication.await(model)
    local skipPrompt = model.PrimaryPart.Skip
    local summon1Prompt = model.PrimaryPart.Summon1
    local summon3Prompt = model.PrimaryPart.Summon3
    local summonAutoPrompt = model.PrimaryPart:FindFirstChild('SummonAuto') :: ProximityPrompt?
    
    self.animationSkipped = self:_signal('animationSkipped')
    self.itemSummoned = self:_signal('itemSummoned')
    
    self.unfocused = self:_signal('unfocused')
    self.focused = self:_signal('focused')
    
    --// Methods
    local function showSkip()
        
        if summonAutoPrompt then summonAutoPrompt.Enabled = false end
        summon1Prompt.Enabled = false
        summon3Prompt.Enabled = false
        skipPrompt.Enabled = true
    end
    local function hideSkip()
        
        if summonAutoPrompt then summonAutoPrompt.Enabled = true end
        summon1Prompt.Enabled = true
        summon3Prompt.Enabled = true
        skipPrompt.Enabled = false
    end
    
    --// Listeners
    summon1Prompt.PromptHidden:Connect(function() self.unfocused:_emit() end)
    summon1Prompt.PromptShown:Connect(function() self.focused:_emit() end)
    
    summon1Prompt.PromptButtonHoldBegan:Connect(function()
        
        local promptTriggered = Promise.fromEvent(summon1Prompt.Triggered)
        summon1Prompt.PromptButtonHoldEnded:Connect(function() promptTriggered:cancel() end)
        
        local item = server:invokeSummon1Async()
            :catch(function(err) Gameplay.error(err.error:gsub("[%w%. ]*:%d+: ", " ")) end)
            :expect()
        
        promptTriggered:await()
        showSkip()
        
        self.itemSummoned:_emit(item)
        hideSkip()
    end)
    summon3Prompt.PromptButtonHoldBegan:Connect(function()
        
        local promptTriggered = Promise.fromEvent(summon3Prompt.Triggered)
        summon3Prompt.PromptButtonHoldEnded:Connect(function() promptTriggered:cancel() end)
        
        local item1, item2, item3 = server:invokeSummon3Async()
            :catch(function(err) Gameplay.error(err.error:gsub("[%w%. ]*:%d+: ", " ")) end)
            :expect()
        
        promptTriggered:await()
        showSkip()
        
        self.itemSummoned:_emit(item1, item2, item3)
        hideSkip()
    end)
    skipPrompt.Triggered:Connect(function()
        
        if not game.Players.LocalPlayer.PlayerItemSummon['Fast Open']:GetAttribute('isOwned') then
            
            MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, game.Players.LocalPlayer.PlayerItemSummon['Fast Open']:GetAttribute('id'))
            Gameplay.error('gamepass required')
            return
        end
        self.animationSkipped:_emit()
    end)
    
    if not summonAutoPrompt then return end
    skipPrompt.UIOffset = Vector2.new(110, -200)
    
    local stopPrompt = model.PrimaryPart.Stop
    local autoSummon
    
    stopPrompt.Triggered:Connect(function()
        
        if not autoSummon then return end
        
        task.cancel(autoSummon)
        stopPrompt.Enabled = false
        hideSkip()
    end)
    summonAutoPrompt.Triggered:Connect(function()
        
        if autoSummon then return end
        
        stopPrompt.Enabled = true
        autoSummon = task.spawn(function() while true do
            
            local item = server:invokeSummon1Async()
                :catch(function(err) Gameplay.error(err.error:gsub("[%w%. ]*:%d+: ", " ")) end)
                :expect()
            
            showSkip()
            
            task.spawn(function() self.itemSummoned:_emit(item) end)
            Promise.all{ Promise.delay(LocalSummon.cooldown), Promise.fromEvent(skipPrompt.Triggered):timeout(5) }:await()
        end
            stopPrompt.Enabled = false
            hideSkip()
        end)
    end)
end)