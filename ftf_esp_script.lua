-- FTF ESP Script — consolidated fixed version (menu overhaul)
-- Novidades:
--  - Menu redesenhado: horizontal, arredondado, com categorias (Visuais, Textures, Timers)
--  - Todos os ESPs agrupados em "Visuais": Player ESP, Computer ESP, ESP Doors, Freeze Pods
--  - "Ativar Skin Cinza" renomeado para "Remove players Textures" e movido para "Textures"
--  - "Ativar Texture Tijolos Brancos" movido para "Textures"
--  - "Ativar Contador de Down" em "Timers"
--  - Sistema de pesquisa para filtrar opções por texto
--  - Layout mais limpo e responsivo (UIListLayout) — mantém a funcionalidade existente

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
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

-- helper storage to map buttons to their visible label and category
local buttonLabelMap = {}
local buttonCategory = {} -- button -> category string
local categoryButtons = {} -- name -> button
local categoryNameOrder = {"Visuais","Textures","Timers"}
local uiButtonsByCategory = { Visuais = {}, Textures = {}, Timers = {} }

-- ---------- Startup notice ----------
local function createStartupNotice(opts)
    opts = opts or {}
    local duration = opts.duration or 6
    local width = opts.width or 420
    local height = opts.height or 72

    local noticeGui = Instance.new("ScreenGui")
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false
    noticeGui.Parent = GUI

    local frame = Instance.new("Frame", noticeGui)
    frame.Name = "NoticeFrame"
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.92, 6)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0

    local panel = Instance.new("Frame", frame)
    panel.Name = "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(10,14,20)
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(55,140,220); stroke.Thickness = 1.2; stroke.Transparency = 0.28

    local iconBg = Instance.new("Frame", panel)
    iconBg.Size = UDim2.new(0, 40, 0, 40)
    iconBg.Position = UDim2.new(0, 14, 0.5, -20)
    iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26)
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0,12)
    local iconLabel = Instance.new("TextLabel", iconBg)
    iconLabel.Size = UDim2.new(1, -6, 1, -6); iconLabel.Position = UDim2.new(0,3,0,3)
    iconLabel.BackgroundTransparency = 1; iconLabel.Font = Enum.Font.FredokaOne; iconLabel.Text = "K"
    iconLabel.TextColor3 = Color3.fromRGB(100,170,220); iconLabel.TextSize = 22

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -120, 1, -12)
    txt.Position = UDim2.new(0, 86, 0, 6)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true

    -- tween in/out
    TweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.0}):Play()
    task.delay(duration, function()
        if noticeGui and noticeGui.Parent then noticeGui:Destroy() end
    end)
end
createStartupNotice()

-- ---------- Main (horizontal) menu frame ----------
local gWidth, gHeight = 760, 220
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.BackgroundColor3 = Color3.fromRGB(10,12,16)
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
Frame.Position = UDim2.new(0.5, -gWidth/2, 0.12, 0)
Frame.Active = true
Frame.Visible = false
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
local aCorner = Instance.new("UICorner", Frame); aCorner.CornerRadius = UDim.new(0,18)
local stroke = Instance.new("UIStroke", Frame); stroke.Color = Color3.fromRGB(40,50,64); stroke.Thickness = 1; stroke.Transparency = 0.2

-- Header: title + search
local Header = Instance.new("Frame", Frame)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 56)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Name = "Title"
Title.Text = "FTF - David's ESP"
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(200,220,240)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 22, 0, 12)
Title.Size = UDim2.new(0.5, 0, 0, 32)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Search box
local SearchBox = Instance.new("TextBox", Header)
SearchBox.Name = "SearchBox"
SearchBox.PlaceholderText = "Pesquisar opções..."
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0, 240, 0, 28)
SearchBox.Position = UDim2.new(1, -260, 0, 14)
SearchBox.BackgroundColor3 = Color3.fromRGB(14,16,20)
SearchBox.TextColor3 = Color3.fromRGB(200,220,240)
SearchBox.TextSize = 14
local searchCorner = Instance.new("UICorner", SearchBox); searchCorner.CornerRadius = UDim.new(0,10)
local searchStroke = Instance.new("UIStroke", SearchBox); searchStroke.Color = Color3.fromRGB(60,80,110); searchStroke.Thickness = 1; searchStroke.Transparency = 0.6

-- Left: categories column
local LeftCol = Instance.new("Frame", Frame)
LeftCol.Name = "LeftCol"
LeftCol.Size = UDim2.new(0, 170, 1, -64)
LeftCol.Position = UDim2.new(0, 12, 0, 64)
LeftCol.BackgroundTransparency = 1

local leftCorner = Instance.new("UICorner", LeftCol); leftCorner.CornerRadius = UDim.new(0,12)

-- Category buttons stacked
local CatLayout = Instance.new("UIListLayout", LeftCol)
CatLayout.SortOrder = Enum.SortOrder.LayoutOrder
CatLayout.Padding = UDim.new(0,10)

local function createCategoryButton(text)
    local btn = Instance.new("TextButton", LeftCol)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(180,200,220)
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = Color3.fromRGB(12,14,18)
    local cr = Instance.new("UICorner", btn); cr.CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(36,46,60); stroke.Thickness = 1; stroke.Transparency = 0.4
    return btn
end

-- Create category buttons
for i,cat in ipairs(categoryNameOrder) do
    local btn = createCategoryButton(cat)
    btn.LayoutOrder = i
    categoryButtons[cat] = btn
end

-- Right: content area where option buttons appear
local ContentArea = Instance.new("Frame", Frame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -200, 1, -64)
ContentArea.Position = UDim2.new(0, 188, 0, 64)
ContentArea.BackgroundTransparency = 1

local contentCorner = Instance.new("UICorner", ContentArea); contentCorner.CornerRadius = UDim.new(0,10)

-- Scrolling frame for options (in case exceed area)
local OptionsScroll = Instance.new("ScrollingFrame", ContentArea)
OptionsScroll.Name = "OptionsScroll"
OptionsScroll.Size = UDim2.new(1, -12, 1, 0)
OptionsScroll.Position = UDim2.new(0, 6, 0, 0)
OptionsScroll.BackgroundTransparency = 1
OptionsScroll.CanvasSize = UDim2.new(0,0,0,0)
OptionsScroll.ScrollBarThickness = 6
OptionsScroll.BorderSizePixel = 0
local optLayout = Instance.new("UIListLayout", OptionsScroll)
optLayout.SortOrder = Enum.SortOrder.LayoutOrder
optLayout.Padding = UDim.new(0,8)

-- Reusable futuristic button creator (now parent-aware, stacked via UIListLayout)
local function createFuturisticButtonNamed(txt, c1, c2, parent)
    parent = parent or OptionsScroll
    local btnOuter = Instance.new("TextButton", parent)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1
    btnOuter.BorderSizePixel = 0
    btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -12, 0, 46)
    btnOuter.Text = ""
    btnOuter.ClipsDescendants = true
    btnOuter.LayoutOrder = (#parent:GetChildren()) + 1

    local bg = Instance.new("Frame", btnOuter); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1; bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,10)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation=45

    local inner = Instance.new("Frame", bg); inner.Name="Inner"; inner.Size=UDim2.new(1,-8,1,-8); inner.Position=UDim2.new(0,4,0,4)
    inner.BackgroundColor3 = Color3.fromRGB(8,10,12); inner.BorderSizePixel = 0
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local innerStroke = Instance.new("UIStroke", inner); innerStroke.Color = Color3.fromRGB(24,34,46); innerStroke.Thickness=1; innerStroke.Transparency=0.3

    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, 0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = txt
    label.TextSize = 15; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,48,0,20); indicator.Position = UDim2.new(1,-64,0.5,-10)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14); indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220); local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0,6)

    btnOuter.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(grad, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 135}):Play()
            TweenService:Create(indBar, TweenInfo.new(0.18), {Size = UDim2.new(0.66,0,0.86,0), Position = UDim2.new(0.12,0,0.07,0)}):Play()
            TweenService:Create(label, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(230,245,255)}):Play()
        end)
    end)
    btnOuter.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(grad, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()
            TweenService:Create(indBar, TweenInfo.new(0.18), {Size = UDim2.new(0.38,0,0.6,0), Position = UDim2.new(0.06,0,0.2,0)}):Play()
            TweenService:Create(label, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(180,200,220)}):Play()
        end)
    end)
    btnOuter.MouseButton1Down:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.09), {Position = UDim2.new(0,6,0,6)}):Play() end) end)
    btnOuter.MouseButton1Up:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.12), {Position = UDim2.new(0,4,0,4)}):Play() end) end)

    -- register label for search and external renaming
    buttonLabelMap[btnOuter] = label

    return btnOuter, indBar, label
end

-- create option buttons and map to categories
-- Visuais category
local PlayerBtn, PlayerIndicator = createFuturisticButtonNamed("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101), OptionsScroll)
buttonCategory[PlayerBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], PlayerBtn)

local CompBtn, CompIndicator = createFuturisticButtonNamed("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255), OptionsScroll)
buttonCategory[CompBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], CompBtn)

local DoorBtn, DoorIndicator = createFuturisticButtonNamed("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100), OptionsScroll)
buttonCategory[DoorBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], DoorBtn)

local FreezeBtn, FreezeIndicator = createFuturisticButtonNamed("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80), OptionsScroll)
buttonCategory[FreezeBtn] = "Visuais"; table.insert(uiButtonsByCategory["Visuais"], FreezeBtn)

-- Textures category
local RemoveTexBtn, RemoveTexIndicator = createFuturisticButtonNamed("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140), OptionsScroll)
buttonCategory[RemoveTexBtn] = "Textures"; table.insert(uiButtonsByCategory["Textures"], RemoveTexBtn)

local TextureBtn, TextureIndicator = createFuturisticButtonNamed("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245), OptionsScroll)
buttonCategory[TextureBtn] = "Textures"; table.insert(uiButtonsByCategory["Textures"], TextureBtn)

-- Timers category
local DownTimerBtn, DownIndicator = createFuturisticButtonNamed("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90), OptionsScroll)
buttonCategory[DownTimerBtn] = "Timers"; table.insert(uiButtonsByCategory["Timers"], DownTimerBtn)

-- adjust canvas size automatically
local function updateCanvasSize()
    local total = 0
    for _,obj in ipairs(optLayout:GetChildren()) do end -- no-op to satisfy linter
    -- compute total height by summing absolute sizes (approx)
    local list = OptionsScroll:GetDescendants()
    for _,v in ipairs(OptionsScroll:GetChildren()) do
        if v:IsA("TextButton") then
            total = total + v.AbsoluteSize.Y + optLayout.Padding.Offset
        end
    end
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, math.max(0, total))
end
optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 8) end)

-- Close and draggable
local CloseBtn = Instance.new("TextButton", Frame); CloseBtn.Size = UDim2.new(0,44,0,44); CloseBtn.Position = UDim2.new(1,-52,0,8)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(160,180,200); CloseBtn.AutoButtonColor = false
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

-- Helper: set active category and refresh visible options
local activeCategory = "Visuais"
local function setActiveCategory(cat)
    activeCategory = cat
    -- update category button style
    for name,btn in pairs(categoryButtons) do
        if name == cat then
            btn.BackgroundColor3 = Color3.fromRGB(20,30,40)
            btn.TextColor3 = Color3.fromRGB(240,240,240)
        else
            btn.BackgroundColor3 = Color3.fromRGB(12,14,18)
            btn.TextColor3 = Color3.fromRGB(180,200,220)
        end
    end
    -- update options visibility based on category and search
    local query = string.lower(tostring(SearchBox.Text or ""))
    for btn,label in pairs(buttonLabelMap) do
        local cat = buttonCategory[btn] or "Visuais"
        local matchesCat = (cat == cat) -- no-op to keep variable readable
        local visible = (cat == activeCategory)
        -- apply search filter
        if visible and query ~= "" then
            local labelText = string.lower(label.Text or "")
            if not labelText:find(query) then visible = false end
        end
        btn.Visible = visible
    end
    -- force layout update
    task.delay(0.01, function() OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 8) end)
end

-- connect category buttons
for name,btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function() setActiveCategory(name) end)
end

-- initial activate
setActiveCategory(activeCategory)

-- Search handling
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(tostring(SearchBox.Text or ""))
    for btn,label in pairs(buttonLabelMap) do
        local cat = buttonCategory[btn] or "Visuais"
        local visible = (cat == activeCategory)
        if visible and query ~= "" then
            local labelText = string.lower(label.Text or "")
            if not labelText:find(query) then visible = false end
        end
        btn.Visible = visible
    end
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, optLayout.AbsoluteContentSize.Y + 8)
end)

-- ========== Existing feature wiring (kept mostly intact) ==========
-- Player ESP, Computer ESP, Door ESP (SelectionBox logic), Freeze Pods (Highlight), GraySkin/Remove textures, Texture toggle, Down timer
-- For brevity and stability we reuse the previously working functions and hook them to the new buttons.
-- NOTE: some functions refer to button variables defined above (PlayerBtn, CompBtn, DoorBtn, FreezeBtn, RemoveTexBtn, TextureBtn, DownTimerBtn)

-- ========== PLAYER ESP ==========
local PlayerESPActive = false
local playerHighlights = {}
local NameTags = {}

local function isBeast(player)
    return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end
local function HighlightColorForPlayer(player)
    if isBeast(player) then return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
end
local function AddPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player]=nil end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"; h.Adornee = player.Character
    h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.12; h.OutlineTransparency = 0.04
    h.Enabled = true
    playerHighlights[player] = h
end
local function RemovePlayerHighlight(player) if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player]=nil end end

local function AddNameTag(player)
    if player==LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then pcall(function() NameTags[player]:Destroy() end); NameTags[player]=nil end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTFName]"; billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,110,0,20); billboard.StudsOffset = Vector3.new(0,2.18,0); billboard.AlwaysOnTop = true
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamSemibold
    text.TextSize = 13; text.TextColor3 = Color3.fromRGB(190,210,230); text.TextStrokeColor3 = Color3.fromRGB(8,10,14); text.TextStrokeTransparency = 0.6
    text.Text = player.DisplayName or player.Name
    NameTags[player] = billboard
end
local function RemoveNameTag(player) if NameTags[player] then pcall(function() NameTags[player]:Destroy() end); NameTags[player]=nil end end

local function RefreshPlayerESP()
    for _,p in pairs(Players:GetPlayers()) do
        if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) else RemovePlayerHighlight(p); RemoveNameTag(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() wait(0.08); if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) end end)
end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerHighlight(p); RemoveNameTag(p) end)

RunService.RenderStepped:Connect(function()
    if PlayerESPActive then
        for _,p in pairs(Players:GetPlayers()) do
            if playerHighlights[p] then
                local fill, outline = HighlightColorForPlayer(p)
                playerHighlights[p].FillColor = fill
                playerHighlights[p].OutlineColor = outline
            end
        end
    end
end)

-- ========== COMPUTER ESP ==========
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(model)
    return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc"))
end
local function getScreenPart(model)
    for _,name in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        if model:FindFirstChild(name) and model[name]:IsA("BasePart") then return model[name] end
    end
    local biggest
    for _,c in ipairs(model:GetChildren()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function getPcColor(model)
    local s = getScreenPart(model)
    if not s then return Color3.fromRGB(77,164,255) end
    return s.Color
end
local function AddComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"; h.Adornee = model
    h.Parent = Workspace
    h.FillColor = getPcColor(model); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03
    h.Enabled = true
    compHighlights[model] = h
end
local function RemoveComputerHighlight(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end end
local function RefreshComputerESP()
    for m,h in pairs(compHighlights) do if h then h:Destroy() end end; compHighlights = {}
    if not ComputerESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then AddComputerHighlight(d) end end
end
Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive and isComputerModel(obj) then task.delay(0.05, function() AddComputerHighlight(obj) end) end end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then h.FillColor = getPcColor(m) end end end end)

-- ========== ESP DOORS (bordas finas via SelectionBox) ==========
local DoorESPActive = false
local doorHighlights = {} -- model => SelectionBox
local doorDescendantAddConn = nil
local doorDescendantRemConn = nil

local function isDoorModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("door") then return true end
    if name:find("exitdoor") then return true end
    return false
end

local function getDoorPrimaryPart(model)
    if not model then return nil end
    local candidates = {"DoorBoard","Door", "Part", "ExitDoorTrigger", "DoorL", "DoorR", "BasePart"}
    for _,n in ipairs(candidates) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BasePart") then return v end
    end
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
    if doorHighlights[model] then pcall(function() doorHighlights[model]:Destroy() end); doorHighlights[model]=nil end
    local primary = getDoorPrimaryPart(model)
    if not primary then return end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_ESP_DoorEdge_DAVID]"
    box.Adornee = primary
    box.Color3 = Color3.fromRGB(255,230,120)
    if pcall(function() box.LineThickness = 0.02 end) then end
    box.SurfaceTransparency = 1
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
    if desc and desc:IsA("Model") and isDoorModel(desc) then task.delay(0.04, function() AddDoorHighlight(desc) end) end
    if desc and desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isDoorModel(mdl) then task.delay(0.04, function() AddDoorHighlight(mdl) end) end
    end
end

local function onDoorDescendantRemoving(desc)
    if not desc then return end
    if desc:IsA("Model") and isDoorModel(desc) then RemoveDoorHighlight(desc) end
    if desc and desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isDoorModel(mdl) then RemoveDoorHighlight(mdl) end
    end
end

-- ========== FREEZE PODS AURA ==========
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
    h.Name = "[FTF_ESP_FreezePodAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100)    -- vermelho
    h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08
    h.OutlineTransparency = 0.02
    h.Enabled = true
    podHighlights[model] = h
end

local function RemoveFreezePodHighlight(model)
    if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end
end

local function RefreshFreezePods()
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    if not FreezePodsActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if isFreezePodModel(d) then AddFreezePodHighlight(d) end
    end
end

local function onPodDescendantAdded(desc)
    if not FreezePodsActive then return end
    if desc and (desc:IsA("Model") or desc:IsA("Folder")) and isFreezePodModel(desc) then
        task.delay(0.05, function() AddFreezePodHighlight(desc) end)
    elseif desc and desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isFreezePodModel(mdl) then task.delay(0.05, function() AddFreezePodHighlight(mdl) end) end
    end
end

local function onPodDescendantRemoving(desc)
    if desc and desc:IsA("Model") and isFreezePodModel(desc) then
        RemoveFreezePodHighlight(desc)
    elseif desc and desc:IsA("BasePart") then
        local mdl = desc:FindFirstAncestorWhichIsA("Model")
        if mdl and isFreezePodModel(mdl) then RemoveFreezePodHighlight(mdl) end
    end
end

-- ========== RAGDOLL DOWN TIMER (28s) ==========
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
    billboard.Size = UDim2.new(0,140,0,44); billboard.StudsOffset = Vector3.new(0,3.2,0); billboard.AlwaysOnTop = true
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
        local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0,200,0,50); frame.BackgroundTransparency = 1
        local nameLabel = Instance.new("TextLabel", frame); nameLabel.Size = UDim2.new(1,0,0.5,0); nameLabel.BackgroundTransparency = 1; nameLabel.TextScaled = true; nameLabel.Text = player.Name
        local timerLabel = Instance.new("TextLabel", frame); timerLabel.Size = UDim2.new(1,0,0.5,0); timerLabel.Position = UDim2.new(0,0,0.5,0); timerLabel.BackgroundTransparency = 1; timerLabel.TextScaled = true; timerLabel.Text = tostring(DOWN_TIME)
        frame.Position = UDim2.new(1,-220,1,-60)
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
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p); p.CharacterAdded:Connect(function() wait(0.06); if ragdollBillboards[p] then removeRagdollBillboard(p); createRagdollBillboardFor(p) end end) end)
for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end

-- ========== GRAY SKIN / Remove players Textures ==========
local GraySkinActive = false
local skinBackup = {}
local grayConns = {}

local function storePartOriginal(part, store)
    if not part or (not part:IsA("BasePart") and not part:IsA("MeshPart")) then return end
    if store[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    store[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
end
local function applyGrayToCharacter(player)
    if not player or not player.Character then return end
    local map = skinBackup[player] or {}
    skinBackup[player] = map
    for _,obj in ipairs(player.Character:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            storePartOriginal(obj, map)
            pcall(function() obj.Color = Color3.fromRGB(128,128,132); obj.Material = Enum.Material.SmoothPlastic end)
        elseif obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                storePartOriginal(handle, map)
                pcall(function() handle.Color = Color3.fromRGB(128,128,132); handle.Material = Enum.Material.SmoothPlastic end)
            end
        end
    end
end
local function restoreGrayForPlayer(player)
    local map = skinBackup[player]; if not map then return end
    for part, props in pairs(map) do
        if part and part.Parent then
            pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end)
        end
    end
    skinBackup[player] = nil
end
local function enableGraySkin()
    GraySkinActive = true
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyGrayToCharacter(p) end
        if not grayConns[p] then
            grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end)
        end
    end
    if not grayConns._playerAddedConn then
        grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer and GraySkinActive then if p.Character then applyGrayToCharacter(p) end; if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end end)
    end
end
local function disableGraySkin()
    GraySkinActive = false
    for p,_ in pairs(skinBackup) do pcall(function() restoreGrayForPlayer(p) end) end
    skinBackup = {}
    for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k]=nil end
end
Players.PlayerRemoving:Connect(function(p) if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end; if grayConns[p] then pcall(function() grayConns[p]:Disconnect() end); grayConns[p]=nil end end)

-- ========== SAFE WHITE BRICK TEXTURE (toggle) ==========
local TextureActive = false
local textureBackup = {}         -- [part] = {Color, Material}
local textureDescendantConn = nil

local function isPartPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then
        return Players:GetPlayerFromCharacter(model) ~= nil
    end
    return false
end

local function saveAndApplyWhiteBrick(part)
    if not part or not part:IsA("BasePart") then return end
    if isPartPlayerCharacter(part) then return end
    if textureBackup[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    textureBackup[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
    pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end)
end

local function applyWhiteBrickToAll()
    local desc = Workspace:GetDescendants()
    local batch = 0
    for i = 1, #desc do
        local d = desc[i]
        if d and d:IsA("BasePart") then
            saveAndApplyWhiteBrick(d)
            batch = batch + 1
            if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
        end
    end
end

local function onWorkspaceDescendantAdded(desc)
    if not TextureActive then return end
    if desc and desc:IsA("BasePart") and not isPartPlayerCharacter(desc) then
        task.defer(function() saveAndApplyWhiteBrick(desc) end)
    end
end

local function restoreTextures()
    local entries = {}
    for p, props in pairs(textureBackup) do entries[#entries+1] = {p=p, props=props} end
    local batch = 0
    for _, e in ipairs(entries) do
        local part = e.p; local props = e.props
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
        batch = batch + 1
        if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
    end
    textureBackup = {}
end

local function enableTextureToggle()
    if TextureActive then return end
    TextureActive = true
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(245,245,245)
    task.spawn(applyWhiteBrickToAll)
    textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Desativar Textures Tijolos Brancos" end
end

local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    task.spawn(restoreTextures)
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Ativar Textures Tijolos Brancos" end
end

-- ========== BUTTON BEHAVIORS (wiring new UI buttons) ==========
-- Player ESP toggle
PlayerBtn.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive; RefreshPlayerESP()
    if PlayerESPActive then PlayerIndicator.BackgroundColor3 = Color3.fromRGB(52,215,101) else PlayerIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

-- Computer ESP toggle
CompBtn.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive; RefreshComputerESP()
    if ComputerESPActive then CompIndicator.BackgroundColor3 = Color3.fromRGB(54,144,255) else CompIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

-- Door ESP toggle
DoorBtn.MouseButton1Click:Connect(function()
    DoorESPActive = not DoorESPActive
    if DoorESPActive then
        DoorIndicator.BackgroundColor3 = Color3.fromRGB(255,220,100)
        RefreshDoorESP()
        if not doorDescendantAddConn then doorDescendantAddConn = Workspace.DescendantAdded:Connect(onDoorDescendantAdded) end
        if not doorDescendantRemConn then doorDescendantRemConn = Workspace.DescendantRemoving:Connect(onDoorDescendantRemoving) end
    else
        DoorIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
        for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
        if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn = nil end
        if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn = nil end
    end
end)

-- Freeze Pods toggle
FreezeBtn.MouseButton1Click:Connect(function()
    FreezePodsActive = not FreezePodsActive
    if FreezePodsActive then
        FreezeIndicator.BackgroundColor3 = Color3.fromRGB(255,80,80)
        RefreshFreezePods()
        if not podDescendantAddConn then podDescendantAddConn = Workspace.DescendantAdded:Connect(onPodDescendantAdded) end
        if not podDescendantRemConn then podDescendantRemConn = Workspace.DescendantRemoving:Connect(onPodDescendantRemoving) end
    else
        FreezeIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
        for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
        if podDescendantAddConn then pcall(function() podDescendantAddConn:Disconnect() end); podDescendantAddConn = nil end
        if podDescendantRemConn then pcall(function() podDescendantRemConn:Disconnect() end); podDescendantRemConn = nil end
    end
end)

-- Remove players Textures toggle
RemoveTexBtn.MouseButton1Click:Connect(function()
    GraySkinActive = not GraySkinActive
    if GraySkinActive then RemoveTexIndicator.BackgroundColor3 = Color3.fromRGB(200,200,200); enableGraySkin()
    else RemoveTexIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220); disableGraySkin() end
end)

-- Textures Brick toggle
TextureBtn.MouseButton1Click:Connect(function()
    if not TextureActive then enableTextureToggle() else disableTextureToggle() end
end)

-- Down timer toggle
DownTimerBtn.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then DownIndicator.BackgroundColor3 = Color3.fromRGB(255,200,90)
    else DownIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
    if not DownTimerActive then
        for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end
        for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    else
        for _,p in pairs(Players:GetPlayers()) do
            local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then attachRagdollListenerToPlayer(p); end end
        end
    end
end)

-- Cleanup on unload (best effort)
local function cleanupAll()
    if TextureActive then disableTextureToggle() end
    if GraySkinActive then disableGraySkin() end
    for p,_ in pairs(playerHighlights) do RemovePlayerHighlight(p) end
    for p,_ in pairs(NameTags) do RemoveNameTag(p) end
    for m,_ in pairs(compHighlights) do RemoveComputerHighlight(m) end
    for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    -- disconnect ragdoll listeners and remove billboards
    for p,conn in pairs(ragdollConnects) do pcall(function() conn:Disconnect() end); ragdollConnects[p]=nil end
    for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
    for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    -- restore textures
    if next(textureBackup) ~= nil then restoreTextures() end
    -- disconnect workspace listeners
    if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn = nil end
    if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn = nil end
    if podDescendantAddConn then pcall(function() podDescendantAddConn:Disconnect() end); podDescendantAddConn = nil end
    if podDescendantRemConn then pcall(function() podDescendantRemConn:Disconnect() end); podDescendantRemConn = nil end
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
end

-- Bind PlayerRemoving to cleanup for players
Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end
    if playerHighlights[p] then RemovePlayerHighlight(p) end
    if NameTags[p] then RemoveNameTag(p) end
    if ragdollConnects[p] then pcall(function() ragdollConnects[p]:Disconnect() end); ragdollConnects[p]=nil end
    if ragdollBillboards[p] then removeRagdollBillboard(p) end
    if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p] = nil
    if compHighlights[p] then RemoveComputerHighlight(p) end
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
end)

print("[FTF_ESP] Loaded successfully (new UI)")
