local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	repeat task.wait() until Players.LocalPlayer
	LocalPlayer = Players.LocalPlayer
end

pcall(function()
	if LocalPlayer.PlayerGui:FindFirstChild("NexVoidHub") then LocalPlayer.PlayerGui.NexVoidHub:Destroy() end
	if CoreGui:FindFirstChild("NexVoidHub") then CoreGui.NexVoidHub:Destroy() end
end)

local function SendNotification(text, duration)
	pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "NexVoidHub", Text = text, Duration = duration or 3}) end)
end

local viewport = (gethui and gethui()) or (getgenv and getgenv().gethui and getgenv().gethui()) or CoreGui

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexVoidHub"
ScreenGui.Parent = viewport
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10000 
ScreenGui.Enabled = false 

local Theme = {
	FrameColor = Color3.fromRGB(12, 12, 12),
	ContentColor = Color3.fromRGB(20, 20, 20),
	ItemColor = Color3.fromRGB(30, 30, 30),
	ItemStroke = Color3.fromRGB(60, 60, 60),
	SwitchOff = Color3.fromRGB(40, 40, 40), 
	Accent = Color3.fromRGB(240, 240, 240),
    AccentDark = Color3.fromRGB(160, 160, 160),
	Text = Color3.fromRGB(255, 255, 255), 
	TextDark = Color3.fromRGB(150, 150, 150),
	Font = Enum.Font.GothamBold,
	CloseRed = Color3.fromRGB(100, 100, 100)
}

local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false}
local CurrentSoundIDs = {Running = 0, Jumping = 0, Landing = 0}
local OriginalSoundBackups = {}

local function formatID(id)
	if type(id) == "number" and id > 0 then return "rbxassetid://" .. id
	elseif type(id) == "string" and id ~= "" and id ~= "0" then
        if not id:find("rbxassetid://") then return "rbxassetid://" .. id else return id end
	end
	return nil
end

local function replaceSounds(character)
	task.spawn(function()
		local rootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not rootPart then return end
		task.wait(0.5)
        if not OriginalSoundBackups[character] then
            OriginalSoundBackups[character] = {}
            for name, _ in pairs(CurrentSoundIDs) do
                local existingSound = rootPart:FindFirstChild(name)
                if existingSound and existingSound:IsA("Sound") then OriginalSoundBackups[character][name] = existingSound.SoundId end
            end
        end
		for soundName, soundId in pairs(CurrentSoundIDs) do
            local sound = rootPart:FindFirstChild(soundName)
            if soundId == 0 then
                if sound and OriginalSoundBackups[character] and OriginalSoundBackups[character][soundName] then
                    sound.SoundId = OriginalSoundBackups[character][soundName]
                end
            else
                local validId = formatID(soundId)
                if validId then
                    if sound and sound:IsA("Sound") then sound.SoundId = validId
                    else
                        local newSound = Instance.new("Sound")
                        newSound.Name = soundName
                        newSound.Parent = rootPart
                        newSound.SoundId = validId
                    end
                end
            end
		end
	end)
end

local function RefreshAllSounds() for _, player in ipairs(Players:GetPlayers()) do if player.Character then replaceSounds(player.Character) end end end
local function setupPlayerSoundEvents(player)
	if player.Character then replaceSounds(player.Character) end
	player.CharacterAdded:Connect(function(newCharacter) replaceSounds(newCharacter) end)
end
for _, player in ipairs(Players:GetPlayers()) do setupPlayerSoundEvents(player) end
Players.PlayerAdded:Connect(setupPlayerSoundEvents)

local function ProcessCharacter(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    local function MuteLogic(soundObj, typeName)
        if not soundObj then return end
        local targetVol = 0.5
        if typeName == "Running" then targetVol = 1.0 end
        if char == LocalPlayer.Character then
            if typeName == "Running" and LegitSettings.MuteSteps then targetVol = 0 end
            if (typeName == "Jumping" or typeName == "Landing") and LegitSettings.MuteJumps then targetVol = 0 end
        end
        soundObj.Volume = targetVol
        soundObj:GetPropertyChangedSignal("Volume"):Connect(function()
            if char == LocalPlayer.Character then
                if typeName == "Running" and LegitSettings.MuteSteps then soundObj.Volume = 0 
                elseif (typeName == "Jumping" or typeName == "Landing") and LegitSettings.MuteJumps then soundObj.Volume = 0 end
            end
        end)
    end
    task.spawn(function()
        local s1 = root:WaitForChild("Running", 5)
        if s1 then MuteLogic(s1, "Running") end
        local s2 = root:WaitForChild("Jumping", 5)
        if s2 then MuteLogic(s2, "Jumping") end
        local s3 = root:WaitForChild("Landing", 5)
        if s3 then MuteLogic(s3, "Landing") end
    end)
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(ProcessCharacter) end)
for _, p in pairs(Players:GetPlayers()) do if p.Character then ProcessCharacter(p.Character) end
p.CharacterAdded:Connect(ProcessCharacter) end

local CurrentCursorSize = 24
local PCCursorActive = false
local MobileCrosshair = Instance.new("ImageLabel")
MobileCrosshair.Name = "MobileCrosshair"
MobileCrosshair.Size = UDim2.new(0, CurrentCursorSize, 0, CurrentCursorSize)
MobileCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
MobileCrosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
MobileCrosshair.BackgroundTransparency = 1
MobileCrosshair.Image = ""
MobileCrosshair.Visible = false
MobileCrosshair.ZIndex = 99
MobileCrosshair.Parent = ScreenGui 
local PCSoftwareCursor = Instance.new("ImageLabel")
PCSoftwareCursor.Name = "PCCursor"
PCSoftwareCursor.Size = UDim2.new(0, CurrentCursorSize, 0, CurrentCursorSize)
PCSoftwareCursor.AnchorPoint = Vector2.new(0.5, 0.5)
PCSoftwareCursor.BackgroundTransparency = 1
PCSoftwareCursor.Image = ""
PCSoftwareCursor.Visible = false
PCSoftwareCursor.ZIndex = 10000
PCSoftwareCursor.Parent = ScreenGui

local function UpdateCursorSizes(val) CurrentCursorSize = val
MobileCrosshair.Size = UDim2.new(0, val, 0, val)
PCSoftwareCursor.Size = UDim2.new(0, val, 0, val) end
RunService.RenderStepped:Connect(function() if PCCursorActive then UserInputService.MouseIconEnabled = false
local mousePos = UserInputService:GetMouseLocation()
PCSoftwareCursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y) else if UserInputService.MouseIconEnabled == false and not PCCursorActive then UserInputService.MouseIconEnabled = true end end end)

local function ApplyGradient(instance, color1, color2, rotation)
    local gradient = instance:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, color1), ColorSequenceKeypoint.new(1.00, color2)}
    gradient.Rotation = rotation or 45
    gradient.Parent = instance
    return gradient
end

local AnimatedTextGradients = {}
local function ApplyAnimatedTextGradient(instance)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(140, 140, 140)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(140, 140, 140)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)), 
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(140, 140, 140)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(140, 140, 140))
    }
    gradient.Rotation = 20
    gradient.Parent = instance
    table.insert(AnimatedTextGradients, gradient)
    return gradient
end

RunService.RenderStepped:Connect(function()
    local time = tick() * 0.6 
    local offset = (time % 2) - 1 
    for _, grad in ipairs(AnimatedTextGradients) do
        if grad.Parent then
            grad.Offset = Vector2.new(offset, 0)
        end
    end
end)

local isMobile = UserInputService.TouchEnabled

local ConfigFileName = "NexVoidHub_Config.json"
local UserConfigs = { ToggleKey = "K" }

local function LoadConfigs()
	pcall(function()
		if isfile and isfile(ConfigFileName) and readfile then
			local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
			if decoded and type(decoded) == "table" then
				for k, v in pairs(decoded) do
					UserConfigs[k] = v
				end
			end
		end
	end)
end
LoadConfigs()

local CurrentKey = Enum.KeyCode[UserConfigs.ToggleKey] or Enum.KeyCode.K

local function SaveConfigs()
	UserConfigs.ToggleKey = CurrentKey.Name
	pcall(function()
		if writefile then writefile(ConfigFileName, HttpService:JSONEncode(UserConfigs)) end
	end)
end

local function ResetConfigs()
	pcall(function()
		if delfile and isfile and isfile(ConfigFileName) then
			delfile(ConfigFileName)
		end
	end)
	UserConfigs = { ToggleKey = "K" }
	CurrentKey = Enum.KeyCode.K
end

local Config = {
	MainSize = isMobile and UDim2.new(0, 520, 0, 365) or UDim2.new(0, 600, 0, 420),
	SidebarWidth = isMobile and 130 or 150,
	FooterHeight = 18, 
	BtnHeight = isMobile and 25 or 32, 
	ListPadding = UDim.new(0, 5), 
	FontSize = isMobile and 11 or 13,
	IconSize = isMobile and 14 or 18
}

local ContentConfig = {
	ItemHeight = 40,
	PlayerCardHeight = 50,
	ItemPadding = UDim.new(0, 6)
}

local function MakeDraggable(triggerObject, frameObject)
	local dragging = false
	local dragInput, dragStart, startPos
	triggerObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
            dragStart = input.Position
            startPos = frameObject.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	triggerObject.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frameObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = Config.MainSize
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
MainFrame.BackgroundColor3 = Theme.FrameColor 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = true
MainFrame.Visible = false 
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
ApplyGradient(MainStroke, Theme.Accent, Color3.fromRGB(20,20,20), -45)

local AnimeBg = Instance.new("ImageLabel")
AnimeBg.Name = "AnimeBackground"
AnimeBg.Size = UDim2.new(1, 0, 1, 0)
AnimeBg.Image = "rbxassetid://72302772727492" 
AnimeBg.ScaleType = Enum.ScaleType.Crop
AnimeBg.BackgroundTransparency = 1
AnimeBg.ZIndex = 1
AnimeBg.Parent = MainFrame

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.new(0,0,0)
DarkOverlay.BackgroundTransparency = 0.65 
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.new(0,0,0)
TopBar.BackgroundTransparency = 0.5
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = MainFrame
MakeDraggable(TopBar, MainFrame)
local TopDiv = Instance.new("Frame")
TopDiv.Size = UDim2.new(1,0,0,1)
TopDiv.Position = UDim2.new(0,0,1,0)
TopDiv.BorderSizePixel=0
TopDiv.Parent = TopBar
ApplyGradient(TopDiv, Color3.new(0,0,0), Theme.Accent, 0) 

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Text = "Nex<font color='rgb(150,150,150)'>Void Released</font>"
TitleLabel.RichText = true
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Theme.Font
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0, 45, 0, 0)
TitleLabel.ZIndex = 4
TitleLabel.Parent = TopBar
local LogoIcon = Instance.new("ImageLabel")
LogoIcon.Image = "rbxassetid://"
LogoIcon.Size = UDim2.new(0, 20, 0, 20)
LogoIcon.Position = UDim2.new(0, 15, 0.5, -10)
LogoIcon.BackgroundTransparency = 1
LogoIcon.ScaleType = Enum.ScaleType.Fit
LogoIcon.ImageColor3 = Theme.Accent
LogoIcon.ZIndex = 4
LogoIcon.Parent = TopBar

local OpenButton = Instance.new("ImageButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 45, 0, 45)
OpenButton.AnchorPoint = Vector2.new(0, 0)
OpenButton.Position = UDim2.new(0, 15, 0, 60)
OpenButton.BackgroundColor3 = Theme.FrameColor
OpenButton.Image = "rbxassetid://138188957887846"
OpenButton.Visible = false
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 4)
local OBS = Instance.new("UIStroke")
OBS.Color = Theme.Accent
OBS.Thickness = 1.5
OBS.Parent = OpenButton
ApplyGradient(OBS, Theme.Accent, Color3.fromRGB(50,50,50), 45)
MakeDraggable(OpenButton, OpenButton)

local function createTopBtn(name, icon, offsetOrder, isImage)
	local Btn
	if isImage then
		Btn = Instance.new("ImageButton")
        Btn.Image = "rbxassetid://" .. icon
        Btn.ScaleType = Enum.ScaleType.Fit
        local iconSize = (name == "Search") and 22 or 16
        Btn.ImageTransparency = 1
        local Inner = Instance.new("ImageLabel")
        Inner.Size = UDim2.new(0, iconSize, 0, iconSize)
        Inner.Position = UDim2.new(0.5, -(iconSize/2), 0.5, -(iconSize/2))
        Inner.BackgroundTransparency = 1
        Inner.Image = "rbxassetid://" .. icon
        Inner.ImageColor3 = Theme.TextDark
        Inner.ScaleType = Enum.ScaleType.Fit
        Inner.ZIndex = 4
        Inner.Parent = Btn
        Btn.MouseEnter:Connect(function() Inner.ImageColor3 = Theme.Accent end)
        Btn.MouseLeave:Connect(function() Inner.ImageColor3 = Theme.TextDark end)
	else
		Btn = Instance.new("TextButton")
        Btn.Text = icon
        Btn.Font = Enum.Font.GothamBlack
        Btn.TextSize = 16
        Btn.TextColor3 = Theme.TextDark
        if icon == "-" then
            Btn.Text = ""
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(0, 12, 0, 2)
            Line.Position = UDim2.new(0.5, -6, 0.5, 0)
            Line.BackgroundColor3 = Theme.TextDark
            Line.BorderSizePixel = 0
            Line.ZIndex = 4
            Line.Parent = Btn
            Btn.MouseEnter:Connect(function() Line.BackgroundColor3 = Theme.Accent end)
            Btn.MouseLeave:Connect(function() Line.BackgroundColor3 = Theme.TextDark end)
        else
            Btn.MouseEnter:Connect(function() Btn.TextColor3 = Theme.CloseRed end)
            Btn.MouseLeave:Connect(function() Btn.TextColor3 = Theme.TextDark end)
        end
	end
	Btn.Name = name
    Btn.Parent = TopBar
    Btn.BackgroundTransparency = 1
    Btn.ZIndex = 4
    Btn.Position = UDim2.new(1, -(40 * offsetOrder), 0, 0)
    Btn.Size = UDim2.new(0, 40, 1, 0)
    return Btn
end

local CloseBtn = createTopBtn("Close", "X", 1, false)
local MinimizeBtn = createTopBtn("Minimize", "-", 2, false)
local SettingsBtn = createTopBtn("Settings", "11293977610", 3, true)
local SearchBtn = createTopBtn("Search", "104986431790017", 4, true) 

local SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(0, 0, 0, 26)
SearchContainer.Position = UDim2.new(1, -165, 0.5, -13)
SearchContainer.AnchorPoint = Vector2.new(1, 0)
SearchContainer.BackgroundColor3 = Theme.ContentColor
SearchContainer.BorderSizePixel = 0
SearchContainer.ClipsDescendants = true
SearchContainer.ZIndex = 4
SearchContainer.Parent = TopBar
Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 4)
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -10, 1, 0)
SearchBox.Position = UDim2.new(0, 10, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.TextColor3 = Theme.Text
SearchBox.PlaceholderColor3 = Theme.TextDark
SearchBox.Font = Theme.Font
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 5
SearchBox.Parent = SearchContainer

local CenterContainer = Instance.new("Frame")
CenterContainer.Name = "CenterContainer"
CenterContainer.Size = UDim2.new(1, 0, 1, -(40 + Config.FooterHeight))
CenterContainer.Position = UDim2.new(0, 0, 0, 40)
CenterContainer.BackgroundTransparency = 1
CenterContainer.ZIndex = 3
CenterContainer.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, Config.SidebarWidth, 1, 0)
Sidebar.BackgroundColor3 = Color3.new(0,0,0)
Sidebar.BackgroundTransparency = 0.6
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = CenterContainer
local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = Config.ListPadding
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar
local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar 

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -Config.SidebarWidth, 1, 0)
ContentArea.Position = UDim2.new(0, Config.SidebarWidth, 0, 0)
ContentArea.BackgroundColor3 = Color3.new(0,0,0)
ContentArea.BackgroundTransparency = 0.7
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 3
ContentArea.Parent = CenterContainer

local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, 0, 0, Config.FooterHeight)
BottomBar.Position = UDim2.new(0, 0, 1, -Config.FooterHeight)
BottomBar.BackgroundColor3 = Color3.new(0,0,0)
BottomBar.BackgroundTransparency = 0.5
BottomBar.BorderSizePixel = 0
BottomBar.ZIndex = 5
BottomBar.Parent = MainFrame

local StatusText = Instance.new("TextLabel")
StatusText.RichText = true
local modeText = isMobile and "Mobile" or "PC"
StatusText.Text = "Menu Base <font color='rgb(200,200,200)'>" .. modeText .. "</font> | Editado"
StatusText.Size = UDim2.new(1, -5, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Theme.Text
StatusText.Font = Theme.Font
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Right
StatusText.ZIndex = 6
StatusText.Parent = BottomBar

local ModalOverlay = Instance.new("Frame")
ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
ModalOverlay.BackgroundColor3 = Color3.new(0,0,0)
ModalOverlay.BackgroundTransparency = 0.5
ModalOverlay.Visible = false
ModalOverlay.ZIndex = 10
ModalOverlay.Parent = MainFrame
local function createModalBox(height)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 280, 0, height)
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Box.BackgroundColor3 = Theme.FrameColor
    Box.BorderSizePixel = 0
    Box.ZIndex = 11
    Box.Visible = false
    Box.Parent = ModalOverlay
    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Theme.ItemStroke
    BoxStroke.Parent = Box
    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 2)
    TopLine.BackgroundColor3 = Theme.Accent
    TopLine.BorderSizePixel = 0
    TopLine.ZIndex = 12
    TopLine.Parent = Box
    ApplyGradient(TopLine, Theme.Accent, Theme.AccentDark, 0)
    return Box
end

local ExitBox = createModalBox(120)
local YesBtn = Instance.new("TextButton")
YesBtn.Parent = ExitBox
YesBtn.Size = UDim2.new(0, 90, 0, 30)
YesBtn.Position = UDim2.new(0, 20, 0, 75)
YesBtn.Text = "Exit"
YesBtn.BackgroundColor3 = Theme.CloseRed
YesBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 4)

local NoBtn = Instance.new("TextButton")
NoBtn.Parent = ExitBox
NoBtn.Size = UDim2.new(0, 90, 0, 30)
NoBtn.Position = UDim2.new(1, -110, 0, 75)
NoBtn.Text = "Cancel"
NoBtn.BackgroundColor3 = Theme.ContentColor
NoBtn.TextColor3 = Theme.TextDark
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 4)

local ExitTitle = Instance.new("TextLabel")
ExitTitle.Parent = ExitBox
ExitTitle.Text = "CONFIRMATION"
ExitTitle.Font = Theme.Font
ExitTitle.TextSize = 14
ExitTitle.TextColor3 = Theme.Accent
ExitTitle.Size = UDim2.new(1, 0, 0, 35)
ExitTitle.BackgroundTransparency = 1

local ExitDesc = Instance.new("TextLabel")
ExitDesc.Parent = ExitBox
ExitDesc.Text = "Exit the Script?"
ExitDesc.Font = Enum.Font.Gotham
ExitDesc.TextSize = 14
ExitDesc.TextColor3 = Theme.Text
ExitDesc.Size = UDim2.new(1, 0, 0, 30)
ExitDesc.Position = UDim2.new(0, 0, 0, 35)
ExitDesc.BackgroundTransparency = 1

local SettingsBox = createModalBox(320)
local SetTitle = Instance.new("TextLabel")
SetTitle.Parent = SettingsBox
SetTitle.Text = "SETTINGS"
SetTitle.Size = UDim2.new(1,0,0,35)
SetTitle.TextColor3 = Theme.Accent
SetTitle.BackgroundTransparency = 1
SetTitle.Font = Theme.Font
SetTitle.TextSize = 14

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Text = "Menu Keybind:"
KeyLabel.Font = Enum.Font.Gotham
KeyLabel.TextSize = 12
KeyLabel.TextColor3 = Theme.Text
KeyLabel.Size = UDim2.new(0, 100, 0, 30)
KeyLabel.Position = UDim2.new(0, 15, 0, 45)
KeyLabel.BackgroundTransparency = 1
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyLabel.Parent = SettingsBox

local KeyBtn = Instance.new("TextButton")
KeyBtn.Parent = SettingsBox
KeyBtn.Text = CurrentKey.Name
KeyBtn.Size = UDim2.new(0, 80, 0, 26)
KeyBtn.Position = UDim2.new(1, -100, 0, 47)
KeyBtn.BackgroundColor3 = Theme.ContentColor
KeyBtn.TextColor3 = Theme.Accent
Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 4)

local KeyDesc = Instance.new("TextLabel")
KeyDesc.Parent = SettingsBox
KeyDesc.Text = "Sets the key to Open and Close this menu."
KeyDesc.Size = UDim2.new(1, -30, 0, 15)
KeyDesc.Position = UDim2.new(0, 15, 0, 75)
KeyDesc.BackgroundTransparency = 1
KeyDesc.Font = Enum.Font.Gotham
KeyDesc.TextSize = 10
KeyDesc.TextColor3 = Theme.TextDark
KeyDesc.TextXAlignment = Enum.TextXAlignment.Left
KeyDesc.TextWrapped = true

local SaveCfgBtn = Instance.new("TextButton")
SaveCfgBtn.Parent = SettingsBox
SaveCfgBtn.Text = "Save Configurations"
SaveCfgBtn.Size = UDim2.new(0, 250, 0, 30)
SaveCfgBtn.Position = UDim2.new(0, 15, 0, 110)
SaveCfgBtn.BackgroundColor3 = Theme.Accent
SaveCfgBtn.TextColor3 = Color3.new(0,0,0)
SaveCfgBtn.Font = Theme.Font
SaveCfgBtn.TextSize = 12
Instance.new("UICorner", SaveCfgBtn).CornerRadius = UDim.new(0, 4)
ApplyGradient(SaveCfgBtn, Theme.Accent, Theme.AccentDark, 90)

local SaveDesc = Instance.new("TextLabel")
SaveDesc.Parent = SettingsBox
SaveDesc.Text = "Saves ALL your enabled options (Toggles, Sliders, Inputs) and your Keybind so they load automatically on your next execution."
SaveDesc.Size = UDim2.new(1, -30, 0, 25)
SaveDesc.Position = UDim2.new(0, 15, 0, 145)
SaveDesc.BackgroundTransparency = 1
SaveDesc.Font = Enum.Font.Gotham
SaveDesc.TextSize = 10
SaveDesc.TextColor3 = Theme.TextDark
SaveDesc.TextXAlignment = Enum.TextXAlignment.Center
SaveDesc.TextWrapped = true

local ResetCfgBtn = Instance.new("TextButton")
ResetCfgBtn.Parent = SettingsBox
ResetCfgBtn.Text = "Reset Configurations"
ResetCfgBtn.Size = UDim2.new(0, 250, 0, 30)
ResetCfgBtn.Position = UDim2.new(0, 15, 0, 185)
ResetCfgBtn.BackgroundColor3 = Theme.CloseRed
ResetCfgBtn.TextColor3 = Color3.new(1,1,1)
ResetCfgBtn.Font = Theme.Font
ResetCfgBtn.TextSize = 12
Instance.new("UICorner", ResetCfgBtn).CornerRadius = UDim.new(0, 4)

local ResetDesc = Instance.new("TextLabel")
ResetDesc.Parent = SettingsBox
ResetDesc.Text = "Deletes all saved data and restores the script to its default state."
ResetDesc.Size = UDim2.new(1, -30, 0, 25)
ResetDesc.Position = UDim2.new(0, 15, 0, 220)
ResetDesc.BackgroundTransparency = 1
ResetDesc.Font = Enum.Font.Gotham
ResetDesc.TextSize = 10
ResetDesc.TextColor3 = Theme.TextDark
ResetDesc.TextXAlignment = Enum.TextXAlignment.Center
ResetDesc.TextWrapped = true

local CloseSetBtn = Instance.new("TextButton")
CloseSetBtn.Parent = SettingsBox
CloseSetBtn.Text = "Close"
CloseSetBtn.Size = UDim2.new(0, 250, 0, 30)
CloseSetBtn.Position = UDim2.new(0, 15, 0, 270)
CloseSetBtn.BackgroundColor3 = Theme.ContentColor
CloseSetBtn.TextColor3 = Theme.TextDark
Instance.new("UICorner", CloseSetBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function() ModalOverlay.Visible = true
ExitBox.Visible = true
SettingsBox.Visible = false end)
SettingsBtn.MouseButton1Click:Connect(function() ModalOverlay.Visible = true
SettingsBox.Visible = true
ExitBox.Visible = false end)
CloseSetBtn.MouseButton1Click:Connect(function() ModalOverlay.Visible = false
SettingsBox.Visible = false end)
NoBtn.MouseButton1Click:Connect(function() ModalOverlay.Visible = false
ExitBox.Visible = false end)
YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
KeyBtn.MouseButton1Click:Connect(function() KeyBtn.Text = "..."
local input = UserInputService.InputBegan:Wait()
if input.KeyCode ~= Enum.KeyCode.Unknown then CurrentKey = input.KeyCode
KeyBtn.Text = CurrentKey.Name end end)

SaveCfgBtn.MouseButton1Click:Connect(function() 
	SaveConfigs()
	SaveCfgBtn.Text = "Saved Successfully!"
	task.wait(1.5)
	SaveCfgBtn.Text = "Save Configurations" 
end)

ResetCfgBtn.MouseButton1Click:Connect(function() 
	ResetConfigs()
	KeyBtn.Text = "K"
	ResetCfgBtn.Text = "Reset Successfully!"
	task.wait(1.5)
	ResetCfgBtn.Text = "Reset Configurations" 
end)

local isSearching = false
SearchBtn.MouseButton1Click:Connect(function()
	isSearching = not isSearching
	if isSearching then SearchContainer:TweenSize(UDim2.new(0, 150, 0, 26), "Out", "Quad", 0.3, true)
        task.wait(0.1)
        SearchBox:CaptureFocus() 
	else SearchContainer:TweenSize(UDim2.new(0, 0, 0, 26), "Out", "Quad", 0.3, true)
        SearchBox:ReleaseFocus()
        SearchBox.Text = ""
		for _, p in pairs(ContentArea:GetChildren()) do if p:IsA("ScrollingFrame") then for _, i in pairs(p:GetDescendants()) do if i:IsA("GuiObject") then i.Visible = true end end end end
	end
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = SearchBox.Text:lower()
	for _, page in pairs(ContentArea:GetChildren()) do if page:IsA("ScrollingFrame") then
		for _, item in pairs(page:GetChildren()) do
			if item:IsA("Frame") or item:IsA("TextButton") then
				local lbl = item:FindFirstChildWhichIsA("TextLabel") or (item:IsA("TextButton") and item) or nil
				local txt = (lbl and lbl.Text or ""):lower()
				if txt:find(text) then item.Visible = true else if text ~= "" then item.Visible = false end end
			end
		end
	end end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == CurrentKey then
		if MainFrame.Visible then MainFrame.Visible = false
        OpenButton.Visible = false else MainFrame.Visible = true
        OpenButton.Visible = false end
	end
end)
MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false
OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true
OpenButton.Visible = false end)

local Library = {}
local tabs = {}

function createSidebarButton(iconId, name)
	local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
	Page.Size = UDim2.new(1, -20, 1, -10)
    Page.Position = UDim2.new(0, 10, 0, 5)
	Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.ScrollBarImageTransparency = 0 
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.Visible = false
    Page.Parent = ContentArea
	local PL = Instance.new("UIListLayout")
    PL.Padding = ContentConfig.ItemPadding
    PL.SortOrder = Enum.SortOrder.LayoutOrder
    PL.Parent = Page
	local PP = Instance.new("UIPadding")
    PP.PaddingBottom = UDim.new(0, 10)
    PP.Parent = Page
	
	local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, Config.BtnHeight)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = ""
    TabButton.Parent = Sidebar
	local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 0.7, 0)
    Indicator.Position = UDim2.new(0, 0, 0.15, 0)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BackgroundTransparency = 1
    Indicator.BorderSizePixel = 0
    Indicator.Parent = TabButton
    ApplyGradient(Indicator, Theme.Accent, Theme.AccentDark, 90)
	
	local Icon = Instance.new("ImageLabel")
    Icon.Image = "rbxassetid://" .. iconId
    Icon.Size = UDim2.new(0, Config.IconSize, 0, Config.IconSize)
    Icon.Position = UDim2.new(0, 12, 0.5, -(Config.IconSize/2))
    Icon.BackgroundTransparency = 1
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Icon.ImageTransparency = 0.5
    Icon.Parent = TabButton
	local Label = Instance.new("TextLabel")
    Label.Text = name
    Label.Size = UDim2.new(0, 100, 1, 0)
    Label.Position = UDim2.new(0, 38, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Theme.Font
    Label.TextSize = Config.FontSize
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextTransparency = 0.5
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TabButton
	
	ApplyAnimatedTextGradient(Label)

	TabButton.MouseButton1Click:Connect(function()
		for _, tab in pairs(tabs) do 
			tab.Page.Visible = false
			tab.Indicator.BackgroundTransparency = 1
			tab.Label.TextTransparency = 0.5
			tab.Icon.ImageTransparency = 0.5
		end
		Page.Visible = true
		Indicator.BackgroundTransparency = 0
		Label.TextTransparency = 0
		Icon.ImageTransparency = 0
	end)
	
	table.insert(tabs, {Page = Page, Indicator = Indicator, Label = Label, Icon = Icon})
	return Page
end

function Library:CreateFooter(Page)
    local Footer = Instance.new("TextLabel")
    Footer.Size = UDim2.new(1, 0, 0, 30)
    Footer.BackgroundTransparency = 1
    Footer.Text = "New scripts will be added soon."
    Footer.TextColor3 = Theme.TextDark
    Footer.Font = Enum.Font.Gotham
    Footer.TextSize = 10
    Footer.TextXAlignment = Enum.TextXAlignment.Center
    Footer.Parent = Page
end

function Library:CreateButton(Page, Text, Callback)
	local BtnFrame = Instance.new("TextButton")
    BtnFrame.Size = UDim2.new(1, 0, 0, ContentConfig.ItemHeight)
    BtnFrame.BackgroundColor3 = Theme.ItemColor
    BtnFrame.BackgroundTransparency = 0.2
    BtnFrame.Text = ""
    BtnFrame.Parent = Page
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = BtnFrame
    Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 6)
    ApplyGradient(BtnFrame, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.Font = Theme.Font
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = BtnFrame
	BtnFrame.MouseButton1Click:Connect(function() pcall(Callback) end)
    BtnFrame.MouseEnter:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.Accent, Transparency = 0.4}):Play() end)
    BtnFrame.MouseLeave:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.ItemStroke, Transparency = 0.7}):Play() end)
end

function Library:CreateToggle(Page, Text, Default, Callback)
	local Flag = Page.Name .. "_" .. Text
	local State = UserConfigs[Flag]
	if State == nil then State = Default or false end
	UserConfigs[Flag] = State

	local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(1, 0, 0, ContentConfig.ItemHeight)
    Tgl.BackgroundColor3 = Theme.ItemColor
    Tgl.BackgroundTransparency = 0.2
    Tgl.Text = ""
    Tgl.Parent = Page
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = Tgl
    Instance.new("UICorner", Tgl).CornerRadius = UDim.new(0, 6)
    ApplyGradient(Tgl, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.Font = Theme.Font
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Tgl
	local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, 34, 0, 18)
    Bg.Position = UDim2.new(1, -46, 0.5, -9)
    Bg.BackgroundColor3 = Theme.SwitchOff
    Bg.Parent = Tgl
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local BgGrad = ApplyGradient(Bg, Theme.SwitchOff, Theme.SwitchOff, 90)
	local Cir = Instance.new("Frame")
    Cir.Size = UDim2.new(0, 14, 0, 14)
    Cir.Position = UDim2.new(0, 2, 0.5, -7)
    Cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Cir.Parent = Bg
    Instance.new("UICorner", Cir).CornerRadius = UDim.new(1, 0)
	
    local function Upd(fireCallback)
		if State then TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark)}
        TweenService:Create(Cir, TweenInfo.new(0.2), {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.new(0,0,0)}):Play()
		else TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
        BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.SwitchOff), ColorSequenceKeypoint.new(1, Theme.SwitchOff)}
        TweenService:Create(Cir, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play() end
		if fireCallback then pcall(Callback, State) end
	end
	
	Tgl.MouseButton1Click:Connect(function() State = not State
    UserConfigs[Flag] = State
    Upd(true) end)
	Upd(true) 
	
    Tgl.MouseEnter:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.Accent, Transparency = 0.4}):Play() end)
    Tgl.MouseLeave:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.ItemStroke, Transparency = 0.7}):Play() end)
    
    local function Set(val)
        State = val
        UserConfigs[Flag] = State
        Upd(true)
    end
    return {Set = Set}
end

function Library:CreateToggleKeybind(Page, Text, DefaultState, DefaultKey, Callback)
    local FlagState = Page.Name .. "_" .. Text .. "_State"
    local FlagKey = Page.Name .. "_" .. Text .. "_Key"
    
    local State = UserConfigs[FlagState]
    if State == nil then State = DefaultState or false end
    UserConfigs[FlagState] = State
    
    local Key = UserConfigs[FlagKey]
    if Key == nil then Key = DefaultKey or "None" end
    UserConfigs[FlagKey] = Key

    local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(1, 0, 0, ContentConfig.ItemHeight)
    Tgl.BackgroundColor3 = Theme.ItemColor
    Tgl.BackgroundTransparency = 0.2
    Tgl.Text = ""
    Tgl.Parent = Page
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = Tgl
    Instance.new("UICorner", Tgl).CornerRadius = UDim.new(0, 6)
    ApplyGradient(Tgl, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.Font = Theme.Font
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Tgl

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = UDim2.new(0, 55, 0, 22)
    KeyBtn.Position = UDim2.new(1, -105, 0.5, -11)
    KeyBtn.BackgroundColor3 = Theme.SwitchOff
    KeyBtn.Text = (Key == "None" and "Set Key" or Key)
    KeyBtn.TextColor3 = Theme.Accent
    KeyBtn.Font = Theme.Font
    KeyBtn.TextSize = 10
    KeyBtn.Parent = Tgl
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 4)

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, 34, 0, 18)
    Bg.Position = UDim2.new(1, -46, 0.5, -9)
    Bg.BackgroundColor3 = Theme.SwitchOff
    Bg.Parent = Tgl
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local BgGrad = ApplyGradient(Bg, Theme.SwitchOff, Theme.SwitchOff, 90)
    local Cir = Instance.new("Frame")
    Cir.Size = UDim2.new(0, 14, 0, 14)
    Cir.Position = UDim2.new(0, 2, 0.5, -7)
    Cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Cir.Parent = Bg
    Instance.new("UICorner", Cir).CornerRadius = UDim.new(1, 0)

    local function Upd(fireCallback)
        if State then 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.new(0,0,0)}):Play()
        else 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.SwitchOff), ColorSequenceKeypoint.new(1, Theme.SwitchOff)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play() 
        end
        if fireCallback then pcall(Callback, State) end
    end

    Tgl.MouseButton1Click:Connect(function()
        State = not State
        UserConfigs[FlagState] = State
        Upd(true)
    end)
    
    KeyBtn.MouseButton1Click:Connect(function()
        KeyBtn.Text = "..."
        local input = UserInputService.InputBegan:Wait()
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            UserConfigs[FlagKey] = input.KeyCode.Name
            KeyBtn.Text = input.KeyCode.Name
        else
            UserConfigs[FlagKey] = "None"
            KeyBtn.Text = "Set Key"
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp then
            local currentKey = UserConfigs[FlagKey]
            if currentKey and currentKey ~= "None" and input.KeyCode.Name == currentKey then
                State = not State
                UserConfigs[FlagState] = State
                Upd(true)
            end
        end
    end)

    Upd(true)
    
    Tgl.MouseEnter:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.Accent, Transparency = 0.4}):Play() end)
    Tgl.MouseLeave:Connect(function() TweenService:Create(str, TweenInfo.new(0.3), {Color = Theme.ItemStroke, Transparency = 0.7}):Play() end)
    
    local function Set(val)
        State = val
        UserConfigs[FlagState] = State
        Upd(true)
    end
    return {Set = Set}
end

function Library:CreateSection(Page, Text)
	local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 20)
    Section.BackgroundTransparency = 1
    Section.Parent = Page
	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section
	
	ApplyAnimatedTextGradient(Label)
	
	local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, -(Label.TextBounds.X + 10), 0, 1)
    Line.Position = UDim2.new(0, Label.TextBounds.X + 10, 0.5, 0)
    Line.BackgroundColor3 = Theme.ItemStroke
    Line.BorderSizePixel = 0
    Line.Parent = Section
    ApplyGradient(Line, Theme.Accent, Color3.new(0,0,0), 0)
end

function Library:CreateSlider(Page, Text, Min, Max, Default, Callback)
	local Flag = Page.Name .. "_" .. Text
	local currentVal = UserConfigs[Flag]
	if currentVal == nil then currentVal = Default end
	currentVal = math.clamp(currentVal, Min, Max)
	UserConfigs[Flag] = currentVal

	local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Theme.ItemColor
    Frame.BackgroundTransparency = 0.2
    Frame.Parent = Page
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = Frame
    ApplyGradient(Frame, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.Font = Theme.Font
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
	local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 40, 0, 20)
    ValueLabel.Position = UDim2.new(1, -10, 0, 2)
    ValueLabel.AnchorPoint = Vector2.new(1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(currentVal)
    ValueLabel.TextColor3 = Theme.TextDark
    ValueLabel.Font = Theme.Font
    ValueLabel.TextSize = 11
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame
	local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -20, 0, 4)
    SliderBar.Position = UDim2.new(0, 10, 0, 28)
    SliderBar.BackgroundColor3 = Theme.SwitchOff
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = Frame
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
	local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((currentVal - Min) / (Max - Min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    ApplyGradient(Fill, Theme.Accent, Theme.AccentDark, 0)
	local Trigger = Instance.new("TextButton")
    Trigger.Size = UDim2.new(1, 0, 1, 0)
    Trigger.BackgroundTransparency = 1
    Trigger.Text = ""
    Trigger.Parent = SliderBar
	
	task.spawn(function() pcall(Callback, currentVal) end)

	local dragging = false
	local function Update(input)
		local pos = UDim2.new(math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
        Fill.Size = pos
		local value = math.floor(Min + ((Max - Min) * pos.X.Scale))
		ValueLabel.Text = tostring(value)
		UserConfigs[Flag] = value
		pcall(Callback, value)
	end
	Trigger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true
    Update(input) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end end)
end

function Library:CreateInput(Page, Text, Default, Callback)
	local Flag = Page.Name .. "_" .. Text
	local currentVal = UserConfigs[Flag]
	if currentVal == nil then currentVal = Default end
	UserConfigs[Flag] = currentVal

	local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundColor3 = Theme.ItemColor
    Container.BackgroundTransparency = 0.2
    Container.Parent = Page
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = Container
    ApplyGradient(Container, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -90, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.Font = Theme.Font
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
	local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 70, 0, 26)
    Box.Position = UDim2.new(1, -80, 0.5, -13)
    Box.BackgroundColor3 = Theme.SwitchOff
    Box.Text = tostring(currentVal)
    Box.TextColor3 = Theme.Text
    Box.Font = Theme.Font
    Box.TextSize = 14
    Box.TextScaled = false
    Box.ClipsDescendants = true
    Box.Parent = Container
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
	
	task.spawn(function() pcall(Callback, currentVal) end)

	Box.FocusLost:Connect(function() 
		local num = tonumber(Box.Text)
		local finalVal = num or (Box.Text ~= "" and Box.Text or currentVal)
		Box.Text = tostring(finalVal)
		UserConfigs[Flag] = finalVal
		pcall(Callback, finalVal)
	end)
end

function Library:CreateCustomIDInput(Page, IsMobile)
	local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundColor3 = Theme.ItemColor
    Container.BackgroundTransparency = 0.2
    Container.Parent = Page
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
    ApplyGradient(Container, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -70, 1, 0)
    TextBox.Position = UDim2.new(0, 10, 0, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.Text = ""
    TextBox.PlaceholderText = "Enter Texture ID..."
    TextBox.TextColor3 = Theme.Text
    TextBox.PlaceholderColor3 = Theme.TextDark
    TextBox.Font = Theme.Font
    TextBox.TextSize = 12
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.Parent = Container
	local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(0, 50, 0, 26)
    ApplyBtn.Position = UDim2.new(1, -60, 0.5, -13)
    ApplyBtn.BackgroundColor3 = Theme.Accent
    ApplyBtn.Text = "Apply"
    ApplyBtn.TextColor3 = Color3.new(0,0,0)
    ApplyBtn.Font = Theme.Font
    ApplyBtn.TextSize = 11
    ApplyBtn.Parent = Container
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
    ApplyGradient(ApplyBtn, Theme.Accent, Theme.AccentDark, 90)
    ApplyBtn.MouseButton1Click:Connect(function() 
        local id = TextBox.Text
        if id ~= "" then 
            local fullID = "rbxassetid://" .. id:gsub("rbxassetid://", "")
            if IsMobile then MobileCrosshair.Image = fullID
            MobileCrosshair.Visible = true 
            else PCSoftwareCursor.Image = fullID
            PCCursorActive = true
            PCSoftwareCursor.Visible = true end 
        end 
    end)
end

function Library:CreateCursorGrid(Page, Items, IsMobile)
	local GridContainer = Instance.new("Frame")
    GridContainer.Size = UDim2.new(1, 0, 0, 0)
    GridContainer.BackgroundTransparency = 1
    GridContainer.Parent = Page
	local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 50, 0, 50)
    Grid.CellPadding = UDim2.new(0, 5, 0, 5)
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = GridContainer
	Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() GridContainer.Size = UDim2.new(1, 0, 0, Grid.AbsoluteContentSize.Y) end)
	for _, item in pairs(Items) do
		local Btn = Instance.new("TextButton")
        Btn.BackgroundColor3 = Theme.ItemColor
        Btn.BackgroundTransparency = 0.4
        Btn.Text = ""
        Btn.Parent = GridContainer
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
		if item.ID == "RESET" then
			local TextLbl = Instance.new("TextLabel")
            TextLbl.Size = UDim2.new(1, 0, 1, 0)
            TextLbl.BackgroundTransparency = 1
            TextLbl.Text = "Default"
            TextLbl.TextColor3 = Theme.Accent
            TextLbl.Font = Theme.Font
            TextLbl.TextSize = 11
            TextLbl.Parent = Btn
		else
			local Preview = Instance.new("ImageLabel")
            Preview.Size = UDim2.new(0, 24, 0, 24)
            Preview.Position = UDim2.new(0.5, -12, 0.5, -12)
            Preview.BackgroundTransparency = 1
            Preview.Image = "rbxassetid://" .. item.ID
            Preview.ScaleType = Enum.ScaleType.Fit
            Preview.Parent = Btn
		end
        Btn.MouseButton1Click:Connect(function() 
            if item.ID == "RESET" then 
                if IsMobile then MobileCrosshair.Visible = false 
                else PCCursorActive = false
                PCSoftwareCursor.Visible = false
                UserInputService.MouseIconEnabled = true end 
            else 
                local fullID = "rbxassetid://" .. item.ID
                if IsMobile then MobileCrosshair.Image = fullID
                MobileCrosshair.Visible = true 
                else PCSoftwareCursor.Image = fullID
                PCCursorActive = true
                PCSoftwareCursor.Visible = true end 
            end 
        end)
	end
end

function Library:CreatePlayerCard(Page, Player, Callback)
	local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, ContentConfig.PlayerCardHeight)
    Card.BackgroundColor3 = Theme.ItemColor
    Card.BackgroundTransparency = 0.2
    Card.Parent = Page
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
    local str = Instance.new("UIStroke")
    str.Color = Theme.ItemStroke
    str.Thickness = 1
    str.Transparency = 0.7
    str.Parent = Card
    ApplyGradient(Card, Color3.fromRGB(45,45,45), Theme.ItemColor, 90)
	local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(0, 36, 0, 36)
    Avatar.Position = UDim2.new(0, 8, 0.5, -18)
    Avatar.BackgroundColor3 = Theme.SwitchOff
    Avatar.Parent = Card
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)
	task.spawn(function() local content, isReady = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    if isReady then Avatar.Image = content end end)
	local Display = Instance.new("TextLabel")
    Display.Text = Player.DisplayName
    Display.Size = UDim2.new(1, -130, 0, 18)
    Display.Position = UDim2.new(0, 54, 0, 8)
    Display.BackgroundTransparency = 1
    Display.Font = Theme.Font
    Display.TextSize = 13
    Display.TextColor3 = Theme.Text
    Display.TextXAlignment = Enum.TextXAlignment.Left
    Display.Parent = Card
	local User = Instance.new("TextLabel")
    User.Text = "@" .. Player.Name
    User.Size = UDim2.new(1, -130, 0, 14)
    User.Position = UDim2.new(0, 54, 0, 26)
    User.BackgroundTransparency = 1
    User.Font = Enum.Font.Gotham
    User.TextSize = 11
    User.TextColor3 = Theme.TextDark
    User.TextXAlignment = Enum.TextXAlignment.Left
    User.Parent = Card
	local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, 75, 0, 26)
    ActionBtn.Position = UDim2.new(1, -83, 0.5, -13)
    ActionBtn.BackgroundColor3 = Theme.Accent
    ActionBtn.Text = "Teleport"
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = 11
    ActionBtn.TextColor3 = Color3.new(0,0,0)
    ActionBtn.Parent = Card
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)
    ApplyGradient(ActionBtn, Theme.Accent, Theme.AccentDark, 90)
	ActionBtn.MouseButton1Click:Connect(function() TweenService:Create(ActionBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    task.wait(0.1)
    TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
    pcall(Callback) end)
end

local HighlightPage = createSidebarButton("132131289033378", "Highlight") 
local VisualPage = createSidebarButton("76176408662599", "Visual") 
local AdvancedPage = createSidebarButton("16717281575", "Advanced") 
local ProgressPage = createSidebarButton("105442920358687", "Progress")
local VisualSkinsPage = createSidebarButton("13285615740", "Visual Skins") 
local LegitPage = createSidebarButton("11322093465", "Legit")
local TeleportPage = createSidebarButton("12689978575", "Teleport")
local CrossHairPage = createSidebarButton("114326908103962", "CrossHair")
local SoundsPage = createSidebarButton("7203392850", "Sounds")
local ScriptInfoPage = createSidebarButton("9405926389", "Script Info")

do
    local EspPlayersConnection = nil
    local EspPlayersLoop = nil
    local BEAST_WEAPON_NAMES = {["Hammer"] = true,["Gemstone Hammer"] = true, ["Iron Hammer"] = true,["Mallet"] = true}
    local beastCache = {}

    local function isBeast(player)
        if beastCache[player] ~= nil then return beastCache[player] end
        local backpack = player:FindFirstChild("Backpack")
        local character = player.Character
        for name in pairs(BEAST_WEAPON_NAMES) do
            if backpack and backpack:FindFirstChild(name) then beastCache[player] = true
            return true end
            if character and character:FindFirstChild(name) then beastCache[player] = true
            return true end
        end
        if player.Team and player.Team.Name == "Beast" then beastCache[player] = true
        return true end
        beastCache[player] = false
        return false
    end

    local function ClearPlayerESP()
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("RoleESP")
                if hl then hl:Destroy() end
                local head = p.Character:FindFirstChild("Head")
                if head and head:FindFirstChild("NameESP") then head.NameESP:Destroy() end
            end
        end
    end

    Library:CreateSection(HighlightPage, "ESP Features")
    Library:CreateToggle(HighlightPage, "Esp Players", false, function(state)
        if state then
            task.spawn(function()
                while state do
                    table.clear(beastCache)
                    task.wait(1)
                end
            end)

            EspPlayersLoop = task.spawn(function()
                while state do
                    local localChar = LocalPlayer.Character
                    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
                    if localHRP then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local char = player.Character
                                local highlight = char:FindFirstChild("RoleESP")
                                if not highlight then
                                    highlight = Instance.new("Highlight")
                                    highlight.Name = "RoleESP"
                                    highlight.Adornee = char
                                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    highlight.OutlineTransparency = 0
                                    highlight.FillTransparency = 0.5
                                    highlight.Parent = char
                                end
                                local beast = isBeast(player)
                                highlight.FillColor = beast and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                                local head = char:FindFirstChild("Head")
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if head and hrp then
                                    local gui = head:FindFirstChild("NameESP")
                                    if not gui then
                                        gui = Instance.new("BillboardGui")
                                        gui.Name = "NameESP"
                                        gui.Adornee = head
                                        gui.AlwaysOnTop = true
                                        gui.Size = UDim2.new(0, 90, 0, 20)
                                        gui.StudsOffset = Vector3.new(0, 2.3, 0)
                                        gui.Parent = head
                                        local txt = Instance.new("TextLabel")
                                        txt.Name = "Label"
                                        txt.Size = UDim2.new(1,0,1,0)
                                        txt.BackgroundTransparency = 1
                                        txt.TextStrokeTransparency = 0.3
                                        txt.Font = Enum.Font.GothamBold
                                        txt.TextSize = 10
                                        txt.Parent = gui
                                    end
                                    local label = gui:FindFirstChild("Label")
                                    if label then
                                        local dist = math.floor((localHRP.Position - hrp.Position).Magnitude)
                                        label.Text = player.Name .. "\n" .. (beast and "BEAST" or "SURVIVOR") .. " | " .. dist .. " studs"
                                        label.TextColor3 = beast and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.6)
                end
            end)
        else
            if EspPlayersLoop then task.cancel(EspPlayersLoop) end
            ClearPlayerESP()
        end
    end)
    
    local BeastGlowConnection = nil
    local activeGlows = {}
    
    Library:CreateToggle(HighlightPage, "Beast Highlight", false, function(state)
        if state then
            local function checkGlow(char)
                if not char then return end
                local Head = char:FindFirstChild("Head")
                if not Head then return end
                
                local function update()
                    local BeastPowers = char:FindFirstChild("BeastPowers")
                    local existing = Head:FindFirstChild("BeastGlow")
                    if BeastPowers then
                        if not existing then
                            local pl = Instance.new("PointLight")
                            pl.Name = "BeastGlow"
                            pl.Color = Color3.fromRGB(0, 255, 255)
                            pl.Brightness = 8
                            pl.Range = 25
                            pl.Parent = Head
                            table.insert(activeGlows, pl)
                        end
                    else
                        if existing then existing:Destroy() end
                    end
                end
                update()
                char.ChildAdded:Connect(function(c) if c.Name == "BeastPowers" then update() end end)
                char.ChildRemoved:Connect(function(c) if c.Name == "BeastPowers" then update() end end)
            end
            
            BeastGlowConnection = Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(checkGlow)
                if p.Character then checkGlow(p.Character) end
            end)
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then checkGlow(p.Character) end
                p.CharacterAdded:Connect(checkGlow)
            end
        else
            if BeastGlowConnection then BeastGlowConnection:Disconnect() end
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local g = p.Character.Head:FindFirstChild("BeastGlow")
                    if g then g:Destroy() end
                end
            end
        end
    end)

    local EspCompConnection = nil
    local EspCompRender = nil
    local computers = {}

    local function ClearCompESP()
        for _, data in pairs(computers) do
            if data.Highlight then data.Highlight:Destroy() end
        end
        computers = {}
    end

    Library:CreateToggle(HighlightPage, "Esp Computers", false, function(state)
        if state then
            local function setupComputer(model)
                if model.Name == "ComputerTable" then
                    local screen = model:FindFirstChild("Screen")
                    if screen then
                        local highlight = model:FindFirstChild("CompESP")
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "CompESP"
                            highlight.Adornee = model
                            highlight.Parent = model
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.OutlineTransparency = 0
                            highlight.FillTransparency = 0.5
                        end
                        table.insert(computers, {Screen = screen, Highlight = highlight, Model = model})
                    end
                end
            end
            for _, obj in pairs(workspace:GetDescendants()) do setupComputer(obj) end
            EspCompConnection = workspace.DescendantAdded:Connect(setupComputer)
            
            EspCompRender = RunService.RenderStepped:Connect(function()
                for i = #computers, 1, -1 do
                    local data = computers[i]
                    if data.Model.Parent then
                        local color = data.Screen.Color
                        if color.R > color.G and color.R > color.B then data.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        elseif color.G > color.B and color.G > color.R then data.Highlight.FillColor = Color3.fromRGB(0, 255, 0)
                        else data.Highlight.FillColor = Color3.fromRGB(0, 170, 255)
                        end
                    else
                        table.remove(computers, i)
                    end
                end
            end)
        else
            if EspCompConnection then EspCompConnection:Disconnect() end
            if EspCompRender then EspCompRender:Disconnect() end
            ClearCompESP()
        end
    end)

    local EspDoorsConnection = nil
    local createdDoorESP = {}

    Library:CreateToggle(HighlightPage, "Esp Doors", false, function(state)
        if state then
            local function checkDoor(obj)
                if obj:IsA("Model") then
                    if obj.Name == "SingleDoor" or (obj.Name == "Door" and obj.Name ~= "ExitDoor" and (obj:FindFirstChild("Hinge") or obj:FindFirstChild("Door"))) then
                        if not obj:FindFirstChild("FtfDoorESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "FtfDoorESP"
                            hl.Adornee = obj
                            hl.Parent = obj
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.65
                            hl.OutlineTransparency = 0
                            table.insert(createdDoorESP, hl)
                        end
                    end
                end
            end
            for _, v in pairs(workspace:GetDescendants()) do checkDoor(v) end
            EspDoorsConnection = workspace.DescendantAdded:Connect(checkDoor)
        else
            if EspDoorsConnection then EspDoorsConnection:Disconnect() end
            for _, hl in pairs(createdDoorESP) do if hl.Parent then hl:Destroy() end end
            createdDoorESP = {}
        end
    end)

    local EspPodsConnection = nil
    local createdPodESP = {}

    Library:CreateToggle(HighlightPage, "Esp Freezepods", false, function(state)
        if state then
            local function setupPod(obj)
                if obj:IsA("Model") and obj.Name == "FreezePod" then
                    if not obj:FindFirstChild("PodESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "PodESP"
                        hl.Adornee = obj
                        hl.Parent = obj
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillColor = Color3.fromRGB(0, 255, 255)
                        hl.FillTransparency = 0.2
                        hl.OutlineTransparency = 0
                        table.insert(createdPodESP, hl)
                    end
                end
            end
            for _, v in pairs(workspace:GetDescendants()) do setupPod(v) end
            EspPodsConnection = workspace.DescendantAdded:Connect(setupPod)
        else
            if EspPodsConnection then EspPodsConnection:Disconnect() end
            for _, hl in pairs(createdPodESP) do if hl.Parent then hl:Destroy() end end
            createdPodESP = {}
        end
    end)

    local TracerConnection = nil
    local tracers = {}
    
    Library:CreateToggle(HighlightPage, "Esp Tracer Line", false, function(state)
        if state then
            local function createTracer(p)
                local l = Drawing.new("Line")
                l.Thickness = 1
                l.Transparency = 1
                l.Visible = false
                tracers[p] = l
            end
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p ~= nil then createTracer(p) end end
            
            TracerConnection = RunService.RenderStepped:Connect(function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) 

                for p, line in pairs(tracers) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                        if vis then
                            line.From = from
                            line.To = Vector2.new(pos.X, pos.Y)
                            local isBeast = false
                            if p.Team and p.Team.Name == "Beast" then isBeast = true else
                                local bp = p:FindFirstChild("Backpack")
                                if bp and (bp:FindFirstChild("Hammer") or bp:FindFirstChild("Gemstone Hammer")) then isBeast = true end
                                if p.Character:FindFirstChild("Hammer") then isBeast = true end
                            end
                            line.Color = isBeast and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,255)
                            line.Visible = true
                        else line.Visible = false end
                    else line.Visible = false end
                end
            end)
        else
            if TracerConnection then TracerConnection:Disconnect() end
            for _, l in pairs(tracers) do l:Remove() end
            tracers = {}
        end
    end)

    Library:CreateToggle(HighlightPage, "Esp outline", false, function(state) 
	end)
    
    Library:CreateFooter(HighlightPage)
end

do
    Library:CreateSection(VisualPage, "Visual Environment")
	
	local HideLeavesConnection = nil
    local hiddenParts = {} 

    Library:CreateToggle(VisualPage, "Hide Leaves (Only Homestead)", false, function(state)
        if state then
            local function isGreen(part)
                local c = part.Color
                return (c.G > c.R * 1.1) and (c.G > c.B * 1.1)
            end

            local function cleanPart(part)
                if not part:IsA("BasePart") then return end
                if part.Transparency == 1 then return end
                if part.Name == "HumanoidRootPart" then return end
                if not part.CanCollide then
                    local mat = part.Material
                    local name = part.Name:lower()
                    if name:find("leaf") or name:find("bush") or name:find("grass") or name:find("tree") or mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass or isGreen(part) then
                        if not (part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")) then
                             if not hiddenParts[part] then
                                hiddenParts[part] = part.Transparency 
                                part.Transparency = 1
                            end
                        end
                    end
                end
            end

            for _, v in pairs(workspace:GetDescendants()) do cleanPart(v) end
            HideLeavesConnection = workspace.DescendantAdded:Connect(cleanPart)
        else
            if HideLeavesConnection then HideLeavesConnection:Disconnect() end
            for part, originalTrans in pairs(hiddenParts) do
                if part and part.Parent then part.Transparency = originalTrans end
            end
            hiddenParts = {}
        end
    end)
    
    Library:CreateToggle(VisualPage, "No fog", false, function(state) 
	end)

    Library:CreateSection(VisualPage, "Camera & UI")
    local FovVal = 70
    Library:CreateSlider(VisualPage, "Fov Changer", 70, 120, 70, function(v) FovVal = v end)
    RunService.RenderStepped:Connect(function() Camera.FieldOfView = FovVal end)

    Library:CreateToggle(VisualPage, "Font Changer", false, function(state) 
	end)
    Library:CreateToggle(VisualPage, "Beast/Survivor Cam", false, function(state) 
	end)

    Library:CreateSection(VisualPage, "Visual Name/Level")
    Library:CreateToggle(VisualPage, "Enable Visuals", false, function(state) 
	end)
    Library:CreateInput(VisualPage, "Fake Name", LocalPlayer.Name, function(val) 
	end)
    Library:CreateInput(VisualPage, "Fake Level", "100", function(val) 
	end)
    Library:CreateToggle(VisualPage, "Show VIP Icon", false, function(state) 
	end)

    Library:CreateFooter(VisualPage)
end

do
	Library:CreateSection(AdvancedPage, "Beast")
    
    local AC_Frame = Instance.new("Frame")
    AC_Frame.Size = UDim2.new(0, 160, 0, 90)
    AC_Frame.Position = UDim2.new(0.5, -80, 0.4, 0)
    AC_Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    AC_Frame.Visible = false
    AC_Frame.Parent = ScreenGui
    Instance.new("UICorner", AC_Frame).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", AC_Frame).Color = Theme.Accent
    MakeDraggable(AC_Frame, AC_Frame)
    local AC_Title = Instance.new("TextLabel", AC_Frame)
    AC_Title.Size = UDim2.new(1,0,0,25)
    AC_Title.BackgroundTransparency = 1
    AC_Title.Text = "AutoClicker"
    AC_Title.TextColor3 = Theme.Accent
    AC_Title.Font = Theme.Font
    AC_Title.TextSize = 12
    local AC_Btn = Instance.new("TextButton", AC_Frame)
    AC_Btn.Size = UDim2.new(0.8,0,0,25)
    AC_Btn.Position = UDim2.new(0.1,0,0,30)
    AC_Btn.BackgroundColor3 = Theme.SwitchOff
    AC_Btn.Text = "OFF"
    AC_Btn.TextColor3 = Theme.CloseRed
    AC_Btn.Font = Theme.Font
    AC_Btn.TextSize = 12
    Instance.new("UICorner", AC_Btn).CornerRadius = UDim.new(0,4)
    local AC_Box = Instance.new("TextBox", AC_Frame)
    AC_Box.Size = UDim2.new(0.8,0,0,20)
    AC_Box.Position = UDim2.new(0.1,0,0,60)
    AC_Box.BackgroundColor3 = Theme.ItemColor
    AC_Box.Text = "15"
    AC_Box.TextColor3 = Theme.Text
    AC_Box.Font = Theme.Font
    AC_Box.TextSize = 12
    Instance.new("UICorner", AC_Box).CornerRadius = UDim.new(0,4)
    
    local acActive = false
    local acCPS = 15
    AC_Btn.MouseButton1Click:Connect(function()
        acActive = not acActive
        AC_Btn.Text = acActive and "ON" or "OFF"
        AC_Btn.TextColor3 = acActive and Color3.new(0,1,0) or Theme.CloseRed
    end)
    AC_Box.FocusLost:Connect(function()
        local n = tonumber(AC_Box.Text)
        if n and n > 0 then acCPS = n else AC_Box.Text = tostring(acCPS) end
    end)
    task.spawn(function()
        while task.wait() do
            if acActive and AC_Frame.Visible then
                local d = 1 / acCPS
                pcall(function()
                    local x = Camera.ViewportSize.X / 2
                    local y = Camera.ViewportSize.Y / 2
                    VirtualInputManager:SendTouchEvent(10, 0, x, y)
                    task.wait(0.01)
                    VirtualInputManager:SendTouchEvent(10, 2, x, y)
                end)
                task.wait(d)
            end
        end
    end)

	Library:CreateToggle(AdvancedPage, "AutoClick", false, function(state) 
		AC_Frame.Visible = state
        if not state then acActive = false
        AC_Btn.Text = "OFF"
        AC_Btn.TextColor3 = Theme.CloseRed end
	end)

    local njdEnabled = false
    local njdConnection
    local function checkNJD(c)
        if not c then return false end
        if c:FindFirstChildOfClass("Tool") then return true end
        if c:FindFirstChild("Hammer") then return true end
        return false
    end
    local function bindNJD(c)
        local h = c:WaitForChild("Humanoid", 5)
        if not h then return end
        njdConnection = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if njdEnabled and h.WalkSpeed < 16.5 and checkNJD(c) then
                h.WalkSpeed = 16.5
            end
        end)
    end
	Library:CreateToggle(AdvancedPage, "No Jump Delay", false, function(state) 
		njdEnabled = state
        if state and LocalPlayer.Character then bindNJD(LocalPlayer.Character) end
	end)
    LocalPlayer.CharacterAdded:Connect(function(c) if njdEnabled then bindNJD(c) end end)
    
    local hbEnabled = false
    local hbShowVisual = false
    local hbSize = 2
    local hbConnection = nil
	local function updateHitboxes()
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = v.Character.HumanoidRootPart
				local targetSize = Vector3.new(hbSize, hbSize, hbSize)
				if hrp.Size ~= targetSize then hrp.Size = targetSize end
				local targetTrans = hbShowVisual and 0.6 or 1
				if hrp.Transparency ~= targetTrans then hrp.Transparency = targetTrans end
				hrp.CanCollide = false
			end
		end
	end
	Library:CreateToggle(AdvancedPage, "Hitbox extender", false, function(state) hbEnabled = state
    if state then hbConnection = RunService.RenderStepped:Connect(updateHitboxes) else if hbConnection then hbConnection:Disconnect() end
    for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then v.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
    v.Character.HumanoidRootPart.Transparency = 1
    v.Character.HumanoidRootPart.CanCollide = true end end end end)
    Library:CreateInput(AdvancedPage, "Hitbox Size", 2, function(val) hbSize = val end)

	Library:CreateSection(AdvancedPage, "Survivor")
    
    local noHackFailEnabled = false
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        if noHackFailEnabled and getnamecallmethod() == "FireServer" and self.Name == "RemoteEvent" and args[1] == "SetPlayerMinigameResult" then
            args[2] = true
            return oldNamecall(self, unpack(args))
        end
        return oldNamecall(self, ...)
    end)
	Library:CreateToggle(AdvancedPage, "No hack fail", false, function(state) 
		noHackFailEnabled = state
	end)

    local autoSaveEnabled = false
    local isActingSave = false
    local mapPods = {}
    task.spawn(function()
        while task.wait(2) do
            local pods = {}
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and string.find(string.lower(v.Name), "freezepod") then table.insert(pods, v) end
            end
            mapPods = pods
        end
    end)
    local playerLastPositions = {}
    task.spawn(function()
        while task.wait(0.5) do
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    playerLastPositions[p] = p.Character.HumanoidRootPart.Position
                end
            end
        end
    end)
    local function isBeastSave(player)
        if player and player.Character and player.Character:FindFirstChild("Hammer") then return true end
        if player and player.Backpack and player.Backpack:FindFirstChild("Hammer") then return true end
        return false
    end
    local function isInsidePod(hrp, pod)
        for _, part in ipairs(pod:GetDescendants()) do
            if part:IsA("BasePart") then
                local distXZ = Vector3.new(hrp.Position.X - part.Position.X, 0, hrp.Position.Z - part.Position.Z).Magnitude
                if distXZ < 3.5 then return true end
            end
        end
        return false
    end
    local function getCapturedPlayer()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isBeastSave(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                local currentPos = hrp.Position
                local lastPos = playerLastPositions[p]
                if lastPos and (currentPos - lastPos).Magnitude < 0.5 then
                    for _, pod in ipairs(mapPods) do
                        if isInsidePod(hrp, pod) then return p, hrp end
                    end
                end
            end
        end
        return nil, nil
    end

	Library:CreateToggle(AdvancedPage, "auto save", false, function(state) 
		autoSaveEnabled = state
	end)
    
    task.spawn(function()
        while task.wait(0.2) do
            if not autoSaveEnabled or isActingSave then continue end
            if isBeastSave(LocalPlayer) then continue end
            local capturedPlayer, targetHRP = getCapturedPlayer()
            if capturedPlayer and targetHRP then
                local myChar = LocalPlayer.Character
                if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then continue end
                isActingSave = true
                local myHRP = myChar.HumanoidRootPart
                local originalPosition = myHRP.CFrame
                local aimPos = targetHRP.CFrame * CFrame.new(0, 0, -4)
                myHRP.CFrame = CFrame.lookAt(aimPos.Position, targetHRP.Position)
                task.wait(0.2)
                local cam = Workspace.CurrentCamera
                cam.CFrame = CFrame.lookAt(myHRP.Position + Vector3.new(0, 1.5, 0), targetHRP.Position)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                local startPos = targetHRP.Position
                local timeElapsed = 0
                while timeElapsed < 4 do
                    task.wait(0.1)
                    timeElapsed = timeElapsed + 0.1
                    if not targetHRP or not targetHRP.Parent then break end
                    if (targetHRP.Position - startPos).Magnitude > 2 then break end
                end
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.35)
                myHRP.CFrame = originalPosition
                task.wait(2)
                isActingSave = false
            end
        end
    end)

    local autoHackEnabled = false
    local isHacking = false
    local currentTween = nil
    local noclipHackConnection = nil
    local remoteEventHack = ReplicatedStorage:WaitForChild("RemoteEvent", 5)
    if remoteEventHack then
        remoteEventHack.OnClientEvent:Connect(function(eventName)
            if autoHackEnabled and type(eventName) == "string" and string.find(string.lower(eventName), "minigame") then
                remoteEventHack:FireServer("SetPlayerMinigameResult", true)
            end
        end)
    end
    local function isBeastHack()
        if not LocalPlayer.Character then return false end
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Model") then
                local name = string.lower(item.Name)
                if name:match("hammer") or name:match("gemstone") or name:match("sledge") then return true end
            end
        end
        return false
    end
    local function restoreFullCollision()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                    if part.Name == "Head" or part.Name == "Torso" or part.Name:match("Torso") then
                        part.CanCollide = true 
                    end
                end
            end
        end
    end
    local function ghostUpperBody()
        local char = LocalPlayer.Character
        if char then
            local legParts = { ["Left Leg"]=true, ["Right Leg"]=true, ["LeftUpperLeg"]=true,["LeftLowerLeg"]=true,["LeftFoot"]=true, ["RightUpperLeg"]=true,["RightLowerLeg"]=true,["RightFoot"]=true }
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = legParts[part.Name] or false end
            end
        end
    end
    local function flyToHack(targetCFrame)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        local hrp = char.HumanoidRootPart
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 45 
        local timeToFly = dist / speed
        if noclipHackConnection then noclipHackConnection:Disconnect() end
        noclipHackConnection = RunService.Stepped:Connect(function()
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
        end)
        hrp.Anchored = true
        local tweenInfo = TweenInfo.new(timeToFly, Enum.EasingStyle.Linear)
        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        local completed = false
        currentTween.Completed:Connect(function() completed = true end)
        currentTween:Play()
        while not completed do
            if not autoHackEnabled or isBeastHack() or not char or not hrp.Parent then
                if currentTween then currentTween:Cancel() end
                if noclipHackConnection then noclipHackConnection:Disconnect() end
                hrp.Anchored = false
                restoreFullCollision()
                return false
            end
            task.wait(0.05)
        end
        if noclipHackConnection then noclipHackConnection:Disconnect() end
        hrp.Anchored = false
        ghostUpperBody()
        return true
    end
    local function getPerfectCFrameHack()
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, nil end
        local myPos = myChar.HumanoidRootPart.Position
        local bestScreen, bestCFrame = nil, nil
        local shortestDist = math.huge
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignoreList = {myChar}
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignoreList, p.Character) end end
        rayParams.FilterDescendantsInstances = ignoreList
        for _, pc in ipairs(Workspace:GetDescendants()) do
            if pc:IsA("Model") and pc.Name == "ComputerTable" then
                local screen = pc:FindFirstChild("Screen")
                if screen and screen:IsA("BasePart") and screen.Position.Y > -20 then
                    local color = string.lower(screen.BrickColor.Name)
                    if not string.find(color, "green") and not string.find(color, "verde") then
                        local keyboards = {}
                        for _, v in ipairs(pc:GetDescendants()) do
                            if string.find(string.lower(v.Name), "keyboard") then
                                local kbPos = nil
                                if v:IsA("BasePart") then kbPos = v.Position elseif v:IsA("Model") then kbPos = v:GetPivot().Position end
                                if kbPos then
                                    local duplicate = false
                                    for _, ex in ipairs(keyboards) do if (ex.pos - kbPos).Magnitude < 1.5 then duplicate = true break end end
                                    if not duplicate then table.insert(keyboards, {pos = kbPos}) end
                                end
                            end
                        end
                        if #keyboards == 0 then table.insert(keyboards, {pos = screen.Position + (screen.CFrame.LookVector * 1.5)}) end
                        local validPos = nil
                        local chosenKbPos = nil
                        for _, kbData in ipairs(keyboards) do
                            local kbPos = kbData.pos
                            local flatScreen = Vector3.new(screen.Position.X, 0, screen.Position.Z)
                            local flatKb = Vector3.new(kbPos.X, 0, kbPos.Z)
                            if (flatKb - flatScreen).Magnitude > 0.01 then
                                local kbDir = (flatKb - flatScreen).Unit
                                local targetXZ = flatKb + (kbDir * 1.6)
                                local occupied = false
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                                        local pXZ = Vector3.new(p.Character.HumanoidRootPart.Position.X, 0, p.Character.HumanoidRootPart.Position.Z)
                                        if (pXZ - targetXZ).Magnitude < 1.5 then occupied = true break end
                                    end
                                end
                                if not occupied then
                                    local floorRayOrigin = Vector3.new(targetXZ.X, screen.Position.Y + 3, targetXZ.Z)
                                    local floorHit = Workspace:Raycast(floorRayOrigin, Vector3.new(0, -15, 0), rayParams)
                                    local finalY = floorHit and floorHit.Position.Y or (screen.Position.Y - 2.8)
                                    finalY = finalY + 3.2 
                                    validPos = Vector3.new(targetXZ.X, finalY, targetXZ.Z)
                                    chosenKbPos = kbPos
                                    break
                                end
                            end
                        end
                        if validPos and chosenKbPos then
                            local dist = (validPos - myPos).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                bestScreen = screen
                                bestCFrame = CFrame.lookAt(validPos, Vector3.new(chosenKbPos.X, validPos.Y, chosenKbPos.Z))
                            end
                        end
                    end
                end
            end
        end
        return bestScreen, bestCFrame
    end

	Library:CreateToggle(AdvancedPage, "auto hack", false, function(state) 
		autoHackEnabled = state
        if not state then
            isHacking = false
            if currentTween then currentTween:Cancel() end
            if noclipHackConnection then noclipHackConnection:Disconnect() end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
            if isHacking then restoreFullCollision() end
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
	end)

    task.spawn(function()
        while task.wait(0.2) do
            if not autoHackEnabled or isHacking then continue end
            if isBeastHack() then autoHackEnabled = false
            restoreFullCollision() continue end
            local screen, targetCFrame = getPerfectCFrameHack()
            if screen and targetCFrame then
                local myChar = LocalPlayer.Character
                if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then continue end
                local reachedDest = flyToHack(targetCFrame)
                if not reachedDest then continue end
                isHacking = true
                local myHRP = myChar.HumanoidRootPart
                myHRP.Velocity = Vector3.zero 
                myHRP.CFrame = targetCFrame
                local cam = Workspace.CurrentCamera
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetCFrame.Position + targetCFrame.LookVector * 5)
                task.wait(0.2)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                local spamTimer = 0
                while autoHackEnabled and isHacking do
                    task.wait(0.1)
                    spamTimer = spamTimer + 0.1
                    if not myChar or not myHRP.Parent or (myHRP.Position - targetCFrame.Position).Magnitude > 3.5 then break end
                    if spamTimer >= 0.5 then
                        spamTimer = 0
                        pcall(function() remoteEventHack:FireServer("SetPlayerMinigameResult", true) end)
                    end
                    pcall(function()
                        local touchGui = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
                        if touchGui and touchGui:FindFirstChild("TouchControlFrame") then
                            touchGui.Enabled = true
                            touchGui.TouchControlFrame.Visible = true
                        end
                    end)
                    local color = string.lower(screen.BrickColor.Name)
                    if string.find(color, "green") or string.find(color, "verde") then break end
                end
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                isHacking = false
                restoreFullCollision()
                task.wait(1.5) 
            else
                task.wait(1)
            end
        end
    end)

	Library:CreateSection(AdvancedPage, "Players")
    
    local flyEnabled = false
    local flySpeed = 50
    local flyBg, flyBv
    Library:CreateToggleKeybind(AdvancedPage, "Fly", false, "None", function(state) 
        flyEnabled = state
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        if state then
            if hum then hum.PlatformStand = true end
            flyBg = Instance.new("BodyGyro", hrp)
            flyBg.P = 9e4
            flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBg.CFrame = hrp.CFrame
            flyBv = Instance.new("BodyVelocity", hrp)
            flyBv.Velocity = Vector3.new(0, 0, 0)
            flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        else
            if hum then hum.PlatformStand = false end
            if flyBg then flyBg:Destroy() flyBg = nil end
            if flyBv then flyBv:Destroy() flyBv = nil end
        end
	end)
    Library:CreateSlider(AdvancedPage, "Fly Speed", 10, 200, 50, function(val) flySpeed = val end)
    
    RunService.RenderStepped:Connect(function()
        if flyEnabled and flyBg and flyBv and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local hum = LocalPlayer.Character.Humanoid
            flyBg.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local camLook = Camera.CFrame.LookVector
                local camRight = Camera.CFrame.RightVector
                local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
                local forwardInput = moveDir:Dot(flatLook)
                local rightInput = moveDir:Dot(flatRight)
                local flyVelocity = (Camera.CFrame.LookVector * forwardInput) + (Camera.CFrame.RightVector * rightInput)
                flyBv.Velocity = flyVelocity.Unit * flySpeed
            else
                flyBv.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    local noclipEnabled = false
    Library:CreateToggleKeybind(AdvancedPage, "No clip", false, "None", function(state) 
        noclipEnabled = state
        if not state and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Torso" or part.Name == "Head" or part.Name:match("Torso")) then
                    part.CanCollide = true
                end
            end
        end
    end)
    RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)

    local jpEnabled = false
    local jpVal = 120
    Library:CreateToggleKeybind(AdvancedPage, "Jump Power", false, "None", function(state) 
        jpEnabled = state 
        if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = false
            LocalPlayer.Character.Humanoid.JumpPower = 50
            LocalPlayer.Character.Humanoid.JumpHeight = 7.2
        end
    end)
    Library:CreateSlider(AdvancedPage, "Jump Power Val", 50, 300, 120, function(val) jpVal = val end)
    RunService.Stepped:Connect(function()
        if jpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = jpVal
            LocalPlayer.Character.Humanoid.JumpHeight = jpVal / 2
        end
    end)

    local wsEnabled = false
    local wsValue = 16
    Library:CreateToggleKeybind(AdvancedPage, "Walkspeed", false, "None", function(state) 
        wsEnabled = state 
        if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end)
	Library:CreateSlider(AdvancedPage, "Speed Value", 16, 200, 16, function(val) wsValue = val end)
    RunService.Stepped:Connect(function()
        if wsEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = wsValue
        end
    end)

    Library:CreateFooter(AdvancedPage)
end

do
    local CompVars = {Active = {}, Loop = nil}
    Library:CreateSection(ProgressPage, "Timers & Indicators")
    Library:CreateToggle(ProgressPage, "Computer Progress", false, function(state)
        if state then
            local function createProgressBar(parent)
                if parent:FindFirstChild("ProgressBar") then 
                    local bb = parent.ProgressBar
                    return bb, bb.BackgroundBar.Bar, bb.ProgressText
                end

                local billboard = Instance.new("BillboardGui")
                billboard.Name = "ProgressBar"
                billboard.Adornee = parent
                billboard.Size = UDim2.new(0, 110, 0, 30)
                billboard.StudsOffset = Vector3.new(0, 4.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Enabled = true
                billboard.Parent = parent

                local text = Instance.new("TextLabel")
                text.Name = "ProgressText"
                text.Size = UDim2.new(1, 0, 0, 20)
                text.BackgroundTransparency = 1
                text.TextColor3 = Color3.fromRGB(255, 255, 255)
                text.TextStrokeTransparency = 0
                text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                text.Font = Enum.Font.GothamBold
                text.TextSize = 16
                text.Text = "0%"
                text.Parent = billboard

                local bgBar = Instance.new("Frame")
                bgBar.Name = "BackgroundBar"
                bgBar.Size = UDim2.new(1, 0, 0, 6)
                bgBar.Position = UDim2.new(0, 0, 1, -6)
                bgBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                bgBar.BorderSizePixel = 1
                bgBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                bgBar.Parent = billboard

                local bar = Instance.new("Frame")
                bar.Name = "Bar"
                bar.Size = UDim2.new(0, 0, 1, 0)
                bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
                bar.BorderSizePixel = 0
                bar.Parent = bgBar

                return billboard, bar, text
            end

            local function setupComputer(tableModel)
                if CompVars.Active[tableModel] then return end

                local billboard, bar, text = createProgressBar(tableModel)
                
                local highlight = tableModel:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
                highlight.Name = "ComputerHighlight"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = true
                highlight.Parent = tableModel

                local savedProgress = 0

                local connection = RunService.Heartbeat:Connect(function()
                    if not tableModel or not tableModel.Parent then 
                        if CompVars.Active[tableModel] then
                            if CompVars.Active[tableModel].Conn then CompVars.Active[tableModel].Conn:Disconnect() end
                            CompVars.Active[tableModel] = nil
                        end
                        return 
                    end

                    local screen = tableModel:FindFirstChild("Screen")
                    if screen and screen:IsA("BasePart") then
                        highlight.FillColor = screen.Color
                        highlight.OutlineColor = screen.Color
                    end

                    local currentFrameMax = 0
                    local isAnyoneTouching = false

                    for _, part in ipairs(tableModel:GetChildren()) do
                        if part:IsA("BasePart") and part.Name:match("^ComputerTrigger") then
                            local touching = part:GetTouchingParts()
                            for _, touchingPart in ipairs(touching) do
                                local character = touchingPart.Parent
                                local plr = Players:GetPlayerFromCharacter(character)
                                
                                if plr then
                                    local tpsm = plr:FindFirstChild("TempPlayerStatsModule")
                                    if tpsm then
                                        local ragdoll = tpsm:FindFirstChild("Ragdoll")
                                        local ap = tpsm:FindFirstChild("ActionProgress")
                                        
                                        if ragdoll and (ragdoll.Value == false) and ap then
                                            currentFrameMax = math.max(currentFrameMax, ap.Value)
                                            isAnyoneTouching = true
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if isAnyoneTouching then
                        savedProgress = math.max(savedProgress, currentFrameMax)
                    end

                    bar.Size = UDim2.new(savedProgress, 0, 1, 0)

                    if savedProgress >= 0.99 then
                        bar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                        text.Text = "DONE"
                        text.TextColor3 = Color3.fromRGB(0, 255, 100)
                        highlight.FillColor = Color3.fromRGB(0, 255, 100)
                    else
                        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        text.TextColor3 = Color3.fromRGB(255, 255, 255)
                        text.Text = string.format("%d%%", math.floor(savedProgress * 100))
                    end
                end)

                CompVars.Active[tableModel] = {
                    Conn = connection,
                    Billboard = billboard,
                    Highlight = highlight
                }
            end

            local function scan()
                local currentMapVal = ReplicatedStorage:FindFirstChild("CurrentMap")
                if currentMapVal then
                    local mapName = tostring(currentMapVal.Value)
                    local map = Workspace:FindFirstChild(mapName)
                    if map then
                        for _, obj in ipairs(map:GetChildren()) do
                            if obj.Name == "ComputerTable" then
                                setupComputer(obj)
                            end
                        end
                    end
                end
            end

            scan()

            CompVars.Loop = task.spawn(function()
                while state do
                    task.wait(2)
                    scan()
                end
            end)
        else
            if CompVars.Loop then task.cancel(CompVars.Loop) end
            for _, data in pairs(CompVars.Active) do
                if data.Conn then data.Conn:Disconnect() end
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
            end
            CompVars.Active = {}
        end
    end)

    local GetUpConnection = nil
    local activeTimers = {}
    local globalFrame = nil

    Library:CreateToggle(ProgressPage, "GetUp", false, function(state)
        if state then
            local function getUI() local s, r = pcall(function() return game:GetService("CoreGui") end); return s and r or LocalPlayer:WaitForChild("PlayerGui") end
            if not globalFrame then
                local p = getUI()
                if p:FindFirstChild("RagdollGlobalHUD") then p.RagdollGlobalHUD:Destroy() end
                local sg = Instance.new("ScreenGui")
                sg.Name = "RagdollGlobalHUD"
                sg.IgnoreGuiInset = true
                sg.Parent = p
                globalFrame = Instance.new("Frame")
                globalFrame.Name = "Container"
                globalFrame.AnchorPoint = Vector2.new(1, 0)
                globalFrame.Position = UDim2.new(1, -10, 0.35, 0)
                globalFrame.Size = UDim2.new(0, 250, 0, 400)
                globalFrame.BackgroundTransparency = 1
                globalFrame.Parent = sg
                local ll = Instance.new("UIListLayout")
                ll.Padding = UDim.new(0, 2)
                ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
                ll.Parent = globalFrame
            end

            GetUpConnection = RunService.Heartbeat:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.PlatformStand then
                        local head = char:FindFirstChild("Head")
                        local isFrozen = false
                        if head then for _, part in ipairs(workspace:GetPartBoundsInBox(head.CFrame, Vector3.new(2,2,2))) do if part.Parent and part.Parent.Name == "FreezePod" then isFrozen = true
                        break end end end
                        
                        if not activeTimers[player] then activeTimers[player] = {EndTime = tick() + 28} end
                        local data = activeTimers[player]
                        
                        if isFrozen then
                            if data.Lbl then data.Lbl.Visible = false end
                            data.EndTime = tick() + (data.Rem or 28)
                        else
                            local rem = data.EndTime - tick()
                            data.Rem = rem
                            if not data.Lbl then
                                local l = Instance.new("TextLabel")
                                l.Size = UDim2.new(1,0,0,22)
                                l.BackgroundTransparency = 1
                                l.TextStrokeTransparency = 0
                                l.Font = Enum.Font.GothamBold
                                l.TextSize = 16
                                l.TextXAlignment = Enum.TextXAlignment.Right
                                l.Parent = globalFrame
                                data.Lbl = l
                            end
                            data.Lbl.Visible = true
                            if rem <= 0 then data.Lbl:Destroy()
                            activeTimers[player] = nil else
                                local col = Color3.fromRGB(255, 255, 255)
                                if rem < 10 then col = Color3.fromRGB(255, 200, 50) end
                                if rem < 5 then col = Color3.fromRGB(255, 80, 80) end
                                data.Lbl.Text = player.DisplayName .. ": " .. string.format("%.2fs", rem)
                                data.Lbl.TextColor3 = col
                            end
                        end
                    else
                        if activeTimers[player] then if activeTimers[player].Lbl then activeTimers[player].Lbl:Destroy() end
                        activeTimers[player] = nil end
                    end
                end
            end)
        else
            if GetUpConnection then GetUpConnection:Disconnect() end
            if globalFrame and globalFrame.Parent then globalFrame.Parent:Destroy() end
            activeTimers = {}
            globalFrame = nil
        end
    end)

    local ExitDoorLoop = nil
    local activeExitDoors = {}
    local ED_COLORS = { RED = Color3.fromRGB(255, 50, 50), YELLOW = Color3.fromRGB(255, 200, 0), GREEN = Color3.fromRGB(50, 255, 100) }

    Library:CreateToggle(ProgressPage, "ExitDoor Timer", false, function(state)
        if state then
            local function createDoorHUD(parent)
                if parent:FindFirstChild("DoorGUI") then 
                    local bb = parent.DoorGUI
                    return bb, bb.BgBar.Fill, bb.StatusText
                end
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "DoorGUI"
                billboard.Adornee = parent
                billboard.Size = UDim2.new(0, 120, 0, 30)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true
                billboard.Enabled = true
                billboard.Parent = parent
                local text = Instance.new("TextLabel")
                text.Name = "StatusText"
                text.Size = UDim2.new(1, 0, 0, 15)
                text.BackgroundTransparency = 1
                text.Text = "EXIT DOOR"
                text.TextColor3 = ED_COLORS.RED
                text.TextStrokeTransparency = 0
                text.TextStrokeColor3 = Color3.new(0,0,0)
                text.Font = Enum.Font.GothamBlack
                text.TextSize = 14
                text.Parent = billboard
                local bgBar = Instance.new("Frame")
                bgBar.Name = "BgBar"
                bgBar.Size = UDim2.new(1, 0, 0, 6)
                bgBar.Position = UDim2.new(0, 0, 1, -6)
                bgBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                bgBar.BorderSizePixel = 1
                bgBar.BorderColor3 = Color3.new(0,0,0)
                bgBar.Parent = billboard
                local fill = Instance.new("Frame")
                fill.Name = "Fill"
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = ED_COLORS.YELLOW
                fill.BorderSizePixel = 0
                fill.Parent = bgBar
                return billboard, fill, text
            end

            local function setupExitDoor(doorModel)
                if activeExitDoors[doorModel] then return end
                local highlight = doorModel:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
                highlight.Name = "DoorESP"
                highlight.FillColor = ED_COLORS.RED
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.8
                highlight.OutlineTransparency = 0.5
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = true
                highlight.Parent = doorModel
                
                local centerPart = doorModel.PrimaryPart or doorModel:FindFirstChildWhichIsA("BasePart", true)
                if not centerPart then return end
                
                local billboard, bar, text = createDoorHUD(centerPart)
                local doorData = {Connection = nil, Billboard = billboard, Highlight = highlight}
                activeExitDoors[doorModel] = doorData
                
                local overlapParams = OverlapParams.new()
                overlapParams.FilterDescendantsInstances = {doorModel}
                overlapParams.FilterType = Enum.RaycastFilterType.Exclude
                local lastUpdate = 0
                
                doorData.Connection = RunService.Heartbeat:Connect(function()
                    if not doorModel or not doorModel.Parent then
                        if doorData.Connection then doorData.Connection:Disconnect() end
                        activeExitDoors[doorModel] = nil
                        return
                    end
                    if tick() - lastUpdate < 0.1 then return end
                    lastUpdate = tick()
                    
                    if centerPart.CanCollide == false or centerPart.Transparency >= 0.9 then
                        bar.Size = UDim2.new(1, 0, 1, 0)
                        bar.BackgroundColor3 = ED_COLORS.GREEN
                        text.Text = "OPEN"
                        text.TextColor3 = ED_COLORS.GREEN
                        highlight.FillColor = ED_COLORS.GREEN
                        return
                    end
                    
                    local rawMax = 0
                    local cf, size = doorModel:GetBoundingBox()
                    local partsInBox = Workspace:GetPartBoundsInBox(cf, Vector3.new(35, 35, 35), overlapParams)
                    for _, part in ipairs(partsInBox) do
                        local char = part.Parent
                        local player = Players:GetPlayerFromCharacter(char)
                        if player then
                            local stats = player:FindFirstChild("TempPlayerStatsModule")
                            if stats then
                                local actionProgress = stats:FindFirstChild("ActionProgress")
                                if actionProgress and actionProgress.Value > 0 and actionProgress.Value > rawMax then rawMax = actionProgress.Value end
                            end
                        end
                    end
                    
                    local finalScale = rawMax
                    if rawMax > 1 then finalScale = rawMax / 100 end
                    finalScale = math.clamp(finalScale, 0, 1)
                    bar.Size = UDim2.new(finalScale, 0, 1, 0)
                    if finalScale > 0.01 then
                        bar.BackgroundColor3 = ED_COLORS.YELLOW
                        text.Text = string.format("OPENING %d%%", math.floor(finalScale * 100))
                        text.TextColor3 = ED_COLORS.YELLOW
                        highlight.FillColor = ED_COLORS.YELLOW
                    else
                        bar.BackgroundColor3 = ED_COLORS.RED
                        text.Text = "EXIT DOOR"
                        text.TextColor3 = ED_COLORS.RED
                        highlight.FillColor = ED_COLORS.RED
                    end
                end)
            end

            local function checkObj(obj) if obj:IsA("Model") and obj.Name == "ExitDoor" then setupExitDoor(obj) end end
            for _, obj in ipairs(Workspace:GetDescendants()) do checkObj(obj) end
            ExitDoorLoop = Workspace.DescendantAdded:Connect(checkObj)
        else
            if ExitDoorLoop then ExitDoorLoop:Disconnect() end
            for _, data in pairs(activeExitDoors) do
                if data.Connection then data.Connection:Disconnect() end
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
            end
            activeExitDoors = {}
        end
    end)

    local BeastPowerConnection = nil
    local BeastPowerLabel = nil

    Library:CreateToggle(ProgressPage, "BeastPower timer", false, function(state)
        if state then
            local function getUI() local s, r = pcall(function() return game:GetService("CoreGui") end); return s and r or LocalPlayer:WaitForChild("PlayerGui") end
            local c = getUI()
            if c:FindFirstChild("BeastTextHUD") then c.BeastTextHUD:Destroy() end
            local sg = Instance.new("ScreenGui")
            sg.Name = "BeastTextHUD"
            sg.IgnoreGuiInset = true
            sg.Parent = c
            BeastPowerLabel = Instance.new("TextLabel")
            BeastPowerLabel.AnchorPoint = Vector2.new(1, 0)
            BeastPowerLabel.Position = UDim2.new(1, -15, 0.60, 0)
            BeastPowerLabel.Size = UDim2.new(0, 200, 0, 30)
            BeastPowerLabel.BackgroundTransparency = 1
            BeastPowerLabel.TextColor3 = Color3.new(1,1,1)
            BeastPowerLabel.TextStrokeTransparency = 0
            BeastPowerLabel.Font = Enum.Font.SourceSansBold
            BeastPowerLabel.TextSize = 18
            BeastPowerLabel.TextXAlignment = Enum.TextXAlignment.Right
            BeastPowerLabel.Visible = false
            BeastPowerLabel.Parent = sg

            BeastPowerConnection = RunService.Heartbeat:Connect(function()
                local found = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("BeastPowers") then
                        found = true
                        BeastPowerLabel.Visible = true
                        local nv = p.Character.BeastPowers:FindFirstChildOfClass("NumberValue")
                        if nv then
                            local pct = math.clamp(nv.Value, 0, 1)
                            BeastPowerLabel.Text = "BEAST POWER: " .. math.floor(pct * 100) .. "%"
                            BeastPowerLabel.TextColor3 = (pct >= 0.99) and Color3.fromRGB(100, 255, 100) or Color3.new(1,1,1)
                        end
                        break
                    end
                end
                if not found then BeastPowerLabel.Visible = false end
            end)
        else
            if BeastPowerConnection then BeastPowerConnection:Disconnect() end
            if BeastPowerLabel and BeastPowerLabel.Parent then BeastPowerLabel.Parent:Destroy() end
        end
    end)
	
	Library:CreateToggle(ProgressPage, "BeastPower Timer V2", false, function(state) 
	end)

    local BeastSpawnLoop = nil
    local BeastTimerGui = nil

    Library:CreateToggle(ProgressPage, "BeastSpawn Timer", false, function(state)
        if state then
            local p = (RunService:IsStudio() and LocalPlayer.PlayerGui) or game:GetService("CoreGui")
            if not p:FindFirstChild("FleeBeastCountdown") then
                local sg = Instance.new("ScreenGui")
                sg.Name = "FleeBeastCountdown"
                sg.ResetOnSpawn = false
                sg.Parent = p
                local c = Instance.new("Frame")
                c.Name = "TimerContainer"
                c.Size = UDim2.new(0, 500, 0, 80)
                c.Position = UDim2.new(0.5, -250, 0.2, 0)
                c.BackgroundTransparency = 1
                c.Visible = false
                c.Parent = sg
                local t = Instance.new("TextLabel")
                t.Name = "MainText"
                t.Size = UDim2.new(1,0,1,0)
                t.BackgroundTransparency = 1
                t.Font = Enum.Font.FredokaOne
                t.TextSize = 42
                t.TextColor3 = Color3.fromRGB(255, 230, 0)
                t.TextStrokeTransparency = 0
                t.Parent = c
                BeastTimerGui = {Gui = sg, Container = c, Text = t, Counting = false}
            end

            BeastSpawnLoop = task.spawn(function()
                while state do
                    task.wait(0.5)
                    if BeastTimerGui and not BeastTimerGui.Counting then
                        local found = false
                        for _, obj in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                            if obj:IsA("TextLabel") and obj.Visible and string.find(string.upper(obj.Text), "HEAD START") then found = true
                            break end
                        end
                        if found then
                            BeastTimerGui.Counting = true
                            BeastTimerGui.Container.Visible = true
                            for i = 15, 1, -1 do
                                if not state then break end
                                BeastTimerGui.Text.Text = "BEAST SPAWNS IN " .. i .. "sec"
                                BeastTimerGui.Text.TextColor3 = (i <= 5) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 230, 0)
                                task.wait(1)
                            end
                            if state then
                                BeastTimerGui.Text.Text = "BEAST SPAWNED"
                                BeastTimerGui.Text.TextColor3 = Color3.fromRGB(255, 0, 0)
                                task.wait(2)
                                BeastTimerGui.Container.Visible = false
                                task.wait(5)
                                BeastTimerGui.Counting = false
                            end
                        end
                    end
                end
            end)
        else
            if BeastSpawnLoop then task.cancel(BeastSpawnLoop) end
            if BeastTimerGui then BeastTimerGui.Gui:Destroy()
            BeastTimerGui = nil end
        end
    end)
    
    Library:CreateFooter(ProgressPage)
end

do
    getgenv().FixLoop = nil 
    local selectedUserId = nil

    local function SmartWeld(char, accessory)
        local handle = accessory:FindFirstChild("Handle")
        if not handle then return end
        handle.Anchored = false
        handle.CanCollide = false
        handle.Massless = true
        accessory.Parent = char
        local accAtt = handle:FindFirstChildWhichIsA("Attachment")
        local charAtt, targetPart = nil, nil
        if accAtt then
            if char:FindFirstChild("Head") and char.Head:FindFirstChild(accAtt.Name) then charAtt = char.Head[accAtt.Name]
            targetPart = char.Head
            elseif char:FindFirstChild("Torso") and char.Torso:FindFirstChild(accAtt.Name) then charAtt = char.Torso[accAtt.Name]
            targetPart = char.Torso end
        end
        local weld = Instance.new("Weld")
        weld.Part1 = handle
        if charAtt and targetPart then weld.Part0 = targetPart
        weld.C0 = charAtt.CFrame
        weld.C1 = accAtt.CFrame
        else targetPart = char:FindFirstChild("Head")
        if targetPart then weld.Part0 = targetPart
        weld.C0 = CFrame.new(0, 0.5, 0) end end
        if weld.Part0 then weld.Parent = handle end
    end

    local function StartFixLoop(char, colorTable, originalHeadTextureId)
        if getgenv().FixLoop then getgenv().FixLoop:Disconnect() end
        getgenv().FixLoop = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent then if getgenv().FixLoop then getgenv().FixLoop:Disconnect() end return end
            for partName, color in pairs(colorTable) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if part.Color ~= color then part.Color = color
                    part.Material = Enum.Material.SmoothPlastic end
                    local mesh = part:FindFirstChildOfClass("SpecialMesh")
                    if mesh then
                        if partName == "Head" then
                            if originalHeadTextureId and originalHeadTextureId ~= "" then if mesh.TextureId ~= originalHeadTextureId then mesh.TextureId = originalHeadTextureId end
                            mesh.VertexColor = Vector3.new(1, 1, 1) else if mesh.TextureId ~= "" then mesh.TextureId = "" end end
                        else if mesh.TextureId ~= "" then mesh.TextureId = "" end
                        mesh.VertexColor = Vector3.new(1,1,1) end
                    end
                    for _, child in pairs(part:GetChildren()) do if child:IsA("Decal") and child.Name ~= "face" then child:Destroy() elseif child:IsA("Texture") then child:Destroy() end end
                end
            end
        end)
    end

    local function Transformar(userId)
        local char = LocalPlayer.Character
        if not char then return end
        local desc = Players:GetHumanoidDescriptionFromUserId(userId)
        local realColors = { ["Head"] = desc.HeadColor,["Torso"] = desc.TorsoColor,["Left Arm"] = desc.LeftArmColor,["Right Arm"] = desc.RightArmColor, ["Left Leg"] = desc.LeftLegColor,["Right Leg"] = desc.RightLegColor }
        local dummy = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
        dummy.Name = "AssetSource"
        dummy.Parent = workspace
        dummy:SetPrimaryPartCFrame(CFrame.new(0, -500, 0))
        task.wait(1.0)
        local targetHeadTexture = ""
        if dummy.Head:FindFirstChildOfClass("SpecialMesh") then targetHeadTexture = dummy.Head:FindFirstChildOfClass("SpecialMesh").TextureId end
        for _, v in pairs(char:GetChildren()) do if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then v:Destroy() end end
        if char:FindFirstChild("Head") and char.Head:FindFirstChild("face") then char.Head.face:Destroy() end
        local dummyMesh = dummy.Head:FindFirstChildOfClass("SpecialMesh")
        local myMesh = char.Head:FindFirstChildOfClass("SpecialMesh")
        if dummyMesh then if not myMesh then myMesh = Instance.new("SpecialMesh", char.Head) end
        myMesh.MeshType = Enum.MeshType.FileMesh
        myMesh.MeshId = dummyMesh.MeshId
        myMesh.Scale = dummyMesh.Scale
        myMesh.TextureId = targetHeadTexture
        myMesh.VertexColor = Vector3.new(1,1,1) end
        for _, item in pairs(dummy:GetChildren()) do if item:IsA("CharacterMesh") then item:Clone().Parent = char end end
        for _, item in pairs(dummy:GetChildren()) do if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then item:Clone().Parent = char elseif item.Name == "Head" and item:FindFirstChild("face") then item.face:Clone().Parent = char:FindFirstChild("Head") end end
        local newBC = Instance.new("BodyColors")
        newBC.HeadColor3 = desc.HeadColor
        newBC.TorsoColor3 = desc.TorsoColor
        newBC.LeftArmColor3 = desc.LeftArmColor
        newBC.RightArmColor3 = desc.RightArmColor
        newBC.LeftLegColor3 = desc.LeftLegColor
        newBC.RightLegColor3 = desc.RightLegColor
        newBC.Parent = char
        StartFixLoop(char, realColors, targetHeadTexture)
        for _, item in pairs(dummy:GetChildren()) do if item:IsA("Accessory") then local clone = item:Clone()
        SmartWeld(char, clone) end end
        dummy:Destroy()
        SendNotification("Skin Applied Successfully!", 3)
    end

    local HeaderContainer = Instance.new("Frame")
    HeaderContainer.Size = UDim2.new(1, 0, 0, 40)
    HeaderContainer.BackgroundTransparency = 1
    HeaderContainer.Parent = VisualSkinsPage

    local BigIcon = Instance.new("ImageLabel")
    BigIcon.Size = UDim2.new(0, 30, 0, 30)
    BigIcon.Position = UDim2.new(0, 10, 0, 5)
    BigIcon.Image = "rbxassetid://72635232675621"
    BigIcon.BackgroundTransparency = 1
    BigIcon.ImageColor3 = Theme.Accent
    BigIcon.Parent = HeaderContainer

    local MainTitle = Instance.new("TextLabel")
    MainTitle.Text = "SKIN CHANGER"
    MainTitle.Size = UDim2.new(0, 200, 1, 0)
    MainTitle.Position = UDim2.new(0, 50, 0, 0)
    MainTitle.Font = Enum.Font.GothamBlack
    MainTitle.TextSize = 14
    MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainTitle.TextXAlignment = Enum.TextXAlignment.Left
    MainTitle.BackgroundTransparency = 1
    MainTitle.Parent = HeaderContainer
    ApplyAnimatedTextGradient(MainTitle)

    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, 0, 0, 35)
    InputContainer.Position = UDim2.new(0, 0, 0, 45)
    InputContainer.BackgroundColor3 = Theme.ItemColor
    InputContainer.BackgroundTransparency = 0.4
    InputContainer.Parent = VisualSkinsPage
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 6)

    local UserInputBox = Instance.new("TextBox")
    UserInputBox.Size = UDim2.new(1, -40, 1, 0)
    UserInputBox.Position = UDim2.new(0, 10, 0, 0)
    UserInputBox.BackgroundTransparency = 1
    UserInputBox.Text = ""
    UserInputBox.PlaceholderText = "Username..."
    UserInputBox.TextColor3 = Theme.Text
    UserInputBox.PlaceholderColor3 = Theme.TextDark
    UserInputBox.Font = Theme.Font
    UserInputBox.TextSize = 13
    UserInputBox.TextXAlignment = Enum.TextXAlignment.Left
    UserInputBox.Parent = InputContainer

    local SearchBtnIcon = Instance.new("ImageButton")
    SearchBtnIcon.Size = UDim2.new(0, 20, 0, 20)
    SearchBtnIcon.Position = UDim2.new(1, -28, 0.5, -10)
    SearchBtnIcon.BackgroundTransparency = 1
    SearchBtnIcon.Image = "rbxassetid://104986431790017"
    SearchBtnIcon.ImageColor3 = Theme.Accent
    SearchBtnIcon.ScaleType = Enum.ScaleType.Fit
    SearchBtnIcon.Parent = InputContainer

    local PresetsLabel = Instance.new("TextLabel")
    PresetsLabel.Text = "QUICK SELECT"
    PresetsLabel.Size = UDim2.new(1, 0, 0, 15)
    PresetsLabel.Position = UDim2.new(0, 0, 0, 85)
    PresetsLabel.BackgroundTransparency = 1
    PresetsLabel.TextColor3 = Theme.TextDark
    PresetsLabel.Font = Enum.Font.GothamBold
    PresetsLabel.TextSize = 10
    PresetsLabel.Parent = VisualSkinsPage

    local PresetsContainer = Instance.new("ScrollingFrame")
    PresetsContainer.Size = UDim2.new(1, 0, 1, -110) 
    PresetsContainer.Position = UDim2.new(0, 0, 0, 105)
    PresetsContainer.BackgroundTransparency = 1
    PresetsContainer.BorderSizePixel = 0
    PresetsContainer.ScrollBarThickness = 2
    PresetsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    PresetsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    PresetsContainer.ScrollingDirection = Enum.ScrollingDirection.Y 
    PresetsContainer.Parent = VisualSkinsPage

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 45, 0, 45) 
    Grid.CellPadding = UDim2.new(0, 6, 0, 6)
    Grid.FillDirection = Enum.FillDirection.Horizontal 
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = PresetsContainer
    
    local PreviewFrame = Instance.new("Frame")
    PreviewFrame.Size = UDim2.new(0, 220, 0, 80) 
    PreviewFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    PreviewFrame.Position = UDim2.new(0.5, 0, 0.5, 0) 
    PreviewFrame.BackgroundColor3 = Theme.FrameColor 
    PreviewFrame.BorderSizePixel = 0
    PreviewFrame.Visible = false
    PreviewFrame.ZIndex = 100 
    PreviewFrame.Parent = MainFrame 
    
    local PFC = Instance.new("UICorner")
    PFC.CornerRadius = UDim.new(0, 6)
    PFC.Parent = PreviewFrame
    local PFS = Instance.new("UIStroke")
    PFS.Color = Theme.Accent
    PFS.Thickness = 1
    PFS.Parent = PreviewFrame
    
    local PImage = Instance.new("ImageLabel")
    PImage.Size = UDim2.new(0, 60, 0, 60)
    PImage.Position = UDim2.new(0, 10, 0.5, -30)
    PImage.BackgroundColor3 = Theme.SwitchOff
    PImage.Parent = PreviewFrame
    Instance.new("UICorner", PImage).CornerRadius = UDim.new(0, 6)
    
    local PText = Instance.new("TextLabel")
    PText.Text = "Skin Found!"
    PText.Size = UDim2.new(1, -80, 0, 15)
    PText.Position = UDim2.new(0, 80, 0, 10)
    PText.BackgroundTransparency = 1
    PText.TextColor3 = Theme.Accent
    PText.Font = Theme.Font
    PText.TextSize = 13
    PText.TextXAlignment = Enum.TextXAlignment.Left
    PText.Parent = PreviewFrame
    
    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Text = "APPLY"
    ApplyBtn.Size = UDim2.new(0, 80, 0, 24)
    ApplyBtn.Position = UDim2.new(0, 80, 0, 40)
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    ApplyBtn.TextColor3 = Color3.new(1,1,1)
    ApplyBtn.Font = Theme.Font
    ApplyBtn.TextSize = 11
    ApplyBtn.Parent = PreviewFrame
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
    
    local CancelBtn = Instance.new("TextButton")
    CancelBtn.Text = "X"
    CancelBtn.Size = UDim2.new(0, 24, 0, 24)
    CancelBtn.Position = UDim2.new(0, 170, 0, 40)
    CancelBtn.BackgroundColor3 = Theme.ContentColor
    CancelBtn.TextColor3 = Theme.CloseRed
    CancelBtn.Font = Theme.Font
    CancelBtn.TextSize = 12
    CancelBtn.Parent = PreviewFrame
    Instance.new("UICorner", CancelBtn).CornerRadius = UDim.new(0, 4)

    local function PerformSearch(forcedText)
        local text = forcedText or UserInputBox.Text
        if text and text ~= "" then
            UserInputBox.Text = text
            local s, id = pcall(function() return Players:GetUserIdFromNameAsync(text) end)
            if s and id then
                selectedUserId = id
                local thumb, isReady = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size150x150)
                if isReady then
                    PImage.Image = thumb
                    PreviewFrame.Visible = true
                end
            else
                SendNotification("User not found!", 2)
                PreviewFrame.Visible = false
            end
        end
    end

    local DummyNames = {
        "Dv_223", "Dimeyuri", "JaoEverCry", "Baydiina", "Meshew", "SniperFq",
        "sukyaik", "nathanserafas12", "guhtorrez", "sthefany12091", "011coded", 
        "1Rxdrigo", "akatexs", "j_oqoo", "Mwaiconn", "tio_morcego", "l_qke", 
        "hqilyy", "pqsteljxde", "brokensfr", "noschillies", "ZxvqZayan"
    }
    
    for _, name in pairs(DummyNames) do
        local Btn = Instance.new("ImageButton")
        Btn.BackgroundColor3 = Theme.ItemColor
        Btn.BackgroundTransparency = 0.4
        Btn.Parent = PresetsContainer
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        task.spawn(function()
            local s, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
            if s and id then
                local thumb = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                Btn.Image = thumb
            end
        end)
        Btn.MouseButton1Click:Connect(function() PerformSearch(name) end)
    end

    UserInputBox.FocusLost:Connect(function(enter) if enter then PerformSearch() end end)
    SearchBtnIcon.MouseButton1Click:Connect(function() PerformSearch() end)
    
    ApplyBtn.MouseButton1Click:Connect(function()
        if selectedUserId then
            Transformar(selectedUserId)
            PreviewFrame.Visible = false
        end
    end)
    
    CancelBtn.MouseButton1Click:Connect(function() PreviewFrame.Visible = false
    selectedUserId = nil end)
    
    Library:CreateFooter(VisualSkinsPage)
end

do
    Library:CreateSection(LegitPage, "Client Modifications")
    
    Library:CreateToggle(LegitPage, "FpsBooster", false, function(state) 
        if state then
            for _, v in pairs(Lighting:GetDescendants()) do if v:IsA("PostEffect") then v.Enabled = false end end
            Lighting.GlobalShadows = false
        else
            Lighting.GlobalShadows = true
        end
    end)
    
    local greyConnection = nil
    local mapTextureConnection = nil
    local stretchConnection = nil
    local hackConnection = nil
    
    local OriginalCharacterData = {}
	local function SaveCharData(player) if not player.Character then return end
    if OriginalCharacterData[player] then return end
    local data = {Parts = {}, Clothes = {}}
    for _, v in ipairs(player.Character:GetChildren()) do if v:IsA("BasePart") then data.Parts[v] = {Color = v.Color, Material = v.Material} elseif v:IsA("Clothing") or v:IsA("ShirtGraphic") then table.insert(data.Clothes, v) elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then local h = v.Handle
    if h:IsA("BasePart") then data.Parts[h] = {Color = h.Color, Material = h.Material} end end end
    OriginalCharacterData[player] = data end
	local function ApplyGray(player) if not player.Character then return end
    SaveCharData(player)
    local char = player.Character
    for _, v in ipairs(char:GetChildren()) do if v:IsA("BasePart") then v.Color = Color3.fromRGB(150, 150, 150)
    v.Material = Enum.Material.SmoothPlastic elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then local h = v.Handle
    if h:IsA("BasePart") then h.Color = Color3.fromRGB(150, 150, 150)
    h.Material = Enum.Material.SmoothPlastic end end end
    local data = OriginalCharacterData[player]
    if data and data.Clothes then for _, cloth in ipairs(data.Clothes) do cloth.Parent = nil end end end
	local function RestoreGray() for player, data in pairs(OriginalCharacterData) do if player.Character then for part, props in pairs(data.Parts) do if part.Parent then part.Color = props.Color
    part.Material = props.Material end end
    for _, cloth in ipairs(data.Clothes) do cloth.Parent = player.Character end end end
    OriginalCharacterData = {} end
	Library:CreateToggle(LegitPage, "Gray characters", false, function(state) if state then for _, player in ipairs(Players:GetChildren()) do ApplyGray(player) end
    greyConnection = Players.PlayerAdded:Connect(function(player) player.CharacterAdded:Wait()
    ApplyGray(player) end) else if greyConnection then greyConnection:Disconnect()
    greyConnection = nil end
    RestoreGray() end end)
	
    local OriginalMapData = {}
    local function SaveMap() if next(OriginalMapData) then return end
    for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then OriginalMapData[v] = {Mat = v.Material} elseif v:IsA("Texture") or v:IsA("Decal") then OriginalMapData[v] = {Trans = v.Transparency} end end end
	local function ApplyNoTextures() SaveMap()
    for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then v.Material = Enum.Material.SmoothPlastic elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end end end
	local function RestoreMap() for v, data in pairs(OriginalMapData) do if v and v.Parent then if v:IsA("BasePart") then v.Material = data.Mat elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency = data.Trans end end end
    OriginalMapData = {} end
	Library:CreateToggle(LegitPage, "Remove Textures", false, function(state) if state then ApplyNoTextures()
    mapTextureConnection = Workspace.DescendantAdded:Connect(function(v) if v:IsA("BasePart") and not v:IsA("Terrain") then v.Material = Enum.Material.SmoothPlastic elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end end) else if mapTextureConnection then mapTextureConnection:Disconnect() end
    RestoreMap() end end)
	
    Library:CreateToggle(LegitPage, "stretch screen", false, function(state) if state then getgenv().Resolution = {[".gg/scripters"] = 0.65}
    local Cam = workspace.CurrentCamera
    stretchConnection = game:GetService("RunService").RenderStepped:Connect(function() Cam.CFrame = Cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1) end) else if stretchConnection then stretchConnection:Disconnect()
    stretchConnection = nil end
    getgenv().Resolution = {[".gg/scripters"] = 1} end end)
	
    Library:CreateToggle(LegitPage, "Remove Your Steps", false, function(state) LegitSettings.MuteSteps = state
    if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end end)
	Library:CreateToggle(LegitPage, "Remove Your Jumps", false, function(state) LegitSettings.MuteJumps = state
    if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end end)
	
    local BlackFogLoop = nil
    Library:CreateToggle(LegitPage, "Black Fog (Remove Fog)", false, function(state)
        if state then
            BlackFogLoop = task.spawn(function()
                while state do
                    task.wait(1)
                    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                    if not atmosphere then atmosphere = Instance.new("Atmosphere")
                    atmosphere.Parent = Lighting end
                    if atmosphere.Density ~= 0.75 or atmosphere.Haze ~= 2.46 then
                        atmosphere.Color = Color3.fromRGB(0, 0, 0)
                        atmosphere.Glare = 0
                        atmosphere.Haze = 2.46
                        atmosphere.Decay = Color3.fromRGB(0, 0, 0)
                        atmosphere.Density = 0.75
                        atmosphere.Offset = 0
                    end
                end
            end)
        else
            if BlackFogLoop then task.cancel(BlackFogLoop) end
        end
    end)

	local hackSignals = {}
    local HACK_KEYWORDS = {"keyboard", "typing", "type", "hack", "key"}
    local function isHackSound(sound) local name = sound.Name:lower()
    for _, keyword in ipairs(HACK_KEYWORDS) do if name:find(keyword) then return true end end
    return false end
    local function isFromComputer(sound) local parent = sound.Parent
    while parent do if parent.Name == "ComputerTable" then return true end
    parent = parent.Parent end
    return false end
    local function muteHack(sound) sound.Volume = 0
    local sig = sound:GetPropertyChangedSignal("Volume"):Connect(function() sound.Volume = 0 end)
    table.insert(hackSignals, {Signal = sig, Object = sound}) end
	Library:CreateToggle(LegitPage, "Remove Pc Hack Sounds", false, function(state) if state then for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("Sound") and isHackSound(obj) and isFromComputer(obj) then muteHack(obj) end end
    hackConnection = Workspace.DescendantAdded:Connect(function(obj) if obj:IsA("Sound") then if isHackSound(obj) and isFromComputer(obj) then muteHack(obj) end end end) else if hackConnection then hackConnection:Disconnect()
    hackConnection = nil end
    for _, data in ipairs(hackSignals) do if data.Signal then data.Signal:Disconnect() end
    if data.Object then data.Object.Volume = 0.5 end end
    hackSignals = {} end end)
    
    Library:CreateFooter(LegitPage)
end

do
    Library:CreateSection(TeleportPage, "Players Teleport")
    local function UpdateTeleportList()
        for _, child in pairs(TeleportPage:GetChildren()) do if child:IsA("Frame") and child.Name ~= "Frame" then child:Destroy() elseif child:IsA("TextButton") then child:Destroy() end end
        local RefreshBtn = Instance.new("TextButton")
        RefreshBtn.Size = UDim2.new(1, 0, 0, 32)
        RefreshBtn.BackgroundColor3 = Theme.ItemStroke
        RefreshBtn.Text = "Refresh"
        RefreshBtn.TextColor3 = Theme.Accent
        RefreshBtn.Font = Theme.Font
        RefreshBtn.TextSize = 13
        RefreshBtn.Parent = TeleportPage
        Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)
        RefreshBtn.MouseButton1Click:Connect(function() UpdateTeleportList() end)
        local Spacer = Instance.new("Frame")
        Spacer.Name = "Spacer"
        Spacer.Size = UDim2.new(1, 0, 0, 5)
        Spacer.BackgroundTransparency = 1
        Spacer.Parent = TeleportPage
        for _, player in pairs(Players:GetPlayers()) do 
            if player ~= LocalPlayer then 
                Library:CreatePlayerCard(TeleportPage, player, function() 
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0) 
                    end 
                end) 
            end 
        end
    end
    UpdateTeleportList()
    
    Library:CreateFooter(TeleportPage)
end

do
    local CursorList = {
        {Name = "Default", ID = "RESET"}, {Name = "Use Cursor", ID = "15368174199"}, {Name = "Use Cursor", ID = "12701650945"}, {Name = "Use Cursor", ID = "128514706094926"}, {Name = "Use Cursor", ID = "119350232226515"}, {Name = "Use Cursor", ID = "5060823578"}, {Name = "Use Cursor", ID = "9896571799"}, {Name = "Use Cursor", ID = "139654963330788"}, {Name = "Use Cursor", ID = "13441649168"}, {Name = "Use Cursor", ID = "88005681147215"}, {Name = "Use Cursor", ID = "72902755839437"}, {Name = "Use Cursor", ID = "128926155948846"}, {Name = "Use Cursor", ID = "95348763251820"}, {Name = "Use Cursor", ID = "138513473967293"}, {Name = "Use Cursor", ID = "82043397777881"}, {Name = "Use Cursor", ID = "84583215296063"}, {Name = "Use Cursor", ID = "120058675182639"}, {Name = "Use Cursor", ID = "130210380679877"}, {Name = "Use Cursor", ID = "74264514489577"}, {Name = "Use Cursor", ID = "115877213393063"}, {Name = "Use Cursor", ID = "133579119074302"}, {Name = "Use Cursor", ID = "137970082797101"}, {Name = "Use Cursor", ID = "116865736993390"}
    }
    Library:CreateSection(CrossHairPage, "Settings")
    Library:CreateSlider(CrossHairPage, "Cursor Size", 10, 100, 24, UpdateCursorSizes)
    Library:CreateSection(CrossHairPage, "Computer Cursor")
    Library:CreateCustomIDInput(CrossHairPage, false)
    Library:CreateCursorGrid(CrossHairPage, CursorList, false)
    Library:CreateSection(CrossHairPage, "Mobile Cursor")
    Library:CreateCustomIDInput(CrossHairPage, true)
    Library:CreateCursorGrid(CrossHairPage, CursorList, true)
    
    Library:CreateFooter(CrossHairPage)
end

do
    local SoundIDs = {Facility = {Walk = "131592620665625", Jump = "89459688918065", Fall = "88947883822456"}, Noob = {Walk = "110709356093026", Jump = "124276657634407", Fall = "88947883822456"}, Morcego = {Walk = "97458293386939", Jump = "72503238596964", Fall = "83702883984130"}, FKPS = {Walk = "97733831736820", Jump = "86031664547378", Fall = "78180192109919"}, Normal = {Walk = "79392671800290", Jump = "80853972291847", Fall = "88947883822456"}, Others = {Pew = "136299701781122", Sharingan = "118102230060662", Bubble = "129415490412106", Laugh = "80276851298640"}}

    Library:CreateSection(SoundsPage, "General")
    Library:CreateSlider(SoundsPage, "Volume Boost", 0, 10, 1, function(val) for _, sound in pairs(workspace:GetDescendants()) do if sound:IsA("Sound") then sound.Volume = val end end end)
    Library:CreateButton(SoundsPage, "Default Sounds (Reset)", function() CurrentSoundIDs.Running = 0
    CurrentSoundIDs.Jumping = 0
    CurrentSoundIDs.Landing = 0
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "Facility Gamer")
    Library:CreateButton(SoundsPage, "FootSteps", function() CurrentSoundIDs.Running = SoundIDs.Facility.Walk
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Facility.Jump
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "NoobTwoPoint")
    Library:CreateButton(SoundsPage, "FootSteps", function() CurrentSoundIDs.Running = SoundIDs.Noob.Walk
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Noob.Jump
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "Tio Morcego")
    Library:CreateButton(SoundsPage, "FootSteps", function() CurrentSoundIDs.Running = SoundIDs.Morcego.Walk
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Morcego.Jump
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Fall", function() CurrentSoundIDs.Landing = SoundIDs.Morcego.Fall
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "FKPS")
    Library:CreateButton(SoundsPage, "FootSteps", function() CurrentSoundIDs.Running = SoundIDs.FKPS.Walk
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Jumps", function() CurrentSoundIDs.Jumping = SoundIDs.FKPS.Jump
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Fall", function() CurrentSoundIDs.Landing = SoundIDs.FKPS.Fall
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "Normal")
    Library:CreateButton(SoundsPage, "FootSteps", function() CurrentSoundIDs.Running = SoundIDs.Normal.Walk
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Normal.Jump
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Fall", function() CurrentSoundIDs.Landing = SoundIDs.Normal.Fall
    RefreshAllSounds() end)

    Library:CreateSection(SoundsPage, "Others")
    Library:CreateButton(SoundsPage, "Pew Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Others.Pew
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Sharingan Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Others.Sharingan
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Albino Jump", function() CurrentSoundIDs.Jumping = SoundIDs.Others.Bubble
    RefreshAllSounds() end)
    Library:CreateButton(SoundsPage, "Anime Laugh", function() CurrentSoundIDs.Jumping = SoundIDs.Others.Laugh
    RefreshAllSounds() end)
    
    Library:CreateFooter(SoundsPage)
end

do
	Library:CreateSection(ScriptInfoPage, "Informacoes do Script")
	Library:CreateButton(ScriptInfoPage, "NexVoid Hub V2 - Editado", function() end)
	Library:CreateButton(ScriptInfoPage, "Desenvolvedores: DraxynSoulx", function() end)
    
    Library:CreateFooter(ScriptInfoPage)
end

if tabs[1] then 
	tabs[1].Page.Visible = true
	tabs[1].Indicator.BackgroundTransparency = 0
	tabs[1].Label.TextTransparency = 0
	tabs[1].Icon.ImageTransparency = 0
end

ScreenGui.Enabled = true
MainFrame.Visible = true
OpenButton.Visible = false
