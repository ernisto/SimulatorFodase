--// Packages
local wrapper = require(game.ReplicatedStorage.Packages.Wrapper)
local localPlayer = game.Players.LocalPlayer

--// Module
return wrapper(localPlayer:WaitForChild('PlayerItemSummon')) :: any