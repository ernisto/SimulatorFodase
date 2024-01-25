--// Packages
local DataStoreService = game:GetService('DataStoreService')

local Promise = require(game.ReplicatedStorage.Packages.Promise)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

--// Handler
local Leaderboard = {}

local leaderboards = Cache.new(-1)
function Leaderboard.get(name: string) return leaderboards:find(name) or Leaderboard.new(name) end

--// Component
function Leaderboard.new(name: string)
    
    local container = Instance.new('Folder', game.ReplicatedStorage)
    container.Name = name
    container:AddTag('Leaderboard')
    
    --// Instance
    local store = DataStoreService:GetOrderedDataStore(name)
    local queuedUpdates = {}
    local self = {}
    
    --// Methods
    function self:listAsync(ascending: boolean, pageSize: number, minValue: number?, maxValue: number?)
        
        return Promise.try(store.GetSortedAsync, store,  ascending, pageSize, minValue, maxValue)
    end
    
    local players = Cache.new(-1, 'k')
    function self:wrap(player: Player)
        
        if players:find(player) then return players:find(player) end
        
        local playerRank = {}
        
        function playerRank:queueUpdate(value: number)
            
            queuedUpdates[player.UserId] = value
        end
        
        players:set(playerRank, player)
        return playerRank
    end
    
    --// Setup
    for rank = 1, 100 do Instance.new("Folder", container).Name = `{rank}` end
    
    --// Loops
    task.delay(10, function()
        
        repeat
            for userId, value in queuedUpdates do
                
                if not value then continue end
                task.spawn(pcall, store.SetAsync, store, userId, value // 1)
            end
            queuedUpdates = {}
            
            for rank, entry in store:GetSortedAsync(false, 100):GetCurrentPage() do
                
                local container = container:FindFirstChild(`{rank}`)
                container:SetAttribute('value', entry.value)
                container:SetAttribute('key', entry.key)
            end
        until not task.wait(5*60)
    end)
    
    --// End
    leaderboards:set(self, name)
    return self
end

--// End
return Leaderboard