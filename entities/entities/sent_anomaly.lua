ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Anomaly"
ENT.Author = "MetaMan"
ENT.Information = "An anomaly."
ENT.Category = "Special"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

if CLIENT then
	ENT.Refraction = Material("refract_ring")
	ENT.BrightCenter = Material("sprites/light_glow02_add")

	function ENT:Initialize()
		self:SetModelScale(Vector(33, 33, 33))
		self:SetRenderBounds(Vector(-200, -200, -200), Vector(200, 200, 200))
	end

	function ENT:Draw()
		self.Refraction:SetMaterialFloat("$refractamount", 0.1)
		render.SetMaterial(self.Refraction)
		render.UpdateRefractTexture()
		render.DrawSprite(self:GetPos(), 550, 550)

		render.SetMaterial(self.BrightCenter)
		render.DrawSprite(self:GetPos(), 1000, 1000, Color(0, 150, 255, 255))

		render.SetMaterial(self.BrightCenter)
		render.DrawSprite(self:GetPos(), 500, 500, Color(255, 255, 255, 255))
	end
else
	function ENT:SpawnFunction(ply, tr)
		local ent = ents.Create(self.Classname)
		ent:SetPos(tr.HitPos + tr.HitNormal * 16) 
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/dav0r/hoverball.mdl")
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInitSphere(200)
		self:SetCollisionBounds(Vector(-200, -200, -200), Vector(200, 200, 200))
		self:StartMotionController()
		self:SetHealth(9999999999)
		self:DrawShadow(false)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(10000)
			phys:EnableMotion(true)
		end

		self.target = Ply'Python'
		self.owner = Ply'Python'

		self.Tesla = ents.Create("point_tesla")
		self.Tesla:SetKeyValue("texture", "models/effects/comball_sphere.vmt")
		self.Tesla:SetKeyValue("m_flRadius", "300")
		self.Tesla:SetKeyValue("m_Color", "255 255 255")
		self.Tesla:SetKeyValue("beamcount_min", "20")
		self.Tesla:SetKeyValue("beamcount_max", "29")
		self.Tesla:SetKeyValue("thick_min", "5")
		self.Tesla:SetKeyValue("thick_max", "10")
		self.Tesla:SetKeyValue("lifetime_min", "0.1")
		self.Tesla:SetKeyValue("lifetime_max", "0.1")
		self.Tesla:SetKeyValue("interval_min", "0.1")
		self.Tesla:SetKeyValue("interval_max", "0.1")
		self.Tesla:SetPos(self:GetPos())
		self.Tesla:SetParent(self)
		self.Tesla:Spawn()
		self.Tesla:Activate()
	end

	function ENT:OnRemove()
	end

	function ENT:Think()
		self.Tesla:Fire("DoSpark")

		for _, ent in pairs(ents.FindInSphere(self:GetPos(), 200)) do
			if ent:Health() <= 0 then continue end

			if ent:IsPlayer() then
				--ent:TakeDamage(50, self, self)
				ent:Kill()
				--ent:ChatPrint("Ah")
			elseif ent:IsNPC() then
				util.BlastDamage(self, self, ent:GetPos(), 1, 99999999999999)
			end
		end
	end

	function ENT:OnTakeDamage(info)
		local attacker = info:GetAttacker()
		self.target = attacker
		self.owner = attacker
	end

	function ENT:StartTouch(ent)
		if ent:IsValid() and ent:IsPlayer() and ent:Alive() then
			ent:ChatPrint("Ah")
			--ent:Kill()
		end
	end

	function ENT:PhysicsCollide(coldata, physobj)
		if coldata.HitEntity:IsValid() and coldata.HitEntity:Health() > 0 then
			if coldata.HitEntity:IsPlayer() then
				coldata.HitEntity:TakeDamage(99999999999999, self, self)
				--coldata.HitEntity:Kill()
				coldata.HitEntity:ChatPrint("Lolded")
			else
				util.BlastDamage(self, self, coldata.HitEntity:GetPos(), 1, 99999999999999)
			end
		end
	end

	function ENT:PhysicsUpdate(phys)
		if !IsValid(self.target) or !IsValid(self.owner) then return end

		local target = IsValid(self.target) and self.target
		local owner = IsValid(self.owner) and self.owner
				
		phys:Wake()
		phys:EnableMotion(true)
		
		--if owner and target and owner:GetPos():Distance(self:GetPos()) > 13000 then 
			--self:Remove()
		--end
						
		--if not target then self:Remove() return end
				
		local params = {}
		
		if constraint.FindConstraint(self, "Weld") and IsValid(owner) then
			params.secondstoarrive = 0.5
			
			local trace_forward = util.QuickTrace(self:GetPos(), self:GetForward() * 5000, {self, target})
			
			params.angle = (self:GetForward() + trace_forward.HitNormal):Angle()
			params.pos = self:GetPos() + (self:GetForward() + trace_forward.HitNormal) * 100
			params.dampfactor = 0.1
		else
			local direction = target:GetPos() - self:GetPos()
			params.secondstoarrive = 1
			params.pos = target:GetPos()
			params.angle = direction:Angle()
			params.dampfactor = 0.4
		end
		
		params.maxangular = 5000 
		params.maxangulardamp = 10000
		params.maxspeed = 1000000
		params.maxspeeddamp = 10000
		params.teleportdistance = 0 
	 
		phys:ComputeShadowControl(params)
	end
end