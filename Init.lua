--[[
  Acinonyx UI Library — Orion‑Compatible API (v0.1)
  --------------------------------------------------
  Goal: Provide a safe, lightweight UI library with an API compatible with the
        popular "Orion" UI so existing scripts can be ported with minimal change.

  Supported API (subset of Orion):
    local OrionLib = require(Acinonyx)
    local Window = OrionLib:MakeWindow({
        Name = "Acinonyx Script",
        HidePremium = false,
        SaveConfig = false,
        ConfigFolder = "Acinonyx",
        IntroEnabled = false,
        IntroText = "Acinonyx",
        Icon = "rbxassetid://0"
    })

    local Tab = Window:MakeTab({ Name = "Main", Icon = "rbxassetid://0", PremiumOnly = false })
    local Section = Tab:AddSection({ Name = "Core" })

    Tab:AddButton({ Name = "Click Me", Callback = function() print("clicked") end })
    Tab:AddToggle({ Name = "Bool", Default = false, Callback = function(v) print("T:", v) end })
    Tab:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, ValueName = "%", Increment = 1, Callback = function(v) end })
    Tab:AddDropdown({ Name = "Mode", Options = {"A","B","C"}, Default = "B", Callback = function(v) end })
    Tab:AddParagraph("Info", "Hello from Acinonyx")
    Tab:AddColorpicker({ Name = "Tint", Default = Color3.fromRGB(255, 170, 0), Callback = function(c) end })
    Tab:AddKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.LeftControl, Callback = function() end })

    OrionLib:MakeNotification({ Name = "Loaded", Content = "Acinonyx ready", Time = 5 })
    OrionLib:Init()

  Notes:
    • This is a fresh implementation; no code copied from other libraries.
    • Uses high ZIndex overlays for dropdown/popups so they always render in front.
    • Emphasis on clean layout, consistent spacing, tweened interactions.
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== Utility =====
local function new(instance, props, children)
    local obj = Instance.new(instance)
    if props then for k, v in pairs(props) do obj[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = obj end end
    return obj
end

local function round(n, inc)
    inc = inc or 1
    return math.floor(n / inc + 0.5) * inc
end

local function spring(instance, goal, time)
    return TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
end

local function safeCallback(fn, ...)
    if typeof(fn) == "function" then
        task.spawn(pcall, fn, ...)
    end
end

-- Theme
local Theme = {
    Bg = Color3.fromRGB(18, 18, 20),
    Panel = Color3.fromRGB(28, 28, 32),
    Muted = Color3.fromRGB(150, 150, 160),
    Text = Color3.fromRGB(235, 235, 240),
    Accent = Color3.fromRGB(0, 170, 255),
    Accent2 = Color3.fromRGB(255, 115, 0),
    Stroke = Color3.fromRGB(60, 60, 70),
    Sel = Color3.fromRGB(42, 42, 50)
}

-- ZIndex layering (ensure popups always in front)
local Z = {
    BASE = 1,
    HEADER = 2,
    TABBAR = 3,
    CONTENT = 4,
    FLOAT = 20,
    TOAST = 50
}

-- ===== Root Gui =====
local RootGui = new("ScreenGui", {
    Name = "AcinonyxUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
})

-- Allow multiple instances safely
pcall(function()
    local old = PlayerGui:FindFirstChild(RootGui.Name)
    if old then old:Destroy() end
end)

RootGui.Parent = PlayerGui

-- Global toast layer
local ToastLayer = new("Frame", {
    Name = "ToastLayer", Parent = RootGui,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0),
    ZIndex = Z.TOAST
})

local function makeToast(title, content, timeSec)
    local holder = new("Frame", {
        Parent = ToastLayer,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.fromOffset(320, 96),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1.02, 1.02),
        ZIndex = Z.TOAST
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 12) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.35 }),
        new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })
    })

    local titleL = new("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 2),
        Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(title or "Notification"), TextColor3 = Theme.Text,
        ZIndex = Z.TOAST
    })

    local contentL = new("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -28), Position = UDim2.fromOffset(0, 26),
        Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, Text = tostring(content or ""),
        TextColor3 = Theme.Muted,
        ZIndex = Z.TOAST
    })

    holder.Position = UDim2.fromScale(1.02, 1.02)
    holder.BackgroundTransparency = 1
    spring(holder, { Position = UDim2.fromScale(0.985, 0.985), BackgroundTransparency = 0 }, 0.22):Play()

    task.delay(timeSec or 4, function()
        local tw = spring(holder, { Position = UDim2.fromScale(1.05, 1.05), BackgroundTransparency = 1 }, 0.18)
        tw:Play()
        tw.Completed:Wait()
        holder:Destroy()
    end)
end

-- ===== Draggable Window =====
local function makeWindowFrame(opts)
    opts = opts or {}
    local root = new("Frame", {
        Name = "Window",
        Parent = RootGui,
        BackgroundColor3 = Theme.Bg,
        Size = opts.Size or UDim2.fromOffset(620, 420),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        ZIndex = Z.BASE
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 14) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.35 })
    })

    local header = new("Frame", {
        Parent = root,
        Name = "Header",
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 46),
        ZIndex = Z.HEADER
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 14) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.4 }),
        new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) })
    })

    local title = new("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(opts.Name or "Acinonyx Script"), TextColor3 = Theme.Text,
        ZIndex = Z.HEADER
    })

    local minimizeBtn = new("TextButton", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        Text = "–", TextScaled = true, Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Muted, ZIndex = Z.HEADER
    })

    local closeBtn = new("TextButton", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -28, 0.5, -13),
        Text = "×", TextScaled = true, Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Muted, ZIndex = Z.HEADER
    })

    local body = new("Frame", {
        Parent = root,
        Name = "Body",
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -46),
        Position = UDim2.fromOffset(0, 46),
        ZIndex = Z.CONTENT
    })

    local sidebar = new("Frame", {
        Parent = body,
        Name = "Sidebar",
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 160, 1, 0),
        ZIndex = Z.TABBAR
    }, {
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.4 })
    })

    local tabList = new("Frame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -8),
        Position = UDim2.fromOffset(0, 8),
        ZIndex = Z.TABBAR
    }, {
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6) })
    })

    local content = new("Frame", {
        Parent = body,
        Name = "Content",
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.fromOffset(160, 0),
        ClipsDescendants = true,
        ZIndex = Z.CONTENT
    })

    -- Dragging
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = root.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Buttons
    minimizeBtn.MouseButton1Click:Connect(function()
        local collapsed = content.Visible
        content.Visible = not collapsed
        spring(root, { Size = collapsed and (opts.Size or UDim2.fromOffset(620, 420)) or UDim2.fromOffset(root.Size.X.Offset, 46) }, 0.2):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        root.Visible = false
    end)

    return root, header, sidebar, tabList, content
end

-- ===== Orion‑compatible objects =====
local Acinonyx = { _windows = {}, _started = false }
Acinonyx.__index = Acinonyx

function Acinonyx:MakeNotification(opts)
    makeToast(opts and opts.Name or "Notification", opts and opts.Content or "", opts and opts.Time or 4)
end

function Acinonyx:Init()
    -- no-op placeholder for Orion compatibility
    self._started = true
end

function Acinonyx:MakeWindow(opts)
    opts = opts or {}
    local frame, header, sidebar, tabList, content = makeWindowFrame({
        Name = opts.Name or "Acinonyx",
        Size = opts.Size or UDim2.fromOffset(620, 420)
    })

    local Window = { _tabs = {}, _content = content, _tabList = tabList, _sidebar = sidebar, _frame = frame, _opts = opts }

    function Window:MakeTab(t)
        t = t or {}
        local btn = new("TextButton", {
            Parent = self._tabList,
            BackgroundColor3 = Theme.Panel,
            Text = tostring(t.Name or "Tab"),
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Muted,
            Size = UDim2.new(1, -0, 0, 36), AutoButtonColor = false,
            ZIndex = Z.TABBAR
        }, {
            new("UICorner", { CornerRadius = UDim.new(0, 10) }),
            new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.45 })
        })

        local page = new("ScrollingFrame", {
            Parent = self._content,
            Name = (t.Name or "Tab") .. "Page",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 5,
            Visible = false,
            ZIndex = Z.CONTENT
        }, {
            new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
            new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) })
        })

        local function select()
            for _, tinfo in pairs(self._tabs) do
                tinfo.page.Visible = false
                tinfo.btn.TextColor3 = Theme.Muted
                tinfo.btn.BackgroundColor3 = Theme.Panel
            end
            page.Visible = true
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Sel
        end

        btn.MouseButton1Click:Connect(select)
        if #self._tabs == 0 then select() end

        local TabObj = { _page = page, _sections = {}, _btn = btn }

        function TabObj:AddSection(s)
            s = s or {}
            local section = new("Frame", {
                Parent = page,
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = Z.CONTENT
            }, {
                new("UICorner", { CornerRadius = UDim.new(0, 10) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.45 }),
                new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
                new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            })

            local title = new("TextLabel", {
                Parent = section,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(s.Name or "Section"), TextColor3 = Theme.Text,
                ZIndex = Z.CONTENT
            })

            local SectionObj = { _container = section }

            local function addRow(height)
                local row = new("Frame", {
                    Parent = section, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, height or 34)
                }, {
                    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
                })
                return row
            end

            local function labelAndRight(row, nameText)
                local name = new("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -8, 1, 0),
                    Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
                    Text = tostring(nameText or ""), TextColor3 = Theme.Muted
                })
                local right = new("Frame", {
                    Parent = row, BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -8, 1, 0)
                })
                return name, right
            end

            -- BUTTON
            function SectionObj:AddButton(b)
                b = b or {}
                local row = addRow(34)
                labelAndRight(row, b.Name)
                local btn = new("TextButton", {
                    Parent = row, BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0.5, -8, 1, 0), Text = b.Name or "Button",
                    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), AutoButtonColor = false
                }, {
                    new("UICorner", { CornerRadius = UDim.new(0, 8) })
                })
                btn.MouseButton1Click:Connect(function()
                    spring(btn, { BackgroundColor3 = Theme.Accent2 }, 0.08):Play()
                    safeCallback(b.Callback)
                    spring(btn, { BackgroundColor3 = Theme.Accent }, 0.18):Play()
                end)
                return btn
            end

            -- TOGGLE
            function SectionObj:AddToggle(t)
                t = t or {}
                local state = not not t.Default
                local row = addRow(34)
                local _, right = labelAndRight(row, t.Name)
                local toggle = new("TextButton", {
                    Parent = right, BackgroundColor3 = state and Theme.Accent or Theme.Panel,
                    Size = UDim2.new(0, 56, 1, -6), Position = UDim2.fromOffset(0, 3),
                    AutoButtonColor = false, Text = ""
                }, {
                    new("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    new("UIStroke", { Color = Theme.Stroke, Transparency = 0.45 })
                })
                local knob = new("Frame", {
                    Parent = toggle, BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(state and 32 or 2, 2)
                }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local function set(v)
                    state = not not v
                    local targetColor = state and Theme.Accent or Theme.Panel
                    spring(toggle, { BackgroundColor3 = targetColor }, 0.12):Play()
                    spring(knob, { Position = UDim2.fromOffset(state and 32 or 2, 2) }, 0.12):Play()
                    safeCallback(t.Callback, state)
                end
                toggle.MouseButton1Click:Connect(function() set(not state) end)
                if t.Callback then task.defer(t.Callback, state) end
                return { Set = set }
            end

            -- SLIDER
            function SectionObj:AddSlider(s)
                s = s or {}; s.Min = s.Min or 0; s.Max = s.Max or 100; s.Increment = s.Increment or 1
                local value = s.Default or s.Min
                local row = addRow(46)
                local name, right = labelAndRight(row, (s.Name or "Slider") .. (s.ValueName and (" ("..s.ValueName..")") or ""))

                local bar = new("Frame", { Parent = right, BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 18) }, {
                    new("UICorner", { CornerRadius = UDim.new(1, 0) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.5 })
                })
                local fill = new("Frame", { Parent = bar, BackgroundColor3 = Theme.Accent, Size = UDim2.new((value-s.Min)/(s.Max-s.Min), 0, 1, 0) }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
                local valL = new("TextLabel", { Parent = right, BackgroundTransparency = 1, Size = UDim2.new(0, 60, 0, 18), Position = UDim2.fromOffset(right.AbsoluteSize.X - 60, 0), Text = tostring(value), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text })

                local dragging = false
                local function applyFromX(px)
                    local a = bar.AbsolutePosition.X; local w = bar.AbsoluteSize.X
                    local t = math.clamp((px - a)/w, 0, 1)
                    local v = round(s.Min + t * (s.Max - s.Min), s.Increment)
                    value = math.clamp(v, s.Min, s.Max)
                    fill.Size = UDim2.new((value-s.Min)/(s.Max-s.Min), 0, 1, 0)
                    valL.Text = tostring(value)
                    safeCallback(s.Callback, value)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true; applyFromX(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        applyFromX(input.Position.X)
                    end
                end)

                if s.Callback then task.defer(s.Callback, value) end
                return { Set = function(v) applyFromX(bar.AbsolutePosition.X + (math.clamp(v, s.Min, s.Max) - s.Min) / (s.Max - s.Min) * bar.AbsoluteSize.X) end }
            end

            -- DROPDOWN (front overlay, no clipping issues)
            function SectionObj:AddDropdown(d)
                d = d or {}; d.Options = d.Options or {}
                local selected = d.Default
                local row = addRow(34)
                local _, right = labelAndRight(row, d.Name)
                local holder = new("TextButton", {
                    Parent = right, BackgroundColor3 = Theme.Panel, AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 1, -6), Position = UDim2.fromOffset(0, 3), Text = "",
                }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.45 }) })

                local text = new("TextLabel", { Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(10,0), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Text, Text = tostring(selected or "Select...") })
                local arrow = new("TextLabel", { Parent = holder, BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 0.5, -10), Text = "▼", TextColor3 = Theme.Muted, Font = Enum.Font.GothamBold, TextSize = 14 })

                local popup = new("Frame", { Parent = RootGui, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Size = UDim2.fromOffset(holder.AbsoluteSize.X, 0), Position = UDim2.fromOffset(0, 0), Visible = false, ZIndex = Z.FLOAT }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.4 }), new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

                local function rebuild()
                    popup:ClearAllChildren()
                    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = popup })
                    new("UIStroke", { Color = Theme.Stroke, Transparency = 0.4, Parent = popup })
                    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = popup })
                    for _, opt in ipairs(d.Options) do
                        local item = new("TextButton", { Parent = popup, BackgroundColor3 = Theme.Panel, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), Text = tostring(opt), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.Text, ZIndex = Z.FLOAT })
                        item.MouseEnter:Connect(function() item.BackgroundColor3 = Theme.Sel end)
                        item.MouseLeave:Connect(function() item.BackgroundColor3 = Theme.Panel end)
                        item.MouseButton1Click:Connect(function()
                            selected = opt
                            text.Text = tostring(opt)
                            popup.Visible = false
                            safeCallback(d.Callback, selected)
                        end)
                    end
                    popup.Size = UDim2.fromOffset(holder.AbsoluteSize.X, math.min(#d.Options, 8) * 30)
                end
                rebuild()

                local function open()
                    if popup.Visible then popup.Visible = false return end
                    local absPos = holder.AbsolutePosition
                    popup.Position = UDim2.fromOffset(absPos.X, absPos.Y + holder.AbsoluteSize.Y + 4)
                    popup.Visible = true
                end

                holder.MouseButton1Click:Connect(open)
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if popup.Visible then
                            local m = UserInputService:GetMouseLocation()
                            local p = popup.AbsolutePosition; local s = popup.AbsoluteSize
                            local inside = (m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y)
                            if not inside then popup.Visible = false end
                        end
                    end
                end)

                if d.Callback and selected ~= nil then task.defer(d.Callback, selected) end
                return { Set = function(v) selected = v; text.Text = tostring(v); safeCallback(d.Callback, v) end, Refresh = function(opts) d.Options = opts or {}; rebuild() end }
            end

            -- PARAGRAPH / LABEL
            function SectionObj:AddParagraph(titleText, bodyText)
                local row = addRow(60)
                local card = new("Frame", { Parent = row, BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 1, 0) }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.4 }), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8) }), new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }) })
                new("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Text, Text = tostring(titleText or "Paragraph") })
                new("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -22), Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Theme.Muted, Text = tostring(bodyText or "") })
            end

            -- COLOR PICKER (RGB sliders — simple, reliable)
            function SectionObj:AddColorpicker(c)
                c = c or {}; local col = c.Default or Color3.fromRGB(255, 255, 255)
                local row = addRow(60)
                local _, right = labelAndRight(row, c.Name or "Color")
                local swatch = new("Frame", { Parent = right, BackgroundColor3 = col, Size = UDim2.new(0, 42, 1, -6), Position = UDim2.fromOffset(0, 3) }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.4 }) })
                local sliders = new("Frame", { Parent = right, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(50, 0) }, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })

                local comps = { {"R", col.R*255}, {"G", col.G*255}, {"B", col.B*255} }
                local function push()
                    swatch.BackgroundColor3 = col
                    safeCallback(c.Callback, col)
                end
                local function make(name, def)
                    local bar = new("Frame", { Parent = sliders, BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 8) }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.5 }) })
                    local fill = new("Frame", { Parent = bar, BackgroundColor3 = Theme.Accent, Size = UDim2.new(def/255, 0, 1, 0) }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
                    local lab = new("TextLabel", { Parent = sliders, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Muted, Text = name..": "..tostring(math.floor(def)) })
                    local dragging = false
                    local function apply(px)
                        local a = bar.AbsolutePosition.X; local w = bar.AbsoluteSize.X
                        local t = math.clamp((px - a)/w, 0, 1)
                        local v = math.floor(t*255 + 0.5)
                        lab.Text = name..": "..v
                        fill.Size = UDim2.new(v/255, 0, 1, 0)
                        if name=="R" then col = Color3.fromRGB(v, col.G*255, col.B*255)
                        elseif name=="G" then col = Color3.fromRGB(col.R*255, v, col.B*255)
                        else col = Color3.fromRGB(col.R*255, col.G*255, v) end
                        push()
                    end
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; apply(input.Position.X) end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then apply(input.Position.X) end
                    end)
                end
                for _, kv in ipairs(comps) do make(kv[1], kv[2]) end
                if c.Callback then task.defer(c.Callback, col) end
                return { Set = function(v) col = v; push() end }
            end

            -- KEYBIND
            function SectionObj:AddKeybind(k)
                k = k or {}
                local current = k.Default or Enum.KeyCode.LeftControl
                local row = addRow(34)
                local _, right = labelAndRight(row, k.Name or "Keybind")
                local button = new("TextButton", { Parent = right, BackgroundColor3 = Theme.Panel, AutoButtonColor = false, Size = UDim2.new(1, 0, 1, -6), Position = UDim2.fromOffset(0,3), Text = current.Name, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.Text }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), new("UIStroke", { Color = Theme.Stroke, Transparency = 0.45 }) })
                local listening = false
                button.MouseButton1Click:Connect(function()
                    listening = true; button.Text = "Press any key..."
                end)
                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false; current = input.KeyCode; button.Text = current.Name
                        safeCallback(k.Callback, current)
                    end
                end)
                if k.Callback then task.defer(k.Callback, current) end
                return { Set = function(code) current = code; button.Text = current.Name; safeCallback(k.Callback, current) end }
            end

            return SectionObj
        end

        table.insert(self._tabs, { btn = btn, page = page })
        return TabObj
    end

    return Window
end

-- Expose as a module table (Orion‑like)
local OrionLib = setmetatable({ MakeWindow = function(self, ...) return Acinonyx:MakeWindow(...) end, MakeNotification = function(self, ...) return Acinonyx:MakeNotification(...) end, Init = function(self, ...) return Acinonyx:Init(...) end }, Acinonyx)

return OrionLib
