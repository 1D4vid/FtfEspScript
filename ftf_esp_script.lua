--[[
Script for FTF by David – ESP Flat (futuristic buttons + improved gray-skin)
Beast: vermelho, sobreviventes: verde
PC: aura cor da tela em tempo real (azul, vermelho, verde etc)
Menu Futurista [K]

Nesta versão:
- Integrei a sua função exemplo GreyOutfits para aplicar skin cinza.
- Melhorei para salvar propriedades originais (cores, materials, textures, roupas)
  sempre que possível, para que possamos restaurar ao desativar a opção.
- Restauração tenta recolocar roupas clonadas e restaurar cores/materials/textures.
- Mantive as outras features (ESP, contador ragdoll 28s, startup notice, UI futurista).
- NOTA: em alguns casos (por exemplo quando o jogo troca completamente peças ou remove
  objetos), a restauração pode não ser perfeita — mas a maioria dos casos é coberta.
]]

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- cleanup old GUI instances
for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- ---------- Startup notice (futuristic, bottom center) ----------
local function createStartupNotice(opts)
    opts = opts or {}
    local duration = opts.duration or 6
    local width = opts.width or 340
    local height = opts.height or 60

    local noticeGui = Instance.new("ScreenGui")
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false
    noticeGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "NoticeFrame"
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.94, 20)
    frame.AnchorPoint = Vector2.new(0,0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = noticeGui

    local panel = Instance.new("Frame", frame)
    panel.Name = "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.Position = UDim2.new(0, 0, 0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(10,14,20)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0

    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(55,140,220); stroke.Thickness = 1.2; stroke.Transparency = 0.28
    local grad = Instance.new("UIGradient", panel)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14,18,24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,10,14))
    }
    grad.Rotation = 90

    local accent = Instance.new("Frame", panel)
    accent.Size = UDim2.new(0, 6, 1, -12)
    accent.Position = UDim2.new(0, 8, 0, 6)
    accent.BackgroundColor3 = Color3.fromRGB(49,157,255)
    accent.BorderSizePixel = 0
    local aCorner = Instance.new("UICorner", accent); aCorner.CornerRadius = UDim.new(0, 6)

    local iconBg = Instance.new("Frame", panel)
    iconBg.Size = UDim2.new(0, 36, 0, 36)
    iconBg.Position = UDim2.new(0, 24, 0.5, -18)
    iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26)
    iconBg.BorderSizePixel = 0
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0, 10)
    local iconStroke = Instance.new("UIStroke", iconBg); iconStroke.Color = Color3.fromRGB(90,170,225); iconStroke.Thickness = 1; iconStroke.Transparency = 0.48

    local iconLabel = Instance.new("TextLabel", iconBg)
    iconLabel.Size = UDim2.new(1, -6, 1, -6)
    iconLabel.Position = UDim2.new(0, 3, 0, 3)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.FredokaOne
    iconLabel.Text = "K"
    iconLabel.TextColor3 = Color3.fromRGB(100,170,220)
    iconLabel.TextStrokeTransparency = 0.9
    iconLabel.TextSize = 20

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -96, 1, 0)
    txt.Position = UDim2.new(0, 76, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 16
    txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.TextStrokeTransparency = 0.9
    txt.Text = "Clique na letra \"K\" para ativar o menu"
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Center

    local hint = Instance.new("TextLabel", panel)
    hint.Size = UDim2.new(1, -96, 0, 16)
    hint.Position = UDim2.new(0, 76, 1, -20)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.TextColor3 = Color3.fromRGB(120,140,170)
    hint.Text = "Pressione novamente para fechar"
    hint.TextXAlignment = Enum.TextXAlignment.Left

    -- subtle glow (less white, bluish)
    local glow = Instance.new("Frame", frame)
    glow.Name = "Glow2"
    glow.Size = UDim2.new(1.1, 0, 0.5, 0)
    glow.Position = UDim2.new(-0.05, 0, -0.35, 0)
    glow.BackgroundColor3 = Color3.fromRGB(49,157,255)
    glow.BackgroundTransparency = 0.96
    glow.BorderSizePixel = 0
    local glowCorner = Instance.new("UICorner", glow)
    glowCorner.CornerRadius = UDim.new(0, 20)

    -- initial state: invisible and slightly lower
    panel.BackgroundTransparency = 1
    txt.TextTransparency = 1
    hint.TextTransparency = 1
    iconLabel.TextTransparency = 1
    accent.BackgroundTransparency = 1
    stroke.Transparency = 1

    -- tween in
    local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -width/2, 0.92, 0)}):Play()
    TweenService:Create(panel, tweenInfo, {BackgroundTransparency = 0.0}):Play()
    TweenService:Create(txt, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(hint, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(iconLabel, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(accent, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(stroke, tweenInfo, {Transparency = 0.28}):Play()

    local pulse = true
    spawn(function()
        while pulse and panel.Parent do
            local t1 = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            TweenService:Create(stroke, t1, {Thickness = 1.6}):Play()
            TweenService:Create(iconLabel, t1, {TextColor3 = Color3.fromRGB(120,200,255)}):Play()
            wait(1.0)
            local t2 = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            TweenService:Create(stroke, t2, {Thickness = 1.2}):Play()
            TweenService:Create(iconLabel, t2, {TextColor3 = Color3.fromRGB(100,170,220)}):Play()
            wait(1.0)
        end
    end)

    spawn(function()
        wait(duration)
        pulse = false
        local outInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(panel, outInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(txt, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(hint, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(iconLabel, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(accent, outInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
        TweenService:Create(frame, outInfo, {Position = UDim2.new(0.5, -width/2, 0.96, 20)}):Play()
        wait(0.5)
        if noticeGui and noticeGui.Parent then noticeGui:Destroy() end
    end)

    return noticeGui
end

createStartupNotice({duration = 6, width = 340, height = 60})

-- ---------- Main menu frame (futuristic buttons) ----------
local gWidth, gHeight = 360, 320
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.BackgroundColor3 = Color3.fromRGB(8,10,14)
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
Frame.Position = UDim2.new(0.5, -gWidth//2, 0.17, 0)
Frame.Active = true
Frame.Visible = false
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true

local Accent = Instance.new("Frame", Frame)
Accent.Size = UDim2.new(0, 8, 1, 0)
Accent.Position = UDim2.new(0,4,0,0)
Accent.BackgroundColor3 = Color3.fromRGB(49, 157, 255)
Accent.BorderSizePixel = 0
local aCorner = Instance.new("UICorner", Accent); aCorner.CornerRadius = UDim.new(0,6)

local Title = Instance.new("TextLabel", Frame)
Title.Text = "FTF - David's ESP"
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(170,200,230)
Title.Size = UDim2.new(1, -32, 0, 36)
Title.Position = UDim2.new(0,28,0,8)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local Line = Instance.new("Frame", Frame)
Line.BackgroundColor3 = Color3.fromRGB(20,28,36)
Line.BorderSizePixel = 0
Line.Position = UDim2.new(0,0,0,48)
Line.Size = UDim2.new(1,0,0,2)

-- Futuristic button creator (gradient, rounded, glow, hover tween)
local function createFuturisticButton(txt, ypos, c1, c2)
    local btnOuter = Instance.new("TextButton", Frame)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1
    btnOuter.BorderSizePixel = 0
    btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -36, 0, 50)
    btnOuter.Position = UDim2.new(0, 18, 0, ypos)
    btnOuter.Text = ""
    btnOuter.ClipsDescendants = true

    -- background panel (gradient)
    local bg = Instance.new("Frame", btnOuter)
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = c1
    bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0, 12)

    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(0.6, c2),
        ColorSequenceKeypoint.new(1, c1)
    }
    grad.Rotation = 45

    -- inner panel for depth (darker, less white)
    local inner = Instance.new("Frame", bg)
    inner.Name = "Inner"
    inner.Size = UDim2.new(1, -8, 1, -10)
    inner.Position = UDim2.new(0, 4, 0, 5)
    inner.BackgroundColor3 = Color3.fromRGB(12,14,18)
    inner.BorderSizePixel = 0
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0, 10)

    local innerStroke = Instance.new("UIStroke", inner)
    innerStroke.Color = Color3.fromRGB(28,36,46)
    innerStroke.Thickness = 1
    innerStroke.Transparency = 0.2

    -- subtle shine overlay (much less white, bluish)
    local shine = Instance.new("Frame", inner)
    shine.Size = UDim2.new(1, 0, 0.28, 0)
    shine.Position = UDim2.new(0, 0, 0, 0)
    shine.BackgroundTransparency = 0.9
    shine.BackgroundColor3 = Color3.fromRGB(30,45,60)
    local shineCorner = Instance.new("UICorner", shine); shineCorner.CornerRadius = UDim.new(0, 10)

    -- glow (outer)
    local glow = Instance.new("Frame", bg)
    glow.Size = UDim2.new(1, 14, 1, 14)
    glow.Position = UDim2.new(-0.02, 0, -0.02, 0)
    glow.BackgroundColor3 = c2
    glow.BackgroundTransparency = 0.92
    local glowCorner = Instance.new("UICorner", glow); glowCorner.CornerRadius = UDim.new(0, 14)

    -- text
    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, -4)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.Text = txt
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(170,195,215) -- less white
    label.TextXAlignment = Enum.TextXAlignment.Left

    -- small right accent (toggle indicator)
    local indicator = Instance.new("Frame", inner)
    indicator.Size = UDim2.new(0, 50, 0, 26)
    indicator.Position = UDim2.new(1, -64, 0.5, -13)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14)
    indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,10)
    local indStroke = Instance.new("UIStroke", indicator); indStroke.Color = Color3.fromRGB(24,30,36); indStroke.Thickness = 1

    local indBar = Instance.new("Frame", indicator)
    indBar.Size = UDim2.new(0.38, 0, 0.5, 0)
    indBar.Position = UDim2.new(0.06, 0, 0.25, 0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    indBar.BorderSizePixel = 0
    local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0, 8)

    -- hover animations
    local hoverTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local leaveTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    btnOuter.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(grad, hoverTweenInfo, {Rotation = 135}):Play()
            TweenService:Create(glow, hoverTweenInfo, {BackgroundTransparency = 0.84}):Play()
            TweenService:Create(inner, hoverTweenInfo, {Size = UDim2.new(1, -4, 1, -6), Position = UDim2.new(0, 2, 0, 3)}):Play()
            TweenService:Create(label, hoverTweenInfo, {TextColor3 = Color3.fromRGB(220,235,245)}):Play()
            TweenService:Create(indBar, hoverTweenInfo, {Size = UDim2.new(0.66,0,0.66,0), Position = UDim2.new(0.16,0,0.17,0)}):Play()
        end)
    end)
    btnOuter.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(grad, leaveTweenInfo, {Rotation = 45}):Play()
            TweenService:Create(glow, leaveTweenInfo, {BackgroundTransparency = 0.92}):Play()
            TweenService:Create(inner, leaveTweenInfo, {Size = UDim2.new(1, -8, 1, -10), Position = UDim2.new(0, 4, 0, 5)}):Play()
            TweenService:Create(label, leaveTweenInfo, {TextColor3 = Color3.fromRGB(170,195,215)}):Play()
            TweenService:Create(indBar, leaveTweenInfo, {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
        end)
    end)

    -- click flash
    btnOuter.MouseButton1Down:Connect(function()
        pcall(function()
            TweenService:Create(inner, TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(0,6,0,6)}):Play()
        end)
    end)
    btnOuter.MouseButton1Up:Connect(function()
        pcall(function()
            TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(0,4,0,5)}):Play()
        end)
    end)

    return btnOuter, indBar
end

-- Create menu buttons with gradient color pairs
local PlayerBtn, PlayerIndicator = createFuturisticButton("Ativar ESP Jogadores", 70, Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101))
local CompBtn, CompIndicator   = createFuturisticButton("Ativar Destacar Computadores", 136, Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255))
local DownTimerBtn, DownIndicator = createFuturisticButton("Ativar Contador de Down", 202, Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90))
local GraySkinBtn, GraySkinIndicator = createFuturisticButton("Ativar Skin Cinza", 268, Color3.fromRGB(80,80,90), Color3.fromRGB(130,130,140))

-- Ensure Frame has enough height for the gray button
Frame.Size = UDim2.new(0, gWidth, 0, 340)

-- close button (top-right)
local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 18
CloseBtn.Size = UDim2.new(0,36,0,36)
CloseBtn.Position = UDim2.new(1,-44,0,8)
CloseBtn.BackgroundTransparency = 1
CloseBtn.BorderSizePixel = 0
CloseBtn.TextColor3 = Color3.fromRGB(140,160,180)
CloseBtn.AutoButtonColor = false
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(240,110,110)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(140,160,180)}):Play() end)
CloseBtn.MouseButton1Click:Connect(function()
    Frame.Visible = false
    MenuOpen = false
end)

-- draggable behavior
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local MenuOpen = false
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.K then
        MenuOpen = not MenuOpen
        Frame.Visible = MenuOpen
    end
end)

------------- ESP (beast red, survivors green) --------------
local PlayerESPActive = false
local playerHighlights, NameTags = {}, {}

local function isBeast(player)
    return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function HighlightColorForPlayer(player)
    if isBeast(player) then
        return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) -- VERMELHO (beast)
    end
    -- SOBREVIVENTES: VERDE
    return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)   -- VERDE
end

local function AddPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if playerHighlights[player] then playerHighlights[player]:Destroy() playerHighlights[player]=nil end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"
    h.Adornee = player.Character
    h.Parent = CoreGui
    h.FillColor = fill
    h.OutlineColor = outline
    h.FillTransparency = 0.19
    h.OutlineTransparency = 0.08
    playerHighlights[player] = h
end
local function RemovePlayerHighlight(player)
    if playerHighlights[player] then playerHighlights[player]:Destroy() playerHighlights[player]=nil end
end

local function AddNameTag(player)
    if player==LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then NameTags[player]:Destroy() NameTags[player]=nil end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "[FTFName]"
    billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0, 110, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.18, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = CoreGui
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = player.DisplayName or player.Name
    text.TextColor3 = Color3.fromRGB(190,210,230)
    text.TextStrokeColor3 = Color3.fromRGB(8,10,14)
    text.TextStrokeTransparency = 0.6
    text.Font = Enum.Font.GothamSemibold
    text.BackgroundTransparency = 1
    text.TextSize = 13
    NameTags[player]=billboard
end
local function RemoveNameTag(player)
    if NameTags[player] then NameTags[player]:Destroy() NameTags[player]=nil end
end

local function RefreshPlayerESP()
    for _, p in pairs(Players:GetPlayers()) do
        if PlayerESPActive then AddPlayerHighlight(p) AddNameTag(p)
        else RemovePlayerHighlight(p) RemoveNameTag(p) end
    end
end

RunService.RenderStepped:Connect(function()
    if PlayerESPActive then
        for _,player in pairs(Players:GetPlayers()) do
            if playerHighlights[player] then
                local fill, outline = HighlightColorForPlayer(player)
                playerHighlights[player].FillColor = fill
                playerHighlights[player].OutlineColor = outline
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        wait(0.08)
        if PlayerESPActive then AddPlayerHighlight(p) AddNameTag(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    RemovePlayerHighlight(p)
    RemoveNameTag(p)
end)
for _, p in pairs(Players:GetPlayers()) do
    if p.Character then p.Character:WaitForChild("Head",1) AddNameTag(p) end
    p.CharacterAdded:Connect(function()
        wait(0.08)
        if PlayerESPActive then AddPlayerHighlight(p) AddNameTag(p) end
    end)
end

------------------- PC highlight (screen color) -------------------
local ComputerESPActive = false
local compHighlights = {}

local function isComputerModel(model)
    return (model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc")))
end

local function getScreenPart(model)
    for _, name in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        if model:FindFirstChild(name) and model[name]:IsA("BasePart") then
            return model[name]
        end
    end
    -- fallback: maior part
    local biggest
    for _,p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") and (not biggest or p.Size.Magnitude > biggest.Size.Magnitude) then
            biggest = p
        end
    end
    return biggest
end

local function getPcColor(model)
    local screen = getScreenPart(model)
    if not screen then return Color3.fromRGB(77,164,255) end -- fallback azul
    return screen.Color
end

local function AddComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then compHighlights[model]:Destroy() compHighlights[model]=nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"
    h.Parent = CoreGui
    h.Adornee = model
    h.FillColor = getPcColor(model)
    h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.14
    h.OutlineTransparency = 0.08
    compHighlights[model]=h
end

local function RemoveComputerHighlight(model)
    if compHighlights[model] then compHighlights[model]:Destroy() compHighlights[model]=nil end
end

local function RefreshComputerESP()
    for _, v in pairs(compHighlights) do v:Destroy() end
    compHighlights = {}
    if not ComputerESPActive then return end
    for _, d in pairs(Workspace:GetDescendants()) do
        if isComputerModel(d) then AddComputerHighlight(d) end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if ComputerESPActive and isComputerModel(obj) then wait(0.1) AddComputerHighlight(obj) end
end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)

RunService.RenderStepped:Connect(function()
    if ComputerESPActive then
        for model,h in pairs(compHighlights) do
            if model and model.Parent and h and h.Parent then
                h.FillColor = getPcColor(model)
            end
        end
    end
end)

-- ======= Ragdoll down counter (28s) =======
local DownTimerActive = false
local DOWN_TIME = 28 -- segundos até levantar
local ragdollBillboards = {}
local ragdollConns = {}
local bottomUI = {}

local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "[FTF_RagdollTimer]"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 140, 0, 44)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = CoreGui

    local bg = Instance.new("Frame", billboard)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(24,24,28)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.ClipsDescendants = true
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", bg); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.LineJoinMode = Enum.LineJoinMode.Round; stroke.Color = Color3.fromRGB(40,40,45); stroke.Thickness = 1

    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,24))
    }
    grad.Rotation = 90

    local txt = Instance.new("TextLabel", bg)
    txt.Size = UDim2.new(1, -16, 1, -16)
    txt.Position = UDim2.new(0, 8, 0, 6)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 18
    txt.TextColor3 = Color3.fromRGB(220,220,230)
    txt.TextStrokeTransparency = 0.6
    txt.Text = tostring(DOWN_TIME) .. "s"
    txt.TextXAlignment = Enum.TextXAlignment.Center
    txt.TextYAlignment = Enum.TextYAlignment.Center

    local pbg = Instance.new("Frame", bg)
    pbg.Size = UDim2.new(0.92, 0, 0, 6)
    pbg.Position = UDim2.new(0.04, 0, 1, -10)
    pbg.AnchorPoint = Vector2.new(0, 1)
    pbg.BackgroundColor3 = Color3.fromRGB(40,40,44)
    pbg.BorderSizePixel = 0
    local pcorner = Instance.new("UICorner", pbg); pcorner.CornerRadius = UDim.new(0, 4)

    local pfill = Instance.new("Frame", pbg)
    pfill.Size = UDim2.new(1, 0, 1, 0)
    pfill.Position = UDim2.new(0, 0, 0, 0)
    pfill.BackgroundColor3 = Color3.fromRGB(90,180,255)
    pfill.BorderSizePixel = 0
    local pfillCorner = Instance.new("UICorner", pfill); pfillCorner.CornerRadius = UDim.new(0, 4)

    local info = { gui = billboard, label = txt, endTime = tick() + DOWN_TIME, progress = pfill, bg = bg, stroke = stroke }
    ragdollBillboards[player] = info
    return info
end

local function removeRagdollBillboard(player)
    local info = ragdollBillboards[player]
    if info then
        if info.gui and info.gui.Parent then info.gui:Destroy() end
        ragdollBillboards[player] = nil
    end
end

local function updateBottomRightFor(player, endTime)
    if player == LocalPlayer then return end
    if bottomUI[player] == nil then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FTF_Ragdoll_UI"
        screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 50)
        frame.BackgroundTransparency = 1
        frame.Parent = screenGui

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PlayerNameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Text = player.Name
        nameLabel.Parent = frame

        local timerLabel = Instance.new("TextLabel")
        timerLabel.Name = "TimerLabel"
        timerLabel.Size = UDim2.new(1, 0, 0.5, 0)
        timerLabel.Position = UDim2.new(0, 0, 0.5, 0)
        timerLabel.BackgroundTransparency = 1
        timerLabel.TextScaled = true
        timerLabel.TextColor3 = Color3.new(1, 1, 1)
        timerLabel.TextStrokeTransparency = 0
        timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        timerLabel.Text = tostring(DOWN_TIME)
        timerLabel.Parent = frame

        local yOffset = #Players:GetPlayers()
        frame.Position = UDim2.new(1, -220, 1, -60 - (yOffset * 0))

        bottomUI[player] = { screenGui = screenGui, frame = frame, timerLabel = timerLabel }
    end

    bottomUI[player].timerLabel.Text = string.format("%.2f", math.max(0, endTime - tick()))
end

local function removeBottomUI(player)
    if bottomUI[player] then
        if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end
        bottomUI[player] = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not DownTimerActive then return end
    local now = tick()
    for player, info in pairs(ragdollBillboards) do
        if not player or not player.Parent or not info or not info.gui then
            removeRagdollBillboard(player)
            removeBottomUI(player)
        else
            local remaining = info.endTime - now
            if remaining <= 0 then
                removeRagdollBillboard(player)
                removeBottomUI(player)
            else
                if info.label and info.label.Parent then
                    info.label.Text = string.format("%.2f", remaining)
                    if remaining <= 5 then
                        info.label.TextColor3 = Color3.fromRGB(255,90,90)
                    else
                        info.label.TextColor3 = Color3.fromRGB(220,220,230)
                    end
                end
                if info.progress and info.progress.Parent then
                    local frac = math.clamp(remaining / DOWN_TIME, 0, 1)
                    info.progress.Size = UDim2.new(frac, 0, 1, 0)
                    if frac > 0.5 then
                        info.progress.BackgroundColor3 = Color3.fromRGB(90,180,255)
                    elseif frac > 0.15 then
                        info.progress.BackgroundColor3 = Color3.fromRGB(240,200,60)
                    else
                        info.progress.BackgroundColor3 = Color3.fromRGB(255,90,90)
                    end
                end
                if bottomUI[player] then
                    bottomUI[player].timerLabel.Text = string.format("%.2f", remaining)
                end
            end
        end
    end
end)

local function onRagdollValueChanged(player, value)
    if not DownTimerActive then
        if ragdollBillboards[player] then removeRagdollBillboard(player) end
        if bottomUI[player] then removeBottomUI(player) end
        return
    end

    if value then
        local info = createRagdollBillboardFor(player)
        if info then
            info.endTime = tick() + DOWN_TIME
            updateBottomRightFor(player, info.endTime)
        end
    else
        removeRagdollBillboard(player)
        removeBottomUI(player)
    end
end

local ragdollConnects = {}
local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then
        pcall(function() ragdollConnects[player]:Disconnect() end)
        ragdollConnects[player] = nil
    end

    spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 10) end)
        if not ok or not tempStats then return end
        local ok2, ragdoll = pcall(function() return tempStats:WaitForChild("Ragdoll", 10) end)
        if not ok2 or not ragdoll then return end

        pcall(function() onRagdollValueChanged(player, ragdoll.Value) end)

        local conn = ragdoll.Changed:Connect(function()
            pcall(function() onRagdollValueChanged(player, ragdoll.Value) end)
        end)
        ragdollConnects[player] = conn
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        wait(0.06)
        if ragdollBillboards[p] then
            removeRagdollBillboard(p)
            createRagdollBillboardFor(p)
        end
    end)
    attachRagdollListenerToPlayer(p)
end)
for _, p in pairs(Players:GetPlayers()) do
    attachRagdollListenerToPlayer(p)
    p.CharacterAdded:Connect(function()
        wait(0.06)
        if ragdollBillboards[p] then
            removeRagdollBillboard(p)
            createRagdollBillboardFor(p)
        end
    end)
end

-- ======= Gray skin (based on your example) with backups to restore =======
local GraySkinActive = false

-- storage tables
local skinBackup = {}        -- player -> { parts = { [part]= {Color, Material, TextureID} }, accessories = { [acc] = {Color, Material, TextureID}}, clothes = { clones } }
local grayConns = {}         -- player -> CharacterAdded connection

local GRAY_COLOR = Color3.fromRGB(150,150,150)
local GRAY_MATERIAL = Enum.Material.SmoothPlastic

local function ensureBackupForPlayer(player)
    if not skinBackup[player] then
        skinBackup[player] = { parts = {}, accessories = {}, clothes = {} }
    end
    return skinBackup[player]
end

local function GreyOutfitsApply(player)
    if not player or not player.Character then return end
    if player == LocalPlayer then return end -- skip local player by default
    local char = player.Character
    local backup = ensureBackupForPlayer(player)

    for _, i in ipairs(char:GetChildren()) do
        if i:IsA("BasePart") or i:IsA("MeshPart") then
            -- save original
            if backup.parts[i] == nil then
                backup.parts[i] = {
                    Color = (pcall(function() return i.Color end) and i.Color) or nil,
                    Material = (pcall(function() return i.Material end) and i.Material) or nil,
                    TextureID = (i:IsA("MeshPart") and (pcall(function() return i.TextureID end) and i.TextureID) or nil)
                }
            end
            -- apply gray
            pcall(function()
                i.Color = GRAY_COLOR
                i.Material = GRAY_MATERIAL
                if i:IsA("MeshPart") then
                    -- clear texture safely
                    pcall(function() i.TextureID = "" end)
                end
            end)
        elseif i:IsA("Accessory") then
            local handle = i:FindFirstChild("Handle")
            if handle then
                if backup.accessories[i] == nil then
                    backup.accessories[i] = {
                        Color = (pcall(function() return handle.Color end) and handle.Color) or nil,
                        Material = (pcall(function() return handle.Material end) and handle.Material) or nil,
                        -- try common texture fields
                        Texture = (pcall(function() if handle:IsA("MeshPart") then return handle.TextureID elseif handle:FindFirstChild("Mesh") then return handle.Mesh.TextureId elseif handle:FindFirstChild("SpecialMesh") then return handle.SpecialMesh.TextureId end end) and (
                            (handle:IsA("MeshPart") and handle.TextureID) or
                            (handle:FindFirstChild("Mesh") and handle.Mesh.TextureId) or
                            (handle:FindFirstChild("SpecialMesh") and handle.SpecialMesh.TextureId)
                        )) or nil
                    }
                end
                pcall(function()
                    handle.Color = GRAY_COLOR
                    handle.Material = GRAY_MATERIAL
                    if handle:IsA("MeshPart") then
                        pcall(function() handle.TextureID = "" end)
                    else
                        local mesh = handle:FindFirstChild("Mesh")
                        if mesh and mesh:IsA("Mesh") then
                            pcall(function() mesh.TextureId = "" end)
                        end
                        local sm = handle:FindFirstChild("SpecialMesh")
                        if sm and sm:IsA("SpecialMesh") then
                            pcall(function() sm.TextureId = "" end)
                        end
                    end
                end)
            end
        elseif i:IsA("Pants") or i:IsA("Shirt") or i:IsA("ShirtGraphic") then
            -- clone to backup so we can restore later
            if backup.clothes then
                local ok, clone = pcall(function() return i:Clone() end)
                if ok and clone then
                    table.insert(backup.clothes, clone)
                end
            end
            pcall(function() i:Destroy() end)
        end
    end
end

local function GreyOutfitsRestore(player)
    if not player then return end
    local backup = skinBackup[player]
    if not backup then return end

    -- restore parts: iterate the saved parts map and try restore if part still exists
    for part, props in pairs(backup.parts) do
        if part and part.Parent then
            pcall(function()
                if props.Color then part.Color = props.Color end
                if props.Material then part.Material = props.Material end
                if props.TextureID and part:IsA("MeshPart") then
                    part.TextureID = props.TextureID
                end
            end)
        end
    end

    -- restore accessories
    for acc, ap in pairs(backup.accessories) do
        if acc and acc.Parent then
            local handle = acc:FindFirstChild("Handle")
            if handle then
                pcall(function()
                    if ap.Color then handle.Color = ap.Color end
                    if ap.Material then handle.Material = ap.Material end
                    if ap.Texture and handle:IsA("MeshPart") then
                        handle.TextureID = ap.Texture
                    else
                        local mesh = handle:FindFirstChild("Mesh")
                        if mesh and ap.Texture then mesh.TextureId = ap.Texture end
                        local sm = handle:FindFirstChild("SpecialMesh")
                        if sm and ap.Texture then sm.TextureId = ap.Texture end
                    end
                end)
            end
        end
    end

    -- restore clothes clones (reparent them to character)
    if backup.clothes and player.Character then
        for _, clone in ipairs(backup.clothes) do
            if clone and not clone.Parent then
                pcall(function() clone.Parent = player.Character end)
            end
        end
    end

    -- clear backup
    skinBackup[player] = nil
end

local function enableGraySkin()
    GraySkinActive = true
    -- apply to all current players
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            GreyOutfitsApply(p)
            -- connect to reapply on respawn
            if not grayConns[p] then
                grayConns[p] = p.CharacterAdded:Connect(function(char)
                    wait(0.06)
                    if GraySkinActive then
                        GreyOutfitsApply(p)
                    end
                end)
            end
        end
    end

    -- ensure new players are handled
    if not grayConns._playerAddedConn then
        grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p)
            if p ~= LocalPlayer and GraySkinActive then
                -- apply when their character exists
                if p.Character then GreyOutfitsApply(p) end
                if not grayConns[p] then
                    grayConns[p] = p.CharacterAdded:Connect(function()
                        wait(0.06)
                        if GraySkinActive then GreyOutfitsApply(p) end
                    end)
                end
            end
        end)
    end
end

local function disableGraySkin()
    GraySkinActive = false
    -- restore all players
    for p, _ in pairs(skinBackup) do
        pcall(function() GreyOutfitsRestore(p) end)
    end
    skinBackup = {}

    -- disconnect per-player connections
    for p, conn in pairs(grayConns) do
        if p == "_playerAddedConn" then
            pcall(function() conn:Disconnect() end)
        else
            pcall(function() conn:Disconnect() end)
        end
        grayConns[p] = nil
    end
    grayConns = {}
end

-- cleanup on player leaving
Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then
        GreyOutfitsRestore(p)
        skinBackup[p] = nil
    end
    if grayConns[p] then
        pcall(function() grayConns[p]:Disconnect() end)
        grayConns[p] = nil
    end
end)

-- ======= Button behaviors (visual feedback) =======
PlayerBtn.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive
    RefreshPlayerESP()
    pcall(function()
        if PlayerESPActive then
            PlayerIndicator.BackgroundColor3 = Color3.fromRGB(52,215,101)
            TweenService:Create(PlayerIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
        else
            PlayerIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
            TweenService:Create(PlayerIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
        end
    end)
end)

CompBtn.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive
    RefreshComputerESP()
    pcall(function()
        if ComputerESPActive then
            CompIndicator.BackgroundColor3 = Color3.fromRGB(54,144,255)
            TweenService:Create(CompIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
        else
            CompIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
            TweenService:Create(CompIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
        end
    end)
end)

DownTimerBtn.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    pcall(function()
        if DownTimerActive then
            DownIndicator.BackgroundColor3 = Color3.fromRGB(255,200,90)
            TweenService:Create(DownIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
        else
            DownIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
            TweenService:Create(DownIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
        end
    end)

    if not DownTimerActive then
        for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
        for p,_ in pairs(bottomUI) do removeBottomUI(p) end
    else
        for _, p in pairs(Players:GetPlayers()) do
            local ok, tempStats = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and tempStats then
                local ragdoll = tempStats:FindFirstChild("Ragdoll")
                if ragdoll and ragdoll.Value then
                    onRagdollValueChanged(p, true)
                end
            end
        end
    end
end)

GraySkinBtn.MouseButton1Click:Connect(function()
    GraySkinActive = not GraySkinActive
    pcall(function()
        if GraySkinActive then
            GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(200,200,200)
            TweenService:Create(GraySkinIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
            enableGraySkin()
        else
            GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
            TweenService:Create(GraySkinIndicator, TweenInfo.new(0.2), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
            disableGraySkin()
        end
    end)
end)

-- Safety: restore on script unload (if possible)
local function cleanupAll()
    disableGraySkin()
    for _, p in pairs(Players:GetPlayers()) do
        if playerHighlights[p] then RemovePlayerHighlight(p) end
        if NameTags[p] then RemoveNameTag(p) end
    end
end

-- End of script
