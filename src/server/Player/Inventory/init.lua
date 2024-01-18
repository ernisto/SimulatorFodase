--// Packages
local Cache = require(game.ReplicatedStorage.Packages.Cache)
local PlayerProfile = require(script.Parent.Profile)

local Inventory = require(game.ServerScriptService.Inventory)
local Item = require(game.ServerScriptService.Inventory.Item)

--// Data
local awaitData = PlayerProfile.subData('Inventory', {
    itemDatas = {} :: {Item.data},
    slots = 30,
})

--// Handler
local PlayerInventory = {}

local cache = Cache.new(-1, 'k')
function PlayerInventory.get(player: Player) return cache:find(player) or PlayerInventory.wrap(player) end

--// Adapter
function PlayerInventory.wrap(player)
    
    local self = Inventory.get(player)
    
    local data = awaitData(player)
    self:_syncAttributes(data)
    
    --// Load
    for _,itemData in data.itemDatas do
        
        local item = Item.new(itemData)
        self:addItem(item)
    end
    
    --// End
    cache:set(self, player)
    return self
end

--// End
return PlayerInventory