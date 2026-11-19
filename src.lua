--// Atlas UI v3 - LocalScript
--// Emplacement : StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer

local ATLAS_VERSION = "1.0 (release)"
local KEY_DURATION = 2 * 3600 -- 2h

--------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------
local theme = {
	Background = Color3.fromRGB(18, 18, 18),
	Element = Color3.fromRGB(30, 30, 30),
	Gutter = Color3.fromRGB(24, 24, 24),
	Stroke = Color3.fromRGB(52, 52, 52),
	Text = Color3.fromRGB(255, 255, 255),
	Hover = Color3.fromRGB(210, 210, 210),
	Inactive = Color3.fromRGB(150, 150, 150),
	SubText = Color3.fromRGB(150, 150, 150),
	Line = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(88, 101, 242),
}
local DEFAULT_ACCENT = Color3.fromRGB(88, 101, 242)

local accentObjects = {}
local accentCallbacks = {}
local connections = {}

local function track(conn)
	table.insert(connections, conn)
	return conn
end

local function bindAccent(inst, prop)
	table.insert(accentObjects, { inst, prop })
	inst[prop] = theme.Accent
end

local function setAccent(color)
	theme.Accent = color
	for _, v in ipairs(accentObjects) do
		if v[1] and v[1].Parent then
			TweenService:Create(v[1], TweenInfo.new(0.25), { [v[2]] = color }):Play()
		end
	end
	for _, cb in ipairs(accentCallbacks) do
		cb()
	end
end

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local orderCounter = 0
local function ord()
	orderCounter += 1
	return orderCounter
end

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function stroke(parent, color, thickness)
	return make("UIStroke", {
		Color = color or theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function label(parent, text, size, props)
	local l = make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = size,
	}, parent)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

--------------------------------------------------------------------
-- SCREEN GUI + FENÊTRE (angles droits)
--------------------------------------------------------------------
local FULL_SIZE = UDim2.new(0, 485, 0, 315)
local TOPBAR_HEIGHT = 62
local LINE_HEIGHT = 3
local MIN_SIZE = UDim2.new(0, 485, 0, TOPBAR_HEIGHT + LINE_HEIGHT)
local FINAL_POS = UDim2.new(0.5, -242, 0.5, -157)

local gui = make("ScreenGui", {
	Name = "AtlasUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

gui.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
end)

local main = make("Frame", {
	Name = "Main",
	Position = FINAL_POS + UDim2.new(0, 0, 0, 16),
	Size = FULL_SIZE,
	BackgroundColor3 = theme.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
stroke(main, theme.Stroke, 1)
local mainScale = make("UIScale", { Scale = 1 }, main)

local refs = {}
local keybind = { key = Enum.KeyCode.RightShift, listening = false, refresh = function() end }

--------------------------------------------------------------------
-- NOTIFICATIONS (toast)
--------------------------------------------------------------------
local notificationsEnabled = true
local function notify(text)
	if not notificationsEnabled then return end
	local toast = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 50),
		Size = UDim2.new(0, 270, 0, 34),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, main)
	stroke(toast)
	make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 51,
	}, toast)
	label(toast, text, 13, {
		Position = UDim2.new(0, 3, 0, 0),
		Size = UDim2.new(1, -3, 1, 0),
		ZIndex = 51,
		Font = Enum.Font.GothamMedium,
	})
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
		Position = UDim2.new(0.5, 0, 1, -14),
	}):Play()
	task.delay(2, function()
		local t = TweenService:Create(toast, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 1, 50),
		})
		t:Play()
		t.Completed:Wait()
		toast:Destroy()
	end)
end

--------------------------------------------------------------------
-- BARRE DU HAUT
--------------------------------------------------------------------
local topbar = make("Frame", {
	Name = "Topbar",
	Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
	BackgroundTransparency = 1,
}, main)

make("Frame", {
	Name = "Separator",
	Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT),
	Size = UDim2.new(1, 0, 0, LINE_HEIGHT),
	BackgroundColor3 = theme.Line,
	BorderSizePixel = 0,
}, main)

-- Soulignement animé de l'onglet actif (par-dessus la ligne blanche)
local underline = make("Frame", {
	Name = "TabUnderline",
	Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT),
	Size = UDim2.new(0, 0, 0, LINE_HEIGHT),
	BorderSizePixel = 0,
	ZIndex = 3,
}, main)
bindAccent(underline, "BackgroundColor3")

local tabsHolder = make("Frame", {
	Name = "Tabs",
	Position = UDim2.new(0, 21, 0, 0),
	Size = UDim2.new(1, -140, 1, 0),
	BackgroundTransparency = 1,
}, topbar)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 26),
}, tabsHolder)

local controls = make("Frame", {
	Name = "Controls",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -20, 0.5, 0),
	Size = UDim2.new(0, 60, 0, 36),
	BackgroundTransparency = 1,
}, topbar)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 14),
}, controls)

local function controlButton(text, order, hoverColor)
	local b = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(0, 20, 0, 36),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
	}, controls)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { TextColor3 = hoverColor }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { TextColor3 = theme.Text }):Play()
	end)
	return b
end

local minimizeBtn = controlButton("-", 1, theme.SubText)
local closeBtn = controlButton("X", 2, Color3.fromRGB(237, 66, 69))

local content = make("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT + LINE_HEIGHT + 4),
	Size = UDim2.new(1, 0, 1, -(TOPBAR_HEIGHT + LINE_HEIGHT + 4)),
	BackgroundTransparency = 1,
}, main)

--------------------------------------------------------------------
-- DÉPLACEMENT (en tirant la barre du haut)
--------------------------------------------------------------------
local draggable = true
do
	local dragging, dragStart, startPos
	track(topbar.InputBegan:Connect(function(input)
		if not draggable then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

--------------------------------------------------------------------
-- ONGLETS
--------------------------------------------------------------------
local tabNames = { "Home", "Editor", "Hub", "Settings" }
local pages, tabButtons = {}, {}
local currentTab
local minimized = false

local function moveUnderline(name, instant)
	local b = tabButtons[name]
	if not b or b.AbsoluteSize.X == 0 then return end
	local s = mainScale.Scale
	local x = (b.AbsolutePosition.X - main.AbsolutePosition.X) / s
	local w = b.AbsoluteSize.X / s
	local pos = UDim2.new(0, x, 0, TOPBAR_HEIGHT)
	local size = UDim2.new(0, w, 0, LINE_HEIGHT)
	if instant then
		underline.Position = pos
		underline.Size = size
	else
		TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
			Position = pos,
			Size = size,
		}):Play()
	end
end

local function setMinimized(state)
	minimized = state
	if state then
		content.Visible = false
		TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = MIN_SIZE }):Play()
	else
		TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = FULL_SIZE }):Play()
		task.delay(0.15, function()
			if not minimized then content.Visible = true end
		end)
	end
end

local function selectTab(name)
	if minimized then setMinimized(false) end
	if currentTab == name then return end
	local first = currentTab == nil
	currentTab = name
	for _, n in ipairs(tabNames) do
		local active = (n == name)
		pages[n].Visible = active
		TweenService:Create(tabButtons[n], TweenInfo.new(0.2), {
			TextColor3 = active and theme.Text or theme.Inactive,
		}):Play()
	end
	if not first then
		pages[name].Position = UDim2.new(0, 0, 0, 10)
		TweenService:Create(pages[name], TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
	end
	moveUnderline(name, first)
end

for i, name in ipairs(tabNames) do
	pages[name] = make("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, content)

	local b = make("TextButton", {
		Name = name,
		LayoutOrder = i,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = theme.Inactive,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
	}, tabsHolder)
	tabButtons[name] = b

	b.MouseEnter:Connect(function()
		if currentTab ~= name then
			TweenService:Create(b, TweenInfo.new(0.15), { TextColor3 = theme.Hover }):Play()
		end
	end)
	b.MouseLeave:Connect(function()
		if currentTab ~= name then
			TweenService:Create(b, TweenInfo.new(0.15), { TextColor3 = theme.Inactive }):Play()
		end
	end)
	b.MouseButton1Click:Connect(function() selectTab(name) end)

	-- Repositionne le soulignement quand la mise en page change
	b:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if currentTab == name then moveUnderline(name, true) end
	end)
end

minimizeBtn.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

--------------------------------------------------------------------
-- WIDGETS
--------------------------------------------------------------------
local function makeButton(parent, text, size, pos, accent)
	local b = make("TextButton", {
		LayoutOrder = ord(),
		Size = size,
		Position = pos or UDim2.new(),
		BackgroundColor3 = theme.Element,
		Text = text,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
	if accent then
		bindAccent(b, "BackgroundColor3")
	else
		stroke(b)
	end
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.25 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	end)
	return b
end

local function section(parent, text)
	return label(parent, text, 11, {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.SubText,
	})
end

local function makeToggle(parent, text, default, callback)
	local row = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 38),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
	}, parent)
	stroke(row)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local trackBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 20),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		BorderSizePixel = 0,
	}, row)
	local knob = make("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
	}, trackBtn)

	local state = default
	local function render()
		TweenService:Create(knob, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		}):Play()
		TweenService:Create(trackBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = state and theme.Accent or Color3.fromRGB(55, 55, 55),
		}):Play()
	end
	render()
	table.insert(accentCallbacks, render)

	trackBtn.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)

	-- Retourne un setter (utilisé par "Reset to default")
	return function(v)
		state = v
		render()
		callback(v)
	end
end

local function makeSlider(parent, text, min, max, default, callback)
	local row = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 52),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
	}, parent)
	stroke(row)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(0.6, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local valueLabel = label(row, "", 13, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.new(0.3, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = theme.SubText,
	})
	local bar = make("Frame", {
		Position = UDim2.new(0, 14, 0, 36),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		BorderSizePixel = 0,
	}, row)
	local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, bar)
	bindAccent(fill, "BackgroundColor3")
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 8, 0, 16),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
	}, bar)

	local function set(alpha)
		alpha = math.clamp(alpha, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		local v = math.floor((min + (max - min) * alpha) * 100 + 0.5) / 100
		valueLabel.Text = tostring(v)
		callback(v)
	end
	set((default - min) / (max - min))

	local sliding = false
	local function update(x)
		set((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
	end
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(i.Position.X)
		end
	end)
	track(UserInputService.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end))

	-- Retourne un setter par valeur (utilisé par "Reset to default")
	return function(v)
		set((v - min) / (max - min))
	end
end

--------------------------------------------------------------------
-- HOME
--------------------------------------------------------------------
do
	local home = pages.Home

	local holder = make("Frame", {
		Position = UDim2.new(0, 21, 0, 12),
		Size = UDim2.new(1, -42, 0, 78),
		BackgroundTransparency = 1,
	}, home)
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, holder)

	local function line(text, order, size)
		return label(holder, text, size, {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	line("Welcome, " .. player.Name, 1, 20)
	local keyLabel = line("Key status: 2h left", 2, 19)
	line("Atlas version: " .. ATLAS_VERSION, 3, 19)

	-- Barre de progression de la clé
	local barTrack = make("Frame", {
		Position = UDim2.new(0, 21, 0, 98),
		Size = UDim2.new(1, -42, 0, 6),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		BorderSizePixel = 0,
	}, home)
	local barFill = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0 }, barTrack)
	bindAccent(barFill, "BackgroundColor3")

	-- Tuiles de stats
	local stats = make("Frame", {
		Position = UDim2.new(0, 21, 0, 122),
		Size = UDim2.new(1, -42, 0, 66),
		BackgroundTransparency = 1,
	}, home)
	refs.stats = stats
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, stats)

	local function tile(title, order)
		local t = make("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1 / 3, -6, 1, 0),
			BackgroundColor3 = theme.Element,
			BorderSizePixel = 0,
		}, stats)
		stroke(t)
		local accentBar = make("Frame", {
			Size = UDim2.new(0, 2, 1, 0),
			BorderSizePixel = 0,
		}, t)
		bindAccent(accentBar, "BackgroundColor3")
		local v = label(t, "--", 22, {
			Position = UDim2.new(0, 14, 0, 10),
			Size = UDim2.new(1, -24, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label(t, title, 11, {
			Position = UDim2.new(0, 14, 0, 38),
			Size = UDim2.new(1, -24, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.SubText,
			Font = Enum.Font.GothamMedium,
		})
		return v
	end

	local fpsLabel = tile("FPS", 1)
	local pingLabel = tile("PING", 2)
	local plrLabel = tile("PLAYERS", 3)

	local frames, last = 0, os.clock()
	track(RunService.RenderStepped:Connect(function()
		frames += 1
	end))
	task.spawn(function()
		while gui.Parent do
			task.wait(0.5)
			local now = os.clock()
			fpsLabel.Text = tostring(math.floor(frames / (now - last) + 0.5))
			frames, last = 0, now
			local ok, ping = pcall(function()
				return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			pingLabel.Text = ok and (tostring(math.floor(ping)) .. " ms") or "-- ms"
			plrLabel.Text = tostring(#Players:GetPlayers())
		end
	end)

	-- Compte à rebours de la clé
	local endTime = os.time() + KEY_DURATION
	task.spawn(function()
		while gui.Parent do
			local remaining = math.max(0, endTime - os.time())
			if remaining >= 3600 then
				keyLabel.Text = ("Key status: %dh left"):format(math.ceil(remaining / 3600))
			elseif remaining > 0 then
				keyLabel.Text = ("Key status: %dm left"):format(math.ceil(remaining / 60))
			else
				keyLabel.Text = "Key status: expired"
			end
			barFill.Size = UDim2.new(remaining / KEY_DURATION, 0, 1, 0)
			task.wait(1)
		end
	end)
end

--------------------------------------------------------------------
-- EDITOR
--------------------------------------------------------------------
do
	local editor = pages.Editor

	local box = make("Frame", {
		Position = UDim2.new(0, 20, 0, 4),
		Size = UDim2.new(1, -40, 1, -60),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, editor)
	stroke(box)

	local gutter = make("Frame", {
		Size = UDim2.new(0, 36, 1, 0),
		BackgroundColor3 = theme.Gutter,
		BorderSizePixel = 0,
	}, box)

	local lines = make("TextLabel", {
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, -8, 1, -16),
		BackgroundTransparency = 1,
		Text = "1",
		TextColor3 = theme.SubText,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, gutter)

	local input = make("TextBox", {
		Position = UDim2.new(0, 44, 0, 8),
		Size = UDim2.new(1, -52, 1, -16),
		BackgroundTransparency = 1,
		Text = "-- Écris ton code ici\nprint(\"Hello Atlas\")",
		TextColor3 = theme.Text,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		MultiLine = true,
		ClearTextOnFocus = false,
		TextWrapped = false,
		PlaceholderText = "Écris ton code...",
		PlaceholderColor3 = theme.SubText,
	}, box)

	local status = label(editor, "", 12, {
		Position = UDim2.new(0, 22, 1, -46),
		Size = UDim2.new(0.45, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.SubText,
		Font = Enum.Font.GothamMedium,
	})

	local function updateInfo()
		local count = select(2, input.Text:gsub("\n", "")) + 1
		local t = {}
		for i = 1, count do t[i] = tostring(i) end
		lines.Text = table.concat(t, "\n")
		status.Text = ("Lines: %d   |   Chars: %d"):format(count, #input.Text)
	end
	input:GetPropertyChangedSignal("Text"):Connect(updateInfo)
	updateInfo()

	local clear = makeButton(editor, "Clear", UDim2.new(0, 80, 0, 32), UDim2.new(1, -20 - 80 - 8 - 90, 1, -46))
	local run = makeButton(editor, "Execute", UDim2.new(0, 90, 0, 32), UDim2.new(1, -20 - 90, 1, -46), true)

	clear.MouseButton1Click:Connect(function()
		input.Text = ""
		status.Text = "Editor cleared"
	end)
	run.MouseButton1Click:Connect(function()
		-- Exécution simulée (démo) : rien n'est réellement lancé
		status.Text = "Executed (demo)"
		notify("Script executed (demo)")
	end)
end

--------------------------------------------------------------------
-- HUB (faux script hub)
--------------------------------------------------------------------
do
	local hub = pages.Hub

	local search = make("TextBox", {
		Position = UDim2.new(0, 20, 0, 4),
		Size = UDim2.new(1, -40, 0, 30),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Search scripts...",
		PlaceholderColor3 = theme.SubText,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, hub)
	stroke(search)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, search)

	-- Filtres par catégorie
	local categories = { "All", "Universal", "Games" }
	local currentCat = "All"
	local chips = {}

	local chipHolder = make("Frame", {
		Position = UDim2.new(0, 20, 0, 40),
		Size = UDim2.new(0.7, 0, 0, 24),
		BackgroundTransparency = 1,
	}, hub)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, chipHolder)

	local count = label(hub, "", 12, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 40),
		Size = UDim2.new(0, 100, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = theme.SubText,
		Font = Enum.Font.GothamMedium,
	})

	local list = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 72),
		Size = UDim2.new(1, -40, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, hub)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local fakeScripts = {
		{ "Fly Mode", "by Nova", "12.4k", "Universal" },
		{ "Speed Boost", "by Kairo", "8.1k", "Universal" },
		{ "ESP Universal", "by Zephyr", "21.7k", "Universal" },
		{ "Noclip Plus", "by Orion", "5.9k", "Universal" },
		{ "Auto Farm Simulator", "by Lyra", "15.3k", "Games" },
		{ "Teleport Menu", "by Atlas Team", "9.8k", "Universal" },
		{ "Infinite Jump", "by Vega", "30.2k", "Universal" },
		{ "Obby Skipper", "by Sora", "7.2k", "Games" },
		{ "Tycoon Booster", "by Ember", "4.6k", "Games" },
		{ "Night Vision", "by Echo", "3.4k", "Universal" },
	}

	local rows = {}

	local function applyFilter()
		local q = search.Text:lower()
		local shown = 0
		for _, r in ipairs(rows) do
			local ok = (currentCat == "All" or r.cat == currentCat)
				and (q == "" or r.name:find(q, 1, true) ~= nil)
			r.frame.Visible = ok
			if ok then shown += 1 end
		end
		count.Text = tostring(shown) .. (shown == 1 and " script" or " scripts")
	end

	local function renderChips()
		for name, chip in pairs(chips) do
			TweenService:Create(chip, TweenInfo.new(0.2), {
				BackgroundColor3 = (name == currentCat) and theme.Accent or theme.Element,
			}):Play()
		end
	end
	table.insert(accentCallbacks, renderChips)

	for i, cat in ipairs(categories) do
		local chip = make("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(0, 74, 1, 0),
			BackgroundColor3 = theme.Element,
			BorderSizePixel = 0,
			Text = cat,
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			AutoButtonColor = false,
		}, chipHolder)
		stroke(chip)
		chips[cat] = chip
		chip.MouseButton1Click:Connect(function()
			currentCat = cat
			renderChips()
			applyFilter()
		end)
	end

	for i, s in ipairs(fakeScripts) do
		local row = make("Frame", {
			Size = UDim2.new(1, -8, 0, 46),
			BackgroundColor3 = theme.Element,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, list)
		stroke(row)
		local accentBar = make("Frame", { Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0 }, row)
		bindAccent(accentBar, "BackgroundColor3")
		label(row, s[1], 14, {
			Position = UDim2.new(0, 14, 0, 5),
			Size = UDim2.new(0.6, 0, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label(row, s[2] .. "  •  " .. s[3] .. " uses  •  " .. s[4], 11, {
			Position = UDim2.new(0, 14, 0, 24),
			Size = UDim2.new(0.7, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.SubText,
			Font = Enum.Font.Gotham,
		})
		local load = makeButton(row, "Load", UDim2.new(0, 64, 0, 28), UDim2.new(1, -76, 0.5, -14), true)
		local busy = false
		load.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			load.Text = "..."
			task.wait(0.6)
			load.Text = "Loaded"
			notify(s[1] .. " loaded (fake)")
			task.wait(1.5)
			load.Text = "Load"
			busy = false
		end)
		rows[i] = { frame = row, name = s[1]:lower(), cat = s[4] }
	end

	search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
	renderChips()
	applyFilter()
end

--------------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------------
do
	local settings = pages.Settings

	local scroll = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 4),
		Size = UDim2.new(1, -40, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, settings)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	----------------------------------------------------------------
	section(scroll, "APPEARANCE")

	local colorRow = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
	}, scroll)
	stroke(colorRow)
	label(colorRow, "Accent color", 14, {
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(1, -28, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})

	local swatches = {
		Color3.fromRGB(88, 101, 242), Color3.fromRGB(235, 69, 158), Color3.fromRGB(237, 66, 69),
		Color3.fromRGB(250, 166, 26), Color3.fromRGB(87, 242, 135), Color3.fromRGB(0, 190, 230),
		Color3.fromRGB(170, 100, 255),
	}
	local swatchStrokes = {}
	local function selectSwatch(idx)
		for i, st in ipairs(swatchStrokes) do
			st.Enabled = (i == idx)
		end
	end
	for i, c in ipairs(swatches) do
		local s = make("TextButton", {
			Position = UDim2.new(0, 14 + (i - 1) * 34, 0, 32),
			Size = UDim2.new(0, 26, 0, 26),
			BackgroundColor3 = c,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, colorRow)
		local st = stroke(s, theme.Text, 2)
		st.Enabled = false
		swatchStrokes[i] = st
		s.MouseButton1Click:Connect(function()
			setAccent(c)
			selectSwatch(i)
			notify("Accent color updated")
		end)
	end
	selectSwatch(1)

	local setTransparency = makeSlider(scroll, "Window transparency", 0, 0.6, 0, function(v)
		main.BackgroundTransparency = v
	end)

	local setScale = makeSlider(scroll, "UI scale", 0.7, 1.3, 1, function(v)
		mainScale.Scale = v
	end)

	----------------------------------------------------------------
	section(scroll, "BEHAVIOR")

	local setDrag = makeToggle(scroll, "Draggable window", true, function(on)
		draggable = on
	end)

	local setNotif = makeToggle(scroll, "Notifications", true, function(on)
		notificationsEnabled = on
	end)

	local setStats = makeToggle(scroll, "Show stats on Home", true, function(on)
		refs.stats.Visible = on
	end)

	----------------------------------------------------------------
	section(scroll, "CONTROLS")

	local kRow = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 38),
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
	}, scroll)
	stroke(kRow)
	label(kRow, "Show / hide key", 14, {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local kBtn = makeButton(kRow, keybind.key.Name, UDim2.new(0, 120, 0, 26), UDim2.new(1, -132, 0.5, -13))
	keybind.refresh = function()
		kBtn.Text = keybind.listening and "Press a key..." or keybind.key.Name
	end
	kBtn.MouseButton1Click:Connect(function()
		keybind.listening = true
		keybind.refresh()
	end)

	local resetBtn = makeButton(scroll, "Reset to default", UDim2.new(1, -8, 0, 34), nil, false)
	resetBtn.MouseButton1Click:Connect(function()
		setAccent(DEFAULT_ACCENT)
		selectSwatch(1)
		setTransparency(0)
		setScale(1)
		setDrag(true)
		setNotif(true)
		setStats(true)
		keybind.key = Enum.KeyCode.RightShift
		keybind.listening = false
		keybind.refresh()
		notify("Settings reset")
	end)
end

--------------------------------------------------------------------
-- TOUCHE AFFICHER / MASQUER (modifiable dans Settings)
--------------------------------------------------------------------
track(UserInputService.InputBegan:Connect(function(input, processed)
	if keybind.listening then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode ~= Enum.KeyCode.Escape then
				keybind.key = input.KeyCode
			end
			keybind.listening = false
			keybind.refresh()
		end
		return
	end
	if processed then return end
	if input.KeyCode == keybind.key then
		main.Visible = not main.Visible
	end
end))

--------------------------------------------------------------------
-- DÉMARRAGE
--------------------------------------------------------------------
selectTab("Home")
task.defer(function()
	moveUnderline("Home", true)
end)
TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Position = FINAL_POS }):Play()
