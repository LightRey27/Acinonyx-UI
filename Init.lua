--[[
    Acinonyx UI Library
    Single-file UI library for Roblox client environments
    Version: 1.1.0
]]

local Acinonyx = {}
Acinonyx.__index = Acinonyx

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- Utility Functions
local ActiveWindowCleanup = nil

local function Connect(connections, signal, callback)
    local connection = signal:Connect(callback)
    if connections then
        table.insert(connections, connection)
    end
    return connection
end

local function DisconnectAll(connections)
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(connections)
end

local function Tween(instance, properties, duration)
    duration = duration or 0.3
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, handle, connections)
    local dragging = false
    local activeTouch = nil
    local inputStart = nil
    local frameStart = nil
    
    Connect(connections, handle.InputBegan, function(input)
        local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
        local isTouch = input.UserInputType == Enum.UserInputType.Touch
        if isMouse or isTouch then
            dragging = true
            activeTouch = isTouch and input or nil
            inputStart = input.Position
            frameStart = frame.Position
        end
    end)
    
    Connect(connections, UserInputService.InputChanged, function(input)
        local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
        local isActiveTouch = activeTouch ~= nil and input == activeTouch
        if dragging and (isMouseMove or isActiveTouch) then
            local delta = input.Position - inputStart
            frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    
    Connect(connections, UserInputService.InputEnded, function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 and activeTouch == nil) or input == activeTouch then
            dragging = false
            activeTouch = nil
        end
    end)
end

-- Notification System
local NotificationHolder = nil
local ActiveNotifications = {}

local function CreateNotification(title, text, duration, notifType, ownerNotifications, guiParent)
    duration = math.max(tonumber(duration) or 3, 0.1)
    notifType = notifType or "info" -- info, success, warning, error
    guiParent = guiParent or CoreGui
    
    -- Create notification holder if it doesn't exist
    if not NotificationHolder or not NotificationHolder.Parent then
        local NotifGui = Instance.new("ScreenGui")
        NotifGui.Name = "AcinonyxNotifications"
        NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NotifGui.ResetOnSpawn = false
        NotifGui.DisplayOrder = 999
        
        if guiParent == CoreGui and type(syn) == "table" and type(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, NotifGui)
        end
        NotifGui.Parent = guiParent
        
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
    ActiveNotifications[NotifFrame] = true
    
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
    local notificationConnections = {}
    local isClosing = false

    local function RemoveNotification()
        if NotifFrame.Parent then
            NotifFrame:Destroy()
        end
        ActiveNotifications[NotifFrame] = nil
        if ownerNotifications then
            ownerNotifications[NotifFrame] = nil
        end

        if next(ActiveNotifications) == nil and NotificationHolder and NotificationHolder.Parent then
            local notificationGui = NotificationHolder.Parent
            NotificationHolder = nil
            notificationGui:Destroy()
        end
    end

    local function CloseNotification(immediate)
        if isClosing then
            return
        end

        isClosing = true
        DisconnectAll(notificationConnections)

        if immediate then
            RemoveNotification()
            return
        end

        Tween(NotifFrame, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.delay(0.3, RemoveNotification)
    end

    if ownerNotifications then
        ownerNotifications[NotifFrame] = function()
            CloseNotification(true)
        end
    end
    
    Connect(notificationConnections, CloseBtn.MouseEnter, function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 80, 80), BackgroundTransparency = 0})
    end)
    
    Connect(notificationConnections, CloseBtn.MouseLeave, function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0.3})
    end)
    
    Connect(notificationConnections, CloseBtn.Activated, function()
        CloseNotification(false)
    end)
    
    -- Progress bar animation
    Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration)
    
    -- Auto dismiss
    task.delay(duration, CloseNotification)

    return NotifFrame
end

-- Main Library Functions
function Acinonyx:CreateWindow(config)
    config = config or {}
    local brandName = config.BrandName or config.Name or "Acinonyx UI"
    local guiParent = config.GuiParent or CoreGui
    if typeof(guiParent) ~= "Instance" then
        error("GuiParent must be a Roblox Instance", 2)
    end

    if ActiveWindowCleanup then
        ActiveWindowCleanup()
    end

    local connections = {}
    local windowNotifications = {}
    local destroyed = false
    
    -- Get viewport size for responsive scaling
    local camera = workspace.CurrentCamera
    local ViewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)
    local screenWidth = ViewportSize.X
    local screenHeight = ViewportSize.Y
    
    -- Keep the default window inside smaller viewports while retaining desktop limits.
    local availableWidth = math.max(1, screenWidth - 20)
    local availableHeight = math.max(1, screenHeight - 20)
    local defaultWidth = math.clamp(
        math.floor(screenWidth * 0.9),
        math.min(300, availableWidth),
        math.min(800, availableWidth)
    )
    local defaultHeight = math.clamp(
        math.floor(screenHeight * 0.82),
        math.min(300, availableHeight),
        math.min(600, availableHeight)
    )
    local windowSize = config.Size or UDim2.fromOffset(defaultWidth, defaultHeight)
    local windowPixelWidth = windowSize.X.Offset + screenWidth * windowSize.X.Scale
    local sidebarWidth = math.clamp(
        tonumber(config.SidebarWidth) or math.floor(windowPixelWidth * 0.21),
        150,
        math.min(220, math.max(150, windowPixelWidth - 150))
    )
    
    -- Clean up old instances
    for _, gui in pairs(guiParent:GetChildren()) do
        if gui.Name == "AcinonyxUI" then
            gui:Destroy()
        end
    end
    
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AcinonyxUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    if guiParent == CoreGui and type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, ScreenGui)
    end
    ScreenGui.Parent = guiParent
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = windowSize
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 27)
    MainFrame.BackgroundTransparency = 0.03
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(73, 82, 96)
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.18
    MainStroke.Parent = MainFrame

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(21, 27, 36)
    Sidebar.BackgroundTransparency = 0.02
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Name = "SidebarDivider"
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = Color3.fromRGB(57, 66, 79)
    SidebarDivider.BackgroundTransparency = 0.35
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.Parent = Sidebar

    local BrandIcon = Instance.new("Frame")
    BrandIcon.Name = "BrandIcon"
    BrandIcon.Size = UDim2.new(0, 34, 0, 34)
    BrandIcon.Position = UDim2.new(0, 22, 0, 17)
    BrandIcon.Rotation = 15
    BrandIcon.BackgroundColor3 = Color3.fromRGB(18, 165, 255)
    BrandIcon.BorderSizePixel = 0
    BrandIcon.Parent = Sidebar

    local BrandIconGradient = Instance.new("UIGradient")
    BrandIconGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(51, 211, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 98, 238))
    })
    BrandIconGradient.Rotation = 45
    BrandIconGradient.Parent = BrandIcon

    local BrandIconCorner = Instance.new("UICorner")
    BrandIconCorner.CornerRadius = UDim.new(0, 3)
    BrandIconCorner.Parent = BrandIcon

    local BrandIconCutout = Instance.new("Frame")
    BrandIconCutout.Name = "BrandIconCutout"
    BrandIconCutout.Size = UDim2.new(0, 10, 0, 10)
    BrandIconCutout.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandIconCutout.Position = UDim2.new(0.5, 0, 0.5, 0)
    BrandIconCutout.Rotation = -15
    BrandIconCutout.BackgroundColor3 = Sidebar.BackgroundColor3
    BrandIconCutout.BorderSizePixel = 0
    BrandIconCutout.Parent = BrandIcon

    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Name = "BrandTitle"
    BrandTitle.Size = UDim2.new(1, -72, 0, 40)
    BrandTitle.Position = UDim2.new(0, 66, 0, 14)
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.Text = brandName
    BrandTitle.TextColor3 = Color3.fromRGB(245, 247, 251)
    BrandTitle.TextSize = 17
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.TextTruncate = Enum.TextTruncate.AtEnd
    BrandTitle.Parent = Sidebar
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, -sidebarWidth, 0, 54)
    TopBar.Position = UDim2.new(0, sidebarWidth, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
    TopBar.BackgroundTransparency = 0.02
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarDivider = Instance.new("Frame")
    TopBarDivider.Name = "TopBarDivider"
    TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
    TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
    TopBarDivider.BackgroundColor3 = Color3.fromRGB(54, 62, 74)
    TopBarDivider.BackgroundTransparency = 0.45
    TopBarDivider.BorderSizePixel = 0
    TopBarDivider.Parent = TopBar
    
    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 38, 0, 38)
    MinimizeButton.Position = UDim2.new(1, -122, 0, 8)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.TextSize = 24
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TopBar

    local MaximizeButton = Instance.new("TextButton")
    MaximizeButton.Name = "MaximizeButton"
    MaximizeButton.Size = UDim2.new(0, 38, 0, 38)
    MaximizeButton.Position = UDim2.new(1, -82, 0, 8)
    MaximizeButton.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
    MaximizeButton.BackgroundTransparency = 1
    MaximizeButton.BorderSizePixel = 0
    MaximizeButton.Text = "□"
    MaximizeButton.TextColor3 = Color3.fromRGB(204, 214, 229)
    MaximizeButton.TextSize = 21
    MaximizeButton.Font = Enum.Font.Gotham
    MaximizeButton.Parent = TopBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 38, 0, 38)
    CloseButton.Position = UDim2.new(1, -42, 0, 8)
    CloseButton.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
    CloseButton.BackgroundTransparency = 1
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 24
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TopBar
    
    Connect(connections, MinimizeButton.MouseEnter, function()
        Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(39, 49, 64), BackgroundTransparency = 0})
    end)
    
    Connect(connections, MinimizeButton.MouseLeave, function()
        Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(18, 23, 31), BackgroundTransparency = 1})
    end)

    Connect(connections, MaximizeButton.MouseEnter, function()
        Tween(MaximizeButton, {BackgroundColor3 = Color3.fromRGB(39, 49, 64), BackgroundTransparency = 0})
    end)

    Connect(connections, MaximizeButton.MouseLeave, function()
        Tween(MaximizeButton, {BackgroundColor3 = Color3.fromRGB(18, 23, 31), BackgroundTransparency = 1})
    end)
    
    Connect(connections, CloseButton.MouseEnter, function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(190, 52, 61), BackgroundTransparency = 0})
    end)
    
    Connect(connections, CloseButton.MouseLeave, function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(18, 23, 31), BackgroundTransparency = 1})
    end)

    local function DestroyWindow()
        if destroyed then
            return
        end

        destroyed = true
        DisconnectAll(connections)

        local notificationCleanups = {}
        for _, cleanupNotification in pairs(windowNotifications) do
            table.insert(notificationCleanups, cleanupNotification)
        end
        for _, cleanupNotification in ipairs(notificationCleanups) do
            cleanupNotification()
        end

        if ScreenGui.Parent then
            ScreenGui:Destroy()
        end
        if ActiveWindowCleanup == DestroyWindow then
            ActiveWindowCleanup = nil
        end
    end
    ActiveWindowCleanup = DestroyWindow
    Connect(connections, CloseButton.Activated, DestroyWindow)

    local isMaximized = false
    local restoreSize = MainFrame.Size
    local restorePosition = MainFrame.Position
    Connect(connections, MaximizeButton.Activated, function()
        if isMaximized then
            isMaximized = false
            MaximizeButton.Text = "□"
            Tween(MainFrame, {Size = restoreSize, Position = restorePosition}, 0.22)
        else
            isMaximized = true
            restoreSize = MainFrame.Size
            restorePosition = MainFrame.Position
            MaximizeButton.Text = "❐"
            local currentCamera = workspace.CurrentCamera
            local currentViewport = currentCamera and currentCamera.ViewportSize or ViewportSize
            Tween(MainFrame, {
                Size = UDim2.fromOffset(math.max(1, currentViewport.X - 32), math.max(1, currentViewport.Y - 32)),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, 0.22)
        end
    end)
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -28, 1, -180)
    TabContainer.Position = UDim2.new(0, 14, 0, 88)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = Sidebar
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 16)
    TabPadding.PaddingBottom = UDim.new(0, 10)
    TabPadding.PaddingLeft = UDim.new(0, 0)
    TabPadding.PaddingRight = UDim.new(0, 0)
    TabPadding.Parent = TabContainer

    -- Player profile footer
    local ProfileFooter = Instance.new("Frame")
    ProfileFooter.Name = "ProfileFooter"
    ProfileFooter.Size = UDim2.new(1, -32, 0, 76)
    ProfileFooter.Position = UDim2.new(0, 16, 1, -10)
    ProfileFooter.AnchorPoint = Vector2.new(0, 1)
    ProfileFooter.BackgroundTransparency = 1
    ProfileFooter.ZIndex = 2
    ProfileFooter.Parent = Sidebar

    local ProfileDivider = Instance.new("Frame")
    ProfileDivider.Name = "ProfileDivider"
    ProfileDivider.Size = UDim2.new(1, 0, 0, 1)
    ProfileDivider.Position = UDim2.new(0, 0, 0, 0)
    ProfileDivider.BackgroundColor3 = Color3.fromRGB(66, 76, 91)
    ProfileDivider.BackgroundTransparency = 0.35
    ProfileDivider.BorderSizePixel = 0
    ProfileDivider.ZIndex = 2
    ProfileDivider.Parent = ProfileFooter

    local ProfileAvatar = Instance.new("ImageLabel")
    ProfileAvatar.Name = "ProfileAvatar"
    ProfileAvatar.Size = UDim2.new(0, 44, 0, 44)
    ProfileAvatar.Position = UDim2.new(0, 0, 0, 17)
    ProfileAvatar.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    ProfileAvatar.BackgroundTransparency = 0
    ProfileAvatar.BorderSizePixel = 0
    ProfileAvatar.ScaleType = Enum.ScaleType.Crop
    ProfileAvatar.ZIndex = 2
    ProfileAvatar.Parent = ProfileFooter

    local ProfileAvatarCorner = Instance.new("UICorner")
    ProfileAvatarCorner.CornerRadius = UDim.new(1, 0)
    ProfileAvatarCorner.Parent = ProfileAvatar

    local localPlayer = Players.LocalPlayer
    local username = localPlayer and localPlayer.Name or "Player"

    local ProfileUsername = Instance.new("TextLabel")
    ProfileUsername.Name = "ProfileUsername"
    ProfileUsername.Size = UDim2.new(1, -54, 0, 48)
    ProfileUsername.Position = UDim2.new(0, 54, 0, 15)
    ProfileUsername.BackgroundTransparency = 1
    ProfileUsername.Text = string.sub(username, 1, 2) .. string.rep("•", 6)
    ProfileUsername.TextColor3 = Color3.fromRGB(235, 235, 240)
    ProfileUsername.TextSize = 16
    ProfileUsername.Font = Enum.Font.GothamMedium
    ProfileUsername.TextXAlignment = Enum.TextXAlignment.Left
    ProfileUsername.TextYAlignment = Enum.TextYAlignment.Center
    ProfileUsername.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileUsername.ZIndex = 2
    ProfileUsername.Parent = ProfileFooter

    if localPlayer then
        task.spawn(function()
            local success, thumbnail = pcall(function()
                return Players:GetUserThumbnailAsync(
                    localPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)

            if success and ProfileAvatar.Parent then
                ProfileAvatar.Image = thumbnail
            end
        end)
    end
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -sidebarWidth - 58, 1, -86)
    ContentContainer.Position = UDim2.new(0, sidebarWidth + 28, 0, 78)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 25, 33)
    ContentContainer.BackgroundTransparency = 0.04
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = MainFrame

    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 16)
    ContentCorner.Parent = ContentContainer

    local ContentStroke = Instance.new("UIStroke")
    ContentStroke.Color = Color3.fromRGB(53, 62, 75)
    ContentStroke.Thickness = 1
    ContentStroke.Transparency = 0.58
    ContentStroke.Parent = ContentContainer
    
    -- Minimize Overlay
    local MinimizeOverlay = Instance.new("ImageButton")
    MinimizeOverlay.Name = "MinimizeOverlay"
    MinimizeOverlay.Size = UDim2.new(0, 40, 0, 40)
    MinimizeOverlay.Position = UDim2.new(0, 20, 0, 180) -- Top-left corner
    MinimizeOverlay.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MinimizeOverlay.BackgroundTransparency = 0.2
    MinimizeOverlay.BorderSizePixel = 0
    MinimizeOverlay.Image = "rbxassetid://76457278649459" -- Ganti dengan ID gambar Anda
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
    MakeDraggable(MinimizeOverlay, MinimizeOverlay, connections)
    
    -- Make Draggable
    MakeDraggable(MainFrame, TopBar, connections)
    
    -- Minimize/Restore functionality
    local isMinimized = false
    
    Connect(connections, MinimizeButton.Activated, function()
        isMinimized = true
        MainFrame.Visible = false
        MinimizeOverlay.Visible = true
        MinimizeOverlay.Size = UDim2.new(0, 0, 0, 0)
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 40, 0, 40)}, 0.3)
    end)
    
    Connect(connections, MinimizeOverlay.Activated, function()
        if isMinimized then
            isMinimized = false
            Tween(MinimizeOverlay, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
            task.wait(0.2)
            MinimizeOverlay.Visible = false
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            Tween(MainFrame, {Size = windowSize}, 0.3)
        end
    end)
    
    Connect(connections, MinimizeOverlay.MouseEnter, function()
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 45, 0, 45)}, 0.2)
        Tween(OverlayStroke, {Transparency = 0}, 0.2)
    end)
    
    Connect(connections, MinimizeOverlay.MouseLeave, function()
        Tween(MinimizeOverlay, {Size = UDim2.new(0, 40, 0, 40)}, 0.2)
        Tween(OverlayStroke, {Transparency = 0.5}, 0.2)
    end)
    
    -- Window Object
    local Window = {
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        ProfileFooter = ProfileFooter,
        ProfileAvatar = ProfileAvatar,
        ProfileUsername = ProfileUsername,
        GuiParent = guiParent,
        Tabs = {},
        CurrentTab = nil
    }

    function Window:Destroy()
        DestroyWindow()
    end
    
    -- Notification Method
    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local text = config.Text or "No message provided"
        local duration = config.Duration or 3
        local notifType = config.Type or "info" -- info, success, warning, error
        
        return CreateNotification(title, text, duration, notifType, windowNotifications, guiParent)
    end
    
    function Window:CreateTab(tabName, tabConfig)
        if type(tabName) ~= "string" or tabName == "" then
            error("Tab name must be a non-empty string", 2)
        end
        if Window.Tabs[tabName] then
            error("A tab named '" .. tabName .. "' already exists", 2)
        end

        local icon = type(tabConfig) == "table" and tabConfig.Icon or nil
        if type(tabConfig) == "string" then
            icon = tabConfig
        end
        if icon == nil then
            local normalizedName = string.lower(tabName)
            if normalizedName == "home" or normalizedName == "beranda" or normalizedName == "main" then
                icon = "⌂"
            elseif normalizedName == "friends" or normalizedName == "friend" or normalizedName == "teman" then
                icon = "♟"
            elseif normalizedName == "settings" or normalizedName == "setting" or normalizedName == "pengaturan" then
                icon = "⚙"
            else
                icon = "◆"
            end
        end

        local Tab = {}
        
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, 0, 0, 48)
        TabButton.BackgroundColor3 = Color3.fromRGB(18, 52, 92)
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.TextColor3 = Color3.fromRGB(239, 245, 255)
        TabButton.TextSize = 15
        TabButton.Font = Enum.Font.Gotham
        TabButton.Parent = TabContainer
        
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 12)
        TabButtonCorner.Parent = TabButton

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "ActiveIndicator"
        TabIndicator.Size = UDim2.new(0, 4, 1, -12)
        TabIndicator.Position = UDim2.new(0, 0, 0, 6)
        TabIndicator.BackgroundColor3 = Color3.fromRGB(24, 177, 255)
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Visible = false
        TabIndicator.Parent = TabButton

        local TabIndicatorCorner = Instance.new("UICorner")
        TabIndicatorCorner.CornerRadius = UDim.new(1, 0)
        TabIndicatorCorner.Parent = TabIndicator

        local isImageIcon = type(icon) == "string" and string.sub(icon, 1, 13) == "rbxassetid://"
        local TabIcon = Instance.new(isImageIcon and "ImageLabel" or "TextLabel")
        TabIcon.Name = "TabIcon"
        TabIcon.Size = UDim2.new(0, 34, 0, 36)
        TabIcon.Position = UDim2.new(0, 18, 0.5, -18)
        TabIcon.BackgroundTransparency = 1
        if isImageIcon then
            TabIcon.Image = icon
            TabIcon.ImageColor3 = Color3.fromRGB(155, 167, 184)
            TabIcon.ScaleType = Enum.ScaleType.Fit
        else
            TabIcon.Text = tostring(icon)
            TabIcon.TextColor3 = Color3.fromRGB(155, 167, 184)
            TabIcon.TextSize = 27
            TabIcon.Font = Enum.Font.GothamBold
        end
        TabIcon.Parent = TabButton

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TabLabel"
        TabLabel.Size = UDim2.new(1, -66, 1, 0)
        TabLabel.Position = UDim2.new(0, 60, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = tabName
        TabLabel.TextColor3 = Color3.fromRGB(181, 192, 208)
        TabLabel.TextSize = 15
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.TextTruncate = Enum.TextTruncate.AtEnd
        TabLabel.Parent = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "Content"
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
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
        ContentPadding.PaddingTop = UDim.new(0, 10)
        ContentPadding.PaddingBottom = UDim.new(0, 10)
        ContentPadding.PaddingLeft = UDim.new(0, 10)
        ContentPadding.PaddingRight = UDim.new(0, 12)
        ContentPadding.Parent = TabContent
        
        -- Auto-resize canvas
        Connect(connections, ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.Indicator = TabIndicator
        Tab.Icon = TabIcon
        Tab.Label = TabLabel
        Tab.Elements = {}

        Connect(connections, TabButton.Activated, function()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Color3.fromRGB(18, 52, 92)
                tab.Button.BackgroundTransparency = 1
                tab.Indicator.Visible = false
                if tab.Icon:IsA("ImageLabel") then
                    tab.Icon.ImageColor3 = Color3.fromRGB(155, 167, 184)
                else
                    tab.Icon.TextColor3 = Color3.fromRGB(155, 167, 184)
                end
                tab.Label.TextColor3 = Color3.fromRGB(181, 192, 208)
                tab.Content.Visible = false
            end
            
            TabButton.BackgroundColor3 = Color3.fromRGB(18, 52, 92)
            TabButton.BackgroundTransparency = 0.12
            TabIndicator.Visible = true
            if TabIcon:IsA("ImageLabel") then
                TabIcon.ImageColor3 = Color3.fromRGB(35, 195, 255)
            else
                TabIcon.TextColor3 = Color3.fromRGB(35, 195, 255)
            end
            TabLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end)
        
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
            
            Connect(connections, Button.MouseEnter, function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(60, 120, 220), BackgroundTransparency = 0.2})
            end)
            
            Connect(connections, Button.MouseLeave, function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0.3})
            end)
            
            Connect(connections, Button.Activated, callback)
            
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
            
            Connect(connections, ToggleButton.Activated, function()
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
            local min = tonumber(config.Min) or 0
            local max = tonumber(config.Max) or 100
            local step = tonumber(config.Step) or 1
            if max <= min then
                error("Slider Max must be greater than Min", 2)
            end
            if step <= 0 then
                error("Slider Step must be greater than 0", 2)
            end

            local function SnapValue(value)
                local steppedValue = min + math.floor(((value - min) / step) + 0.5) * step
                return math.clamp(steppedValue, min, max)
            end

            local function FormatValue(value)
                local stepDecimals = tostring(step):match("%.(%d+)")
                if stepDecimals then
                    return string.format("%." .. math.min(#stepDecimals, 6) .. "f", value)
                end
                return tostring(value)
            end

            local default = SnapValue(math.clamp(tonumber(config.Default) or min, min, max))
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
            SliderValue.Text = FormatValue(default)
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
            local activeTouch = nil

            local function UpdateSlider(input)
                local barWidth = SliderBar.AbsoluteSize.X
                if barWidth <= 0 then
                    return
                end

                local position = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / barWidth, 0, 1)
                local value = SnapValue(min + (max - min) * position)
                local fillPosition = (value - min) / (max - min)

                SliderFill.Size = UDim2.new(fillPosition, 0, 1, 0)
                SliderValue.Text = FormatValue(value)
                callback(value)
            end
            
            Connect(connections, SliderButton.InputBegan, function(input)
                local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
                local isTouch = input.UserInputType == Enum.UserInputType.Touch
                if isMouse or isTouch then
                    dragging = true
                    activeTouch = isTouch and input or nil
                    UpdateSlider(input)
                end
            end)
            
            Connect(connections, UserInputService.InputChanged, function(input)
                local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
                local isActiveTouch = activeTouch ~= nil and input == activeTouch
                if dragging and (isMouseMove or isActiveTouch) then
                    UpdateSlider(input)
                end
            end)

            Connect(connections, UserInputService.InputEnded, function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 and activeTouch == nil) or input == activeTouch then
                    dragging = false
                    activeTouch = nil
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
            
            Connect(connections, Textbox.FocusLost, function(enterPressed)
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
                
                Connect(connections, OptionButton.MouseEnter, function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(60, 120, 220), BackgroundTransparency = 0.1})
                end)
                
                Connect(connections, OptionButton.MouseLeave, function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40), BackgroundTransparency = 0.2})
                end)
                
                Connect(connections, OptionButton.Activated, function()
                    DropdownButton.Text = dropdownText .. ": " .. option
                    callback(option)
                    
                    isOpen = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, {Rotation = 0})
                end)
            end
            
            Connect(connections, DropdownButton.Activated, function()
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
                
                Connect(connections, OptionButton.MouseEnter, function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.1})
                end)
                
                Connect(connections, OptionButton.MouseLeave, function()
                    Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40), BackgroundTransparency = 0.2})
                end)
                
                Connect(connections, OptionButton.Activated, function()
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
            
            Connect(connections, DropdownButton.Activated, function()
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
        if Window.CurrentTab == nil then
            TabButton.BackgroundColor3 = Color3.fromRGB(18, 52, 92)
            TabButton.BackgroundTransparency = 0.12
            TabIndicator.Visible = true
            if TabIcon:IsA("ImageLabel") then
                TabIcon.ImageColor3 = Color3.fromRGB(35, 195, 255)
            else
                TabIcon.TextColor3 = Color3.fromRGB(35, 195, 255)
            end
            TabLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        return Tab
    end
    
    return Window
end

return Acinonyx
