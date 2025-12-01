-- FTF ESP Script — Complete final script
-- Features:
--  - Player / Computer / Freeze Pod / Door ESP (enable/disable with full cleanup)
--  - Remove Fog (toggleable) with backup/restore
--  - Remove Textures (heavy optimization) with backups and restore
--  - Remove players Textures (Gray skin), White Brick texture, Snow texture (toggleable + restore)
--  - Down ragdoll timer (toggleable)
--  - Teleport tab (dynamic)
--  - Modern UI: centered loading panel (no full-screen overlay), toast hint,
--    minimize icon (shows local player's headshot), mobile toggle button
--  - Menu toggle with keyboard "K" (PC). Minimize icon opens menu when clicked.
-- NOTE: Set ICON_IMAGE_ID to a fallback image asset id if desired. The script will attempt to use the player's headshot.

-- ===== CONFIG =====
local ICON_IMAGE_ID = "" -- optional fallback asset id (string or number)
local REMOVE_TEXTURES_BATCH_SIZE = 250 -- batch size for the heavy remove-textures loop
-- ==================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Helper: safe destroy
local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

-- Remove previous GUIs if present
for _,v in pairs(CoreGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- Small batch iterator (yields every batchSize) to avoid freezing
local function batchIterate(list, batchSize, callback)
    batchSize = batchSize or 200
    local i = 1
    while i <= #list do
        local stop = math.min(i + batchSize - 1, #list)
        for j = i, stop do
            pcall(callback, list[j])
        end
        i = stop + 1
        RunService.Heartbeat:Wait()
    end
end

-- ============================================================================
-- FEATURE STATE & IMPLEMENTATIONS
-- Each feature provides enable / disable functions that fully clean up.
-- ============================================================================

-- PLAYER ESP
local PlayerESPActive = false
local playerHighlights = {}   -- [player] = Highlight
local playerNameTags = {}     -- [player] = BillboardGui

local function isBeast(player)
    return player and player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function createPlayerHighlight(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then safeDestroy(playerHighlights[player]) end
    local fill, outline = Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
    if isBeast(player) then fill, outline = Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"
    h.Adornee = player.Character
    h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline
    h.FillTransparency = 0.12; h.OutlineTransparency = 0.04
    h.Enabled = true
    playerHighlights[player] = h
end

local function removePlayerHighlight(player)
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
end

local function createPlayerNameTag(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    if playerNameTags[player] then safeDestroy(playerNameTags[player]) end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTFName]"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0,110,0,20)
    billboard.StudsOffset = Vector3.new(0,2.18,0)
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(190,210,230)
    label.Text = player.DisplayName or player.Name
    label.TextXAlignment = Enum.TextXAlignment.Center
    playerNameTags[player] = billboard
end

local function removePlayerNameTag(player)
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
end

local function enablePlayerESP()
    if PlayerESPActive then return end
    PlayerESPActive = true
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then createPlayerHighlight(p); createPlayerNameTag(p) end
    end
end

local function disablePlayerESP()
    if not PlayerESPActive then return end
    PlayerESPActive = false
    for p,_ in pairs(playerHighlights) do removePlayerHighlight(p) end
    for p,_ in pairs(playerNameTags) do removePlayerNameTag(p) end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.08)
        if PlayerESPActive then createPlayerHighlight(p); createPlayerNameTag(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    removePlayerHighlight(p); removePlayerNameTag(p)
end)

local function TogglePlayerESP() if PlayerESPActive then disablePlayerESP() else enablePlayerESP() end end

-- COMPUTER ESP
local ComputerESPActive = false
local compHighlights = {} -- [model] = Highlight

local function isComputerModel(model)
    return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc"))
end

local function addComputerHighlight(model)
    if not model then return end
    if compHighlights[model] then safeDestroy(compHighlights[model]) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(77,164,255); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    compHighlights[model] = h
end

local function removeComputerHighlight(model)
    if compHighlights[model] then safeDestroy(compHighlights[model]); compHighlights[model] = nil end
end

local function enableComputerESP()
    if ComputerESPActive then return end
    ComputerESPActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then addComputerHighlight(d) end end
    -- keep reactive: add listener while active
    compDescConn = Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive then if isComputerModel(obj) then task.delay(0.05, function() addComputerHighlight(obj) end) end end end)
    compDescRemConn = Workspace.DescendantRemoving:Connect(function(obj) removeComputerHighlight(obj) end)
end

local function disableComputerESP()
    if not ComputerESPActive then return end
    ComputerESPActive = false
    if compDescConn then pcall(function() compDescConn:Disconnect() end); compDescConn = nil end
    if compDescRemConn then pcall(function() compDescRemConn:Disconnect() end); compDescRemConn = nil end
    for m,_ in pairs(compHighlights) do removeComputerHighlight(m) end
end

local function ToggleComputerESP() if ComputerESPActive then disableComputerESP() else enableComputerESP() end end

-- FREEZE PODS
local FreezePodsActive = false
local podHighlights = {}

local function isFreezePodModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    return name:find("freezepod") or (name:find("freeze") and name:find("pod")) or (name:find("freeze") and name:find("capsule"))
end

local function addPodHighlight(model)
    if not model then return end
    if podHighlights[model] then safeDestroy(podHighlights[model]) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_FreezePodAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[model] = h
end

local function removePodHighlight(model)
    if podHighlights[model] then safeDestroy(podHighlights[model]); podHighlights[model] = nil end
end

local function enableFreezePodsESP()
    if FreezePodsActive then return end
    FreezePodsActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if isFreezePodModel(d) then addPodHighlight(d) end end
    podDescConn = Workspace.DescendantAdded:Connect(function(obj) if FreezePodsActive then if isFreezePodModel(obj) then task.delay(0.05, function() addPodHighlight(obj) end) end end end)
    podDescRemConn = Workspace.DescendantRemoving:Connect(function(obj) removePodHighlight(obj) end)
end

local function disableFreezePodsESP()
    if not FreezePodsActive then return end
    FreezePodsActive = false
    if podDescConn then pcall(function() podDescConn:Disconnect() end); podDescConn = nil end
    if podDescRemConn then pcall(function() podDescRemConn:Disconnect() end); podDescRemConn = nil end
    for m,_ in pairs(podHighlights) do removePodHighlight(m) end
end

local function ToggleFreezePodsESP() if FreezePodsActive then disableFreezePodsESP() else enableFreezePodsESP() end end

-- DOOR AURA
local DoorESPActive = false
local doorHighlights = {}

local function isDoorModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("door") then return true end
    if name:find("exitdoor") then return true end
    if (name:find("single") or name:find("double")) and name:find("door") then return true end
    return false
end

local function addDoorAura(model)
    if not model then return end
    if doorHighlights[model] then safeDestroy(doorHighlights[model]) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_DoorAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillTransparency = 1; h.OutlineTransparency = 0; h.OutlineColor = Color3.fromRGB(255,230,120); h.Enabled = true
    doorHighlights[model] = h
end

local function removeDoorAura(model)
    if doorHighlights[model] then safeDestroy(doorHighlights[model]); doorHighlights[model] = nil end
end

local function enableDoorESP()
    if DoorESPActive then return end
    DoorESPActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if isDoorModel(d) then addDoorAura(d) end end
    doorDescConn = Workspace.DescendantAdded:Connect(function(obj) if DoorESPActive then if isDoorModel(obj) then task.delay(0.04, function() addDoorAura(obj) end) end end end)
    doorDescRemConn = Workspace.DescendantRemoving:Connect(function(obj) if doorHighlights[obj] then removeDoorAura(obj) end end)
end

local function disableDoorESP()
    if not DoorESPActive then return end
    DoorESPActive = false
    if doorDescConn then pcall(function() doorDescConn:Disconnect() end); doorDescConn = nil end
    if doorDescRemConn then pcall(function() doorDescRemConn:Disconnect() end); doorDescRemConn = nil end
    for m,_ in pairs(doorHighlights) do removeDoorAura(m) end
end

local function ToggleDoorESP() if DoorESPActive then disableDoorESP() else enableDoorESP() end end

-- DOWN TIMER (Ragdoll)
local DownTimerActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}

local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTF_RagdollTimer]"; billboard.Adornee = head
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
    if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then safeDestroy(ragdollBillboards[player].gui) end ragdollBillboards[player] = nil end
end

local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then
        pcall(function() ragdollConnects[player]:Disconnect() end)
        ragdollConnects[player] = nil
    end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, rag = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not rag then return end
        if rag.Value and DownTimerActive then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME end end
        local conn = rag.Changed:Connect(function()
            if rag.Value then
                if DownTimerActive then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME end end
            else
                removeRagdollBillboard(player)
            end
        end)
        ragdollConnects[player] = conn
    end)
end

for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p) end)

local function ToggleDownTimer()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then
        for _,p in pairs(Players:GetPlayers()) do
            local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then local info = createRagdollBillboardFor(p); if info then info.endTime = tick() + DOWN_TIME end end end
        end
    else
        for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
    end
end

-- ============================================================================
-- TEXTURE / SNOW / GRAY SKIN IMPLEMENTATIONS
-- ============================================================================
-- Gray skin (remove player textures)
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
    if GraySkinActive then return end
    GraySkinActive = true
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyGrayToCharacter(p) end
        if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() task.wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end
    end
    if not grayConns._playerAddedConn then grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer and GraySkinActive then if p.Character then applyGrayToCharacter(p) end; if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() task.wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end end) end
end

local function disableGraySkin()
    if not GraySkinActive then return end
    GraySkinActive = false
    for p,_ in pairs(skinBackup) do pcall(function() restoreGrayForPlayer(p) end) end
    skinBackup = {}
    for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k] = nil end
end

local function ToggleGraySkin() if GraySkinActive then disableGraySkin() else enableGraySkin() end end

-- White Brick Texture (environment)
local TextureActive = false
local textureBackup = {}
local textureDescConn = nil

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
    batchIterate(desc, 200, function(d) if d and d:IsA("BasePart") then saveAndApplyWhiteBrick(d) end end)
end

local function onWorkspaceDescendantAdded(desc)
    if not TextureActive then return end
    if desc and desc:IsA("BasePart") and not isPartPlayerCharacter(desc) then task.defer(function() saveAndApplyWhiteBrick(desc) end) end
end

local function restoreTextures()
    local entries = {}
    for p, props in pairs(textureBackup) do entries[#entries+1] = {p=p, props=props} end
    batchIterate(entries, 200, function(e)
        local part = e.p; local props = e.props
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
    end)
    textureBackup = {}
end

local function enableTextureToggle()
    if TextureActive then return end
    TextureActive = true
    task.spawn(applyWhiteBrickToAll)
    textureDescConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
end

local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescConn then pcall(function() textureDescConn:Disconnect() end); textureDescConn = nil end
    task.spawn(restoreTextures)
end

local function ToggleTexture() if TextureActive then disableTextureToggle() else enableTextureToggle() end end

-- Snow texture (change lights & whiten parts)
local SnowActive = false
local snowBackupParts = {}
local snowPartConn = nil
local snowLightingBackup = nil
local snowSkyBackup = {}
local createdSnowSky = nil

local function backupLightingForSnow()
    snowLightingBackup = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end

local function restoreLightingFromSnow()
    if not snowLightingBackup then return end
    pcall(function() Lighting.Ambient = snowLightingBackup.Ambient end)
    pcall(function() Lighting.OutdoorAmbient = snowLightingBackup.OutdoorAmbient end)
    pcall(function() Lighting.FogColor = snowLightingBackup.FogColor end)
    pcall(function() Lighting.FogEnd = snowLightingBackup.FogEnd end)
    pcall(function() Lighting.Brightness = snowLightingBackup.Brightness end)
    pcall(function() Lighting.ClockTime = snowLightingBackup.ClockTime end)
    pcall(function() Lighting.EnvironmentDiffuseScale = snowLightingBackup.EnvironmentDiffuseScale end)
    pcall(function() Lighting.EnvironmentSpecularScale = snowLightingBackup.EnvironmentSpecularScale end)
    snowLightingBackup = nil
end

local function enableSnowTexture()
    if SnowActive then return end
    SnowActive = true
    backupLightingForSnow()
    for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then pcall(function() table.insert(snowSkyBackup, v:Clone()) end); pcall(function() v:Destroy() end) end end
    local desc = Workspace:GetDescendants()
    batchIterate(desc, 200, function(obj)
        if obj and obj:IsA("BasePart") then
            if not snowBackupParts[obj] then
                local okC, col = pcall(function() return obj.Color end)
                local okM, mat = pcall(function() return obj.Material end)
                snowBackupParts[obj] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
            end
            pcall(function() obj.Color = Color3.new(1,1,1); obj.Material = Enum.Material.SmoothPlastic end)
        end
    end)
    pcall(function()
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogColor = Color3.new(1,1,1)
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    local sky = Instance.new("Sky")
    sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""
    sky.Parent = Lighting
    createdSnowSky = sky
    snowPartConn = Workspace.DescendantAdded:Connect(function(desc)
        if not SnowActive then return end
        if desc and desc:IsA("BasePart") then
            if not snowBackupParts[desc] then
                local okC, col = pcall(function() return desc.Color end)
                local okM, mat = pcall(function() return desc.Material end)
                snowBackupParts[desc] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
            end
            pcall(function() desc.Color = Color3.new(1,1,1); desc.Material = Enum.Material.SmoothPlastic end)
        end
    end)
end

local function disableSnowTexture()
    if not SnowActive then return end
    SnowActive = false
    if snowPartConn then pcall(function() snowPartConn:Disconnect() end); snowPartConn = nil end
    for part, props in pairs(snowBackupParts) do
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
    end
    snowBackupParts = {}
    if createdSnowSky and createdSnowSky.Parent then pcall(function() createdSnowSky:Destroy() end) end
    createdSnowSky = nil
    for _,cloneSky in ipairs(snowSkyBackup) do if cloneSky then pcall(function() cloneSky.Parent = Lighting end) end end
    snowSkyBackup = {}
    restoreLightingFromSnow()
end

local function ToggleSnow() if SnowActive then disableSnowTexture() else enableSnowTexture() end end

-- ============================================================================
-- REMOVE FOG & REMOVE TEXTURES (implemented earlier) are available:
-- ToggleRemoveFog() and ToggleRemoveTextures()
-- Implement Remove Fog:
local RemoveFogActive = false
local RemoveFogBackup = nil

local function enableRemoveFog()
    if RemoveFogActive then return end
    RemoveFogBackup = {
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows
    }
    pcall(function()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    end)
    RemoveFogActive = true
end

local function disableRemoveFog()
    if not RemoveFogActive then return end
    if RemoveFogBackup then
        pcall(function()
            if RemoveFogBackup.FogEnd ~= nil then Lighting.FogEnd = RemoveFogBackup.FogEnd end
            if RemoveFogBackup.FogStart ~= nil then Lighting.FogStart = RemoveFogBackup.FogStart end
            if RemoveFogBackup.ClockTime ~= nil then Lighting.ClockTime = RemoveFogBackup.ClockTime end
            if RemoveFogBackup.Brightness ~= nil then Lighting.Brightness = RemoveFogBackup.Brightness end
            if RemoveFogBackup.GlobalShadows ~= nil then Lighting.GlobalShadows = RemoveFogBackup.GlobalShadows end
        end)
    end
    RemoveFogBackup = nil
    RemoveFogActive = false
end

local function ToggleRemoveFog() if RemoveFogActive then disableRemoveFog() else enableRemoveFog() end end

-- Remove Textures (heavy operation) with backups and batch processing
local RemoveTexturesActive = false
local rt_backup_parts = {}
local rt_backup_meshparts = {}
local rt_backup_decals = {}
local rt_backup_particles = {}
local rt_backup_explosions = {}
local rt_backup_effects = {}
local rt_backup_terrain = {}
local rt_backup_lighting = {}
local rt_backup_quality = nil
local rt_desc_added_conn = nil

local function rt_store_part(p)
    if not p or not p:IsA("BasePart") then return end
    if rt_backup_parts[p] then return end
    rt_backup_parts[p] = { Material = p.Material, Reflectance = p.Reflectance }
end
local function rt_store_meshpart(mp)
    if not mp or not mp:IsA("MeshPart") then return end
    if rt_backup_meshparts[mp] then return end
    rt_backup_meshparts[mp] = { Material = mp.Material, Reflectance = mp.Reflectance, TextureID = mp.TextureID }
end
local function rt_store_decal(d)
    if not d then return end
    if rt_backup_decals[d] then return end
    rt_backup_decals[d] = d.Transparency
end
local function rt_store_particle(e)
    if not e then return end
    if rt_backup_particles[e] then return end
    if e:IsA("ParticleEmitter") or e:IsA("Trail") then
        rt_backup_particles[e] = { Lifetime = e.Lifetime }
    end
end
local function rt_store_explosion(ex)
    if not ex or not ex:IsA("Explosion") then return end
    if rt_backup_explosions[ex] then return end
    rt_backup_explosions[ex] = { BlastPressure = ex.BlastPressure, BlastRadius = ex.BlastRadius }
end
local function rt_store_effect(e)
    if not e then return end
    if rt_backup_effects[e] ~= nil then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_backup_effects[e] = e.Enabled
    end
    if e:IsA("Fire") or e:IsA("SpotLight") or e:IsA("Smoke") then
        rt_backup_effects[e] = e.Enabled
    end
end

local function rt_apply_to_instance(v)
    if v:IsA("BasePart") then
        rt_store_part(v)
        pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end)
    end
    if v:IsA("UnionOperation") then
        rt_store_part(v)
        pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end)
    end
    if v:IsA("Decal") or v:IsA("Texture") then
        rt_store_decal(v)
        pcall(function() v.Transparency = 1 end)
    end
    if v:IsA("ParticleEmitter") or v:IsA("Trail") then
        rt_store_particle(v)
        pcall(function() v.Lifetime = NumberRange.new(0) end)
    end
    if v:IsA("Explosion") then
        rt_store_explosion(v)
        pcall(function() v.BlastPressure = 1; v.BlastRadius = 1 end)
    end
    if v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
        rt_store_effect(v)
        pcall(function() v.Enabled = false end)
    end
    if v:IsA("MeshPart") then
        rt_store_meshpart(v)
        pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0; v.TextureID = "rbxassetid://10385902758728957" end)
    end
end

local function rt_apply_to_lighting_child(e)
    if not e then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_store_effect(e)
        pcall(function() e.Enabled = false end)
    end
end

local function enableRemoveTextures()
    if RemoveTexturesActive then return end
    -- Backup terrain & lighting
    rt_backup_terrain = {
        WaterWaveSize = Workspace.Terrain.WaterWaveSize,
        WaterWaveSpeed = Workspace.Terrain.WaterWaveSpeed,
        WaterReflectance = Workspace.Terrain.WaterReflectance,
        WaterTransparency = Workspace.Terrain.WaterTransparency
    }
    rt_backup_lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness
    }
    local ok, q = pcall(function() return settings().Rendering.QualityLevel end)
    if ok then rt_backup_quality = q end

    -- Apply terrain & lighting changes
    pcall(function()
        local t = Workspace.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
    end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
    end)
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    -- Apply to existing descendants in batches
    local desc = Workspace:GetDescendants()
    batchIterate(desc, REMOVE_TEXTURES_BATCH_SIZE, function(v) rt_apply_to_instance(v) end)

    -- Apply to lighting children
    for _,e in ipairs(Lighting:GetChildren()) do rt_apply_to_lighting_child(e) end

    -- Connect to new descendants while active
    rt_desc_added_conn = Workspace.DescendantAdded:Connect(function(v)
        if not RemoveTexturesActive then return end
        task.defer(function() rt_apply_to_instance(v) end)
    end)

    RemoveTexturesActive = true
end

local function disableRemoveTextures()
    if not RemoveTexturesActive then return end
    if rt_desc_added_conn then pcall(function() rt_desc_added_conn:Disconnect() end); rt_desc_added_conn = nil end

    -- Restore parts
    for part, props in pairs(rt_backup_parts) do
        if part and part.Parent then
            pcall(function() if props.Material then part.Material = props.Material end; if props.Reflectance then part.Reflectance = props.Reflectance end end)
        end
    end
    rt_backup_parts = {}

    -- Restore meshparts
    for mp, props in pairs(rt_backup_meshparts) do
        if mp and mp.Parent then
            pcall(function()
                if props.Material then mp.Material = props.Material end
                if props.Reflectance then mp.Reflectance = props.Reflectance end
                if props.TextureID then mp.TextureID = props.TextureID end
            end)
        end
    end
    rt_backup_meshparts = {}

    -- Restore decals
    for d, tr in pairs(rt_backup_decals) do if d and d.Parent then pcall(function() d.Transparency = tr end) end end
    rt_backup_decals = {}

    -- Restore particles
    for e, info in pairs(rt_backup_particles) do if e and e.Parent then pcall(function() e.Lifetime = info.Lifetime end) end end
    rt_backup_particles = {}

    -- Restore explosions
    for ex, props in pairs(rt_backup_explosions) do if ex and ex.Parent then pcall(function() if props.BlastPressure then ex.BlastPressure = props.BlastPressure end; if props.BlastRadius then ex.BlastRadius = props.BlastRadius end end) end end
    rt_backup_explosions = {}

    -- Restore effects
    for e, enabled in pairs(rt_backup_effects) do if e and e.Parent then pcall(function() e.Enabled = enabled end) end end
    rt_backup_effects = {}

    -- Restore terrain
    if rt_backup_terrain and next(rt_backup_terrain) then
        pcall(function()
            local t = Workspace.Terrain
            if rt_backup_terrain.WaterWaveSize ~= nil then t.WaterWaveSize = rt_backup_terrain.WaterWaveSize end
            if rt_backup_terrain.WaterWaveSpeed ~= nil then t.WaterWaveSpeed = rt_backup_terrain.WaterWaveSpeed end
            if rt_backup_terrain.WaterReflectance ~= nil then t.WaterReflectance = rt_backup_terrain.WaterReflectance end
            if rt_backup_terrain.WaterTransparency ~= nil then t.WaterTransparency = rt_backup_terrain.WaterTransparency end
        end)
    end
    rt_backup_terrain = {}

    -- Restore lighting
    if rt_backup_lighting and next(rt_backup_lighting) then
        pcall(function()
            if rt_backup_lighting.GlobalShadows ~= nil then Lighting.GlobalShadows = rt_backup_lighting.GlobalShadows end
            if rt_backup_lighting.FogEnd ~= nil then Lighting.FogEnd = rt_backup_lighting.FogEnd end
            if rt_backup_lighting.Brightness ~= nil then Lighting.Brightness = rt_backup_lighting.Brightness end
        end)
    end
    rt_backup_lighting = {}

    -- Restore quality
    if rt_backup_quality then pcall(function() settings().Rendering.QualityLevel = rt_backup_quality end) end
    rt_backup_quality = nil

    RemoveTexturesActive = false
end

local function ToggleRemoveTextures() if RemoveTexturesActive then disableRemoveTextures() else enableRemoveTextures() end end

-- ============================================================================
-- UI: Loading panel (centered), toast, minimized icon (avatar headshot), mobile toggle, main menu
-- ============================================================================

-- Loading panel (center-only)
local LoadingPanel = Instance.new("Frame", GUI)
LoadingPanel.Name = "FTF_LoadingPanel"
LoadingPanel.Size = UDim2.new(0,420,0,120)
LoadingPanel.Position = UDim2.new(0.5,-210,0.45,-60)
LoadingPanel.BackgroundColor3 = Color3.fromRGB(18,18,20)
LoadingPanel.BorderSizePixel = 0
local lpCorner = Instance.new("UICorner", LoadingPanel); lpCorner.CornerRadius = UDim.new(0,14)
local lpStroke = Instance.new("UIStroke", LoadingPanel); lpStroke.Color = Color3.fromRGB(40,40,48); lpStroke.Thickness = 1; lpStroke.Transparency = 0.3
local lpTitle = Instance.new("TextLabel", LoadingPanel)
lpTitle.Size = UDim2.new(1,-40,0,36); lpTitle.Position = UDim2.new(0,20,0,14)
lpTitle.BackgroundTransparency = 1; lpTitle.Font = Enum.Font.FredokaOne; lpTitle.TextSize = 20
lpTitle.TextColor3 = Color3.fromRGB(220,220,230); lpTitle.Text = "Loading FTF hub - By David"; lpTitle.TextXAlignment = Enum.TextXAlignment.Left
local lpSub = Instance.new("TextLabel", LoadingPanel)
lpSub.Size = UDim2.new(1,-40,0,18); lpSub.Position = UDim2.new(0,20,0,56)
lpSub.BackgroundTransparency = 1; lpSub.Font = Enum.Font.Gotham; lpSub.TextSize = 12
lpSub.TextColor3 = Color3.fromRGB(170,170,180); lpSub.Text = "Initializing..."; lpSub.TextXAlignment = Enum.TextXAlignment.Left
local spinner = Instance.new("Frame", LoadingPanel)
spinner.Size = UDim2.new(0,40,0,40); spinner.Position = UDim2.new(1,-64,0,20); spinner.BackgroundColor3 = Color3.fromRGB(24,24,26)
local spCorner = Instance.new("UICorner", spinner); spCorner.CornerRadius = UDim.new(0,10)
local inner = Instance.new("Frame", spinner); inner.Size = UDim2.new(0,24,0,24); inner.Position = UDim2.new(0.5,-12,0.5,-12); inner.BackgroundColor3 = Color3.fromRGB(60,160,255)
local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
spinTween:Play()

-- Toast
local Toast = Instance.new("Frame", GUI)
Toast.Name = "FTF_Toast"
Toast.Size = UDim2.new(0,360,0,46)
Toast.Position = UDim2.new(0.5,-180,0.02,0)
Toast.BackgroundColor3 = Color3.fromRGB(20,20,22)
Toast.Visible = false
local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
local toastLabel = Instance.new("TextLabel", Toast)
toastLabel.Size = UDim2.new(1,-48,1,0); toastLabel.Position = UDim2.new(0,12,0,0); toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14; toastLabel.TextColor3 = Color3.fromRGB(220,220,220)
toastLabel.Text = "Use the letter K on your keyboard to open the MENU."
local toastClose = Instance.new("TextButton", Toast); toastClose.Size = UDim2.new(0,28,0,28); toastClose.Position = UDim2.new(1,-40,0.5,-14)
toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)

-- Minimized icon (ImageButton) — updated to player's headshot
local MinimizedIcon = Instance.new("ImageButton", GUI)
MinimizedIcon.Name = "FTF_MinimizedIcon"
MinimizedIcon.Size = UDim2.new(0,56,0,56)
MinimizedIcon.Position = UDim2.new(0.02,0,0.06,0)
MinimizedIcon.BackgroundColor3 = Color3.fromRGB(24,24,26)
MinimizedIcon.BorderSizePixel = 0
MinimizedIcon.Visible = false
local miCorner = Instance.new("UICorner", MinimizedIcon); miCorner.CornerRadius = UDim.new(0,12)
local miStroke = Instance.new("UIStroke", MinimizedIcon); miStroke.Color = Color3.fromRGB(30,80,130); miStroke.Transparency = 0.7
if tostring(ICON_IMAGE_ID) ~= "" then pcall(function() MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end) end

-- Update minimized icon to local player's headshot (safe)
local function updateMinimizedIconAvatar()
    if not MinimizedIcon then return end
    pcall(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if ok and url and url ~= "" then MinimizedIcon.Image = url end
    end)
end
-- initial fetch
task.defer(updateMinimizedIconAvatar)
-- update on character appearance reload
if LocalPlayer then
    pcall(function()
        LocalPlayer.CharacterAppearanceLoaded:Connect(function()
            task.delay(0.4, updateMinimizedIconAvatar)
        end)
    end)
end

-- Mobile quick toggle
local MobileToggle = Instance.new("TextButton", GUI)
MobileToggle.Name = "FTF_MobileToggle"
MobileToggle.Size = UDim2.new(0,56,0,56)
MobileToggle.Position = UDim2.new(0.02,68,0.06,0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(24,24,26)
MobileToggle.BorderSizePixel = 0
MobileToggle.Text = "☰"; MobileToggle.Font = Enum.Font.GothamBold; MobileToggle.TextColor3 = Color3.fromRGB(220,220,220)
MobileToggle.Visible = UserInputService.TouchEnabled and true or false
local mtCorner = Instance.new("UICorner", MobileToggle); mtCorner.CornerRadius = UDim.new(0,12)

-- Main menu UI
local MENU_W, MENU_H = 520, 380
local MainFrame = Instance.new("Frame", GUI)
MainFrame.Name = "FTF_Main"; MainFrame.Size = UDim2.new(0,MENU_W,0,MENU_H); MainFrame.Position = UDim2.new(0.5,-MENU_W/2,0.08,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18); MainFrame.BorderSizePixel = 0; MainFrame.Visible = false
local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame); TitleBar.Size = UDim2.new(1,0,0,48); TitleBar.BackgroundTransparency = 1
local TitleLbl = Instance.new("TextLabel", TitleBar); TitleLbl.Text = "FTF - David's ESP"; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 16
TitleLbl.TextColor3 = Color3.fromRGB(220,220,220); TitleLbl.BackgroundTransparency = 1; TitleLbl.Position = UDim2.new(0,12,0,12); TitleLbl.Size = UDim2.new(0,260,0,24)
local SearchBox = Instance.new("TextBox", TitleBar); SearchBox.Size = UDim2.new(0,220,0,28); SearchBox.Position = UDim2.new(1,-240,0,10)
SearchBox.BackgroundColor3 = Color3.fromRGB(26,26,26); SearchBox.TextColor3 = Color3.fromRGB(200,200,200); SearchBox.ClearTextOnFocus = true
local sbCorner = Instance.new("UICorner", SearchBox); sbCorner.CornerRadius = UDim.new(0,8)

local MinimizeBtn = Instance.new("TextButton", TitleBar); MinimizeBtn.Text = "—"; MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 20
MinimizeBtn.BackgroundTransparency = 1; MinimizeBtn.Size = UDim2.new(0,36,0,36); MinimizeBtn.Position = UDim2.new(1,-92,0,6); MinimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)
local CloseBtn = Instance.new("TextButton", TitleBar); CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18
CloseBtn.BackgroundTransparency = 1; CloseBtn.Size = UDim2.new(0,36,0,36); CloseBtn.Position = UDim2.new(1,-44,0,6); CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)

-- Tabs and content scroll
local TabsParent = Instance.new("Frame", MainFrame); TabsParent.Size = UDim2.new(1,-24,0,44); TabsParent.Position = UDim2.new(0,12,0,56)
local tabNames = {"ESP","Textures","Timers","Teleport"}; local tabPadding = 10
local tabCount = #tabNames; local tabAvailableWidth = MENU_W - 24
local tabWidth = math.max(80, math.floor((tabAvailableWidth - (tabPadding * (tabCount - 1))) / tabCount))
local Tabs = {}
for i,name in ipairs(tabNames) do
    local x = (i-1)*(tabWidth + tabPadding)
    local t = Instance.new("TextButton", TabsParent)
    t.Size = UDim2.new(0,tabWidth,0,34); t.Position = UDim2.new(0,x,0,4)
    t.Text = name; t.Font = Enum.Font.GothamSemibold; t.TextSize = 14; t.TextColor3 = Color3.fromRGB(200,200,200)
    t.BackgroundColor3 = Color3.fromRGB(28,28,28); t.AutoButtonColor = false
    local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0,12)
    Tabs[name] = t
end
local TabESP = Tabs["ESP"]; local TabTextures = Tabs["Textures"]; local TabTimers = Tabs["Timers"]; local TabTeleport = Tabs["Teleport"]

local ContentScroll = Instance.new("ScrollingFrame", MainFrame)
ContentScroll.Name = "ContentScroll"; ContentScroll.Size = UDim2.new(1,-24,1,-120); ContentScroll.Position = UDim2.new(0,12,0,112)
ContentScroll.BackgroundTransparency = 1; ContentScroll.BorderSizePixel = 0; ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(75,75,75); ContentScroll.ScrollBarThickness = 8
local contentLayout = Instance.new("UIListLayout", ContentScroll); contentLayout.SortOrder = Enum.SortOrder.LayoutOrder; contentLayout.Padding = UDim.new(0,10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ContentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 18) end)

-- UI creators
local function createToggleItem(parent, labelText, initial, onToggle)
    local item = Instance.new("Frame", parent); item.Size = UDim2.new(0.95,0,0,44); item.BackgroundColor3 = Color3.fromRGB(28,28,28)
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", item); lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local sw = Instance.new("TextButton", item); sw.Size = UDim2.new(0,88,0,28); sw.Position = UDim2.new(1,-100,0.5,-14); sw.BackgroundColor3 = Color3.fromRGB(38,38,38); sw.AutoButtonColor = false
    local swCorner = Instance.new("UICorner", sw); swCorner.CornerRadius = UDim.new(0,16)
    local swBg = Instance.new("Frame", sw); swBg.Size = UDim2.new(1,-8,1,-8); swBg.Position = UDim2.new(0,4,0,4); swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local swBgCorner = Instance.new("UICorner", swBg); swBgCorner.CornerRadius = UDim.new(0,14)
    local toggleDot = Instance.new("Frame", swBg); toggleDot.Size = UDim2.new(0,20,0,20)
    toggleDot.Position = UDim2.new(initial and 1 or 0, initial and -22 or 2, 0.5, -10)
    toggleDot.BackgroundColor3 = initial and Color3.fromRGB(120,200,120) or Color3.fromRGB(180,180,180)
    local dotCorner = Instance.new("UICorner", toggleDot); dotCorner.CornerRadius = UDim.new(0,10)
    local state = initial or false
    local function updateVisual(s)
        state = s
        local targetPos = s and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        TweenService:Create(toggleDot, TweenInfo.new(0.15), {Position = targetPos}):Play()
        toggleDot.BackgroundColor3 = s and Color3.fromRGB(120,200,120) or Color3.fromRGB(160,160,160)
        swBg.BackgroundColor3 = s and Color3.fromRGB(35,90,35) or Color3.fromRGB(60,60,60)
    end
    sw.MouseButton1Click:Connect(function()
        pcall(function() onToggle() end)
        updateVisual(not state)
    end)
    updateVisual(state)
    return item, function(newState) updateVisual(newState) end, function() return state end, lbl
end

local function createButtonItem(parent, labelText, buttonText, callback)
    local item = Instance.new("Frame", parent); item.Size = UDim2.new(0.95,0,0,44); item.BackgroundColor3 = Color3.fromRGB(28,28,28)
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", item); lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btn = Instance.new("TextButton", item); btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1,-100,0.5,-14)
    btn.BackgroundColor3 = Color3.fromRGB(38,120,190); btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,12)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = buttonText
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return item, lbl, btn
end

-- Categories mapping (including the two new texture options)
local Categories = {
    ["ESP"] = {
        { label = "ESP Players", get = function() return PlayerESPActive end, toggle = function() TogglePlayerESP() end },
        { label = "ESP PCs", get = function() return ComputerESPActive end, toggle = function() ToggleComputerESP() end },
        { label = "ESP Freeze Pods", get = function() return FreezePodsActive end, toggle = function() ToggleFreezePodsESP() end },
        { label = "ESP Exit Doors", get = function() return DoorESPActive end, toggle = function() ToggleDoorESP() end },
    },
    ["Textures"] = {
        { label = "Remove players Textures", get = function() return GraySkinActive end, toggle = function() ToggleGraySkin() end },
        { label = "Ativar Textures Tijolos Brancos", get = function() return TextureActive end, toggle = function() ToggleTexture() end },
        { label = "Snow texture", get = function() return SnowActive end, toggle = function() ToggleSnow() end },
        { label = "Remove Fog", get = function() return RemoveFogActive end, toggle = function() ToggleRemoveFog() end },
        { label = "Remove Textures", get = function() return RemoveTexturesActive end, toggle = function() ToggleRemoveTextures() end },
    },
    ["Timers"] = {
        { label = "Ativar Contador de Down", get = function() return DownTimerActive end, toggle = function() ToggleDownTimer() end },
    },
}

-- Build category UI
local currentCategory = "ESP"
local function clearContent()
    for _,v in pairs(ContentScroll:GetChildren()) do if v:IsA("Frame") then safeDestroy(v) end end
end

local function buildCategory(name, filter)
    filter = (filter or ""):lower()
    clearContent()
    if name == "Teleport" then
        local order = 1
        local list = Players:GetPlayers()
        table.sort(list, function(a,b) return ((a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
        for _,pl in ipairs(list) do
            if pl ~= LocalPlayer then
                local display = (pl.DisplayName or pl.Name) .. " (" .. pl.Name .. ")"
                if filter == "" or display:lower():find(filter) then
                    local item, lbl, btn = createButtonItem(ContentScroll, display, "Teleport", function()
                        local myChar = LocalPlayer.Character; local targetChar = pl.Character
                        if not myChar or not targetChar then return end
                        local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                        local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                        if not hrp or not thrp then return end
                        pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
                    end)
                    item.LayoutOrder = order; order = order + 1
                end
            end
        end
    else
        local items = Categories[name] or {}
        local order = 1
        for _,entry in ipairs(items) do
            if filter == "" or entry.label:lower():find(filter) then
                local ok, state = pcall(function() return entry.get() end)
                state = ok and state or false
                local item, setVisual = createToggleItem(ContentScroll, entry.label, state, function()
                    pcall(function() entry.toggle() end)
                    local ok2, newState = pcall(function() return entry.get() end)
                    if ok2 and setVisual then pcall(function() setVisual(newState) end) end
                end)
                item.LayoutOrder = order; order = order + 1
            end
        end
    end
end

-- Tab visuals and handlers
local function setActiveTabVisual(activeTab)
    TabESP.BackgroundColor3 = (activeTab == TabESP) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTextures.BackgroundColor3 = (activeTab == TabTextures) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTimers.BackgroundColor3 = (activeTab == TabTimers) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTeleport.BackgroundColor3 = (activeTab == TabTeleport) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
end

TabESP.MouseButton1Click:Connect(function() currentCategory = "ESP"; setActiveTabVisual(TabESP); buildCategory("ESP", SearchBox.Text) end)
TabTextures.MouseButton1Click:Connect(function() currentCategory = "Textures"; setActiveTabVisual(TabTextures); buildCategory("Textures", SearchBox.Text) end)
TabTimers.MouseButton1Click:Connect(function() currentCategory = "Timers"; setActiveTabVisual(TabTimers); buildCategory("Timers", SearchBox.Text) end)
TabTeleport.MouseButton1Click:Connect(function() currentCategory = "Teleport"; setActiveTabVisual(TabTeleport); buildCategory("Teleport", SearchBox.Text) end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() buildCategory(currentCategory, SearchBox.Text) end)
Players.PlayerAdded:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)
Players.PlayerRemoving:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)

-- Draggable MainFrame
do
    local dragging, dragStart, startPos = false, nil, nil
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Minimize / restore / mobile toggle / keyboard K
MinimizeBtn.MouseButton1Click:Connect(function() updateMinimizedIconAvatar(); MainFrame.Visible = false; MinimizedIcon.Visible = true end)
MinimizedIcon.MouseButton1Click:Connect(function() MainFrame.Visible = true; MinimizedIcon.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
MobileToggle.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible; if MainFrame.Visible then MinimizedIcon.Visible = false end end)

local menuOpen = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
        if menuOpen then MinimizedIcon.Visible = false end
    end
end)

-- Finish loading: remove panel, show toast & menu
local function finishLoading()
    pcall(function() spinTween:Cancel() end)
    safeDestroy(LoadingPanel)
    Toast.Visible = true
    pcall(function() TweenService:Create(Toast, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play() end)
    task.delay(8, function()
        if Toast and Toast.Parent then
            pcall(function() TweenService:Create(Toast, TweenInfo.new(0.24, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play() end)
            task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end)
        end
    end)
end

-- Initial build and open menu after brief loading
setActiveTabVisual(TabESP)
buildCategory("ESP", "")
task.spawn(function()
    task.wait(1.1)
    MainFrame.Visible = true
    menuOpen = true
    finishLoading()
end)

-- Expose toggles to _G for convenience / debugging
_G.FTF = _G.FTF or {}
_G.FTF.TogglePlayerESP = TogglePlayerESP
_G.FTF.ToggleComputerESP = ToggleComputerESP
_G.FTF.ToggleFreezePodsESP = ToggleFreezePodsESP
_G.FTF.ToggleDoorESP = ToggleDoorESP
_G.FTF.ToggleGraySkin = ToggleGraySkin
_G.FTF.ToggleTexture = ToggleTexture
_G.FTF.ToggleSnow = ToggleSnow
_G.FTF.ToggleDownTimer = ToggleDownTimer
_G.FTF.ToggleRemoveFog = ToggleRemoveFog
_G.FTF.ToggleRemoveTextures = ToggleRemoveTextures
_G.FTF.DisableAllESP = function() disablePlayerESP(); disableComputerESP(); disableFreezePodsESP(); disableDoorESP() end

print("[FTF_ESP] Complete script loaded.")
