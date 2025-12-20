-- FTF ESP — By David
-- Integrated Contador de Down, BeastPower Time and Computer ProgressBar (toggleable)
-- Updated: Computer ESP replaced with the method you provided (fixed), menu/draggable/UI kept as requested.
-- WalkSpeed quick input added into "Hackers" category (single input field).

local ICON_IMAGE_ID = ""
local DOWN_COUNT_DURATION = 28
local REMOVE_TEXTURES_BATCH = 250

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function batchIterate(list, batchSize, fn)
    batchSize = batchSize or 200
    local i = 1
    while i <= #list do
        local stop = math.min(i + batchSize - 1, #list)
        for j = i, stop do
            pcall(fn, list[j])
        end
        i = stop + 1
        RunService.Heartbeat:Wait()
    end
end

-- Cleanup previous UI instances
for _,c in pairs(CoreGui:GetChildren()) do
    if c.Name == "FTF_ESP_GUI_DAVID" then pcall(function() c:Destroy() end) end
end
for _,c in pairs(PlayerGui:GetChildren()) do
    if c.Name == "FTF_ESP_GUI_DAVID" then pcall(function() c:Destroy() end) end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FTF_ESP_GUI_DAVID"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent or ScreenGui.Parent ~= CoreGui then ScreenGui.Parent = PlayerGui end

-- Generic highlight creator (used by several features)
local function createHighlight(adornee, fillColor, outlineColor, fillTrans, outlineTrans)
    if not adornee then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = adornee
    h.Parent = Workspace
    h.FillColor = fillColor or Color3.fromRGB(120,200,255)
    h.OutlineColor = outlineColor or Color3.fromRGB(20,40,80)
    h.FillTransparency = (fillTrans ~= nil) and fillTrans or 0.04
    h.OutlineTransparency = (outlineTrans ~= nil) and outlineTrans or 0.0
    h.Enabled = true
    return h
end

-- ======================
-- Player ESP
-- ======================
local PlayerESPEnabled = false
local playerHighlights = {}
local playerNameTags = {}

local function isBeast(player)
    return player and player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function createPlayerNameTag(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return end
    safeDestroy(playerNameTags[player])
    local bb = Instance.new("BillboardGui", ScreenGui)
    bb.Name = "[FTF_NameTag_"..player.Name.."]"
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,130,0,26)
    bb.StudsOffset = Vector3.new(0,2.6,0)
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(230,230,255)
    lbl.TextStrokeTransparency = 0.7
    lbl.Text = player.DisplayName or player.Name
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    playerNameTags[player] = bb
end

local function createPlayerHighlight(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    safeDestroy(playerHighlights[player])
    local fill = Color3.fromRGB(80,220,120)
    local outline = Color3.fromRGB(12,80,28)
    if isBeast(player) then
        fill = Color3.fromRGB(255,60,110)
        outline = Color3.fromRGB(140,30,50)
    end
    local h = createHighlight(player.Character, fill, outline, 0.04, 0)
    playerHighlights[player] = h
end

local function removePlayerESP(player)
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
end

local function enablePlayerESP()
    if PlayerESPEnabled then return true end
    PlayerESPEnabled = true
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            pcall(function() createPlayerHighlight(p); createPlayerNameTag(p) end)
        end
    end
    return true
end

local function disablePlayerESP()
    if not PlayerESPEnabled then return false end
    PlayerESPEnabled = false
    for p,_ in pairs(playerHighlights) do safeDestroy(playerHighlights[p]); playerHighlights[p] = nil end
    for p,_ in pairs(playerNameTags) do safeDestroy(playerNameTags[p]); playerNameTags[p] = nil end
    return false
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if PlayerESPEnabled then pcall(function() createPlayerHighlight(p); createPlayerNameTag(p) end) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

-- ======================
-- Computer ESP (USER METHOD: replaced to fix bug)
-- ======================
local ComputerESPEnabled = false
local computerInfo = {}

local function isComputerCandidate(model)
    if not model or not model:IsA("Model") then return false end
    local lower = model.Name:lower()
    return lower:find("computer") or lower:find("pc") or lower:find("terminal") or lower:find("console")
end

local function getModelState(model)
    if not model then return nil end
    local boolNames = {"Hacked", "IsHacked", "HackedValue"}
    for _,n in ipairs(boolNames) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BoolValue") then return v.Value and "hacked" or "ready" end
    end
    local strNames = {"State", "HackState", "Status", "Phase"}
    for _,n in ipairs(strNames) do
        local s = model:FindFirstChild(n, true)
        if s and s:IsA("StringValue") then return tostring(s.Value):lower() end
    end
    local intNames = {"State", "StateValue", "HackProgress", "Progress"}
    for _,n in ipairs(intNames) do
        local iv = model:FindFirstChild(n, true)
        if iv and iv:IsA("IntValue") then
            if iv.Value <= 0 then return "ready" end
            if iv.Value >= 1 then return "hacked" end
            return tostring(iv.Value)
        end
    end
    local attrs = {"HackState", "State", "Status"}
    for _,a in ipairs(attrs) do
        local at = model:GetAttribute(a)
        if at ~= nil then return tostring(at):lower() end
    end
    return nil
end

local function stateColorsFor(s)
    if not s then return Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 40, 80) end
    s = tostring(s):lower()
    if s:find("ready") or s:find("avail") then
        return Color3.fromRGB(80, 150, 255), Color3.fromRGB(20, 40, 80)
    elseif s:find("hacked") or s:find("done") or s:find("complete") or s == "1" then
        return Color3.fromRGB(90, 230, 120), Color3.fromRGB(16, 80, 24)
    elseif s:find("wrong") or s:find("failed") or s:find("error") or s == "-1" then
        return Color3.fromRGB(255, 80, 80), Color3.fromRGB(120, 24, 24)
    elseif s:find("progress") or s:find("hacking") then
        return Color3.fromRGB(255, 200, 90), Color3.fromRGB(130, 90, 20)
    else
        return Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 40, 80)
    end
end

local function createHighlightForComputer(model, fillColor, outlineColor, transparency, outlineTransparency)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = transparency or 0.06
    highlight.OutlineTransparency = outlineTransparency or 0
    highlight.Parent = workspace
    return highlight
end

local function updateHighlightColorFromScreen(model, highlight)
    local screen = model:FindFirstChild("Screen")
    if screen and screen:IsA("BasePart") then
        highlight.FillColor = screen.Color
        highlight.OutlineColor = screen.Color:Lerp(Color3.fromRGB(0, 0, 0), 0.5)
    end
end

local function updateComputerVisual(model)
    if not model then return end
    local info = computerInfo[model] or {}
    local state = getModelState(model)
    local fill, outline = stateColorsFor(state)

    if info.highlight and info.highlight.Parent then
        info.highlight.FillColor = fill
        info.highlight.OutlineColor = outline
    else
        info.highlight = createHighlightForComputer(model, fill, outline, 0.06, 0)
    end

    updateHighlightColorFromScreen(model, info.highlight)

    computerInfo[model] = info
end

local function wireComputerModel(model)
    if not model then return end
    local info = computerInfo[model] or { conns = {} }

    if info.conns then 
        for _, c in ipairs(info.conns) do 
            pcall(function() c:Disconnect() end)
        end 
    end
    info.conns = {}

    local function tryWire(obj)
        if obj:IsA("BoolValue") or obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
            local c = obj.Changed:Connect(function() updateComputerVisual(model) end)
            table.insert(info.conns, c)
        end
    end

    for _, d in ipairs(model:GetDescendants()) do tryWire(d) end

    local addConn = model.DescendantAdded:Connect(function(d)
        tryWire(d)
        updateComputerVisual(model)
    end)
    table.insert(info.conns, addConn)

    computerInfo[model] = info
end

local function scanAndWireExistingComputers()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and isComputerCandidate(d) then
            updateComputerVisual(d)
            wireComputerModel(d)
        end
    end
end

local compAddConn, compRemoveConn
local function enableComputerESP()
    if ComputerESPEnabled then return true end
    ComputerESPEnabled = true

    -- initial pass
    scanAndWireExistingComputers()

    compAddConn = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and isComputerCandidate(obj) then
            updateComputerVisual(obj)
            wireComputerModel(obj)
        end
    end)

    compRemoveConn = workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") and computerInfo[obj] then
            local info = computerInfo[obj]
            if info.highlight then safeDestroy(info.highlight) end
            if info.conns then 
                for _, c in ipairs(info.conns) do 
                    pcall(function() c:Disconnect() end) 
                end 
            end
            computerInfo[obj] = nil
        end
    end)

    return true
end

local function disableComputerESP()
    if not ComputerESPEnabled then return false end
    ComputerESPEnabled = false

    if compAddConn then pcall(function() compAddConn:Disconnect() end); compAddConn = nil end
    if compRemoveConn then pcall(function() compRemoveConn:Disconnect() end); compRemoveConn = nil end

    for mdl, info in pairs(computerInfo) do
        if info.highlight then safeDestroy(info.highlight) end
        if info.conns then 
            for _, c in ipairs(info.conns) do 
                pcall(function() c:Disconnect() end) 
            end 
        end
        computerInfo[mdl] = nil
    end

    return false
end

-- ======================
-- Freeze Pod ESP
-- ======================
local FreezeESPEnabled = false
local freezeHighlights = {}
local freezeAddedConn, freezeRemovedConn

local function isFreezePodModel(m)
    if not m or not m:IsA("Model") then return false end
    local n = m.Name:lower()
    return n:find("freezepod") or (n:find("freeze") and n:find("pod")) or (n:find("freeze") and n:find("capsule"))
end

local function enableFreezeESP()
    if FreezeESPEnabled then return true end
    FreezeESPEnabled = true
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and isFreezePodModel(d) then
            if not freezeHighlights[d] then freezeHighlights[d] = createHighlight(d, Color3.fromRGB(255,100,100), Color3.fromRGB(200,40,40), 0.08, 0) end
        end
    end
    freezeAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not FreezeESPEnabled then return end
        if obj:IsA("Model") and isFreezePodModel(obj) then freezeHighlights[obj] = createHighlight(obj, Color3.fromRGB(255,100,100), Color3.fromRGB(200,40,40), 0.08, 0) end
    end)
    freezeRemovedConn = Workspace.DescendantRemoving:Connect(function(obj) if freezeHighlights[obj] then safeDestroy(freezeHighlights[obj]); freezeHighlights[obj] = nil end end)
    return true
end

local function disableFreezeESP()
    if not FreezeESPEnabled then return false end
    FreezeESPEnabled = false
    if freezeAddedConn then pcall(function() freezeAddedConn:Disconnect() end); freezeAddedConn = nil end
    if freezeRemovedConn then pcall(function() freezeRemovedConn:Disconnect() end); freezeRemovedConn = nil end
    for k,_ in pairs(freezeHighlights) do safeDestroy(freezeHighlights[k]); freezeHighlights[k] = nil end
    return false
end

-- ======================
-- Door ESP
-- ======================
local DoorESPEnabled = false
local doorHighlights = {}
local doorAddedConn, doorRemovedConn

local function isDoorModel(m)
    if not m or not m:IsA("Model") then return false end
    local n = m.Name:lower()
    if n:find("door") then return true end
    if n:find("exitdoor") then return true end
    if (n:find("single") or n:find("double")) and n:find("door") then return true end
    return false
end

local function enableDoorESP()
    if DoorESPEnabled then return true end
    DoorESPEnabled = true
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and isDoorModel(d) then
            if not doorHighlights[d] then doorHighlights[d] = createHighlight(d, Color3.fromRGB(255,230,120), Color3.fromRGB(120,90,20), 1.0, 0) end
        end
    end
    doorAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not DoorESPEnabled then return end
        if obj:IsA("Model") and isDoorModel(obj) then doorHighlights[obj] = createHighlight(obj, Color3.fromRGB(255,230,120), Color3.fromRGB(120,90,20), 1.0, 0) end
    end)
    doorRemovedConn = Workspace.DescendantRemoving:Connect(function(obj) if doorHighlights[obj] then safeDestroy(doorHighlights[obj]); doorHighlights[obj] = nil end end)
    return true
end

local function disableDoorESP()
    if not DoorESPEnabled then return false end
    DoorESPEnabled = false
    if doorAddedConn then pcall(function() doorAddedConn:Disconnect() end); doorAddedConn = nil end
    if doorRemovedConn then pcall(function() doorRemovedConn:Disconnect() end); doorRemovedConn = nil end
    for k,_ in pairs(doorHighlights) do safeDestroy(doorHighlights[k]); doorHighlights[k] = nil end
    return false
end

-- ======================
-- White Brick (textures)
-- ======================
local WhiteBrickActive = false
local whiteBackup = {}

local function isPartPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then return Players:GetPlayerFromCharacter(model) ~= nil end
    return false
end

local function saveAndApplyWhite(part)
    if not part or not part:IsA("BasePart") then return end
    if isPartPlayerCharacter(part) then return end
    if whiteBackup[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    whiteBackup[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
    pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end)
end

local function applyWhiteToAll()
    local desc = Workspace:GetDescendants()
    batchIterate(desc, 200, function(d)
        if d and d:IsA("BasePart") then saveAndApplyWhite(d) end
    end)
end

local whiteDescConn = nil
local function enableWhiteBrick()
    if WhiteBrickActive then return true end
    WhiteBrickActive = true
    task.spawn(applyWhiteToAll)
    whiteDescConn = Workspace.DescendantAdded:Connect(function(d)
        if not WhiteBrickActive then return end
        if d and d:IsA("BasePart") then task.defer(function() saveAndApplyWhite(d) end) end
    end)
    return true
end

local function disableWhiteBrick()
    if not WhiteBrickActive then return false end
    WhiteBrickActive = false
    if whiteDescConn then pcall(function() whiteDescConn:Disconnect() end); whiteDescConn = nil end
    for part, props in pairs(whiteBackup) do
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
    end
    whiteBackup = {}
    return false
end

-- ======================
-- Snow Mode
-- ======================
local SnowActive = false
local snowBackupParts = {}
local snowPartConn = nil
local snowLightingBackup = nil
local snowSkies = {}

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

local function enableSnow()
    if SnowActive then return true end
    SnowActive = true
    backupLightingForSnow()
    for _,v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then
            pcall(function() table.insert(snowSkies, v:Clone()) end)
            pcall(function() v:Destroy() end)
        end
    end
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
    return true
end

local function disableSnow()
    if not SnowActive then return false end
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
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") and v.SkyboxBk == "" then pcall(function() v:Destroy() end) end end
    for _,clone in ipairs(snowSkies) do if clone then pcall(function() clone.Parent = Lighting end) end end
    snowSkies = {}
    restoreLightingFromSnow()
    return false
end

-- ======================
-- Remove Textures (performance)
-- ======================
local RemoveTexturesActive = false
local rt_parts = {}
local rt_meshparts = {}
local rt_decals = {}
local rt_particles = {}
local rt_explosions = {}
local rt_effects = {}
local rt_terrain = {}
local rt_lighting = {}
local rt_quality = nil
local rt_conn = nil

local function rt_store_part(p)
    if not p or not p:IsA("BasePart") then return end
    if rt_parts[p] then return end
    rt_parts[p] = { Material = p.Material, Reflectance = p.Reflectance }
end
local function rt_store_mesh(mp)
    if not mp or not mp:IsA("MeshPart") then return end
    if rt_meshparts[mp] then return end
    rt_meshparts[mp] = { Material = mp.Material, Reflectance = mp.Reflectance, TextureID = mp.TextureID }
end
local function rt_store_decal(d)
    if not d then return end
    if rt_decals[d] then return end
    rt_decals[d] = d.Transparency
end
local function rt_store_particle(e)
    if not e then return end
    if rt_particles[e] then return end
    if e:IsA("ParticleEmitter") or e:IsA("Trail") then rt_particles[e] = { Lifetime = e.Lifetime } end
end
local function rt_store_explosion(ex)
    if not ex or not ex:IsA("Explosion") then return end
    if rt_explosions[ex] then return end
    rt_explosions[ex] = { BlastPressure = ex.BlastPressure, BlastRadius = ex.BlastRadius }
end
local function rt_store_effect(e)
    if not e then return end
    if rt_effects[e] ~= nil then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_effects[e] = e.Enabled
    elseif e:IsA("Fire") or e:IsA("SpotLight") or e:IsA("Smoke") then
        rt_effects[e] = e.Enabled
    end
end

local function applyInstanceForRemove(v)
    if v:IsA("BasePart") then rt_store_part(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end) end
    if v:IsA("Decal") or v:IsA("Texture") then rt_store_decal(v); pcall(function() v.Transparency = 1 end) end
    if v:IsA("ParticleEmitter") or v:IsA("Trail") then rt_store_particle(v); pcall(function() v.Lifetime = NumberRange.new(0) end) end
    if v:IsA("Explosion") then rt_store_explosion(v); pcall(function() v.BlastPressure = 1; v.BlastRadius = 1 end) end
    if v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then rt_store_effect(v); pcall(function() v.Enabled = false end) end
    if v:IsA("MeshPart") then rt_store_mesh(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0; v.TextureID = "rbxassetid://10385902758728957" end) end
end

local function applyLightingChildForRemove(e)
    if not e then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_store_effect(e); pcall(function() e.Enabled = false end)
    end
end

local function enableRemoveTextures()
    if RemoveTexturesActive then return true end
    rt_terrain = {
        WaterWaveSize = Workspace.Terrain.WaterWaveSize,
        WaterWaveSpeed = Workspace.Terrain.WaterWaveSpeed,
        WaterReflectance = Workspace.Terrain.WaterReflectance,
        WaterTransparency = Workspace.Terrain.WaterTransparency
    }
    rt_lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness
    }
    local ok,q = pcall(function() return settings().Rendering.QualityLevel end)
    if ok then rt_quality = q end

    pcall(function()
        local t = Workspace.Terrain
        t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterReflectance = 0; t.WaterTransparency = 0
    end)
    pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 0 end)
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    local desc = Workspace:GetDescendants()
    batchIterate(desc, REMOVE_TEXTURES_BATCH, function(v) applyInstanceForRemove(v) end)
    for _,e in ipairs(Lighting:GetChildren()) do applyLightingChildForRemove(e) end

    rt_conn = Workspace.DescendantAdded:Connect(function(v)
        if not RemoveTexturesActive then return end
        task.defer(function() applyInstanceForRemove(v) end)
    end)

    RemoveTexturesActive = true
    return true
end

local function disableRemoveTextures()
    if not RemoveTexturesActive then return false end
    if rt_conn then pcall(function() rt_conn:Disconnect() end); rt_conn = nil end

    for p, props in pairs(rt_parts) do if p and p.Parent then pcall(function() if props.Material then p.Material = props.Material end; if props.Reflectance then p.Reflectance = props.Reflectance end end) end end
    rt_parts = {}

    for mp, props in pairs(rt_meshparts) do if mp and mp.Parent then pcall(function() if props.Material then mp.Material = props.Material end; if props.Reflectance then mp.Reflectance = props.Reflectance end; if props.TextureID then mp.TextureID = props.TextureID end end) end end
    rt_meshparts = {}

    for d, tr in pairs(rt_decals) do if d and d.Parent then pcall(function() d.Transparency = tr end) end end
    rt_decals = {}

    for e, info in pairs(rt_particles) do if e and e.Parent then pcall(function() e.Lifetime = info.Lifetime end) end end
    rt_particles = {}

    for ex, props in pairs(rt_explosions) do if ex and ex.Parent then pcall(function() if props.BlastPressure then ex.BlastPressure = props.BlastPressure end; if props.BlastRadius then ex.BlastRadius = props.BlastRadius end end) end end
    rt_explosions = {}

    for e, enabled in pairs(rt_effects) do if e and e.Parent then pcall(function() e.Enabled = enabled end) end end
    rt_effects = {}

    if rt_terrain and next(rt_terrain) then
        pcall(function()
            local t = Workspace.Terrain
            if rt_terrain.WaterWaveSize ~= nil then t.WaterWaveSize = rt_terrain.WaterWaveSize end
            if rt_terrain.WaterWaveSpeed ~= nil then t.WaterWaveSpeed = rt_terrain.WaterWaveSpeed end
            if rt_terrain.WaterReflectance ~= nil then t.WaterReflectance = rt_terrain.WaterReflectance end
            if rt_terrain.WaterTransparency ~= nil then t.WaterTransparency = rt_terrain.WaterTransparency end
        end)
    end
    rt_terrain = {}

    if rt_lighting and next(rt_lighting) then
        pcall(function()
            if rt_lighting.GlobalShadows ~= nil then Lighting.GlobalShadows = rt_lighting.GlobalShadows end
            if rt_lighting.FogEnd ~= nil then Lighting.FogEnd = rt_lighting.FogEnd end
            if rt_lighting.Brightness ~= nil then Lighting.Brightness = rt_lighting.Brightness end
        end)
    end
    rt_lighting = {}

    if rt_quality then pcall(function() settings().Rendering.QualityLevel = rt_quality end) end
    rt_quality = nil

    RemoveTexturesActive = false
    return false
end

-- ======================
-- Ragdoll Countdown
-- ======================
local RagdollCountdownActive = false
local ragdoll_whitelist_strings = {
    {49,51,57,52,57,56,53,52,52,48},
    {51,52,54,50,51,56,53,50,57,57},
    {52,55,50,56,50,49,51,57,52,50},
    {52,54,48,51,57,54,48,56,57,51},
    {57,56,52,48,48,57,55,52,53}
}
local ragdoll = {
    screenGui = nil,
    globalFrame = nil,
    uiList = nil,
    globalLabels = {},
    renderConns = {},
    heartbeatConn = nil,
    inputConn = nil,
    playersCharConns = {},
    playerAddedConn = nil
}

local function inFreezePodRagdoll(player)
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return false end
    local ok, parts = pcall(function() return workspace:GetPartsInPart(head) end)
    if not ok or not parts then return false end
    for _, part in ipairs(parts) do
        if part.Parent and part.Parent:IsA("Model") and part.Parent.Name == "FreezePod" then
            local gui = head:FindFirstChild("RagdollCountdown")
            if gui then
                local lbl = gui:FindFirstChild("CountdownLabel")
                if lbl then lbl.Text = "" end
            end
            return true
        end
    end
    return false
end

local function createBillboardCountdownRagdoll(player)
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return nil end
    local billboard = head:FindFirstChild("RagdollCountdown")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "RagdollCountdown"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(3, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = head

        local label = Instance.new("TextLabel", billboard)
        label.Name = "CountdownLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.TextColor3 = Color3.new(1,1,1)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0,0,0)
    end
    return billboard, billboard:FindFirstChild("CountdownLabel")
end

local function clearCountdownRagdoll(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local billboard = player.Character.Head:FindFirstChild("RagdollCountdown")
        if billboard then billboard:Destroy() end
    end
    if player and player.UserId and ragdoll.globalLabels[player.UserId] then
        safeDestroy(ragdoll.globalLabels[player.UserId])
        ragdoll.globalLabels[player.UserId] = nil
    end
    if player and ragdoll.renderConns[player] then
        pcall(function() ragdoll.renderConns[player]:Disconnect() end)
        ragdoll.renderConns[player] = nil
    end
end

local function startCountdownRagdoll(player)
    if not RagdollCountdownActive then return end
    if inFreezePodRagdoll(player) then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local billboard, bbLabel = createBillboardCountdownRagdoll(player)
    if not bbLabel then return end

    local endTime = tick() + DOWN_COUNT_DURATION

    local function update()
        if not RagdollCountdownActive then return end
        if inFreezePodRagdoll(player) then return end
        local remaining = endTime - tick()
        if remaining <= 0 then
            clearCountdownRagdoll(player)
            return
        end
        local formatted = string.format("%.3f", remaining)
        if bbLabel and bbLabel.Parent then
            bbLabel.Text = formatted
        end

        if player and player.UserId then
            local label = ragdoll.globalLabels[player.UserId]
            if not label then
                label = Instance.new("TextLabel")
                label.Name = (player.Name or "Player") .. "_GlobalCountdown"
                label.Size = UDim2.new(1, 0, 0, 30)
                label.BackgroundTransparency = 1
                label.TextScaled = true
                label.Font = Enum.Font.SourceSans
                label.TextColor3 = Color3.new(1,1,1)
                label.TextStrokeTransparency = 0.5
                label.Parent = ragdoll.globalFrame
                ragdoll.globalLabels[player.UserId] = label
            end
            if label and label.Parent then
                label.Text = (player.Name or "Player") .. ": " .. formatted
            end
        end
    end

    if ragdoll.renderConns[player] then
        pcall(function() ragdoll.renderConns[player]:Disconnect() end)
        ragdoll.renderConns[player] = nil
    end
    local conn = RunService.RenderStepped:Connect(update)
    ragdoll.renderConns[player] = conn

    coroutine.wrap(function()
        repeat RunService.Heartbeat:Wait() until tick() >= endTime or not RagdollCountdownActive
        if conn then pcall(function() conn:Disconnect() end) end
        ragdoll.renderConns[player] = nil
        clearCountdownRagdoll(player)
    end)()
end

local function listenForToggleRagdoll(player)
    if ragdoll.inputConn then return end
    local toggleKey = Enum.KeyCode.P
    ragdoll.inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            local p = player
            if p and p.Character and p.Character:FindFirstChild("Head") then
                local billboard = p.Character.Head:FindFirstChild("RagdollCountdown")
                if billboard then
                    clearCountdownRagdoll(p)
                else
                    startCountdownRagdoll(p)
                end
            end
        end
    end)
end

local function updateAllCountdownsRagdoll()
    if not RagdollCountdownActive then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local inRagdoll = humanoid and humanoid.PlatformStand
            local head = character:FindFirstChild("Head")
            local billboard = head and head:FindFirstChild("RagdollCountdown")
            if inRagdoll then
                if not billboard then
                    startCountdownRagdoll(player)
                end
            else
                if billboard then
                    clearCountdownRagdoll(player)
                end
            end
        end
    end
end

local function onCharacterAddedRagdoll(player)
    local function charAdded(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            local childConn
            childConn = char.ChildAdded:Connect(function(child)
                if child and child:IsA("Humanoid") then
                    childConn:Disconnect()
                    listenForToggleRagdoll(player)
                    updateAllCountdownsRagdoll()
                end
            end)
        else
            listenForToggleRagdoll(player)
            updateAllCountdownsRagdoll()
        end
    end
    if ragdoll.playersCharConns[player] then
        pcall(function() ragdoll.playersCharConns[player]:Disconnect() end)
    end
    ragdoll.playersCharConns[player] = player.CharacterAdded:Connect(charAdded)
    if player.Character then
        charAdded(player.Character)
    end
end

local function enableRagdollCountdown()
    if RagdollCountdownActive then return true end
    RagdollCountdownActive = true

    ragdoll.screenGui = Instance.new("ScreenGui")
    ragdoll.screenGui.Name = "RagdollCountdownScreenUI"
    ragdoll.screenGui.Parent = PlayerGui

    ragdoll.globalFrame = Instance.new("Frame")
    ragdoll.globalFrame.Name = "GlobalCountdownFrame"
    ragdoll.globalFrame.Size = UDim2.new(0, 200, 0, 300)
    ragdoll.globalFrame.Position = UDim2.new(1, -210, 0.3, 0)
    ragdoll.globalFrame.BackgroundTransparency = 1
    ragdoll.globalFrame.Parent = ragdoll.screenGui

    ragdoll.uiList = Instance.new("UIListLayout")
    ragdoll.uiList.Parent = ragdoll.globalFrame

    for _, player in ipairs(Players:GetPlayers()) do
        onCharacterAddedRagdoll(player)
    end

    ragdoll.playerAddedConn = Players.PlayerAdded:Connect(function(pl)
        onCharacterAddedRagdoll(pl)
    end)

    ragdoll.heartbeatConn = RunService.Heartbeat:Connect(updateAllCountdownsRagdoll)
    return true
end

local function disableRagdollCountdown()
    if not RagdollCountdownActive then return false end
    RagdollCountdownActive = false

    if ragdoll.heartbeatConn then
        pcall(function() ragdoll.heartbeatConn:Disconnect() end)
        ragdoll.heartbeatConn = nil
    end

    if ragdoll.inputConn then
        pcall(function() ragdoll.inputConn:Disconnect() end)
        ragdoll.inputConn = nil
    end

    for player, conn in pairs(ragdoll.playersCharConns) do
        pcall(function() conn:Disconnect() end)
    end
    ragdoll.playersCharConns = {}

    if ragdoll.playerAddedConn then
        pcall(function() ragdoll.playerAddedConn:Disconnect() end)
        ragdoll.playerAddedConn = nil
    end

    for player, conn in pairs(ragdoll.renderConns) do
        pcall(function() conn:Disconnect() end)
    end
    ragdoll.renderConns = {}

    for _, lbl in pairs(ragdoll.globalLabels) do
        safeDestroy(lbl)
    end
    ragdoll.globalLabels = {}

    if ragdoll.screenGui then
        safeDestroy(ragdoll.screenGui)
        ragdoll.screenGui = nil
    end
    ragdoll.globalFrame = nil
    ragdoll.uiList = nil
    return false
end

-- ======================
-- Beast Power Time
-- ======================
local BeastPowerActive = false
local beast = {
    heartbeatConn = nil,
    playerAddedConn = nil,
    playersCharConns = {},
}

local function createBeastLabel(player)
    if not player or not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        local childConn
        childConn = player.Character.ChildAdded:Connect(function(child)
            if child and child.Name == "HumanoidRootPart" then
                childConn:Disconnect()
                pcall(function() createBeastLabel(player) end)
            end
        end)
        return nil
    end
    local billboard = hrp:FindFirstChild("BeastPowerBillboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "BeastPowerBillboard"
        billboard.Size = UDim2.new(2, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 1
        billboard.Parent = hrp

        local label = Instance.new("TextLabel")
        label.Name = "BeastPowerLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Arcade
        label.TextSize = 20
        label.Text = ""
        label.TextStrokeTransparency = 0.5
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = billboard
    end
    return billboard:FindFirstChild("BeastPowerLabel")
end

local function updateBeastLabels()
    if not BeastPowerActive then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local label = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("BeastPowerBillboard") and player.Character.HumanoidRootPart.BeastPowerBillboard:FindFirstChild("BeastPowerLabel")
        if label then
            local beastPowers = player.Character and player.Character:FindFirstChild("BeastPowers")
            if beastPowers then
                local numberValue = beastPowers:FindFirstChildOfClass("NumberValue")
                if numberValue then
                    local roundedValue = math.round(numberValue.Value * 100)
                    label.Text = tostring(roundedValue) .. "%"
                else
                    label.Text = ""
                end
            else
                label.Text = ""
            end
        end
    end
end

local function onCharacterAddedBeast(player)
    local function charAdded(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            local childConn
            childConn = char.ChildAdded:Connect(function(child)
                if child and child.Name == "HumanoidRootPart" then
                    childConn:Disconnect()
                    if BeastPowerActive then pcall(function() createBeastLabel(player) end) end
                end
            end)
        else
            if BeastPowerActive then pcall(function() createBeastLabel(player) end) end
        end
    end
    if beast.playersCharConns[player] then
        pcall(function() beast.playersCharConns[player]:Disconnect() end)
    end
    beast.playersCharConns[player] = player.CharacterAdded:Connect(charAdded)
    if player.Character then
        charAdded(player.Character)
    end
end

local function enableBeastPowerTime()
    if BeastPowerActive then return true end
    BeastPowerActive = true
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(function() createBeastLabel(player) end)
        end
        onCharacterAddedBeast(player)
    end

    beast.playerAddedConn = Players.PlayerAdded:Connect(function(pl)
        onCharacterAddedBeast(pl)
        if BeastPowerActive then pcall(function() createBeastLabel(pl) end) end
    end)

    beast.heartbeatConn = RunService.Heartbeat:Connect(updateBeastLabels)
    return true
end

local function disableBeastPowerTime()
    if not BeastPowerActive then return false end
    BeastPowerActive = false

    if beast.heartbeatConn then
        pcall(function() beast.heartbeatConn:Disconnect() end)
        beast.heartbeatConn = nil
    end
    if beast.playerAddedConn then
        pcall(function() beast.playerAddedConn:Disconnect() end)
        beast.playerAddedConn = nil
    end
    for player, conn in pairs(beast.playersCharConns) do
        pcall(function() conn:Disconnect() end)
    end
    beast.playersCharConns = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local bb = hrp:FindFirstChild("BeastPowerBillboard")
            if bb then safeDestroy(bb) end
        end
    end
    return false
end

-- ======================
-- Computer ProgressBar (replaced with provided implementation — adjusted to work with this hub)
-- ======================
local ComputerProgressActive = false
local progressEnabled = true -- visible/enabled state for bars & highlights (toggleable with P)
local progressHeartbeatConns = {} -- model -> conn
local progressReloadTask = nil
local progressRunning = false

-- Toggle visibility (P) — toggles enabled state of ProgressBar billboards and ComputerHighlight highlights
local toggleKey = Enum.KeyCode.P
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
        progressEnabled = not progressEnabled
        -- toggle Billboards in our ScreenGui and Highlights in workspace
        for _, descendant in ipairs(ScreenGui:GetDescendants()) do
            if descendant:IsA("BillboardGui") and descendant.Name == "ProgressBar" then
                descendant.Enabled = progressEnabled
            end
        end
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Highlight") and descendant.Name == "ComputerHighlight" then
                descendant.Enabled = progressEnabled
            end
        end
        print("[FTF_ESP] Progress toggled:", progressEnabled)
    end
end)

local function createProgressBar(parentPart)
    if not parentPart or not parentPart:IsA("BasePart") then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProgressBar"
    billboard.Adornee = parentPart
    billboard.Size = UDim2.new(0, 120, 0, 12)
    billboard.StudsOffset = Vector3.new(0, 4.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = progressEnabled
    billboard.Parent = ScreenGui -- parent to hub ScreenGui so it displays

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    background.BorderSizePixel = 2
    background.BorderColor3 = Color3.fromRGB(255, 255, 255)
    background.Parent = billboard

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.Parent = background

    local text = Instance.new("TextLabel")
    text.Name = "ProgressText"
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextScaled = true
    text.Font = Enum.Font.SciFi
    text.Text = "0.0%"
    text.Parent = background

    return billboard, bar, text
end

local function setupComputerProgress(tableModel)
    if not ComputerProgressActive then return end
    if not tableModel or not tableModel:IsA("Model") then return end
    if progressHeartbeatConns[tableModel] then return end

    -- find a good adornee part (Screen, PrimaryPart, or first BasePart)
    local screenPart = tableModel:FindFirstChild("Screen")
    if not (screenPart and screenPart:IsA("BasePart")) then
        if tableModel.PrimaryPart and tableModel.PrimaryPart:IsA("BasePart") then
            screenPart = tableModel.PrimaryPart
        else
            for _,c in ipairs(tableModel:GetDescendants()) do
                if c:IsA("BasePart") then
                    screenPart = c
                    break
                end
            end
        end
    end
    if not screenPart then return end

    local billboard, bar, text = createProgressBar(screenPart)
    if not billboard then return end

    local highlight = tableModel:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
    highlight.Name = "ComputerHighlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = progressEnabled
    highlight.Parent = tableModel

    local savedProgress = 0

    local conn = RunService.Heartbeat:Connect(function()
        if not ComputerProgressActive then return end

        local screen = tableModel:FindFirstChild("Screen")
        if screen and screen:IsA("BasePart") then
            highlight.FillColor = screen.Color
            highlight.OutlineColor = screen.Color
            -- also prefer adornee color if needed
            if billboard and billboard.Parent then
                billboard.Adornee = screen
            end
        end

        local highestTouch = 0
        for _, part in ipairs(tableModel:GetChildren()) do
            if part:IsA("BasePart") and part.Name:match("^ComputerTrigger") then
                for _, touchingPart in ipairs(part:GetTouchingParts()) do
                    local plr = Players:GetPlayerFromCharacter(touchingPart.Parent)
                    if plr then
                        local tpsm = plr:FindFirstChild("TempPlayerStatsModule")
                        if tpsm then
                            local ragdoll = tpsm:FindFirstChild("Ragdoll")
                            local ap = tpsm:FindFirstChild("ActionProgress")
                            if ragdoll and typeof(ragdoll.Value) == "boolean" and not ragdoll.Value then
                                if ap and typeof(ap.Value) == "number" then
                                    highestTouch = math.max(highestTouch, ap.Value)
                                end
                            end
                        end
                    end
                end
            end
        end

        savedProgress = math.max(savedProgress, highestTouch)
        if bar then pcall(function() bar.Size = UDim2.new(savedProgress, 0, 1, 0) end) end

        if savedProgress >= 1 then
            if bar then pcall(function() bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) end) end
            if text then pcall(function() text.Text = "COMPLETED" end) end
        else
            if bar then pcall(function() bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end) end
            if text then pcall(function() text.Text = string.format("%.1f%%", math.floor(savedProgress * 200 + 0.1) / 2) end) end
        end
    end)

    progressHeartbeatConns[tableModel] = { conn = conn, billboard = billboard, highlight = highlight }
end

local function teardownComputerProgress(tableModel)
    if not tableModel then return end
    local info = progressHeartbeatConns[tableModel]
    if info then
        if info.conn then pcall(function() info.conn:Disconnect() end) end
        if info.billboard then safeDestroy(info.billboard) end
        if info.highlight and info.highlight:IsA("Highlight") then safeDestroy(info.highlight) end
        progressHeartbeatConns[tableModel] = nil
    end
end

local function reloadComputersTask()
    while ComputerProgressActive do
        local ok, currentMap = pcall(function() return ReplicatedStorage:FindFirstChild("CurrentMap") end)
        if ok and currentMap then
            local mapValue = currentMap.Value
            if mapValue and tostring(mapValue) ~= "" then
                local map = Workspace:FindFirstChild(tostring(mapValue))
                if map then
                    for _, obj in ipairs(map:GetChildren()) do
                        if obj.Name == "ComputerTable" and obj:IsA("Model") then
                            pcall(function() setupComputerProgress(obj) end)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

local function enableComputerProgress()
    if ComputerProgressActive then return true end
    ComputerProgressActive = true
    progressEnabled = true
    -- clean any leftovers before starting
    for mdl, _ in pairs(progressHeartbeatConns) do
        teardownComputerProgress(mdl)
    end
    progressHeartbeatConns = {}

    progressReloadTask = task.spawn(reloadComputersTask)
    return true
end

local function disableComputerProgress()
    if not ComputerProgressActive then return false end
    ComputerProgressActive = false
    progressEnabled = false

    -- disconnect and destroy all progress components
    for mdl, info in pairs(progressHeartbeatConns) do
        teardownComputerProgress(mdl)
    end
    progressHeartbeatConns = {}

    -- ensure no lingering billboards in ScreenGui
    for _, descendant in ipairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("BillboardGui") and descendant.Name == "ProgressBar" then
            safeDestroy(descendant)
        end
    end
    -- ensure highlights removed
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Highlight") and descendant.Name == "ComputerHighlight" then
            safeDestroy(descendant)
        end
    end

    -- stop reload task if running
    progressReloadTask = nil
    return false
end

-- ======================
-- UI: vertical-left model; close is "X"; menu/draggable
-- (the UI layout has been kept as requested; the Computer ESP now uses the user-provided method)
-- WalkSpeed Quick Input added into Hackers tab (single input)
-- ======================

local LoadingPanel = Instance.new("Frame", ScreenGui)
LoadingPanel.Name = "FTF_LoadingPanel"
LoadingPanel.Size = UDim2.new(0,420,0,120)
LoadingPanel.Position = UDim2.new(0.5, -210, 0.45, -60)
LoadingPanel.BackgroundColor3 = Color3.fromRGB(18,18,20)
LoadingPanel.BorderSizePixel = 0
local lpCorner = Instance.new("UICorner", LoadingPanel); lpCorner.CornerRadius = UDim.new(0,14)
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
local inner = Instance.new("Frame", spinner); inner.Size = UDim2.new(0,24,0,24); inner.Position = UDim2.new(0.5,-12,0.5,-12); inner.BackgroundColor3 = Color3.fromRGB(80,160,255)
local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
spinTween:Play()

local Toast = Instance.new("Frame", ScreenGui)
Toast.Name = "FTF_Toast"
Toast.Size = UDim2.new(0,360,0,46)
Toast.Position = UDim2.new(0.5, -180, 0.02, 0)
Toast.BackgroundColor3 = Color3.fromRGB(20,20,22)
Toast.Visible = false
local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
local toastLabel = Instance.new("TextLabel", Toast)
toastLabel.Size = UDim2.new(1,-48,1,0); toastLabel.Position = UDim2.new(0,12,0,0)
toastLabel.BackgroundTransparency = 1; toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14; toastLabel.TextColor3 = Color3.fromRGB(220,220,220)
toastLabel.Text = "Use the letter K on your keyboard to open the MENU."
local toastClose = Instance.new("TextButton", Toast)
toastClose.Size = UDim2.new(0,28,0,28); toastClose.Position = UDim2.new(1,-40,0.5,-14)
toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)

local MinimizedIcon = Instance.new("ImageButton", ScreenGui)
MinimizedIcon.Name = "FTF_MinimizedIcon"
MinimizedIcon.Size = UDim2.new(0,56,0,56)
MinimizedIcon.Position = UDim2.new(0.02, 0, 0.06, 0)
MinimizedIcon.BackgroundColor3 = Color3.fromRGB(24,24,26)
MinimizedIcon.BorderSizePixel = 0
MinimizedIcon.Visible = false
MinimizedIcon.AutoButtonColor = true
local miCorner = Instance.new("UICorner", MinimizedIcon); miCorner.CornerRadius = UDim.new(0,12)
local miStroke = Instance.new("UIStroke", MinimizedIcon); miStroke.Color = Color3.fromRGB(30,80,130); miStroke.Transparency = 0.7
if tostring(ICON_IMAGE_ID) ~= "" then pcall(function() MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end) end

local function updateMinimizedAvatar()
    pcall(function()
        if Players.GetUserThumbnailAsync then
            local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
            if ok and url and url ~= "" then MinimizedIcon.Image = url end
        end
    end)
end
task.defer(updateMinimizedAvatar)
pcall(function() if LocalPlayer and LocalPlayer.CharacterAppearanceLoaded then LocalPlayer.CharacterAppearanceLoaded:Connect(function() task.delay(0.4, updateMinimizedAvatar) end) end end)

local MobileToggle = Instance.new("TextButton", ScreenGui)
MobileToggle.Name = "FTF_MobileToggle"
MobileToggle.Size = UDim2.new(0,56,0,56)
MobileToggle.Position = UDim2.new(0.02,68,0.06,0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(24,24,26)
MobileToggle.BorderSizePixel = 0
MobileToggle.Text = "☰"
MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.TextColor3 = Color3.fromRGB(220,220,220)
MobileToggle.Visible = UserInputService.TouchEnabled and true or false
local mtCorner = Instance.new("UICorner", MobileToggle); mtCorner.CornerRadius = UDim.new(0,12)

-- Menu dimensions
local MENU_W, MENU_H = 720, 420
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "FTF_Main"
MainFrame.Size = UDim2.new(0, MENU_W, 0, MENU_H)
MainFrame.Position = UDim2.new(0.5, -MENU_W/2, 0.08, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)

-- TitleBar (draggable)
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1,0,0,40)
TitleBar.Position = UDim2.new(0,0,0,0)
TitleBar.BackgroundTransparency = 0.95

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Text = "FTF - David's ESP"
TitleLbl.Font = Enum.Font.GothamSemibold
TitleLbl.TextSize = 14
TitleLbl.TextColor3 = Color3.fromRGB(220,220,220)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position = UDim2.new(0,12,0,8)
TitleLbl.Size = UDim2.new(0,300,0,24)

-- Window control placeholders (Minimize and Close 'X')
local WinControls = Instance.new("Frame", TitleBar)
WinControls.Size = UDim2.new(0,90,0,24)
WinControls.Position = UDim2.new(1,-100,0,8)
WinControls.BackgroundTransparency = 1

local MinimizeBtn = Instance.new("TextButton", WinControls)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Size = UDim2.new(0,36,0,24)
MinimizeBtn.Position = UDim2.new(0,0,0,0)
MinimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)

local CloseBtn = Instance.new("TextButton", WinControls)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0,36,0,24)
CloseBtn.Position = UDim2.new(0,54,0,0)
CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)

-- Sidebar (original categories + "Hackers")
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0,200,1, -40)
Sidebar.Position = UDim2.new(0,0,0,40)
Sidebar.BackgroundTransparency = 1

local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0,14)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0,12)

-- include "Hackers" category
local tabNames = {"ESP","Textures","Timers","Teleport","Hackers"}

local Tabs = {}
local function createSidebarButton(parent, text)
    local btn = Instance.new("TextButton", parent)
    btn.AutoButtonColor = false
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
    btn.BorderSizePixel = 0
    local bCorner = Instance.new("UICorner", btn); bCorner.CornerRadius = UDim.new(0,8)

    local iconFrame = Instance.new("Frame", btn)
    iconFrame.Size = UDim2.new(0,32,0,32)
    iconFrame.Position = UDim2.new(0,8,0.5,-16)
    iconFrame.BackgroundColor3 = Color3.fromRGB(24,24,26)
    local icCorner = Instance.new("UICorner", iconFrame); icCorner.CornerRadius = UDim.new(1,0)
    local iconLabel = Instance.new("TextLabel", iconFrame)
    iconLabel.Size = UDim2.new(1,0,1,0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamSemibold
    iconLabel.TextSize = 18
    iconLabel.TextColor3 = Color3.fromRGB(200,200,200)
    iconLabel.Text = "◉"

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0,52,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text

    return btn, iconFrame, lbl
end

for i,name in ipairs(tabNames) do
    local b, icon, lbl = createSidebarButton(Sidebar, name)
    Tabs[name] = b
end

-- Content area
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -200, 1, -40)
ContentArea.Position = UDim2.new(0,200,0,40)
ContentArea.BackgroundColor3 = Color3.fromRGB(12,12,12)
ContentArea.BorderSizePixel = 0
local contentCorner = Instance.new("UICorner", ContentArea); contentCorner.CornerRadius = UDim.new(0,6)

local LargeTitle = Instance.new("TextLabel", ContentArea)
LargeTitle.Name = "LargeTitle"
LargeTitle.Size = UDim2.new(1, 0, 0, 80)
LargeTitle.Position = UDim2.new(0, 24, 0, 12)
LargeTitle.BackgroundTransparency = 1
LargeTitle.Font = Enum.Font.FredokaOne
LargeTitle.TextSize = 36
LargeTitle.TextColor3 = Color3.fromRGB(240,240,240)
LargeTitle.Text = "Tab"
LargeTitle.TextXAlignment = Enum.TextXAlignment.Left

local ContentScroll = Instance.new("ScrollingFrame", ContentArea)
ContentScroll.Name = "ContentScroll"
ContentScroll.Size = UDim2.new(1, -48, 1, -120)
ContentScroll.Position = UDim2.new(0,24,0,104)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(75,75,75)
ContentScroll.ScrollBarThickness = 8
local contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0,10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 18)
end)

-- Builders (from original script)
local function createToggle(parent, labelText, initial, onToggle)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95,0,0,44); frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    local fc = Instance.new("UICorner", frame); fc.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText
    local sw = Instance.new("TextButton", frame)
    sw.Size = UDim2.new(0,88,0,28); sw.Position = UDim2.new(1,-100,0.5,-14); sw.BackgroundColor3 = Color3.fromRGB(38,38,38); sw.AutoButtonColor = false
    local swc = Instance.new("UICorner", sw); swc.CornerRadius = UDim.new(0,16)
    local swBg = Instance.new("Frame", sw); swBg.Size = UDim2.new(1,-8,1,-8); swBg.Position = UDim2.new(0,4,0,4); swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local swDot = Instance.new("Frame", swBg); swDot.Size = UDim2.new(0,20,0,20)
    local state = initial and true or false
    swDot.Position = UDim2.new(state and 1 or 0, state and -22 or 2, 0.5, -10)
    swDot.BackgroundColor3 = state and Color3.fromRGB(120,200,120) or Color3.fromRGB(180,180,180)
    local dotCorner = Instance.new("UICorner", swDot); dotCorner.CornerRadius = UDim.new(0,10)

    local function updateVisual(s)
        state = s and true or false
        local target = state and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        pcall(function() TweenService:Create(swDot, TweenInfo.new(0.12), {Position = target}):Play() end)
        swDot.BackgroundColor3 = state and Color3.fromRGB(120,200,120) or Color3.fromRGB(160,160,160)
        swBg.BackgroundColor3 = state and Color3.fromRGB(35,90,35) or Color3.fromRGB(60,60,60)
    end

    sw.MouseButton1Click:Connect(function()
        local ok, ret = pcall(onToggle)
        if ok then
            if type(ret) == "boolean" then
                updateVisual(ret)
            else
                updateVisual(not state)
            end
        else
            updateVisual(not state)
        end
    end)

    updateVisual(state)
    return frame, updateVisual, function() return state end, lbl
end

local function createButton(parent, labelText, btnText, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95,0,0,44); frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    local fc = Instance.new("UICorner", frame); fc.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1,-100,0.5,-14); btn.BackgroundColor3 = Color3.fromRGB(38,120,190); btn.AutoButtonColor = false
    local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,12)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = btnText
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return frame, lbl, btn
end

local function clearContent()
    for _,v in pairs(ContentScroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then safeDestroy(v) end end
end

-- ======================
-- WalkSpeed GUI (kept as optional panel but Hackers tab will only show the single input)
-- ======================
local WalkSpeedActive = false
local ws_frame = nil
local ws_numBox = nil
local ws_plus = nil
local ws_minus = nil
local ws_number = nil
local ws_humanoid = nil
local ws_editing = false
local ws_charConn = nil
local ws_humPropConn = nil

local function ws_UpdateNum()
    if ws_numBox then
        ws_numBox.Text = tostring(ws_number or 16)
    end
    if ws_humanoid and ws_number then
        pcall(function() ws_humanoid.WalkSpeed = ws_number end)
    end
end

local function ws_onCharacterAdded(character)
    if ws_humPropConn then
        pcall(function() ws_humPropConn:Disconnect() end)
        ws_humPropConn = nil
    end
    ws_humanoid = nil
    if not character then return end
    ws_humanoid = character:FindFirstChildOfClass("Humanoid")
    if ws_humanoid then
        ws_number = ws_humanoid.WalkSpeed or 16
        ws_humPropConn = ws_humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if ws_humanoid and ws_number and ws_humanoid.WalkSpeed ~= ws_number then
                pcall(function() ws_humanoid.WalkSpeed = ws_number end)
            end
        end)
    else
        ws_number = 16
    end
    ws_UpdateNum()
end

local function createWalkSpeedPanel()
    if ws_frame and ws_frame.Parent then return end
    ws_frame = Instance.new("Frame", ScreenGui)
    ws_frame.Name = "FTF_WalkSpeedPanel"
    ws_frame.Size = UDim2.new(0, 200, 0, 100)
    ws_frame.Position = UDim2.new(0.5, -100, 0.5, -50)
    ws_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ws_frame.Active = true
    pcall(function() ws_frame.Draggable = true end)

    local corner = Instance.new("UICorner", ws_frame); corner.CornerRadius = UDim.new(0,8)

    ws_numBox = Instance.new("TextBox", ws_frame)
    ws_numBox.Size = UDim2.new(0.6, 0, 0.6, 0)
    ws_numBox.Position = UDim2.new(0.2, 0, 0.3, 0)
    ws_numBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ws_numBox.TextColor3 = Color3.new(1, 1, 1)
    ws_numBox.TextScaled = true
    ws_numBox.Font = Enum.Font.SourceSans
    ws_numBox.ClearTextOnFocus = true

    ws_plus = Instance.new("TextButton", ws_frame)
    ws_plus.Size = UDim2.new(0.2, 0, 0.6, 0)
    ws_plus.Position = UDim2.new(0.8, 0, 0.3, 0)
    ws_plus.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    ws_plus.TextColor3 = Color3.new(1, 1, 1)
    ws_plus.TextScaled = true
    ws_plus.Font = Enum.Font.SourceSans
    ws_plus.Text = "+"

    ws_minus = Instance.new("TextButton", ws_frame)
    ws_minus.Size = UDim2.new(0.2, 0, 0.6, 0)
    ws_minus.Position = UDim2.new(0, 0, 0.3, 0)
    ws_minus.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    ws_minus.TextColor3 = Color3.new(1, 1, 1)
    ws_minus.TextScaled = true
    ws_minus.Font = Enum.Font.SourceSans
    ws_minus.Text = "-"

    ws_plus.MouseButton1Click:Connect(function()
        ws_number = (ws_number or 16) + 1
        ws_UpdateNum()
    end)
    ws_minus.MouseButton1Click:Connect(function()
        if (ws_number or 0) > 0 then
            ws_number = ws_number - 1
            ws_UpdateNum()
        end
    end)

    ws_numBox.Focused:Connect(function()
        ws_editing = true
    end)
    ws_numBox.FocusLost:Connect(function(enter)
        ws_editing = false
        if enter then
            local Value = tonumber(ws_numBox.Text)
            if Value and Value > 0 then
                ws_number = Value
                ws_UpdateNum()
            else
                ws_UpdateNum()
            end
        end
    end)

    if LocalPlayer.Character then
        ws_onCharacterAdded(LocalPlayer.Character)
    end
    if ws_charConn then pcall(function() ws_charConn:Disconnect() end) end
    ws_charConn = LocalPlayer.CharacterAdded:Connect(ws_onCharacterAdded)
end

local function destroyWalkSpeedPanel()
    if ws_charConn then pcall(function() ws_charConn:Disconnect() end); ws_charConn = nil end
    if ws_humPropConn then pcall(function() ws_humPropConn:Disconnect() end); ws_humPropConn = nil end
    if ws_frame then safeDestroy(ws_frame); ws_frame = nil end
    ws_numBox = nil; ws_plus = nil; ws_minus = nil
    ws_number = nil; ws_humanoid = nil; ws_editing = false
end

local function enableWalkSpeedGUI()
    if WalkSpeedActive then return true end
    WalkSpeedActive = true
    createWalkSpeedPanel()
    return true
end

local function disableWalkSpeedGUI()
    if not WalkSpeedActive then return false end
    WalkSpeedActive = false
    destroyWalkSpeedPanel()
    return false
end

-- ======================
-- Tab builders
-- ======================
local function buildTexturesTab()
    clearContent()
    local tb1, set1 = createToggle(ContentScroll, "Ativar Textures Tijolos Brancos", WhiteBrickActive, function()
        if WhiteBrickActive then
            disableWhiteBrick()
            return false
        else
            enableWhiteBrick()
            return true
        end
    end)
    tb1.LayoutOrder = 1

    local tb2, set2 = createToggle(ContentScroll, "Snow texture", SnowActive, function()
        if SnowActive then
            disableSnow()
            return false
        else
            enableSnow()
            return true
        end
    end)
    tb2.LayoutOrder = 2

    local tb3, set3 = createToggle(ContentScroll, "Remove Textures (performance)", RemoveTexturesActive, function()
        if RemoveTexturesActive then
            disableRemoveTextures()
            return false
        else
            enableRemoveTextures()
            return true
        end
    end)
    tb3.LayoutOrder = 3
end

local function buildESPTab()
    clearContent()
    local order = 1
    local a1, _ = createToggle(ContentScroll, "ESP Players", PlayerESPEnabled, function()
        if PlayerESPEnabled then
            disablePlayerESP()
            return false
        else
            enablePlayerESP()
            return true
        end
    end)
    a1.LayoutOrder = order; order = order + 1

    local a2, _ = createToggle(ContentScroll, "ESP PCs (state colors)", ComputerESPEnabled, function()
        if ComputerESPEnabled then
            disableComputerESP()
            return false
        else
            enableComputerESP()
            return true
        end
    end)
    a2.LayoutOrder = order; order = order + 1

    local a3, _ = createToggle(ContentScroll, "ESP Freeze Pods", FreezeESPEnabled, function()
        if FreezeESPEnabled then
            disableFreezeESP()
            return false
        else
            enableFreezeESP()
            return true
        end
    end)
    a3.LayoutOrder = order; order = order + 1

    local a4, _ = createToggle(ContentScroll, "ESP Exit Doors", DoorESPEnabled, function()
        if DoorESPEnabled then
            disableDoorESP()
            return false
        else
            enableDoorESP()
            return true
        end
    end)
    a4.LayoutOrder = order; order = order + 1
end

local function buildTimersTab()
    clearContent()
    local tb1, set1 = createToggle(ContentScroll, "Contador de Down", RagdollCountdownActive, function()
        if RagdollCountdownActive then
            disableRagdollCountdown()
            return false
        else
            enableRagdollCountdown()
            return true
        end
    end)
    tb1.LayoutOrder = 1

    local tb2, set2 = createToggle(ContentScroll, "BeastPower Time", BeastPowerActive, function()
        if BeastPowerActive then
            disableBeastPowerTime()
            return false
        else
            enableBeastPowerTime()
            return true
        end
    end)
    tb2.LayoutOrder = 2

    local tb3, set3 = createToggle(ContentScroll, "Computer ProgressBar", ComputerProgressActive, function()
        if ComputerProgressActive then
            disableComputerProgress()
            return false
        else
            enableComputerProgress()
            return true
        end
    end)
    tb3.LayoutOrder = 3
end

local function buildTeleportTab()
    clearContent()
    local order = 1
    local list = Players:GetPlayers()
    table.sort(list, function(a,b) return ((a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
    for _,pl in ipairs(list) do
        if pl ~= LocalPlayer then
            local display = (pl.DisplayName or pl.Name) .. " (" .. pl.Name .. ")"
            local item, _, btn = createButton(ContentScroll, display, "Teleport", function()
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

-- ======================
-- Tab behaviour (including Hackers tab with quick WalkSpeed input only)
-- ======================
local currentTab = tabNames[1]

local function setActiveTab(name)
    currentTab = name or tabNames[1]

    for tName, btn in pairs(Tabs) do
        if tName == currentTab then
            btn.BackgroundColor3 = Color3.fromRGB(34,34,34)
        else
            btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
        end
    end

    LargeTitle.Text = currentTab

    if currentTab == "ESP" then
        pcall(buildESPTab)
    elseif currentTab == "Textures" then
        pcall(buildTexturesTab)
    elseif currentTab == "Timers" then
        pcall(buildTimersTab)
    elseif currentTab == "Teleport" then
        pcall(buildTeleportTab)
    elseif currentTab == "Hackers" then
        clearContent()

        -- input row for WalkSpeed value (single input only)
        local row = Instance.new("Frame", ContentScroll)
        row.Size = UDim2.new(0.95, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(28,28,28)
        local rowCorner = Instance.new("UICorner", row); rowCorner.CornerRadius = UDim.new(0,10)

        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(1, -160, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(210,210,210)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "WalkSpeed (valor)"

        local tb = Instance.new("TextBox", row)
        tb.Size = UDim2.new(0, 100, 0, 28)
        tb.Position = UDim2.new(1, -160, 0.5, -14)
        tb.BackgroundColor3 = Color3.fromRGB(30,30,30)
        tb.TextColor3 = Color3.fromRGB(240,240,240)
        tb.Font = Enum.Font.SourceSans
        tb.TextSize = 18
        tb.TextScaled = false
        tb.ClearTextOnFocus = true
        tb.PlaceholderText = "Ex: 16"

        -- populate with current value (fallback to 16)
        local function getCurrentWalkSpeed()
            local cur = ws_number
            if not cur then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.WalkSpeed then cur = hum.WalkSpeed end
                end
            end
            return cur or 16
        end
        tb.Text = tostring(getCurrentWalkSpeed())

        local applyBtn = Instance.new("TextButton", row)
        applyBtn.Size = UDim2.new(0, 72, 0, 28)
        applyBtn.Position = UDim2.new(1, -86, 0.5, -14)
        applyBtn.BackgroundColor3 = Color3.fromRGB(38,120,190)
        applyBtn.Font = Enum.Font.GothamBold
        applyBtn.TextSize = 14
        applyBtn.TextColor3 = Color3.fromRGB(240,240,240)
        applyBtn.Text = "Aplicar"
        local applyCorner = Instance.new("UICorner", applyBtn); applyCorner.CornerRadius = UDim.new(0,8)

        local function applyValueFromTextbox()
            local v = tonumber(tb.Text)
            if v and v > 0 then
                ws_number = v -- store for the optional walkspeed panel
                -- try to apply to current humanoid
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        pcall(function() hum.WalkSpeed = ws_number end)
                    end
                end
                tb.Text = tostring(ws_number)
            else
                tb.Text = tostring(getCurrentWalkSpeed())
            end
        end

        applyBtn.MouseButton1Click:Connect(applyValueFromTextbox)
        tb.FocusLost:Connect(function(enterPressed)
            if enterPressed then applyValueFromTextbox() end
        end)

        row.LayoutOrder = 1

    else
        clearContent()
    end
end

for name, btn in pairs(Tabs) do
    btn.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

-- Initialize selection
setActiveTab(currentTab)

-- Draggable TitleBar
do
    local dragging = false
    local dragStart = Vector2.new(0,0)
    local startPos = MainFrame.Position

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Close/minimize controls
MinimizeBtn.MouseButton1Click:Connect(function()
    pcall(updateMinimizedAvatar)
    MainFrame.Visible = false
    MinimizedIcon.Visible = true
end)
MinimizedIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizedIcon.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)
MobileToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then MinimizedIcon.Visible = false end
end)

-- Keyboard toggle (K)
local menuOpen = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
        if menuOpen then MinimizedIcon.Visible = false end
    end
end)

-- Finalize startup
task.spawn(function()
    task.wait(1.1)
    safeDestroy(LoadingPanel)
    Toast.Visible = true
    pcall(function() TweenService:Create(Toast, TweenInfo.new(0.28), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play() end)
    task.delay(7.5, function()
        if Toast and Toast.Parent then pcall(function() TweenService:Create(Toast, TweenInfo.new(0.22), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play() end); task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end) end
    end)
    setActiveTab(currentTab)
    MainFrame.Visible = true
    menuOpen = true
end)

-- Expose toggles and utilities globally (same as original) + WalkSpeed
_G.FTF = _G.FTF or {}
_G.FTF.EnablePlayerESP = enablePlayerESP
_G.FTF.DisablePlayerESP = disablePlayerESP
_G.FTF.EnableComputerESP = enableComputerESP
_G.FTF.DisableComputerESP = disableComputerESP
_G.FTF.EnableWhiteBrick = enableWhiteBrick
_G.FTF.DisableWhiteBrick = disableWhiteBrick
_G.FTF.EnableSnow = enableSnow
_G.FTF.DisableSnow = disableSnow
_G.FTF.EnableRagdollCountdown = enableRagdollCountdown
_G.FTF.DisableRagdollCountdown = disableRagdollCountdown
_G.FTF.EnableBeastPowerTime = enableBeastPowerTime
_G.FTF.DisableBeastPowerTime = disableBeastPowerTime
_G.FTF.EnableComputerProgress = enableComputerProgress
_G.FTF.DisableComputerProgress = disableComputerProgress
_G.FTF.EnableWalkSpeedGUI = enableWalkSpeedGUI
_G.FTF.DisableWalkSpeedGUI = disableWalkSpeedGUI

print("[FTF_ESP] Script loaded — Computer ESP replaced with provided method; UI/menu retained. 'Hackers' category now contains WalkSpeed quick input.")
