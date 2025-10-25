--[[
  Acinonyx UI Library — Rayfield‑Compatible API (v0.1)
  ----------------------------------------------------
  Fresh implementation with an API designed to mirror Rayfield so your
  existing Rayfield scripts can be ported with tiny/no changes.

  Example:
    local Rayfield = loadstring(game:HttpGet("<your raw Init.lua>"))()
    local Window = Rayfield:CreateWindow({
      Name = "Acinonyx Script",
      LoadingTitle = "Acinonyx",
      LoadingSubtitle = "Rayfield API",
      ConfigurationSaving = { Enabled = false, FileName = "Acinonyx" },
      KeySystem = false
    })

    local Tab = Window:CreateTab("Main")
    Tab:CreateSection("Controls")

    Tab:CreateToggle({ Name = "Enable", CurrentValue = true, Callback = function(v) print("toggle", v) end })
    Tab:CreateButton({ Name = "Click", Callback = function() print("clicked") end })
    Tab:CreateSlider({ Name = "Speed", Range = {0, 100}, Increment = 1, CurrentValue = 40, Suffix = "%", Callback = function(v) end })
    Tab:CreateDropdown({ Name = "Mode", Options = {"A","B","C"}, CurrentOption = "A", Callback = function(o) end })
    Tab:CreateInput({ Name = "Threshold", PlaceholderText = "number", NumbersOnly = true, OnEnter = true, Callback = function(txt) end })
    Tab:CreateKeybind({ Name = "Toggle UI", CurrentKeybind = Enum.KeyCode.LeftControl, Callback = function(key) end })
    Tab:CreateColorPicker({ Name = "Tint", Color = Color3.fromRGB(0,170,255), Callback = function(c) end })
    Tab:CreateParagraph({ Title = "Info", Content = "Hello from Acinonyx" })

    Rayfield:Notify({ Title = "Loaded", Content = "Acinonyx ready", Duration = 4 })

  Notes:
    • No code is copied from Rayfield; only the API surface is mimicked.
    • Dropdown uses a high‑Z overlay to ensure it renders above everything.
    • ConfigurationSaving / Discord / KeySystem are stubs for now.
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== Utils =====
local function new(klass, props, children)
  local o = Instance.new(klass)
  if props then for k,v in pairs(props) do o[k]=v end end
  if children then for _,c in ipairs(children) do c.Parent = o end end
  return o
end
local function tw(i, g, t)
  return TweenService:Create(i, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), g)
end
local function cb(fn, ...) if typeof(fn)=="function" then task.spawn(pcall, fn, ...) end end
local function round(n, inc) inc = inc or 1; return math.floor(n/inc+0.5)*inc end

local Theme = {
  Bg = Color3.fromRGB(16,16,19),
  Panel = Color3.fromRGB(26,27,31),
  Text = Color3.fromRGB(240,241,245),
  Muted = Color3.fromRGB(180,183,190),
  Stroke = Color3.fromRGB(54,57,63),
  Accent = Color3.fromRGB(0,170,255),
  Accent2 = Color3.fromRGB(0,140,220),
  Sel = Color3.fromRGB(38,40,46)
}
local Z = { BASE=1, HEADER=2, TAB=3, CONTENT=4, FLOAT=20, TOAST=50 }

-- Root GUI (single instance)
local Root = new("ScreenGui", { Name="Acinonyx_Rayfield", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999999, IgnoreGuiInset=true })
pcall(function() local old=PlayerGui:FindFirstChild(Root.Name); if old then old:Destroy() end end)
Root.Parent = PlayerGui

local ToastLayer = new("Frame", { Parent=Root, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=Z.TOAST })
local function notify(opts)
  local holder = new("Frame", { Parent=ToastLayer, BackgroundColor3=Theme.Panel, Size=UDim2.fromOffset(320,96), AnchorPoint=Vector2.new(1,1), Position=UDim2.fromScale(1.02,1.02), ZIndex=Z.TOAST }, {
    new("UICorner",{CornerRadius=UDim.new(0,12)}), new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.35}), new("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)})
  })
  new("TextLabel", { Parent=holder, BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), Font=Enum.Font.GothamBold, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Theme.Text, Text=tostring(opts.Title or "Notification") })
  new("TextLabel", { Parent=holder, BackgroundTransparency=1, Size=UDim2.new(1,0,1,-28), Position=UDim2.fromOffset(0,26), Font=Enum.Font.Gotham, TextSize=14, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextColor3=Theme.Muted, Text=tostring(opts.Content or "") })
  holder.BackgroundTransparency = 1
  tw(holder,{Position=UDim2.fromScale(0.985,0.985), BackgroundTransparency=0},0.22):Play()
  task.delay(tonumber(opts.Duration) or 4, function()
    local a=tw(holder,{Position=UDim2.fromScale(1.05,1.05), BackgroundTransparency=1},0.18); a:Play(); a.Completed:Wait(); holder:Destroy()
  end)
end

-- Window factory
local function createWindow(opts)
  opts = opts or {}
  local root = new("Frame", { Parent=Root, BackgroundColor3=Theme.Bg, Size=opts.Size or UDim2.fromOffset(640,440), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5), ZIndex=Z.BASE }, {
    new("UICorner",{CornerRadius=UDim.new(0,14)}), new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.25})
  })
  local header = new("Frame", { Parent=root, BackgroundColor3=Theme.Panel, Size=UDim2.new(1,0,0,50), ZIndex=Z.HEADER }, {
    new("UICorner",{CornerRadius=UDim.new(0,14)}), new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.35}), new("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,12)})
  })
  new("TextLabel", { Parent=header, BackgroundTransparency=1, Size=UDim2.new(1,-120,1,0), Font=Enum.Font.GothamBold, TextSize=18, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Theme.Text, Text=tostring(opts.Name or "Acinonyx Script") })
  local minimizeBtn = new("TextButton", { Parent=header, BackgroundTransparency=1, Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-60,0.5,-13), Text="–", TextScaled=true, Font=Enum.Font.GothamBold, TextColor3=Theme.Muted })
  local closeBtn    = new("TextButton", { Parent=header, BackgroundTransparency=1, Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-28,0.5,-13), Text="×", TextScaled=true, Font=Enum.Font.GothamBold, TextColor3=Theme.Muted })

  local body = new("Frame", { Parent=root, BackgroundColor3=Theme.Bg, Size=UDim2.new(1,0,1,-50), Position=UDim2.fromOffset(0,50), ZIndex=Z.CONTENT })
  local sidebar = new("Frame", { Parent=body, BackgroundColor3=Theme.Panel, Size=UDim2.new(0,168,1,0), ZIndex=Z.TAB }, {
    new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.35})
  })
  local tabList = new("Frame", { Parent=sidebar, BackgroundTransparency=1, Size=UDim2.new(1,0,1,-8), Position=UDim2.fromOffset(0,8), ZIndex=Z.TAB }, {
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8)}), new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,8)})
  })
  local content = new("Frame", { Parent=body, BackgroundColor3=Theme.Bg, Size=UDim2.new(1,-168,1,0), Position=UDim2.fromOffset(168,0), ZIndex=Z.CONTENT })

  -- drag
  do
    local dragging, dragStart, start
    header.InputBegan:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; start=root.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end
    end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart; root.Position=UDim2.new(start.X.Scale,start.X.Offset+d.X,start.Y.Scale,start.Y.Offset+d.Y) end end)
  end
  minimizeBtn.MouseButton1Click:Connect(function() local c=content.Visible; content.Visible=not c; tw(root,{Size=c and (opts.Size or UDim2.fromOffset(640,440)) or UDim2.fromOffset(root.Size.X.Offset,50)},0.2):Play() end)
  closeBtn.MouseButton1Click:Connect(function() root.Visible=false end)

  local Window = { _tabs = {}, _content = content, _tabList = tabList }

  function Window:CreateTab(name, iconAssetId)
    local btn = new("TextButton", { Parent=tabList, BackgroundColor3=Theme.Panel, Size=UDim2.new(1,0,0,38), AutoButtonColor=false, Text=tostring(name or "Tab"), Font=Enum.Font.GothamBold, TextSize=15, TextColor3=Theme.Muted, ZIndex=Z.TAB }, { new("UICorner",{CornerRadius=UDim.new(0,10)}), new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.4}) })
    local page = new("ScrollingFrame", { Parent=content, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Visible=false, ScrollBarThickness=6, ScrollBarImageTransparency=0.6, ScrollBarImageColor3=Theme.Stroke, ZIndex=Z.CONTENT }, {
      new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,12)}), new("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,16)})
    })

    local function select()
      for _,t in pairs(self._tabs) do t.page.Visible=false; t.btn.TextColor3=Theme.Muted; t.btn.BackgroundColor3=Theme.Panel end
      page.Visible=true; btn.TextColor3=Theme.Text; btn.BackgroundColor3=Theme.Sel
    end
    btn.MouseButton1Click:Connect(select); if #self._tabs==0 then select() end

    local TabObj = { _page = page }

    function TabObj:CreateSection(title)
      local section = new("Frame", { Parent=page, BackgroundColor3=Theme.Panel, Size=UDim2.new(1,0,0,48), AutomaticSize=Enum.AutomaticSize.Y, ZIndex=Z.CONTENT }, {
        new("UICorner",{CornerRadius=UDim.new(0,12)}), new("UIStroke",{Color=Theme.Stroke,Thickness=1,Transparency=0.35}), new("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)}), new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
      })
      new("TextLabel", { Parent=section, BackgroundTransparency=1, Size=UDim2.new(1,0,0,18), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Theme.Text, Text=tostring(title or "Section"), TextXAlignment=Enum.TextXAlignment.Left })
      local Container = section

      local function row(h)
        return new("Frame", { Parent=Container, BackgroundTransparency=1, Size=UDim2.new(1,0,0,h or 34) }, { new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8)}) })
      end
      local function nameRight(r, text)
        new("TextLabel",{Parent=r,BackgroundTransparency=1,Size=UDim2.new(0.5,-8,1,0),Font=Enum.Font.Gotham,TextSize=14,TextColor3=Theme.Muted,Text=tostring(text or ""),TextXAlignment=Enum.TextXAlignment.Left})
        local right=new("Frame",{Parent=r,BackgroundTransparency=1,Size=UDim2.new(0.5,-8,1,0)})
        return right
      end

      -- Toggle
      function TabObj:CreateToggle(o)
        local r=row(34); local right=nameRight(r,o.Name)
        local state = not not o.CurrentValue
        local toggle = new("TextButton",{Parent=right,BackgroundColor3=state and Theme.Accent or Theme.Panel,Size=UDim2.new(0,58,1,-6),Position=UDim2.fromOffset(0,3),AutoButtonColor=false,Text=""},{new("UICorner",{CornerRadius=UDim.new(1,0)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.45})})
        local knob=new("Frame",{Parent=toggle,BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(22,22),Position=UDim2.fromOffset(state and 34 or 2,2)},{new("UICorner",{CornerRadius=UDim.new(1,0)})})
        local function set(v) state=not not v; tw(toggle,{BackgroundColor3=state and Theme.Accent or Theme.Panel},0.12):Play(); tw(knob,{Position=UDim2.fromOffset(state and 34 or 2,2)},0.12):Play(); cb(o.Callback,state) end
        toggle.MouseButton1Click:Connect(function() set(not state) end)
        if o.Callback then task.defer(o.Callback, state) end
        local Obj = { Set = set }
        return Obj
      end

      -- Button
      function TabObj:CreateButton(o)
        local r=row(34); nameRight(r,o.Name)
        local b=new("TextButton",{Parent=r,BackgroundColor3=Theme.Accent,Size=UDim2.new(0.5,-8,1,0),Text=o.Name or "Button",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.new(1,1,1),AutoButtonColor=false},{new("UICorner",{CornerRadius=UDim.new(0,8)})})
        b.MouseButton1Click:Connect(function() tw(b,{BackgroundColor3=Theme.Accent2},0.08):Play(); cb(o.Callback); tw(b,{BackgroundColor3=Theme.Accent},0.18):Play() end)
        return b
      end

      -- Slider
      function TabObj:CreateSlider(o)
        o.Range = o.Range or {0,100}; o.Increment = o.Increment or 1
        local val = o.CurrentValue or o.Range[1]
        local r=row(46)
        local right=nameRight(r, (o.Name or "Slider") .. (o.Suffix and (" ("..o.Suffix..")") or ""))
        local valL=new("TextLabel",{Parent=right,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(60,18),Position=UDim2.new(1,0,0,0),Text=tostring(val),Font=Enum.Font.Gotham,TextSize=13,TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Right})
        local bar=new("Frame",{Parent=right,BackgroundColor3=Theme.Panel,Size=UDim2.new(1,-64,0,8),Position=UDim2.fromOffset(0,18)},{new("UICorner",{CornerRadius=UDim.new(1,0)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.5})})
        local fill=new("Frame",{Parent=bar,BackgroundColor3=Theme.Accent,Size=UDim2.new((val-o.Range[1])/(o.Range[2]-o.Range[1]),0,1,0)},{new("UICorner",{CornerRadius=UDim.new(1,0)})})
        local dragging=false
        local function apply(px)
          local a=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
          local t=math.clamp((px-a)/w,0,1)
          local v=round(o.Range[1] + t*(o.Range[2]-o.Range[1]), o.Increment)
          val=math.clamp(v,o.Range[1],o.Range[2])
          fill.Size=UDim2.new((val-o.Range[1])/(o.Range[2]-o.Range[1]),0,1,0)
          valL.Text=tostring(val)
          cb(o.Callback,val)
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; apply(i.Position.X) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then apply(i.Position.X) end end)
        if o.Callback then task.defer(o.Callback,val) end
        return { Set = function(v) apply(bar.AbsolutePosition.X + (math.clamp(v,o.Range[1],o.Range[2]) - o.Range[1])/(o.Range[2]-o.Range[1])*bar.AbsoluteSize.X) end }
      end

      -- Dropdown (single select)
      function TabObj:CreateDropdown(o)
        o.Options=o.Options or {}; local selected=o.CurrentOption
        local r=row(34); local right=nameRight(r,o.Name)
        local holder=new("TextButton",{Parent=right,BackgroundColor3=Theme.Panel,AutoButtonColor=false,Size=UDim2.new(1,0,1,-6),Position=UDim2.fromOffset(0,3),Text=""},{new("UICorner",{CornerRadius=UDim.new(0,8)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.35})})
        local text=new("TextLabel",{Parent=holder,BackgroundTransparency=1,Size=UDim2.new(1,-28,1,0),Position=UDim2.fromOffset(10,0),Font=Enum.Font.Gotham,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Theme.Text,TextTruncate=Enum.TextTruncate.AtEnd,Text=tostring(selected or "Select...")})
        new("TextLabel",{Parent=holder,BackgroundTransparency=1,Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-22,0.5,-10),Text="▼",TextColor3=Theme.Muted,Font=Enum.Font.GothamBold,TextSize=14})
        local popup=new("Frame",{Parent=Root,BackgroundColor3=Theme.Panel,BorderSizePixel=0,Size=UDim2.fromOffset(holder.AbsoluteSize.X,0),Position=UDim2.fromOffset(0,0),Visible=false,ZIndex=Z.FLOAT},{new("UICorner",{CornerRadius=UDim.new(0,8)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.35}),new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})})
        local function rebuild()
          popup:ClearAllChildren(); new("UICorner",{CornerRadius=UDim.new(0,8),Parent=popup}); new("UIStroke",{Color=Theme.Stroke,Transparency=0.35,Parent=popup}); new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Parent=popup})
          for _,opt in ipairs(o.Options) do
            local item=new("TextButton",{Parent=popup,BackgroundColor3=Theme.Panel,AutoButtonColor=false,Size=UDim2.new(1,0,0,30),Text=tostring(opt),Font=Enum.Font.Gotham,TextSize=14,TextColor3=Theme.Text,ZIndex=Z.FLOAT})
            item.MouseEnter:Connect(function() item.BackgroundColor3=Theme.Sel end)
            item.MouseLeave:Connect(function() item.BackgroundColor3=Theme.Panel end)
            item.MouseButton1Click:Connect(function() selected=opt; text.Text=tostring(opt); popup.Visible=false; cb(o.Callback,selected) end)
          end
          popup.Size=UDim2.fromOffset(holder.AbsoluteSize.X, math.min(#o.Options,8)*30)
        end
        rebuild()
        holder.MouseButton1Click:Connect(function() if popup.Visible then popup.Visible=false return end local p=holder.AbsolutePosition; popup.Position=UDim2.fromOffset(p.X, p.Y+holder.AbsoluteSize.Y+4); popup.Visible=true end)
        UserInputService.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and popup.Visible then local m=UserInputService:GetMouseLocation(); local p=popup.AbsolutePosition; local s=popup.AbsoluteSize; local inside=(m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+s.Y); if not inside then popup.Visible=false end end end)
        if o.Callback and selected~=nil then task.defer(o.Callback,selected) end
        return { Set=function(v) selected=v; text.Text=tostring(v); cb(o.Callback,v) end, Refresh=function(opts) o.Options=opts or {}; rebuild() end }
      end

      -- Input
      function TabObj:CreateInput(o)
        local r=row(34); local right=nameRight(r,o.Name)
        local box=new("TextBox",{Parent=right,BackgroundColor3=Theme.Panel,Size=UDim2.new(1,0,1,-6),Position=UDim2.fromOffset(0,3),ClearTextOnFocus=false,PlaceholderText=tostring(o.PlaceholderText or ""),Font=Enum.Font.Gotham,TextSize=14,TextColor3=Theme.Text},{new("UICorner",{CornerRadius=UDim.new(0,8)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.35})})
        if o.NumbersOnly then box:GetPropertyChangedSignal("Text"):Connect(function() box.Text=(box.Text:match("%d+")) or "" end) end
        local function fire() cb(o.Callback, box.Text) end
        if o.OnEnter then box.FocusLost:Connect(function(enter) if enter then if o.RemoveTextAfterFocusLost then local t=box.Text; box.Text=""; cb(o.Callback,t) else fire() end end end) else box.FocusLost:Connect(function() if o.RemoveTextAfterFocusLost then local t=box.Text; box.Text=""; cb(o.Callback,t) else fire() end end) end
        return { Set=function(t) box.Text=tostring(t) end, Get=function() return box.Text end }
      end

      -- Keybind
      function TabObj:CreateKeybind(o)
        local r=row(34); local right=nameRight(r,o.Name)
        local key=o.CurrentKeybind or Enum.KeyCode.LeftControl
        local b=new("TextButton",{Parent=right,BackgroundColor3=Theme.Panel,Size=UDim2.new(1,0,1,-6),Position=UDim2.fromOffset(0,3),AutoButtonColor=false,Text=key.Name,Font=Enum.Font.Gotham,TextSize=14,TextColor3=Theme.Text},{new("UICorner",{CornerRadius=UDim.new(0,8)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.35})})
        local listening=false
        b.MouseButton1Click:Connect(function() listening=true; b.Text="Press a key..." end)
        UserInputService.InputBegan:Connect(function(input,gpe) if listening and input.UserInputType==Enum.UserInputType.Keyboard then listening=false; key=input.KeyCode; b.Text=key.Name; cb(o.Callback,key) end end)
        if o.Callback then task.defer(o.Callback,key) end
        return { Set=function(k) key=k; b.Text=key.Name; cb(o.Callback,key) end }
      end

      -- Color Picker (RGB sliders, simple)
      function TabObj:CreateColorPicker(o)
        local r=row(68); local right=nameRight(r,o.Name)
        local col=o.Color or Color3.fromRGB(255,255,255)
        local sw=new("Frame",{Parent=right,BackgroundColor3=col,Size=UDim2.new(0,42,1,-6),Position=UDim2.fromOffset(0,3)},{new("UICorner",{CornerRadius=UDim.new(0,8)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.4})})
        local sliders=new("Frame",{Parent=right,BackgroundTransparency=1,Size=UDim2.new(1,-50,1,0),Position=UDim2.fromOffset(50,0)},{new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)})})
        local function push() sw.BackgroundColor3=col; cb(o.Callback,col) end
        local function mk(name,def)
          local bar=new("Frame",{Parent=sliders,BackgroundColor3=Theme.Panel,Size=UDim2.new(1,0,0,8)},{new("UICorner",{CornerRadius=UDim.new(1,0)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.5})})
          local fill=new("Frame",{Parent=bar,BackgroundColor3=Theme.Accent,Size=UDim2.new(def/255,0,1,0)},{new("UICorner",{CornerRadius=UDim.new(1,0)})})
          local lab=new("TextLabel",{Parent=sliders,BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),Font=Enum.Font.Gotham,TextSize=13,TextColor3=Theme.Muted,Text=name..": "..def,TextXAlignment=Enum.TextXAlignment.Left})
          local dragging=false
          local function apply(px)
            local a=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
            local t=math.clamp((px-a)/w,0,1); local v=math.floor(t*255+0.5)
            lab.Text=name..": "..v; fill.Size=UDim2.new(v/255,0,1,0)
            if name=="R" then col=Color3.fromRGB(v, col.G*255, col.B*255) elseif name=="G" then col=Color3.fromRGB(col.R*255, v, col.B*255) else col=Color3.fromRGB(col.R*255, col.G*255, v) end
            push()
          end
          bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; apply(i.Position.X) end end)
          UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
          UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then apply(i.Position.X) end end)
        end
        local r0,g0,b0=math.floor(col.R*255+0.5),math.floor(col.G*255+0.5),math.floor(col.B*255+0.5)
        mk("R",r0); mk("G",g0); mk("B",b0)
        if o.Callback then task.defer(o.Callback,col) end
        return { Set=function(v) col=v; push() end }
      end

      -- Paragraph
      function TabObj:CreateParagraph(o)
        local r=row(70)
        local card=new("Frame",{Parent=r,BackgroundColor3=Theme.Panel,Size=UDim2.new(1,0,1,0)},{new("UICorner",{CornerRadius=UDim.new(0,10)}),new("UIStroke",{Color=Theme.Stroke,Transparency=0.35}),new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,8),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,8)}),new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)})})
        new("TextLabel",{Parent=card,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Theme.Text,Text=tostring(o.Title or "Paragraph"),TextXAlignment=Enum.TextXAlignment.Left})
        new("TextLabel",{Parent=card,BackgroundTransparency=1,Size=UDim2.new(1,0,1,-22),Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,TextColor3=Theme.Muted,Text=tostring(o.Content or ""),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})
      end

      return TabObj
    end

    table.insert(self._tabs, { btn = btn, page = page })
    return TabObj
  end

  return Window
end

-- Public API table named like Rayfield
local Rayfield = {}
function Rayfield:CreateWindow(opts) return createWindow(opts) end
function Rayfield:Notify(o) return notify(o or {}) end
-- Stubs for compatibility
function Rayfield:Destroy() if Root then Root:Destroy() end end

return Rayfield
