
--[[
  ACX-UI • Acinonyx-like Library (Full) — v2.3.0
  ✅ Keeps ALL features from previous "final_merged"
  ➕ Fix: ProfileCard anchored at bottom independently (LeftList container for tabs)
  Features:
    • Acrylic (transparent + blur) with options
    • Window centered on screen
    • Notifications stacked bottom-right
    • Minimize system + draggable overlay (left-center)
    • Profile Card docked at bottom of tab list (not affected by UIListLayout)
    • Thin shadow outline (50%) + thin border stroke
    • Tabs, Sections, Elements: Label, Paragraph, Button, Toggle, Slider, Dropdown, MultiDropdown, Textbox, Keybind
    • Lightweight Config Save/Load + Theme patch + ApplyTheme()
]]

local Acinonyx = {}
Acinonyx._version = "2.3.0"
Acinonyx._instances, Acinonyx._signals, Acinonyx._windows = {}, {}, {}

-- ===== Theme =====
Acinonyx._theme = {
    Font = Enum.Font.Gotham,
    TitleSize = 18,
    TextSize  = 14,
    Round     = 10,
    Padding   = 8,
    -- Palette
    Navy     = Color3.fromRGB(12, 36, 78),
    NavySoft = Color3.fromRGB(18, 48, 96),
    Bg       = Color3.fromRGB(16, 17, 20),
    Bg2      = Color3.fromRGB(22, 24, 28),
    Accent   = Color3.fromRGB(12, 36, 78),
    Accent2  = Color3.fromRGB(18, 48, 96),
    Text     = Color3.fromRGB(235, 239, 245),
    Subtext  = Color3.fromRGB(180, 187, 196),
    Stroke   = Color3.fromRGB(12, 36, 78),
    Hover    = Color3.fromRGB(30, 34, 40),
    ShadowImageId = "rbxassetid://5028857472",
}

-- ===== Services =====
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local Lighting        = game:GetService("Lighting")
local LocalPlayer     = Players.LocalPlayer

-- ===== Utils =====
local function tween(o, t, p)
    local tw = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
    tw:Play(); return tw
end

local function roundify(inst, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or Acinonyx._theme.Round)
    u.Parent = inst
    return u
end

local function stroke(inst, c)
    local s = Instance.new("UIStroke")
    s.Color = c or Acinonyx._theme.Stroke
    s.Thickness = 0.5  -- thinner border
    s.Transparency = 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function padding(inst, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, p)
    pad.PaddingBottom = UDim.new(0, p)
    pad.PaddingLeft   = UDim.new(0, p)
    pad.PaddingRight  = UDim.new(0, p)
    pad.Parent = inst
    return pad
end

local function createText(parent, text, size, bold, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Font = Acinonyx._theme.Font
    t.Text = text or ""
    t.TextSize = size or Acinonyx._theme.TextSize
    t.TextColor3 = color or Acinonyx._theme.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.RichText = true
    if bold then
        t.FontFace = Font.new(t.FontFace.Family, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    end
    t.Parent = parent
    return t
end

local function makeDraggable(handle, target)
    target = target or handle
    local dragging, dragStart, startPos = false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function buttonHover(btnLikeFrame)
    btnLikeFrame.MouseEnter:Connect(function() tween(btnLikeFrame, 0.08, {BackgroundColor3 = Acinonyx._theme.Hover}) end)
    btnLikeFrame.MouseLeave:Connect(function() tween(btnLikeFrame, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg2}) end)
end

local function dropShadow(parent, radius)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "_Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = Acinonyx._theme.ShadowImageId
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10,10,118,118)
    shadow.ImageColor3 = Acinonyx._theme.Navy
    shadow.ImageTransparency = 0.75 -- thinner look
    shadow.Size = UDim2.new(1, 12, 1, 12)     -- half of 24
    shadow.Position = UDim2.new(0, -6, 0, -6) -- half of -12
    shadow.ZIndex = 0
    shadow.Parent = parent
    if radius then
        local u = Instance.new("UICorner"); u.CornerRadius = UDim.new(0, radius); u.Parent = shadow
    end
    return shadow
end

-- ===== Screen =====
local Screen = Instance.new("ScreenGui")
Screen.Name = "ACX_UI"
Screen.IgnoreGuiInset = true
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
Screen.Parent = (RunService:IsStudio() and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or LocalPlayer.PlayerGui

-- ===== Acrylic helpers =====
local function getOrCreateBlur()
    local b = Lighting:FindFirstChild("ACX_UI_Blur")
    if not b then
        b = Instance.new("BlurEffect")
        b.Name = "ACX_UI_Blur"
        b.Enabled = false
        b.Size = 0
        b.Parent = Lighting
    end
    return b
end

function Acinonyx:_updateAcrylic()
    local anyVisible = false
    for _,w in ipairs(self._windows or {}) do
        if w._root and w._root.Parent and w._root.Visible then
            anyVisible = true; break
        end
    end
    getOrCreateBlur().Enabled = anyVisible
end

-- ===== Notifications (bottom-right) =====
local NotifyLayer = Instance.new("Frame")
NotifyLayer.BackgroundTransparency = 1
NotifyLayer.Size = UDim2.new(1, -20, 1, -20)
NotifyLayer.AnchorPoint = Vector2.new(1, 1)
NotifyLayer.Position = UDim2.new(1, -10, 1, -10)
NotifyLayer.Parent = Screen

local NotifyList = Instance.new("UIListLayout")
NotifyList.Parent = NotifyLayer
NotifyList.SortOrder = Enum.SortOrder.LayoutOrder
NotifyList.Padding = UDim.new(0, 6)
NotifyList.FillDirection = Enum.FillDirection.Vertical
NotifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom

function Acinonyx:MakeNotification(opts)
    opts = opts or {}
    local title = tostring(opts.Name or "Notification")
    local content = tostring(opts.Content or "")
    local time = tonumber(opts.Time or 3)

    local card = Instance.new("Frame")
    card.BackgroundColor3 = Acinonyx._theme.Bg2
    card.Size = UDim2.new(0, 320, 0, 70)
    card.AutomaticSize = Enum.AutomaticSize.Y
    roundify(card); stroke(card); padding(card, Acinonyx._theme.Padding)
    card.Parent = NotifyLayer

    local Title = createText(card, title, Acinonyx._theme.TitleSize, true)
    Title.Size = UDim2.new(1, 0, 0, 22)

    local Body = createText(card, content, Acinonyx._theme.TextSize, false, Acinonyx._theme.Subtext)
    Body.Position = UDim2.new(0, 0, 0, 24)
    Body.Size = UDim2.new(1, 0, 0, 20)
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y

    card.BackgroundTransparency = 1
    tween(card, 0.15, {BackgroundTransparency = 0})

    task.delay(time, function()
        if card and card.Parent then
            tween(card, 0.15, {BackgroundTransparency = 1})
            task.wait(0.18)
            card:Destroy()
        end
    end)
end

-- ===== Config =====
Acinonyx.Config = { _data = {}, Folder = "", File = "" }

local function fileops()
    return (typeof(writefile) == "function") and (typeof(readfile) == "function") and (typeof(isfile) == "function")
end

function Acinonyx:BindConfig(opts)
    opts = opts or {}
    self.Config.Folder = tostring(opts.Folder or "ACX_UI")
    self.Config.File   = tostring(opts.File or "config.json")
    self:MakeNotification({Name="Config", Content = "Bound to "..self.Config.Folder.."/"..self.Config.File, Time=2})
end

function Acinonyx.Config:Set(k,v) Acinonyx.Config._data[k] = v end
function Acinonyx.Config:Get(k,def) local v = Acinonyx.Config._data[k]; if v==nil then return def end; return v end

function Acinonyx:SaveConfig()
    if not fileops() then self:MakeNotification({Name="Save", Content="writefile/readfile not available.", Time=2}); return false end
    local folder = self.Config.Folder; local file = self.Config.File
    pcall(function() if not isfolder(folder) then makefolder(folder) end end)
    local json = HttpService:JSONEncode(self.Config._data)
    writefile(string.format("%s/%s", folder, file), json)
    self:MakeNotification({Name="Save", Content="Config saved.", Time=2})
    return true
end

function Acinonyx:LoadConfig()
    if not fileops() then self:MakeNotification({Name="Load", Content="readfile not available.", Time=2}); return false end
    local path = string.format("%s/%s", self.Config.Folder, self.Config.File)
    if not isfile(path) then self:MakeNotification({Name="Load", Content="No config found.", Time=2}); return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and typeof(data)=="table" then
        self.Config._data = data
        self:MakeNotification({Name="Load", Content="Config loaded.", Time=2})
        return true
    else
        self:MakeNotification({Name="Load", Content="Failed to decode config.", Time=2})
        return false
    end
end

-- ===== Theme API =====
function Acinonyx:SetTheme(patch)
    for k,v in pairs(patch or {}) do
        if self._theme[k] ~= nil then self._theme[k] = v end
    end
end

-- ===== Window / Tab / Section Metatables =====
local WindowMT, TabMT, SectionMT = {}, {}, {}
WindowMT.__index = WindowMT; TabMT.__index = TabMT; SectionMT.__index = SectionMT

local function makeItemBase(parent, height)
    local Item = Instance.new("Frame")
    Item.BackgroundColor3 = Acinonyx._theme.Bg2
    Item.Size = UDim2.new(1, 0, 0, height or 40)
    roundify(Item); stroke(Item); padding(Item, Acinonyx._theme.Padding)
    Item.Parent = parent
    return Item
end

-- ===== MakeWindow =====
function Acinonyx:MakeWindow(opts)
    opts = opts or {}
    local windowTitle   = tostring(opts.Name or "ACX-UI Window")
    local introText     = opts.IntroText
    local minimizeKey   = opts.MinimizeKeybind or Enum.KeyCode.RightControl
    local acrylicOn     = (opts.Acrylic ~= false)
    local acrylicAlpha  = tonumber(opts.AcrylicTransparency or 0.25) -- 0..1
    local acrylicBlurSz = tonumber(opts.AcrylicBlur or 12)
    local centerOnScreen= (opts.Center ~= false)       -- default true
    local showProfile   = (opts.ShowProfileCard ~= false) -- default true
    local profilePos    = tostring(opts.ProfileCardPosition or "bottom") -- "bottom"|"center"|"top"

    if introText then
        Acinonyx:MakeNotification({ Name = windowTitle, Content = introText, Time = 2.5 })
    end

    -- Root
    local Root = Instance.new("Frame")
    Root.BackgroundColor3 = Acinonyx._theme.Bg
    Root.Size = UDim2.new(0, 600, 0, 400)
    if centerOnScreen then
        Root.AnchorPoint = Vector2.new(0.5, 0.5)
        Root.Position    = UDim2.new(0.5, 0, 0.5, 0)
    else
        Root.Position    = UDim2.new(0, 60, 0, 60)
    end
    Root.Active = true
    Root.Parent = Screen
    roundify(Root); stroke(Root); dropShadow(Root, Acinonyx._theme.Round)

    local Header = Instance.new("Frame")
    Header.BackgroundColor3 = Acinonyx._theme.Bg2
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.Parent = Root
    roundify(Header)

    local Title = createText(Header, windowTitle, Acinonyx._theme.TitleSize, true)
    Title.Size = UDim2.new(1, -140, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)

    local BtnClose = Instance.new("TextButton")
    BtnClose.Text = "✕"; BtnClose.Font = Acinonyx._theme.Font; BtnClose.TextColor3 = Acinonyx._theme.Subtext; BtnClose.TextSize = 16
    BtnClose.Size = UDim2.new(0, 36, 0, 28)
    BtnClose.Position = UDim2.new(1, -44, 0, 6)
    BtnClose.BackgroundColor3 = Acinonyx._theme.Bg2
    BtnClose.Parent = Header
    roundify(BtnClose); stroke(BtnClose); buttonHover(BtnClose)

    local BtnMin = Instance.new("TextButton")
    BtnMin.Text = "—"; BtnMin.Font = Acinonyx._theme.Font; BtnMin.TextColor3 = Acinonyx._theme.Subtext; BtnMin.TextSize = 16
    BtnMin.Size = UDim2.new(0, 36, 0, 28)
    BtnMin.Position = UDim2.new(1, -84, 0, 6)
    BtnMin.BackgroundColor3 = Acinonyx._theme.Bg2
    BtnMin.Parent = Header
    roundify(BtnMin); stroke(BtnMin); buttonHover(BtnMin)

    makeDraggable(Header, Root)

    local Body = Instance.new("Frame")
    Body.BackgroundTransparency = 1
    Body.Size = UDim2.new(1, -16, 1, -56)
    Body.Position = UDim2.new(0, 8, 0, 48)
    Body.Parent = Root

    local LeftPane = Instance.new("Frame")
    LeftPane.BackgroundColor3 = Acinonyx._theme.Bg2
    LeftPane.Size = UDim2.new(0, 170, 1, 0)
    LeftPane.Parent = Body
    roundify(LeftPane); stroke(LeftPane); padding(LeftPane, 8)

    -- NEW: dedicated container for tab buttons so ProfileCard is independent
    local LeftList = Instance.new("Frame")
    LeftList.Name = "LeftList"
    LeftList.BackgroundTransparency = 1
    LeftList.Size = UDim2.new(1, 0, 1, -88) -- 72 profile + ~16 margin
    LeftList.Position = UDim2.new(0, 0, 0, 0)
    LeftList.Parent = LeftPane

    local TabList = Instance.new("UIListLayout")
    TabList.Parent = LeftList
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 6)

    local RightPane = Instance.new("Frame")
    RightPane.BackgroundColor3 = Acinonyx._theme.Bg2
    RightPane.Size = UDim2.new(1, -180, 1, 0)
    RightPane.Position = UDim2.new(0, 180, 0, 0)
    RightPane.Parent = Body
    roundify(RightPane); stroke(RightPane); padding(RightPane, 10)

    -- Acrylic
    if acrylicOn then
        Root.BackgroundTransparency     = acrylicAlpha
        Header.BackgroundTransparency   = acrylicAlpha
        LeftPane.BackgroundTransparency = acrylicAlpha
        RightPane.BackgroundTransparency= acrylicAlpha
        local blur = getOrCreateBlur()
        blur.Size = acrylicBlurSz
        blur.Enabled = true
        Acinonyx:_updateAcrylic()
    end

    local Pages = Instance.new("Folder")
    Pages.Name = "Pages"; Pages.Parent = RightPane

    -- Overlay (left-center)
    local Overlay = Instance.new("Frame")
    Overlay.Visible = false
    Overlay.BackgroundColor3 = Acinonyx._theme.Bg2
    Overlay.Size = UDim2.new(0, 220, 0, 44)
    Overlay.AnchorPoint = Vector2.new(0, 0.5)
    Overlay.Position = UDim2.new(0, 20, 0.5, 0)
    Overlay.Parent = Screen
    roundify(Overlay); stroke(Overlay); padding(Overlay, 8); dropShadow(Overlay, Acinonyx._theme.Round)

    local OvTitle = createText(Overlay, windowTitle, Acinonyx._theme.TextSize, true); OvTitle.Size = UDim2.new(1, -90, 1, 0)
    local BtnRestore = Instance.new("TextButton")
    BtnRestore.Text = "Restore"
    BtnRestore.Font = Acinonyx._theme.Font
    BtnRestore.TextColor3 = Acinonyx._theme.Text
    BtnRestore.TextSize = Acinonyx._theme.TextSize
    BtnRestore.Size = UDim2.new(0, 80, 0, 28); BtnRestore.Position = UDim2.new(1, -84, 0.5, -14)
    BtnRestore.BackgroundColor3 = Acinonyx._theme.Bg; BtnRestore.Parent = Overlay
    roundify(BtnRestore); stroke(BtnRestore); buttonHover(BtnRestore)

    makeDraggable(Overlay, Overlay)

    local minimized = false
    local function setMinimized(state) minimized = state; Root.Visible = not state; Overlay.Visible = state; Acinonyx:_updateAcrylic() end
    BtnClose.MouseButton1Click:Connect(function() Root:Destroy(); Overlay:Destroy(); Acinonyx:_updateAcrylic() end)
    BtnMin.MouseButton1Click:Connect(function() setMinimized(true) end)
    BtnRestore.MouseButton1Click:Connect(function() setMinimized(false) end)
    UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==minimizeKey then setMinimized(not minimized) end end)

    -- Profile Card (bottom of LeftPane, independent of LeftList)
    local profileApi = nil
    if showProfile then
        local Card = Instance.new("Frame")
        Card.Name = "ProfileCard"
        Card.BackgroundColor3 = Acinonyx._theme.Bg
        Card.Size = UDim2.new(1, -16, 0, 72)
        Card.Parent = LeftPane
        roundify(Card, 12); stroke(Card)

        if profilePos == "top" then
            Card.AnchorPoint = Vector2.new(0,0)
            Card.Position = UDim2.new(0,8,0,8)
        elseif profilePos == "center" then
            Card.AnchorPoint = Vector2.new(0,0.5)
            Card.Position = UDim2.new(0,8,0.5,0)
        else -- bottom
            Card.AnchorPoint = Vector2.new(0,1)
            Card.Position = UDim2.new(0,8,1,-8)
        end

        local Avatar = Instance.new("ImageLabel")
        Avatar.BackgroundTransparency = 1
        Avatar.Size = UDim2.new(0, 44, 0, 44)
        Avatar.Position = UDim2.new(0, 10, 0, 14)
        Avatar.Parent = Card
        roundify(Avatar, 999)
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok then Avatar.Image = content end

        local Name = createText(Card, LocalPlayer.DisplayName or LocalPlayer.Name, 15, true)
        Name.Position = UDim2.new(0, 60, 0, 14); Name.Size = UDim2.new(1, -70, 0, 18)

        local Sub = createText(Card, "@"..LocalPlayer.Name, 13, false, Acinonyx._theme.Subtext)
        Sub.Position = UDim2.new(0, 60, 0, 34); Sub.Size = UDim2.new(1, -70, 0, 16)

        profileApi = {
            SetName   = function(_, t) Name.Text    = tostring(t) end,
            SetSub    = function(_, t) Sub.Text     = tostring(t) end,
            SetAvatar = function(_, id) Avatar.Image= tostring(id) end,
        }
    end

    local api = setmetatable({
        _root = Root, _tabs = {}, _pages = Pages, _left = LeftPane, _leftList = LeftList,
        _overlay = Overlay, _ovTitle = OvTitle, _minKey = minimizeKey, _profile = profileApi,
        SetMinimized = function(self2, v) setMinimized(not not v) end,
        SetMinimizeKeybind = function(self2, key) self2._minKey = key end,
        ApplyTheme = function(self2)
            Root.BackgroundColor3    = Acinonyx._theme.Bg
            Header.BackgroundColor3  = Acinonyx._theme.Bg2
            LeftPane.BackgroundColor3= Acinonyx._theme.Bg2
            RightPane.BackgroundColor3= Acinonyx._theme.Bg2
            Overlay.BackgroundColor3 = Acinonyx._theme.Bg2
        end,
        SetOverlayTitle = function(self2, txt) OvTitle.Text = tostring(txt) end,
        Profile = function(self2) return self2._profile end,
    }, WindowMT)

    table.insert(self._windows, api)
    return api
end

-- ===== Tabs / Sections =====
function WindowMT:MakeTab(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Tab")

    local TabButton = Instance.new("TextButton")
    TabButton.BackgroundColor3 = Acinonyx._theme.Bg2
    TabButton.Size = UDim2.new(1, 0, 0, 34)
    TabButton.Text = name
    TabButton.TextColor3 = Acinonyx._theme.Text
    TabButton.TextSize = Acinonyx._theme.TextSize
    TabButton.Font = Acinonyx._theme.Font
    TabButton.Parent = self._leftList -- <-- in LeftList, not LeftPane
    roundify(TabButton); stroke(TabButton); buttonHover(TabButton)

    local Page = Instance.new("ScrollingFrame")
    Page.Active = true
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new()
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 6
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.Visible = false
    Page.Parent = self._pages

    local PageList = Instance.new("UIListLayout")
    PageList.Parent = Page
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Padding = UDim.new(0, 10)

    local function show()
        for _, child in ipairs(self._pages:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        Page.Visible = true
        tween(TabButton, 0.08, {BackgroundColor3 = Acinonyx._theme.Hover})
    end
    TabButton.MouseButton1Click:Connect(show)
    if #self._pages:GetChildren() == 1 then show() end

    local api = setmetatable({ _page = Page }, TabMT)
    table.insert(self._tabs, api)
    return api
end

function TabMT:AddSection(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Section")

    local Section = Instance.new("Frame")
    Section.BackgroundColor3 = Acinonyx._theme.Bg
    Section.Size = UDim2.new(1, -6, 0, 48)
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.Parent = self._page
    roundify(Section); stroke(Section); padding(Section, 10)

    local Title = createText(Section, name, 15, true, Acinonyx._theme.Subtext)
    Title.Size = UDim2.new(1, 0, 0, 18)

    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Position = UDim2.new(0, 0, 0, 24)
    Holder.Size = UDim2.new(1, 0, 0, 10)
    Holder.AutomaticSize = Enum.AutomaticSize.Y
    Holder.Parent = Section

    local List = Instance.new("UIListLayout")
    List.Parent = Holder
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)

    local Sep = Instance.new("Frame")
    Sep.BackgroundColor3 = Acinonyx._theme.Stroke
    Sep.BorderSizePixel = 0
    Sep.Size = UDim2.new(1, 0, 0, 1)
    Sep.Position = UDim2.new(0, 0, 0, 22)
    Sep.Parent = Section

    local api = setmetatable({ _holder = Holder }, SectionMT)
    return api
end

-- ===== Elements =====
function SectionMT:AddLabel(opts)
    opts = opts or {}
    local text = tostring(opts.Text or "Label")
    local Item = makeItemBase(self._holder, 34)
    local L = createText(Item, text, Acinonyx._theme.TextSize)
    L.Size = UDim2.new(1, 0, 1, 0)
    return { Set = function(_, t) L.Text = tostring(t) end }
end

function SectionMT:AddParagraph(opts)
    opts = opts or {}
    local title = tostring(opts.Title or "Paragraph")
    local content = tostring(opts.Content or "")
    local Item = makeItemBase(self._holder, 64)
    Item.AutomaticSize = Enum.AutomaticSize.Y

    local T = createText(Item, title, Acinonyx._theme.TextSize, true)
    T.Size = UDim2.new(1, 0, 0, 18)

    local C = createText(Item, content, Acinonyx._theme.TextSize, false, Acinonyx._theme.Subtext)
    C.Position = UDim2.new(0, 0, 0, 20)
    C.Size = UDim2.new(1, 0, 0, 20)
    C.TextWrapped = true
    C.AutomaticSize = Enum.AutomaticSize.Y

    return { Set = function(_, newTitle, newContent)
        if newTitle then T.Text = tostring(newTitle) end
        if newContent then C.Text = tostring(newContent) end
    end }
end

function SectionMT:AddButton(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Button")
    local cb = opts.Callback or function() end

    local Item = makeItemBase(self._holder, 36)
    local B = Instance.new("TextButton")
    B.BackgroundTransparency = 1
    B.Font = Acinonyx._theme.Font
    B.Text = name
    B.TextColor3 = Acinonyx._theme.Text
    B.TextSize = Acinonyx._theme.TextSize
    B.Size = UDim2.new(1, 0, 1, 0)
    B.Parent = Item

    B.MouseEnter:Connect(function() tween(Item, 0.08, {BackgroundColor3 = Acinonyx._theme.Hover}) end)
    B.MouseLeave:Connect(function() tween(Item, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg2}) end)
    B.MouseButton1Click:Connect(function() task.spawn(cb) end)

    return { Set = function(_, label) B.Text = tostring(label) end, Fire = function() task.spawn(cb) end }
end

function SectionMT:AddToggle(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Toggle")
    local default = not not opts.Default
    local cb = opts.Callback or function(_) end

    local Item = makeItemBase(self._holder, 36)
    local L = createText(Item, name)
    L.Size = UDim2.new(1, -60, 1, 0)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 42, 0, 22)
    Btn.Position = UDim2.new(1, -48, 0.5, -11)
    Btn.BackgroundColor3 = Acinonyx._theme.Bg
    Btn.Text = ""
    Btn.Parent = Item
    roundify(Btn, 999); stroke(Btn)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 18, 0, 18)
    Dot.Position = UDim2.new(0, 2, 0.5, -9)
    Dot.BackgroundColor3 = Acinonyx._theme.Stroke
    Dot.Parent = Btn
    roundify(Dot, 999)

    local state = default
    local function setState(on, silent)
        state = on
        if on then
            tween(Btn, 0.08, {BackgroundColor3 = Acinonyx._theme.Accent})
            tween(Dot, 0.08, {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Color3.new(1,1,1)})
        else
            tween(Btn, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg})
            tween(Dot, 0.08, {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Acinonyx._theme.Stroke})
        end
        if not silent then task.spawn(cb, on) end
    end
    setState(state, true)

    Btn.MouseButton1Click:Connect(function() setState(not state) end)

    return {
        Set = function(_, v) setState(not not v) end,
        Get = function() return state end,
        Toggle = function() setState(not state) end
    }
end

function SectionMT:AddSlider(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Slider")
    local min = tonumber(opts.Min or 0)
    local max = tonumber(opts.Max or 100)
    local def = math.clamp(tonumber(opts.Default or min), min, max)
    local inc = tonumber(opts.Increment or 1)
    local cb = opts.Callback or function(_) end

    local Item = makeItemBase(self._holder, 52)
    local L = createText(Item, ("%s: %s"):format(name, def))
    L.Size = UDim2.new(1, 0, 0, 18)

    local Bar = Instance.new("Frame")
    Bar.BackgroundColor3 = Acinonyx._theme.Bg
    Bar.Size = UDim2.new(1, -10, 0, 10)
    Bar.Position = UDim2.new(0, 5, 0, 28)
    Bar.Parent = Item
    roundify(Bar, 999); stroke(Bar)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Acinonyx._theme.Accent
    Fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0)
    Fill.Parent = Bar
    roundify(Fill, 999)

    local dragging, value = false, def

    local function setValue(v, silent)
        v = math.clamp(v, min, max)
        if inc > 0 then v = math.round(v / inc) * inc end
        value = v
        L.Text = ("%s: %s"):format(name, v)
        local alpha = (v - min) / (max - min)
        tween(Fill, 0.08, {Size = UDim2.new(alpha, 0, 1, 0)})
        if not silent then task.spawn(cb, v) end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = (input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X
            setValue(min + rel*(max-min))
        end
    end)

    setValue(def, true)
    return { Set = function(_, v) setValue(v) end, Get = function() return value end }
end

function SectionMT:AddDropdown(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Dropdown")
    local list = opts.Options or {}
    local def = opts.Default
    local cb = opts.Callback or function(_) end

    local Item = makeItemBase(self._holder, 40)
    local Label = createText(Item, name)
    Label.Size = UDim2.new(1, -160, 1, 0)

    local Box = Instance.new("TextButton")
    Box.Size = UDim2.new(0, 140, 0, 26)
    Box.Position = UDim2.new(1, -146, 0.5, -13)
    Box.BackgroundColor3 = Acinonyx._theme.Bg
    Box.Text = tostring(def or "Select...")
    Box.Font = Acinonyx._theme.Font
    Box.TextSize = Acinonyx._theme.TextSize
    Box.TextColor3 = Acinonyx._theme.Text
    Box.Parent = Item
    roundify(Box); stroke(Box, Acinonyx._theme.Navy)

    local Menu; local selected = def
    local function choose(v)
        selected = v; Box.Text = tostring(v); task.spawn(cb, v)
        if Menu then Menu.Visible = false end
        return v
    end

    Box.MouseButton1Click:Connect(function()
        if Menu then Menu.Visible = not Menu.Visible; return end
        Menu = Instance.new("Frame")
        Menu.BackgroundColor3 = Acinonyx._theme.Bg
        Menu.Size = UDim2.new(0, Box.AbsoluteSize.X, 0, math.clamp(#list*28, 36, 180))
        Menu.Position = UDim2.new(0, Box.AbsolutePosition.X - Item.AbsolutePosition.X, 0, Box.AbsolutePosition.Y - Item.AbsolutePosition.Y + Box.AbsoluteSize.Y + 4)
        Menu.Parent = Item
        roundify(Menu); stroke(Menu, Acinonyx._theme.Navy); padding(Menu, 4)

        local L = Instance.new("UIListLayout"); L.Parent = Menu; L.SortOrder = Enum.SortOrder.LayoutOrder; L.Padding = UDim.new(0, 4)
        for _, opt in ipairs(list) do
            local row = Instance.new("TextButton")
            row.BackgroundColor3 = Acinonyx._theme.Bg2
            row.Text = tostring(opt)
            row.TextColor3 = Acinonyx._theme.Text
            row.TextSize = Acinonyx._theme.TextSize
            row.Font = Acinonyx._theme.Font
            row.Size = UDim2.new(1, 0, 0, 24)
            row.Parent = Menu
            roundify(row); stroke(row, Acinonyx._theme.Navy)
            row.MouseEnter:Connect(function() tween(row, 0.08, {BackgroundColor3 = Acinonyx._theme.NavySoft}) end)
            row.MouseLeave:Connect(function() if selected ~= opt then tween(row, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg2}) end end)
            row.MouseButton1Click:Connect(function()
                choose(opt)
                for _, r in ipairs(Menu:GetChildren()) do
                    if r:IsA("TextButton") then tween(r, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg2}) end
                end
                tween(row, 0.08, {BackgroundColor3 = Acinonyx._theme.Navy})
            end)
        end
    end)

    if def then choose(def) end

    return {
        Set = function(_, v) choose(v) end,
        Get = function() return selected end,
        Refresh = function(_, newList, newDefault)
            list = newList or list
            if Menu then Menu:Destroy(); Menu = nil end
            if newDefault ~= nil then choose(newDefault) end
        end
    }
end

function SectionMT:AddMultiDropdown(opts)
    opts = opts or {}
    local name  = tostring(opts.Name or "Multi Dropdown")
    local list  = opts.Options or {}
    local defs  = opts.Default or {}
    local cb    = opts.Callback or function(_) end

    local selectedSet = {}
    if typeof(defs) == "table" then
        for _, v in ipairs(defs) do selectedSet[tostring(v)] = true end
    end

    local Item  = makeItemBase(self._holder, 40)
    local Label = createText(Item, name); Label.Size = UDim2.new(1, -200, 1, 0)

    local Box = Instance.new("TextButton")
    Box.Size = UDim2.new(0, 180, 0, 26)
    Box.Position = UDim2.new(1, -186, 0.5, -13)
    Box.BackgroundColor3 = Acinonyx._theme.Bg
    Box.Text = "Select multiple"
    Box.Font = Acinonyx._theme.Font
    Box.TextSize = Acinonyx._theme.TextSize
    Box.TextColor3 = Acinonyx._theme.Text
    Box.Parent = Item
    roundify(Box); stroke(Box, Acinonyx._theme.Navy)

    local function selectedList()
        local t = {}
        for _, opt in ipairs(list) do if selectedSet[tostring(opt)] then table.insert(t, opt) end end
        return t
    end

    local function updateBoxText()
        local t = selectedList()
        if #t == 0 then Box.Text = "Select multiple"
        elseif #t <= 3 then Box.Text = table.concat(t, ", ")
        else Box.Text = tostring(#t).." selected" end
    end

    local Menu
    local function fire() task.spawn(cb, selectedList()) end

    Box.MouseButton1Click:Connect(function()
        if Menu then Menu.Visible = not Menu.Visible; return end
        Menu = Instance.new("Frame")
        Menu.BackgroundColor3 = Acinonyx._theme.Bg
        Menu.Size = UDim2.new(0, Box.AbsoluteSize.X, 0, math.clamp(#list*30, 36, 220))
        Menu.Position = UDim2.new(0, Box.AbsolutePosition.X - Item.AbsolutePosition.X, 0, Box.AbsolutePosition.Y - Item.AbsolutePosition.Y + Box.AbsoluteSize.Y + 4)
        Menu.Parent = Item
        roundify(Menu); stroke(Menu, Acinonyx._theme.Navy); padding(Menu, 4)

        local L = Instance.new("UIListLayout"); L.Parent = Menu; L.SortOrder = Enum.SortOrder.LayoutOrder; L.Padding = UDim.new(0, 4)
        for _, opt in ipairs(list) do
            local key = tostring(opt)
            local row = Instance.new("TextButton")
            row.BackgroundColor3 = selectedSet[key] and Acinonyx._theme.Navy or Acinonyx._theme.Bg2
            row.Text = key
            row.TextColor3 = Acinonyx._theme.Text
            row.TextSize = Acinonyx._theme.TextSize
            row.Font = Acinonyx._theme.Font
            row.Size = UDim2.new(1, 0, 0, 24)
            row.Parent = Menu
            roundify(row); stroke(row, Acinonyx._theme.Navy)
            row.MouseEnter:Connect(function() if not selectedSet[key] then tween(row, 0.08, {BackgroundColor3 = Acinonyx._theme.NavySoft}) end end)
            row.MouseLeave:Connect(function() if not selectedSet[key] then tween(row, 0.08, {BackgroundColor3 = Acinonyx._theme.Bg2}) end end)
            row.MouseButton1Click:Connect(function()
                selectedSet[key] = not selectedSet[key]
                tween(row, 0.08, {BackgroundColor3 = selectedSet[key] and Acinonyx._theme.Navy or Acinonyx._theme.Bg2})
                updateBoxText(); fire()
            end)
        end
    end)

    updateBoxText(); fire()

    return {
        Get = function() return selectedList() end,
        IsSelected = function(_, v) return not not selectedSet[tostring(v)] end,
        SetSelected = function(_, v, on) selectedSet[tostring(v)] = not not on; updateBoxText(); fire() end,
        Clear = function() selectedSet = {}; updateBoxText(); fire() end,
        Refresh = function(_, newList, newDefaults)
            list = newList or list
            selectedSet = {}
            if typeof(newDefaults) == "table" then
                for _, v in ipairs(newDefaults) do selectedSet[tostring(v)] = true end
            end
            if Menu then Menu:Destroy(); Menu = nil end
            updateBoxText(); fire()
        end
    }
end

function SectionMT:AddTextbox(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Textbox")
    local placeholder = tostring(opts.PlaceholderText or "Type here...")
    local default = tostring(opts.Default or "")
    local clearOnFocus = not not opts.ClearTextOnFocus
    local cb = opts.Callback or function(_) end

    local Item = makeItemBase(self._holder, 40)
    local Label = createText(Item, name)
    Label.Size = UDim2.new(1, -200, 1, 0)

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 180, 0, 26)
    Box.Position = UDim2.new(1, -186, 0.5, -13)
    Box.BackgroundColor3 = Acinonyx._theme.Bg
    Box.Text = default
    Box.PlaceholderText = placeholder
    Box.ClearTextOnFocus = clearOnFocus
    Box.Font = Acinonyx._theme.Font
    Box.TextSize = Acinonyx._theme.TextSize
    Box.TextColor3 = Acinonyx._theme.Text
    Box.Parent = Item
    roundify(Box); stroke(Box)

    Box.FocusLost:Connect(function(enter)
        if enter ~= false then task.spawn(cb, Box.Text) end
    end)

    return { Set = function(_, v) Box.Text = tostring(v) end, Get = function() return Box.Text end }
end

function SectionMT:AddKeybind(opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Keybind")
    local def = opts.Default or Enum.KeyCode.RightControl
    local cb = opts.Callback or function(_) end

    local Item = makeItemBase(self._holder, 40)
    local Label = createText(Item, name)
    Label.Size = UDim2.new(1, -180, 1, 0)

    local Box = Instance.new("TextButton")
    Box.Size = UDim2.new(0, 160, 0, 26)
    Box.Position = UDim2.new(1, -166, 0.5, -13)
    Box.BackgroundColor3 = Acinonyx._theme.Bg
    Box.Text = def.Name
    Box.Font = Acinonyx._theme.Font
    Box.TextSize = Acinonyx._theme.TextSize
    Box.TextColor3 = Acinonyx._theme.Text
    Box.Parent = Item
    roundify(Box); stroke(Box)

    local current, listening = def, false
    local function setKey(k) current = k; Box.Text = k.Name; task.spawn(cb, k) end

    Box.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true; Box.Text = "Press key..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect(); listening = false; setKey(input.KeyCode)
            end
        end)
    end)

    return { Set = function(_, k) if typeof(k)=="EnumItem" then setKey(k) end end, Get = function() return current end }
end

function Acinonyx:Destroy() if Screen then Screen:Destroy() end end

return Acinonyx
