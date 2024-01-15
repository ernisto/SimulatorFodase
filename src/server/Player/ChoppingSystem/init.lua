--// Packages
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Replicator = require(ServerStorage.Packages.Replicator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PowerLeaderboard = ReplicatedStorage.PowerLeaderboard
local MoneyLeaderboard = ReplicatedStorage.MoneyLeaderboard

local wrapper = require(ReplicatedStorage.Packages.Wrapper)
local Wood = require(ReplicatedStorage.Config.Wood)

local PlayerProfile = require(script.Parent.Profile)
local Booster = require(script.Parent.Booster)
local Market = require(script.Parent.Market)

local WoodStack = require(ReplicatedStorage.Shared.WoodStack)
type WoodStack = WoodStack.WoodStack

local Bag = require(script.Bag)
type Bag = Bag.Bag

local Axe = require(script.Axe)
type Axe = Axe.Axe

--// Module
local ChoppingSystem = {}

--// Consts
local MERGE_REQUIREMENT = 3
local BASE_DAMAGE = 5
local MAX_LEVEL = 3

--// Vars
local powerOrderedStore = DataStoreService:GetOrderedDataStore('PowerLeaderstats')
local moneyOrderedStore = DataStoreService:GetOrderedDataStore('MoneyLeaderstats')

--// Data
ChoppingSystem.baseData = {
    axeDatas = {} :: {Axe.axeData},
    bagData = Bag.baseData,
    basePower = 0,
    axeSlots = 30,
    money = 0,
}
local awaitChoppingData = PlayerProfile.subData('ChoppingSystem', ChoppingSystem.baseData)
export type choppingData = typeof(ChoppingSystem.baseData)

--// Cache
local onLoad = setmetatable({}, { __mode = 'k' })
local cache = setmetatable({}, { __mode = 'k' })
function ChoppingSystem.get(player: Player) return cache[player] or onLoad[player] and onLoad[player]:await() or ChoppingSystem.wrap(player) end

--// Factory
function ChoppingSystem.wrap(player: Player)
    
    local container = Instance.new("Folder", player)
    container.Name = "AxeInventory"
    
    --// Instance
    local market = Market.get(player)
    local client = Replicator.get(container)
    local self = wrapper(container, 'AxeInventory') :: AxeInventory
    self.powerBooster = self:_host(Booster.new('powerBooster'))
    self.woodsBooster = self:_host(Booster.new('woodsBooster'))
    self.moneyBooster = self:_host(Booster.new('moneyBooster'))
    self.equippedBagName = nil :: string?
    self.canQuickSell = false
    self.powerBonus = 0
    
    self.totalStoredAxes = 0
    self.equippedAxe = nil :: Axe?
    self.axes = {} :: {Axe}
    
    --// Market
    market.gamepasses[676255192] = function() self.powerBooster:add('gamepass', 1.00) end
    market.gamepasses[676066429] = function() self.woodsBooster:add('gamepass', 1.00) end
    market.gamepasses[683240555] = function() self.canAutoTraining = true end
    market.gamepasses[683073502] = function() self.canQuickSell = true end
    
    market.products[1722940680] = function() self.axeSlots += 20 end
    market.products[1712173773] = function() self:addAxe(Axe.deserialize{ name = 'FuriousAxe' }) end
    market.products[1712173422] = function() self:addAxe(Axe.deserialize{ name = 'LavaAxe' }) end
    
    market.products[1712166855] = function() self:forceStoreWoods(WoodStack.deserialize{ Oak = { trunk = (self.money + self.equippedBag.capacity)*0.25 } }, 'ignore boost') end
    market.products[1712167132] = function() self:forceStoreWoods(WoodStack.deserialize{ Oak = { trunk = (self.money + self.equippedBag.capacity)*0.50 } }, 'ignore boost') end
    market.products[1712167502] = function() self:forceStoreWoods(WoodStack.deserialize{ Oak = { trunk = (self.money + self.equippedBag.capacity)*1.00 } }, 'ignore boost') end
    market.products[1712168133] = function() self:forceStoreWoods(WoodStack.deserialize{ Oak = { trunk = (self.money + self.equippedBag.capacity)*2.00 } }, 'ignore boost') end
    
    --// Data Load
    onLoad[player] = self:_signal('onLoad')
    local data = awaitChoppingData(player)
    self.storedWoods = WoodStack.deserialize(data.storedWoodDatas)
    self.equippedBag = Bag.deserialize(data.bagData)
    self.equippedBagName = data.bagData.name
    self.totalStoredWoods = self.storedWoods.totalAmount
    
    self:_syncAttributes(data)
    self.data = data
    
    --// Remote Methods
    function client.EquipAxe(_player, axeContainer: Instance)
        
        local axe = Axe.find(axeContainer) or error(`invalid axe`)
        return self:equipAxe(axe)
    end
    function client.UnequipAxe(_player, axeContainer: Instance)
        
        local axe = Axe.find(axeContainer) or error(`invalid axe`)
        return self:unequipAxe(axe)
    end
    function client.QuickSell(_player,...: string)
        
        assert(self.canQuickSell, `quick sell pass required`)
        
        local selling = {}
        for _,woodName in {...} do
            
            selling[woodName] = self.storedWoods.data[woodName]
        end
        
        local sellingWoods = self:popStoredWoods(WoodStack.deserialize(selling))
        self:addMoney(sellingWoods.totalPrice)
    end
    function client.MergeAxes(_player,...: Instance)
        
        local axes = {}
        for index, axeContainer in {...} do
            
            local axe = Axe.find(axeContainer) or error(`invalid axe`)
            axes[index] = axe
        end
        
        return self:mergeAxes(unpack(axes)).roblox
    end
    function client.EquipBag(_player, bagName: string)
        
        local bag = Bag.deserialize{ name = bagName }
        assert(self.basePower >= bag.requiredPower, `you havent enough base power`)
        
        return self:setBag(bag)
    end
    
    --// Functions
    local storedWoodsContainer = Instance.new("Folder", container)
    storedWoodsContainer.Name = "StoredWoods"
    
    local function replicateStoredWoods(changingWoods: WoodStack)
        
        for kind, changingSizes in changingWoods.data do
            
            local kindContainer = storedWoodsContainer:FindFirstChild(kind) or Instance.new("Folder", storedWoodsContainer)
            kindContainer.Name = kind
            
            local kindConfig = Wood[kind]
            local totalAmount = 0
            local totalWeight = 0
            local totalPrice = 0
            
            for size in changingSizes do
                
                local sizeConfig = kindConfig.sizes[size]
                local amount = self.storedWoods.data[kind][size]
                kindContainer:SetAttribute(size, amount)
                
                totalWeight += sizeConfig.weight*amount
                totalPrice += sizeConfig.price*amount
                totalAmount += amount
            end
            kindContainer:SetAttribute('totalAmount', totalAmount)
            kindContainer:SetAttribute('totalWeight', totalWeight)
            kindContainer:SetAttribute('totalPrice', totalPrice)
        end
        storedWoodsContainer:SetAttribute('totalAmount', self.storedWoods.totalAmount)
        storedWoodsContainer:SetAttribute('totalWeight', self.storedWoods.totalWeight)
        storedWoodsContainer:SetAttribute('totalPrice', self.storedWoods.totalPrice)
    end
    
    --// Methods
    function self:addPowerBonus(bonus: number) self.powerBonus += bonus end
    function self:removePowerBonus(bonus: number) self.powerBonus -= bonus end
    function self:reset()
        
        self:setBag(Bag.deserialize{ name='Bag' })
        self:popStoredWoods()
        
        self.moneyBooster:reset()
        self.powerBooster:reset()
        self.woodsBooster:reset()
        self.powerBonus = 0
        self.basePower = 0
        self.money = 0
        
        for _,axe in self.axes do
            
            if not axe:is("eternal") then self:removeAxe(axe) end
        end
        if not next(self.axes) then self:addAxe(Axe.deserialize{ name = 'Axe' }) end
        if not self.equippedAxe then self:equipAxe(self.axes[1]) end
    end
    
    function self:forceStoreWoods(requestedWoods: WoodStack, ignoreBoost: boolean?)
        
        if not ignoreBoost then requestedWoods *= self.woodsBooster:get() end
        
        self.totalStoredWoods += requestedWoods.totalAmount
        data.storedWoodDatas = self.storedWoods.data
        self.storedWoods += requestedWoods
        
        replicateStoredWoods(requestedWoods)
    end
    function self:boundedStoreWoods(requestedWoods: WoodStack): WoodStack
        
        -- local weightLimit = self.powerBooster:get()*(100 + self.powerBonus + self.basePower)
        local limit = {
            amount = self.equippedBag.capacity - self.storedWoods.totalAmount,
            -- weight = weightLimit - self.storedWoods.totalWeight,
        }
        local storingWoods = requestedWoods:fromLimit(limit)
        
        self:forceStoreWoods(storingWoods, 'ignore boost')
        return storingWoods
    end
    function self:popStoredWoods(poppingWoods: WoodStack?): WoodStack
        
        local boundedPoppingWoods = if poppingWoods
            then poppingWoods:fromLimit{ each=self.storedWoods }
            else self.storedWoods
        
        self.totalStoredWoods -= boundedPoppingWoods.totalAmount
        self.storedWoods -= boundedPoppingWoods
        data.storedWoodDatas = self.storedWoods.data
        
        replicateStoredWoods(boundedPoppingWoods)
        return boundedPoppingWoods
    end
    
    function self:addMoney(amount: number)
        
        self.money += amount*self.moneyBooster:get()
    end
    function self:consumeMoney(amount: number)
        
        assert(self.money > amount, `not enough money`)
        self.money -= amount
    end
    
    function self:addBasePower(increment: number)
        
        self.basePower += increment*self.powerBooster:get()
    end
    function self:getTotalDamage(): number
        
        return BASE_DAMAGE
            + self.basePower/10
            + self.powerBonus/10
            * (if self.equippedAxe then self.equippedAxe.damage/10 else 0.00)
            * (self.powerBooster:get())
    end
    
    function self:equipAxe(axe: Axe)
        
        assert(axe.player :: Player? == player, `permission denied`)
        if self.equippedAxe then self:unequipAxe(self.equippedAxe) end
        
        self.equippedAxe = axe
        return axe:equip()
    end
    function self:unequipAxe(axe: Axe)
        
        self.equippedAxe = nil
        return axe:unequip()
    end
    
    function self:removeAxe(axe: Axe)
        
        assert(axe.player :: Player? == player, `this axe already is removed`)
        if self.equippedAxe == axe then self:unequipAxe(axe) end
        
        local index1 = table.find(self.axes, axe)
        if index1 then table.remove(self.axes, index1) end
        
        local index2 = table.find(self.axeDatas, axe.data)
        if index2 then table.remove(self.axeDatas, index2) end
        
        axe:setPlayer(nil)
        self.totalStoredAxes -= 1
    end
    function self:addAxe(axe: Axe)
        
        assert(axe.player == nil, `this axe already is owned`)
        assert(self.totalStoredAxes < self.axeSlots, `max of stored axes reached`)
        
        local index1 = table.find(self.axes, axe)
        if not index1 then table.insert(self.axes, axe) end
        
        local index2 = table.find(self.axeDatas, axe.data)
        if not index2 then table.insert(self.axeDatas, axe.data) end
        
        axe:setPlayer(player)
        self.totalStoredAxes += 1
    end
    
    function self:mergeAxes(baseAxe: Axe,...: Axe): Axe
        
        local axes = {baseAxe,...}
        
        assert(#axes == MERGE_REQUIREMENT, `is needed {MERGE_REQUIREMENT} to merge a axe`)
        assert((baseAxe.level :: number) < MAX_LEVEL, `limit of level reached`)
        
        for index, axe in axes do
            
            assert(axe.player == player and not axe.isEquipped, `all axes should be owned and unequipped`)
            assert(axe.level == baseAxe.level, `all axes should be the same level`)
            assert(axe.name == baseAxe.name, `all axes should be the same kind`)
        end
        for _,axe in axes do self:removeAxe(axe) end
        
        local merged = Axe.deserialize{ name = baseAxe.name, level = baseAxe.level + 1 }
        self:addAxe(merged)
        
        return merged
    end
    function self:setBag(bag: Bag)
        
        self.equippedBag = bag
        data.bagData = bag.data
        
        self.equippedBagName = bag.name
    end
    
    --// Load
    for _,axeData in self.axeDatas do
        
        if self.totalStoredAxes >= self.axeSlots then break end
        
        local axe = Axe.deserialize(axeData)
        self:addAxe(axe)
        
        if axeData.isEquipped then self:equipAxe(axe) end
    end
    if not next(self.axes) then self:addAxe(Axe.deserialize{ name = 'Axe' }) end
    if not self.equippedAxe then self:equipAxe(self.axes[1]) end
    
    replicateStoredWoods(self.storedWoods)
    
    --// End
    onLoad[player] = onLoad[player]:_emit(self)
    cache[player] = self
    return self
end
export type AxeInventory = choppingData & {
    data: choppingData,
    basePower: number,
    
    equippedBagName: string,
    equippedBag: Bag,
    
    totalStoredAxes: number,
    equippedAxe: Axe,
    axes: {Axe},
    
    totalStoredWoods: number,
    storedWoods: WoodStack,
    
    popStoredWoods: (any, removing: WoodStack?) -> WoodStack,
    boundedStoreWoods: (any, woods: WoodStack) -> WoodStack,
    
    addBasePower: (increment: number) -> (),
    getDamage: () -> number,
    equipAxe: (axe: Axe) -> (),
    unequipAxe: (axe: Axe) -> (),
    removeAxe: (axe: Axe) -> (),
    addAxe: (axe: Axe) -> (),
    mergeAxes: (baseAxe: Axe,...Axe) -> Axe,
}

task.spawn(function()
    
    for rank = 1, 100 do
        
        Instance.new("Folder", PowerLeaderboard).Name = `{rank}`
        Instance.new("Folder", MoneyLeaderboard).Name = `{rank}`
    end
    task.wait(10)
    
    repeat
        for player, chopping in cache do
            
            pcall(powerOrderedStore.SetAsync, powerOrderedStore, player.UserId, chopping.basePower // 1)
            pcall(moneyOrderedStore.SetAsync, moneyOrderedStore, player.UserId, chopping.money // 1)
        end
        
        for rank, entry in powerOrderedStore:GetSortedAsync(false, 100):GetCurrentPage() do
            
            local container = PowerLeaderboard:FindFirstChild(`{rank}`)
            container:SetAttribute('value', entry.value)
            container:SetAttribute('key', entry.key)
        end
        for rank, entry in moneyOrderedStore:GetSortedAsync(false, 100):GetCurrentPage() do
            
            local container = MoneyLeaderboard:FindFirstChild(`{rank}`)
            container:SetAttribute('value', entry.value)
            container:SetAttribute('key', entry.key)
        end
        
    until not task.wait(5*60)
end)

--// End
return ChoppingSystem