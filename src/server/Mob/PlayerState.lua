--// Packages
local Signal = require(game.ReplicatedStorage.Packages.Signal)
local Cache = require(game.ReplicatedStorage.Packages.Cache)

local PlayerCurrency = require(game.ServerScriptService.Player.Currency)
local PlayerInventory = require(game.ServerScriptService.Player.Inventory)
local Item = require(game.ServerScriptService.Inventory.Item)

local Mob = require(script.Parent)

--// Handler
local PlayerState = {}
local cache = Cache.new(-1, 'k')

--// Functions
function PlayerState.get(mobEntity: Mob.entity, player: Player)
    
    return cache:find(mobEntity, player) or PlayerState.new(mobEntity, player)
end

--// Component
function PlayerState.new(mobEntity: Mob.entity, player: Player)
    
    local inventory = PlayerInventory.get(player)
    local currency = PlayerCurrency.get(player)
    local mob = Mob.get(mobEntity)
    
    --// Instance
    local self = { player = player }
    self.availableTime = os.clock()
    self.droppedItems = {}
    self.droppedCoins = 0
    self.health = 0
    
    --// Signals
    self.coinsDropped = Signal.new('coinsDropped')
    self.itemsDropped = Signal.new('itemsDropped')
    
    --// Methods
    function self:takeDamage(damage: number)
        
        if not self:isAlive() then return end
        if self.health <= 0 then self:respawn() end
        
        local damageDealed = math.min(self.health, damage)
        self.health -= damageDealed
        
        if self.health <= 0 then self:kill() end
        return damageDealed
    end
    function self:kill()
        
        self.availableTime = os.clock() + mob.respawnTime
        self.health = 0
        
        self:dropCoins(mob:getCoins())
        self:dropItem(Item.new{ name=mob:getItemName() })
    end
    
    function self:pickupDrops()
        
        return { coins = self:pickupCoins(), items = self:pickupItems() }
    end
    function self:pickupCoins(amount: number?)
        
        amount = amount or self.droppedCoins
        
        assert(self.droppedCoins >= amount, `not enough coins`)
        self.droppedCoins -= amount
        
        currency:add(amount)
        return amount
    end
    function self:pickupItems()
        
        local pickedItems = {}
        for item in self.droppedItems do
            
            local success = pcall(inventory.addItem, inventory, item)
            if not success then continue end
            
            self.droppedItems[item] = nil
            table.insert(pickedItems, item.name)
        end
        return pickedItems
    end
    
    function self:dropCoins(amount: number)
        
        self.droppedCoins += amount
        self.coinsDropped:_emit(amount)
    end
    function self:dropItem(item: Item.Item)
        
        self.droppedItems[item] = true
        self.itemsDropped:_emit(item.name)
    end
    
    function self:respawn()
        
        self.health = mob.maxHealth
    end
    function self:isAlive()
        
        return os.clock() > self.availableTime
    end
    
    --// End
    cache:set(self, mobEntity, player)
    self:respawn()
    return self
end

--// End
return PlayerState