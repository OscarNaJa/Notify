Config = {}

-- ใช้ระบบ ESX หรือไม่ (เปิด = เติมน้ำมัน/ซื้อแกลลอนมีค่าใช้จ่าย)
Config.UseESX = true

-- ราคาซื้อถังน้ำมัน (แกลลอน)
Config.JerryCanCost = 500
Config.RefillCost = 350 -- ค่าเติมแกลลอน (คิดตามสัดส่วนที่ขาด)

-- Decor ที่ใช้เก็บระดับน้ำมัน (ไม่แนะนำให้แก้)
Config.FuelDecor = "_FUEL_LEVEL"

-- ปุ่มที่ถูกปิดระหว่างกำลังเติมน้ำมัน
Config.DisableKeys = {0, 22, 23, 24, 29, 30, 31, 37, 44, 56, 82, 140, 166, 167, 168, 170, 288, 289, 311, 323}

-- เปิด HUD แสดงความเร็ว/น้ำมัน
Config.EnableHUD = false

-- ตั้งค่าการแสดง Blip ปั๊มน้ำมัน (ปิดทั้งคู่ = ไม่แสดง)
Config.ShowNearestGasStationOnly = false
Config.ShowAllGasStations = false

-- ตัวคูณราคาน้ำมัน (เช่น 2.0 = ราคาเพิ่มเป็น 2 เท่า)
Config.CostMultiplier = 1.0

-- ตั้งค่าประสิทธิภาพ
Config.StationActivationDistance = 30.0 -- เริ่มค้นหาหัวจ่ายเฉพาะตอนเข้าใกล้ปั๊มน้ำมัน
Config.PumpInteractDistance = 2.5 -- ระยะสูงสุดที่สามารถโต้ตอบการเติมน้ำมันได้
Config.LowSpeedThreshold = 0.8 -- ความเร็วต่ำกว่า (m/s) จะถือว่าเป็นรถจอด/นิ่ง
Config.IdleFuelMultiplier = 0.2 -- ตัวคูณการกินน้ำมันตอนรถนิ่ง/วิ่งช้ามาก
Config.DrawTextMaxDistance = 15.0 -- ระยะสูงสุดในการวาดข้อความ 3D เพื่อลดโหลด

-- ตั้งค่าพฤติกรรมระบบ
Config.AllowRefuelInVehicle = true -- true = อนุญาตเติมน้ำมันขณะนั่งตำแหน่งคนขับ
Config.NotiToggle = true -- เปิด/ปิดการแจ้งเตือนผ่าน ssr_notify
Config.NotiTitle = 'ระบบน้ำมัน' -- หัวข้อแจ้งเตือน

-- ข้อความต่าง ๆ ในเกม (แก้ได้ตามต้องการ)
Config.Strings = {
	ExitVehicle = "Exit the vehicle to refuel",
	EToRefuel = "Press ~g~E ~w~to refuel vehicle",
	JerryCanEmpty = "Jerry can is empty",
	FullTank = "Tank is full",
	PurchaseJerryCan = "Press ~g~E ~w~to purchase a jerry can for ~g~$" .. Config.JerryCanCost,
	CancelFuelingPump = "Press ~g~E ~w~to cancel the fueling",
	CancelFuelingJerryCan = "Press ~g~E ~w~to cancel the fueling",
	NotEnoughCash = "Not enough cash",
	RefillJerryCan = "Press ~g~E ~w~ to refill the jerry can for ",
	NotEnoughCashJerryCan = "Not enough cash to refill jerry can",
	JerryCanFull = "Jerry can is full",
	TotalCost = "Cost",
}

if not Config.UseESX then
	Config.Strings.PurchaseJerryCan = "Press ~g~E ~w~to grab a jerry can"
	Config.Strings.RefillJerryCan = "Press ~g~E ~w~ to refill the jerry can"
end

Config.PumpModels = {
	[-2007231801] = true,
	[1339433404] = true,
	[1694452750] = true,
	[1933174915] = true,
	[-462817101] = true,
	[-469694731] = true,
	[-164877493] = true
}

-- รถที่ไม่ให้ใช้งานระบบน้ำมัน (ใส่ชื่อรุ่นหรือ hash)
Config.Blacklist = {
	--"Adder",
	--276773164
}

-- ซ่อน HUD เมื่ออยู่ในรถที่ถูก Blacklist
Config.RemoveHUDForBlacklistedVehicle = true

-- ตัวคูณการกินน้ำมันตามประเภทรถ (น้อยกว่า 1 = กินน้อยลง)
Config.Classes = {
	[0] = 1.0, -- Compacts
	[1] = 1.0, -- Sedans
	[2] = 1.0, -- SUVs
	[3] = 1.0, -- Coupes
	[4] = 1.0, -- Muscle
	[5] = 1.0, -- Sports Classics
	[6] = 1.0, -- Sports
	[7] = 1.0, -- Super
	[8] = 1.0, -- Motorcycles
	[9] = 1.0, -- Off-road
	[10] = 1.0, -- Industrial
	[11] = 1.0, -- Utility
	[12] = 1.0, -- Vans
	[13] = 0.0, -- Cycles
	[14] = 1.0, -- Boats
	[15] = 1.0, -- Helicopters
	[16] = 1.0, -- Planes
	[17] = 1.0, -- Service
	[18] = 1.0, -- Emergency
	[19] = 1.0, -- Military
	[20] = 1.0, -- Commercial
	[21] = 1.0, -- Trains
}

-- ค่าการกินน้ำมันตามรอบเครื่อง (ซ้าย = RPM, ขวา = ปริมาณที่ลดต่อวินาที/10)
Config.FuelUsage = {
	[1.0] = 0.8,
	[0.9] = 0.7,
	[0.8] = 0.6,
	[0.7] = 0.5,
	[0.6] = 0.4,
	[0.5] = 0.3,
	[0.4] = 0.2,
	[0.3] = 0.1,
	[0.2] = 0.1,
	[0.1] = 0.1,
	[0.0] = 0.0,
}

Config.GasStations = {
	vector3(49.4187, 2778.793, 58.043),
	vector3(263.894, 2606.463, 44.983),
	vector3(1039.958, 2671.134, 39.550),
	vector3(1207.260, 2660.175, 37.899),
	vector3(2539.685, 2594.192, 37.944),
	vector3(2679.858, 3263.946, 55.240),
	vector3(2005.055, 3773.887, 32.403),
	vector3(1687.156, 4929.392, 42.078),
	vector3(1701.314, 6416.028, 32.763),
	vector3(179.857, 6602.839, 31.868),
	vector3(-94.4619, 6419.594, 31.489),
	vector3(-2554.996, 2334.40, 33.078),
	vector3(-1800.375, 803.661, 138.651),
	vector3(-1437.622, -276.747, 46.207),
	vector3(-2096.243, -320.286, 13.168),
	vector3(-724.619, -935.1631, 19.213),
	vector3(-526.019, -1211.003, 18.184),
	vector3(-70.2148, -1761.792, 29.534),
	vector3(265.648, -1261.309, 29.292),
	vector3(819.653, -1028.846, 26.403),
	vector3(1208.951, -1402.567,35.224),
	vector3(1181.381, -330.847, 69.316),
	vector3(620.843, 269.100, 103.089),
	vector3(2581.321, 362.039, 108.468),
	vector3(176.631, -1562.025, 29.263),
	vector3(176.631, -1562.025, 29.263),
	vector3(-319.292, -1471.715, 30.549),
	vector3(1784.324, 3330.55, 41.253)
}
