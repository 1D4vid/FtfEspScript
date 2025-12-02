-- FTF ESP Script — Complete, fixed and improved
-- Changes in this version (requested):
--  - PC/Computer highlights now reflect hacking state:
--      * Blue = ready to hack
--      * Green = hacked
--      * Red = wrong/failed
--    The script detects common Value/Attribute names under the PC model (flexible).
--  - Down / ragdoll timer fixed and robust: 28 seconds always; detects TempPlayerStatsModule.Ragdoll,
--    Humanoid state changes (Ragdoll/FallingDown/PlatformStand) and Humanoid attribute "Ragdoll".
--    Timer restarts correctly after hit/ragdoll events.
--  - ESP visuals improved (crisper, more vivid colors, stronger outlines).
--  - All previous features (textures, remove fog/textures, minimize icon, loading panel, menu, teleports)
--    remain included.
--
-- NOTE: This script tries to be tolerant to different game implementations. If your game's PC models
-- use custom names for state values, tell me their exact names and I'll add them for more reliable detection.

-- ===== CONFIG =====
local ICON_IMAGE_ID = ""                      -- optional fallback asset id for minimized icon
local DOWN_TIME = 28                          -- down / ragdoll timer (seconds)
local REMOVE_TEXTURES_BATCH_SIZE = 250       -- batch size when removing textures (to avoid freezes)
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

-- Utility
local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

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

-- Clean previous GUIs
for _,v in pairs(CoreGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- ======================================================================
-- IMPROVED ESP (crisper, vivid)
-- We'll create Highlight instances with low FillTransparency and strong Outline.
-- ======================================================================

local function makeHighlight(adornTarget, fillColor, outlineColor, fillTrans, outlineTrans)
    if not adornTarget then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = adornTarget
    h.Parent = Workspace
    h.FillColor = fillColor or Color3.fromRGB(80,180,255)
    h.OutlineColor = outlineColor or Color3.fromRGB(20,40,80)
    -- for vivid look use low transparency (more solid), but not fully opaque to preserve model detail
    h.FillTransparency = (fillTrans ~= nil) and fillTrans or 0.08
    h.OutlineTransparency = (outlineTrans ~= nil) and outlineTrans or 0.0
    h.Enabled = true
    return h
end

-- PLAYER ESP (improved visuals)
local PlayerESPActive = false
local playerHighlights = {}   -- player -> highlight
local playerNameTags = {}     -- player -> BillboardGui

local function isBeast(player)
    return player and player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function createPlayerESP(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    -- name tag
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
    local head = player.Character:FindFirstChild("Head")
    if head then
        local bill = Instance.new("BillboardGui", GUI)
        bill.Name = "[FTF_ESP_Name]" .. player.Name
        bill.Adornee = head
        bill.Size = UDim2.new(0,120,0,24)
        bill.StudsOffset = Vector3.new(0,2.6,0)
        bill.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bill)
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamSemibold
        txt.TextSize = 14
        txt.TextColor3 = Color3.fromRGB(220,220,240)
        txt.TextStrokeTransparency = 0.7
        txt.Text = player.DisplayName or player.Name
        txt.TextXAlignment = Enum.TextXAlignment.Center
        playerNameTags[player] = bill
    end
    -- highlight
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
    local fill = Color3.fromRGB(80,220,120)
    local outline = Color3.fromRGB(12,80,28)
    if isBeast(player) then fill = Color3.fromRGB(255,60,110); outline = Color3.fromRGB(140,30,50) end
    local h = makeHighlight(player.Character, fill, outline, 0.04, 0.0)
    playerHighlights[player] = h
end

local function removePlayerESP(player)
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
end

local function enablePlayerESP()
    if PlayerESPActive then return end
    PlayerESPActive = true
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then pcall(function() createPlayerESP(p) end) end
    end
end

local function disablePlayerESP()
    if not PlayerESPActive then return end
    PlayerESPActive = false
    for p,_ in pairs(playerHighlights) do removePlayerESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.06)
        if PlayerESPActive then createPlayerESP(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

-- ======================================================================
-- COMPUTER / PC ESP with state colors (ready/hacked/wrong)
-- Flexible detection: looks for common Value or Attribute names under model:
-- StringValue/IntValue/BoolValue names: "State","HackState","Hacked","IsHacked","Status","Phase","StateValue"
-- Possible string values: "ready","hacked","wrong","failed","ready_to_hack","done"
-- ======================================================================

local ComputerESPActive = false
local computerInfos = {} -- model -> {highlight, billboard, connections}

local function getComputerStateFromModel(model)
    if not model then return nil end
    -- 1) Check for Bool values named "Hacked" / "IsHacked"
    local candidatesBool = {"Hacked","IsHacked","HackedValue"}
    for _,name in ipairs(candidatesBool) do
        local v = model:FindFirstChild(name, true)
        if v and v:IsA("BoolValue") then
            return v.Value and "hacked" or "ready"
        end
    end
    -- 2) Check for StringValue "State" or "HackState"
    local candidatesString = {"State","HackState","Status","Phase"}
    for _,name in ipairs(candidatesString) do
        local s = model:FindFirstChild(name, true)
        if s and s:IsA("StringValue") then
            return tostring(s.Value):lower()
        end
    end
    -- 3) Check for IntValue "State" or "HackProgress" (progress => ready if 0, hacked if max)
    local candidatesInt = {"State","StateValue","HackProgress"}
    for _,name in ipairs(candidatesInt) do
        local n = model:FindFirstChild(name, true)
        if n and n:IsA("IntValue") then
            return tostring(n.Value)
        end
    end
    -- 4) Check model attribute "HackState" or "State"
    local attrCandidates = {"HackState","State","Status"}
    for _,attr in ipairs(attrCandidates) do
        local a = model:GetAttribute(attr)
        if a ~= nil then
            return tostring(a):lower()
        end
    end
    -- unknown
    return nil
end

local function colorForComputerState(state)
    if not state then
        return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80) -- default cyan
    end
    local s = tostring(state):lower()
    if s:find("ready") or s:find("avail") or s:find("available") then
        return Color3.fromRGB(80,150,255), Color3.fromRGB(20,40,80) -- blue ready
    elseif s:find("hacked") or s:find("done") or s:find("complete") or s == "1" then
        return Color3.fromRGB(90,230,120), Color3.fromRGB(16,80,24) -- green hacked
    elseif s:find("wrong") or s:find("failed") or s:find("error") or s == "-1" then
        return Color3.fromRGB(255,80,80), Color3.fromRGB(120,24,24) -- red wrong
    elseif s:find("progress") or s:find("hacking") then
        return Color3.fromRGB(255,200,90), Color3.fromRGB(130,90,20) -- yellow in-progress
    else
        -- fallback: if numeric string maybe 0=ready, max=done: leave cyan
        return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80)
    end
end

local function makeComputerBillboard(model, text)
    if not model then return nil end
    -- try to get a central part to attach to
    local part = model:FindFirstChildWhichIsA("BasePart") or model.PrimaryPart
    if not part then
        -- fallback: create billboard at model:GetModelCFrame()
        return nil
    end
    local bg = Instance.new("BillboardGui", GUI)
    bg.Name = "[FTF_PC_Status]"
    bg.Adornee = part
    bg.Size = UDim2.new(0,140,0,34)
    bg.StudsOffset = Vector3.new(0,2.6,0)
    bg.AlwaysOnTop = true
    local label = Instance.new("TextLabel", bg)
    label.BackgroundTransparency = 0.6
    label.BackgroundColor3 = Color3.fromRGB(12,12,16)
    label.Size = UDim2.new(1,0,1,0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(230,230,255)
    label.Text = text or ""
    label.TextXAlignment = Enum.TextXAlignment.Center
    local corner = Instance.new("UICorner", label)
    corner.CornerRadius = UDim.new(0,8)
    return bg
end

local function updateComputerVisual(model)
    if not model then return end
    local info = computerInfos[model]
    local state = getComputerStateFromModel(model)
    local fill, outline = colorForComputerState(state)
    if info and info.highlight then
        info.highlight.FillColor = fill
        info.highlight.OutlineColor = outline
        info.highlight.FillTransparency = 0.06
        info.highlight.OutlineTransparency = 0.0
    else
        -- create
        local h = makeHighlight(model, fill, outline, 0.06, 0.0)
        if not info then info = {} end
        info.highlight = h
    end
    if info then
        -- update billboard text if exists or create one
        if info.billboard and info.billboard.Parent then
            local lbl = info.billboard:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = tostring(state or "PC") end
        else
            local b = makeComputerBillboard(model, tostring(state or "PC"))
            info.billboard = b
        end
    end
    computerInfos[model] = info
end

local function attachModelStateListeners(model)
    if not model then return end
    local info = computerInfos[model] or {}
    -- disconnect old
    if info.connections then
        for _,c in ipairs(info.connections) do pcall(function() c:Disconnect() end) end
    end
    info.connections = {}
    -- listen for common Value objects changing anywhere in the model
    local function tryWire(val)
        if not val or not val.Parent then return end
        if val:IsA("BoolValue") or val:IsA("StringValue") or val:IsA("IntValue") or val:IsA("NumberValue") then
            local c = val.Changed:Connect(function()
                updateComputerVisual(model)
            end)
            table.insert(info.connections, c)
        end
    end
    for _,desc in ipairs(model:GetDescendants()) do
        tryWire(desc)
    end
    -- also listen for future descendants that might be added
    local addConn
    addConn = model.DescendantAdded:Connect(function(d)
        tryWire(d)
        -- update immediately as new state might appear
        updateComputerVisual(model)
    end)
    table.insert(info.connections, addConn)
    computerInfos[model] = info
end

local function addComputerModel(model)
    if not model or computerInfos[model] then return end
    updateComputerVisual(model)
    attachModelStateListeners(model)
end

local function removeComputerModel(model)
    local info = computerInfos[model]
    if not info then return end
    if info.highlight then safeDestroy(info.highlight); info.highlight = nil end
    if info.billboard then safeDestroy(info.billboard); info.billboard = nil end
    if info.connections then
        for _,c in ipairs(info.connections) do pcall(function() c:Disconnect() end) end
        info.connections = nil
    end
    computerInfos[model] = nil
end

local compDescAddedConn, compDescRemovingConn
local function enableComputerESPFull()
    if ComputerESPActive then return end
    ComputerESPActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and isComputerModel(d) then pcall(function() addComputerModel(d) end) end
    end
    compDescAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not ComputerESPActive then return end
        if obj:IsA("Model") and isComputerModel(obj) then task.delay(0.05, function() addComputerModel(obj) end) end
        if obj:IsA("BasePart") then
            local mdl = obj:FindFirstAncestorWhichIsA("Model")
            if mdl and isComputerModel(mdl) then task.delay(0.05, function() addComputerModel(mdl) end) end
        end
    end)
    compDescRemovingConn = Workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") and computerInfos[obj] then removeComputerModel(obj) end
    end)
end

local function disableComputerESPFull()
    if not ComputerESPActive then return end
    ComputerESPActive = false
    if compDescAddedConn then pcall(function() compDescAddedConn:Disconnect() end); compDescAddedConn = nil end
    if compDescRemovingConn then pcall(function() compDescRemovingConn:Disconnect() end); compDescRemovingConn = nil end
    for mdl,_ in pairs(computerInfos) do removeComputerModel(mdl) end
end

local function ToggleComputerESP() if ComputerESPActive then disableComputerESPFull() else enableComputerESPFull() end end

-- ======================================================================
-- RAGDOLL / DOWN TIMER — robust detection and correct timer behavior
-- Monitors:
--  - TempPlayerStatsModule.Ragdoll (BoolValue) if present
--  - Humanoid.StateChanged for Ragdoll/FallingDown
--  - Humanoid.PlatformStand attribute/property
--  - Humanoid:GetAttribute("Ragdoll")
-- Creates a Billboard timer and optional bottom UI. Timer is DOWN_TIME.
-- ======================================================================

local downActive = false -- whether we show timers (user toggle)
local ragdollTimers = {} -- player -> {endTime, gui}
local ragdollHumConns = {} -- player -> connections

local function createDownGUIForPlayer(player)
    if ragdollTimers[player] then
        -- refresh endTime externally
        return ragdollTimers[player]
    end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    local bill = Instance.new("BillboardGui", GUI)
    bill.Name = "[FTF_DownTimer]"
    bill.Adornee = head
    bill.Size = UDim2.new(0,150,0,44)
    bill.StudsOffset = Vector3.new(0,3.2,0)
    bill.AlwaysOnTop = true
    local frame = Instance.new("Frame", bill)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(12,12,16)
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-12,1,-12); lbl.Position = UDim2.new(0,6,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Text = tostring(DOWN_TIME) .. "s"
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    local pbarBG = Instance.new("Frame", frame)
    pbarBG.Size = UDim2.new(0.9,0,0,6); pbarBG.Position = UDim2.new(0.05,0,1,-10)
    pbarBG.BackgroundColor3 = Color3.fromRGB(30,30,34)
    local pfill = Instance.new("Frame", pbarBG)
    pfill.Size = UDim2.new(1,0,1,0)
    pfill.BackgroundColor3 = Color3.fromRGB(80,170,255)
    local info = { gui = bill, label = lbl, progress = pfill, endTime = tick() + DOWN_TIME }
    ragdollTimers[player] = info
    return info
end

local function removeDownGUIForPlayer(player)
    if ragdollTimers[player] then
        if ragdollTimers[player].gui and ragdollTimers[player].gui.Parent then safeDestroy(ragdollTimers[player].gui) end
        ragdollTimers[player] = nil
    end
end

local function setPlayerDown(player)
    if not downActive then return end
    local info = createDownGUIForPlayer(player)
    if info then info.endTime = tick() + DOWN_TIME end
end

local function clearPlayerDown(player)
    removeDownGUIForPlayer(player)
end

-- Heartbeat updater for timers
RunService.Heartbeat:Connect(function()
    if not downActive then return end
    local now = tick()
    for player, info in pairs(ragdollTimers) do
        if not player or not player.Parent or not info or not info.gui then
            removeDownGUIForPlayer(player)
        else
            local remaining = info.endTime - now
            if remaining <= 0 then
                removeDownGUIForPlayer(player)
            else
                if info.label and info.label.Parent then
                    info.label.Text = string.format("%.1f s", remaining)
                    info.label.TextColor3 = remaining <= 5 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220,220,230)
                end
                if info.progress and info.progress.Parent then
                    local frac = math.clamp(remaining / DOWN_TIME, 0, 1)
                    info.progress.Size = UDim2.new(frac, 0, 1, 0)
                    if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(80,170,255)
                    elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(255,200,80)
                    else info.progress.BackgroundColor3 = Color3.fromRGB(255,80,80) end
                end
            end
        end
    end
end)

-- Helper to determine ragdoll state for a character
local function checkHumanoidRagdoll(hum)
    if not hum then return false end
    local st = hum:GetState()
    -- Check some states that indicate ragdoll-like
    if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then return true end
    if hum.PlatformStand then return true end
    -- Check attribute if present
    local attr = hum:GetAttribute("Ragdoll")
    if attr ~= nil and attr == true then return true end
    -- Some games put a BoolValue in character
    local b = hum.Parent and hum.Parent:FindFirstChild("Ragdoll")
    if b and b:IsA("BoolValue") and b.Value == true then return true end
    return false
end

-- Attach listeners per player/character
local function attachRagdollListeners(player)
    -- disconnect existing
    if ragdollHumConns[player] then
        for _,c in ipairs(ragdollHumConns[player]) do pcall(function() c:Disconnect() end) end
        ragdollHumConns[player] = nil
    end
    local conns = {}
    local function hookCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum then
            -- wait for humanoid
            hum = char:WaitForChild("Humanoid", 6)
            if not hum then return end
        end
        -- check some Ragdoll value under player's TempPlayerStatsModule
        local temp = player:FindFirstChild("TempPlayerStatsModule") or player:FindFirstChild("TempStats") or player:FindFirstChild("TempPlayerStats")
        if temp and temp:FindFirstChild("Ragdoll") and temp.Ragdoll:IsA("BoolValue") then
            local conn = temp.Ragdoll.Changed:Connect(function(val)
                if val then
                    setPlayerDown(player)
                else
                    clearPlayerDown(player)
                end
            end)
            table.insert(conns, conn)
            -- set initial if true
            if temp.Ragdoll.Value then setPlayerDown(player) end
        end
        -- Humanoid state changed
        local c1 = hum.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown then
                setPlayerDown(player)
            elseif new == Enum.HumanoidStateType.GettingUp or new == Enum.HumanoidStateType.Physics then
                -- some games use GettingUp to indicate recovery
                clearPlayerDown(player)
            end
        end)
        table.insert(conns, c1)
        -- PlatformStand changed
        local c2 = hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if hum.PlatformStand then setPlayerDown(player) else clearPlayerDown(player) end
        end)
        table.insert(conns, c2)
        -- Health change: if health drops to 0 or low, may trigger ragdoll; not auto create timer unless ragdoll detected
        local c3 = hum.HealthChanged:Connect(function(h)
            -- If character dies, clear timer
            if h <= 0 then clearPlayerDown(player) end
        end)
        table.insert(conns, c3)
        -- also check attribute "Ragdoll" on humanoid
        local c4 = hum:GetAttributeChangedSignal and pcall(function()
            local ok, signal = pcall(function() return hum:GetAttributeChangedSignal("Ragdoll") end)
            if ok and signal then
                local connA = hum:GetAttributeChangedSignal("Ragdoll"):Connect(function()
                    if hum:GetAttribute("Ragdoll") then setPlayerDown(player) else clearPlayerDown(player) end
                end)
                table.insert(conns, connA)
            end
        end)
    end
    -- CharacterAdded
    local cadd = player.CharacterAdded:Connect(function(char) task.wait(0.06); hookCharacter(char) end)
    table.insert(conns, cadd)
    -- If already has character, hook it
    if player.Character then hookCharacter(player.Character) end
    ragdollHumConns[player] = conns
end

-- Attach for existing players
for _,p in ipairs(Players:GetPlayers()) do attachRagdollListeners(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListeners(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ragdollHumConns[p] then for _,c in ipairs(ragdollHumConns[p]) do pcall(function() c:Disconnect() end) end; ragdollHumConns[p] = nil end
    if ragdollTimers[p] then removeDownGUIForPlayer(p) end
end)

local function ToggleDownDisplay()
    downActive = not downActive
    if not downActive then
        -- clear all timers
        for p,_ in pairs(ragdollTimers) do removeDownGUIForPlayer(p) end
    end
end

-- ======================================================================
-- REMOVE FOG and REMOVE TEXTURES functionality (kept from previous, with safe backups)
-- ======================================================================

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

-- RemoveTextures heavy (with batching and backups)
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
    elseif e:IsA("Fire") or e:IsA("SpotLight") or e:IsA("Smoke") then
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
    -- backups
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

    local desc = Workspace:GetDescendants()
    batchIterate(desc, REMOVE_TEXTURES_BATCH_SIZE, function(v) rt_apply_to_instance(v) end)
    for _,e in ipairs(Lighting:GetChildren()) do rt_apply_to_lighting_child(e) end

    rt_desc_added_conn = Workspace.DescendantAdded:Connect(function(v)
        if not RemoveTexturesActive then return end
        task.defer(function() rt_apply_to_instance(v) end)
    end)

    RemoveTexturesActive = true
end

local function disableRemoveTextures()
    if not RemoveTexturesActive then return end
    if rt_desc_added_conn then pcall(function() rt_desc_added_conn:Disconnect() end); rt_desc_added_conn = nil end

    for part, props in pairs(rt_backup_parts) do
        if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end; if props.Reflectance then part.Reflectance = props.Reflectance end end) end
    end
    rt_backup_parts = {}

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

    for d, tr in pairs(rt_backup_decals) do if d and d.Parent then pcall(function() d.Transparency = tr end) end end
    rt_backup_decals = {}

    for e, info in pairs(rt_backup_particles) do if e and e.Parent then pcall(function() e.Lifetime = info.Lifetime end) end end
    rt_backup_particles = {}

    for ex, props in pairs(rt_backup_explosions) do if ex and ex.Parent then pcall(function() if props.BlastPressure then ex.BlastPressure = props.BlastPressure end; if props.BlastRadius then ex.BlastRadius = props.BlastRadius end end) end end
    rt_backup_explosions = {}

    for e, enabled in pairs(rt_backup_effects) do if e and e.Parent then pcall(function() e.Enabled = enabled end) end end
    rt_backup_effects = {}

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

    if rt_backup_lighting and next(rt_backup_lighting) then
        pcall(function()
            if rt_backup_lighting.GlobalShadows ~= nil then Lighting.GlobalShadows = rt_backup_lighting.GlobalShadows end
            if rt_backup_lighting.FogEnd ~= nil then Lighting.FogEnd = rt_backup_lighting.FogEnd end
            if rt_backup_lighting.Brightness ~= nil then Lighting.Brightness = rt_backup_lighting.Brightness end
        end)
    end
    rt_backup_lighting = {}

    if rt_backup_quality then pcall(function() settings().Rendering.QualityLevel = rt_backup_quality end) end
    rt_backup_quality = nil

    RemoveTexturesActive = false
end

local function ToggleRemoveTextures() if RemoveTexturesActive then disableRemoveTextures() else enableRemoveTextures() end end

-- ======================================================================
-- UI: minimal loading panel + menu + minimized icon + mobile toggle
-- ======================================================================

local LoadingPanel = Instance.new("Frame", GUI)
LoadingPanel.Name = "FTF_LoadingPanel"
LoadingPanel.Size = UDim2.new(0,420,0,120)
LoadingPanel.Position = UDim2.new(0.5,-210,0.45,-60)
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
lpSub.TextColor3 = Color3.fromRGB(170,170,180); lpSub.Text = "Preparing visuals and timers..."; lpSub.TextXAlignment = Enum.TextXAlignment.Left
local spinner = Instance.new("Frame", LoadingPanel)
spinner.Size = UDim2.new(0,40,0,40); spinner.Position = UDim2.new(1,-64,0,20); spinner.BackgroundColor3 = Color3.fromRGB(24,24,26)
local spCorner = Instance.new("UICorner", spinner); spCorner.CornerRadius = UDim.new(0,10)
local inner = Instance.new("Frame", spinner); inner.Size = UDim2.new(0,24,0,24); inner.Position = UDim2.new(0.5,-12,0.5,-12); inner.BackgroundColor3 = Color3.fromRGB(80,160,255)
local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
spinTween:Play()

local Toast = Instance.new("Frame", GUI)
Toast.Name = "FTF_Toast"; Toast.Size = UDim2.new(0,360,0,46); Toast.Position = UDim2.new(0.5,-180,0.02,0)
Toast.BackgroundColor3 = Color3.fromRGB(20,20,22); Toast.Visible = false
local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
local toastLabel = Instance.new("TextLabel", Toast)
toastLabel.Size = UDim2.new(1,-48,1,0); toastLabel.Position = UDim2.new(0,12,0,0); toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14; toastLabel.TextColor3 = Color3.fromRGB(220,220,220)
toastLabel.Text = "Use the letter K on your keyboard to open the MENU."
local toastClose = Instance.new("TextButton", Toast); toastClose.Size = UDim2.new(0,28,0,28); toastClose.Position = UDim2.new(1,-40,0.5,-14)
toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)

local MinimizedIcon = Instance.new("ImageButton", GUI)
MinimizedIcon.Name = "FTF_MinimizedIcon"; MinimizedIcon.Size = UDim2.new(0,56,0,56); MinimizedIcon.Position = UDim2.new(0.02,0,0.06,0)
MinimizedIcon.BackgroundColor3 = Color3.fromRGB(24,24,26); MinimizedIcon.BorderSizePixel = 0; MinimizedIcon.Visible = false
local miCorner = Instance.new("UICorner", MinimizedIcon); miCorner.CornerRadius = UDim.new(0,12)
local miStroke = Instance.new("UIStroke", MinimizedIcon); miStroke.Color = Color3.fromRGB(30,80,130); miStroke.Transparency = 0.7
if tostring(ICON_IMAGE_ID) ~= "" then pcall(function() MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end) end

local function updateMinimizedIconAvatar()
    pcall(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if ok and url and url ~= "" then MinimizedIcon.Image = url end
    end)
end
task.defer(updateMinimizedIconAvatar)
if LocalPlayer then pcall(function() LocalPlayer.CharacterAppearanceLoaded:Connect(function() task.delay(0.4, updateMinimizedIconAvatar) end) end) end

local MobileToggle = Instance.new("TextButton", GUI)
MobileToggle.Name = "FTF_MobileToggle"; MobileToggle.Size = UDim2.new(0,56,0,56); MobileToggle.Position = UDim2.new(0.02,68,0.06,0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(24,24,26); MobileToggle.BorderSizePixel = 0; MobileToggle.Text = "☰"; MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.TextColor3 = Color3.fromRGB(220,220,220); MobileToggle.Visible = UserInputService.TouchEnabled and true or false
local mtCorner = Instance.new("UICorner", MobileToggle); mtCorner.CornerRadius = UDim.new(0,12)

local MENU_W, MENU_H = 520, 380
local MainFrame = Instance.new("Frame", GUI)
MainFrame.Name = "FTF_Main"; MainFrame.Size = UDim2.new(0,MENU_W,0,MENU_H); MainFrame.Position = UDim2.new(0.5,-MENU_W/2,0.08,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18); MainFrame.BorderSizePixel = 0; MainFrame.Visible = false
local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)

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
        TweenService:Create(toggleDot, TweenInfo.new(0.12), {Position = targetPos}):Play()
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

-- Categories including new Remove Fog and Remove Textures toggles
local Categories = {
    ["ESP"] = {
        { label = "ESP Players", get = function() return PlayerESPActive end, toggle = function() if PlayerESPActive then disablePlayerESP() else enablePlayerESP() end end },
        { label = "ESP PCs", get = function() return ComputerESPActive end, toggle = function() if ComputerESPActive then disableComputerESPFull() else enableComputerESPFull() end end },
        { label = "ESP Freeze Pods", get = function() return FreezePodsActive end, toggle = function() if FreezePodsActive then disableFreezePodsESP() else enableFreezePodsESP() end end },
        { label = "ESP Exit Doors", get = function() return DoorESPActive end, toggle = function() if DoorESPActive then disableDoorESP() else enableDoorESP() end end },
    },
    ["Textures"] = {
        { label = "Remove players Textures", get = function() return GraySkinActive end, toggle = function() ToggleGraySkin() end },
        { label = "Ativar Textures Tijolos Brancos", get = function() return TextureActive end, toggle = function() ToggleTexture() end },
        { label = "Snow texture", get = function() return SnowActive end, toggle = function() ToggleSnow() end },
        { label = "Remove Fog", get = function() return RemoveFogActive end, toggle = function() ToggleRemoveFog() end },
        { label = "Remove Textures", get = function() return RemoveTexturesActive end, toggle = function() ToggleRemoveTextures() end },
    },
    ["Timers"] = {
        { label = "Ativar Contador de Down", get = function() return downActive end, toggle = function() ToggleDownDisplay() end },
    },
}

-- Build content & wire tabs
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
                    -- refresh visual to real state
                    local ok2, newState = pcall(function() return entry.get() end)
                    if ok2 and setVisual then pcall(function() setVisual(newState) end) end
                end)
                item.LayoutOrder = order; order = order + 1
            end
        end
    end
end

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

-- Dragging
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

-- Finish loading
local function finishLoading()
    pcall(function() spinTween:Cancel() end)
    safeDestroy(LoadingPanel)
    Toast.Visible = true
    pcall(function() TweenService:Create(Toast, TweenInfo.new(0.28), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play() end)
    task.delay(7.5, function()
        if Toast and Toast.Parent then
            pcall(function() TweenService:Create(Toast, TweenInfo.new(0.22), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play() end)
            task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end)
        end
    end)
end

-- Initial build and show menu
setActiveTabVisual(TabESP)
buildCategory("ESP", "")
task.spawn(function() task.wait(1.15); MainFrame.Visible = true; menuOpen = true; finishLoading() end)

-- Expose toggles globally (optional)
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
_G.FTF.DisableAllESP = function() disablePlayerESP(); disableComputerESPFull(); disableFreezePodsESP(); disableDoorESP() end

print("[FTF_ESP] Script loaded — improved PC state colors, fixed down timer, crisper ESP.")
