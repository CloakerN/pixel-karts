
AddCSLuaFile()

local kart = {
    IsPIXELKart = true
}

function kart:Initialize()
    PIXEL.Karts.SetupNWVars(self)

    if CLIENT then return end

    self:SetNWInt("PIXEL.Karts.Health", 100)

    self:SetRocketBoost(true)
    self:SetGlider(true)
    self:SetRainbowMode(true)
    self:SetBuiltInRadio(true)
    self:SetUnderGlow(Color(255, 0, 0))
end

function kart:GetClass()
    return "pixel_kart"
end

if CLIENT then
    local hsv, time = HSVToColor, CurTime
    local boosterPos, boosterAng = Vector(0, -42, 14), Angle(90, -90, 0)
    function kart:Think()
        if self:GetRainbowMode() then
            self:SetColor(hsv((time() * 20) % 360, 1, 1))
        else
            self:GetCustomColor()
        end

        if self:GetRocketBoost() then
            if not IsValid(self.RocketBooster) then
                self.RocketBooster = ClientsideModel("models/maxofs2d/thruster_projector.mdl")
                self.RocketBooster:SetParent(self)
                self.RocketBooster:SetModelScale(.6)
            end

            self.RocketBooster:SetPos(self:LocalToWorld(boosterPos))
            self.RocketBooster:SetAngles(self:LocalToWorldAngles(boosterAng))
        elseif IsValid(self.RocketBooster) then
            self.RocketBooster:Remove()
        end

        self:SetBodygroup(4, self:GetNWBool("PIXEL.Karts.IsGliding", false) and 1 or 0)
    end

    function kart:RadioStop()
        if not self.RadioPlayer then return end

        PIXEL.Karts.Radio.StopMedia(self.RadioPlayer)
        self.RadioPlayer = nil
        self.RadioPlayerCreated = nil
    end

    function kart:OnRemove()
        if IsValid(self.RocketBooster) then self.RocketBooster:Remove() end
        self:RadioStop()
    end
else
    function kart:Think()
        if self:IsVehicleBodyInWater() then
            self:SetNWInt("PIXEL.Karts.Health", 0)
        end
    end

    function kart:RadioSetChannel(chan)
        self:SetNW2Int("PIXEL.Karts.RadioChannel", chan)
    end
end

function kart:RadioGetChannel()
    return self:GetNW2Int("PIXEL.Karts.RadioChannel")
end

PIXEL.Karts.KartTable = kart

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "PIXEL Kart"
ENT.Category = "PIXEL Karts"
ENT.Author = "Tom.bat & The One Free-Man"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:Initialize()
    if CLIENT then
        self:SetModel("models/freeman/vehicles/electric_go-kart.mdl")
        return
    end

    if not self.CPPIGetOwner then
        SafeRemoveEntityDelayed(self, .1)
        return
    end

    local owner = self:CPPIGetOwner()
    local ownerId = owner:SteamID64()
    if PIXEL.Karts.Vehicles[ownerId] then
        PIXEL.Karts.Notify(owner, "Ayy wassup bro i think u got too many karts there.", 1)
        SafeRemoveEntityDelayed(self, .1)
        return
    end

    local veh = ents.Create("prop_vehicle_jeep")
    veh:SetPos(self:GetPos())
    veh:SetAngles(self:GetAngles())
    veh:SetModel("models/freeman/vehicles/electric_go-kart.mdl")
    veh:SetKeyValue("vehiclescript", "scripts/vehicles/pixel/kart.txt")
    veh:Spawn()

    for k, v in pairs(kart) do
        veh[k] = v
    end

    veh:SetNWBool("PIXEL.Karts.IsKart", true)
    veh:SetNWString("PIXEL.Karts.KartID", ownerId)

    veh:CPPISetOwner(owner)
    veh.PIXELKartID = ownerId


    if owner:IsSuperAdmin() then
        undo.Create("PIXEL Kart")
            undo.AddEntity(veh)
            undo.SetPlayer(owner)
        undo.Finish()
    end

    self.Kart = veh
    PIXEL.Karts.Vehicles[ownerId] = veh

    SafeRemoveEntityDelayed(self, .1)

    veh:Initialize()
end