-- FTF ESP Script — menu moved to bottom, Door ESP fixed, Teleport category added
-- Changes:
--  - Menu moved to bottom center, larger but not stretched
--  - Door ESP fixed: better primary part detection, SelectionBox DepthMode AlwaysOnTop, thicker line
--  - New category "Teleporte" with dynamic list of players and teleport buttons
--  - Search still works and filters options per category (including teleport targets)
--  - All previous features preserved (Player/Computer/Freeze Pods ESP, Textures, Snow, Down timer, etc.)

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- UI root
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
-- cleanup old
for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- helper storage
local buttonLabelMap = {}
local buttonCategory = {}
local categoryButtons = {}
-- order: Visuais, Textures, Timers, Teleporte
local categoryNameOrder = {"Visuais","Textures","Timers","Teleporte"}
local uiButtonsByCategory = { Visuais = {}, Textures = {}, Timers = {}, Teleporte = {} }

-- ---------- Startup notice ----------
local function createStartupNotice()
    local noticeGui = Instance.new("ScreenGui")
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false
    noticeGui.Parent = GUI
    local frame = Instance.new("Frame", noticeGui)
    frame.Size = UDim2.new(0, 520, 0, 72)
    frame.Position = UDim2.new(0.5, -260, 0.92, 6)
    frame.BackgroundTransparency = 1
    local panel = Instance.new("Frame", frame)
    panel.Size = UDim2.new(1,0,1,0); panel.BackgroundColor3 = Color3.fromRGB(10,14,20); panel.BackgroundTransparency = 0.04
    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 16)
    local iconBg = Instance.new("Frame", panel); iconBg.Size = UDim2.new(0,40,0,40); iconBg.Position = UDim2.new(0,14,0.5,-20); iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26)
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0,12)
    local iconLabel = Instance.new("TextLabel", iconBg); iconLabel.Size = UDim2.new(1,-6,1,-6); iconLabel.Position = UDim2.new(0,3,0,3)
    iconLabel.BackgroundTransparency = 1; iconLabel.Font = Enum.Font.FredokaOne; iconLabel.Text = "K"; iconLabel.TextColor3 = Color3.fromRGB(100,170,220); iconLabel.TextSize = 22
    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -140, 1, -12); txt.Position = UDim2.new(0,86,0,6); txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold; txt.TextSize = 15; txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'; txt.TextXAlignment = Enum.TextXAlignment.Left; txt.TextWrapped = true
    TweenService:Create(panel, TweenInfo.new(0.45), {BackgroundTransparency = 0.0}):Play()
    task.delay(4.5, function() if noticeGui and noticeGui.Parent then noticeGui:Destroy() end end)
end
createStartupNotice()

-- ---------- Main menu (bottom center) ----------
local gWidth, gHeight = 980, 360
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.BackgroundColor3 = Color3.fromRGB(10,12,16)
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
-- place near bottom center (above default bottom UI)
Frame.Position = UDim2.new(0.5, -gWidth/2, 1, -gHeight - 24)
Frame.Active = true
Frame.Visible = false
Frame.BorderSizePixel = 0
local aCorner = Instance.new("UICorner", Frame); aCorner.CornerRadius = UDim.new(0,16)
local stroke = Instance.new("UIStroke", Frame); stroke.Color = Color3.fromRGB(40,50,64); stroke.Thickness = 1; stroke.Transparency = 0.2

-- Header: title + search
local Header = Instance.new("Frame", Frame); Header.Size = UDim2.new(1,0,0,72); Header.Position = UDim2.new(0,0,0,0); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Text = "FTF - David's ESP"; Title.Font = Enum.Font.FredokaOne; Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(200,220,240); Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 18, 0, 18); Title.Size = UDim2.new(0.5,0,0,36); Title.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", Header)
SearchBox.PlaceholderText = "Pesquisar opções..."
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0, 320, 0, 34)
SearchBox.Position = UDim2.new(1, -356, 0, 18)
SearchBox.BackgroundColor3 = Color3.fromRGB(14,16,20); SearchBox.TextColor3 = Color3.fromRGB(200,220,240); SearchBox.TextSize = 15
local searchCorner = Instance.new("UICorner", SearchBox); searchCorner.CornerRadius = UDim.new(0,10)
local searchStroke = Instance.new("UIStroke", SearchBox); searchStroke.Color = Color3.fromRGB(60,80,110); searchStroke.Thickness = 1; searchStroke.Transparency = 0.6

-- Left column: categories
local LeftCol = Instance.new("Frame", Frame)
LeftCol.Size = UDim2.new(0, 220, 1, -88)
LeftCol.Position = UDim2.new(0, 18, 0, 72 + 6)
LeftCol.BackgroundTransparency = 1
local CatLayout = Instance.new("UIListLayout", LeftCol); CatLayout.SortOrder = Enum.SortOrder.LayoutOrder; CatLayout.Padding = UDim.new(0,12)

local function createCategoryButton(text)
    local btn = Instance.new("TextButton", LeftCol)
    btn.Size = UDim2.new(1, 0, 0, 56)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(180,200,220)
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = Color3.fromRGB(12,14,18)
    local cr = Instance.new("UICorner", btn); cr.CornerRadius = UDim.new(0,12)
    local strokeLine = Instance.new("UIStroke", btn); strokeLine.Color = Color3.fromRGB(36,46,60); strokeLine.Thickness = 1; strokeLine.Transparency = 0.4
    return btn
end

for i,cat in ipairs(categoryNameOrder) do
    local btn = createCategoryButton(cat)
    btn.LayoutOrder = i
    categoryButtons[cat] = btn
end

-- Content area
local ContentArea = Instance.new("Frame", Frame)
ContentArea.Size = UDim2.new(1, -260, 1, -88)
ContentArea.Position = UDim2.new(0, 248, 0, 72 + 6)
ContentArea.BackgroundTransparency = 1

local OptionsScroll = Instance.new("ScrollingFrame", ContentArea)
OptionsScroll.Size = UDim2.new(1, -12, 1, 0)
OptionsScroll.Position = UDim2.new(0, 6, 0, 0)
OptionsScroll.BackgroundTransparency = 1
OptionsScroll.CanvasSize = UDim2.new(0,0,0,0)
OptionsScroll.ScrollBarThickness = 8
OptionsScroll.BorderSizePixel = 0
local optLayout = Instance.new("UIListLayout", OptionsScroll); optLayout.SortOrder = Enum.SortOrder.LayoutOrder; optLayout.Padding = UDim.new(0,10)

-- Futuristic option button creator
local function createFuturisticButtonNamed(txt, c1, c2, parent)
    parent = parent or OptionsScroll
    local btnOuter = Instance.new("TextButton", parent)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1
    btnOuter.BorderSizePixel = 0
    btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -12, 0, 56)
    btnOuter.Text = ""
    btnOuter.ClipsDescendants = true
    btnOuter.LayoutOrder = (#parent:GetChildren()) + 1

    local bg = Instance.new("Frame", btnOuter); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,10)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation=45

    local inner = Instance.new("Frame", bg); inner.Name="Inner"; inner.Size=UDim2.new(1,-8,1,-8); inner.Position=UDim2.new(0,4,0,4)
    inner.BackgroundColor3 = Color3.fromRGB(8,10,12)
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local innerStroke = Instance.new("UIStroke", inner); innerStroke.Color = Color3.fromRGB(24,34,46); innerStroke.Thickness=1; innerStroke.Transparency=0.3

    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, 0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = txt
    label.TextSize = 16; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,66,0,26); indicator.Position = UDim2.new(1,-92,0.5,-13)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14); indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220); local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0,6)

    btnOuter.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(grad, TweenInfo.new(0.18), {Rotation = 135}):Play()
            TweenService:Create(indBar, TweenInfo.new(0.18), {Size = UDim2.new(0.66,0,0.86,0), Position = UDim2.new(0.12,0,0.07,0)}):Play()
            TweenService:Create(label, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(230,245,255)}):Play()
        end)
    end)
    btnOuter.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(grad, TweenInfo.new(0.18), {Rotation = 45}):Play()
            TweenService:Create(indBar, TweenInfo.new(0.18), {Size = UDim2.new(0.38,0,0.6,0), Position = UDim2.new(0.06,0,0.2,0)}):Play()
            TweenService:Create(label, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(180,200,220)}):Play()
        end)
    end)

    -- register label (search)
    buttonLabelMap[btnOuter] = label

    return btnOuter, indBar, label
end

-- Create base option buttons and assign categories
-- Visuais
local PlayerBtn = createFuturisticButtonNamed("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101)); PlayerBtn = PlayerBtn
buttonCategory[PlayerBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], PlayerBtn)
local CompBtn = createFuturisticButtonNamed("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255)); CompBtn = CompBtn
buttonCategory[CompBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], CompBtn)
local DoorBtn = createFuturisticButtonNamed("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100)); DoorBtn = DoorBtn
buttonCategory[DoorBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], DoorBtn)
local FreezeBtn = createFuturisticButtonNamed("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80)); FreezeBtn = FreezeBtn
buttonCategory[FreezeBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], FreezeBtn)

-- Textures
local RemoveTexBtn = createFuturisticButtonNamed("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140)); RemoveTexBtn = RemoveTexBtn
buttonCategory[RemoveTexBtn] = "Textures"; table.insert(uiButtonsByCategory["Textures"], RemoveTexBtn)
local TextureBtn = createFuturisticButtonNamed("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245)); TextureBtn = TextureBtn
buttonCategory[TextureBtn] = "Textures"; table.insert(uiButtonsByCategory["Textures"], TextureBtn)
local SnowBtn = createFuturisticButtonNamed("Snow texture", Color3.fromRGB(235,245,255), Color3.fromRGB(245,250,255)); SnowBtn = SnowBtn
buttonCategory[SnowBtn] = "Textures"; table.insert(uiButtonsByCategory["Textures"], SnowBtn)

-- Timers
local DownTimerBtn = createFuturisticButtonNamed("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90)); DownTimerBtn = DownTimerBtn
buttonCategory[DownTimerBtn] = "Timers"; table.insert(uiButtonsByCategory["Timers"], DownTimerBtn)

-- Teleporte: we'll create dynamic buttons per player; create a header placeholder
local TeleportHeaderBtn = createFuturisticButtonNamed("Teleport to player (select from list)", Color3.fromRGB(120,120,140), Color3.fromRGB(160,160,180)); TeleportHeaderBtn = TeleportHeaderBtn
buttonCategory[TeleportHeaderBtn] = "Teleporte"; table.insert(uiButtonsByCategory["Teleporte"], TeleportHeaderBtn)

-- track teleport buttons (so we can remove/rebuild)
local teleportButtons = {} -- player -> button

-- helper to create a teleport button for a player
local function createTeleportButtonFor(player)
    if not player or not player:IsA("Player") then return end
    if player == LocalPlayer then return end -- optional: skip teleport to self
    -- remove existing if exists
    if teleportButtons[player] and teleportButtons[player].Parent then teleportButtons[player]:Destroy() end
    local labelText = "Teleport to " .. (player.DisplayName or player.Name)
    local btn = createFuturisticButtonNamed(labelText, Color3.fromRGB(100,110,140), Color3.fromRGB(140,150,180))
    buttonCategory[btn] = "Teleporte"
    table.insert(uiButtonsByCategory["Teleporte"], btn)
    teleportButtons[player] = btn
    -- click handler: teleport local player to target
    btn.MouseButton1Click:Connect(function()
        local function safeTeleport()
            local char = LocalPlayer.Character
            local targetChar = player.Character
            if not char or not targetChar then return end
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
            if not hrp or not thrp then return end
            -- try teleporting safely (set CFrame slightly above target)
            pcall(function()
                hrp.CFrame = thrp.CFrame + Vector3.new(0, 4, 0)
            end)
        end
        safeTeleport()
    end)
end

-- rebuild teleport list (clear old teleport buttons and recreate)
local function rebuildTeleportButtons()
    -- remove previous teleport buttons from uiButtonsByCategory and UI
    for p,btn in pairs(teleportButtons) do
        if btn and btn.Parent then
            pcall(function() btn:Destroy() end)
        end
        teleportButtons[p] = nil
    end
    -- ensure TeleportHeaderBtn stays and is first under Teleporte category
    -- create buttons for current players (excluding LocalPlayer)
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            createTeleportButtonFor(pl)
        end
    end
    -- update UI canvas size
    task.delay(0.01, function() OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 12) end)
end

-- update teleport list on players join/leave / name change
Players.PlayerAdded:Connect(function(pl)
    task.delay(0.06, function() if Frame then rebuildTeleportButtons() end end)
end)
Players.PlayerRemoving:Connect(function(pl)
    task.delay(0.06, function() if Frame then rebuildTeleportButtons() end end)
end)
Players.PlayerAdded:Connect(function() end)

-- initial build
rebuildTeleportButtons()

-- OptionsScroll canvas adaptation
optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 12)
end)

-- Close and draggable
local CloseBtn = Instance.new("TextButton", Frame); CloseBtn.Size = UDim2.new(0,48,0,48); CloseBtn.Position = UDim2.new(1,-64,0,12)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200,220,240); CloseBtn.AutoButtonColor = false
CloseBtn.MouseButton1Click:Connect(function() Frame.Visible = false end)
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local MenuOpen = false
UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == Enum.KeyCode.K then MenuOpen = not MenuOpen; Frame.Visible = MenuOpen end end)

-- active category logic
local activeCategory = "Visuais"
local function setActiveCategory(cat)
    activeCategory = cat
    for name,btn in pairs(categoryButtons) do
        if name == cat then
            btn.BackgroundColor3 = Color3.fromRGB(22,32,44); btn.TextColor3 = Color3.fromRGB(250,250,250)
        else
            btn.BackgroundColor3 = Color3.fromRGB(12,14,18); btn.TextColor3 = Color3.fromRGB(180,200,220)
        end
    end
    local query = string.lower(tostring(SearchBox.Text or ""))
    for btn,label in pairs(buttonLabelMap) do
        local catBtn = buttonCategory[btn] or "Visuais"
        local visible = (catBtn == activeCategory)
        if visible and query ~= "" then
            local labelText = string.lower(label.Text or "")
            if not labelText:find(query) then visible = false end
        end
        btn.Visible = visible
    end
    task.delay(0.01, function() OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 12) end)
end
for name,btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function() setActiveCategory(name) end)
end
setActiveCategory(activeCategory)

-- Search handling
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(tostring(SearchBox.Text or ""))
    for btn,label in pairs(buttonLabelMap) do
        local catBtn = buttonCategory[btn] or "Visuais"
        local visible = (catBtn == activeCategory)
        if visible and query ~= "" then
            local labelText = string.lower(label.Text or "")
            if not labelText:find(query) then visible = false end
        end
        btn.Visible = visible
    end
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 12)
end)

-- ========== Feature implementations (kept & fixed) ==========

-- PLAYER ESP (unchanged)
local PlayerESPActive = false
local playerHighlights = {}
local NameTags = {}
local function isBeast(player) return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil end
local function HighlightColorForPlayer(player) if isBeast(player) then return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200) end
local function AddPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player]=nil end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"; h.Adornee = player.Character; h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.12; h.OutlineTransparency = 0.04; h.Enabled = true
    playerHighlights[player] = h
end
local function RemovePlayerHighlight(player) if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player]=nil end end
local function AddNameTag(player)
    if player==LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then pcall(function() NameTags[player]:Destroy() end); NameTags[player]=nil end
    local billboard = Instance.new("BillboardGui", GUI); billboard.Name = "[FTFName]"; billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,130,0,24); billboard.StudsOffset = Vector3.new(0,2.18,0); billboard.AlwaysOnTop = true
    local text = Instance.new("TextLabel", billboard); text.Size = UDim2.new(1,0,1,0); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamSemibold
    text.TextSize = 14; text.TextColor3 = Color3.fromRGB(190,210,230); text.TextStrokeColor3 = Color3.fromRGB(8,10,14); text.TextStrokeTransparency = 0.6
    text.Text = player.DisplayName or player.Name
    NameTags[player] = billboard
end
local function RemoveNameTag(player) if NameTags[player] then pcall(function() NameTags[player]:Destroy() end); NameTags[player]=nil end end
local function RefreshPlayerESP() for _,p in pairs(Players:GetPlayers()) do if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) else RemovePlayerHighlight(p); RemoveNameTag(p) end end end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() wait(0.08); if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) end end) end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerHighlight(p); RemoveNameTag(p) end)
RunService.RenderStepped:Connect(function() if PlayerESPActive then for _,p in pairs(Players:GetPlayers()) do if playerHighlights[p] then local fill, outline = HighlightColorForPlayer(p); playerHighlights[p].FillColor = fill; playerHighlights[p].OutlineColor = outline end end end end)

-- COMPUTER ESP (unchanged)
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(model) return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc")) end
local function getScreenPart(model)
    for _,name in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        if model:FindFirstChild(name) and model[name]:IsA("BasePart") then return model[name] end
    end
    local biggest
    for _,c in ipairs(model:GetChildren()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function getPcColor(model) local s = getScreenPart(model); if not s then return Color3.fromRGB(77,164,255) end return s.Color end
local function AddComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end
    local h = Instance.new("Highlight"); h.Name = "[FTF_ESP_ComputerAura_DAVID]"; h.Adornee = model; h.Parent = Workspace
    h.FillColor = getPcColor(model); h.OutlineColor = Color3.fromRGB(210,210,210); h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    compHighlights[model] = h
end
local function RemoveComputerHighlight(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end end
local function RefreshComputerESP() for m,h in pairs(compHighlights) do if h then h:Destroy() end end; compHighlights = {} if not ComputerESPActive then return end for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then AddComputerHighlight(d) end end end
Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive and isComputerModel(obj) then task.delay(0.05, function() AddComputerHighlight(obj) end) end end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then h.FillColor = getPcColor(m) end end end end)

-- DOOR ESP (fixed)
local DoorESPActive = false
local doorHighlights = {} -- model -> SelectionBox
local doorDescendantAddConn = nil
local doorDescendantRemConn = nil

local function isDoorModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("door") then return true end
    if name:find("exitdoor") then return true end
    -- some maps: "SingleDoor"/"DoubleDoor" often are Models; try that
    if name:find("singledoor") or name:find("doubledoor") or name:find("single") and name:find("door") or name:find("double") and name:find("door") then return true end
    return false
end

local function getDoorPrimaryPart(model)
    if not model then return nil end
    -- prefer PrimaryPart
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    -- common candidates (search children deeply)
    local candidates = {"DoorBoard","Door","Part","ExitDoorTrigger","DoorL","DoorR","BasePart","Main"}
    for _,n in ipairs(candidates) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BasePart") then return v end
    end
    -- fallback: largest BasePart in model
    local biggest
    for _,c in ipairs(model:GetDescendants()) do
        if c:IsA("BasePart") then
            if not biggest or c.Size.Magnitude > biggest.Size.Magnitude then biggest = c end
        end
    end
    return biggest
end

local function AddDoorHighlight(model)
    if not model or not isDoorModel(model) then return end
    -- remove existing
    if doorHighlights[model] then pcall(function() doorHighlights[model]:Destroy() end); doorHighlights[model] = nil end
    local primary = getDoorPrimaryPart(model)
    if not primary then return end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_ESP_DoorEdge_DAVID]"
    box.Adornee = primary
    box.Color3 = Color3.fromRGB(255,220,120)
    -- make it clearly visible but not overpowering
    pcall(function() box.LineThickness = 0.14 end) -- larger thickness for visibility
    pcall(function() box.SurfaceTransparency = 1 end)
    pcall(function() box.DepthMode = Enum.SelectionBoxDepthMode.AlwaysOnTop end) -- ensure visible above geometry
    box.Parent = Workspace
    doorHighlights[model] = box
end

local function RemoveDoorHighlight(model)
    if doorHighlights[model] then pcall(function() doorHighlights[model]:Destroy() end); doorHighlights[model] = nil end
end

local function RefreshDoorESP()
    for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
    if not DoorESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if isDoorModel(d) then AddDoorHighlight(d) end
    end
end

local function onDoorDescendantAdded(desc)
    if not DoorESPActive then return end
    if not desc then return end
    if desc:IsA("Model") and isDoorModel(desc) then task.delay(0.05, function() AddDoorHighlight(desc) end) end
    if desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isDoorModel(mdl) then task.delay(0.05, function() AddDoorHighlight(mdl) end) end
    end
end

local function onDoorDescendantRemoving(desc)
    if not desc then return end
    if desc:IsA("Model") and isDoorModel(desc) then RemoveDoorHighlight(desc) end
    if desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isDoorModel(mdl) then RemoveDoorHighlight(mdl) end
    end
end

-- FREEZE PODS (kept)
local FreezePodsActive = false
local podHighlights = {}
local podDescendantAddConn = nil
local podDescendantRemConn = nil

local function isFreezePodModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("freezepod") then return true end
    if name:find("freeze") and name:find("pod") then return true end
    if name:find("freeze") and name:find("capsule") then return true end
    return false
end

local function AddFreezePodHighlight(model)
    if not model or not isFreezePodModel(model) then return end
    if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_FreezePodAura_DAVID]"; h.Adornee = model; h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[model] = h
end

local function RemoveFreezePodHighlight(model) if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end end
local function RefreshFreezePods() for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end if not FreezePodsActive then return end for _,d in ipairs(Workspace:GetDescendants()) do if isFreezePodModel(d) then AddFreezePodHighlight(d) end end end
local function onPodDescendantAdded(desc) if not FreezePodsActive then return end if desc and (desc:IsA("Model") or desc:IsA("Folder")) and isFreezePodModel(desc) then task.delay(0.05, function() AddFreezePodHighlight(desc) end) elseif desc and desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model") if mdl and isFreezePodModel(mdl) then task.delay(0.05, function() AddFreezePodHighlight(mdl) end) end end end
local function onPodDescendantRemoving(desc) if desc and desc:IsA("Model") and isFreezePodModel(desc) then RemoveFreezePodHighlight(desc) elseif desc and desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model") if mdl and isFreezePodModel(mdl) then RemoveFreezePodHighlight(mdl) end end end

-- RAGDOLL DOWN TIMER (kept)
local DownTimerActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}
local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head") if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI); billboard.Name = "[FTF_RagdollTimer]"; billboard.Adornee = head
    billboard.Size = UDim2.new(0,160,0,48); billboard.StudsOffset = Vector3.new(0,3.2,0); billboard.AlwaysOnTop = true
    local bg = Instance.new("Frame", billboard); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(24,24,28)
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,12)
    local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1,-16,1,-16); txt.Position = UDim2.new(0,8,0,6)
    txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 18; txt.TextColor3 = Color3.fromRGB(220,220,230)
    txt.Text = tostring(DOWN_TIME) .. "s"; txt.TextXAlignment = Enum.TextXAlignment.Center
    local pbg = Instance.new("Frame", bg); pbg.Size = UDim2.new(0.92,0,0,6); pbg.Position = UDim2.new(0.04,0,1,-10)
    local pfill = Instance.new("Frame", pbg); pfill.Size = UDim2.new(1,0,1,0); pfill.BackgroundColor3 = Color3.fromRGB(90,180,255)
    local info = { gui = billboard, label = txt, endTime = tick() + DOWN_TIME, progress = pfill }
    ragdollBillboards[player] = info
    return info
end
local function removeRagdollBillboard(player) if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then ragdollBillboards[player].gui:Destroy() end ragdollBillboards[player] = nil end end
local function updateBottomRightFor(player, endTime)
    if player == LocalPlayer then return end
    if not bottomUI[player] then
        local gui = Instance.new("ScreenGui"); gui.Name = "FTF_Ragdoll_UI"; gui.Parent = PlayerGui
        local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0,220,0,60); frame.BackgroundTransparency = 1
        local nameLabel = Instance.new("TextLabel", frame); nameLabel.Size = UDim2.new(1,0,0.5,0); nameLabel.BackgroundTransparency = 1; nameLabel.TextScaled = true; nameLabel.Text = player.Name
        local timerLabel = Instance.new("TextLabel", frame); timerLabel.Size = UDim2.new(1,0,0.5,0); timerLabel.Position = UDim2.new(0,0,0.5,0); timerLabel.BackgroundTransparency = 1; timerLabel.TextScaled = true; timerLabel.Text = tostring(DOWN_TIME)
        frame.Position = UDim2.new(1,-240,1,-80)
        bottomUI[player] = { screenGui = gui, frame = frame, timerLabel = timerLabel }
    end
    bottomUI[player].timerLabel.Text = string.format("%.2f", math.max(0, endTime - tick()))
end
RunService.Heartbeat:Connect(function()
    if not DownTimerActive then return end
    local now = tick()
    for player, info in pairs(ragdollBillboards) do
        if not player or not player.Parent or not info or not info.gui then
            removeRagdollBillboard(player)
            if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end bottomUI[player]=nil end
        else
            local remaining = info.endTime - now
            if remaining <= 0 then removeRagdollBillboard(player); if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end bottomUI[player]=nil end
            else
                if info.label and info.label.Parent then info.label.Text = string.format("%.2f", remaining); if remaining <= 5 then info.label.TextColor3 = Color3.fromRGB(255,90,90) else info.label.TextColor3 = Color3.fromRGB(220,220,230) end end
                if info.progress and info.progress.Parent then local frac = math.clamp(remaining / DOWN_TIME, 0, 1); info.progress.Size = UDim2.new(frac,0,1,0); if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(90,180,255) elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(240,200,60) else info.progress.BackgroundColor3 = Color3.fromRGB(255,90,90) end end
                if bottomUI[player] then bottomUI[player].timerLabel.Text = string.format("%.2f", remaining) end
            end
        end
    end
end)

local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, ragdoll = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not ragdoll then return end
        pcall(function() if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end end end)
        local conn = ragdoll.Changed:Connect(function() pcall(function() if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end else removeRagdollBillboard(player) end end) end)
        ragdollConnects[player] = conn
    end)
end
for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p) end)

-- GRAY SKIN (Remove players Textures)
local GraySkinActive = false
local skinBackup = {}
local grayConns = {}
local function storePartOriginal(part, store) if not part or (not part:IsA("BasePart") and not part:IsA("MeshPart")) then return end if store[part] then return end local okC, col = pcall(function() return part.Color end) local okM, mat = pcall(function() return part.Material end) store[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil } end
local function applyGrayToCharacter(player) if not player or not player.Character then return end local map = skinBackup[player] or {} skinBackup[player] = map for _,obj in ipairs(player.Character:GetDescendants()) do if obj:IsA("BasePart") or obj:IsA("MeshPart") then storePartOriginal(obj, map) pcall(function() obj.Color = Color3.fromRGB(128,128,132); obj.Material = Enum.Material.SmoothPlastic end) elseif obj:IsA("Accessory") then local handle = obj:FindFirstChild("Handle") if handle and handle:IsA("BasePart") then storePartOriginal(handle, map) pcall(function() handle.Color = Color3.fromRGB(128,128,132); handle.Material = Enum.Material.SmoothPlastic end) end end end end
local function restoreGrayForPlayer(player) local map = skinBackup[player]; if not map then return end for part, props in pairs(map) do if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end) end end skinBackup[player] = nil end
local function enableGraySkin() GraySkinActive = true for _,p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then applyGrayToCharacter(p) end if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end if not grayConns._playerAddedConn then grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer and GraySkinActive then if p.Character then applyGrayToCharacter(p) end if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end end) end end
local function disableGraySkin() GraySkinActive = false for p,_ in pairs(skinBackup) do pcall(function() restoreGrayForPlayer(p) end) end skinBackup = {} for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k]=nil end end
Players.PlayerRemoving:Connect(function(p) if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end; if grayConns[p] then pcall(function() grayConns[p]:Disconnect() end); grayConns[p]=nil end end)

-- SAFE WHITE BRICK TEXTURE
local TextureActive = false
local textureBackup = {}
local textureDescendantConn = nil
local function isPartPlayerCharacter(part) if not part then return false end local model = part:FindFirstAncestorWhichIsA("Model") if model then return Players:GetPlayerFromCharacter(model) ~= nil end return false end
local function saveAndApplyWhiteBrick(part) if not part or not part:IsA("BasePart") then return end if isPartPlayerCharacter(part) then return end if textureBackup[part] then return end local okC, col = pcall(function() return part.Color end) local okM, mat = pcall(function() return part.Material end) textureBackup[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil } pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end) end
local function applyWhiteBrickToAll() local desc = Workspace:GetDescendants() local batch = 0 for i = 1, #desc do local d = desc[i] if d and d:IsA("BasePart") then saveAndApplyWhiteBrick(d) batch = batch + 1 if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end end end end
local function onWorkspaceDescendantAdded(desc) if not TextureActive then return end if desc and desc:IsA("BasePart") and not isPartPlayerCharacter(desc) then task.defer(function() saveAndApplyWhiteBrick(desc) end) end end
local function restoreTextures() local entries = {} for p, props in pairs(textureBackup) do entries[#entries+1] = {p=p, props=props} end local batch = 0 for _, e in ipairs(entries) do local part = e.p; local props = e.props if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end if props.Color then part.Color = props.Color end end) end batch = batch + 1 if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end end textureBackup = {} end
local function enableTextureToggle() if TextureActive then return end TextureActive = true TextureIndicator.BackgroundColor3 = Color3.fromRGB(245,245,245) task.spawn(applyWhiteBrickToAll) textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded) if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Desativar Textures Tijolos Brancos" end end
local function disableTextureToggle() if not TextureActive then return end TextureActive = false if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end task.spawn(restoreTextures) TextureIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Ativar Textures Tijolos Brancos" end end

-- SNOW TEXTURE toggle (user script integrated, but safe: backs up parts/lighting/sky)
local SnowActive = false
local snowBackup = { parts = {}, lighting = {}, skies = {}, createdSky = nil }
local function enableSnowTexture()
    if SnowActive then return end
    SnowActive = true
    SnowIndicator.BackgroundColor3 = Color3.fromRGB(230,240,255)
    -- backup lighting
    snowBackup.lighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
    -- backup current skies and remove them
    for _,v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then table.insert(snowBackup.skies, v:Clone()); v:Destroy() end
    end
    -- create blank sky
    local sky = Instance.new("Sky"); sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""; sky.Parent = Lighting
    snowBackup.createdSky = sky
    -- apply lighting overrides
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogColor = Color3.new(1,1,1)
    Lighting.FogEnd = 100000; Lighting.Brightness = 2; Lighting.ClockTime = 12
    Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    -- apply to workspace parts (batched)
    task.spawn(function()
        local desc = Workspace:GetDescendants(); local batch = 0
        for i = 1, #desc do
            local obj = desc[i]
            if obj and obj:IsA("BasePart") then
                local mdl = obj:FindFirstAncestorWhichIsA("Model")
                local skip = (mdl and Players:GetPlayerFromCharacter(mdl) ~= nil)
                if not skip then
                    if not snowBackup.parts[obj] then
                        local okC, col = pcall(function() return obj.Color end)
                        local okM, mat = pcall(function() return obj.Material end)
                        snowBackup.parts[obj] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
                    end
                    pcall(function() obj.Color = Color3.new(1,1,1); obj.Material = Enum.Material.SmoothPlastic end)
                end
                batch = batch + 1
                if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
            end
        end
    end)
end
local function disableSnowTexture()
    if not SnowActive then return end
    SnowActive = false
    SnowIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
    -- restore parts
    task.spawn(function()
        local entries = {}
        for p,props in pairs(snowBackup.parts) do entries[#entries+1] = {p=p, props=props} end
        local batch = 0
        for _,e in ipairs(entries) do local part = e.p; local props = e.props if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end if props.Color then part.Color = props.Color end end) end batch = batch + 1 if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end end
        snowBackup.parts = {}
    end)
    -- restore lighting
    local L = snowBackup.lighting
    if L then
        Lighting.Ambient = L.Ambient or Lighting.Ambient
        Lighting.OutdoorAmbient = L.OutdoorAmbient or Lighting.OutdoorAmbient
        Lighting.FogColor = L.FogColor or Lighting.FogColor
        Lighting.FogEnd = L.FogEnd or Lighting.FogEnd
        Lighting.Brightness = L.Brightness or Lighting.Brightness
        Lighting.ClockTime = L.ClockTime or Lighting.ClockTime
        Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale or Lighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale or Lighting.EnvironmentSpecularScale
    end
    if snowBackup.createdSky and snowBackup.createdSky.Parent then snowBackup.createdSky:Destroy() end
    for _,cl in ipairs(snowBackup.skies) do local ok,new = pcall(function() return cl:Clone() end) if ok and new then new.Parent = Lighting end end
    snowBackup.skies = {}; snowBackup.lighting = {}; snowBackup.createdSky = nil
end

-- ========== Button behaviors ==========

-- Player ESP toggle
PlayerBtn.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive; RefreshPlayerESP()
    if PlayerESPActive then buttonLabelMap[PlayerBtn].Text = "Player ESP (ON)"; PlayerBtn.BackgroundColor3 = Color3.fromRGB(28,140,96) else buttonLabelMap[PlayerBtn].Text = "Player ESP"; PlayerBtn.BackgroundColor3 = Color3.fromRGB(12,14,18) end
end)

-- Computer ESP toggle
CompBtn.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive; RefreshComputerESP()
    if ComputerESPActive then buttonLabelMap[CompBtn].Text = "Computer ESP (ON)"; CompBtn.BackgroundColor3 = Color3.fromRGB(28,90,170) else buttonLabelMap[CompBtn].Text = "Computer ESP"; CompBtn.BackgroundColor3 = Color3.fromRGB(12,14,18) end
end)

-- Door ESP toggle
DoorBtn.MouseButton1Click:Connect(function()
    DoorESPActive = not DoorESPActive
    if DoorESPActive then
        buttonLabelMap[DoorBtn].Text = "ESP Doors (ON)"; DoorBtn.BackgroundColor3 = Color3.fromRGB(230,200,60)
        RefreshDoorESP()
        if not doorDescendantAddConn then doorDescendantAddConn = Workspace.DescendantAdded:Connect(onDoorDescendantAdded) end
        if not doorDescendantRemConn then doorDescendantRemConn = Workspace.DescendantRemoving:Connect(onDoorDescendantRemoving) end
    else
        buttonLabelMap[DoorBtn].Text = "ESP Doors"; DoorBtn.BackgroundColor3 = Color3.fromRGB(12,14,18)
        for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
        if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn = nil end
        if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn = nil end
    end
end)

-- Freeze Pods toggle
FreezeBtn.MouseButton1Click:Connect(function()
    FreezePodsActive = not FreezePodsActive
    if FreezePodsActive then buttonLabelMap[FreezeBtn].Text = "Freeze Pods ESP (ON)"; FreezeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); RefreshFreezePods(); if not podDescendantAddConn then podDescendantAddConn = Workspace.DescendantAdded:Connect(onPodDescendantAdded) end; if not podDescendantRemConn then podDescendantRemConn = Workspace.DescendantRemoving:Connect(onPodDescendantRemoving) end
    else buttonLabelMap[FreezeBtn].Text = "Freeze Pods ESP"; FreezeBtn.BackgroundColor3 = Color3.fromRGB(12,14,18); for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end; if podDescendantAddConn then pcall(function() podDescendantAddConn:Disconnect() end); podDescendantAddConn = nil end; if podDescendantRemConn then pcall(function() podDescendantRemConn:Disconnect() end); podDescendantRemConn = nil end end
end)

-- Remove players Textures toggle
RemoveTexBtn.MouseButton1Click:Connect(function()
    GraySkinActive = not GraySkinActive
    if GraySkinActive then buttonLabelMap[RemoveTexBtn].Text = "Remove players Textures (ON)"; RemoveTexBtn.BackgroundColor3 = Color3.fromRGB(120,120,140); enableGraySkin()
    else buttonLabelMap[RemoveTexBtn].Text = "Remove players Textures"; RemoveTexBtn.BackgroundColor3 = Color3.fromRGB(12,14,18); disableGraySkin() end
end)

-- Brick texture toggle
TextureBtn.MouseButton1Click:Connect(function()
    if not TextureActive then enableTextureToggle(); buttonLabelMap[TextureBtn].Text = "Ativar Textures Tijolos Brancos (ON)"; TextureBtn.BackgroundColor3 = Color3.fromRGB(220,220,220)
    else disableTextureToggle(); buttonLabelMap[TextureBtn].Text = "Ativar Textures Tijolos Brancos"; TextureBtn.BackgroundColor3 = Color3.fromRGB(12,14,18) end
end)

-- Snow texture toggle
SnowBtn.MouseButton1Click:Connect(function()
    if not SnowActive then enableSnowTexture(); buttonLabelMap[SnowBtn].Text = "Snow texture (ON)"; SnowBtn.BackgroundColor3 = Color3.fromRGB(230,240,255)
    else disableSnowTexture(); buttonLabelMap[SnowBtn].Text = "Snow texture"; SnowBtn.BackgroundColor3 = Color3.fromRGB(12,14,18) end
end)

-- Down timer toggle
DownTimerBtn.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then buttonLabelMap[DownTimerBtn].Text = "Ativar Contador de Down (ON)"; DownTimerBtn.BackgroundColor3 = Color3.fromRGB(200,120,30)
    else buttonLabelMap[DownTimerBtn].Text = "Ativar Contador de Down"; DownTimerBtn.BackgroundColor3 = Color3.fromRGB(12,14,18) end
    if not DownTimerActive then for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    else for _,p in pairs(Players:GetPlayers()) do local ok,temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end) if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then attachRagdollListenerToPlayer(p); end end end end
end)

-- Teleport buttons rebuilt on demand
-- We already connected Players.PlayerAdded/Removing to rebuildTeleportButtons earlier

-- Cleanup on unload
local function cleanupAll()
    -- textures
    if TextureActive then disableTextureToggle() end
    if GraySkinActive then disableGraySkin() end
    if SnowActive then disableSnowTexture() end
    -- highlights / billboards
    for p,_ in pairs(playerHighlights) do RemovePlayerHighlight(p) end
    for p,_ in pairs(NameTags) do RemoveNameTag(p) end
    for m,_ in pairs(compHighlights) do RemoveComputerHighlight(m) end
    for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    -- ragdoll
    for p,conn in pairs(ragdollConnects) do pcall(function() conn:Disconnect() end); ragdollConnects[p]=nil end
    for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
    for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    -- disconnect listeners
    if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn = nil end
    if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn = nil end
    if podDescendantAddConn then pcall(function() podDescendantAddConn:Disconnect() end); podDescendantAddConn = nil end
    if podDescendantRemConn then pcall(function() podDescendantRemConn:Disconnect() end); podDescendantRemConn = nil end
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
end

-- PlayerRemoving cleanup
Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end
    if playerHighlights[p] then RemovePlayerHighlight(p) end
    if NameTags[p] then RemoveNameTag(p) end
    if ragdollConnects[p] then pcall(function() ragdollConnects[p]:Disconnect() end); ragdollConnects[p]=nil end
    if ragdollBillboards[p] then removeRagdollBillboard(p) end
    if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p] = nil
    if compHighlights[p] then RemoveComputerHighlight(p) end
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
    -- rebuild teleport list when someone leaves
    task.delay(0.06, rebuildTeleportButtons)
end)

-- keep teleport list updated on name/displayname changes
Players.PlayerRemoving:Connect(function() end)
Players:GetPlayers() -- ensure players loaded

-- finalize
print("[FTF_ESP] Loaded successfully (menu bottom, door ESP fixed, Teleporte added)")
