-- Mist Universal
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Module Table
local module = {}
local camlockConn

-- UI Load
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false
})

ui.autoDisableToggles = true

-- Window
local window = ui.newWindow({
    text = 'Dollarware demo',
    resize = true,
    size = Vector2.new(550, 376),
    position = nil
})

-- Menu: Main
local menuMain = window:addMenu({
    text = 'Main'
})

local sectionMain = menuMain:addSection({
    text = 'Main Features',
    side = 'auto',
    showMinButton = true
})

-- Aimlock Toggle
local aimlockToggle = sectionMain:addToggle({
    text = 'Aimlock',
    state = false
})
aimlockToggle:bindToEvent('onToggle', function(state)
    if state then
        module.EnableCamlock()
    else
        module.DisableCamlock()
    end
end)

-- Aimlock Functions
function module.EnableCamlock()
    if camlockConn then camlockConn:Disconnect() end
    camlockConn = RunService.RenderStepped:Connect(function()
        local nearest, dist = nil, math.huge
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local d = (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = plr
                end
            end
        end
        if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Character.HumanoidRootPart.Position)
        end
    end)
end

function module.DisableCamlock()
    if camlockConn then camlockConn:Disconnect() end
end

-- ESP Toggle
local espToggle = sectionMain:addToggle({
    text = 'ESP',
    state = false
})
local espConn
espToggle:bindToEvent('onToggle', function(state)
    if espConn then espConn:Disconnect() end
    if not state then return end

    -- ESP Logic
    local Lines, Quads = {}, {}

    local function HasCharacter(Player)
        return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    end

    local function DrawLine(From, To)
        local FromScreen, FromVisible = Camera:WorldToViewportPoint(From)
        local ToScreen, ToVisible = Camera:WorldToViewportPoint(To)
        if not FromVisible and not ToVisible then return end
        local Line = Drawing.new("Line")
        Line.Thickness = 1
        Line.From = Vector2.new(FromScreen.X, FromScreen.Y)
        Line.To = Vector2.new(ToScreen.X, ToScreen.Y)
        Line.Color = Color3.fromRGB(255, 255, 255)
        Line.Transparency = 1
        Line.Visible = true
        table.insert(Lines, Line)
    end

    local function DrawQuad(A, B, C, D)
        local a, aVis = Camera:WorldToViewportPoint(A)
        local b, bVis = Camera:WorldToViewportPoint(B)
        local c, cVis = Camera:WorldToViewportPoint(C)
        local d, dVis = Camera:WorldToViewportPoint(D)
        if not (aVis or bVis or cVis or dVis) then return end
        local Quad = Drawing.new("Quad")
        Quad.PointA = Vector2.new(a.X, a.Y)
        Quad.PointB = Vector2.new(b.X, b.Y)
        Quad.PointC = Vector2.new(c.X, c.Y)
        Quad.PointD = Vector2.new(d.X, d.Y)
        Quad.Color = Color3.fromRGB(255, 255, 255)
        Quad.Thickness = 0.5
        Quad.Transparency = 0.25
        Quad.Filled = true
        Quad.Visible = true
        table.insert(Quads, Quad)
    end

    local function GetCorners(Part)
        local cf, sz = Part.CFrame, Part.Size / 2
        local c = {}
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    table.insert(c, (cf * CFrame.new(sz * Vector3.new(x, y, z))).Position)
                end
            end
        end
        return c
    end

    local function DrawEsp(Player)
        local HRP = Player.Character.HumanoidRootPart
        local verts = GetCorners({CFrame = HRP.CFrame * CFrame.new(0, -0.5, 0), Size = Vector3.new(3, 5, 3)})
        DrawLine(verts[1], verts[2])
        DrawLine(verts[2], verts[6])
        DrawLine(verts[6], verts[5])
        DrawLine(verts[5], verts[1])
        DrawQuad(verts[1], verts[2], verts[6], verts[5])
        DrawLine(verts[1], verts[3])
        DrawLine(verts[2], verts[4])
        DrawLine(verts[6], verts[8])
        DrawLine(verts[5], verts[7])
        DrawQuad(verts[2], verts[4], verts[8], verts[6])
        DrawQuad(verts[1], verts[2], verts[4], verts[3])
        DrawQuad(verts[1], verts[5], verts[7], verts[3])
        DrawQuad(verts[5], verts[7], verts[8], verts[6])
        DrawLine(verts[3], verts[4])
        DrawLine(verts[4], verts[8])
        DrawLine(verts[8], verts[7])
        DrawLine(verts[7], verts[3])
        DrawQuad(verts[3], verts[4], verts[8], verts[7])
    end

    espConn = RunService.RenderStepped:Connect(function()
        for _, l in ipairs(Lines) do l:Remove() end
        for _, q in ipairs(Quads) do q:Remove() end
        Lines, Quads = {}, {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and HasCharacter(player) then
                DrawEsp(player)
            end
        end
    end)
end)

-- FOV Slider
sectionMain:addSlider({
    text = 'FOV',
    min = 40,
    max = 120,
    step = 1,
    val = Camera.FieldOfView
}, function(val)
    module.SetFOV(val)
end)

function module.SetFOV(val)
    val = math.clamp(tonumber(val) or 70, 40, 120)
    Camera.FieldOfView = val
end

-- Speed Slider
sectionMain:addSlider({
    text = 'Speed',
    min = 8,
    max = 100,
    step = 1,
    val = 16
}, function(val)
    module.SetSpeed(val)
end)

function module.SetSpeed(val)
    val = math.clamp(tonumber(val) or 16, 8, 100)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end
