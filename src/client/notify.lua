--// Packages
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local localGui = localPlayer:WaitForChild("PlayerGui")
local notificationsHololer = localGui:WaitForChild("HUD"):WaitForChild("Notifications")

--// Consts
local DURATION = 5

--// Module
return function(message: string, color: Color3)
	
	local notification = notificationsHololer.BaseText:Clone()
	notification.UIStroke.Color = Color3.new():Lerp(color, .5)
	notification.TextColor3 = color
	notification.Text = message
	notification.Parent = notificationsHololer
	notification.Visible = true
	
	task.delay(DURATION, function()
		
		notification:Destroy()
	end)
end