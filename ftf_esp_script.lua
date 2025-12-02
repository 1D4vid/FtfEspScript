-- FTF ESP — Stable complete LocalScript
-- Features included:
--  - Player ESP (highlight + name tag) with improved visuals
--  - Computer/PC ESP with state-aware colors (blue = ready, green = hacked, red = failed)
--  - Freeze Pod & Door ESP
--  - Down (ragdoll) timer (28s) that starts when ragdoll is detected and updates correctly
--  - Remove Fog toggle (backups & restore)
--  - Remove Textures toggle (heavy performance mode) with backups & restore (batched)
--  - UI: centered non-blocking loading panel, toast, minimize button that minimizes to player's avatar headshot,
--        keyboard "K" to toggle menu, mobile quick toggle
--
-- Notes:
--  - This is a LocalScript and must run on the client (StarterPlayerScripts or equivalent).
--  - The script uses pcall around risky operations to avoid hard errors.
--  - Remove Textures is destructive and attempts to backup many properties to restore them later.
--  - If your game's PC models use very different names for state values, provide names and I can add them.
--  - If you still see an error, copy/paste the exact Output error and I'll patch it.

-- ===== CONFIG =====
local ICON_IMAGE_ID = ""                   -- optional fallback asset id (string/number)
local DOWN_TIME = 28                       -- seconds for down/ ragdoll timer
local REMOVE_TEXTURES_BATCH = 250          -- batch size for heavy loops
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

-- Helpers
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

-- Remove previous GUI(s)
for _,c in pairs(CoreGui:GetChildren()) do
    if c.Name == "FTF_ESP_GUI_DAVID" then pcall(function() c:Destroy() end) end
end
for _,c in pairs(PlayerGui:GetChildren()) do
    if c.Name == "FTF_ESP_GUI_DAVID" then pcall(function() c:Destroy() end) end
end

-- Root ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FTF_ESP_GUI_DAVID"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent or ScreenGui.Parent ~= CoreGui then ScreenGui.Parent = PlayerGui end

-- Styling helper to create highlights with vivid look
local function createHighlight(adorn, fillColor, outlineColor, fillTrans, outlineTrans)
    if not adorn then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = adorn
    h.Parent = Workspace
    h.FillColor = fillColor or Color3.fromRGB(80,180,255)
    h.OutlineColor = outlineColor or Color3.fromRGB(20,40,80)
    h.FillTransparency = (fillTrans ~= nil) and fillTrans or 0.06
    h.OutlineTransparency = (outlineTrans ~= nil) and outlineTrans or 0.0
    h.Enabled = true
    return h
end

-- ============================
-- PLAYER ESP
-- ============================
local PlayerESPEnabled = false
local playerHighlightMap = {}   -- player -> Highlight
local playerNameTagMap = {}     -- player -> BillboardGui

local function isBeast(player)
    return player and player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function createPlayerNameTag(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return end
    safeDestroy(playerNameTagMap[player])
    local bb = Instance.new("BillboardGui", ScreenGui)
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,130,0,26)
    bb.StudsOffset = Vector3.new(0,2.6,0)
    bb.Name = "[FTF_NameTag_"..player.Name.."]"
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(230,230,255)
    lbl.TextStrokeTransparency = 0.7
    lbl.Text = player.DisplayName or player.Name
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    playerNameTagMap[player] = bb
end

local function createPlayerHighlight(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    safeDestroy(playerHighlightMap[player])
    local fill = Color3.fromRGB(80,220,120)
    local outline = Color3.fromRGB(12,80,28)
    if isBeast(player) then
        fill = Color3.fromRGB(255,60,110)
        outline = Color3.fromRGB(140,30,50)
    end
    local h = createHighlight(player.Character, fill, outline, 0.04, 0.0)
    playerHighlightMap[player] = h
end

local function enablePlayerESP()
    if PlayerESPEnabled then return end
    PlayerESPEnabled = true
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            pcall(function() createPlayerHighlight(p); createPlayerNameTag(p) end)
        end
    end
end

local function disablePlayerESP()
    if not PlayerESPEnabled then return end
    PlayerESPEnabled = false
    for p,_ in pairs(playerHighlightMap) do safeDestroy(playerHighlightMap[p]); playerHighlightMap[p] = nil end
    for p,_ in pairs(playerNameTagMap) do safeDestroy(playerNameTagMap[p]); playerNameTagMap[p] = nil end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.06)
        if PlayerESPEnabled then pcall(function() createPlayerHighlight(p); createPlayerNameTag(p) end) end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    safeDestroy(playerHighlightMap[p]); playerHighlightMap[p] = nil
    safeDestroy(playerNameTagMap[p]); playerNameTagMap[p] = nil
end)

-- ============================
-- COMPUTER / PC ESP (state-aware)
-- ============================
local ComputerESPEnabled = false
local computerInfo = {} -- model -> { highlight, billboard, conns }

local function isComputerCandidate(model)
    if not model or not model:IsA("Model") then return false end
    local lower = model.Name:lower()
    if lower:find("computer") or lower:find("pc") or lower:find("terminal") or lower:find("console") then
        return true
    end
    return false
end

-- Look for common Values/Attributes to determine state
local function getModelState(model)
    if not model then return nil end
    -- BoolValue names
    local boolNames = {"Hacked","IsHacked","HackedValue"}
    for _,n in ipairs(boolNames) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BoolValue") then return v.Value and "hacked" or "ready" end
    end
    -- StringValue names
    local strNames = {"State","HackState","Status","Phase"}
    for _,n in ipairs(strNames) do
        local s = model:FindFirstChild(n, true)
        if s and s:IsA("StringValue") then return tostring(s.Value):lower() end
    end
    -- IntValue names (progress)
    local intNames = {"State","StateValue","HackProgress","Progress"}
    for _,n in ipairs(intNames) do
        local iv = model:FindFirstChild(n, true)
        if iv and iv:IsA("IntValue") then
            if iv.Value <= 0 then return "ready" end
            if iv.Value >= 1 then return "hacked" end
            return tostring(iv.Value)
        end
    end
    -- Attributes
    local attrs = {"HackState","State","Status"}
    for _,a in ipairs(attrs) do
        local at = model:GetAttribute(a)
        if at ~= nil then return tostring(at):lower() end
    end
    return nil
end

local function stateColorsFor(s)
    if not s then return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80) end
    s = tostring(s):lower()
    if s:find("ready") or s:find("avail") then
        return Color3.fromRGB(80,150,255), Color3.fromRGB(20,40,80) -- blue
    elseif s:find("hacked") or s:find("done") or s:find("complete") or s == "1" then
        return Color3.fromRGB(90,230,120), Color3.fromRGB(16,80,24) -- green
    elseif s:find("wrong") or s:find("failed") or s:find("error") or s == "-1" then
        return Color3.fromRGB(255,80,80), Color3.fromRGB(120,24,24) -- red
    elseif s:find("progress") or s:find("hacking") then
        return Color3.fromRGB(255,200,90), Color3.fromRGB(130,90,20) -- yellow
    else
        return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80)
    end
end

local function makeModelBillboard(model, txt)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return nil end
    local bb = Instance.new("BillboardGui", ScreenGui)
    bb.Adornee = part
    bb.Size = UDim2.new(0,140,0,34)
    bb.StudsOffset = Vector3.new(0,2.6,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 0.6
    lbl.BackgroundColor3 = Color3.fromRGB(8,8,12)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(230,230,255)
    lbl.Text = txt or ""
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    local c = Instance.new("UICorner", lbl)
    c.CornerRadius = UDim.new(0,8)
    return bb
end

local function updateComputerModelVisual(model)
    if not model then return end
    local info = computerInfo[model] or {}
    local state = getModelState(model)
    local fill, outline = stateColorsFor(state)
    if info.highlight and info.highlight.Parent then
        info.highlight.FillColor = fill
        info.highlight.OutlineColor = outline
    else
        info.highlight = createHighlight(model, fill, outline, 0.06, 0)
    end
    if info.billboard and info.billboard.Parent then
        local lbl = info.billboard:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = tostring(state or "PC") end
    else
        info.billboard = makeModelBillboard(model, tostring(state or "PC"))
    end
    computerInfo[model] = info
end

local function wireModelForChanges(model)
    if not model then return end
    local info = computerInfo[model] or { conns = {} }
    -- disconnect old
    if info.conns then
        for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end
    end
    info.conns = {}
    local function tryWire(obj)
        if obj:IsA("BoolValue") or obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
            local c = obj.Changed:Connect(function() updateComputerModelVisual(model) end)
            table.insert(info.conns, c)
        end
    end
    for _,d in ipairs(model:GetDescendants()) do tryWire(d) end
    local addConn = model.DescendantAdded:Connect(function(d) tryWire(d); updateComputerModelVisual(model) end)
    table.insert(info.conns, addConn)
    computerInfo[model] = info
end

local compAddedConn, compRemovingConn
local function enableComputerESP()
    if ComputerESPEnabled then return end
    ComputerESPEnabled = true
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and isComputerCandidate(d) then
            updateComputerModelVisual(d)
            wireModelForChanges(d)
        end
    end
    compAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not ComputerESPEnabled then return end
        if obj:IsA("Model") and isComputerCandidate(obj) then
            task.delay(0.05, function() updateComputerModelVisual(obj); wireModelForChanges(obj) end)
        elseif obj:IsA("BasePart") then
            local mdl = obj:FindFirstAncestorWhichIsA("Model")
            if mdl and isComputerCandidate(mdl) then task.delay(0.05, function() updateComputerModelVisual(mdl); wireModelForChanges(mdl) end) end
        end
    end)
    compRemovingConn = Workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") and computerInfo[obj] then
            local info = computerInfo[obj]
            if info.highlight then safeDestroy(info.highlight) end
            if info.billboard then safeDestroy(info.billboard) end
            if info.conns then for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end end
            computerInfo[obj] = nil
        end
    end)
end

local function disableComputerESP()
    if not ComputerESPEnabled then return end
    ComputerESPEnabled = false
    if compAddedConn then pcall(function() compAddedConn:Disconnect() end); compAddedConn = nil end
    if compRemovingConn then pcall(function() compRemovingConn:Disconnect() end); compRemovingConn = nil end
    for mdl,info in pairs(computerInfo) do
        if info.highlight then safeDestroy(info.highlight) end
        if info.billboard then safeDestroy(info.billboard) end
        if info.conns then for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end end
        computerInfo[mdl] = nil
    end
end

-- ============================
-- FREEZE POD & DOOR ESP (simple name-based)
-- ============================
local FreezeESPEnabled = false
local freezeHighlights = {}

local function isFreezePodModel(m)
    if not m or not m:IsA("Model") then return false end
    local n = m.Name:lower()
    return n:find("freezepod") or (n:find("freeze") and n:find("pod")) or (n:find("freeze") and n:find("capsule"))
end

local function enableFreezeESP()
    if FreezeESPEnabled then return end
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
end

local function disableFreezeESP()
    if not FreezeESPEnabled then return end
    FreezeESPEnabled = false
    if freezeAddedConn then pcall(function() freezeAddedConn:Disconnect() end); freezeAddedConn = nil end
    if freezeRemovedConn then pcall(function() freezeRemovedConn:Disconnect() end); freezeRemovedConn = nil end
    for k,_ in pairs(freezeHighlights) do safeDestroy(freezeHighlights[k]); freezeHighlights[k] = nil end
end

-- Door ESP
local DoorESPEnabled = false
local doorHighlights = {}

local function isDoorModel(m)
    if not m or not m:IsA("Model") then return false end
    local n = m.Name:lower()
    if n:find("door") then return true end
    if n:find("exitdoor") then return true end
    if (n:find("single") or n:find("double")) and n:find("door") then return true end
    return false
end

local function enableDoorESP()
    if DoorESPEnabled then return end
    DoorESPEnabled = true
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and isDoorModel(d) then
            if not doorHighlights[d] then doorHighlights[d] = createHighlight(d, Color3.fromRGB(255,230,120), Color3.fromRGB(120,90,20), 1.0, 0.0) end
        end
    end
    doorAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not DoorESPEnabled then return end
        if obj:IsA("Model") and isDoorModel(obj) then doorHighlights[obj] = createHighlight(obj, Color3.fromRGB(255,230,120), Color3.fromRGB(120,90,20), 1.0, 0.0) end
    end)
    doorRemovedConn = Workspace.DescendantRemoving:Connect(function(obj) if doorHighlights[obj] then safeDestroy(doorHighlights[obj]); doorHighlights[obj] = nil end end)
end

local function disableDoorESP()
    if not DoorESPEnabled then return end
    DoorESPEnabled = false
    if doorAddedConn then pcall(function() doorAddedConn:Disconnect() end); doorAddedConn = nil end
    if doorRemovedConn then pcall(function() doorRemovedConn:Disconnect() end); doorRemovedConn = nil end
    for k,_ in pairs(doorHighlights) do safeDestroy(doorHighlights[k]); doorHighlights[k] = nil end
end

-- ============================
-- DOWN / RAGDOLL TIMER wiring
-- ============================
local DownDisplayEnabled = false
local downMap = {} -- player -> { gui, endTime }

local function createDownGui(player)
    if downMap[player] then return downMap[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end
    local bb = Instance.new("BillboardGui", ScreenGui)
    bb.Adornee = head
    bb.Size = UDim2.new(0,150,0,44)
    bb.StudsOffset = Vector3.new(0,3.2,0)
    bb.AlwaysOnTop = true
    local frame = Instance.new("Frame", bb)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(12,12,16)
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-12,1,-12); lbl.Position = UDim2.new(0,6,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.fromRGB(230,230,240)
    lbl.Text = tostring(DOWN_TIME).."s"
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    local pbg = Instance.new("Frame", frame)
    pbg.Size = UDim2.new(0.9,0,0,6); pbg.Position = UDim2.new(0.05,0,1,-10)
    pbg.BackgroundColor3 = Color3.fromRGB(30,30,34)
    local pfill = Instance.new("Frame", pbg)
    pfill.Size = UDim2.new(1,0,1,0)
    pfill.BackgroundColor3 = Color3.fromRGB(80,170,255)
    local info = { gui = bb, label = lbl, progress = pfill, endTime = tick() + DOWN_TIME }
    downMap[player] = info
    return info
end

local function removeDownGui(player)
    if downMap[player] then
        safeDestroy(downMap[player].gui)
        downMap[player] = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not DownDisplayEnabled then return end
    local now = tick()
    for player,info in pairs(downMap) do
        if not player or not player.Parent or not info or not info.gui then
            removeDownGui(player)
        else
            local rem = info.endTime - now
            if rem <= 0 then
                removeDownGui(player)
            else
                if info.label and info.label.Parent then info.label.Text = string.format("%.1f s", rem) end
                if info.progress and info.progress.Parent then
                    local frac = math.clamp(rem / DOWN_TIME, 0, 1)
                    info.progress.Size = UDim2.new(frac,0,1,0)
                    if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(80,170,255)
                    elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(255,200,80)
                    else info.progress.BackgroundColor3 = Color3.fromRGB(255,80,80) end
                end
            end
        end
    end
end)

local ragdollConns = {} -- player -> list of conns
local function setPlayerDown(player)
    if not DownDisplayEnabled then return end
    local info = createDownGui(player)
    if info then info.endTime = tick() + DOWN_TIME end
end
local function clearPlayerDown(player) removeDownGui(player) end

local function attachRagdollListeners(player)
    -- cleanup existing
    if ragdollConns[player] then
        for _,c in ipairs(ragdollConns[player]) do pcall(function() c:Disconnect() end) end
    end
    ragdollConns[player] = {}

    local function onCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid") or char:WaitForChild("Humanoid", 5)
        if not hum then return end
        -- TempPlayerStatsModule.Ragdoll (BoolValue) handling
        local temp = player:FindFirstChild("TempPlayerStatsModule") or player:FindFirstChild("TempStats") or player:FindFirstChild("TempPlayerStats")
        if temp then
            local rv = temp:FindFirstChild("Ragdoll")
            if rv and rv:IsA("BoolValue") then
                table.insert(ragdollConns[player], rv.Changed:Connect(function(val)
                    if val then setPlayerDown(player) else clearPlayerDown(player) end
                end))
                if rv.Value then setPlayerDown(player) end
            end
        end
        -- Humanoid state changes
        table.insert(ragdollConns[player], hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown then
                setPlayerDown(player)
            elseif new == Enum.HumanoidStateType.GettingUp or new == Enum.HumanoidStateType.Landed then
                clearPlayerDown(player)
            end
        end))
        -- PlatformStand
        table.insert(ragdollConns[player], hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if hum.PlatformStand then setPlayerDown(player) else clearPlayerDown(player) end
        end))
        -- Health (on death clear)
        table.insert(ragdollConns[player], hum.HealthChanged:Connect(function(h)
            if h <= 0 then clearPlayerDown(player) end
        end))
    end

    local c = player.CharacterAdded:Connect(function(char) task.wait(0.06); onCharacter(char) end)
    table.insert(ragdollConns[player], c)
    if player.Character then onCharacter(player.Character) end
end

for _,p in pairs(Players:GetPlayers()) do attachRagdollListeners(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListeners(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ragdollConns[p] then for _,c in ipairs(ragdollConns[p]) do pcall(function() c:Disconnect() end) end; ragdollConns[p] = nil end
    removeDownGui(p)
end)

-- Toggle for down display
local function toggleDownDisplay()
    DownDisplayEnabled = not DownDisplayEnabled
    if not DownDisplayEnabled then
        for p,_ in pairs(downMap) do removeDownGui(p) end
    end
end

-- ============================
-- REMOVE FOG / REMOVE TEXTURES
-- ============================
-- Remove Fog
local RemoveFogActive = false
local fogBackup = nil
local function enableRemoveFog()
    if RemoveFogActive then return end
    fogBackup = {
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
    if fogBackup then
        pcall(function()
            if fogBackup.FogEnd ~= nil then Lighting.FogEnd = fogBackup.FogEnd end
            if fogBackup.FogStart ~= nil then Lighting.FogStart = fogBackup.FogStart end
            if fogBackup.ClockTime ~= nil then Lighting.ClockTime = fogBackup.ClockTime end
            if fogBackup.Brightness ~= nil then Lighting.Brightness = fogBackup.Brightness end
            if fogBackup.GlobalShadows ~= nil then Lighting.GlobalShadows = fogBackup.GlobalShadows end
        end)
    end
    fogBackup = nil
    RemoveFogActive = false
end

-- Remove Textures (heavy) - backups
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
    if v:IsA("UnionOperation") then rt_store_part(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end) end
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
    if RemoveTexturesActive then return end
    -- backups
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
end

local function disableRemoveTextures()
    if not RemoveTexturesActive then return end
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
end

-- ============================
-- UI creation & wiring
-- ============================
-- Loading panel (center only)
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
spinner.Size = UDim2.new(0,40,0,40); spinner.Position = UDim2.new(1,-64,0,20)
spinner.BackgroundColor3 = Color3.fromRGB(24,24,26)
local spCorner = Instance.new("UICorner", spinner); spCorner.CornerRadius = UDim.new(0,10)
local inner = Instance.new("Frame", spinner)
inner.Size = UDim2.new(0,24,0,24); inner.Position = UDim2.new(0.5, -12, 0.5, -12)
inner.BackgroundColor3 = Color3.fromRGB(80,160,255)
local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
spinTween:Play()

-- Toast
local Toast = Instance.new("Frame", ScreenGui)
Toast.Name = "FTF_Toast"
Toast.Size = UDim2.new(0,360,0,46)
Toast.Position = UDim2.new(0.5, -180, 0.02, 0)
Toast.BackgroundColor3 = Color3.fromRGB(20,20,22)
Toast.BorderSizePixel = 0
Toast.Visible = false
local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
local toastLabel = Instance.new("TextLabel", Toast)
toastLabel.Size = UDim2.new(1,-48,1,0); toastLabel.Position = UDim2.new(0,12,0,0)
toastLabel.BackgroundTransparency = 1; toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14
toastLabel.TextColor3 = Color3.fromRGB(220,220,220)
toastLabel.Text = "Use the letter K on your keyboard to open the MENU."
local toastClose = Instance.new("TextButton", Toast)
toastClose.Size = UDim2.new(0,28,0,28); toastClose.Position = UDim2.new(1,-40,0.5,-14)
toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)

-- Minimized icon (avatar) - initially hidden
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
if tostring(ICON_IMAGE_ID) ~= "" then
    pcall(function() MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end)
end

local function updateMinimizedAvatar()
    pcall(function()
        if Players.GetUserThumbnailAsync then
            local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
            if ok and url and url ~= "" then MinimizedIcon.Image = url end
        end
    end)
end
task.defer(updateMinimizedAvatar)
pcall(function()
    if LocalPlayer and LocalPlayer.CharacterAppearanceLoaded then
        LocalPlayer.CharacterAppearanceLoaded:Connect(function() task.delay(0.4, updateMinimizedAvatar) end)
    end
end)

-- Mobile quick toggle button
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
local mtStroke = Instance.new("UIStroke", MobileToggle); mtStroke.Color = Color3.fromRGB(30,80,130); mtStroke.Transparency = 0.75

-- Main menu frame
local MENU_W, MENU_H = 520, 380
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "FTF_Main"
MainFrame.Size = UDim2.new(0, MENU_W, 0, MENU_H)
MainFrame.Position = UDim2.new(0.5, -MENU_W/2, 0.08, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)

-- Titlebar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundTransparency = 1
local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Text = "FTF - David's ESP"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 16
TitleLbl.TextColor3 = Color3.fromRGB(220,220,220)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position = UDim2.new(0,12,0,12)
TitleLbl.Size = UDim2.new(0,260,0,24)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", TitleBar)
SearchBox.Size = UDim2.new(0, 220, 0, 28)
SearchBox.Position = UDim2.new(1, -240, 0, 10)
SearchBox.BackgroundColor3 = Color3.fromRGB(26,26,26)
SearchBox.TextColor3 = Color3.fromRGB(200,200,200)
SearchBox.ClearTextOnFocus = true
local sbCorner = Instance.new("UICorner", SearchBox); sbCorner.CornerRadius = UDim.new(0,8)

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Size = UDim2.new(0,36,0,36)
MinimizeBtn.Position = UDim2.new(1,-92,0,6)
MinimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)
MinimizeBtn.AutoButtonColor = false

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0,36,0,36)
CloseBtn.Position = UDim2.new(1,-44,0,6)
CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)
CloseBtn.AutoButtonColor = false

-- Tabs
local TabsParent = Instance.new("Frame", MainFrame)
TabsParent.Size = UDim2.new(1, -24, 0, 44)
TabsParent.Position = UDim2.new(0,12,0,56)
TabsParent.BackgroundTransparency = 1

local tabNames = {"ESP","Textures","Timers","Teleport"}
local tabPadding = 10
local tabCount = #tabNames
local tabAvailableWidth = MENU_W - 24
local tabWidth = math.max(80, math.floor((tabAvailableWidth - (tabPadding * (tabCount - 1))) / tabCount))
local Tabs = {}
for i,name in ipairs(tabNames) do
    local x = (i-1) * (tabWidth + tabPadding)
    local t = Instance.new("TextButton", TabsParent)
    t.Size = UDim2.new(0, tabWidth, 0, 34)
    t.Position = UDim2.new(0, x, 0, 4)
    t.Text = name
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(200,200,200)
    t.BackgroundColor3 = Color3.fromRGB(28,28,28)
    t.AutoButtonColor = false
    local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0,12)
    Tabs[name] = t
end

local ContentScroll = Instance.new("ScrollingFrame", MainFrame)
ContentScroll.Name = "ContentScroll"
ContentScroll.Size = UDim2.new(1, -24, 1, -120)
ContentScroll.Position = UDim2.new(0,12,0,112)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(75,75,75)
ContentScroll.ScrollBarThickness = 8
local contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0,10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 18)
end)

-- UI element creators
local function createToggle(parent, labelText, initial, onToggle)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95,0,0,44)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1,-100,0.5,-14)
    btn.BackgroundColor3 = Color3.fromRGB(38,38,38); btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,16)
    local swBg = Instance.new("Frame", btn); swBg.Size = UDim2.new(1,-8,1,-8); swBg.Position = UDim2.new(0,4,0,4); swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local swBgCorner = Instance.new("UICorner", swBg); swBgCorner.CornerRadius = UDim.new(0,14)
    local dot = Instance.new("Frame", swBg); dot.Size = UDim2.new(0,20,0,20)
    dot.Position = UDim2.new(initial and 1 or 0, initial and -22 or 2, 0.5, -10)
    dot.BackgroundColor3 = initial and Color3.fromRGB(120,200,120) or Color3.fromRGB(180,180,180)
    local dotCorner = Instance.new("UICorner", dot); dotCorner.CornerRadius = UDim.new(0,10)
    local state = initial or false
    local function updateVisual(s)
        state = s
        local target = s and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        TweenService:Create(dot, TweenInfo.new(0.12), {Position = target}):Play()
        dot.BackgroundColor3 = s and Color3.fromRGB(120,200,120) or Color3.fromRGB(160,160,160)
        swBg.BackgroundColor3 = s and Color3.fromRGB(35,90,35) or Color3.fromRGB(60,60,60)
    end
    btn.MouseButton1Click:Connect(function()
        pcall(onToggle)
        updateVisual(not state)
    end)
    updateVisual(state)
    return frame, updateVisual, function() return state end, lbl
end

local function createButton(parent, labelText, btnText, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95,0,0,44)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1,-100,0.5,-14)
    btn.BackgroundColor3 = Color3.fromRGB(38,120,190); btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,12)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = btnText
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return frame, lbl, btn
end

-- Category mapping (ties labels to functions/state)
local function buildCategories()
    -- ESP tab entries
    local espList = {
        { label = "ESP Players", get = function() return PlayerESPEnabled end, toggle = function() if PlayerESPEnabled then disablePlayerESP() else enablePlayerESP() end end },
        { label = "ESP PCs", get = function() return ComputerESPEnabled end, toggle = function() if ComputerESPEnabled then disableComputerESP() else enableComputerESP() end end },
        { label = "ESP Freeze Pods", get = function() return FreezeESPEnabled end, toggle = function() if FreezeESPEnabled then disableFreezeESP() else enableFreezeESP() end end },
        { label = "ESP Exit Doors", get = function() return DoorESPEnabled end, toggle = function() if DoorESPEnabled then disableDoorESP() else enableDoorESP() end end },
    }
    local texturesList = {
        { label = "Remove players Textures (Gray Skin)", get = function() return false end, toggle = function() end }, -- left intentionally inert for safety
        { label = "Remove Fog", get = function() return RemoveFogActive end, toggle = function() if RemoveFogActive then disableRemoveFog() else enableRemoveFog() end end },
        { label = "Remove Textures (performance)", get = function() return RemoveTexturesActive end, toggle = function() if RemoveTexturesActive then disableRemoveTextures() else enableRemoveTextures() end end },
    }
    local timersList = {
        { label = "Mostrar contador de Down (28s)", get = function() return DownDisplayEnabled end, toggle = function() toggleDownDisplay() end },
    }
    return espList, texturesList, timersList
end

local espList, texturesList, timersList = buildCategories()

-- Build content for selected tab
local currentTab = "ESP"
local function clearContent()
    for _,c in pairs(ContentScroll:GetChildren()) do
        if c:IsA("Frame") then safeDestroy(c) end
    end
end

local function buildTab(name, filterText)
    filterText = (filterText or ""):lower()
    clearContent()
    if name == "ESP" then
        local order = 1
        for _,entry in ipairs(espList) do
            if filterText == "" or entry.label:lower():find(filterText) then
                local initial = false
                pcall(function() initial = entry.get() end)
                local item, setVisual = createToggle(ContentScroll, entry.label, initial, function() entry.toggle() end)
                item.LayoutOrder = order
                order = order + 1
            end
        end
    elseif name == "Textures" then
        local order = 1
        for _,entry in ipairs(texturesList) do
            if filterText == "" or entry.label:lower():find(filterText) then
                local initial = false
                pcall(function() initial = entry.get() end)
                local item, setVisual = createToggle(ContentScroll, entry.label, initial, function() entry.toggle() end)
                item.LayoutOrder = order
                order = order + 1
            end
        end
    elseif name == "Timers" then
        local order = 1
        for _,entry in ipairs(timersList) do
            if filterText == "" or entry.label:lower():find(filterText) then
                local initial = false
                pcall(function() initial = entry.get() end)
                local item, setVisual = createToggle(ContentScroll, entry.label, initial, function() entry.toggle() end)
                item.LayoutOrder = order
                order = order + 1
            end
        end
    elseif name == "Teleport" then
        local order = 1
        local list = Players:GetPlayers()
        table.sort(list, function(a,b) return ((a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
        for _,pl in ipairs(list) do
            if pl ~= LocalPlayer then
                local display = (pl.DisplayName or pl.Name) .. " (" .. pl.Name .. ")"
                if filterText == "" or display:lower():find(filterText) then
                    local item, lbl, btn = createButton(ContentScroll, display, "Teleport", function()
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
    end
end

-- Tabs wiring
Tabs.ESP.MouseButton1Click:Connect(function()
    currentTab = "ESP"
    Tabs.ESP.BackgroundColor3 = Color3.fromRGB(34,34,34)
    Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28)
    buildTab("ESP", SearchBox.Text)
end)
Tabs.Textures.MouseButton1Click:Connect(function()
    currentTab = "Textures"
    Tabs.Textures.BackgroundColor3 = Color3.fromRGB(34,34,34)
    Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28)
    buildTab("Textures", SearchBox.Text)
end)
Tabs.Timers.MouseButton1Click:Connect(function()
    currentTab = "Timers"
    Tabs.Timers.BackgroundColor3 = Color3.fromRGB(34,34,34)
    Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28)
    buildTab("Timers", SearchBox.Text)
end)
Tabs.Teleport.MouseButton1Click:Connect(function()
    currentTab = "Teleport"
    Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(34,34,34)
    Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28)
    buildTab("Teleport", SearchBox.Text)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    buildTab(currentTab, SearchBox.Text)
end)

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

-- Minimize/restore and mobile toggle
MinimizeBtn.MouseButton1Click:Connect(function()
    pcall(updateMinimizedAvatar)
    MainFrame.Visible = false
    MinimizedIcon.Visible = true
end)
MinimizedIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizedIcon.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
MobileToggle.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible; if MainFrame.Visible then MinimizedIcon.Visible = false end end)

-- Keyboard K toggling
local menuOpen = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
        if menuOpen then MinimizedIcon.Visible = false end
    end
end)

-- Finish loading UI: remove loading panel, show toast & build initial tab
task.spawn(function()
    task.wait(1.1)
    if LoadingPanel and LoadingPanel.Parent then safeDestroy(LoadingPanel) end
    Toast.Visible = true
    pcall(function() TweenService:Create(Toast, TweenInfo.new(0.28), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play() end)
    task.delay(6.8, function()
        if Toast and Toast.Parent then pcall(function() TweenService:Create(Toast, TweenInfo.new(0.22), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play() end); task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end) end
    end)
    buildTab("ESP", "")
    MainFrame.Visible = true
    menuOpen = true
end)

-- Expose some toggles on _G for debugging
_G.FTF = _G.FTF or {}
_G.FTF.EnablePlayerESP = enablePlayerESP
_G.FTF.DisablePlayerESP = disablePlayerESP
_G.FTF.EnableComputerESP = enableComputerESP
_G.FTF.DisableComputerESP = disableComputerESP
_G.FTF.ToggleRemoveFog = function() if RemoveFogActive then disableRemoveFog() else enableRemoveFog() end end
_G.FTF.ToggleRemoveTextures = function() if RemoveTexturesActive then disableRemoveTextures() else enableRemoveTextures() end end
_G.FTF.ToggleDownDisplay = toggleDownDisplay

print("[FTF_ESP] Client script loaded. If there is still an error, copy the exact error message from the Output console and send it so I can patch any remaining issue.")
