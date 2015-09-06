class 'Submarine'

function Submarine:__init()
	
	self.altitude_step = 0.2 -- 0.2
	self.sea_level = 199.6 -- 199.6
	
	self.altitude_gain = 20 -- 20
	
	self.pitch_gain = 25 -- 25
	self.yaw_gain = 0.6 -- 0.6
	self.roll_gain = 1 -- 1

	if LocalPlayer:InVehicle() then
		local vehicle = LocalPlayer:GetVehicle()
		if vehicle:GetModelId() == 88 and vehicle:GetDriver() == LocalPlayer then
			self.vehicle = vehicle
			self.altitude = self.sea_level
			self.sub = Events:Subscribe("PreTick", self, self.Control)
		end
	end

	Events:Subscribe("LocalPlayerEnterVehicle", self, self.Enter)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.Exit)
	Events:Subscribe("LocalPlayerEjectVehicle", self, self.BlockEject)
	Events:Subscribe("EntityDespawn", self, self.Despawn)
	Events:Subscribe("ModulesLoad", self, self.AddHelp)
	Events:Subscribe("ModuleUnLoad", self, self.RemoveHelp)
	
end

function Submarine:BlockEject()

	if IsValid(self.vehicle) then
		return false
	end

end

function Submarine:Control(args)

	if not IsValid(self.vehicle) then return end
	
	local velocity = self.vehicle:GetLinearVelocity()
	local position = self.vehicle:GetPosition()
	local angle = self.vehicle:GetAngle()
	local speed = -(-angle * velocity).z

	if Input:GetValue(Action.HeliIncAltitude) > 0 then
		self.altitude = self.altitude + self.altitude_step
	elseif Input:GetValue(Action.HeliDecAltitude) > 0 then
		self.altitude = self.altitude - self.altitude_step
	end
	
	self.altitude = math.clamp(self.altitude, math.ceil(Physics:GetTerrainHeight(position)), self.sea_level)
	
	if Input:GetValue(Action.Accelerate) > 0 then
		self.accel = self.vehicle:GetValue("max_accel") - (self.vehicle:GetValue("max_accel") / self.vehicle:GetValue("max_speed")^2) * speed^2
	elseif Input:GetValue(Action.Reverse) > 0 then
		self.accel = -0.1 * (self.vehicle:GetValue("max_accel") - (self.vehicle:GetValue("max_accel") / self.vehicle:GetValue("max_speed")^2) * speed^2)
	else	
		self.accel = 0
	end
	
	if Input:GetValue(Action.TurnLeft) > 0 then
		self.yaw = 1
	elseif Input:GetValue(Action.TurnRight) > 0 then
		self.yaw = -1
	else
		self.yaw = 0
	end

	if self.altitude < self.sea_level or position.y < self.sea_level then
	
		self.vehicle:SetLinearVelocity(velocity + angle * Vector3(0, self.altitude_gain * (self.altitude - position.y), -self.accel) * args.delta)
	
		self.vehicle:SetAngularVelocity(angle * Vector3(self.pitch_gain * -angle.pitch, math.abs(speed)/speed * self.yaw_gain * self.yaw, -self.roll_gain * angle.roll))
	
		LocalPlayer:SetOxygen(1)
		
		-- Chat:Print("submerged", Color.Red)
		
	elseif position.y < self.sea_level + 1 then
	
		self.vehicle:SetLinearVelocity(velocity + angle * Vector3(0, 0, -self.accel) * args.delta)
		
		self.vehicle:SetAngularVelocity(angle * Vector3(self.vehicle:GetAngularVelocity().x, math.abs(speed)/speed * self.yaw_gain * self.yaw, self.vehicle:GetAngularVelocity().z))
		
		-- Chat:Print("on water", Color.Red)
		
	-- else
	
		-- Chat:Print("above water", Color.Red)
		
	end
	
	-- Chat:Print(tostring(self.altitude), Color.Red)

end

function Submarine:Enter(args)

	if args.vehicle:GetModelId() == 88 and args.vehicle:GetDriver() == LocalPlayer and args.vehicle:GetValue("max_speed") and args.vehicle:GetValue("max_accel") then
		self.vehicle = args.vehicle
		self.altitude = self.sea_level
		if not self.sub then
			self.sub = Events:Subscribe("PreTick", self, self.Control)
		end
	end

end

function Submarine:Exit(args)

	if self.vehicle then
		self.vehicle = nil
		if self.sub then
			Events:Unsubscribe(self.sub)
			self.sub = nil
		end
	end

end

function Submarine:Despawn(args)

	if args.entity.__type == "Vehicle" and args.entity == self.vehicle then
		self.vehicle = nil
		if self.sub then
			Events:Unsubscribe(self.sub)
			self.sub = nil
		end
	end
		
end

function Submarine:AddHelp()

    Events:Fire("HelpAddItem",
        {
            name = "Submarine",
            text = 
                "This allows you to spawn a submersible MTA Powerrun 77." .. 
				"\n\nEnter /sub [max accel] [max speed] to spawn a submarine," ..
                "\nwhere max accel and max speed are numbers. If these are" ..
				"\nomited, the defaults are 5 and 35 m/s, respectively."
        })

end

function Submarine:RemoveHelp()

    Events:Fire("HelpRemoveItem",
        {
            name = "Submarine"
        })

end

Submarine = Submarine()
