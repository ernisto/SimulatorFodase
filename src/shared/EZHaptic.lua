--// Packages
local HapticService = game:GetService("HapticService")

--// Consts
local ALTERNATIVES = {
    [Enum.VibrationMotor.RightHand] = { Enum.VibrationMotor.RightTrigger, Enum.VibrationMotor.Large, Enum.VibrationMotor.Small },
    [Enum.VibrationMotor.RightTrigger] = { Enum.VibrationMotor.RightHand, Enum.VibrationMotor.Large, Enum.VibrationMotor.Small },
    [Enum.VibrationMotor.LeftHand] = { Enum.VibrationMotor.LeftTrigger, Enum.VibrationMotor.Large, Enum.VibrationMotor.Small },
    [Enum.VibrationMotor.LeftTrigger] = { Enum.VibrationMotor.LeftHand, Enum.VibrationMotor.Large, Enum.VibrationMotor.Small },
    [Enum.VibrationMotor.Large] = { Enum.VibrationMotor.Small },
    [Enum.VibrationMotor.Small] = { Enum.VibrationMotor.Large },
}

--// Module
type params = { device: Enum.UserInputType, motor: Enum.VibrationMotor, intensity: number?, duration: number?, alternate: boolean? }
return function(params: params)
    
    local intensity = math.clamp(params.intensity or 0.50, 0.00, 1.00)
    
    local motor = params.motor
    for _,_motor in {motor, unpack(if params.alternate then ALTERNATIVES[params.motor] else {})} do
        
        if HapticService:IsMotorSupported(params.device, motor) then break end
        motor = _motor
    end
    
    HapticService:SetMotor(params.device, motor, intensity)
    task.delay(intensity*(params.duration or .15), function()
        
        HapticService:SetMotor(params.device, motor, 0.00)
    end)
end