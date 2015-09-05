class 'Submarine'

function Submarine:__init()

	Events:Subscribe("PlayerChat", self, self.OnPlayerChat)
	
end

function Submarine:Create(args, max_accel, max_speed)

	local vehicle = Vehicle.Create(args)
	
	vehicle:SetNetworkValue("max_accel", max_accel or 5)
	vehicle:SetNetworkValue("max_speed", max_speed or 35) 
	-- May not always match actual max speed, depending upon acceleration and drag
	
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
		
		args.player:EnterVehicle(self:Create(spawn_args, tonumber(text[2]), tonumber(text[3])), 0)
		
		return false
		
	end

end

Submarine = Submarine()
