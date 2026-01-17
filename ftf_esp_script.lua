--// Aviso de Nova Versão (Compatível com executores modernos) \\--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- pega GUI correta (funciona em mobile e PC)
local parentGui =
    (gethui and gethui())
    or (syn and syn.protect_gui and game:GetService("CoreGui"))
    or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- remove UI antiga se existir
pcall(function()
    parentGui:FindFirstChild("UpdateWarningUI"):Destroy()
end)

-- SCRIPT NOVO (EXATAMENTE COMO VOCÊ PEDIU)
local NEW_SCRIPT = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/NexVoidwdmoadm"))()
]]

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UpdateWarningUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Frame principal
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 340, 0, 190)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 14)

-- Título
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -20, 0, 60)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Nova versão do script encontrada"
Title.TextWrapped = true
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Botão copiar
local CopyButton = Instance.new("TextButton", Frame)
CopyButton.Size = UDim2.new(1, -40, 0, 40)
CopyButton.Position = UDim2.new(0, 20, 0, 80)
CopyButton.Text = "Copiar novo script"
CopyButton.Font = Enum.Font.Gotham
CopyButton.TextSize = 14
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
CopyButton.BorderSizePixel = 0
Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 10)

-- Botão fechar
local CloseButton = Instance.new("TextButton", Frame)
CloseButton.Size = UDim2.new(1, -40, 0, 32)
CloseButton.Position = UDim2.new(0, 20, 0, 130)
CloseButton.Text = "Fechar"
CloseButton.Font = Enum.Font.Gotham
CloseButton.TextSize = 13
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
CloseButton.BorderSizePixel = 0
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 10)

-- FUNÇÕES
CopyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(NEW_SCRIPT)
        CopyButton.Text = "Script copiado!"
        task.delay(1.5, function()
            CopyButton.Text = "Copiar novo script"
        end)
    else
        CopyButton.Text = "Executor não suporta cópia"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
