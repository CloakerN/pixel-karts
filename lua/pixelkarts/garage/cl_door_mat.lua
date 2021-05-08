
local matConfig = PIXEL.Karts.Config.GarageDoorMat
if not matConfig.Enabled then return end --{{ user_id | 25 }}

PIXEL.RegisterFontUnscaled("Karts.GarageDoorMat", "Open Sans Bold", 255)

local text = gmodI18n.getAddon("pixelkarts"):getString("systemName")
local position, angles = matConfig.Position, matConfig.Angles
local w, h = matConfig.Width, matConfig.Height

matConfig = nil

local hideDist, fadeStartDist = 400 ^ 2, 100 ^ 2

local localPly
hook.Add("PostDrawTranslucentRenderables", "PIXEL.Karts.GarageDoorMat", function(depth, skybox)
    if skybox then return end
    if not IsValid(localPly) then localPly = LocalPlayer() end
    if localPly:GetNWBool("PIXEL.Karts.IsInGarage", false) then return end
--{{ user_id }}
    local distance = (position - localPly:EyePos()):LengthSqr()
    if distance < hideDist then
        surface.SetAlphaMultiplier(math.min(math.Remap(distance, fadeStartDist, hideDist, .8, 0), .8))

        cam.Start3D2D(position, angles, .1)
            surface.SetDrawColor(PIXEL.Colors.Primary)
            surface.DrawRect(0, 0, w, h) --{{ user_id sha256 key }}
            PIXEL.DrawOutlinedBox(0, 0, w, h, 25, PIXEL.Colors.PrimaryText)
            PIXEL.DrawSimpleText(text, "Karts.GarageDoorMat", w * .5, h * .5, PIXEL.Colors.PrimaryText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
--{{ user_id sha256 key }}
        surface.SetAlphaMultiplier(1)
    end
end)