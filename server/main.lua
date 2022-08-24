local occupied = {}

RegisterServerEvent('esx_sit:occupyObject', function(object)
	table.insert(occupied, object)
	Entity(object).state.isOccupied = true
end)

RegisterServerEvent('esx_sit:unoccupyObject', function(object)
	for i, v in ipairs(occupied) do
		if (v == object) then
			table.remove(occupied, i)
			break
		end
	end
	Entity(object).state.isOccupied = false
end)
