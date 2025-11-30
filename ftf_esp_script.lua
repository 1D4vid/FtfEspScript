--[[
FTF ESP Script — Versão completa e pronta (PT-BR)
Funcionalidades:
- ESP Jogadores (Highlight + NameTags)
- ESP Computadores (cor da tela)
- Contador de down (ragdoll) 28s com UI inferior
- Toggle Skin Cinza (aplica e restaura)
- Toggle Texture Tijolos Brancos (aplica/restaura, ignora personagens)
- Toggle Freeze Pods (interno, robusto para cápsulas do Flee The Facility)
- UI futurista, processamento em lotes para evitar travar, proteções com pcall/task.spawn
Use K para abrir/fechar o menu.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Local player + PlayerGui
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Cleanup GUIs antigas
pcall(function()
    for _, v in pairs(PlayerGui:GetChildren()) do
        if v.Name == "FTF_ESP_GUI_DAVID" or v.Name == "FTF_ESP_Error" then v:Destroy() end
    end
end)

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = PlayerGui

-- map para acessar labels dos botões
local buttonLabelMap = {}

-- ---------- Startup notice ----------
local function createStartupNotice(duration, width, height)
    duration = duration or 6
    width = width or 380
    height = height or 68

    local notice = Instance.new("Frame")
    notice.Name = "FTF_StartupNotice_DAVID"
    notice.Size = UDim2.new(0, width, 0, height)
    notice.Position = UDim2.new(0.5, -width/2, 0.92, 6)
    notice.AnchorPoint = Vector2.new(0, 0)
    notice.BackgroundTransparency = 1
    notice.Parent = GUI

    local panel = Instance.new("Frame", notice)
    panel.Name = "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(55,140,220); stroke.Thickness = 1.2; stroke.Transparency = 0.28

    local iconBg = Instance.new("Frame", panel)
    iconBg.Size = UDim2.new(0,36,0,36); iconBg.Position = UDim2.new(0,16,0.5,-18)
    iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26); iconBg.BorderSizePixel = 0
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0,10)
    local iconLabel = Instance.new("TextLabel", iconBg)
    iconLabel.Size = UDim2.new(1,-6,1,-6); iconLabel.Position = UDim2.new(0,3,0,3)
    iconLabel.BackgroundTransparency = 1; iconLabel.Font = Enum.Font.FredokaOne; iconLabel.Text = "K"
    iconLabel.TextColor3 = Color3.fromRGB(100,170,220); iconLabel.TextSize = 20

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -96, 1, -8); txt.Position = UDim2.new(0,76,0,4)
    txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.Text = 'Clique na letra "K" para ativar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left; txt.TextWrapped = true

    local hint = Instance.new("TextLabel", panel)
    hint.Size = UDim2.new(1, -96, 0, 16); hint.Position = UDim2.new(0,76,1,-22)
    hint.BackgroundTransparency = 1; hint.Font = Enum.Font.Gotham; hint.TextSize = 11
    hint.TextColor3 = Color3.fromRGB(120,140,170); hint.Text = "Pressione novamente para fechar"; hint.TextXAlignment = Enum.TextXAlignment.Left

    pcall(function()
        TweenService:Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.0}):Play()
    end)

    task.delay(duration, function()
        pcall(function() if notice and notice.Parent then notice:Destroy() end end)
    end)
end

createStartupNotice()

-- ---------- Main menu frame (UI) ----------
local gWidth, gHeight = 360, 460
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
Frame.Position = UDim2.new(0.5, -gWidth/2, 0.17, 0)
Frame.BackgroundColor3 = Color3.fromRGB(8,10,14)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Visible = false
local menuCorner = Instance.new("UICorner", Frame); menuCorner.CornerRadius = UDim.new(0,8)

local Accent = Instance.new("Frame", Frame)
Accent.Size = UDim2.new(0,8,1,0); Accent.Position = UDim2.new(0,4,0,0)
Accent.BackgroundColor3 = Color3.fromRGB(49,157,255); Accent.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Frame)
Title.Text = "FTF - David's ESP"; Title.Font = Enum.Font.FredokaOne; Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(170,200,230); Title.Size = UDim2.new(1, -32, 0, 36); Title.Position = UDim2.new(0,28,0,8)
Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local Line = Instance.new("Frame", Frame)
Line.BackgroundColor3 = Color3.fromRGB(20,28,36); Line.Position = UDim2.new(0,0,0,48); Line.Size = UDim2.new(1,0,0,2)

local function createFuturisticButton(txt, ypos, c1, c2)
    local btnOuter = Instance.new("TextButton", Frame)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1; btnOuter.BorderSizePixel = 0; btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -36, 0, 50); btnOuter.Position = UDim2.new(0, 18, 0, ypos)
    btnOuter.Text = ""; btnOuter.ClipsDescendants = true

    local bg = Instance.new("Frame", btnOuter); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1; bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,12)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation = 45

    local inner = Instance.new("Frame", bg); inner.Name = "Inner"; inner.Size = UDim2.new(1, -8, 1, -10); inner.Position = UDim2.new(0,4,0,5)
    inner.BackgroundColor3 = Color3.fromRGB(12,14,18); inner.BorderSizePixel = 0
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,10)
    local innerStroke = Instance.new("UIStroke", inner); innerStroke.Color = Color3.fromRGB(28,36,46); innerStroke.Thickness = 1; innerStroke.Transparency = 0.2

    local shine = Instance.new("Frame", inner); shine.Size = UDim2.new(1,0,0.28,0); shine.BackgroundTransparency = 0.9; shine.BackgroundColor3 = Color3.fromRGB(30,45,60)
    local shineCorner = Instance.new("UICorner", shine); shineCorner.CornerRadius = UDim.new(0,10)

    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, -4); label.Position = UDim2.new(0,12,0,2)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = txt
    label.TextSize = 15; label.TextColor3 = Color3.fromRGB(170,195,215); label.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,50,0,26); indicator.Position = UDim2.new(1, -64, 0.5, -13)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14); indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,10)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.5,0); indBar.Position = UDim2.new(0.06,0,0.25,0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220); local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0,8)

    local hoverTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    btnOuter.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(grad, hoverTweenInfo, {Rotation = 135}):Play()
            TweenService:Create(indBar, hoverTweenInfo, {Size = UDim2.new(0.66,0,0.66,0), Position = UDim2.new(0.16,0,0.17,0)}):Play()
            TweenService:Create(label, hoverTweenInfo, {TextColor3 = Color3.fromRGB(220,235,245)}):Play()
        end)
    end)
    btnOuter.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(grad, hoverTweenInfo, {Rotation = 45}):Play()
            TweenService:Create(indBar, hoverTweenInfo, {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
            TweenService:Create(label, hoverTweenInfo, {TextColor3 = Color3.fromRGB(170,195,215)}):Play()
        end)
    end)
    btnOuter.MouseButton1Down:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.09), {Position = UDim2.new(0,6,0,6)}):Play() end) end)
    btnOuter.MouseButton1Up:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.12), {Position = UDim2.new(0,4,0,5)}):Play() end) end)

    buttonLabelMap[btnOuter] = label
    return btnOuter, indBar, label
end

-- Botões
local PlayerBtn, PlayerIndicator = createFuturisticButton("Ativar ESP Jogadores", 70, Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101))
local CompBtn, CompIndicator   = createFuturisticButton("Ativar Destacar Computadores", 136, Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255))
local DownTimerBtn, DownIndicator = createFuturisticButton("Ativar Contador de Down", 202, Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90))
local GraySkinBtn, GraySkinIndicator = createFuturisticButton("Ativar Skin Cinza", 268, Color3.fromRGB(80,80,90), Color3.fromRGB(130,130,140))
local TextureBtn, TextureIndicator = createFuturisticButton("Ativar Texture Tijolos Brancos", 334, Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245))
local FreezeBtn, FreezeIndicator = createFuturisticButton("Ativar Freeze Pods", 394, Color3.fromRGB(200,140,220), Color3.fromRGB(220,180,240))

-- Botão fechar e draggable
local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Size = UDim2.new(0,36,0,36); CloseBtn.Position = UDim2.new(1,-44,0,8)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(140,160,180); CloseBtn.AutoButtonColor = false
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
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.K then
        MenuOpen = not MenuOpen; Frame.Visible = MenuOpen
    end
end)

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
    if playerHighlights[player] then playerHighlights[player]:Destroy(); playerHighlights[player] = nil end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"; h.Adornee = player.Character; h.Parent = GUI
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.19; h.OutlineTransparency = 0.08
    playerHighlights[player] = h
end

local function RemovePlayerHighlight(player)
    if playerHighlights[player] then playerHighlights[player]:Destroy(); playerHighlights[player] = nil end
end

local function AddNameTag(player)
    if player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then NameTags[player]:Destroy(); NameTags[player] = nil end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTFName]"; billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,110,0,20); billboard.StudsOffset = Vector3.new(0,2.18,0); billboard.AlwaysOnTop = true
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamSemibold; text.TextSize = 13
    text.TextColor3 = Color3.fromRGB(190,210,230); text.TextStrokeColor3 = Color3.fromRGB(8,10,14); text.TextStrokeTransparency = 0.6
    text.Text = player.DisplayName or player.Name
    NameTags[player] = billboard
end

local function RemoveNameTag(player)
    if NameTags[player] then NameTags[player]:Destroy(); NameTags[player] = nil end
end

local function RefreshPlayerESP()
    for _, p in pairs(Players:GetPlayers()) do
        if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) else RemovePlayerHighlight(p); RemoveNameTag(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        wait(0.08)
        if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerHighlight(p); RemoveNameTag(p) end)

RunService.RenderStepped:Connect(function()
    if PlayerESPActive then
        for _, p in pairs(Players:GetPlayers()) do
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
    for _, name in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        if model:FindFirstChild(name) and model[name]:IsA("BasePart") then return model[name] end
    end
    local biggest
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end
    end
    return biggest
end

local function getPcColor(model)
    local s = getScreenPart(model)
    if not s then return Color3.fromRGB(77,164,255) end
    return s.Color
end

local function AddComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then compHighlights[model]:Destroy(); compHighlights[model] = nil end
    local h = Instance.new("Highlight", GUI)
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"; h.Adornee = model
    h.FillColor = getPcColor(model); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.14; h.OutlineTransparency = 0.08
    compHighlights[model] = h
end

local function RemoveComputerHighlight(model)
    if compHighlights[model] then compHighlights[model]:Destroy(); compHighlights[model] = nil end
end

local function RefreshComputerESP()
    for m, h in pairs(compHighlights) do if h then h:Destroy() end end; compHighlights = {}
    if not ComputerESPActive then return end
    for _, d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then AddComputerHighlight(d) end end
end

Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive and isComputerModel(obj) then task.delay(0.05, function() AddComputerHighlight(obj) end) end end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then h.FillColor = getPcColor(m) end end end end)

-- ========== RAGDOLL DOWN TIMER ==========
local DownTimerActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}

local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head"); if not head then return nil end
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

local function removeRagdollBillboard(player)
    if ragdollBillboards[player] then
        if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then ragdollBillboards[player].gui:Destroy() end
        ragdollBillboards[player] = nil
    end
end

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
            if bottomUI[player] and bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end
            bottomUI[player] = nil
        else
            local remaining = info.endTime - now
            if remaining <= 0 then
                removeRagdollBillboard(player)
                if bottomUI[player] and bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end
                bottomUI[player] = nil
            else
                if info.label and info.label.Parent then
                    info.label.Text = string.format("%.2f", remaining)
                    if remaining <= 5 then info.label.TextColor3 = Color3.fromRGB(255,90,90) else info.label.TextColor3 = Color3.fromRGB(220,220,230) end
                end
                if info.progress and info.progress.Parent then
                    local frac = math.clamp(remaining / DOWN_TIME, 0, 1)
                    info.progress.Size = UDim2.new(frac,0,1,0)
                    if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(90,180,255)
                    elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(240,200,60)
                    else info.progress.BackgroundColor3 = Color3.fromRGB(255,90,90) end
                end
                if bottomUI[player] then bottomUI[player].timerLabel.Text = string.format("%.2f", remaining) end
            end
        end
    end
end)

local ragdollConnects = {}
local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, rag = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not rag then return end
        pcall(function() if rag.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end end end)
        local conn = rag.Changed:Connect(function()
            pcall(function()
                if rag.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end
                else removeRagdollBillboard(player) end
            end)
        end)
        ragdollConnects[player] = conn
    end)
end

Players.PlayerAdded:Connect(function(p)
    attachRagdollListenerToPlayer(p)
    p.CharacterAdded:Connect(function() wait(0.06); if ragdollBillboards[p] then removeRagdollBillboard(p); createRagdollBillboardFor(p) end end)
end)
for _, p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end

-- ========== GRAY SKIN ==========
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
    for _, obj in ipairs(player.Character:GetDescendants()) do
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
    for _, p in pairs(Players:GetPlayers()) do
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
    for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k] = nil end
end

Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
    if grayConns[p] then pcall(function() grayConns[p]:Disconnect() end); grayConns[p] = nil end
end)

-- ========== SAFE WHITE BRICK TEXTURE ==========
local TextureActive = false
local textureBackup = {}
local textureDescendantConn = nil

local function isPartPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then return Players:GetPlayerFromCharacter(model) ~= nil end
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
    pcall(function() TextureIndicator.BackgroundColor3 = Color3.fromRGB(245,245,245) end)
    task.spawn(applyWhiteBrickToAll)
    textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Desativar Texture Tijolos Brancos" end
end

local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    task.spawn(restoreTextures)
    pcall(function() TextureIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end)
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Ativar Texture Tijolos Brancos" end
end

-- ========== FREEZE PODS (já implementado acima e integrado) ==========

-- ========== BUTTONS LIGANDO A AÇÕES ==========
PlayerBtn.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive; RefreshPlayerESP()
    if PlayerESPActive then PlayerIndicator.BackgroundColor3 = Color3.fromRGB(52,215,101) else PlayerIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

CompBtn.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive; RefreshComputerESP()
    if ComputerESPActive then CompIndicator.BackgroundColor3 = Color3.fromRGB(54,144,255) else CompIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

DownTimerBtn.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then DownIndicator.BackgroundColor3 = Color3.fromRGB(255,200,90)
    else DownIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
    if not DownTimerActive then
        for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end
        for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p] = nil end
    else
        for _, p in pairs(Players:GetPlayers()) do
            local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then attachRagdollListenerToPlayer(p); end end
        end
    end
end)

GraySkinBtn.MouseButton1Click:Connect(function()
    GraySkinActive = not GraySkinActive
    if GraySkinActive then GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(200,200,200); enableGraySkin()
    else GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220); disableGraySkin() end
end)

TextureBtn.MouseButton1Click:Connect(function()
    if not TextureActive then enableTextureToggle() else disableTextureToggle() end
end)

FreezeBtn.MouseButton1Click:Connect(function()
    if not FreezePodsActive then enableFreezePods() else disableFreezePods() end
end)

-- Cleanup on unload
local function cleanupAll()
    if TextureActive then disableTextureToggle() end
    if GraySkinActive then disableGraySkin() end
    if FreezePodsActive then disableFreezePods() end
    for p,_ in pairs(playerHighlights) do RemovePlayerHighlight(p) end
    for p,_ in pairs(NameTags) do RemoveNameTag(p) end
end

Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
    if playerHighlights[p] then RemovePlayerHighlight(p) end
    if NameTags[p] then RemoveNameTag(p) end
end)

print("[FTF_ESP] Script carregado com sucesso. Abra o menu com K.")
