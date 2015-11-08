class 'Submarine'

function Submarine:__init()

	self.vehicles = {}
	Events:Subscribe("PlayerChat", self, self.OnPlayerChat)
	Events:Subscribe("PlayerQuit", self, self.OnPlayerQuit)
	Events:Subscribe("ModuleUnload", self, self.OnModuleUnload)
	
end

function Submarine:Create(args, max_accel, max_speed, creator)

	local id = creator:GetId()
	if IsValid(self.vehicles[id]) then
		self.vehicles[id]:Remove()
		self.vehicles[id] = nil
	end

	local vehicle = Vehicle.Create(args)
	
	vehicle:SetNetworkValue("max_accel", math.max(max_accel or 5, 1))
	vehicle:SetNetworkValue("max_speed", math.max(max_speed or 35, 5))
	-- May not always match actual max speed, depending upon acceleration and drag

	self.vehicles[id] = vehicle
	
	return vehicle

end

function Submarine:OnPlayerChat(args)

	local text = args.text:split(" ")
	
	if text[1] == "/sub" then
		
		spawn_args = {
			model_id = 88,
			position = args.player:GetPosition(),
			angle = args.player:GetAngle(),
		}
		
		args.player:EnterVehicle(self:Create(spawn_args, tonumber(text[2]), tonumber(text[3]), args.player), 0)
		
		return false
		
	end

end

function Submarine:OnPlayerQuit(args)

	local id = args.player:GetId()
	if IsValid(self.vehicles[id]) then
		self.vehicles[id]:Remove()
		self.vehicles[id] = nil
	end

end

function Submarine:OnModuleUnload()

	for _, vehicle in pairs(self.vehicles) do
		if IsValid(vehicle) then vehicle:Remove() end
	end

end

Submarine = Submarine()
