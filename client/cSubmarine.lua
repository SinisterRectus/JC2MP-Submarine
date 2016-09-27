local clamp, ceil, abs = math.clamp, math.ceil, math.abs

class 'Submarine'

function Submarine:__init()

	self.altitude_step = 0.2 -- 0.2
	self.sea_level = 199.6 -- 199.6

	self.altitude_gain = 20 -- 20

	self.pitch_gain = 25 -- 25
	self.yaw_gain = 0.6 -- 0.6
	self.roll_gain = 1 -- 1

	Events:Subscribe("LocalPlayerEnterVehicle", self, self.Enter)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.Exit)
	Events:Subscribe("LocalPlayerEjectVehicle", self, self.BlockEject)
	Events:Subscribe("EntityDespawn", self, self.Despawn)
	Events:Subscribe("ModulesLoad", self, self.AddHelp)
	Events:Subscribe("ModuleUnload", self, self.RemoveHelp)

end

function Submarine:BlockEject()
	return not IsValid(self.vehicle)
end

function Submarine:Control(args)

	local vehicle = self.vehicle
	if not IsValid(vehicle) then return end

	local velocity = vehicle:GetLinearVelocity()
	local position = vehicle:GetPosition()
	local angle = vehicle:GetAngle()
	local speed = -(-angle * velocity).z

	local altitude = self.altitude
	local sea_level = self.sea_level

	if Input:GetValue(Action.HeliIncAltitude) > 0 then
		altitude = altitude + self.altitude_step
	elseif Input:GetValue(Action.HeliDecAltitude) > 0 then
		altitude = altitude - self.altitude_step
	end

	altitude = clamp(altitude, ceil(Physics:GetTerrainHeight(position)), self.sea_level)
	self.altitude = altitude

	local accel = 0

	if Input:GetValue(Action.Accelerate) > 0 then
		local max_accel = vehicle:GetValue("max_accel")
		local max_speed = vehicle:GetValue("max_speed")
		accel = max_accel - (max_accel / max_speed^2) * speed^2
	elseif Input:GetValue(Action.Reverse) > 0 then
		local max_accel = vehicle:GetValue("max_accel")
		local max_speed = vehicle:GetValue("max_speed")
		accel = -0.1 * (max_accel - (max_accel / max_speed^2) * speed^2)
	end

	local yaw = 0
	if Input:GetValue(Action.TurnLeft) > 0 then
		yaw = 1
	elseif Input:GetValue(Action.TurnRight) > 0 then
		yaw = -1
	end

	if altitude < sea_level or position.y < sea_level then

		local yaw_gain = self.yaw_gain
		local roll_gain = self.roll_gain
		local pitch_gain = self.pitch_gain
		local altitude_gain = self.altitude_gain

		vehicle:SetLinearVelocity(velocity + angle * Vector3(0, altitude_gain * (altitude - position.y), -accel) * args.delta)
		vehicle:SetAngularVelocity(angle * Vector3(pitch_gain * -angle.pitch, abs(speed)/speed * yaw_gain * yaw, -roll_gain * angle.roll))
		LocalPlayer:SetOxygen(1)

		-- Chat:Print("submerged", Color.Red) -- debug

	elseif position.y < sea_level + 1 then

		vehicle:SetLinearVelocity(velocity + angle * Vector3(0, 0, -accel) * args.delta)
		vehicle:SetAngularVelocity(angle * Vector3(vehicle:GetAngularVelocity().x, abs(speed)/speed * self.yaw_gain * yaw, vehicle:GetAngularVelocity().z))

		-- Chat:Print("on water", Color.Red) -- debug

	-- else

		-- Chat:Print("above water", Color.Red) -- debug

	end

end

function Submarine:Enter(args)
	if args.vehicle:GetModelId() == 88 and args.vehicle:GetValue("max_speed") and args.vehicle:GetValue("max_accel") then
		self.vehicle = args.vehicle
		self.altitude = self.sea_level
		self.sub = self.sub or Events:Subscribe("PreTick", self, self.Control)
	end
end

function Submarine:Exit(args)
	if self.vehicle then self:Reset() end
end

function Submarine:Despawn(args)
	if args.entity == self.vehicle then self:Reset() end
end

function Submarine:Reset()
	self.vehicle = nil
	if self.sub then
		Events:Unsubscribe(self.sub)
		self.sub = nil
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
				"\nomited, the defaults are 5 and 35 m/s, respectively." ..
				"\n\nPress Ctrl to dive and Shift to surface."
        })
end

function Submarine:RemoveHelp()
    Events:Fire("HelpRemoveItem",
        {
            name = "Submarine"
        })
end

Submarine = Submarine()
