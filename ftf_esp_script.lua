
local P = game:GetService("Players")
local W = game:GetService("Workspace")
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")

local LP = P.LocalPlayer

local gp = nil
local s = pcall(function() gp = CG end)
if not s or not gp then gp = LP:WaitForChild("PlayerGui") end

if gp:FindFirstChild("FTFHub") then gp.FTFHub:Destroy() end

local C = {
	Bg = Color3.fromRGB(18, 18, 24),
	Panel = Color3.fromRGB(28, 28, 36),
	Accent = Color3.fromRGB(80, 160, 255),
	Txt = Color3.fromRGB(230, 230, 230),
	Red = Color3.fromRGB(255, 75, 75),
	Line = Color3.fromRGB(40, 40, 50)
}

local SG = Instance.new("ScreenGui")
SG.Name = "FTFHub"
SG.ResetOnSpawn = false
SG.Parent = gp

local function Drag(area, target)
	local drag, inp, startPos, startTargetPos
	area.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			startPos = i.Position
			startTargetPos = target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then drag = false end
			end)
		end
	end)
	area.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then inp = i end
	end)
	UIS.InputChanged:Connect(function(i)
		if i == inp and drag then
			local d = i.Position - startPos
			TS:Create(target, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {
				Position = UDim2.new(startTargetPos.X.Scale, startTargetPos.X.Offset + d.X, startTargetPos.Y.Scale, startTargetPos.Y.Offset + d.Y)
			}):Play()
		end
	end)
end

local FB = Instance.new("TextButton")
FB.Size = UDim2.new(0, 50, 0, 50)
FB.Position = UDim2.new(0.05, 0, 0.5, -25)
FB.BackgroundColor3 = C.Bg
FB.Text = "FTF"
FB.Font = Enum.Font.GothamBold
FB.TextSize = 16
FB.TextColor3 = C.Txt
FB.Parent = SG
Instance.new("UICorner", FB).CornerRadius = UDim.new(1, 0)
local FBStroke = Instance.new("UIStroke", FB)
FBStroke.Color = C.Line
FBStroke.Thickness = 1

Drag(FB, FB)

local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 380, 0, 260)
MF.Position = UDim2.new(0.5, -190, 0.5, -130)
MF.BackgroundColor3 = C.Bg
MF.ClipsDescendants = true
MF.Visible = false
MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 8)
local MFStroke = Instance.new("UIStroke", MF)
MFStroke.Color = C.Line
MFStroke.Thickness = 1

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 40)
TB.BackgroundTransparency = 1
TB.Parent = MF

local DA = Instance.new("TextButton")
DA.Size = UDim2.new(1, -80, 1, 0)
DA.BackgroundTransparency = 1
DA.Text = ""
DA.Parent = TB
Drag(DA, MF)

local Ttl = Instance.new("TextLabel")
Ttl.Size = UDim2.new(1, -80, 1, 0)
Ttl.Position = UDim2.new(0, 15, 0, 0)
Ttl.BackgroundTransparency = 1
Ttl.Text = "FLEE THE FACILITY"
Ttl.Font = Enum.Font.GothamBold
Ttl.TextSize = 13
Ttl.TextColor3 = C.Txt
Ttl.TextXAlignment = Enum.TextXAlignment.Left
Ttl.Parent = TB

local MinB = Instance.new("TextButton")
MinB.Size = UDim2.new(0, 40, 0, 40)
MinB.Position = UDim2.new(1, -80, 0, 0)
MinB.BackgroundTransparency = 1
MinB.Text = "-"
MinB.Font = Enum.Font.GothamBold
MinB.TextSize = 20
MinB.TextColor3 = C.Txt
MinB.Parent = TB

local ClsB = Instance.new("TextButton")
ClsB.Size = UDim2.new(0, 40, 0, 40)
ClsB.Position = UDim2.new(1, -40, 0, 0)
ClsB.BackgroundTransparency = 1
ClsB.Text = "X"
ClsB.Font = Enum.Font.GothamBold
ClsB.TextSize = 14
ClsB.TextColor3 = C.Red
ClsB.Parent = TB

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, 0, 0, 1)
Sep.Position = UDim2.new(0, 0, 1, 0)
Sep.BackgroundColor3 = C.Line
Sep.BorderSizePixel = 0
Sep.Parent = TB

local CA = Instance.new("ScrollingFrame")
CA.Size = UDim2.new(1, -20, 1, -50)
CA.Position = UDim2.new(0, 10, 0, 45)
CA.BackgroundTransparency = 1
CA.ScrollBarThickness = 2
CA.ScrollBarImageColor3 = C.Accent
CA.CanvasSize = UDim2.new(0, 0, 0, 0)
CA.AutomaticCanvasSize = Enum.AutomaticSize.Y
CA.Parent = MF

local UIL = Instance.new("UIListLayout")
UIL.SortOrder = Enum.SortOrder.LayoutOrder
UIL.Padding = UDim.new(0, 8)
UIL.Parent = CA
Instance.new("UIPadding", CA).PaddingTop = UDim.new(0, 5)

local function Toggle(name, cb)
	local TF = Instance.new("Frame")
	TF.Size = UDim2.new(1, -8, 0, 40)
	TF.BackgroundColor3 = C.Panel
	TF.Parent = CA
	Instance.new("UICorner", TF).CornerRadius = UDim.new(0, 6)

	local Lbl = Instance.new("TextLabel")
	Lbl.Size = UDim2.new(1, -60, 1, 0)
	Lbl.Position = UDim2.new(0, 15, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = name
	Lbl.Font = Enum.Font.GothamMedium
	Lbl.TextSize = 13
	Lbl.TextColor3 = C.Txt
	Lbl.TextXAlignment = Enum.TextXAlignment.Left
	Lbl.Parent = TF

	local SBg = Instance.new("Frame")
	SBg.Size = UDim2.new(0, 36, 0, 18)
	SBg.Position = UDim2.new(1, -46, 0.5, -9)
	SBg.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	SBg.Parent = TF
	Instance.new("UICorner", SBg).CornerRadius = UDim.new(1, 0)

	local SC = Instance.new("Frame")
	SC.Size = UDim2.new(0, 14, 0, 14)
	SC.Position = UDim2.new(0, 2, 0.5, -7)
	SC.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	SC.Parent = SBg
	Instance.new("UICorner", SC).CornerRadius = UDim.new(1, 0)

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	Btn.Parent = TF

	local on = false
	Btn.MouseButton1Click:Connect(function()
		on = not on
		TS:Create(SC, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		}):Play()
		TS:Create(SBg, TweenInfo.new(0.2), {
			BackgroundColor3 = on and C.Accent or Color3.fromRGB(45, 45, 55)
		}):Play()
		if cb then cb(on) end
	end)
end

local pcE = false
local function mkBar(p)
	local b = Instance.new("BillboardGui", p)
	b.Name = "ProgressBar"; b.Size = UDim2.new(0, 120, 0, 12)
	b.StudsOffset = Vector3.new(0, 4.2, 0)
	b.AlwaysOnTop = true; b.Enabled = pcE
	local bg = Instance.new("Frame", b)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bg.BorderSizePixel = 2
	local bar = Instance.new("Frame", bg)
	bar.Name = "Bar"; bar.Size = UDim2.fromScale(0, 1)
	bar.BorderSizePixel = 0
	local txt = Instance.new("TextLabel", bg)
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.TextScaled = true; txt.Font = Enum.Font.SciFi
	return bar, txt
end

local function setupPc(t)
	if t:FindFirstChild("ProgressBar") then return end
	local bar, txt = mkBar(t)
	local sv = 0
	RS.Heartbeat:Connect(function()
		if not pcE then return end
		local mx = 0
		for _, p in ipairs(t:GetChildren()) do
			if p:IsA("BasePart") and p.Name:find("ComputerTrigger") then
				for _, tp in ipairs(p:GetTouchingParts()) do
					local pl = P:GetPlayerFromCharacter(tp.Parent)
					local tpsm = pl and pl:FindFirstChild("TempPlayerStatsModule")
					local ap = tpsm and tpsm:FindFirstChild("ActionProgress")
					local r = tpsm and tpsm:FindFirstChild("Ragdoll")
					if ap and r and not r.Value then mx = math.max(mx, ap.Value) end
				end
			end
		end
		sv = math.max(sv, mx)
		bar.Size = UDim2.fromScale(sv, 1)
		if sv >= 1 then
			bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			txt.Text = "COMPLETED"
		else
			bar.BackgroundColor3 = Color3.new(1, 1, 1)
			txt.Text = string.format("%.1f%%", sv * 100)
		end
	end)
end

task.spawn(function()
	while true do
		local m = RepS:WaitForChild("CurrentMap", 5)
		if m then
			local map = W:FindFirstChild(tostring(m.Value))
			if map then
				for _, o in ipairs(map:GetChildren()) do
					if o.Name == "ComputerTable" then setupPc(o) end
				end
			end
		end
		task.wait(1)
	end
end)

Toggle("Progress Pc", function(v)
	pcE = v
	for _, d in ipairs(W:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == "ProgressBar" then
			d.Enabled = pcE
		end
	end
end)

local espDE = false
local Hls = {}

local function SetupD(door)
	if Hls[door] then return end
	local tar = door:FindFirstChild("Door") or door
	local tri = door:FindFirstChild("DoorTrigger")
	local h = Instance.new("Highlight")
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Enabled = espDE
	h.Parent = tar
	Hls[door] = h
	if tri and tri:FindFirstChild("ActionSign") then
		local val = tri.ActionSign
		local function Upd()
			if h then
				h.FillColor = (val.Value == 11) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
			end
		end
		Upd()
		val:GetPropertyChangedSignal("Value"):Connect(Upd)
	else
		h.FillColor = Color3.fromRGB(255, 0, 0)
	end
end

for _, obj in ipairs(W:GetDescendants()) do
	if obj:IsA("Model") and (obj.Name == "SingleDoor" or obj.Name == "DoubleDoor") then
		SetupD(obj)
	end
end
W.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") and (obj.Name == "SingleDoor" or obj.Name == "DoubleDoor") then
		task.wait(0.1)
		SetupD(obj)
	end
end)

Toggle("Esp Door", function(v)
	espDE = v
	for _, h in pairs(Hls) do
		if h then h.Enabled = espDE end
	end
end)

local guE = false
local GUD = 28
local actG = {}

local guL = Instance.new("Frame", SG)
guL.Size = UDim2.new(0, 240, 0, 300)
guL.Position = UDim2.new(1, -20, 1, -20)
guL.AnchorPoint = Vector2.new(1, 1)
guL.BackgroundTransparency = 1
Instance.new("UIListLayout", guL).VerticalAlignment = Enum.VerticalAlignment.Bottom

local function hum(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function rag(p) local h = hum(p); return h and h.PlatformStand end
local function cap(p) local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart"); return hrp and hrp.Anchored end
local function colS(t) return Color3.fromRGB(255 * (1 - t), 255 * t, 0) end

local function bbG(p)
	local h = p.Character and p.Character:FindFirstChild("Head")
	if not h then return end
	local bb = h:FindFirstChild("RC")
	if bb then return bb.Label end
	bb = Instance.new("BillboardGui", h)
	bb.Name, bb.Size, bb.StudsOffset, bb.AlwaysOnTop = "RC", UDim2.new(2.5, 0, 0.7, 0), Vector3.new(0, 1.9, 0), true
	local t = Instance.new("TextLabel", bb)
	t.Size, t.BackgroundTransparency, t.TextScaled, t.Font = UDim2.fromScale(1, 1), 1, true, Enum.Font.SourceSansBold
	t.Name = "Label"
	return t
end

local function stG(p)
	if actG[p] then return end
	actG[p] = tick()
	local hL = bbG(p)
	local txt = Instance.new("TextLabel", guL)
	txt.Size, txt.BackgroundTransparency, txt.TextScaled, txt.Font, txt.TextXAlignment = UDim2.new(1, 0, 0, 28), 1, true, Enum.Font.GothamBold, Enum.TextXAlignment.Right

	local con; con = RS.RenderStepped:Connect(function()
		if not guE or not rag(p) or cap(p) then
			if p.Character and p.Character:FindFirstChild("Head") then
				local bb = p.Character.Head:FindFirstChild("RC")
				if bb then bb:Destroy() end
			end
			txt:Destroy(); actG[p] = nil; con:Disconnect(); return
		end
		local r = math.max(GUD - (tick() - actG[p]), 0)
		local c = colS(r / GUD)
		if hL then hL.Text, hL.TextColor3 = string.format("%.2fs", r), c end
		txt.Text, txt.TextColor3 = p.Name .. " - " .. string.format("%.2fs", r), c
	end)
end

RS.Heartbeat:Connect(function()
	if not guE then return end
	for _, p in ipairs(P:GetPlayers()) do
		if rag(p) and not cap(p) then stG(p) end
	end
end)

Toggle("Get up", function(v)
	guE = v
	if not v then
		for p, _ in pairs(actG) do
			if p.Character and p.Character:FindFirstChild("Head") then
				local bb = p.Character.Head:FindFirstChild("RC")
				if bb then bb:Destroy() end
			end
		end
		guL:ClearAllChildren()
		Instance.new("UIListLayout", guL).VerticalAlignment = Enum.VerticalAlignment.Bottom
		table.clear(actG)
	end
end)

local bpE = false

local function mkBP(pl)
	local c = pl.Character
	if c then
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bb = hrp:FindFirstChild("BPBill")
			if not bb then
				bb = Instance.new("BillboardGui")
				bb.Name = "BPBill"
				bb.Size = UDim2.new(2, 0, 1, 0)
				bb.StudsOffset = Vector3.new(0, 3, 0)
				bb.AlwaysOnTop = true
				bb.LightInfluence = 1
				bb.Enabled = bpE
				bb.Parent = hrp
				local lbl = Instance.new("TextLabel")
				lbl.Name = "BPLbl"
				lbl.Size = UDim2.new(1, 0, 1, 0)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.Arcade
				lbl.TextSize = 20
				lbl.Text = ""
				lbl.TextStrokeTransparency = 0.5
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
				lbl.Parent = bb
			end
			return bb.BPLbl
		end
	end
	return nil
end

local function upBP()
	if not bpE then return end
	for _, pl in ipairs(P:GetPlayers()) do
		local bpB = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character.HumanoidRootPart:FindFirstChild("BPBill")
		if bpB then
			local lbl = bpB:FindFirstChild("BPLbl")
			local bPs = pl.Character:FindFirstChild("BeastPowers")
			if lbl and bPs then
				local nV = bPs:FindFirstChildOfClass("NumberValue")
				if nV then
					lbl.Text = tostring(math.round(nV.Value * 100)) .. "%"
				else
					lbl.Text = ""
				end
			elseif lbl then
				lbl.Text = ""
			end
		end
	end
end

P.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Connect(function()
		task.wait(1)
		mkBP(pl)
	end)
	task.wait(1)
	mkBP(pl)
end)

for _, pl in ipairs(P:GetPlayers()) do
	if pl ~= LP then mkBP(pl) end
end

RS.Heartbeat:Connect(upBP)

Toggle("BeastPower", function(v)
	bpE = v
	for _, pl in ipairs(P:GetPlayers()) do
		local bpB = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character.HumanoidRootPart:FindFirstChild("BPBill")
		if bpB then
			bpB.Enabled = bpE
		end
	end
end)

FB.MouseButton1Click:Connect(function()
	FB.Visible = false
	MF.Visible = true
	MF.Size = UDim2.new(0, 0, 0, 0)
	MF.Position = UDim2.new(0, FB.AbsolutePosition.X, 0, FB.AbsolutePosition.Y)
	TS:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 380, 0, 260),
		Position = UDim2.new(0.5, -190, 0.5, -130)
	}):Play()
end)

MinB.MouseButton1Click:Connect(function()
	local tw = TS:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0, FB.AbsolutePosition.X, 0, FB.AbsolutePosition.Y)
	})
	tw:Play()
	tw.Completed:Wait()
	MF.Visible = false
	FB.Visible = true
end)

ClsB.MouseButton1Click:Connect(function()
	SG:Destroy()
end)
