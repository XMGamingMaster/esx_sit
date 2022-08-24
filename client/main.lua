local sitting = false
local lastPosition = nil
local currentObject = nil

local validObjects = {}

Citizen.CreateThread(function()
	for i, v in ipairs(Config.Sitable) do
		validObjects[GetHashKey(v.prop)] = true
	end
end)

local closest = { object = nil, dist = -1 }
Citizen.CreateThread(function()
	while true do
		if not sitting then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			closest = { object = nil, dist = -1 }
			for obj in EnumerateObjects() do
				local model = GetEntityModel(obj)
				if validObjects[model] then
					local dist = #(coords - GetEntityCoords(obj))
					if (closest.object == nil) or (closest.dist > dist) then
						closest = { object = obj, dist = dist }
					end
				end
			end
		end

		Citizen.Wait(250)
	end
end)

Citizen.CreateThread(function()
	while true do
		if sitting then
			DisableCamCollisionForEntity(currentObject)
			if IsControlJustPressed(0, 51) then
				local ped = PlayerPedId()
				ClearPedTasks(ped)
				sitting = false
				FreezeEntityPosition(ped, false)
				FreezeEntityPosition(currentObject, false)
				SetEntityCoords(ped, lastPosition)
				TriggerServerEvent('esx_sit:unoccupyObject', currentObject)
				currentObject = nil
			end
		elseif not sitting and closest.object and DoesEntityExist(closest.object) and (closest.dist < Config.MaxDistance) then
			local objCoords = GetEntityCoords(closest.object)
			DrawMarker(
				27,
				objCoords + vector3(0, 0, 0.05),
				vector3(0, 0, 0),
				vector3(0, 0, 0),
				vector3(1, 1, 1),
				255,
				255,
				255,
				100,
				false,
				true,
				2,
				false,
				false,
				false,
				false
			)
			if IsControlJustPressed(0, 51) then
				sit(closest.object)
			end
		end

		Citizen.Wait(0)
	end
end)

function sit(object)
	local state = Entity(object).state
	local isOccupied = state.isOccupied or false
	if not isOccupied then
		local ped = PlayerPedId()
		local height = GetEntityHeightAboveGround(ped)
		lastPosition = GetEntityCoords(ped) - vector3(0, 0, height)
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
