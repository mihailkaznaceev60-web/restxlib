--// NexusUI Library
--// Модульная библиотека для создания чит-стиля интерфейсов в Roblox

local NexusUI = {}
NexusUI.__index = NexusUI

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Default Config
NexusUI.DefaultConfig = {
    -- Colors
    Background = Color3.fromRGB(15, 15, 20),
    Surface = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(0, 255, 136),
    Accent2 = Color3.fromRGB(255, 0, 128),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 170),
    Border = Color3.fromRGB(40, 40, 55),
    
    -- Dimensions
    WindowWidth = 600,
    WindowHeight = 400,
    SidebarWidth = 160,
    HeaderHeight = 45,
    
    -- Animation
    AnimationSpeed = 0.3,
    EasingStyle = Enum.EasingStyle.Quad,
    EasingDirection = Enum.EasingDirection.Out
}

--// Utility Functions
local function Tween(object, properties, config)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            config and config.Duration or NexusUI.DefaultConfig.AnimationSpeed,
            config and config.EasingStyle or NexusUI.DefaultConfig.EasingStyle,
            config and config.EasingDirection or NexusUI.DefaultConfig.EasingDirection
        ),
        properties
    )
    tween:Play()
    return tween
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or NexusUI.DefaultConfig.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

--// Window Class
NexusUI.Window = {}
NexusUI.Window.__index = NexusUI.Window

function NexusUI.Window.new(title, config)
    local self = setmetatable({}, NexusUI.Window)
    
    config = config or {}
    self.Config = setmetatable(config, {__index = NexusUI.DefaultConfig})
    self.Title = title or "Nexus UI"
    self.Tabs = {}
    self.ActiveTab = nil
    self.Minimized = false
    self.Visible = true
    
    --// Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "NexusUI_" .. title:gsub("%s+", "")
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    --// Create Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, self.Config.WindowWidth, 0, self.Config.WindowHeight)
    self.MainFrame.Position = UDim2.new(0.5, -self.Config.WindowWidth/2, 0.5, -self.Config.WindowHeight/2)
    self.MainFrame.BackgroundColor3 = self.Config.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    
    CreateCorner(self.MainFrame, 12)
    CreateStroke(self.MainFrame, self.Config.Border, 2)
    
    --// Create Header
    self:CreateHeader()
    
    --// Create Sidebar
    self:CreateSidebar()
    
    --// Setup Dragging
    self:SetupDragging()
    
    --// Parent to PlayerGui
    self.ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    --// Intro Animation
    self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(self.MainFrame, {Size = UDim2.new(0, self.Config.WindowWidth, 0, self.Config.WindowHeight)}, {
        Duration = 0.5,
        EasingStyle = Enum.EasingStyle.Back
    })
    
    return self
end

function NexusUI.Window:CreateHeader()
    --// Header Frame
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.Size = UDim2.new(1, 0, 0, self.Config.HeaderHeight)
    self.Header.BackgroundColor3 = self.Config.Surface
    self.Header.BorderSizePixel = 0
    self.Header.Parent = self.MainFrame
    
    CreateCorner(self.Header, 12)
    
    --// Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = self.Config.Text
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.Header
    
    --// Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = self.Config.Surface
    closeBtn.Text = "×"
    closeBtn.TextColor3 = self.Config.Accent2
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = self.Header
    CreateCorner(closeBtn, 6)
    CreateStroke(closeBtn, self.Config.Border, 1)
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    --// Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -75, 0.5, -15)
    minBtn.BackgroundColor3 = self.Config.Surface
    minBtn.Text = "−"
    minBtn.TextColor3 = self.Config.TextDim
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = self.Header
    CreateCorner(minBtn, 6)
    CreateStroke(minBtn, self.Config.Border, 1)
    
    minBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
end

function NexusUI.Window:CreateSidebar()
    --// Sidebar Frame
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0, self.Config.SidebarWidth, 1, -self.Config.HeaderHeight)
    self.Sidebar.Position = UDim2.new(0, 0, 0, self.Config.HeaderHeight)
    self.Sidebar.BackgroundColor3 = self.Config.Surface
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = self.MainFrame
    
    --// Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 1, 1, 0)
    divider.Position = UDim2.new(1, 0, 0, 0)
    divider.BackgroundColor3 = self.Config.Border
    divider.BorderSizePixel = 0
    divider.Parent = self.Sidebar
    
    --// Tab Container
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(1, -10, 1, -20)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 10)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.ScrollBarThickness = 2
    self.TabContainer.ScrollBarImageColor3 = self.Config.Accent
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContainer.Parent = self.Sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = self.TabContainer
end

function NexusUI.Window:SetupDragging()
    local dragging = false
    local dragStart, startPos
    
    self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    
    self.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function NexusUI.Window:AddTab(name, icon)
    local tab = {}
    tab.Name = name
    tab.Icon = icon or "⚡"
    tab.Elements = {}
    
    --// Tab Button
    tab.Button = Instance.new("TextButton")
    tab.Button.Name = name
    tab.Button.Size = UDim2.new(1, 0, 0, 40)
    tab.Button.BackgroundColor3 = self.Config.Background
    tab.Button.Text = ""
    tab.Button.Parent = self.TabContainer
    CreateCorner(tab.Button, 8)
    
    --// Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 10, 0.5, -15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = tab.Icon
    iconLabel.TextColor3 = self.Config.TextDim
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = tab.Button
    
    --// Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -50, 1, 0)
    textLabel.Position = UDim2.new(0, 45, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name
    textLabel.TextColor3 = self.Config.TextDim
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = tab.Button
    
    --// Indicator
    tab.Indicator = Instance.new("Frame")
    tab.Indicator.Name = "Indicator"
    tab.Indicator.Size = UDim2.new(0, 3, 0, 0)
    tab.Indicator.Position = UDim2.new(0, 0, 0.5, 0)
    tab.Indicator.AnchorPoint = Vector2.new(0, 0.5)
    tab.Indicator.BackgroundColor3 = self.Config.Accent
    tab.Indicator.BorderSizePixel = 0
    tab.Indicator.Parent = tab.Button
    CreateCorner(tab.Indicator, 2)
    
    --// Content Frame
    tab.Content = Instance.new("ScrollingFrame")
    tab.Content.Name = name .. "Content"
    tab.Content.Size = UDim2.new(
        1, 
        -(self.Config.SidebarWidth + 20), 
        1, 
        -(self.Config.HeaderHeight + 20)
    )
    tab.Content.Position = UDim2.new(0, self.Config.SidebarWidth + 10, 0, self.Config.HeaderHeight + 10)
    tab.Content.BackgroundTransparency = 1
    tab.Content.ScrollBarThickness = 4
    tab.Content.ScrollBarImageColor3 = self.Config.Accent
    tab.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.Content.Visible = false
    tab.Content.Parent = self.MainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.Parent = tab.Content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = tab.Content
    
    --// Tab Selection Logic
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    --// Hover Effects
    tab.Button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(35, 35, 50)})
            Tween(iconLabel, {TextColor3 = self.Config.Text})
        end
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tab.Button, {BackgroundColor3 = self.Config.Background})
            Tween(iconLabel, {TextColor3 = self.Config.TextDim})
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    --// Auto-select first tab
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    --// Return tab API
    return setmetatable(tab, {
        __index = {
            AddToggle = function(_, ...) return NexusUI.Elements.Toggle(tab.Content, ...) end,
            AddSlider = function(_, ...) return NexusUI.Elements.Slider(tab.Content, ...) end,
            AddButton = function(_, ...) return NexusUI.Elements.Button(tab.Content, ...) end,
            AddDropdown = function(_, ...) return NexusUI.Elements.Dropdown(tab.Content, ...) end,
            AddLabel = function(_, ...) return NexusUI.Elements.Label(tab.Content, ...) end,
            AddSeparator = function(_, ...) return NexusUI.Elements.Separator(tab.Content, ...) end
        }
    })
end

function NexusUI.Window:SelectTab(tab)
    if self.ActiveTab == tab then return end
    
    --// Deselect previous
    if self.ActiveTab then
        Tween(self.ActiveTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)})
        Tween(self.ActiveTab.Button, {BackgroundColor3 = self.Config.Background})
        self.ActiveTab.Content.Visible = false
        
        local prevIcon = self.ActiveTab.Button:FindFirstChildOfClass("TextLabel")
        if prevIcon then
            Tween(prevIcon, {TextColor3 = self.Config.TextDim})
        end
    end
    
    --// Select new
    self.ActiveTab = tab
    Tween(tab.Indicator, {Size = UDim2.new(0, 3, 0.6, 0)}, {EasingStyle = Enum.EasingStyle.Back})
    Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(40, 40, 60)})
    tab.Content.Visible = true
    
    local newIcon = tab.Button:FindFirstChildOfClass("TextLabel")
    if newIcon then
        Tween(newIcon, {TextColor3 = self.Config.Accent})
    end
end

function NexusUI.Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    
    if self.Minimized then
        Tween(self.MainFrame, {
            Size = UDim2.new(0, self.Config.WindowWidth, 0, self.Config.HeaderHeight)
        }, {EasingStyle = Enum.EasingStyle.Back})
    else
        Tween(self.MainFrame, {
            Size = UDim2.new(0, self.Config.WindowWidth, 0, self.Config.WindowHeight)
        }, {EasingStyle = Enum.EasingStyle.Back})
    end
end

function NexusUI.Window:SetVisible(visible)
    self.Visible = visible
    self.MainFrame.Visible = visible
end

function NexusUI.Window:Destroy()
    Tween(self.MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, {Duration = 0.3})
    wait(0.3)
    self.ScreenGui:Destroy()
end

--// UI Elements
NexusUI.Elements = {}

function NexusUI.Elements.Toggle(parent, text, default, callback)
    local toggle = {}
    toggle.Value = default or false
    toggle.Callback = callback or function() end
    
    --// Frame
    toggle.Frame = Instance.new("Frame")
    toggle.Frame.Name = text .. "Toggle"
    toggle.Frame.Size = UDim2.new(1, 0, 0, 50)
    toggle.Frame.BackgroundColor3 = NexusUI.DefaultConfig.Background
    toggle.Frame.BorderSizePixel = 0
    toggle.Frame.Parent = parent
    CreateCorner(toggle.Frame, 10)
    CreateStroke(toggle.Frame, NexusUI.DefaultConfig.Border, 1)
    
    --// Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = NexusUI.DefaultConfig.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle.Frame
    
    --// Status
    toggle.StatusLabel = Instance.new("TextLabel")
    toggle.StatusLabel.Size = UDim2.new(0, 50, 0, 20)
    toggle.StatusLabel.Position = UDim2.new(0, 15, 0, 30)
    toggle.StatusLabel.BackgroundTransparency = 1
    toggle.StatusLabel.Text = toggle.Value and "ON" or "OFF"
    toggle.StatusLabel.TextColor3 = toggle.Value and NexusUI.DefaultConfig.Accent or NexusUI.DefaultConfig.TextDim
    toggle.StatusLabel.TextSize = 11
    toggle.StatusLabel.Font = Enum.Font.GothamBold
    toggle.StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggle.StatusLabel.Parent = toggle.Frame
    
    --// Switch
    local switch = Instance.new("Frame")
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 50, 0, 26)
    switch.Position = UDim2.new(1, -60, 0.5, -13)
    switch.BackgroundColor3 = toggle.Value and NexusUI.DefaultConfig.Accent or NexusUI.DefaultConfig.Border
    switch.BorderSizePixel = 0
    switch.Parent = toggle.Frame
    CreateCorner(switch, 13)
    
    --// Knob
    toggle.Knob = Instance.new("Frame")
    toggle.Knob.Name = "Knob"
    toggle.Knob.Size = UDim2.new(0, 22, 0, 22)
    toggle.Knob.Position = toggle.Value and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    toggle.Knob.BackgroundColor3 = NexusUI.DefaultConfig.Text
    toggle.Knob.BorderSizePixel = 0
    toggle.Knob.Parent = switch
    CreateCorner(toggle.Knob, 11)
    
    --// Click Area
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = toggle.Frame
    
    --// Methods
    function toggle:Set(value)
        toggle.Value = value
        toggle.StatusLabel.Text = value and "ON" or "OFF"
        toggle.StatusLabel.TextColor3 = value and NexusUI.DefaultConfig.Accent or NexusUI.DefaultConfig.TextDim
        
        Tween(switch, {BackgroundColor3 = value and NexusUI.DefaultConfig.Accent or NexusUI.DefaultConfig.Border})
        Tween(toggle.Knob, {
            Position = value and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        }, {EasingStyle = Enum.EasingStyle.Back})
        
        if toggle.Callback then
            toggle.Callback(value)
        end
    end
    
    function toggle:Toggle()
        toggle:Set(not toggle.Value)
    end
    
    --// Events
    clickArea.MouseButton1Click:Connect(function()
        toggle:Toggle()
    end)
    
    clickArea.MouseEnter:Connect(function()
        Tween(toggle.Frame, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)})
    end)
    
    clickArea.MouseLeave:Connect(function()
        Tween(toggle.Frame, {BackgroundColor3 = NexusUI.DefaultConfig.Background})
    end)
    
    return toggle
end

function NexusUI.Elements.Slider(parent, text, min, max, default, callback)
    local slider = {}
    slider.Min = min or 0
    slider.Max = max or 100
    slider.Value = default or slider.Min
    slider.Callback = callback or function() end
    
    --// Frame
    slider.Frame = Instance.new("Frame")
    slider.Frame.Name = text .. "Slider"
    slider.Frame.Size = UDim2.new(1, 0, 0, 70)
    slider.Frame.BackgroundColor3 = NexusUI.DefaultConfig.Background
    slider.Frame.BorderSizePixel = 0
    slider.Frame.Parent = parent
    CreateCorner(slider.Frame, 10)
    CreateStroke(slider.Frame, NexusUI.DefaultConfig.Border, 1)
    
    --// Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 0, 25)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = NexusUI.DefaultConfig.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = slider.Frame
    
    --// Value Display
    slider.ValueLabel = Instance.new("TextLabel")
    slider.ValueLabel.Size = UDim2.new(0, 50, 0, 25)
    slider.ValueLabel.Position = UDim2.new(1, -65, 0, 5)
    slider.ValueLabel.BackgroundColor3 = NexusUI.DefaultConfig.Surface
    slider.ValueLabel.Text = tostring(slider.Value)
    slider.ValueLabel.TextColor3 = NexusUI.DefaultConfig.Accent
    slider.ValueLabel.TextSize = 12
    slider.ValueLabel.Font = Enum.Font.GothamBold
    slider.ValueLabel.Parent = slider.Frame
    CreateCorner(slider.ValueLabel, 4)
    
    --// Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -30, 0, 6)
    track.Position = UDim2.new(0, 15, 0, 45)
    track.BackgroundColor3 = NexusUI.DefaultConfig.Border
    track.BorderSizePixel = 0
    track.Parent = slider.Frame
    CreateCorner(track, 3)
    
    --// Fill
    slider.Fill = Instance.new("Frame")
    slider.Fill.Name = "Fill"
    slider.Fill.Size = UDim2.new((slider.Value - slider.Min)/(slider.Max - slider.Min), 0, 1, 0)
    slider.Fill.BackgroundColor3 = NexusUI.DefaultConfig.Accent
    slider.Fill.BorderSizePixel = 0
    slider.Fill.Parent = track
    CreateCorner(slider.Fill, 3)
    
    --// Thumb
    slider.Thumb = Instance.new("Frame")
    slider.Thumb.Name = "Thumb"
    slider.Thumb.Size = UDim2.new(0, 16, 0, 16)
    slider.Thumb.Position = UDim2.new((slider.Value - slider.Min)/(slider.Max - slider.Min), -8, 0.5, -8)
    slider.Thumb.BackgroundColor3 = NexusUI.DefaultConfig.Text
    slider.Thumb.BorderSizePixel = 0
    slider.Thumb.Parent = track
    CreateCorner(slider.Thumb, 8)
    
    --// Methods
    function slider:Set(value)
        value = math.clamp(value, slider.Min, slider.Max)
        slider.Value = value
        slider.ValueLabel.Text = tostring(math.floor(value))
        
        local percent = (value - slider.Min) / (slider.Max - slider.Min)
        Tween(slider.Fill, {Size = UDim2.new(percent, 0, 1, 0)})
        Tween(slider.Thumb, {Position = UDim2.new(percent, -8, 0.5, -8)})
        
        if slider.Callback then
            slider.Callback(value)
        end
    end
    
    --// Dragging Logic
    local dragging = false
    
    local function update(input)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = slider.Min + (slider.Max - slider.Min) * percent
        slider:Set(value)
    end
    
    slider.Thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Tween(slider.Thumb, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(slider.Thumb.Position.X.Scale, -10, 0.5, -10)})
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            Tween(slider.Thumb, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(slider.Thumb.Position.X.Scale, -8, 0.5, -8)})
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(input)
        end
    end)
    
    return slider
end

function NexusUI.Elements.Button(parent, text, callback)
    local btn = {}
    btn.Callback = callback or function() end
    
    --// Frame
    btn.Frame = Instance.new("TextButton")
    btn.Frame.Name = text .. "Button"
    btn.Frame.Size = UDim2.new(1, 0, 0, 45)
    btn.Frame.BackgroundColor3 = NexusUI.DefaultConfig.Surface
    btn.Frame.Text = text
    btn.Frame.TextColor3 = NexusUI.DefaultConfig.Text
    btn.Frame.TextSize = 14
    btn.Frame.Font = Enum.Font.GothamBold
    btn.Frame.Parent = parent
    CreateCorner(btn.Frame, 10)
    CreateStroke(btn.Frame, NexusUI.DefaultConfig.Accent, 1)
    
    --// Hover & Click Effects
    btn.Frame.MouseEnter:Connect(function()
        Tween(btn.Frame, {BackgroundColor3 = NexusUI.DefaultConfig.Accent})
        btn.Frame.TextColor3 = NexusUI.DefaultConfig.Background
    end)
    
    btn.Frame.MouseLeave:Connect(function()
        Tween(btn.Frame, {BackgroundColor3 = NexusUI.DefaultConfig.Surface})
        btn.Frame.TextColor3 = NexusUI.DefaultConfig.Text
    end)
    
    btn.Frame.MouseButton1Click:Connect(function()
        --// Click Animation
        Tween(btn.Frame, {Size = UDim2.new(0.95, 0, 0, 45)}, {Duration = 0.1})
        wait(0.1)
        Tween(btn.Frame, {Size = UDim2.new(1, 0, 0, 45)}, {EasingStyle = Enum.EasingStyle.Back})
        
        btn.Callback()
    end)
    
    return btn
end

function NexusUI.Elements.Dropdown(parent, text, options, callback)
    local dropdown = {}
    dropdown.Options = options or {}
    dropdown.Selected = options[1] or "Select..."
    dropdown.Callback = callback or function() end
    dropdown.Expanded = false
    
    --// Frame
    dropdown.Frame = Instance.new("Frame")
    dropdown.Frame.Name = text .. "Dropdown"
    dropdown.Frame.Size = UDim2.new(1, 0, 0, 50)
    dropdown.Frame.BackgroundColor3 = NexusUI.DefaultConfig.Background
    dropdown.Frame.BorderSizePixel = 0
    dropdown.Frame.ClipsDescendants = true
    dropdown.Frame.Parent = parent
    CreateCorner(dropdown.Frame, 10)
    CreateStroke(dropdown.Frame, NexusUI.DefaultConfig.Border, 1)
    
    --// Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 50)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = NexusUI.DefaultConfig.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = dropdown.Frame
    
    --// Selected Value
    dropdown.SelectedLabel = Instance.new("TextLabel")
    dropdown.SelectedLabel.Size = UDim2.new(0, 120, 0, 30)
    dropdown.SelectedLabel.Position = UDim2.new(1, -140, 0, 10)
    dropdown.SelectedLabel.BackgroundColor3 = NexusUI.DefaultConfig.Surface
    dropdown.SelectedLabel.Text = dropdown.Selected
    dropdown.SelectedLabel.TextColor3 = NexusUI.DefaultConfig.Accent
    dropdown.SelectedLabel.TextSize = 12
    dropdown.SelectedLabel.Font = Enum.Font.GothamBold
    dropdown.SelectedLabel.Parent = dropdown.Frame
    CreateCorner(dropdown.SelectedLabel, 6)
    
    --// Arrow
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 30)
    arrow.Position = UDim2.new(1, -25, 0, 10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = NexusUI.DefaultConfig.TextDim
    arrow.TextSize = 12
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropdown.Frame
    
    --// Options Container
    dropdown.OptionsFrame = Instance.new("Frame")
    dropdown.OptionsFrame.Name = "Options"
    dropdown.OptionsFrame.Size = UDim2.new(1, 0, 0, #dropdown.Options * 35)
    dropdown.OptionsFrame.Position = UDim2.new(0, 0, 0, 50)
    dropdown.OptionsFrame.BackgroundColor3 = NexusUI.DefaultConfig.Background
    dropdown.OptionsFrame.BorderSizePixel = 0
    dropdown.OptionsFrame.Visible = false
    dropdown.OptionsFrame.Parent = dropdown.Frame
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = dropdown.OptionsFrame
    
    --// Create Options
    for i, option in ipairs(dropdown.Options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 35)
        optionBtn.BackgroundColor3 = i % 2 == 0 and NexusUI.DefaultConfig.Background or Color3.fromRGB(30, 30, 40)
        optionBtn.Text = option
        optionBtn.TextColor3 = NexusUI.DefaultConfig.Text
        optionBtn.TextSize = 13
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.Parent = dropdown.OptionsFrame
        
        optionBtn.MouseButton1Click:Connect(function()
            dropdown:Set(option)
        end)
    end
    
    --// Methods
    function dropdown:Set(value)
        dropdown.Selected = value
        dropdown.SelectedLabel.Text = value
        dropdown:Collapse()
        
        if dropdown.Callback then
            dropdown.Callback(value)
        end
    end
    
    function dropdown:Expand()
        dropdown.Expanded = true
        dropdown.OptionsFrame.Visible = true
        Tween(dropdown.Frame, {Size = UDim2.new(1, 0, 0, 50 + dropdown.OptionsFrame.Size.Y.Offset)})
        Tween(arrow, {Rotation = 180})
    end
    
    function dropdown:Collapse()
        dropdown.Expanded = false
        Tween(dropdown.Frame, {Size = UDim2.new(1, 0, 0, 50)})
        Tween(arrow, {Rotation = 0})
        wait(0.3)
        dropdown.OptionsFrame.Visible = false
    end
    
    function dropdown:Toggle()
        if dropdown.Expanded then
            dropdown:Collapse()
        else
            dropdown:Expand()
        end
    end
    
    --// Click Area
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 0, 50)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = dropdown.Frame
    
    clickArea.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    return dropdown
end

function NexusUI.Elements.Label(parent, text, options)
    options = options or {}
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, options.Height or 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = options.Color or NexusUI.DefaultConfig.Text
    label.TextSize = options.Size or 14
    label.Font = options.Bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = options.Alignment or Enum.TextXAlignment.Left
    label.TextWrapped = options.Wrapped or false
    label.Parent = parent
    
    return label
end

function NexusUI.Elements.Separator(parent)
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 0)
    sep.BackgroundColor3 = NexusUI.DefaultConfig.Border
    sep.BorderSizePixel = 0
    sep.Parent = parent
    
    return sep
end

--// Watermark & Stats (Optional Features)
function NexusUI.Window:AddWatermark(text)
    local watermark = Instance.new("TextLabel")
    watermark.Name = "Watermark"
    watermark.Size = UDim2.new(0, 200, 0, 30)
    watermark.Position = UDim2.new(0, 10, 0, 10)
    watermark.BackgroundColor3 = self.Config.Background
    watermark.BackgroundTransparency = 0.3
    watermark.Text = text or self.Title
    watermark.TextColor3 = self.Config.Accent
    watermark.TextSize = 14
    watermark.Font = Enum.Font.GothamBold
    watermark.Parent = self.ScreenGui
    CreateCorner(watermark, 6)
    CreateStroke(watermark, self.Config.Accent, 1)
    
    return watermark
end

function NexusUI.Window:AddStats()
    local stats = {}
    
    local frame = Instance.new("Frame")
    frame.Name = "Stats"
    frame.Size = UDim2.new(0, 150, 0, 60)
    frame.Position = UDim2.new(1, -160, 0, 10)
    frame.BackgroundColor3 = self.Config.Background
    frame.BackgroundTransparency = 0.3
    frame.Parent = self.ScreenGui
    CreateCorner(frame, 10)
    CreateStroke(frame, self.Config.Border, 1)
    
    stats.FPSLabel = Instance.new("TextLabel")
    stats.FPSLabel.Size = UDim2.new(1, -10, 0, 25)
    stats.FPSLabel.Position = UDim2.new(0, 5, 0, 5)
    stats.FPSLabel.BackgroundTransparency = 1
    stats.FPSLabel.Text = "FPS: 60"
    stats.FPSLabel.TextColor3 = self.Config.Accent
    stats.FPSLabel.TextSize = 14
    stats.FPSLabel.Font = Enum.Font.GothamBold
    stats.FPSLabel.Parent = frame
    
    stats.PingLabel = Instance.new("TextLabel")
    stats.PingLabel.Size = UDim2.new(1, -10, 0, 25)
    stats.PingLabel.Position = UDim2.new(0, 5, 0, 30)
    stats.PingLabel.BackgroundTransparency = 1
    stats.PingLabel.Text = "Ping: 24ms"
    stats.PingLabel.TextColor3 = self.Config.Accent2
    stats.PingLabel.TextSize = 14
    stats.PingLabel.Font = Enum.Font.GothamBold
    stats.PingLabel.Parent = frame
    
    --// Update Loop
    local fps = 0
    local lastUpdate = tick()
    
    RunService.RenderStepped:Connect(function()
        fps = fps + 1
        if tick() - lastUpdate >= 1 then
            stats.FPSLabel.Text = "FPS: " .. fps
            fps = 0
            lastUpdate = tick()
            stats.PingLabel.Text = "Ping: " .. math.random(15, 45) .. "ms"
        end
    end)
    
    return stats
end

--// Keybind System
function NexusUI.Window:SetKeybind(keyCode)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == keyCode then
            self:SetVisible(not self.Visible)
        end
    end)
end

return NexusUI
