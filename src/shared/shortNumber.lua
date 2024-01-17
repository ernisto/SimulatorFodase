local EXTENSIONS = {
	'K', 'M', 'B', 'T', 'Q', 'Qn', 'Sx', 'Sp', 'Oc', 'Nn', 'Dc'
}
return function(amount: number)
	
	if amount == 0 then return '0' end
	if amount < 1 then return tostring(amount) end
	
	local cases = math.log10(amount)
	local unit = cases // 3
    
	return string.format("%.02f", amount/10^(unit*3))
		:gsub("%.0+$", "")
		.. (EXTENSIONS[unit] or "")
end