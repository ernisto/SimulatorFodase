--// Packages
local Cache = require(game.ReplicatedStorage.Packages.Cache)
local PlayerProfile = require(script.Parent.Profile)

local Inventory = require(game.ServerScriptService.Inventory)
local Item = require(game.ServerScriptService.Inventory.Item)

--// Data
local awaitData = PlayerProfile.subData('Inventory', {
    equippedAmounts = {} :: { [string]: number },
    itemDatas = {} :: {Item.data},
    slots = 30,
})

--// Handler
local PlayerInventory = {}

local cache = Cache.async(-1, 'k')
function PlayerInventory.get(player: Player)
    
    return if cache:findFirstPromise(player)
        then cache:findFirstPromise(player):expect()
        else PlayerInventory.wrap(player)
end

--// Adapter
function PlayerInventory.wrap(player: Player)
    
    local resolve
    cache:promise(function(_resolve) resolve = _resolve; coroutine.yield() end, player)
    
    local self = Inventory.get(player)
    player:AddTag('PlayerInventory')
    
    local data = awaitData(player)
    self:_syncAttributes(data)
    self.data = data
    
    --// Listeners
    self.itemRemoved:connect(function(item)
        
        local index = table.find(data.itemDatas, item.data)
        if index then table.remove(data.itemDatas, index) end
    end)
    self.itemAdded:connect(function(item)
        
        local index = table.find(data.itemDatas, item.data)
        if not index then table.insert(data.itemDatas, item.data) end
    end)
    
    --// Load
    for _,itemData in data.itemDatas do
        
        if itemData.amount <= 0 then continue end
        
        local item = Item.new(itemData)
        self:addItem(item)
    end
    
    --// End
    resolve(self)
    return self
end

--// End
return PlayerInventory