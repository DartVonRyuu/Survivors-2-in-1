ThreatenTask = {}
ThreatenTask.__index = ThreatenTask

function ThreatenTask:new(superSurvivor,Aite,Demands)

	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	Demands = "Scram"
		
	o.parent = superSurvivor
	o.Name = "Threaten"
	o.OnGoing = false
	o.Demands = Demands -- scram or drop loot
	o.DemandsSpeech = Demands -- scram or drop loot
	o.Aite = Aite
	o.DealBroke = false
	o.Complete = false
	o.StartedThreatening = false
	o.DistanceAtThreat = 99
	o.theDistance = 999
	o.SquareAtThreat = nil
	o.TicksWaitedForResponse = 0
	
	
	return o

end

function ThreatenTask:isComplete()
	if(not self.Complete) then return false
	else 
		self.parent:StopWalk()
		return true 
	end
end

function ThreatenTask:isValid()
	if (not self.parent)   then return false 
	else return true end
end
function ThreatenTask:dealBreaker()
	if self.StartedThreatening then
	
		if self.Demands == "Scram" then
			if self.Aite.player:isAiming() then return true end
			if (self.DistanceAtThreat - self.theDistance) > 2  then return true end
			if (self.TicksWaitedForResponse > 20 ) and self.parent:RealCanSee(self.Aite.player) then return true end
			
		end
	
	end
	
	if (self.parent.player:getModData().hitByCharacter) then return true end -- Aite is actively pvping this survivor so no deal
	
	return false
end

function ThreatenTask:dealComplete()
	if self.StartedThreatening then
	
		if Demands == "Scram" then
			if self.theDistance >= 30 and not self.parent.player:CanSee(self.Aite.player) then 
				print(self.parent:getName() .. " ThreatenTask complete")
				return true 
			end
		end
	
	end
	
	return false
end

function ThreatenTask:update()

	-- Added this to stop threatening spam
	if ((getDistanceBetween(self.Aite, self.parent.player) >= 8) or (self.parent:inFrontOfLockedDoor())) and (not self.parent.player:CanSee(self.Aite.player)) then return false end 

	if(not self:isValid()) or (self:isComplete()) then return false end
	 self.theDistance = getDistanceBetween(self.Aite, self.parent.player)
		
	if(self.StartedThreatening == true) then
		if(self:dealBreaker()) then 			 
			--self.parent.player:getModData().isRobber = false
			--self.parent.player:getModData().isHostile = true
			self.parent:Speak("alright you asking for it!")
			self.Aite.player:getModData().dealBreaker = true
			self.Complete = true
		end
		
		if(self:dealComplete()) then 
			self.parent.player:NPCSetAiming(false)
			self.Complete = true 
		end
		
		self.TicksWaitedForResponse = self.TicksWaitedForResponse + 1
	end
	
	
	if(self.parent.player:IsAttackRange(self.Aite:getX(),self.Aite:getY(),self.Aite:getZ())) or (self.theDistance < 0.65 )then
			
			self.parent:StopWalk()
			self.parent.player:NPCSetAiming(true)
			self.parent.player:faceThisObject(self.Aite.player)	
				if(self.StartedThreatening == false) then
					self.parent:Speak("get out of here or else!")
					self.DistanceAtThreat = self.theDistance
					self.SquareAtThreat = self.Aite.player:getCurrentSquare()
					
					if self.Aite.player:isLocalPlayer() == false then
						self.Aite:StopWalk()
						self.Aite:getTaskManager():clear()
						self.Aite:getTaskManager():AddToTop(FleeFromHereTask:new(self.parent, self.Aite.player:getCurrentSquare()))	
						--self.Aite:getTaskManager():AddToTop(SurenderTask:new(self.parent, self.Aite))											
					end
					self.StartedThreatening = true
				end
		
	elseif(self.parent:isWalkingPermitted() or (not self.parent:inFrontOfLockedDoor())) then
		
	local cs = self.Aite.player:getCurrentSquare()
		
	self.parent:walkToDirect(cs)
		
	-- The new function to make NPCs actually run if they're too far away from their target
	self.parent:NPC_MovementManagement()
		
	self.parent:DebugSay("walking close to threaten:"..tostring(self.theDistance))
		--self.parent:Speak("walking close to attack:"..tostring(self.theDistance))
	else
		-- Attempted failsafe to make the NPC re-calculate the player. In this case it should be saying 'if npc is at locked door and not walkingpermitted, then do thing.
		-- 0 would only happen if not in front of door. the walkto function checks for ifinfrontoflocked door, and forces it to 15
		-- As a result, it will only check for player's active position every 15 ticks (roughly 7 seconds)
		if (self.parent:inFrontOfLockedDoor()) and (getDistanceBetween(self.parent.player, getSpecificPlayer(0)) <= 7) and (self.parent.WalkToTicks <= 0) then
			self.SquareAtThreat = self.Aite.player:getCurrentSquare()
			local csa = self.SquareAtThreat
			self.parent:walkTo(csa)
		end
		self.parent:DebugSay("ThreatenTask:update - something is wrong, attempting to fix. WalkToTicks = "..tostring(self.parent.WalkToTicks))
		return false
	end
	
	
	
end
