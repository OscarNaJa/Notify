if Config.UseESX then
	ESX = nil

	Citizen.CreateThread(function()
		while not ESX do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(500)
		end
	end)
end

local isNearPump = false
local isFueling = false
local currentFuel = 0.0
local currentCost = 0.0
local currentCash = 1000
local fuelSynced = false
local inBlacklisted = false
local nearGasStation = false

local function GetPlayerCash()
	if not Config.UseESX or not ESX then
		return currentCash
	end

	local playerData = ESX.GetPlayerData()

	if playerData and playerData.accounts then
		for i = 1, #playerData.accounts do
			if playerData.accounts[i].name == 'money' then
				return playerData.accounts[i].money
			end
		end
	end

	return playerData and playerData.money or currentCash
end

local function SendFuelNotify(msg)
	if Config.NotiToggle and exports and exports['ssr_notify'] then
		exports['ssr_notify']:sendAlert({
			type = 'success',
			title = Config.NotiTitle or 'ระบบน้ำมัน',
			msg = msg,
			time = 5
		})
	end
end

function ManageFuelUsage(vehicle)
	if not DecorExistOn(vehicle, Config.FuelDecor) then
		SetFuel(vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
		SetFuel(vehicle, GetFuel(vehicle))

		fuelSynced = true
	end

	if IsVehicleEngineOn(vehicle) then
		local rpmUsage = Config.FuelUsage[Round(GetVehicleCurrentRpm(vehicle), 1)] or 0.0
		local classUsage = (Config.Classes[GetVehicleClass(vehicle)] or 1.0)
		local speed = GetEntitySpeed(vehicle)
		local idleMultiplier = 1.0

		if speed <= Config.LowSpeedThreshold then
			idleMultiplier = Config.IdleFuelMultiplier
		end

		SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - rpmUsage * classUsage * idleMultiplier / 10)
	end
end

Citizen.CreateThread(function()
	DecorRegister(Config.FuelDecor, 1)

	for i = 1, #Config.Blacklist do
		if type(Config.Blacklist[i]) == 'string' then
			Config.Blacklist[GetHashKey(Config.Blacklist[i])] = true
		else
			Config.Blacklist[Config.Blacklist[i]] = true
		end
	end

	for i = #Config.Blacklist, 1, -1 do
		table.remove(Config.Blacklist, i)
	end

	while true do
		Citizen.Wait(1000)

		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped)

			if Config.Blacklist[GetEntityModel(vehicle)] then
				inBlacklisted = true
			else
				inBlacklisted = false
			end

			if not inBlacklisted and GetPedInVehicleSeat(vehicle, -1) == ped then
				ManageFuelUsage(vehicle)
			end
		else
			if fuelSynced then
				fuelSynced = false
			end

			if inBlacklisted then
				inBlacklisted = false
			end
		end
	end
end)

function GetNearestGasStationDistance(coords)
	local closestDistance = 9999.0

	for i = 1, #Config.GasStations do
		local distance = #(coords - Config.GasStations[i])

		if distance < closestDistance then
			closestDistance = distance
		end
	end

	return closestDistance
end

function FindNearestFuelPump()
	local coords = GetEntityCoords(PlayerPedId())
	local fuelPumps = {}
	local handle, object = FindFirstObject()
	local success

	repeat
		if Config.PumpModels[GetEntityModel(object)] then
			table.insert(fuelPumps, object)
		end

		success, object = FindNextObject(handle, object)
	until not success

	EndFindObject(handle)

	local pumpObject = 0
	local pumpDistance = 1000

	for k,v in pairs(fuelPumps) do
		local dstcheck = #(coords - GetEntityCoords(v))

		if dstcheck < pumpDistance then
			pumpDistance = dstcheck
			pumpObject = v
		end
	end

	return pumpObject, pumpDistance
end

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)
		local nearestStationDistance = GetNearestGasStationDistance(pedCoords)
		nearGasStation = nearestStationDistance <= Config.StationActivationDistance

		if nearGasStation then
			local pumpObject, pumpDistance = FindNearestFuelPump()

			if pumpDistance < Config.PumpInteractDistance then
				isNearPump = pumpObject

				if Config.UseESX and ESX then
					currentCash = GetPlayerCash()
				end
			else
				isNearPump = false
			end

			Citizen.Wait(300)
		else
			isNearPump = false
			Citizen.Wait(1200)
		end
	end
end)

function DrawText3Ds(x, y, z, text)
	local playerCoords = GetEntityCoords(PlayerPedId())
	local dx = playerCoords.x - x
	local dy = playerCoords.y - y
	local dz = playerCoords.z - z
	local maxDistance = Config.DrawTextMaxDistance or 20.0

	if (dx * dx + dy * dy + dz * dz) > (maxDistance * maxDistance) then
		return
	end

	local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)

	if not onScreen then
		return
	end

	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	DrawText(screenX, screenY)
end

function LoadAnimDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)

		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(1)
		end
	end
end

AddEventHandler('fuel:startFuelUpTick', function(pumpObject, ped, vehicle)
	currentFuel = GetVehicleFuelLevel(vehicle)
	local hasNotifiedFullTank = false

	while isFueling do
		Citizen.Wait(500)

		local oldFuel = DecorGetFloat(vehicle, Config.FuelDecor)
		local fuelToAdd = math.random(10, 20) / 10.0
		local extraCost = fuelToAdd / 1.5 * Config.CostMultiplier

		if not pumpObject then
			if GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100 >= 0 then
				currentFuel = oldFuel + fuelToAdd

				SetPedAmmo(ped, 883325847, math.floor(GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100))
			else
				isFueling = false
			end
		else
			currentFuel = oldFuel + fuelToAdd
		end

		if currentFuel > 100.0 then
			currentFuel = 100.0
			isFueling = false

			if not hasNotifiedFullTank then
				hasNotifiedFullTank = true
				SendFuelNotify('เติมน้ำมันเต็มถังแล้ว')
			end
		end

		currentCost = currentCost + extraCost

		if currentCash >= currentCost then
			SetFuel(vehicle, currentFuel)
		else
			isFueling = false
		end
	end

	if pumpObject then
		TriggerServerEvent('fuel:pay', currentCost)
	end

	currentCost = 0.0
end)

function Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)

	return math.floor(num * mult + 0.5) / mult
end

AddEventHandler('fuel:refuelFromPump', function(pumpObject, ped, vehicle)
	local isRefuelFromVehicle = Config.AllowRefuelInVehicle and IsPedInAnyVehicle(ped) and GetVehiclePedIsIn(ped) == vehicle and GetPedInVehicleSeat(vehicle, -1) == ped

	if not isRefuelFromVehicle then
		TaskTurnPedToFaceEntity(ped, vehicle, 1000)
		Citizen.Wait(1000)
		SetCurrentPedWeapon(ped, -1569615261, true)
		LoadAnimDict("timetable@gardener@filling_can")
		TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	end

	TriggerEvent('fuel:startFuelUpTick', pumpObject, ped, vehicle)

	while isFueling do
		Citizen.Wait(1)

		for k,v in pairs(Config.DisableKeys) do
			DisableControlAction(0, v)
		end

		local vehicleCoords = GetEntityCoords(vehicle)

		if pumpObject then
			local stringCoords = GetEntityCoords(pumpObject)
			local extraString = ""

			if Config.UseESX then
				extraString = "\n" .. Config.Strings.TotalCost .. ": ~g~$" .. Round(currentCost, 1)
			end

			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.CancelFuelingPump .. extraString)
			DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, Round(currentFuel, 1) .. "%")
		else
			DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, Config.Strings.CancelFuelingJerryCan .. "\nGas can: ~g~" .. Round(GetAmmoInPedWeapon(ped, 883325847) / 4500 * 100, 1) .. "% | Vehicle: " .. Round(currentFuel, 1) .. "%")
		end

		if not isRefuelFromVehicle and not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
			TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
		end

		local driver = GetPedInVehicleSeat(vehicle, -1)
		if IsControlJustReleased(0, 38) or (DoesEntityExist(driver) and driver ~= ped) or (isNearPump and GetEntityHealth(pumpObject) <= 0) then
			isFueling = false
		end

		if isRefuelFromVehicle then
			if (not IsPedInAnyVehicle(ped)) or GetVehiclePedIsIn(ped) ~= vehicle then
				isFueling = false
			elseif pumpObject and (#(GetEntityCoords(vehicle) - GetEntityCoords(pumpObject)) > (Config.PumpInteractDistance + 0.5)) then
				isFueling = false
			end
		end
	end

	if not isRefuelFromVehicle then
		ClearPedTasks(ped)
		RemoveAnimDict("timetable@gardener@filling_can")
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(nearGasStation and 1 or 300)

		local ped = PlayerPedId()

		if not isFueling and nearGasStation and ((isNearPump and GetEntityHealth(isNearPump) > 0) or (GetSelectedPedWeapon(ped) == 883325847 and not isNearPump)) then
			local isDriver = IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped
			if isDriver and not Config.AllowRefuelInVehicle then
				local pumpCoords = GetEntityCoords(isNearPump)

				DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, Config.Strings.ExitVehicle)
			else
				local vehicle = isDriver and GetVehiclePedIsIn(ped) or GetPlayersLastVehicle()

				if DoesEntityExist(vehicle) then
					local vehicleCoords = GetEntityCoords(vehicle)
					local inRange = isDriver or (#(GetEntityCoords(ped) - vehicleCoords) < Config.PumpInteractDistance)

					if inRange then
						local driver = GetPedInVehicleSeat(vehicle, -1)
						if (not DoesEntityExist(driver)) or (Config.AllowRefuelInVehicle and driver == ped) then
						local stringCoords = isNearPump and GetEntityCoords(isNearPump) or vehicleCoords
						local canFuel = true

						if GetSelectedPedWeapon(ped) == 883325847 then
							stringCoords = vehicleCoords

							if GetAmmoInPedWeapon(ped, 883325847) < 100 then
								canFuel = false
							end
						end

						if GetVehicleFuelLevel(vehicle) < 95 and canFuel then
							if currentCash > 0 then
								DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.EToRefuel)

								if IsControlJustReleased(0, 38) then
									isFueling = true

									TriggerEvent('fuel:refuelFromPump', isNearPump, ped, vehicle)
									LoadAnimDict("timetable@gardener@filling_can")
								end
							else
								DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.NotEnoughCash)
							end
						elseif not canFuel then
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.JerryCanEmpty)
						else
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.FullTank)
						end
						end
					end
				elseif isNearPump then
					local stringCoords = GetEntityCoords(isNearPump)

					if currentCash >= Config.JerryCanCost then
						if not HasPedGotWeapon(ped, 883325847) then
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.PurchaseJerryCan)

							if IsControlJustReleased(0, 38) then
								GiveWeaponToPed(ped, 883325847, 4500, false, true)

								TriggerServerEvent('fuel:pay', Config.JerryCanCost)
								SendFuelNotify('ซื้อถังน้ำมันเรียบร้อยแล้ว')

								currentCash = GetPlayerCash()
							end
						else
							if Config.UseESX then
								local refillCost = Round(Config.RefillCost * (1 - GetAmmoInPedWeapon(ped, 883325847) / 4500))

								if refillCost > 0 then
									if currentCash >= refillCost then
										DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.RefillJerryCan .. refillCost)

										if IsControlJustReleased(0, 38) then
											TriggerServerEvent('fuel:pay', refillCost)

											SetPedAmmo(ped, 883325847, 4500)
										end
									else
										DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.NotEnoughCashJerryCan)
									end
								else
									DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.JerryCanFull)
								end
							else
								DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.RefillJerryCan)

								if IsControlJustReleased(0, 38) then
									SetPedAmmo(ped, 883325847, 4500)
								end
							end
						end
					else
						DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Strings.NotEnoughCash)
					end
				else
					Citizen.Wait(250)
				end
			end
		else
			Citizen.Wait(250)
		end
	end
end)

function CreateBlip(coords)
	local blip = AddBlipForCoord(coords)

	SetBlipSprite(blip, 361)
	SetBlipScale(blip, 0.9)
	SetBlipColour(blip, 45)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('<font face="ThaiFont">ปั้มน้ำมัน</font>')
	EndTextCommandSetBlipName(blip)

	return blip
end

if Config.ShowNearestGasStationOnly then
	Citizen.CreateThread(function()
		local currentGasBlip = 0

		while true do
			Citizen.Wait(10000)

			local coords = GetEntityCoords(PlayerPedId())
			local closest = 1000
			local closestCoords

			for k,v in pairs(Config.GasStations) do
				local dstcheck = #(coords - v)

				if dstcheck < closest then
					closest = dstcheck
					closestCoords = v
				end
			end

			if DoesBlipExist(currentGasBlip) then
				RemoveBlip(currentGasBlip)
			end

			currentGasBlip = CreateBlip(closestCoords)
		end
	end)
elseif Config.ShowAllGasStations then
	Citizen.CreateThread(function()
		for k,v in pairs(Config.GasStations) do
			CreateBlip(v)
		end
	end)
end

function GetFuel(vehicle)
	return DecorGetFloat(vehicle, Config.FuelDecor)
end

function SetFuel(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, Config.FuelDecor, GetVehicleFuelLevel(vehicle))
	end
end

if Config.EnableHUD then
	local function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
		SetTextFont(font)
		SetTextProportional(0)
		SetTextScale(sc, sc)
		N_0x4e096588b13ffeca(jus)
		SetTextColour(r, g, b, a)
		SetTextDropShadow(0, 0, 0, 0,255)
		SetTextEdge(1, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString(text)
		DrawText(x - 0.1+w, y - 0.02+h)
	end

	local mph = 0
	local kmh = 0
	local fuel = 0
	local displayHud = false

	local x = 0.01135
	local y = 0.002

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(50)

			local ped = PlayerPedId()

			if IsPedInAnyVehicle(ped) then
				local vehicle = GetVehiclePedIsIn(ped)
				local speed = GetEntitySpeed(vehicle)

				mph = tostring(math.ceil(speed * 3.6))
				kmh = tostring(math.ceil(speed * 2.236936))
				fuel = tostring(math.ceil(GetVehicleFuelLevel(vehicle)))

				displayHud = true
			else
				displayHud = false

				Citizen.Wait(500)
			end
		end
	end)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(1)

			if displayHud then
				DrawAdvancedText(0.203 - x, 0.945 - y, 0.130, 0.0028, 0.6, fuel, 255, 255, 255, 255, 6, 1)
				--DrawAdvancedText(0.152 - x, 0.94 - y, 0.135, 0.0028, 0.6, mph, 255, 255, 255, 255, 6, 1)
				DrawAdvancedText(0.152 - x, 0.945 - y, 0.130, 0.0028, 0.6, mph, 255, 255, 255, 255, 6, 1)
				DrawAdvancedText(0.175 - x, 0.955 - y, 0.130, 0.0028, 0.3, "km/h                         Fuel", 255, 255, 255, 255, 6, 1)
			else
				Citizen.Wait(750)
			end
		end
	end)
end
