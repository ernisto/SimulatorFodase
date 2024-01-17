return function(totalSeconds: number)
	
	local totalMinutes, seconds = totalSeconds // 60, totalSeconds % 60
	local totalHours, minutes = totalMinutes // 60, totalMinutes % 60
	
	return if totalHours > 0 then string.format("%02i:%02i:%02i", totalHours, minutes, seconds)
		elseif totalMinutes > 0 then string.format("%02i:%02i", minutes, seconds)
		else string.format("%02i", seconds)
end