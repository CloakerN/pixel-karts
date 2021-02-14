
local garageConfig = PIXEL.Karts.Config.Garage

local function togglePlayerGarageState(ply)
    if ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then
        ply:SetNWBool("PIXEL.Karts.IsInGarage", false)
        ply:SetNWBool("PIXEL.Karts.IsInGarageWithKart", false)

        ply:SetPos(garageConfig.LeavePosition)
        ply:SetEyeAngles(garageConfig.LeaveAngles)

        net.Start("PIXEL.Karts.GarageStateUpdate")
        net.Send(ply)
    else
        if ply:Health() < 1 then return end
        if ply:GetPos():DistToSqr(garageConfig.EntryRangeCheckPoint) > garageConfig.EntryRangeCheckRadius ^ 2 then return end

        local veh = ply:GetVehicle()
        if IsValid(veh) then
            if not veh.IsPIXELKart then return end

            if veh:CPPIGetOwner() ~= ply then
                PIXEL.Karts.Notify(ply, "You can't enter the garage with someone else's kart.", 1, 5)
                return
            end

            veh:GetPhysicsObject():EnableMotion(false)
            veh:SetColor(color_transparent)
            veh:SetRenderMode(RENDERMODE_TRANSCOLOR)

            ply:SetNWBool("PIXEL.Karts.IsInGarage", true)
            ply:SetNWBool("PIXEL.Karts.IsInGarageWithKart", true)
            ply:SetNWEntity("PIXEL.Karts.PersonalKart", nil)

            ply:PIXELKartsGetDataKey("purchased_kart", function(hasKart)
                if not (IsValid(ply) and hasKart) then return end
                ply.PIXELKartsHasKart = true
            end)

            net.Start("PIXEL.Karts.GarageEntered")
             net.WriteVector(veh:GetPos())
            net.Send(ply)

            ply:ExitVehicle()
            ply:SetPos(garageConfig.InsidePosition)
            veh:Remove()

            return
        elseif IsValid(ply:GetNWEntity("PIXEL.Karts.PersonalKart", nil)) and not ply.PIXELKartsHasKart then
            PIXEL.Karts.Notify(ply, "You already have a kart taken out of the garage.", 1, 5)
            return
        end

        net.Start("PIXEL.Karts.GarageEntered")
         net.WriteVector(ply.PIXELKartsHasKart and garageConfig.KartPos or vector_origin)
        net.Send(ply)

        ply:SetNWBool("PIXEL.Karts.IsInGarage", true)
        ply:SetNWBool("PIXEL.Karts.IsInGarageWithKart", true)
        ply:SetNWEntity("PIXEL.Karts.PersonalKart", nil)

        ply:SetPos(garageConfig.InsidePosition)
    end
end
util.AddNetworkString("PIXEL.Karts.GarageEntered")


net.Receive("PIXEL.Karts.GarageStateUpdate", function(len, ply)
    local steamId = ply:SteamID64()
    if timer.Exists("PIXEL.Karts.GarageStateUpdateCooldown:" .. steamId) then return end
    timer.Create("PIXEL.Karts.GarageStateUpdateCooldown:" .. steamId, .5, 1, function() end)

    togglePlayerGarageState(ply)
end)
util.AddNetworkString("PIXEL.Karts.GarageStateUpdate")


net.Receive("PIXEL.Karts.PurchaseKart", function(len, ply)
    if not ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end
    if ply.PIXELKartsHasKart then return end

    local price = PIXEL.Karts.Config.KartPrice[ply:PIXELKartsGetLevel()]
    if not ply:canAfford(price) then
        togglePlayerGarageState(ply)
        PIXEL.Karts.Notify(ply, "You can't afford to buy a kart.", 1)
        return
    end

    ply:PIXELKartsSetDataKey("purchased_kart", true, function()
        ply:addMoney(-price)
        PIXEL.Karts.Notify(ply, "Purchased a kart for " .. DarkRP.formatMoney(price) .. ".", 1)
        ply.PIXELKartsHasKart = true

        net.Start("PIXEL.Karts.RespawnKart")
        net.Send(ply)
    end)
end)
util.AddNetworkString("PIXEL.Karts.PurchaseKart")


local upgradesConfig = PIXEL.Karts.Config.Upgrades
net.Receive("PIXEL.Karts.PurchaseKartUpgrades", function(len, ply)
    if not ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end
    if not ply.PIXELKartsHasKart then return end

    local rankLevel = ply:PIXELKartsGetLevel()

    local changes = {}
    local totalPrice = 0

    local changeCount = net.ReadUInt(4)
    for i = 1, changeCount do
        local upgradeName = net.ReadString()
        local upgrade = upgradesConfig[upgradeName]
        if not upgrade then return end

        if upgrade.RequiredLevel and not ply:PIXELKartsIsLevel(upgrade.RequiredLevel) then return end

        totalPrice = totalPrice + upgrade.Price[rankLevel]

        if upgrade.Type == "Color" then
            changes[upgradeName] = {net.ReadColor(), net.ReadBool()}
        elseif upgrade.Type == "boolean" then
            changes[upgradeName] = net.ReadBool()
        end
    end

    if not ply:canAfford(totalPrice) then
        PIXEL.Karts.Notify(ply, "You can't afford to purchase these upgrades.", 1)
        return
    end

    ply:addMoney(-totalPrice)

    local mergeData = {}
    for upgradeName, newData in pairs(changes) do
        local upgrade = upgradesConfig[upgradeName]
        if not upgrade then return end

        local upgradeKey = upgrade.DataKey

        if upgrade.Type == "Color" then
            local upgradeKeyEnabled = upgrade.DataKeyEnabled
            mergeData[upgradeKey] = ColorAlpha(newData[1], 255)
            mergeData[upgradeKeyEnabled] = newData[2]
        elseif upgrade.Type == "boolean" then
            mergeData[upgradeKey] = newData
        end
    end

    ply:PIXELKartsAddData(mergeData, function()
        if not IsValid(ply) then return end
        togglePlayerGarageState(ply)
        net.Start("PIXEL.Karts.PurchaseKartUpgrades")
        net.Send(ply)
    end)
end)
util.AddNetworkString("PIXEL.Karts.PurchaseKartUpgrades")


net.Receive("PIXEL.Karts.RespawnKart", function(len, ply)
    if not ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end
    if ply.PIXELKartsHasKart then return end

    local price = PIXEL.Karts.Config.RespawnPrice[ply:PIXELKartsGetLevel()]
    if not ply:canAfford(price) then
        togglePlayerGarageState(ply)
        PIXEL.Karts.Notify(ply, "You can't afford to respawn your kart.", 1)
        return
    end

    ply:addMoney(-price)
    PIXEL.Karts.Notify(ply, "Respawned your kart for " .. DarkRP.formatMoney(price) .. ".", 1)
    ply.PIXELKartsHasKart = true

    net.Start("PIXEL.Karts.RespawnKart")
    net.Send(ply)
end)
util.AddNetworkString("PIXEL.Karts.RespawnKart")


net.Receive("PIXEL.Karts.PutAwayKart", function(len, ply)
    if not ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end

    ply:SetPos(garageConfig.LeavePosition)

    ply:SetNWBool("PIXEL.Karts.IsInGarage", false)
    ply:SetNWBool("PIXEL.Karts.IsInGarageWithKart", false)

    net.Start("PIXEL.Karts.GarageStateUpdate")
    net.Send(ply)
end)
util.AddNetworkString("PIXEL.Karts.PutAwayKart")


hook.Add("PlayerDeath", "PIXEL.Karts.LeaveGarageOnDeath", function(ply)
    if not ply:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end

    ply:SetPos(garageConfig.LeavePosition)

    ply:SetNWBool("PIXEL.Karts.IsInGarage", false)
    ply:SetNWBool("PIXEL.Karts.IsInGarageWithKart", false)

    net.Start("PIXEL.Karts.GarageStateUpdate")
    net.Send(ply)
end)