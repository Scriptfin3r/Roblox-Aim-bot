--[[
    Mobile-Friendly Roblox AimBot for Rivals
    
    Features:
    - Automatic target acquisition
    - Customizable aim settings
    - Mobile-friendly UI with draggable panels
    - Works with most Roblox games
    - Supports mouse and touch inputs
]]

-- Configuration
local Config = {
    Enabled = false,
    AimPart = "Head", -- Target part (Head, HumanoidRootPart, Torso, etc.)
    TeamCheck = true, -- Don't target teammates
    VisibilityCheck = true, -- Check if target is visible
    TargetESP = true, -- Highlight current target
    FOV = 500, -- Field of view circle radius
    ShowFOV = true, -- Show FOV circle
    Sensitivity = 0.5, -- Aim smoothness (0-1)
    MaxDistance = 1000, -- Maximum targeting distance
    TriggerBot = false, -- Auto-fire when target acquired
    IgnoreWalls = false, -- Target through walls
    TargetPriority = "Distance", -- Distance, Health, or Threat
    WhitelistedTeams = {}, -- Teams that won't be targeted
    BlacklistedPlayers = {}, -- Players that won't be targeted
    WhitelistedPlayers = {}, -- Players that will be prioritized
    AimKey = Enum.UserInputType.MouseButton2, -- Right mouse button
    TriggerKey = Enum.UserInputType.MouseButton1, -- Left mouse button
    ToggleKey = Enum.KeyCode.RightAlt, -- Toggle aimbot on/off
    MobileButtonPosition = UDim2.new(0.9, -25, 0.5, -25) -- Position for mobile button
}

-- Variables
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Dragging = false
local Target = nil
local GuiObjects = {}
local MobileEnabled = false
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Create UI Function
local function CreateUI()
    -- Main Frame
    local AimBotGui = Instance.new("ScreenGui")
    AimBotGui.Name = "AimAssistGUI"
    AimBotGui.ResetOnSpawn = false
    AimBotGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Check if the game is running on Roblox CoreGui
    local success, result = pcall(function()
        AimBotGui.Parent = game:GetService("CoreGui")
        return true
    end)
    
    if not success then
        AimBotGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Control Panel
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "ControlPanel"
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderColor3 = Color3.fromRGB(138, 43, 226) -- Purple
    MainFrame.BorderSizePixel = 2
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    MainFrame.Size = UDim2.new(0, 300, 0, 250)
    MainFrame.Active = true
    MainFrame.Draggable = true -- Make it draggable on PC
    MainFrame.Visible = false -- Hidden by default
    MainFrame.Parent = AimBotGui
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Parent = MainFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "AIM ASSISTANT V2.1"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(1, -25, 0, 5)
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14
    CloseButton.Parent = TitleBar
    
    -- Mobile drag handling for title bar
    local function HandleDragging(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local dragInput = input
            local dragStart = input.Position
            local startPos = MainFrame.Position
            
            local function Update(input)
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
            
            Dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and Dragging then
                    Update(input)
                end
            end)
        end
    end
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            HandleDragging(input)
        end
    end)
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 0, 0, 30)
    ContentContainer.Size = UDim2.new(1, 0, 1, -30)
    ContentContainer.Parent = MainFrame
    
    -- Enabled Toggle
    local EnabledLabel = Instance.new("TextLabel")
    EnabledLabel.Name = "EnabledLabel"
    EnabledLabel.BackgroundTransparency = 1
    EnabledLabel.Position = UDim2.new(0, 10, 0, 10)
    EnabledLabel.Size = UDim2.new(0, 200, 0, 25)
    EnabledLabel.Font = Enum.Font.Gotham
    EnabledLabel.Text = "Aim Assistant:"
    EnabledLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnabledLabel.TextSize = 14
    EnabledLabel.TextXAlignment = Enum.TextXAlignment.Left
    EnabledLabel.Parent = ContentContainer
    
    local EnabledButton = Instance.new("TextButton")
    EnabledButton.Name = "EnabledButton"
    EnabledButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Red when disabled
    EnabledButton.BorderSizePixel = 1
    EnabledButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
    EnabledButton.Position = UDim2.new(1, -100, 0, 10)
    EnabledButton.Size = UDim2.new(0, 90, 0, 25)
    EnabledButton.Font = Enum.Font.GothamBold
    EnabledButton.Text = "DISABLED"
    EnabledButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnabledButton.TextSize = 12
    EnabledButton.Parent = ContentContainer
    
    -- Sensitivity Slider
    local SensitivityLabel = Instance.new("TextLabel")
    SensitivityLabel.Name = "SensitivityLabel"
    SensitivityLabel.BackgroundTransparency = 1
    SensitivityLabel.Position = UDim2.new(0, 10, 0, 45)
    SensitivityLabel.Size = UDim2.new(0, 200, 0, 25)
    SensitivityLabel.Font = Enum.Font.Gotham
    SensitivityLabel.Text = "Sensitivity: " .. Config.Sensitivity * 100 .. "%"
    SensitivityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SensitivityLabel.TextSize = 14
    SensitivityLabel.TextXAlignment = Enum.TextXAlignment.Left
    SensitivityLabel.Parent = ContentContainer
    
    local SensitivitySlider = Instance.new("Frame")
    SensitivitySlider.Name = "SensitivitySlider"
    SensitivitySlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    SensitivitySlider.BorderSizePixel = 0
    SensitivitySlider.Position = UDim2.new(0, 10, 0, 70)
    SensitivitySlider.Size = UDim2.new(1, -20, 0, 6)
    SensitivitySlider.Parent = ContentContainer
    
    local SensitivityFill = Instance.new("Frame")
    SensitivityFill.Name = "SensitivityFill"
    SensitivityFill.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
    SensitivityFill.BorderSizePixel = 0
    SensitivityFill.Size = UDim2.new(Config.Sensitivity, 0, 1, 0)
    SensitivityFill.Parent = SensitivitySlider
    
    local SensitivityKnob = Instance.new("TextButton")
    SensitivityKnob.Name = "SensitivityKnob"
    SensitivityKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SensitivityKnob.BorderSizePixel = 0
    SensitivityKnob.Position = UDim2.new(Config.Sensitivity, -8, 0.5, -8)
    SensitivityKnob.Size = UDim2.new(0, 16, 0, 16)
    SensitivityKnob.Text = ""
    SensitivityKnob.Parent = SensitivitySlider
    
    local SensitivityRound = Instance.new("UICorner")
    SensitivityRound.CornerRadius = UDim.new(1, 0)
    SensitivityRound.Parent = SensitivityKnob
    
    -- FOV Slider
    local FOVLabel = Instance.new("TextLabel")
    FOVLabel.Name = "FOVLabel"
    FOVLabel.BackgroundTransparency = 1
    FOVLabel.Position = UDim2.new(0, 10, 0, 85)
    FOVLabel.Size = UDim2.new(0, 200, 0, 25)
    FOVLabel.Font = Enum.Font.Gotham
    FOVLabel.Text = "FOV: " .. Config.FOV
    FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVLabel.TextSize = 14
    FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
    FOVLabel.Parent = ContentContainer
    
    local FOVSlider = Instance.new("Frame")
    FOVSlider.Name = "FOVSlider"
    FOVSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    FOVSlider.BorderSizePixel = 0
    FOVSlider.Position = UDim2.new(0, 10, 0, 110)
    FOVSlider.Size = UDim2.new(1, -20, 0, 6)
    FOVSlider.Parent = ContentContainer
    
    -- Calculate relative FOV position (20-1000 range)
    local fovRelative = (Config.FOV - 20) / (1000 - 20)
    
    local FOVFill = Instance.new("Frame")
    FOVFill.Name = "FOVFill"
    FOVFill.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
    FOVFill.BorderSizePixel = 0
    FOVFill.Size = UDim2.new(fovRelative, 0, 1, 0)
    FOVFill.Parent = FOVSlider
    
    local FOVKnob = Instance.new("TextButton")
    FOVKnob.Name = "FOVKnob"
    FOVKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FOVKnob.BorderSizePixel = 0
    FOVKnob.Position = UDim2.new(fovRelative, -8, 0.5, -8)
    FOVKnob.Size = UDim2.new(0, 16, 0, 16)
    FOVKnob.Text = ""
    FOVKnob.Parent = FOVSlider
    
    local FOVRound = Instance.new("UICorner")
    FOVRound.CornerRadius = UDim.new(1, 0)
    FOVRound.Parent = FOVKnob
    
    -- Target Part Dropdown
    local PartLabel = Instance.new("TextLabel")
    PartLabel.Name = "PartLabel"
    PartLabel.BackgroundTransparency = 1
    PartLabel.Position = UDim2.new(0, 10, 0, 125)
    PartLabel.Size = UDim2.new(0, 200, 0, 25)
    PartLabel.Font = Enum.Font.Gotham
    PartLabel.Text = "Target Part:"
    PartLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PartLabel.TextSize = 14
    PartLabel.TextXAlignment = Enum.TextXAlignment.Left
    PartLabel.Parent = ContentContainer
    
    local PartDropdown = Instance.new("TextButton")
    PartDropdown.Name = "PartDropdown"
    PartDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    PartDropdown.BorderSizePixel = 1
    PartDropdown.BorderColor3 = Color3.fromRGB(100, 100, 100)
    PartDropdown.Position = UDim2.new(0, 120, 0, 125)
    PartDropdown.Size = UDim2.new(0, 160, 0, 25)
    PartDropdown.Font = Enum.Font.Gotham
    PartDropdown.Text = Config.AimPart
    PartDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    PartDropdown.TextSize = 12
    PartDropdown.Parent = ContentContainer
    
    -- Toggle Buttons
    local toggles = {
        {name = "TeamCheck", label = "Team Check", value = Config.TeamCheck, pos = 160},
        {name = "ShowFOV", label = "Show FOV", value = Config.ShowFOV, pos = 190},
        {name = "TriggerBot", label = "Trigger Bot", value = Config.TriggerBot, pos = 220},
    }
    
    for i, toggle in ipairs(toggles) do
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Name = toggle.name .. "Label"
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Position = UDim2.new(0, 10, 0, toggle.pos)
        ToggleLabel.Size = UDim2.new(0, 200, 0, 25)
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.Text = toggle.label .. ":"
        ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleLabel.TextSize = 14
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ContentContainer
        
        local ToggleButton = Instance.new("Frame")
        ToggleButton.Name = toggle.name .. "Toggle"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ToggleButton.BorderSizePixel = 1
        ToggleButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
        ToggleButton.Position = UDim2.new(0, 120, 0, toggle.pos)
        ToggleButton.Size = UDim2.new(0, 40, 0, 20)
        ToggleButton.Parent = ContentContainer
        
        local ToggleIndicator = Instance.new("Frame")
        ToggleIndicator.Name = "Indicator"
        ToggleIndicator.BorderSizePixel = 0
        ToggleIndicator.Size = UDim2.new(0, 16, 0, 16)
        
        if toggle.value then
            ToggleIndicator.Position = UDim2.new(1, -19, 0.5, -8)
            ToggleIndicator.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green when enabled
        else
            ToggleIndicator.Position = UDim2.new(0, 3, 0.5, -8)
            ToggleIndicator.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Red when disabled
        end
        
        ToggleIndicator.Parent = ToggleButton
        
        local ToggleRound = Instance.new("UICorner")
        ToggleRound.CornerRadius = UDim.new(0.5, 0)
        ToggleRound.Parent = ToggleIndicator
    end
    
    -- Mobile toggle button (always visible)
    local MobileButton = Instance.new("TextButton")
    MobileButton.Name = "MobileButton"
    MobileButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
    MobileButton.BackgroundTransparency = 0.3
    MobileButton.BorderSizePixel = 0
    MobileButton.Position = Config.MobileButtonPosition
    MobileButton.Size = UDim2.new(0, 50, 0, 50)
    MobileButton.Font = Enum.Font.GothamBold
    MobileButton.Text = "AIM"
    MobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileButton.TextSize = 12
    MobileButton.Visible = IsMobile -- Only show on mobile
    MobileButton.Parent = AimBotGui
    
    local MobileRound = Instance.new("UICorner")
    MobileRound.CornerRadius = UDim.new(1, 0)
    MobileRound.Parent = MobileButton
    
    -- Mobile drag handling
    local function HandleMobileButtonDrag(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local dragInput = input
            local dragStart = input.Position
            local startPos = MobileButton.Position
            
            local function Update(input)
                local delta = input.Position - dragStart
                MobileButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
            
            Dragging = true
            dragStart = input.Position
            startPos = MobileButton.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and Dragging then
                    Update(input)
                end
            end)
        end
    end
    
    MobileButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if input.UserInputState == Enum.UserInputState.Begin then
                HandleMobileButtonDrag(input)
            end
        end
    end)
    
    -- FOV Circle
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = Config.ShowFOV
    FOVCircle.Transparency = 0.5
    FOVCircle.Color = Color3.fromRGB(138, 43, 226) -- Purple
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Config.FOV
    FOVCircle.Filled = false
    
    -- Store GUI objects for updates
    GuiObjects = {
        GUI = AimBotGui,
        MainFrame = MainFrame,
        MobileButton = MobileButton,
        EnabledButton = EnabledButton,
        SensitivityLabel = SensitivityLabel,
        SensitivityFill = SensitivityFill,
        SensitivityKnob = SensitivityKnob,
        FOVLabel = FOVLabel, 
        FOVFill = FOVFill,
        FOVKnob = FOVKnob,
        FOVCircle = FOVCircle,
        PartDropdown = PartDropdown,
        TeamCheckToggle = ContentContainer:FindFirstChild("TeamCheckToggle"),
        ShowFOVToggle = ContentContainer:FindFirstChild("ShowFOVToggle"),
        TriggerBotToggle = ContentContainer:FindFirstChild("TriggerBotToggle")
    }
    
    -- Button Click Events
    EnabledButton.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        UpdateUI()
    end)
    
    -- Mobile Button Click
    MobileButton.MouseButton1Click:Connect(function()
        -- For single taps, toggle the menu visibility
        if not Dragging then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    -- Mobile touch activation
    MobileButton.TouchLongPress:Connect(function(_, state)
        if state == Enum.UserInputState.Begin then
            MobileEnabled = true
            UpdateUI()
        elseif state == Enum.UserInputState.End then
            MobileEnabled = false
            UpdateUI()
        end
    end)
    
    -- Sliders functionality
    local function updateSensitivity(input)
        local absolutePosition = input.Position.X
        local sliderPosition = SensitivitySlider.AbsolutePosition.X
        local sliderWidth = SensitivitySlider.AbsoluteSize.X
        
        local relativeX = math.clamp((absolutePosition - sliderPosition) / sliderWidth, 0, 1)
        Config.Sensitivity = relativeX
        UpdateUI()
    end
    
    local function updateFOV(input)
        local absolutePosition = input.Position.X
        local sliderPosition = FOVSlider.AbsolutePosition.X
        local sliderWidth = FOVSlider.AbsoluteSize.X
        
        local relativeX = math.clamp((absolutePosition - sliderPosition) / sliderWidth, 0, 1)
        Config.FOV = 20 + relativeX * (1000 - 20) -- Scale from 20 to 1000
        Config.FOV = math.floor(Config.FOV) -- Round to integer
        UpdateUI()
    end
    
    -- Slider drag events
    SensitivityKnob.MouseButton1Down:Connect(function()
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                updateSensitivity(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                if connection then connection:Disconnect() end
            end
        end)
    end)
    
    FOVKnob.MouseButton1Down:Connect(function()
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                updateFOV(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                if connection then connection:Disconnect() end
            end
        end)
    end)
    
    -- Toggle buttons
    for _, toggleName in ipairs({"TeamCheck", "ShowFOV", "TriggerBot"}) do
        local toggleButton = ContentContainer:FindFirstChild(toggleName .. "Toggle")
        if toggleButton then
            toggleButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    Config[toggleName] = not Config[toggleName]
                    UpdateUI()
                end
            end)
        end
    end
    
    -- Target part dropdown
    local dropdownOpen = false
    local dropdownMenu
    
    PartDropdown.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        
        if dropdownOpen then
            -- Create dropdown menu
            if dropdownMenu then dropdownMenu:Destroy() end
            
            dropdownMenu = Instance.new("Frame")
            dropdownMenu.Name = "DropdownMenu"
            dropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            dropdownMenu.BorderSizePixel = 1
            dropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
            dropdownMenu.Position = UDim2.new(0, 120, 0, 150)
            dropdownMenu.Size = UDim2.new(0, 160, 0, 120)
            dropdownMenu.ZIndex = 10
            dropdownMenu.Parent = ContentContainer
            
            local parts = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
            
            for i, part in ipairs(parts) do
                local option = Instance.new("TextButton")
                option.Name = part .. "Option"
                option.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                option.BackgroundTransparency = 0.5
                option.BorderSizePixel = 0
                option.Position = UDim2.new(0, 0, 0, (i-1) * 20)
                option.Size = UDim2.new(1, 0, 0, 20)
                option.Font = Enum.Font.Gotham
                option.Text = part
                option.TextColor3 = Color3.fromRGB(255, 255, 255)
                option.TextSize = 12
                option.ZIndex = 11
                option.Parent = dropdownMenu
                
                if part == Config.AimPart then
                    option.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple highlight
                    option.BackgroundTransparency = 0.7
                end
                
                option.MouseButton1Click:Connect(function()
                    Config.AimPart = part
                    dropdownOpen = false
                    dropdownMenu:Destroy()
                    UpdateUI()
                end)
            end
        else
            -- Close dropdown menu
            if dropdownMenu then dropdownMenu:Destroy() end
        end
    end)
    
    -- Close button
    CloseButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)
    
    return GuiObjects
end

-- Update UI Function
function UpdateUI()
    if not GuiObjects or not GuiObjects.GUI then return end
    
    -- Update enabled status
    if GuiObjects.EnabledButton then
        if Config.Enabled then
            GuiObjects.EnabledButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green
            GuiObjects.EnabledButton.Text = "ENABLED"
        else
            GuiObjects.EnabledButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Red
            GuiObjects.EnabledButton.Text = "DISABLED"
        end
    end
    
    -- Update mobile button
    if GuiObjects.MobileButton then
        if MobileEnabled then
            GuiObjects.MobileButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green
        else
            GuiObjects.MobileButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
        end
    end
    
    -- Update sensitivity
    if GuiObjects.SensitivityLabel then
        GuiObjects.SensitivityLabel.Text = "Sensitivity: " .. math.floor(Config.Sensitivity * 100) .. "%"
    end
    
    if GuiObjects.SensitivityFill then
        GuiObjects.SensitivityFill.Size = UDim2.new(Config.Sensitivity, 0, 1, 0)
    end
    
    if GuiObjects.SensitivityKnob then
        GuiObjects.SensitivityKnob.Position = UDim2.new(Config.Sensitivity, -8, 0.5, -8)
    end
    
    -- Update FOV
    if GuiObjects.FOVLabel then
        GuiObjects.FOVLabel.Text = "FOV: " .. Config.FOV
    end
    
    local fovRelative = (Config.FOV - 20) / (1000 - 20)
    
    if GuiObjects.FOVFill then
        GuiObjects.FOVFill.Size = UDim2.new(fovRelative, 0, 1, 0)
    end
    
    if GuiObjects.FOVKnob then
        GuiObjects.FOVKnob.Position = UDim2.new(fovRelative, -8, 0.5, -8)
    end
    
    -- Update FOV circle
    if GuiObjects.FOVCircle then
        GuiObjects.FOVCircle.Visible = Config.ShowFOV and (Config.Enabled or MobileEnabled)
        GuiObjects.FOVCircle.Radius = Config.FOV
    end
    
    -- Update part dropdown
    if GuiObjects.PartDropdown then
        GuiObjects.PartDropdown.Text = Config.AimPart
    end
    
    -- Update toggle buttons
    local toggles = {
        {name = "TeamCheck", element = GuiObjects.TeamCheckToggle},
        {name = "ShowFOV", element = GuiObjects.ShowFOVToggle},
        {name = "TriggerBot", element = GuiObjects.TriggerBotToggle}
    }
    
    for _, toggle in ipairs(toggles) do
        if toggle.element then
            local indicator = toggle.element:FindFirstChild("Indicator")
            if indicator then
                if Config[toggle.name] then
                    indicator.Position = UDim2.new(1, -19, 0.5, -8)
                    indicator.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green
                else
                    indicator.Position = UDim2.new(0, 3, 0.5, -8)
                    indicator.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Red
                end
            end
        end
    end
end

-- Get closest player function
local function GetClosestPlayer()
    local MaxDistance = Config.MaxDistance
    local Target = nil
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            if Config.TeamCheck and v.Team == LocalPlayer.Team then continue end
            if table.find(Config.BlacklistedPlayers, v.Name) then continue end
            
            local Character = v.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            
            if not Character or not Humanoid or not HumanoidRootPart or Humanoid.Health <= 0 then
                continue
            end
            
            local ScreenPosition, OnScreen = Camera:WorldToScreenPoint(HumanoidRootPart.Position)
            
            if not OnScreen then
                continue
            end
            
            local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            
            if Distance > Config.FOV then
                continue
            end
            
            local Part = Character:FindFirstChild(Config.AimPart)
            
            if not Part then
                continue
            end
            
            local PartPos = Part.Position
            local PartDistance = (HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            
            if PartDistance > MaxDistance then
                continue
            end
            
            if Config.VisibilityCheck and not Config.IgnoreWalls then
                local PartVector = Part.Position - Camera.CFrame.Position
                local PartDirection = PartVector.Unit
                
                local RaycastResult = workspace:Raycast(Camera.CFrame.Position, PartDirection * PartVector.Magnitude, {
                    LocalPlayer.Character,
                    Character
                })
                
                if RaycastResult then
                    continue
                end
            end
            
            -- Distance is good and part is found
            if Config.TargetPriority == "Distance" then
                -- Already sorted by distance
                MaxDistance = PartDistance
                Target = {
                    Player = v,
                    Character = Character,
                    Part = Part,
                    Position = PartPos,
                    Distance = PartDistance,
                    Health = Humanoid.Health
                }
            elseif Config.TargetPriority == "Health" then
                -- Sort by lowest health
                if Target and Target.Health < Humanoid.Health then
                    continue
                end
                
                MaxDistance = PartDistance
                Target = {
                    Player = v,
                    Character = Character,
                    Part = Part,
                    Position = PartPos,
                    Distance = PartDistance,
                    Health = Humanoid.Health
                }
            else -- "Threat" - combine distance and health
                local ThreatLevel = (100 - Humanoid.Health) * (1000 - PartDistance)
                local CurrentThreatLevel = Target and (100 - Target.Health) * (1000 - Target.Distance) or 0
                
                if Target and ThreatLevel <= CurrentThreatLevel then
                    continue
                end
                
                MaxDistance = PartDistance
                Target = {
                    Player = v,
                    Character = Character,
                    Part = Part,
                    Position = PartPos,
                    Distance = PartDistance,
                    Health = Humanoid.Health
                }
            end
        end
    end
    
    return Target
end

-- Crosshair ESP
local CrosshairESP = Drawing.new("Circle")
CrosshairESP.Transparency = 1
CrosshairESP.Thickness = 1.5
CrosshairESP.Color = Color3.fromRGB(255, 0, 0)
CrosshairESP.Filled = true
CrosshairESP.Visible = false
CrosshairESP.Radius = 4
CrosshairESP.NumSides = 12

-- Target ESP
local TargetText = Drawing.new("Text")
TargetText.Visible = false
TargetText.Center = true
TargetText.Outline = true
TargetText.Font = 3
TargetText.Color = Color3.fromRGB(255, 0, 0)
TargetText.Size = 16

-- Mouse down tracker
local MouseDown = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Config.AimKey then
        MouseDown = true
    end
    
    -- Toggle aimbot with keybind
    if input.KeyCode == Config.ToggleKey then
        Config.Enabled = not Config.Enabled
        UpdateUI()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AimKey then
        MouseDown = false
        Target = nil
    end
end)

-- Initialize the UI
GuiObjects = CreateUI()

-- Main aimbot loop
RunService:BindToRenderStep("AimBot", 0, function()
    -- Update FOV circle position
    if GuiObjects.FOVCircle then
        GuiObjects.FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    end
    
    CrosshairESP.Position = Vector2.new(Mouse.X, Mouse.Y)
    CrosshairESP.Visible = Target ~= nil and Config.TargetESP and (Config.Enabled or MobileEnabled)
    
    -- Determine if aimbot is active
    local AimbotActive = (Config.Enabled and MouseDown) or MobileEnabled
    
    if not AimbotActive then
        Target = nil
        TargetText.Visible = false
        return
    end
    
    -- Get the closest player within FOV
    Target = GetClosestPlayer()
    
    if Target then
        -- Add target ESP
        if Config.TargetESP then
            local ScreenPosition = Camera:WorldToScreenPoint(Target.Part.Position)
            TargetText.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y - 30)
            TargetText.Text = Target.Player.Name .. " [" .. math.floor(Target.Distance) .. "m]"
            TargetText.Visible = true
        else
            TargetText.Visible = false
        end
        
        -- Calculate the aim position
        local ScreenPosition = Camera:WorldToScreenPoint(Target.Position)
        local AimPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
        
        -- Apply aim smoothing
        local MoveAmount = Vector2.new(
            (AimPosition.X - Mouse.X) * Config.Sensitivity,
            (AimPosition.Y - Mouse.Y) * Config.Sensitivity
        )
        
        -- Apply aim movement
        mousemoverel(MoveAmount.X, MoveAmount.Y)
        
        -- Auto-fire if trigger bot is enabled
        if Config.TriggerBot then
            local Humanoid = Target.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                -- Check if crosshair is over target
                if math.abs(AimPosition.X - Mouse.X) < 30 and math.abs(AimPosition.Y - Mouse.Y) < 30 then
                    -- Simulate mouse click
                    mouse1click()
                end
            end
        end
    else
        TargetText.Visible = false
    end
end)

-- Close UI when the script is terminated
game:GetService("Players").LocalPlayer.Character.Humanoid.Died:Connect(function()
    -- Cleanup drawings
    GuiObjects.FOVCircle:Remove()
    CrosshairESP:Remove()
    TargetText:Remove()
    
    -- Destroy UI
    if GuiObjects.GUI then
        GuiObjects.GUI:Destroy()
    end
end)

-- Instructions in console
print("=== MOBILE-FRIENDLY AIMBOT FOR ROBLOX RIVALS ===")
print("Aim Assist is now running!")
print("Instructions:")
print("- On PC: Right-click to activate aimbot")
print("- On Mobile: Press and hold the AIM button")
print("- Right Alt toggles aimbot on/off")
print("- Settings can be adjusted in the control panel")
print("===== Enjoy! =====")