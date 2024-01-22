--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)
local Spring = require(game.ReplicatedStorage.Packages.Spring)

local ItemSummoner = require(script.Parent)
local ItemsBoard = game.ReplicatedStorage.Assets.ItemsBoard

export type entity = ItemSummoner.entity

--// Trait
return Entity.trait('ItemSummoner', function(self, model: entity)
    
    local itemSummoner = ItemSummoner.get(model)
    local board = ItemsBoard:Clone()
    board.Adornee = model.PrimaryPart
    board.Parent = game.Players.LocalPlayer.PlayerGui
    
    local totalRate = 0
    for _,rate in model.DropRates:GetAttributes() do totalRate += rate end
    
    local petFrames = {}
    for name, rate in model.DropRates:GetAttributes() do
        
        local petConfig = game.ReplicatedStorage.Assets.Items[name]
        
        local petFrame = board.Holder.Pets.PetFrame:Clone()
        petFrame.Parent = board.Holder.Pets
        petFrame.chance.Text = string.format(`%.2f%%`, 100*rate/totalRate)
        petFrame.Visible = true
        
        table.insert(petFrames, petFrame)
        petFrame.LayoutOrder = 100000/rate
        
        local camera = petFrame:FindFirstChildOfClass('Camera') or Instance.new('Camera', petFrame)
        petFrame.CurrentCamera = camera
        
        local itemModel = petConfig.Model:Clone() :: Model
        if not itemModel.PrimaryPart then continue end
        
        itemModel.Parent = petFrame
        camera.CFrame = itemModel.PrimaryPart.CFrame
            * CFrame.new(0, 0, -10)
    end
    
    table.sort(petFrames, function(frame1, frame2) return frame1.LayoutOrder > frame2.LayoutOrder end)
    local threads = {}
    
    --// Functions
    local function open()
        
        for _,thread in threads do task.cancel(thread) end
        for index, petFrame in petFrames do
            
            table.insert(threads, task.delay(index*.03, function()
                Spring.target(petFrame.chance, 1.00, 5.00,
                    { TextTransparency = 0.00, Position = UDim2.new(0, 0, 1, 0) }
                )
            end))
        end
        
        Spring.target(board.Holder.Title, 1.00, 5.00,
            { TextTransparency = 0.00, Position = UDim2.new() }
        )
        Spring.target(board.Holder.Pets, 1.00, 5.00,
            { Position = UDim2.new(0, 10, 0, 40), Size = UDim2.new(0, 180, 0, 180) }
        )
        Spring.target(board.Holder.Pets.UIGridLayout, 1.00, 5.00,
            { CellPadding = UDim2.new(0, 10, 0, 10) }
        )
        Spring.target(board.Holder, 1.00, 5, { GroupTransparency = 0.00 })
    end
    local function close()
        
        for _,thread in threads do task.cancel(thread) end
        for index, petFrame in petFrames do
            
            Spring.target(petFrame.chance, 1.00, 50.00,
                { TextTransparency = 1.00, Position = UDim2.new(0, 0, 1, -40) }
            )
        end
        
        Spring.target(board.Holder.Title, 1.00, 5.00,
            { TextTransparency = 1.00, Position = UDim2.new(0, -40, 0, 0) }
        )
        Spring.target(board.Holder.Pets, 1.00, 5.00,
            { Position = UDim2.new(0, -50, 0, 40), Size = UDim2.new(0, 250, 0, 180) }
        )
        Spring.target(board.Holder.Pets.UIGridLayout, 1.00, 5.00,
            { CellPadding = UDim2.new(0, 60, 0, 10) }
        )
        Spring.target(board.Holder, 1.00, 5, { GroupTransparency = 1.00 })
    end
    close()
    
    --// Events
    itemSummoner.focused:connect(open)
    itemSummoner.unfocused:connect(close)
end)