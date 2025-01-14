--[[
    PIXEL Karts
    Copyright (C) 2022 Thomas (Tom.bat) O'Sullivan 

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

local PANEL = {}

local lang = gmodI18n.getAddon("pixelkarts")

function PANEL:Init()
    self:SetZPos(32767)
    self:SetDraggable(false)
    self:MakePopup()
    self.CloseButton:Remove()

    self:SetTitle(lang:getString("availableUpgradesTitle"))
    self:SetSize(PIXEL.Scale(280), PIXEL.Scale(300))
    self:SetPos(PIXEL.Scale(20), PIXEL.Scale(20))

    self.LocalPly = LocalPlayer()

    self.Upgrades = {}

    for upgradeId, upgrade in pairs(PIXEL.Karts.Config.Upgrades) do
        if not upgrade.UIElement then continue end

        local isLocked
        if upgrade.RequiredLevel then
            isLocked = not self.LocalPly:PIXELKartsIsLevel(upgrade.RequiredLevel)
        end

        self:AddUpgrade(lang:getString("upgrade" .. upgradeId), upgrade.UIElement, isLocked, upgrade.RequiredLevel)
    end

    self.Receipt = vgui.Create("PIXEL.Karts.KartReceipt")
    self.Receipt.UpgradeList = self
end

PIXEL.RegisterFont("Karts.UpgradeName", "Open Sans SemiBold", 22)
PIXEL.RegisterFont("Karts.UpgradeEdit", "Open Sans SemiBold", 18)

local rankNames = PIXEL.Karts.Config.RankLevelNames

local upgradeBg = PIXEL.OffsetColor(PIXEL.Colors.Background, 4)
function PANEL:AddUpgrade(name, element, locked, rank)
    local upgrade = vgui.Create("Panel", self)
    upgrade:Dock(TOP)

    local editButton = vgui.Create("PIXEL.TextButton", upgrade)
    editButton:SetFont("Karts.UpgradeEdit")

    function editButton.DoClick()
        if locked then return end
        if IsValid(self.UpgradeEditor) then self.UpgradeEditor:Remove() end
        self.UpgradeEditor = vgui.Create(element)
        self.UpgradeEditor:SetTitle(name)
        self.UpgradeEditor.UpgradeList = self
    end

    if locked then
        editButton:SetText(lang:getString("rankOnly", {rankName = rankNames[rank] or ""}))
        editButton:SetEnabled(false)
        editButton.DisabledCol = PIXEL.Colors.Negative
        editButton.DesiredSize = 80
    else
        editButton:SetText(lang:getString("edit"))
        editButton.DesiredSize = 50
    end

    function upgrade:Paint(w, h)
        PIXEL.DrawRoundedBox(PIXEL.Scale(6), 0, 0, w, h, upgradeBg)
        PIXEL.DrawSimpleText(name, "Karts.UpgradeName", PIXEL.Scale(10), h * .5, PIXEL.Colors.PrimaryText, nil, TEXT_ALIGN_CENTER)
    end

    function upgrade:PerformLayout(w, h)
        local editBtnW = PIXEL.Scale(editButton.DesiredSize)
        editButton:SetSize(editBtnW, PIXEL.Scale(24))
        editButton:SetPos(w - editBtnW - PIXEL.Scale(5), 0)
        editButton:CenterVertical()
    end

    table.insert(self.Upgrades, upgrade)
end

function PANEL:GetData(data)
    return self.KartData
end

function PANEL:SetData(data)
    if not self.KartData then
        self.OriginalKartData = table.Copy(data)
    end

    self.KartData = table.Copy(data)
end

function PANEL:ResetData(data)
    self.KartData = self.OriginalKartData
end

function PANEL:GetDataKey(key, default)
    return self.KartData[key] or default
end

function PANEL:GetOriginalDataKey(key, default)
    return self.OriginalKartData[key] or default
end

function PANEL:SetDataKey(key, val)
    self.KartData[key] = val
end

function PANEL:ResetDataKey(key)
    if not key then return end
    self.KartData[key] = self.OriginalKartData[key]
end

function PANEL:AddReceiptItem(name, price, ...)
    self.Receipt:AddItem(name, price, ...)
end

function PANEL:RemoveReceiptItem(name)
    self.Receipt:RemoveItem(name)
end

function PANEL:OnClose()
    if IsValid(self.UpgradeEditor) then
        self.UpgradeEditor:Close()
    end

    if IsValid(self.Receipt) then
        self.Receipt:Remove()
    end
end

function PANEL:LayoutContent(w, h)
    local upgradeH = PIXEL.Scale(45)
    local upgradeSpacing = PIXEL.Scale(6)

    for i, upgrade in ipairs(self.Upgrades) do
        if i ~= 1 then upgrade:DockMargin(0, upgradeSpacing, 0, 0) end
        upgrade:SetTall(upgradeH)
    end

    self:SizeToChildren(false, true)
end

vgui.Register("PIXEL.Karts.Upgrader", PANEL, "PIXEL.Frame")