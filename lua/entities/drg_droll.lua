--[[
	by Klen_list

	^=v=^ mew!
]]

if not DrGBase then
	MsgN"[Nextbot] DrGBase not exist! Abort load..."
	return
end

ENT.Base = "drgbase_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Droll"
ENT.Category = "Memes"

ENT.Models = {"models/player/putin.mdl"}
ENT.CollisionBounds = Vector(20, 20, 63)
ENT.RagdollOnDeath = false

ENT.WalkAnimation = "walk_all_Moderate"
ENT.RunAnimation = "walk_all_Moderate"
ENT.IdleAnimation = "idle_all_01"

ENT.RunSpeed = 420

ENT.ClimbLedges = true
ENT.ClimbProps = true
ENT.ClimbLadders = true
ENT.ClimbLaddersDown = true

ENT.OnIdleSounds = {
	"zuzu_mode/op.wav",
	"zuzu_mode/ed.wav"
}

ENT.SpawnHealth = 10000
ENT.HealthRegen = 100

ENT.Factions = {"FACTION_ZUZU"}
ENT.Frightening = true

ENT.EyeBone = "head"
ENT.EyeOffset = Vector(10, 0, 1)
ENT.EyeAngle = Angle(0, 0, 0)

if SERVER then

AddCSLuaFile()

local AI_ignore = GetConVar"ai_ignoreplayers"

-- //// Util functions

local function clamp(_in, _min, _max)
	return _in < _min and _min or _in > _max and _max or _in
end

local function GetPlayerVehicle(p)
	if not (IsValid(p) and p:IsPlayer()) then return end
	local veh = p:GetVehicle()
	if not IsValid(veh) then return end
	local wac = veh:GetNWEntity"wac_aircraft"
	return (IsValid(wac) and wac) or (p.lfsGetPlane and p:lfsGetPlane())
end

-- //// Nextbot functions

function ENT:CustomInitialize()
	self:SetDefaultRelationship(D_HT)
	self:AddPlayersRelationship(D_HT)
end

local fents, fent
function ENT:OpenDoors()
	fents = ents.FindInSphere(self:LocalToWorld(self:OBBCenter()), 50)
	for e = 1,#fents do
		fent = fents[e]
		if IsValid(fent) and fent:GetClass():find"door" then
			fent:Fire"open"
		end
	end
	fents, fent = nil, nil
end

local targ -- target lock for CustomThink

function ENT:OnNewEnemy(e)
	targ = e
end

function ENT:OnEnemyChange(_, new)
	targ = new
end

local fplys, fply, veh
function ENT:CustomThink()
	self:OpenDoors()

	if AI_ignore:GetBool() then return end

	fplys = player.GetAll()
	for p = 1,#fplys do
		fply = fplys[p]
		veh = GetPlayerVehicle(fply)
		if not IsValid(veh) then continue end
		local tr = util.TraceLine{
			start = self:LocalToWorld(self:OBBCenter()),
			endpos = fply:GetVehicle():GetPos(),
			filter = self
		}
		end
	fplys, fply = nil, nil

	if IsValid(targ) and targ:Alive() then
		if self:GetPos():Distance(targ:GetPos()) < 500 and math.random(1, 500) == 14 then
			self:Jump(500)
		end
		if targ:IsPlayer() then
			self.RunSpeed = clamp(targ:InVehicle() and (self.RunSpeed + math.abs(targ:GetVehicle():GetSpeed()) * 2) or 420, 420, 5000)
		end
	end
end

function ENT:OnMeleeAttack(enemy)
	self:Attack{
		damage = self:IsPossessed() and 800 or 90,
		type = DMG_CLUB,
		range = 50,
		angle = 135
	}
end

local physbone
function ENT:OnContact(ent)
	if not IsValid(ent) then return end

	constraint.RemoveAll(ent)

	if ent:Health() > 0 and not (ent.IsDrGNextbot and ent:IsInFaction"FACTION_ZUZU") then
		ent:TakeDamage(self:IsPossessed() and 800 or 90, self, self)
	end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end

	if ent:IsRagdoll() then
		for b = 0,ent:GetBoneCount() do
			physbone = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(b))
			if IsValid(physbone) then physbone:EnableMotion(true) end
		end
		physbone = nil
	else
		phys:EnableMotion(true)
	end
	phys:ApplyForceOffset((ent:GetPos() - self:GetPos()):GetNormalized() * 1e7, ent:GetPos())
end

function ENT:OnTakeDamage(dmg, hitgroup)
	if dmg:IsDamageType(DMG_CRUSH) or dmg:IsDamageType(DMG_VEHICLE) then return true end -- prevent push dmg
	self:SpotEntity(dmg:GetAttacker())
end

function ENT:OnIdle()
	if math.random(1, 4) == 2 then
		self:PlaySequenceAndWait"menu_gman"
	end

	if navmesh.IsLoaded() then
		local ply = table.Random(player.GetAll())
		if IsValid(ply) and ply:OnGround() and not ply:IsInWorld() then
			local plypos = ply:GetPos()
			local area = navmesh.GetNearestNavArea(plypos)
			if IsValid(area) then
				self:AddPatrolPos(area:GetClosestPointOnArea(plypos))
				return
			end
		end
	end

	self:AddPatrolPos(self:RandomPos(1500))
end

elseif CLIENT then

ENT.Killicon = {icon = "killicons/droll", color = Color(255, 80, 0)}

function ENT:CustomDraw()
	self.CustomDraw = function() end
	if util.IsValidModel(self:GetModel()) then
		self:EnableMatrix("RenderMultiply", Matrix{{2, 0, 0, 0}, {0, 7, 0, 0}, {0, 0, .9, 0}, {0, 0, 0, 1}})
		self:DestroyShadow()
		self:SetLOD(-1)
	else
		chat.AddText(beamcol, "[Nextbot] Missing model detected!")
		if havemodel then
			chat.AddText(beamcol, "[Nextbot] Restart the game after additional addon subscription/enable")
			chat.AddText(beamcol, "[Nextbot] If after restarting the game model still missing - reinstall the game")
		else
			chat.AddText(beamcol, "[Nextbot] INSTALL and ENABLE additional addons")
		end
		return
	end
end

end -- CLIENTSERVER endif

DrGBase.AddNextbot(ENT)
