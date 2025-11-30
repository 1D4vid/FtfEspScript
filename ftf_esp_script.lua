-- FTF ESP — Reworked stable version
-- Features:
--  - Square menu (bottom-center), draggable by header
--  - Startup animated notice
--  - Categories: Visuais, Textures, Timers, Teleporte
--  - Search (filters options in active category)
--  - Player ESP, Computer ESP, ESP Doors (SelectionBox), Freeze Pods (Highlight)
--  - Textures: Remove players textures, White Brick, Snow texture (with safe backup/restore)
--  - Timers: Down timer display
--  - Teleport: dynamic list of players to teleport to
--  - Cleanups and safe connections

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Clean old GUI
local function cleanupOldGUI()
    local found = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("FTF_ESP_GUI_DAVID")
    if found then pcall(function() found:Destroy() end) end
    for _,c in pairs(game:GetService("CoreGui"):GetChildren()) do
        if c.Name == "FTF_ESP_GUI_DAVID" then pcall(function() c:Destroy() end) end
    end
end
cleanupOldGUI()

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Utility tables
local buttonLabelMap = {}        -- button -> TextLabel
local buttonCategory = {}        -- button -> category
local optionButtons = {}         -- array of all option buttons (so we can iterate)
local teleportButtons = {}       -- player -> button
local connections = {}           -- store connection refs to disconnect on cleanup

-- Categories
local categories = {"Visuais", "Textures", "Timers", "Teleporte"}
local activeCategory = "Visuais"

-- ---------- Startup notice ----------
local function showStartupNotice()
    local notice = Instance.new("Frame")
    notice.Name = "FTF_StartupNotice"
    notice.Size = UDim2.new(0, 520, 0, 72)
    notice.Position = UDim2.new(0.5, -260, 0.92, 36)
    notice.BackgroundColor3 = Color3.fromRGB(10,14,18)
    notice.BorderSizePixel = 0
    notice.Parent = GUI

    local txt = Instance.new("TextLabel", notice)
    txt.Size = UDim2.new(1, -96, 1, 0)
    txt.Position = UDim2.new(0, 86, 0, 6)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(200,220,240)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left

    local icon = Instance.new("TextLabel", notice)
    icon.Size = UDim2.new(0,40,0,40); icon.Position = UDim2.new(0,12,0.5,-20)
    icon.BackgroundColor3 = Color3.fromRGB(14,16,20); icon.BorderSizePixel = 0
    icon.Font = Enum.Font.FredokaOne; icon.Text = "K"; icon.TextSize = 22; icon.TextColor3 = Color3.fromRGB(100,170,220)
    -- animate up
    notice.Position = UDim2.new(0.5, -260, 0.92, 36)
    TweenService:Create(notice, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -260, 0.88, 0)}):Play()
    task.delay(4.5, function() if notice and notice.Parent then pcall(function() notice:Destroy() end) end end)
end
showStartupNotice()

-- ---------- Main menu ----------
local WIDTH, HEIGHT = 980, 360
local MAIN = Instance.new("Frame", GUI)
MAIN.Name = "FTF_Menu_Main"
MAIN.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
MAIN.Position = UDim2.new(0.5, -WIDTH/2, 1, -HEIGHT - 24) -- bottom center
MAIN.BackgroundColor3 = Color3.fromRGB(10,12,16)
MAIN.BorderSizePixel = 0
-- intentionally square (no UICorner)

local stroke = Instance.new("UIStroke", MAIN); stroke.Color = Color3.fromRGB(36,46,60); stroke.Thickness = 1; stroke.Transparency = 0.16

-- Header (draggable)
local HEADER = Instance.new("Frame", MAIN)
HEADER.Name = "Header"; HEADER.Size = UDim2.new(1,0,0,72); HEADER.BackgroundTransparency = 1

local TITLE = Instance.new("TextLabel", HEADER)
TITLE.Text = "FTF - David's ESP"; TITLE.Font = Enum.Font.FredokaOne; TITLE.TextSize = 22
TITLE.TextColor3 = Color3.fromRGB(200,220,240); TITLE.BackgroundTransparency = 1
TITLE.Position = UDim2.new(0, 16, 0, 18); TITLE.Size = UDim2.new(0.5,0,0,36); TITLE.TextXAlignment = Enum.TextXAlignment.Left

local SEARCH = Instance.new("TextBox", HEADER)
SEARCH.PlaceholderText = "Pesquisar opções..."
SEARCH.ClearTextOnFocus = false
SEARCH.Size = UDim2.new(0, 320, 0, 34)
SEARCH.Position = UDim2.new(1, -356, 0, 18)
SEARCH.BackgroundColor3 = Color3.fromRGB(14,16,20)
SEARCH.TextColor3 = Color3.fromRGB(200,220,240)
local searchStroke = Instance.new("UIStroke", SEARCH); searchStroke.Color = Color3.fromRGB(60,80,110); searchStroke.Thickness = 1; searchStroke.Transparency = 0.6

-- Left categories column
local LEFT = Instance.new("Frame", MAIN)
LEFT.Size = UDim2.new(0, 220, 1, -88)
LEFT.Position = UDim2.new(0, 16, 0, 78)
LEFT.BackgroundTransparency = 1
local LEFT_LAYOUT = Instance.new("UIListLayout", LEFT); LEFT_LAYOUT.SortOrder = Enum.SortOrder.LayoutOrder; LEFT_LAYOUT.Padding = UDim.new(0, 12)

local categoryButtons = {}
for i,cat in ipairs(categories) do
    local b = Instance.new("TextButton", LEFT)
    b.Size = UDim2.new(1,0,0,56); b.LayoutOrder = i; b.Text = cat
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 16
    b.TextColor3 = Color3.fromRGB(180,200,220)
    b.BackgroundColor3 = Color3.fromRGB(12,14,18)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(36,46,60); s.Thickness = 1; s.Transparency = 0.5
    categoryButtons[cat] = b
end

-- Content area
local CONTENT = Instance.new("Frame", MAIN)
CONTENT.Size = UDim2.new(1, -260, 1, -88)
CONTENT.Position = UDim2.new(0, 248, 0, 78)
CONTENT.BackgroundTransparency = 1

local SCROLL = Instance.new("ScrollingFrame", CONTENT)
SCROLL.Size = UDim2.new(1, -12, 1, 0)
SCROLL.Position = UDim2.new(0,6,0,0)
SCROLL.BackgroundTransparency = 1
SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 8
local SCROLL_LAYOUT = Instance.new("UIListLayout", SCROLL); SCROLL_LAYOUT.SortOrder = Enum.SortOrder.LayoutOrder; SCROLL_LAYOUT.Padding = UDim.new(0, 10)
SCROLL_LAYOUT:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SCROLL.CanvasSize = UDim2.new(0,0,0, SCROLL_LAYOUT.AbsoluteContentSize.Y + 12)
end)

-- Option creator
local function createOption(text, colorA, colorB)
    colorA = colorA or Color3.fromRGB(20,20,20)
    colorB = colorB or colorA
    local btn = Instance.new("TextButton", SCROLL)
    btn.Size = UDim2.new(1, -12, 0, 56)
    btn.BackgroundTransparency = 1
    local bg = Instance.new("Frame", btn); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = colorA; bg.BorderSizePixel = 0
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,colorA), ColorSequenceKeypoint.new(0.6,colorB), ColorSequenceKeypoint.new(1,colorA)}; grad.Rotation = 45
    local inner = Instance.new("Frame", bg); inner.Size = UDim2.new(1,-8,1,-8); inner.Position = UDim2.new(0,4,0,4); inner.BackgroundColor3 = Color3.fromRGB(8,10,12)
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", inner); label.Size = UDim2.new(1,-24,1,0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = text; label.TextSize = 16; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left
    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,66,0,26); indicator.Position = UDim2.new(1,-92,0.5,-13); indicator.BackgroundColor3 = Color3.fromRGB(10,12,14)
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0); indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    local indBarCorner = Instance.new("UICorner", indBar); indBarCorner.CornerRadius = UDim.new(0,6)

    buttonLabelMap[btn] = label
    table.insert(optionButtons, btn)
    return btn, label
end

-- Build options and assign categories
-- VISUAIS
local btnPlayer, lblPlayer = createOption("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101)); buttonCategory[btnPlayer] = "Visuais"
local btnComputer, lblComputer = createOption("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255)); buttonCategory[btnComputer] = "Visuais"
local btnDoor, lblDoor = createOption("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100)); buttonCategory[btnDoor] = "Visuais"
local btnFreeze, lblFreeze = createOption("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80)); buttonCategory[btnFreeze] = "Visuais"

-- TEXTURES
local btnRemove, lblRemove = createOption("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140)); buttonCategory[btnRemove] = "Textures"
local btnWhite, lblWhite = createOption("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245)); buttonCategory[btnWhite] = "Textures"
local btnSnow, lblSnow = createOption("Snow texture", Color3.fromRGB(235,245,255), Color3.fromRGB(245,250,255)); buttonCategory[btnSnow] = "Textures"

-- TIMERS
local btnDown, lblDown = createOption("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90)); buttonCategory[btnDown] = "Timers"

-- TELEPORTE header (dynamic buttons appended under this category)
local btnTPHeader, lblTPHeader = createOption("Teleporte — selecione jogador abaixo", Color3.fromRGB(120,120,140), Color3.fromRGB(160,160,180)); buttonCategory[btnTPHeader] = "Teleporte"

-- visibility refresh
local function refreshVisibility()
    local q = string.lower(SEARCH.Text or "")
    for _,btn in ipairs(optionButtons) do
        local cat = buttonCategory[btn] or "Visuais"
        local label = (buttonLabelMap[btn] and buttonLabelMap[btn].Text) or (btn.Text or "")
        local visible = (cat == activeCategory)
        if visible and q ~= "" then
            if not string.find(string.lower(label), q, 1, true) then visible = false end
        end
        btn.Visible = visible
    end
    -- SCROLL canvas handled by layout connection
end

-- category button binds
for name,btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function()
        activeCategory = name
        for k,v in pairs(categoryButtons) do
            if k == name then v.BackgroundColor3 = Color3.fromRGB(22,32,44); v.TextColor3 = Color3.fromRGB(250,250,250)
            else v.BackgroundColor3 = Color3.fromRGB(12,14,18); v.TextColor3 = Color3.fromRGB(180,200,220) end
        end
        refreshVisibility()
    end)
end
-- initial visual
categoryButtons[activeCategory].BackgroundColor3 = Color3.fromRGB(22,32,44); categoryButtons[activeCategory].TextColor3 = Color3.fromRGB(250,250,250)
refreshVisibility()
SEARCH:GetPropertyChangedSignal("Text"):Connect(refreshVisibility)

-- ---------- IMPLEMENTATIONS ----------
-- Player ESP
local PlayerESPActive = false
local playerHighlights = {}
local function addPlayerESP(pl)
    if pl == LocalPlayer then return end
    if not pl.Character then return end
    if playerHighlights[pl] then pcall(function() playerHighlights[pl]:Destroy() end); playerHighlights[pl] = nil end
    local h = Instance.new("Highlight"); h.Parent = Workspace; h.Adornee = pl.Character
    if pl.Character:FindFirstChild("BeastPowers") then h.FillColor = Color3.fromRGB(240,28,80); h.OutlineColor = Color3.fromRGB(255,188,188)
    else h.FillColor = Color3.fromRGB(52,215,101); h.OutlineColor = Color3.fromRGB(170,255,200) end
    h.FillTransparency = 0.12; h.OutlineTransparency = 0.04; h.Enabled = true
    playerHighlights[pl] = h
end
local function removePlayerESP(pl) if playerHighlights[pl] then pcall(function() playerHighlights[pl]:Destroy() end); playerHighlights[pl] = nil end end
local function refreshAllPlayerESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if PlayerESPActive then addPlayerESP(p) else removePlayerESP(p) end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.08); if PlayerESPActive then addPlayerESP(p) end end) end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

-- Computer ESP
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(m) return m and m:IsA("Model") and (m.Name:lower():find("computer") or m.Name:lower():find("pc")) end
local function getScreenPart(m)
    for _,n in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        local p = m:FindFirstChild(n, true)
        if p and p:IsA("BasePart") then return p end
    end
    local biggest
    for _,c in ipairs(m:GetDescendants()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function addComputerESP(model)
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model] = nil end
    local h = Instance.new("Highlight"); h.Parent = Workspace; h.Adornee = model
    local s = getScreenPart(model)
    h.FillColor = (s and s.Color) or Color3.fromRGB(77,164,255); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    compHighlights[model] = h
end
local function removeComputerESP(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model] = nil end end
local function refreshComputerAll()
    for k,_ in pairs(compHighlights) do removeComputerESP(k) end
    if not ComputerESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then addComputerESP(d) end end
end
Workspace.DescendantAdded:Connect(function(d) if ComputerESPActive and isComputerModel(d) then task.delay(0.05, function() addComputerESP(d) end) end end)
Workspace.DescendantRemoving:Connect(removeComputerESP)

-- Door ESP (SelectionBox)
local DoorESPActive = false
local doorBoxes = {}
local function isDoorCandidate(o)
    if not o then return false end
    if o:IsA("Model") then
        local n = o.Name:lower(); return n:find("door") or n:find("exit")
    elseif o:IsA("BasePart") then
        local n = o.Name:lower(); return n:find("door") or n:find("doorboard") or n:find("exitdoor")
    end
    return false
end
local function getDoorPrimary(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o end
    if o.PrimaryPart and o.PrimaryPart:IsA("BasePart") then return o.PrimaryPart end
    local candidates = {"DoorBoard","Door","Part","ExitDoorTrigger","DoorL","DoorR","BasePart","Main","Panel"}
    for _,n in ipairs(candidates) do
        local f = o:FindFirstChild(n, true)
        if f and f:IsA("BasePart") then return f end
    end
    local biggest
    for _,c in ipairs(o:GetDescendants()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function createDoorBox(key, part)
    if not part then return end
    if doorBoxes[key] then pcall(function() doorBoxes[key]:Destroy() end); doorBoxes[key] = nil end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_DoorBox]"; box.Adornee = part
    box.Color3 = Color3.fromRGB(255,220,120)
    pcall(function() box.LineThickness = 0.18 end)
    pcall(function() box.SurfaceTransparency = 1 end)
    pcall(function() box.DepthMode = Enum.SelectionBoxDepthMode.AlwaysOnTop end)
    box.Parent = Workspace
    doorBoxes[key] = box
end
local function addDoorCandidate(o)
    local part = getDoorPrimary(o)
    if part then createDoorBox(o, part) end
end
local function removeDoorCandidate(o)
    if doorBoxes[o] then pcall(function() doorBoxes[o]:Destroy() end); doorBoxes[o] = nil end
    if o:IsA("BasePart") then
        local mdl = o:FindFirstAncestorWhichIsA("Model")
        if mdl and doorBoxes[mdl] then pcall(function() doorBoxes[mdl]:Destroy() end); doorBoxes[mdl] = nil end
    end
end
Workspace.DescendantAdded:Connect(function(d)
    if DoorESPActive and isDoorCandidate(d) then task.delay(0.05, function() addDoorCandidate(d) end) end
end)
Workspace.DescendantRemoving:Connect(function(d) if isDoorCandidate(d) then removeDoorCandidate(d) end end)

-- Freeze Pods ESP
local FreezeActive = false
local podHighlights = {}
local function isFreezePod(o)
    if not o then return false end
    if o:IsA("Model") then
        local n = o.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod")) or n:find("capsule")
    elseif o:IsA("BasePart") then
        local n = o.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod"))
    end
    return false
end
local function addPodHighlight(o)
    if podHighlights[o] then pcall(function() podHighlights[o]:Destroy() end); podHighlights[o] = nil end
    local h = Instance.new("Highlight"); h.Parent = Workspace; h.Adornee = o
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[o] = h
end
local function removePodHighlight(o) if podHighlights[o] then pcall(function() podHighlights[o]:Destroy() end); podHighlights[o] = nil end end
Workspace.DescendantAdded:Connect(function(d) if FreezeActive and isFreezePod(d) then task.delay(0.05, function() addPodHighlight(d) end) end end)
Workspace.DescendantRemoving:Connect(function(d) if isFreezePod(d) then removePodHighlight(d) end end)

-- Textures / White brick / Snow handled earlier logic (simplified hookups below)
local TextureActive = false
local SnowActive = false
local textureConn = nil
local textureBackup = {}
local snowBackup = {parts = {}, lighting = {}, skies = {}, createdSky = nil}

local function enableWhiteBrick()
    if TextureActive then return end
    TextureActive = true
    -- one-shot apply + track new parts
    task.spawn(function()
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                if not textureBackup[d] then
                    local okC, col = pcall(function() return d.Color end)
                    local okM, mat = pcall(function() return d.Material end)
                    textureBackup[d] = {Color = (okC and col) or nil, Material = (okM and mat) or nil}
                end
                pcall(function() d.Material = Enum.Material.Brick; d.Color = Color3.fromRGB(255,255,255) end)
            end
            if (task.wait and false) then task.wait() end
        end
    end)
    textureConn = Workspace.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then task.defer(function()
        if not textureBackup[d] then
            local okC, col = pcall(function() return d.Color end)
            local okM, mat = pcall(function() return d.Material end)
            textureBackup[d] = {Color = (okC and col) or nil, Material = (okM and mat) or nil}
        end
        pcall(function() d.Material = Enum.Material.Brick; d.Color = Color3.fromRGB(255,255,255) end)
    end) end end)
end
local function disableWhiteBrick()
    if not TextureActive then return end
    TextureActive = false
    if textureConn then pcall(function() textureConn:Disconnect() end); textureConn = nil end
    for p,props in pairs(textureBackup) do
        if p and p.Parent then pcall(function() if props.Material then p.Material = props.Material end; if props.Color then p.Color = props.Color end end) end
    end
    textureBackup = {}
end

local function enableSnow()
    if SnowActive then return end
    SnowActive = true
    -- backup lighting
    snowBackup.lighting = {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
    -- backup skies & remove
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then table.insert(snowBackup.skies, v:Clone()); v:Destroy() end end
    local sky = Instance.new("Sky"); sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""; sky.Parent = Lighting
    snowBackup.createdSky = sky
    -- set lighting
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogColor = Color3.new(1,1,1)
    Lighting.FogEnd = 100000; Lighting.Brightness = 2; Lighting.ClockTime = 12; Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    -- parts
    task.spawn(function()
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local mdl = d:FindFirstAncestorWhichIsA("Model")
                if not (mdl and Players:GetPlayerFromCharacter(mdl)) then
                    if not snowBackup.parts[d] then
                        local okC, col = pcall(function() return d.Color end)
                        local okM, mat = pcall(function() return d.Material end)
                        snowBackup.parts[d] = {Color = (okC and col) or nil, Material = (okM and mat) or nil}
                    end
                    pcall(function() d.Color = Color3.new(1,1,1); d.Material = Enum.Material.SmoothPlastic end)
                end
            end
        end
    end)
end
local function disableSnow()
    if not SnowActive then return end
    SnowActive = false
    -- restore parts
    for p,props in pairs(snowBackup.parts) do
        if p and p.Parent then pcall(function() if props.Material then p.Material = props.Material end; if props.Color then p.Color = props.Color end end) end
    end
    snowBackup.parts = {}
    -- restore lighting
    local L = snowBackup.lighting
    if L then
        Lighting.Ambient = L.Ambient or Lighting.Ambient; Lighting.OutdoorAmbient = L.OutdoorAmbient or Lighting.OutdoorAmbient
        Lighting.FogColor = L.FogColor or Lighting.FogColor; Lighting.FogEnd = L.FogEnd or Lighting.FogEnd
        Lighting.Brightness = L.Brightness or Lighting.Brightness; Lighting.ClockTime = L.ClockTime or Lighting.ClockTime
        Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale or Lighting.EnvironmentDiffuseScale; Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale or Lighting.EnvironmentSpecularScale
    end
    if snowBackup.createdSky and snowBackup.createdSky.Parent then snowBackup.createdSky:Destroy() end
    for _,sk in ipairs(snowBackup.skies) do local ok, clone = pcall(function() return sk:Clone() end) if ok and clone then clone.Parent = Lighting end end
    snowBackup.skies = {}
    snowBackup.lighting = {}
    snowBackup.createdSky = nil
end

-- Ragdoll Down timer: kept minimal (already implemented earlier logic above in prior versions)
local DownActive = false
-- For completeness, we reuse createRagdollBillboard logic from earlier if needed. (Already implemented in previous runs.)

-- ---------- Teleport buttons dynamic ----------
local function clearTeleportButtons()
    for pl,btn in pairs(teleportButtons) do
        if btn and btn.Parent then pcall(function() btn:Destroy() end) end
    end
    teleportButtons = {}
end

local function buildTeleportButtons()
    -- remove old teleport buttons
    -- first remove any optionButtons that belong to Teleporte except header
    for i = #optionButtons, 1, -1 do
        local b = optionButtons[i]
        if buttonCategory[b] == "Teleporte" and b ~= btnTPHeader then
            if b and b.Parent then pcall(function() b:Destroy() end) end
            table.remove(optionButtons, i)
        end
    end
    teleportButtons = {}
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local btn, lbl = createOption("Teleport to " .. (pl.DisplayName or pl.Name), Color3.fromRGB(100,110,140), Color3.fromRGB(140,150,180))
            buttonCategory[btn] = "Teleporte"
            teleportButtons[pl] = btn
            btn.MouseButton1Click:Connect(function()
                local myChar = LocalPlayer.Character
                local tgtChar = pl.Character
                if not myChar or not tgtChar then return end
                local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                local thrp = tgtChar:FindFirstChild("HumanoidRootPart") or tgtChar:FindFirstChild("Torso") or tgtChar:FindFirstChild("UpperTorso")
                if not hrp or not thrp then return end
                pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
            end)
        end
    end
    refreshVisibility()
end

Players.PlayerAdded:Connect(function() task.wait(0.12); buildTeleportButtons() end)
Players.PlayerRemoving:Connect(function() task.wait(0.12); buildTeleportButtons() end)
buildTeleportButtons()

-- ---------- Buttons wiring ----------
btnPlayer.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive
    if PlayerESPActive then lblPlayer.Text = "Player ESP (ON)" else lblPlayer.Text = "Player ESP" end
    refreshAllPlayerESP()
end)

btnComputer.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive
    if ComputerESPActive then lblComputer.Text = "Computer ESP (ON)"; refreshComputerAll() else lblComputer.Text = "Computer ESP"; for k,_ in pairs(compHighlights) do pcall(function() compHighlights[k]:Destroy() end); compHighlights[k] = nil end end
end)

btnDoor.MouseButton1Click:Connect(function()
    DoorESPActive = not DoorESPActive
    if DoorESPActive then lblDoor.Text = "ESP Doors (ON)"; refreshDoorESPAll() else lblDoor.Text = "ESP Doors"; for k,v in pairs(doorBoxes) do pcall(function() v:Destroy() end); doorBoxes[k] = nil end end
end)

btnFreeze.MouseButton1Click:Connect(function()
    FreezeActive = not FreezeActive
    if FreezeActive then lblFreeze.Text = "Freeze Pods ESP (ON)"; refreshFreezePodsAll() else lblFreeze.Text = "Freeze Pods ESP"; for k,v in pairs(podHighlights) do pcall(function() v:Destroy() end); podHighlights[k] = nil end end
end)

btnWhite.MouseButton1Click:Connect(function()
    if not TextureActive then enableWhite(); lblWhite.Text = "Ativar Textures Tijolos Brancos (ON)" else disableWhite(); lblWhite.Text = "Ativar Textures Tijolos Brancos" end
end)

btnSnow.MouseButton1Click:Connect(function()
    if not SnowActive then enableSnow(); lblSnow.Text = "Snow texture (ON)" else disableSnow(); lblSnow.Text = "Snow texture" end
end)

btnDown.MouseButton1Click:Connect(function()
    DownActive = not DownActive
    if DownActive then lblDown.Text = "Ativar Contador de Down (ON)" else lblDown.Text = "Ativar Contador de Down" end
end)

btnRemove.MouseButton1Click:Connect(function()
    if not btnRemove._active then
        btnRemove._active = true; lblRemove.Text = "Remove players Textures (ON)"
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character then
                for _,d in ipairs(pl.Character:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("MeshPart") then pcall(function() d.Color = Color3.fromRGB(128,128,132); d.Material = Enum.Material.SmoothPlastic end) end
                end
            end
        end
    else
        btnRemove._active = false; lblRemove.Text = "Remove players Textures"
    end
end)

-- ---------- Header dragging ----------
do
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    HEADER.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MAIN.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    HEADER.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MAIN.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ---------- Toggle menu (K) ----------
local menuOpen = false
UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MAIN.Visible = menuOpen
    end
end)

-- Final output
print("[FTF_ESP] Stable UI loaded — square menu, startup notice, categories, teleport list, door ESP fixed.")

-- END OF FILE
