--[[
    Acinonyx UI Library
    Modern UI Library for Roblox Script Executors
    Version: 1.0.0
]]

local Acinonyx = {}
Acinonyx.__index = Acinonyx

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Utility Functions
local function Tween(instance, properties, duration)
    duration = duration or 0.3
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, mousePos, framePos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Tween(frame, {Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)}, 0.1)
        end
    end)
end

-- Notification System
local NotificationHolder = nil
local ActiveNotifications = {}

local function CreateNotification(title, text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info" -- info, success, warning, error
    
    -- Create notification holder if it doesn't exist
    if not NotificationHolder or not NotificationHolder.Parent then
        local NotifGui = Instance.new("ScreenGui")
        NotifGui.Name = "AcinonyxNotifications"
        NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NotifGui.ResetOnSpawn = false
        NotifGui.DisplayOrder = 999
        
        if syn then
            syn.protect_gui(NotifGui)
            NotifGui.Parent = CoreGui
        else
            NotifGui.Parent = CoreGui
        end
        
        NotificationHolder = Instance.new("Frame")
        NotificationHolder.Name = "NotificationHolder"
        NotificationHolder.Size = UDim2.new(0, 300, 1, -20)
        NotificationHolder.Position = UDim2.new(1, -310, 1, -20)
        NotificationHolder.AnchorPoint = Vector2.new(0, 1)
        NotificationHolder.BackgroundTransparency = 1
        NotificationHolder.Parent = NotifGui
        
        local NotifLayout = Instance.new("UIListLayout")
        NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NotifLayout.Padding = UDim.new(0, 10)
        NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        NotifLayout.Parent = NotificationHolder
    end
    
    -- Color based on type
    local accentColor = Color3.fromRGB(60, 120, 220) -- info
    if notifType == "success" then
        accentColor = Color3.fromRGB(80, 200, 120)
    elseif notifType == "warning" then
        accentColor = Color3.fromRGB(255, 180, 60)
    elseif notifType == "error" then
        accentColor = Color3.fromRGB(220, 80, 80)
    end
    
    -- Notification Frame
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    NotifFrame.BackgroundTransparency = 0.2
    NotifFrame.BorderSizePixel = 0
    NotifFrame.ClipsDescendants = true
    NotifFrame.Parent = NotificationHolder
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = NotifFrame
    
    -- Content Container
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -20, 1, 0)
    ContentFrame.Position = UDim2.new(0, 10, 0, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = NotifFrame
    
    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -35, 0, 20)
    TitleLabel.Position = UDim2.new(0, 5, 0, 8)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.Parent = ContentFrame
    
    -- Description
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -10, 0, 35)
    DescLabel.Position = UDim2.new(0, 5, 0, 28)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = text
    DescLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    DescLabel.TextSize = 12
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextYAlignment = Enum.TextYAlignment.Top
    DescLabel.TextWrapped = true
    DescLabel.Parent = ContentFrame
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    CloseBtn.BackgroundTransparency = 0.3
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = ContentFrame
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 4)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Progress Bar
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, -14, 0, 2)
    ProgressBar.Position = UDim2.new(0, 7, 1, -4)
    ProgressBar.BackgroundColor3 = accentColor
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = NotifFrame
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(1, 0)
    ProgressCorner.Parent = ProgressBar
    
    -- Animation
    NotifFrame.Size = UDim2.new(1, 0, 0, 75)
    NotifFrame.BackgroundTransparency = 1
    
    Tween(NotifFrame, {BackgroundTransparency = 0.2}, 0.3)
    
    -- Auto close
    local function CloseNotification()
        Tween(NotifFrame, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        wait(0.3)
        NotifFrame:Destroy()
    end
    
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 80, 80), BackgroundTransparency = 0})
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0.3})
    end)
    
    CloseBtn.MouseButton1Click:Connect(CloseNotification)
    
    -- Progress bar animation
    Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration)
    
    -- Auto dismiss
    task.delay(duration, CloseNotification)
end

-- Main Library Functions
function Acinonyx:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Acinonyx"
    local windowSize = config.Size or UDim2.new(0, 550, 0, 400)
    
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AcinonyxUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    if syn then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = windowSize
    MainFrame.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBar.BackgroundTransparency = 0.3
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar
    
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 10)
    TopBarFix.Position = UDim2.new(0, 0, 1, -10)
    TopBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBarFix.BackgroundTransparency = 0.3
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = windowName
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
    MinimizeButton.Position = UDim2.new(1, -75, 0, 0)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MinimizeButton.BackgroundTransparency = 0.3
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.TextSize = 24
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TopBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(1, -40, 0, 0)
    CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    CloseButton.BackgroundTransparency = 0.3
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 24
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TopBar
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(60, 120, 220), BackgroundTransparency = 0})
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.3})
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(220, 50, 50), BackgroundTransparency = 0})
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.3})
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)})
        wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 120, 1, -50)
    TabContainer.Position = UDim2.new(0, 10, 0, 45)
    TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TabContainer.BackgroundTransparency = 0.3
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabContainer
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.PaddingBottom = UDim.new(0, 10)
    TabPadding.PaddingLeft = UDim.new(0, 8)
    TabPadding.PaddingRight = UDim.new(0, 8)
    TabPadding.Parent = TabContainer
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -145, 1, -50)
    ContentContainer.Position = UDim2.new(0, 135, 0, 45)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame
    
    -- Minimize Overlay
    local MinimizeOverlay = Instance.new("ImageButton")
    MinimizeOverlay.Name = "MinimizeOverlay"
    MinimizeOverlay.Size = UDim2.new(0, 80, 0, 80)
    MinimizeOverlay.Position = UDim2.new(1, -90, 1, -90)
    MinimizeOverlay.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MinimizeOverlay.BackgroundTransparency = 0.2
    MinimizeOverlay.BorderSizePixel = 0
    MinimizeOverlay.Image = "rbxassetid://109705776664856" -- Ganti dengan ID gambar Anda
    MinimizeOverlay.ImageTransparency = 0
    MinimizeOverlay.ScaleType = Enum.ScaleType.Fit
    MinimizeOverlay.Visible = false
    MinimizeOverlay.Parent = ScreenGui
    
    local OverlayCorner = Instance.new("UICorner")
    OverlayCorner.CornerRadius = UDim.new(0, 12)
    OverlayCorner.Parent = MinimizeOverlay
    
    local OverlayStroke = Instance.new("UIStroke")
    OverlayStroke.Color = Color3.fromRGB(60, 120, 220)
    OverlayStroke.Thickness = 2
    OverlayStroke.Transparency = 0.5
    OverlayStroke.Parent = MinimizeOverlay
    
    -- Make Overlay Draggable
    MakeDraggable(MinimizeOverlay, MinimizeOverlay)
    
    -- Make Draggable
    MakeDraggable(MainFrame, TopBar)
    
    -- Minimize/Restore functionality
    local isMinimized = false
    
    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = true
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        MinimizeOverlay.Visible = true
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 80, 0, 80), BackgroundTransparency = 0.2}, 0.3)
    end)
    
    MinimizeOverlay.MouseButton1Click:Connect(function()
        if isMinimized then
            isMinimized = false
            MinimizeOverlay.Visible = false
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
            Tween(MainFrame, {Size = windowSize, BackgroundTransparency = 0.3}, 0.3)
        end
    end)
    
    MinimizeOverlay.MouseEnter:Connect(function()
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 85, 0, 85)}, 0.2)
        Tween(OverlayStroke, {Transparency = 0}, 0.2)
    end)
    
    MinimizeOverlay.MouseLeave:Connect(function()
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 80, 0, 80)}, 0.2)
        Tween(OverlayStroke, {Transparency = 0.5}, 0.2)
    end)
    
    -- Window Object
    local Window = {
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        Tabs = {},
        CurrentTab = nil
    }
    
    -- Notification Method
    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local text = config.Text or "No message provided"
        local duration = config.Duration or 3
        local notifType = config.Type or "info" -- info, success, warning, error
        
        CreateNotification(title, text, duration, notifType)
    end
    
    function Window:CreateTab(tabName)
        local Tab = {}
        
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        TabButton.BackgroundTransparency = 0.3
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.Parent = TabContainer
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
        TabContent.Visible = false
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Parent = ContentContainer
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.Parent = TabContent
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingBottom = UDim.new(0, 5)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.Parent = TabContent
        
        -- Auto-resize canvas
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                tab.Button.BackgroundTransparency = 0.3
                tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
                tab.Content.Visible = false
            end
            
            TabButton.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
            TabButton.BackgroundTransparency = 0.2
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.Elements = {}
        
        -- Tab Functions
        function Tab:CreateButton(config)
            config = config or {}
            local buttonText = config.Text or "Button"
            local callback = config.Callback or function() end
            
            local Button = Instance.new("TextButton")
            Button.Name = "Button"
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Button.BackgroundTransparency = 0.3
            Button.BorderSizePixel = 0
            Button.Text = buttonText
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.TextSize = 14
            Button.Font = Enum.Font.Gotham
            Button.Parent = TabContent
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 6)
            ButtonCorner.Parent = Button
            
            Button.MouseEnter:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(60, 120, 220), BackgroundTransparency = 0.2})
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0.3})
            end)
            
            Button.MouseButton1Click:Connect(callback)
            
            return Button
        end
        
        function Tab:CreateToggle(config)
            config = config or {}
            local toggleText = config.Text or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = "ToggleFrame"
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            ToggleFrame.BackgroundTransparency = 0.3
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = toggleText
            ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleLabel.TextSize = 14
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 40, 0, 20)
            ToggleButton.Position = UDim2.new(1, -45, 0.5, -10)
            ToggleButton.BackgroundColor3 = default and Color3.fromRGB(60, 120, 220) or Color3.fromRGB(60, 60, 70)
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            
            local ToggleBtnCorner = Instance.new("UICorner")
            ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
            ToggleBtnCorner.Parent = ToggleButton
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
            ToggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Parent = ToggleButton
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                Tween(ToggleButton, {BackgroundColor3 = toggled and Color3.fromRGB(60, 120, 220) or Color3.fromRGB(60, 60, 70)})
                Tween(ToggleCircle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                
                callback(toggled)
            end)
            
            return ToggleFrame
        end
        
        function Tab:CreateSlider(config)
            config = config or {}
            local sliderText = config.Text or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local callback = config.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = "SliderFrame"
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            SliderFrame.BackgroundTransparency = 0.3
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 6)
            SliderCorner.Parent = SliderFrame
            
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -20, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = sliderText
            SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SliderLabel.TextSize = 14
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame
            
            local SliderValue = Instance.new("TextLabel")
            SliderValue.Size = UDim2.new(0, 50, 0, 20)
            SliderValue.Position = UDim2.new(1, -60, 0, 5)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Text = tostring(default)
            SliderValue.TextColor3 = Color3.fromRGB(200, 200, 200)
            SliderValue.TextSize = 14
            SliderValue.Font = Enum.Font.Gotham
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right
            SliderValue.Parent = SliderFrame
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 4)
            SliderBar.Position = UDim2.new(0, 10, 1, -15)
            SliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            
            local SliderBarCorner = Instance.new("UICorner")
            SliderBarCorner.CornerRadius = UDim.new(1, 0)
            SliderBarCorner.Parent = SliderBar
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBar
            
            local SliderFillCorner = Instance.new("UICorner")
            SliderFillCorner.CornerRadius = UDim.new(1, 0)
            SliderFillCorner.Parent = SliderFill
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBar
            
            local dragging = false
            
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                SliderValue.Text = tostring(value)
                callback(value)
            end
            
            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateSlider(input)
                end
            end)
            
            SliderButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)
            
            return SliderFrame
        end
        
        function Tab:CreateTextbox(config)
            config = config or {}
            local textboxText = config.Text or "Textbox"
            local placeholder = config.Placeholder or "Enter text..."
            local callback = config.Callback or function() end
            
            local TextboxFrame = Instance.new("Frame")
            TextboxFrame.Name = "TextboxFrame"
            TextboxFrame.Size = UDim2.new(1, 0, 0, 60)
            TextboxFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            TextboxFrame.BackgroundTransparency = 0.3
            TextboxFrame.BorderSizePixel = 0
            TextboxFrame.Parent = TabContent
            
            local TextboxCorner = Instance.new("UICorner")
            TextboxCorner.CornerRadius = UDim.new(0, 6)
            TextboxCorner.Parent = TextboxFrame
            
            local TextboxLabel = Instance.new("TextLabel")
            TextboxLabel.Size = UDim2.new(1, -20, 0, 20)
            TextboxLabel.Position = UDim2.new(0, 10, 0, 5)
            TextboxLabel.BackgroundTransparency = 1
            TextboxLabel.Text = textboxText
            TextboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextboxLabel.TextSize = 14
            TextboxLabel.Font = Enum.Font.Gotham
            TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextboxLabel.Parent = TextboxFrame
            
            local Textbox = Instance.new("TextBox")
            Textbox.Size = UDim2.new(1, -20, 0, 25)
            Textbox.Position = UDim2.new(0, 10, 0, 28)
            Textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            Textbox.BackgroundTransparency = 0.3
            Textbox.BorderSizePixel = 0
            Textbox.PlaceholderText = placeholder
            Textbox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            Textbox.Text = ""
            Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
            Textbox.TextSize = 13
            Textbox.Font = Enum.Font.Gotham
            Textbox.TextXAlignment = Enum.TextXAlignment.Left
            Textbox.Parent = TextboxFrame
            
            local TextboxInputCorner = Instance.new("UICorner")
            TextboxInputCorner.CornerRadius = UDim.new(0, 4)
            TextboxInputCorner.Parent = Textbox
            
            local TextboxPadding = Instance.new("UIPadding")
            TextboxPadding.PaddingLeft = UDim.new(0, 8)
            TextboxPadding.PaddingRight = UDim.new(0, 8)
            TextboxPadding.Parent = Textbox
            
            Textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    callback(Textbox.Text)
                end
            end)
            
            return TextboxFrame
        end
        
        function Tab:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Name = "Label"
            Label.Size = UDim2.new(1, 0, 0, 30)
            Label.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Label.BackgroundTransparency = 0.3
            Label.BorderSizePixel = 0
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = TabContent
            
            local LabelCorner = Instance.new("UICorner")
            LabelCorner.CornerRadius = UDim.new(0, 6)
            LabelCorner.Parent = Label
            
            local LabelPadding = Instance.new("UIPadding")
            LabelPadding.PaddingLeft = UDim.new(0, 10)
            LabelPadding.Parent = Label
            
            return Label
        end
        
        function Tab:CreateDropdown(config)
            config = config or {}
            local dropdownText = config.Text or "Dropdown"
            local options = config.Options or {}
            local callback = config.Callback or function() end
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "DropdownFrame"
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            DropdownFrame.BackgroundTransparency = 0.3
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 6)
            DropdownCorner.Parent = DropdownFrame
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 35)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = dropdownText
            DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            DropdownButton.TextSize = 14
            DropdownButton.Font = Enum.Font.Gotham
            DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
            DropdownButton.Parent = DropdownFrame
            
            local DropdownPadding = Instance.new("UIPadding")
            DropdownPadding.PaddingLeft = UDim.new(0, 10)
            DropdownPadding.Parent = DropdownButton
            
            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 20, 0, 35)
            Arrow.Position = UDim2.new(1, -30, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
            Arrow.TextSize = 12
            Arrow.Font = Enum.Font.Gotham
            Arrow.Parent = DropdownFrame
            
            local OptionList = Instance.new("Frame")
            OptionList.Size = UDim2.new(1, 0, 0, #options * 30)
            OptionList.Position = UDim2.new(0, 0, 0, 35)
            OptionList.BackgroundTransparency = 1
            OptionList.Parent = DropdownFrame
            
            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionLayout.Parent = OptionList
            
            local isOpen = false
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, 0, 0, 30)
                OptionButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                OptionButton.BackgroundTransparency = 0.2
                OptionButton.BorderSizePixel = 0
                OptionButton.Text = option
                OptionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                OptionButton.TextSize = 13
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.Parent = OptionList
                
                local OptionPadding = Instance.new("UIPadding")
                OptionPadding.PaddingLeft = UDim.new(0, 10)
                OptionPadding.Parent = OptionButton
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(60, 120, 220), BackgroundTransparency = 0.1})
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40), BackgroundTransparency = 0.2})
                end)
                
                OptionButton.MouseButton1Click:Connect(function()
                    DropdownButton.Text = dropdownText .. ": " .. option
                    callback(option)
                    
                    isOpen = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, {Rotation = 0})
                end)
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35 + #options * 30)})
                    Tween(Arrow, {Rotation = 180})
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, {Rotation = 0})
                end
            end)
            
            return DropdownFrame
        end
        
        function Tab:CreateMultiDropdown(config)
            config = config or {}
            local dropdownText = config.Text or "Multi Dropdown"
            local options = config.Options or {}
            local default = config.Default or {}
            local callback = config.Callback or function() end
            
            local selected = {}
            for _, v in ipairs(default) do
                selected[v] = true
            end
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = "MultiDropdownFrame"
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            DropdownFrame.BackgroundTransparency = 0.3
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 6)
            DropdownCorner.Parent = DropdownFrame
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 35)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = dropdownText
            DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            DropdownButton.TextSize = 14
            DropdownButton.Font = Enum.Font.Gotham
            DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
            DropdownButton.Parent = DropdownFrame
            
            local DropdownPadding = Instance.new("UIPadding")
            DropdownPadding.PaddingLeft = UDim.new(0, 10)
            DropdownPadding.Parent = DropdownButton
            
            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 20, 0, 35)
            Arrow.Position = UDim2.new(1, -30, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
            Arrow.TextSize = 12
            Arrow.Font = Enum.Font.Gotham
            Arrow.Parent = DropdownFrame
            
            local OptionList = Instance.new("Frame")
            OptionList.Size = UDim2.new(1, 0, 0, #options * 30)
            OptionList.Position = UDim2.new(0, 0, 0, 35)
            OptionList.BackgroundTransparency = 1
            OptionList.Parent = DropdownFrame
            
            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionLayout.Parent = OptionList
            
            local isOpen = false
            
            local function UpdateText()
                local selectedList = {}
                for option, isSelected in pairs(selected) do
                    if isSelected then
                        table.insert(selectedList, option)
                    end
                end
                
                if #selectedList > 0 then
                    DropdownButton.Text = dropdownText .. ": " .. table.concat(selectedList, ", ")
                else
                    DropdownButton.Text = dropdownText
                end
            end
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, -25, 0, 30)
                OptionButton.Position = UDim2.new(0, 0, 0, 0)
                OptionButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                OptionButton.BackgroundTransparency = 0.2
                OptionButton.BorderSizePixel = 0
                OptionButton.Text = option
                OptionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                OptionButton.TextSize = 13
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.Parent = OptionList
                
                local OptionPadding = Instance.new("UIPadding")
                OptionPadding.PaddingLeft = UDim.new(0, 10)
                OptionPadding.Parent = OptionButton
                
                -- Checkbox indicator
                local Checkbox = Instance.new("Frame")
                Checkbox.Size = UDim2.new(0, 16, 0, 16)
                Checkbox.Position = UDim2.new(1, -20, 0.5, -8)
                Checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                Checkbox.BorderSizePixel = 0
                Checkbox.Parent = OptionButton
                
                local CheckboxCorner = Instance.new("UICorner")
                CheckboxCorner.CornerRadius = UDim.new(0, 3)
                CheckboxCorner.Parent = Checkbox
                
                local Checkmark = Instance.new("TextLabel")
                Checkmark.Size = UDim2.new(1, 0, 1, 0)
                Checkmark.BackgroundTransparency = 1
                Checkmark.Text = "✓"
                Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
                Checkmark.TextSize = 14
                Checkmark.Font = Enum.Font.GothamBold
                Checkmark.Visible = selected[option] or false
                Checkmark.Parent = Checkbox
                
                if selected[option] then
                    Checkbox.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
                end
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.1})
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40), BackgroundTransparency = 0.2})
                end)
                
                OptionButton.MouseButton1Click:Connect(function()
                    selected[option] = not selected[option]
                    Checkmark.Visible = selected[option]
                    
                    if selected[option] then
                        Tween(Checkbox, {BackgroundColor3 = Color3.fromRGB(60, 120, 220)})
                    else
                        Tween(Checkbox, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)})
                    end
                    
                    UpdateText()
                    
                    local selectedList = {}
                    for opt, isSelected in pairs(selected) do
                        if isSelected then
                            table.insert(selectedList, opt)
                        end
                    end
                    callback(selectedList)
                end)
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35 + #options * 30)})
                    Tween(Arrow, {Rotation = 180})
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, {Rotation = 0})
                end
            end)
            
            UpdateText()
            
            return DropdownFrame
        end
        
        Window.Tabs[tabName] = Tab
        
        -- Auto-select first tab
        if #Window.Tabs == 1 then
            TabButton.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
            TabButton.BackgroundTransparency = 0.2
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        return Tab
    end
    
    return Window
end

return Acinonyx
