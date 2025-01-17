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
local upgradeName = lang:getString("upgradeCustomColor")
local rainbowUpgradeName = lang:getString("upgradeRainbowMode")

function PANEL:Init()
    PIXEL.Karts.MoveGarageCamera(0, Vector(0, -20, 25))

    local upgrades = PIXEL.Karts.Config.Upgrades
    local colorDataKey = upgrades.CustomColor.DataKey
    local rainbowDataKey = upgrades.RainbowMode.DataKey

    local function updateColor(col)
        self:SetDataKey(colorDataKey, col)

        local orig = self:GetOriginalDataKey(colorDataKey, color_white)
        if orig.r == col.r and orig.g == col.g and orig.b == col.b then
            self:RemoveReceiptItem(upgradeName)
        else
            self:AddReceiptItem(upgradeName, upgrades.CustomColor.Price[LocalPlayer():PIXELKartsGetLevel()], colorDataKey)
        end
    end

    self.LeftContainer = vgui.Create("Panel", self)
    self.LeftContainer:Dock(LEFT)

    self.RightContainer = vgui.Create("Panel", self)
    self.RightContainer:Dock(RIGHT)

    self.ColorPicker = vgui.Create("PIXEL.ColorPicker", self.LeftContainer)
    self.ColorPicker:Dock(FILL)

    local doneFirstChange
    function self.ColorPicker.OnChange(s, color)
        self.ColorEntry:SetValue("#" .. PIXEL.ColorToHex(color))
        if not IsValid(PIXEL.Karts.PreviewKart) then return end

        if doneFirstChange then
            PIXEL.Karts.SprayPaintKart(PIXEL.Karts.PreviewKart, color)
        end

        doneFirstChange = true
        updateColor(color)
    end

    function self.LeftContainer.PerformLayout(s, w, h)
        local pickerPad = PIXEL.Scale(26)
        self.ColorPicker:DockMargin(0, pickerPad, 0, pickerPad)
    end

    self.RightCenterContainer = vgui.Create("Panel", self.RightContainer)

    function self.RightContainer.PerformLayout(s, w, h)
        self.RightCenterContainer:SetWide(w)
        self.RightCenterContainer:SizeToChildren(false, true)
        self.RightCenterContainer:CenterVertical()
    end

    self.ColorEntryLabel = vgui.Create("PIXEL.Label", self.RightCenterContainer)
    self.ColorEntryLabel:Dock(TOP)
    self.ColorEntryLabel:SetText(lang:getString("hexColour"))
    self.ColorEntryLabel:SetFont("Karts.ColourLabels")
    self.ColorEntryLabel:SetAutoHeight(true)

    self.ColorEntry = vgui.Create("PIXEL.TextEntry", self.RightCenterContainer)
    self.ColorEntry:Dock(TOP)
    self.ColorEntry:SetValue("##000000")

    self.RainbowModeContainer = vgui.Create("Panel", self.RightCenterContainer)
    self.RainbowModeContainer:Dock(TOP)

    self.RainbowCheckbox = vgui.Create("PIXEL.Checkbox", self.RainbowModeContainer)
    self.RainbowCheckbox:Dock(LEFT)

    function self.RainbowCheckbox.OnToggled(s, enabled)
        if not IsValid(PIXEL.Karts.PreviewKart) then return end

        PIXEL.Karts.PreviewKart:SetRainbowMode(enabled)
        self.ColorPicker:SetMouseInputEnabled(not enabled)

        self:SetDataKey(rainbowDataKey, enabled)

        local orig = self:GetOriginalDataKey(rainbowDataKey, false)
        if orig == enabled then
            self:RemoveReceiptItem(rainbowUpgradeName)
        else
            self:AddReceiptItem(rainbowUpgradeName, upgrades.RainbowMode.Price[LocalPlayer():PIXELKartsGetLevel()], rainbowDataKey)
        end
    end

    self.RainbowLabel = vgui.Create("PIXEL.Label", self.RainbowModeContainer)
    self.RainbowLabel:Dock(LEFT)
    self.RainbowLabel:SetText(rainbowUpgradeName)
    self.RainbowLabel:SetFont("Karts.ColourLabels")

    function self.RainbowModeContainer.PerformLayout(s, w, h)
        self.RainbowCheckbox:SetWide(h)
        self.RainbowLabel:SetWide(PIXEL.Scale(140))
        self.RainbowLabel:DockMargin(PIXEL.Scale(4), 0, 0, 0)
    end

    function self.RightCenterContainer.PerformLayout(s, w, h)
        self.ColorEntry:DockMargin(0, PIXEL.Scale(2), PIXEL.Scale(6), 0)
        self.ColorEntry:SetTall(PIXEL.Scale(32))

        self.RainbowModeContainer:DockMargin(0, PIXEL.Scale(8), 0, 0)
        self.RainbowModeContainer:SetTall(PIXEL.Scale(20))
    end

    function self.ColorEntry.OnEnter(s)
        local value = s:GetValue()
        if not string.find(value, "#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]") then return end

        local color = PIXEL.HexToRGB(value)
        if not color then return end

        self.ColorPicker:SetColor(color)
        updateColor(color)
    end

    timer.Simple(0, function()
        self.ColorPicker:SetColor(self:GetDataKey(colorDataKey, color_white))
        if self:GetDataKey(rainbowDataKey, false) then
            self.RainbowCheckbox:DoClick()
        end
    end)
end

function PANEL:LayoutContent(w, h)
    local desiredH = PIXEL.Scale(250)
    if self:GetTall() ~= desiredH then
        self:SetTall(desiredH)
        self:SetWide(PIXEL.Scale(380))
    end

    local halfW = w * .47
    self.LeftContainer:SetWide(halfW)
    self.RightContainer:SetWide(halfW)
end

vgui.Register("PIXEL.Karts.ColorEditor", PANEL, "PIXEL.Karts.BaseUpgradeEditor")