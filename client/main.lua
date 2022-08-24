local sitting = false
local lastPosition = nil
local currentObject = nil

local validObjects = {}

local function headsUp(text)
	SetTextComponentFormat('STRING')
	AddTextComponentString(text)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

Citizen.CreateThread(function()
	for i, v in ipairs(Config.Sitable) do
		table.insert(validObjects, v.prop)
	end
end)

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		local closest = { object = nil, dist = -1 }
		for i, name in ipairs(validObjects) do
			local obj = GetClosestObjectOfType(
				coords.x,
				coords.y,
				coords.z,
				3.0,
				GetHashKey(name),
				false,
				true,
				true
			)
			local dist = GetDistanceBetweenCoords(coords, GetEntityCoords(obj), true)
			if (closest.object == nil) or (closest.dist > dist) then
				closest = { object = obj, dist = dist }
			end
		end

		if sitting then
			headsUp('Appuyez sur ~INPUT_VEH_DUCK~ pour vous lever.')
			if IsControlJustPressed(0, Keys['X']) then
				ClearPedTasks(ped)
				sitting = false
				SetEntityCoords(ped, lastPosition)
				FreezeEntityPosition(ped, false)
				FreezeEntityPosition(currentObject, false)
				TriggerServerEvent('esx_sit:unoccupyObject', currentObject)
				currentObject = nil
			end
		elseif closest.object and DoesEntityExist(closest.object) and (closest.dist < Config.MaxDistance) then
			headsUp('Appuyez sur ~INPUT_CONTEXT~ pouyr vous asseoir.')
			local objCoords = GetEntityCoords(closest.object)
			DrawMarker(
				0,
				objCoords + vector3(0, 0, 1.5),
				vector3(0, 0, 0),
				vector3(0, 0, 0),
				vector3(0.5, 0.5, 0.5),
				0,
				255,
				0,
				100,
				false,
				true,
				2,
				false,
				false,
				false,
				false
			)
			if IsControlJustPressed(0, Keys['E']) then
				sit(object)
			end
		elseif not closest.object then
			Citizen.Wait(2000)
		end
		Citizen.Wait(0)
	end
end)

function sit(object)
	local state = Entity(object).state
	local isOccupied = state.isOccupied or false
	if not isOccupied then
		local ped = PlayerPedId()
		lastPosition = GetEntityCoords(ped)
		currentObject = object
		TriggerServerEvent('esx_sit:occupyObject', object)
		FreezeEntityPosition(object, true)

		sitting = true

		local objData = {}
		for k, v in pairs(Config.Sitable) do
			if (GetHashKey(v.prop) == GetEntityModel(object)) then
				objData = v
				break
			end
		end

		local objCoords = GetEntityCoords(object)
		TaskStartScenarioAtPosition(
			ped,
			objData.scenario,
			objCoords.x,
			objCoords.y,
			objCoords.z - objData.verticalOffset,
			GetEntityHeading(object) + 180.0,
			0,
			true,
			true
		)
	end
end
