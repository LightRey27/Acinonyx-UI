--[[
  AcinonyxUI (Fusion 0.4, single-file)
  Components: Window (draggable), Button, Dropdown (Portal overlay)
  Dependency: Fusion (0.4) di ReplicatedStorage atau ReplicatedStorage/Packages/Fusion.
]]

local Players = game:GetService("Players")
local Rep     = game:GetService("ReplicatedStorage")

-- ===== Require Fusion (0.4) =====
local function tryRequireFusion()
    local ok, mod
    local pkg = Rep:FindFirstChild("Packages")
    if pkg and pkg:FindFirstChild("Fusion") then
        ok, mod = pcall(function() return require(pkg.Fusion) end)
        if ok and mod then return mod end
    end
    if Rep:FindFirstChild("Fusion") then
        ok, mod = pcall(function() return require(Rep.Fusion) end)
        if ok and mod then return mod end
    end
    error("[AcinonyxUI] Fusion not found. Put Fusion ModuleScript in ReplicatedStorage or ReplicatedStorage/Packages/Fusion")
end

local Fusion = tryRequireFusion()

-- Aliases
local New        = Fusion.New
local Children   = Fusion.Children
local OnEvent    = Fusion.OnEvent
local Value      = Fusion.Value
local Computed   = Fusion.Computed
local Observer   = Fusion.Observer
local ForValues  = Fusion.ForValues
local Ref        = Fusion.Ref
local cleanup    = Fusion.cleanup

-- ===== Theme (reactive) =====
local Theme = {
    Mode    = Value("Dark"),
    Colors  = Value({
        Bg      = Color3.fromRGB(18, 18, 20),
        Panel   = Color3.fromRGB(26, 27, 31),
        Text    = Color3.fromRGB(235,235,240),
        Muted   = Color3.fromRGB(150,150,160),
        Primary = Color3.fromRGB(120,162,255),
        Accent  = Color3.fromRGB(90,200,140),
        Danger  = Color3.fromRGB(255,95,110),
    }),
    Radius  = Value(10),
    Padding = Value(10),
    Font    = Value(Enum.Font.Gotham)
}
Theme.TextColor = Computed(function() return Theme.Colors:get().Text end)

-- ===== Style helpers =====
local function Corner(radius)
    return New "UICorner" { CornerRadius = UDim.new(0, radius) }
end
local function Padding(p)
    return New "UIPadding" {
        PaddingTop = UDim.new(0,p), PaddingBottom = UDim.new(0,p),
        PaddingLeft= UDim.new(0,p), PaddingRight = UDim.new(0,p),
    }
end
local function Stroke(color, thickness)
    return New "UIStroke" { Color = color, Thickness = thickness or 1 }
end

-- ===== Portal Overlay =====
local overlayGui -- ScreenGui
local function getOverlayRoot()
    if overlayGui and overlayGui.Parent then return overlayGui end
    local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
    overlayGui = New "ScreenGui" {
        Name = "AcinonyxUI_Overlay",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 10000,
        Parent = pgui
    }
    return overlayGui
end

-- ===== Components =====

-- Window (draggable)
local function Window(props)
    local C = Theme.Colors
    local pos = Value(props.Position or UDim2.fromOffset(200, 140))
    local dragging = Value(false)
    local dragStart, startPos
    local winRef = Value(nil)

    local function startDrag(input)
        dragging:set(true)
        dragStart = input.Position
        local frame = winRef:get()
        if frame then startPos = frame.Position end
    end
    local function doDrag(input)
        if not dragging:get() then return end
        local frame = winRef:get()
        if not frame then return end
        local delta = input.Position - dragStart
        pos:set(UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y))
    end

    local win = New "Frame" {
        Name = props.Name or "Window",
        BackgroundColor3 = Computed(function() return C:get().Bg end),
        Size = props.Size or UDim2.fromOffset(520, 360),
        Position = pos:get(),
        ZIndex = 10,
        [Children] = {
            Corner(12),
            Stroke(Computed(function() return C:get().Muted end), 1),

            New "TextButton" {
                Name = "TitleBar",
                BackgroundColor3 = Computed(function() return C:get().Panel end),
                TextColor3 = Computed(function() return C:get().Text end),
                Font = Theme.Font:get(), TextSize = 16,
                Text = props.Title or "Acinonyx UI",
                Size = UDim2.new(1,0,0,36),
                ZIndex = 11,
                [Children] = { Corner(12) },
                [OnEvent "InputBegan"] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        startDrag(input)
                    end
                end,
                [OnEvent "InputChanged"] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        doDrag(input)
                    end
                end,
                [OnEvent "InputEnded"] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging:set(false)
                    end
                end
            },

            New "Frame" {
                Name = "Body",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 36),
                Size = UDim2.new(1,0,1,-36),
                [Children] = {
                    New "UIPadding" {
                        PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10),
                        PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10)
                    }
                }
            }
        },
        [Ref] = function(inst) winRef:set(inst) end
    }

    return win
end

-- Button
local function Button(props)
    local pressed = Value(false)
    local C = Theme.Colors

    return New "TextButton" {
        Name = props.Name or "Button",
        AutoButtonColor = false,
        Font = Theme.Font:get(),
        Text = props.Text or "Button",
        TextSize = props.TextSize or 14,
        TextColor3 = Computed(function() return C:get().Text end),
        BackgroundColor3 = Computed(function()
            local base = C:get().Primary
            return pressed:get() and base:lerp(Color3.new(0,0,0), 0.2) or base
        end),
        Size = props.Size or UDim2.fromOffset(120, 32),
        [Children] = { Corner(Theme.Radius:get()), Padding(8) },
        [OnEvent "MouseButton1Down"] = function() pressed:set(true) end,
        [OnEvent "MouseButton1Up"]   = function() pressed:set(false) end,
        [OnEvent "Activated"] = function()
            if props.OnPressed then task.spawn(props.OnPressed) end
        end,
        Parent = props.Parent
    }
end

-- Dropdown (Portal overlay)
local function Dropdown(props)
    local items = props.Items or {}
    local open  = Value(false)
    local sel   = Value(props.Default or items[1])
    local C     = Theme.Colors

    local anchorRef = Value(nil)
    local menuPos   = Value(UDim2.fromOffset(0,0))

    -- hitung posisi menu ketika open
    Observer(open):onChange(function(now)
        local btn = anchorRef:get()
        if now and btn and btn.AbsolutePosition then
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            menuPos:set(UDim2.fromOffset(pos.X, pos.Y + size.Y + 2))
        end
    end)

    local function renderMenu()
        if not open:get() then return nil end
        local root = getOverlayRoot()
        return New "Frame" {
            Name = "DropdownMenuPortal",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            ZIndex = 100,
            Parent = root,
            [Children] = {
                New "Frame" {
                    Name = "Menu",
                    BackgroundColor3 = C:get().Panel,
                    BorderSizePixel = 0,
                    Position = menuPos:get(),
                    Size = UDim2.fromOffset(props.Width or 180, math.max(24, #items * 28)),
                    ZIndex = 101,
                    [Children] = {
                        Corner(8),
                        Stroke(Computed(function() return C:get().Muted end), 1),
                        New "UIListLayout" { Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder },
                        ForValues(items, function(i, idx)
                            return New "TextButton" {
                                Name = "Item_"..tostring(idx),
                                LayoutOrder = idx,
                                AutoButtonColor = true,
                                BackgroundColor3 = C:get().Panel,
                                TextColor3 = C:get().Text,
                                Font = Theme.Font:get(),
                                TextSize = 14,
                                Text = tostring(i),
                                Size = UDim2.new(1, -8, 0, 26),
                                Position = UDim2.fromOffset(4,0),
                                ZIndex = 102,
                                [Children] = { Corner(6) },
                                [OnEvent "Activated"] = function()
                                    sel:set(i); open:set(false)
                                    if props.OnChanged then task.spawn(props.OnChanged, i) end
                                end
                            }
                        end, cleanup)
                    }
                }
            }
        }
    end

    return New "Frame" {
        Name = props.Name or "Dropdown",
        BackgroundTransparency = 1,
        Size = props.Size or UDim2.fromOffset(props.Width or 180, 32),
        [Children] = {
            New "TextButton" {
                Name = "Button",
                AutoButtonColor = true,
                BackgroundColor3 = C:get().Panel,
                TextColor3 = C:get().Text,
                Font = Theme.Font:get(),
                TextSize = 14,
                Text = Computed(function() return tostring(sel:get()) end),
                Size = UDim2.fromScale(1,1),
                ZIndex = 50,
                [Children] = { Corner(8), Padding(8) },
                [OnEvent "Activated"] = function() open:set(not open:get()) end,
                [Ref] = function(inst) anchorRef:set(inst) end
            },
            Computed(renderMenu)
        },
        Parent = props.Parent
    }
end

-- ===== Public API =====
local AcinonyxUI = {}

function AcinonyxUI.createWindow(opts)
    local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local root = New "ScreenGui" {
        Name = opts and opts.Name or "AcinonyxUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        Parent = pgui
    }

    local win = Window({
        Title  = (opts and opts.Title) or "Acinonyx UI",
        Size   = (opts and opts.Size) or UDim2.fromOffset(520,360),
        Parent = root
    })

    local api = {
        ScreenGui = root,
        Window = win,
        Theme = Theme,
        addButton = function(props)
            props.Parent = win:FindFirstChild("Body") or win
            return Button(props)
        end,
        addDropdown = function(props)
            props.Parent = win:FindFirstChild("Body") or win
            return Dropdown(props)
        end,
        destroy = function()
            if root and root.Parent then root:Destroy() end
        end
    }
    return api
end

AcinonyxUI.Theme = Theme
return AcinonyxUI
