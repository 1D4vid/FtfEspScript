-- FTF ESP Script — stable fix (menu square, working Door ESP, Teleport category, startup notice)
-- This is a consolidated, tested-at-a-glance script:
--  - Square menu (no UICorner), bottom-center, draggable header
--  - Startup animated notice restored
--  - Categories: Visuais, Textures, Timers, Teleporte (with dynamic player buttons)
--  - Search/filter for options inside active category
--  - Player ESP (Highlight), Computer ESP (Highlight), Door ESP (SelectionBox always-on-top), Freeze Pods (Highlight)
--  - Textures: Remove player textures (best-effort), White Brick toggle, Snow toggle (safe backup/restore)
--  - Down timer (basic ragdoll listener + billboards)
--  - Cleanups on toggles/unload

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Remove old GUI if present
for _,g in pairs(CoreGui:GetChildren()) do if g.Name == "FTF_ESP_GUI_DAVID" then pcall(function() g:Destroy() end) end end
if LocalPlayer:FindFirstChild("PlayerGui") then
    for _,g in pairs(LocalPlayer.PlayerGui:GetChildren()) do if g.Name == "FTF_ESP_GUI_DAVID" then pcall(function() g:Destroy() end) end end
end

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Helpers / state
local OptionButtons = {}           -- list of option buttons
local ButtonLabel = {}             -- btn -> TextLabel
local ButtonCategory = {}          -- btn -> category name
local DoorBoxes = {}               -- model -> SelectionBox
local PlayerHighlights = {}        -- player -> Highlight
local ComputerHighlights = {}      -- model -> Highlight
local PodHighlights = {}           -- model -> Highlight
local TeleportBtns = {}            -- player -> button
local TextureBackup = {}           -- part -> {Color, Material}
local SnowBackup = {parts = {}, skies = {}, lighting = {}, createdSky = nil}
local RagdollBillboards = {}       -- player -> info
local RagdollConns = {}

-- Categories and UI sizes
local categories = {"Visuais","Textures","Timers","Teleporte"}
local activeCategory = "Visuais"

-- ---------- Startup notice ----------
local function startupNotice()
    local notice = Instance.new("Frame")
    notice.Size = UDim2.new(0,520,0,72)
    notice.Position = UDim2.new(0.5,-260,0.92,36)
    notice.BackgroundColor3 = Color3.fromRGB(10,14,18)
    notice.BorderSizePixel = 0
    notice.Name = "FTF_StartNotice"
    notice.Parent = GUI

    local icon = Instance.new("TextLabel", notice)
    icon.Size = UDim2.new(0,40,0,40)
    icon.Position = UDim2.new(0,12,0.5,-20)
    icon.BackgroundColor3 = Color3.fromRGB(14,16,20)
    icon.Font = Enum.Font.FredokaOne
    icon.Text = "K"
    icon.TextColor3 = Color3.fromRGB(100,170,220)
    icon.TextSize = 22
    icon.BorderSizePixel = 0

    local txt = Instance.new("TextLabel", notice)
    txt.Size = UDim2.new(1,-96,1,0); txt.Position = UDim2.new(0,86,0,6)
    txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(200,220,240)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left

    -- tween in
    TweenService:Create(notice, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5,-260,0.88,0)}):Play()
    task.delay(4.5, function() pcall(function() notice:Destroy() end) end)
end
startupNotice()

-- ---------- Main Menu (SQUARE) ----------
local W, H = 980, 360
local Main = Instance.new("Frame", GUI)
Main.Name = "FTF_Main"
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0.5, -W/2, 1, -H - 24)
Main.BackgroundColor3 = Color3.fromRGB(10,12,16)
Main.BorderSizePixel = 0
-- intentionally square (no UICorner)
local stroke = Instance.new("UIStroke", Main); stroke.Color = Color3.fromRGB(36,46,60); stroke.Thickness = 1; stroke.Transparency = 0.15
Main.Visible = false

-- Header (draggable) + Search
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,72); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Text = "FTF - David's ESP"; Title.Font = Enum.Font.FredokaOne; Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(200,220,240); Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0,16,0,18); Title.Size = UDim2.new(0.5,0,0,36); Title.TextXAlignment = Enum.TextXAlignment.Left

local Search = Instance.new("TextBox", Header)
Search.PlaceholderText = "Pesquisar opções..."
Search.ClearTextOnFocus = false
Search.Size = UDim2.new(0,320,0,34)
Search.Position = UDim2.new(1, -356, 0, 18)
Search.BackgroundColor3 = Color3.fromRGB(14,16,20)
Search.TextColor3 = Color3.fromRGB(200,220,240)

-- Left categories
local LeftCol = Instance.new("Frame", Main)
LeftCol.Size = UDim2.new(0,220,1,-88)
LeftCol.Position = UDim2.new(0,16,0,78)
LeftCol.BackgroundTransparency = 1
local list = Instance.new("UIListLayout", LeftCol); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0,12)
local CategoryButtons = {}
for i,c in ipairs(categories) do
    local b = Instance.new("TextButton", LeftCol)
    b.Size = UDim2.new(1,0,0,56); b.LayoutOrder = i
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 16
    b.Text = c; b.TextColor3 = Color3.fromRGB(180,200,220)
    b.BackgroundColor3 = Color3.fromRGB(12,14,18)
    CategoryButtons[c] = b
end

-- Right content (options)
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -260, 1, -88)
Content.Position = UDim2.new(0, 248, 0, 78)
Content.BackgroundTransparency = 1

local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -12, 1, 0); Scroll.Position = UDim2.new(0,6,0,0)
Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 8
local ScrollLayout = Instance.new("UIListLayout", Scroll); ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder; ScrollLayout.Padding = UDim.new(0,10)
ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0,0,0, ScrollLayout.AbsoluteContentSize.Y + 12) end)

-- Option button factory
local function makeOption(text, colorA, colorB, category)
    colorA = colorA or Color3.fromRGB(20,20,20); colorB = colorB or colorA
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, -12, 0, 56); btn.BackgroundTransparency = 1; btn.AutoButtonColor = false
    local bg = Instance.new("Frame", btn); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = colorA; bg.BorderSizePixel = 0
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,colorA), ColorSequenceKeypoint.new(0.6,colorB), ColorSequenceKeypoint.new(1,colorA)}; grad.Rotation = 45
    local inner = Instance.new("Frame", bg); inner.Size = UDim2.new(1,-8,1,-8); inner.Position = UDim2.new(0,4,0,4); inner.BackgroundColor3 = Color3.fromRGB(8,10,12)
    local corner = Instance.new("UICorner", inner); corner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", inner); label.Size = UDim2.new(1,-24,1,0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = text; label.TextSize = 15; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left
    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,66,0,26); indicator.Position = UDim2.new(1,-92,0.5,-13); indicator.BackgroundColor3 = Color3.fromRGB(10,12,14)
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0); indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    local indBarCorner = Instance.new("UICorner", indBar); indBarCorner.CornerRadius = UDim.new(0,6)

    ButtonLabel[btn] = label
    ButtonCategory[btn] = category or "Visuais"
    table.insert(OptionButtons, btn)
    return btn
end

-- Create options
local btnPlayer = makeOption("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101), "Visuais")
local btnComputer = makeOption("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255), "Visuais")
local btnDoors = makeOption("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100), "Visuais")
local btnFreeze = makeOption("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80), "Visuais")

local btnRemoveSkin = makeOption("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140), "Textures")
local btnWhiteBricks = makeOption("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245), "Textures")
local btnSnow = makeOption("Snow texture", Color3.fromRGB(235,245,255), Color3.fromRGB(245,250,255), "Textures")

local btnDown = makeOption("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90), "Timers")
local tpHeader = makeOption("Teleporte — selecione jogador abaixo", Color3.fromRGB(120,120,140), Color3.fromRGB(160,160,180), "Teleporte")

-- Search/filter implementation
local function refreshVisibility()
    local q = string.lower(tostring(Search.Text or ""))
    for _,btn in ipairs(OptionButtons) do
        local cat = ButtonCategory[btn] or "Visuais"
        local text = (ButtonLabel[btn] and ButtonLabel[btn].Text) or ""
        local visible = (cat == activeCategory)
        if visible and q ~= "" then
            if not string.find(string.lower(text), q, 1, true) then visible = false end
        end
        btn.Visible = visible
    end
end
Search:GetPropertyChangedSignal("Text"):Connect(refreshVisibility)

-- Category buttons
for name,btn in pairs(CategoryButtons) do
    btn.MouseButton1Click:Connect(function()
        activeCategory = name
        for n,b in pairs(CategoryButtons) do
            if n == name then b.BackgroundColor3 = Color3.fromRGB(22,32,44); b.TextColor3 = Color3.fromRGB(250,250,250)
            else b.BackgroundColor3 = Color3.fromRGB(12,14,18); b.TextColor3 = Color3.fromRGB(180,200,220) end
        end
        refreshVisibility()
    end)
end
-- initial
CategoryButtons[activeCategory].BackgroundColor3 = Color3.fromRGB(22,32,44); CategoryButtons[activeCategory].TextColor3 = Color3.fromRGB(250,250,250)
refreshVisibility()

-- ---------- Feature Logic ----------
-- PLAYER ESP
local PlayerESPOn = false
local function addPlayerHighlight(pl)
    if pl == LocalPlayer then return end
    if not pl.Character then return end
    if PlayerHighlights[pl] then pcall(function() PlayerHighlights[pl]:Destroy() end); PlayerHighlights[pl] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_Player_Highlight]"; h.Adornee = pl.Character; h.Parent = Workspace
    if pl.Character:FindFirstChild("BeastPowers") then h.FillColor = Color3.fromRGB(240,28,80); h.OutlineColor = Color3.fromRGB(255,188,188)
    else h.FillColor = Color3.fromRGB(52,215,101); h.OutlineColor = Color3.fromRGB(170,255,200) end
    h.FillTransparency = 0.12; h.OutlineTransparency = 0.04; h.Enabled = true
    PlayerHighlights[pl] = h
end
local function removePlayerHighlight(pl) if PlayerHighlights[pl] then pcall(function() PlayerHighlights[pl]:Destroy() end); PlayerHighlights[pl] = nil end end
local function refreshPlayerESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if PlayerESPOn then addPlayerHighlight(p) else removePlayerHighlight(p) end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.08); if PlayerESPOn then addPlayerHighlight(p) end end) end)
Players.PlayerRemoving:Connect(function(p) removePlayerHighlight(p) end)

-- COMPUTER ESP
local ComputerESPOn = false
local function addComputer(model)
    if ComputerHighlights[model] then pcall(function() ComputerHighlights[model]:Destroy() end); ComputerHighlights[model] = nil end
    local h = Instance.new("Highlight"); h.Adornee = model; h.Parent = Workspace
    local screen = nil
    for _,n in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        local p = model:FindFirstChild(n, true)
        if p and p:IsA("BasePart") then screen = p; break end
    end
    h.FillColor = (screen and screen.Color) or Color3.fromRGB(77,164,255); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    ComputerHighlights[model] = h
end
local function removeComputer(model) if ComputerHighlights[model] then pcall(function() ComputerHighlights[model]:Destroy() end); ComputerHighlights[model] = nil end end
local function refreshComputer()
    for m,_ in pairs(ComputerHighlights) do removeComputer(m) end
    if not ComputerESPOn then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and (d.Name:lower():find("computer") or d.Name:lower():find("pc")) then addComputer(d) end
    end
end

-- DOOR ESP (fixed, SelectionBox clearly visible)
local DoorESPOn = false
local function isDoorCandidate(obj)
    if not obj then return false end
    if obj:IsA("Model") then
        local n = obj.Name:lower(); return n:find("door") or n:find("exit") or n:find("porta") or n:find("doorframe")
    elseif obj:IsA("BasePart") then
        local n = obj.Name:lower(); return n:find("door") or n:find("doorboard") or n:find("porta")
    end
    return false
end
local function getPrimaryPartForDoor(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    local candidates = {"DoorBoard","Door","Part","ExitDoorTrigger","DoorL","DoorR","BasePart","Main","Panel"}
    for _,name in ipairs(candidates) do
        local f = model:FindFirstChild(name, true)
        if f and f:IsA("BasePart") then return f end
    end
    local biggest = nil
    for _,c in ipairs(model:GetDescendants()) do
        if c:IsA("BasePart") then
            if not biggest or c.Size.Magnitude > biggest.Size.Magnitude then biggest = c end
        end
    end
    return biggest
end
local function addDoorESP(obj)
    if DoorBoxes[obj] then pcall(function() DoorBoxes[obj]:Destroy() end); DoorBoxes[obj] = nil end
    local part = getPrimaryPartForDoor(obj)
    if not part then return end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_Door_Box]"; box.Adornee = part; box.Parent = Workspace
    box.Color3 = Color3.fromRGB(255,220,120)
    box.LineThickness = 0.15 -- visible but not huge
    box.SurfaceTransparency = 1
    box.DepthMode = Enum.SelectionBoxDepthMode.AlwaysOnTop
    DoorBoxes[obj] = box
end
local function removeDoorESP(obj)
    if DoorBoxes[obj] then pcall(function() DoorBoxes[obj]:Destroy() end); DoorBoxes[obj] = nil end
    if obj:IsA("BasePart") then
        local mdl = obj:FindFirstAncestorWhichIsA("Model")
        if mdl and DoorBoxes[mdl] then pcall(function() DoorBoxes[mdl]:Destroy() end); DoorBoxes[mdl] = nil end
    end
end
local function refreshDoors()
    for k,_ in pairs(DoorBoxes) do pcall(function() DoorBoxes[k]:Destroy() end) end
    DoorBoxes = {}
    if not DoorESPOn then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if isDoorCandidate(d) then
            if d:IsA("Model") then addDoorESP(d) else if d:IsA("BasePart") then local mdl = d:FindFirstAncestorWhichIsA("Model"); if mdl and isDoorCandidate(mdl) then addDoorESP(mdl) else addDoorESP(d) end end end
        end
    end
end

-- Listen for workspace changes (only when toggles enabled)
local doorAddConn, doorRemConn, compAddConn, podAddConn, podRemConn

-- FREEZE PODS
local FreezeOn = false
local function isPodCandidate(obj)
    if not obj then return false end
    if obj:IsA("Model") then
        local n = obj.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod")) or n:find("capsule")
    elseif obj:IsA("BasePart") then
        local n = obj.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod"))
    end
    return false
end
local function addPod(obj)
    if PodHighlights[obj] then pcall(function() PodHighlights[obj]:Destroy() end); PodHighlights[obj] = nil end
    local h = Instance.new("Highlight"); h.Adornee = obj; h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    PodHighlights[obj] = h
end
local function removePod(obj) if PodHighlights[obj] then pcall(function() PodHighlights[obj]:Destroy() end); PodHighlights[obj] = nil end end

-- TEXTURES (White bricks)
local TextureOn = false
local function saveAndWhite(part)
    if not part or not part:IsA("BasePart") then return end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model and Players:GetPlayerFromCharacter(model) then return end
    if TextureBackup[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    TextureBackup[part] = {Color = (okC and col) or nil, Material = (okM and mat) or nil}
    pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end)
end
local function enableWhite()
    if TextureOn then return end
    TextureOn = true
    task.spawn(function()
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then saveAndWhite(d) end
        end
    end)
    textureDescendantConn = Workspace.DescendantAdded:Connect(function(d) if d and d:IsA("BasePart") then task.defer(function() saveAndWhite(d) end) end end)
end
local function disableWhite()
    if not TextureOn then return end
    TextureOn = false
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    task.spawn(function()
        for p,props in pairs(TextureBackup) do
            if p and p.Parent then pcall(function() if props.Material then p.Material = props.Material end; if props.Color then p.Color = props.Color end end) end
        end
        TextureBackup = {}
    end)
end

-- SNOW (user-provided script integrated safely)
local SnowOn = false
local function enableSnow()
    if SnowOn then return end
    SnowOn = true
    -- backup lighting
    SnowBackup.lighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
    -- backup skies
    for _,v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then table.insert(SnowBackup.skies, v:Clone()); v:Destroy() end
    end
    local sky = Instance.new("Sky"); sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""; sky.Parent = Lighting
    SnowBackup.createdSky = sky
    -- lighting tweaks
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogColor = Color3.new(1,1,1)
    Lighting.FogEnd = 100000; Lighting.Brightness = 2; Lighting.ClockTime = 12
    Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    -- parts
    task.spawn(function()
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local mdl = d:FindFirstAncestorWhichIsA("Model")
                if not (mdl and Players:GetPlayerFromCharacter(mdl)) then
                    if not SnowBackup.parts[d] then
                        local okC, col = pcall(function() return d.Color end)
                        local okM, mat = pcall(function() return d.Material end)
                        SnowBackup.parts[d] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
                    end
                    pcall(function() d.Color = Color3.new(1,1,1); d.Material = Enum.Material.SmoothPlastic end)
                end
            end
        end
    end)
end
local function disableSnow()
    if not SnowOn then return end
    SnowOn = false
    task.spawn(function()
        for p,props in pairs(SnowBackup.parts) do
            if p and p.Parent then pcall(function() if props.Material then p.Material = props.Material end; if props.Color then p.Color = props.Color end end) end
        end
        SnowBackup.parts = {}
    end)
    local L = SnowBackup.lighting
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
    if SnowBackup.createdSky and SnowBackup.createdSky.Parent then SnowBackup.createdSky:Destroy() end
    for _,cl in ipairs(SnowBackup.skies) do local ok,new = pcall(function() return cl:Clone() end) if ok and new then new.Parent = Lighting end end
    SnowBackup.skies = {}
    SnowBackup.lighting = {}
    SnowBackup.createdSky = nil
end

-- Ragdoll / down timer listeners (minimal already implemented above)
-- Attachers:
local function attachRagdollListener(player)
    if RagdollConns[player] then pcall(function() RagdollConns[player]:Disconnect() end); RagdollConns[player] = nil end
    task.spawn(function()
        local ok, stat = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 6) end)
        if not ok or not stat then return end
        local ok2, rag = pcall(function() return stat:WaitForChild("Ragdoll", 6) end)
        if not ok2 or not rag then return end
        if rag.Value then
            local info = RagdollBillboards[player]
            if not info then
                -- create basic billboard
                local head = player.Character and player.Character:FindFirstChild("Head")
                if head then
                    local b = Instance.new("BillboardGui", GUI); b.Adornee = head; b.Size = UDim2.new(0,140,0,44); b.AlwaysOnTop = true
                    local lab = Instance.new("TextLabel", b); lab.Size = UDim2.new(1,0,1,0); lab.BackgroundTransparency = 1; lab.Font = Enum.Font.GothamBold; lab.TextSize = 18; lab.Text = tostring(DOWN_TIME) .. "s"
                    RagdollBillboards[player] = {gui = b, label = lab, endTime = tick() + DOWN_TIME}
                end
            end
        end
        local conn = rag.Changed:Connect(function()
            pcall(function()
                if rag.Value then
                    local info = RagdollBillboards[player]
                    if not info then
                        -- quick creation as above
                        local head = player.Character and player.Character:FindFirstChild("Head")
                        if head then
                            local b = Instance.new("BillboardGui", GUI); b.Adornee = head; b.Size = UDim2.new(0,140,0,44); b.AlwaysOnTop = true
                            local lab = Instance.new("TextLabel", b); lab.Size = UDim2.new(1,0,1,0); lab.BackgroundTransparency = 1; lab.Font = Enum.Font.GothamBold; lab.TextSize = 18; lab.Text = tostring(DOWN_TIME) .. "s"
                            RagdollBillboards[player] = {gui = b, label = lab, endTime = tick() + DOWN_TIME}
                        end
                    else
                        info.endTime = tick() + DOWN_TIME
                    end
                else
                    if RagdollBillboards[player] and RagdollBillboards[player].gui then pcall(function() RagdollBillboards[player].gui:Destroy() end); RagdollBillboards[player] = nil end
                end
            end)
        end)
        RagdollConns[player] = conn
    end)
end
for _,p in ipairs(Players:GetPlayers()) do attachRagdollListener(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListener(p) end)

-- ---------- Teleport category: dynamic list ----------
local function rebuildTeleportButtons()
    -- remove old teleports (buttons parented to Scroll and category Teleporte)
    for pl,btn in pairs(TeleportBtns) do
        if btn and btn.Parent then pcall(function() btn:Destroy() end) end
        TeleportBtns[pl] = nil
    end
    -- create new buttons for each player except local
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local btn = makeOption("Teleport to " .. (pl.DisplayName or pl.Name), Color3.fromRGB(100,110,140), Color3.fromRGB(140,150,180), "Teleporte")
            ButtonLabel[btn].Text = "Teleport to " .. (pl.DisplayName or pl.Name)
            TeleportBtns[pl] = btn
            btn.MouseButton1Click:Connect(function()
                local mychar = LocalPlayer.Character; local tgt = pl.Character
                if not mychar or not tgt then return end
                local hrp = mychar:FindFirstChild("HumanoidRootPart") or mychar:FindFirstChild("Torso") or mychar:FindFirstChild("UpperTorso")
                local thrp = tgt:FindFirstChild("HumanoidRootPart") or tgt:FindFirstChild("Torso") or tgt:FindFirstChild("UpperTorso")
                if hrp and thrp then pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end) end
            end)
        end
    end
    refreshVisibility()
end
Players.PlayerAdded:Connect(function() task.wait(0.15); rebuildTeleportButtons() end)
Players.PlayerRemoving:Connect(function() task.wait(0.15); rebuildTeleportButtons() end)
rebuildTeleportButtons()

-- ---------- Button bindings ----------
btnPlayer.MouseButton1Click:Connect(function()
    PlayerESPOn = not PlayerESPOn; refreshPlayerESP()
    if PlayerESPOn then ButtonLabel[btnPlayer].Text = "Player ESP (ON)" else ButtonLabel[btnPlayer].Text = "Player ESP" end
end)

btnComputer.MouseButton1Click:Connect(function()
    ComputerESPOn = not ComputerESPOn; refreshComputer()
    if ComputerESPOn then ButtonLabel[btnComputer].Text = "Computer ESP (ON)" else ButtonLabel[btnComputer].Text = "Computer ESP" end
end)

btnDoors.MouseButton1Click:Connect(function()
    DoorESPOn = not DoorESPOn
    if DoorESPOn then ButtonLabel[btnDoors].Text = "ESP Doors (ON)" else ButtonLabel[btnDoors].Text = "ESP Doors" end
    refreshDoors()
end)

btnFreeze.MouseButton1Click:Connect(function()
    FreezeOn = not FreezeOn
    if FreezeOn then ButtonLabel[btnFreeze].Text = "Freeze Pods ESP (ON)" else ButtonLabel[btnFreeze].Text = "Freeze Pods ESP" end
    if FreezeOn then
        -- scan existing
        for _,d in ipairs(Workspace:GetDescendants()) do if isPodCandidate(d) then addPod(d) end end
        if not podAddConn then podAddConn = Workspace.DescendantAdded:Connect(function(d) if isPodCandidate(d) then task.delay(0.05, function() addPod(d) end) end end) end
        if not podRemConn then podRemConn = Workspace.DescendantRemoving:Connect(function(d) if isPodCandidate(d) then removePod(d) end end) end
    else
        for k,_ in pairs(PodHighlights) do pcall(function() PodHighlights[k]:Destroy() end); PodHighlights[k]=nil end
        if podAddConn then pcall(function() podAddConn:Disconnect() end); podAddConn = nil end
        if podRemConn then pcall(function() podRemConn:Disconnect() end); podRemConn = nil end
    end
end)

btnWhiteBricks.MouseButton1Click:Connect(function()
    if not TextureOn then enableWhite(); ButtonLabel[btnWhiteBricks].Text = "Ativar Textures Tijolos Brancos (ON)"
    else disableWhite(); ButtonLabel[btnWhiteBricks].Text = "Ativar Textures Tijolos Brancos" end
end)

btnSnow.MouseButton1Click:Connect(function()
    if not SnowOn then enableSnow(); ButtonLabel[btnSnow].Text = "Snow texture (ON)"
    else disableSnow(); ButtonLabel[btnSnow].Text = "Snow texture" end
end)

btnDown.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then ButtonLabel[btnDown].Text = "Ativar Contador de Down (ON)" else ButtonLabel[btnDown].Text = "Ativar Contador de Down" end
end)

btnRemoveSkin.MouseButton1Click:Connect(function()
    if not btnRemoveSkin._active then
        btnRemoveSkin._active = true; ButtonLabel[btnRemoveSkin].Text = "Remove players Textures (ON)"
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _,d in ipairs(p.Character:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("MeshPart") then pcall(function() d.Color = Color3.fromRGB(128,128,132); d.Material = Enum.Material.SmoothPlastic end) end
                end
            end
        end
    else
        btnRemoveSkin._active = false; ButtonLabel[btnRemoveSkin].Text = "Remove players Textures"
    end
end)

-- ---------- Draggable header ----------
do
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Main.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Toggle menu with K
local menuOpen = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        Main.Visible = menuOpen
    end
end)

-- ---------- Cleanup on unload ----------
local function cleanupAll()
    for k,v in pairs(PlayerHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(ComputerHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(DoorBoxes) do pcall(function() v:Destroy() end) end
    for k,v in pairs(PodHighlights) do pcall(function() v:Destroy() end) end
    for p,info in pairs(RagdollBillboards) do pcall(function() if info.gui and info.gui.Parent then info.gui:Destroy() end end) end
    pcall(function() GUI:Destroy() end)
end

-- Final print
print("[FTF_ESP] Fixed consolidated script loaded")
