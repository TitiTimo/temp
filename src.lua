--// Atlas UI - LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------
local theme = {
	Background = Color3.fromRGB(20, 20, 20),
	Pill = Color3.fromRGB(40, 40, 40),
	Highlight = Color3.fromRGB(22, 22, 22),
	Element = Color3.fromRGB(32, 32, 32),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(160, 160, 160),
	Accent = Color3.fromRGB(88, 101, 242),
}

local accentObjects = {} -- {instance, property}
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
end

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function corner(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
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
-- SCREEN GUI + MAIN WINDOW
--------------------------------------------------------------------
local gui = make("ScreenGui", {
	Name = "AtlasUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local main = make("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 485, 0, 315),
	BackgroundColor3 = theme.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
local mainCorner = corner(main, 24)
local mainScale = make("UIScale", { Scale = 1 }, main)

--------------------------------------------------------------------
-- DRAGGING
--------------------------------------------------------------------
local draggable = true
do
	local dragging, dragStart, startPos
	main.InputBegan:Connect(function(input)
		if not draggable then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

--------------------------------------------------------------------
-- NOTIFICATIONS (toast)
--------------------------------------------------------------------
local notificationsEnabled = true
local function notify(text)
	if not notificationsEnabled then return end
	local toast = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 40),
		Size = UDim2.new(0, 260, 0, 34),
		BackgroundColor3 = theme.Pill,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, main)
	corner(toast, 17)
	label(toast, text, 13, { Size = UDim2.new(1, 0, 1, 0), ZIndex = 51, Font = Enum.Font.GothamMedium })
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 1, -14) }):Play()
	task.delay(2, function()
		local t = TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 1, 40) })
		t:Play()
		t.Completed:Wait()
		toast:Destroy()
	end)
end

--------------------------------------------------------------------
-- NAV BAR (pill)
--------------------------------------------------------------------
local pill = make("Frame", {
	Name = "Nav",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0, 407, 0, 56),
	BackgroundColor3 = theme.Pill,
	BorderSizePixel = 0,
}, main)
corner(pill, 28)

local inner = make("Frame", {
	Position = UDim2.new(0, 6, 0, 6),
	Size = UDim2.new(1, -12, 1, -12),
	BackgroundTransparency = 1,
}, pill)

local highlight = make("Frame", {
	Size = UDim2.new(0.25, 0, 1, 0),
	BackgroundColor3 = theme.Highlight,
	BorderSizePixel = 0,
}, inner)
corner(highlight, 22)

local content = make("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 0, 0, 76),
	Size = UDim2.new(1, 0, 1, -76),
	BackgroundTransparency = 1,
}, main)

local tabNames = { "Home", "Editor", "Hub", "Settings" }
local pages, buttons = {}, {}

local function makePage(name)
	local p = make("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, content)
	pages[name] = p
	return p
end

local currentTab
local function selectTab(name)
	if currentTab == name then return end
	currentTab = name
	for i, n in ipairs(tabNames) do
		pages[n].Visible = (n == name)
		if n == name then
			TweenService:Create(highlight, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				Position = UDim2.new((i - 1) * 0.25, 0, 0, 0),
			}):Play()
		end
	end
end

for i, name in ipairs(tabNames) do
	makePage(name)
	local b = make("TextButton", {
		Name = name,
		Position = UDim2.new((i - 1) * 0.25, 0, 0, 0),
		Size = UDim2.new(0.25, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = false,
		ZIndex = 2,
	}, inner)
	b.MouseButton1Click:Connect(function() selectTab(name) end)
	buttons[name] = b
end

--------------------------------------------------------------------
-- UI WIDGETS
--------------------------------------------------------------------
local function makeButton(parent, text, size, pos, accent)
	local b = make("TextButton", {
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
	corner(b, 10)
	if accent then bindAccent(b, "BackgroundColor3") end
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.25 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	end)
	return b
end

local function makeToggle(parent, text, default, callback)
	local row = make("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundColor3 = theme.Element, BorderSizePixel = 0 }, parent)
	corner(row, 10)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium,
	})
	local track = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22), Text = "", AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0,
	}, row)
	corner(track, 11)
	local knob = make("Frame", {
		Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = theme.Text, BorderSizePixel = 0,
	}, track)
	corner(knob, 8)

	local state = default
	local function render()
		TweenService:Create(knob, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		}):Play()
		TweenService:Create(track, TweenInfo.new(0.2), {
			BackgroundColor3 = state and theme.Accent or Color3.fromRGB(60, 60, 60),
		}):Play()
	end
	render()
	track.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)
	-- re-render when accent changes
	task.spawn(function()
		while track.Parent do
			task.wait(0.3)
			if state then track.BackgroundColor3 = theme.Accent end
		end
	end)
end

local function makeSlider(parent, text, min, max, default, callback, decimals)
	local row = make("Frame", { Size = UDim2.new(1, -8, 0, 54), BackgroundColor3 = theme.Element, BorderSizePixel = 0 }, parent)
	corner(row, 10)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(0.6, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium,
	})
	local valueLabel = label(row, "", 13, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.new(0.3, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = theme.SubText,
	})
	local track = make("Frame", {
		Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0,
	}, row)
	corner(track, 3)
	local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, track)
	bindAccent(fill, "BackgroundColor3")
	corner(fill, 3)
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = theme.Text, BorderSizePixel = 0,
	}, track)
	corner(knob, 7)

	local function set(alpha)
		alpha = math.clamp(alpha, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		local v = min + (max - min) * alpha
		if decimals then v = math.floor(v * 100 + 0.5) / 100 else v = math.floor(v + 0.5) end
		valueLabel.Text = tostring(v)
		callback(v)
	end
	set((default - min) / (max - min))

	local sliding = false
	local function update(x)
		set((x - track.AbsolutePosition.X) / track.AbsoluteSize.X)
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
end

--------------------------------------------------------------------
-- HOME PAGE
--------------------------------------------------------------------
do
	local home = pages.Home
	local title = label(home, "Welcome to Atlas !", 28, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -22),
		Size = UDim2.new(1, 0, 0, 36),
	})
	local keyLabel = label(home, "Key: 24h left", 28, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 18),
		Size = UDim2.new(1, 0, 0, 36),
	})

	local endTime = os.time() + 24 * 3600
	task.spawn(function()
		while keyLabel.Parent do
			local remaining = math.max(0, endTime - os.time())
			keyLabel.Text = ("Key: %dh left"):format(math.ceil(remaining / 3600))
			task.wait(1)
		end
	end)
end

--------------------------------------------------------------------
-- EDITOR PAGE
--------------------------------------------------------------------
do
	local editor = pages.Editor

	local box = make("Frame", {
		Position = UDim2.new(0, 20, 0, 4), Size = UDim2.new(1, -40, 1, -64),
		BackgroundColor3 = theme.Element, BorderSizePixel = 0,
	}, editor)
	corner(box, 12)

	local lines = make("TextLabel", {
		Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, 22, 1, -16),
		BackgroundTransparency = 1, Text = "1", TextColor3 = theme.SubText,
		Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, box)

	local input = make("TextBox", {
		Position = UDim2.new(0, 38, 0, 8), Size = UDim2.new(1, -46, 1, -16),
		BackgroundTransparency = 1, Text = "-- Écris ton code ici\nprint(\"Hello Atlas\")",
		TextColor3 = theme.Text, Font = Enum.Font.Code, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		MultiLine = true, ClearTextOnFocus = false, TextWrapped = false,
		PlaceholderText = "Écris ton code...", PlaceholderColor3 = theme.SubText,
	}, box)

	local function updateLines()
		local count = select(2, input.Text:gsub("\n", "")) + 1
		local t = {}
		for i = 1, count do t[i] = tostring(i) end
		lines.Text = table.concat(t, "\n")
	end
	input:GetPropertyChangedSignal("Text"):Connect(updateLines)
	updateLines()

	local status = label(editor, "Prêt", 12, {
		Position = UDim2.new(0, 22, 1, -50), Size = UDim2.new(0.4, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.SubText, Font = Enum.Font.GothamMedium,
	})

	local clear = makeButton(editor, "Clear", UDim2.new(0, 80, 0, 32), UDim2.new(1, -20 - 80 - 8 - 90, 1, -46))
	local run = makeButton(editor, "Execute", UDim2.new(0, 90, 0, 32), UDim2.new(1, -20 - 90, 1, -46), true)

	clear.MouseButton1Click:Connect(function()
		input.Text = ""
		status.Text = "Éditeur vidé"
	end)
	run.MouseButton1Click:Connect(function()
		-- Exécution simulée (démo) : on vérifie juste la syntaxe
		local fn, err = loadstring and loadstring(input.Text)
		if loadstring == nil then
			status.Text = "Executed (demo)"
		elseif fn then
			status.Text = "Syntaxe OK (demo)"
		else
			status.Text = "Erreur : " .. tostring(err):sub(1, 40)
		end
		notify("Script executed (demo)")
	end)
end

--------------------------------------------------------------------
-- HUB PAGE (faux script hub)
--------------------------------------------------------------------
do
	local hub = pages.Hub

	local search = make("TextBox", {
		Position = UDim2.new(0, 20, 0, 4), Size = UDim2.new(1, -40, 0, 32),
		BackgroundColor3 = theme.Element, BorderSizePixel = 0,
		Text = "", PlaceholderText = "Search scripts...", PlaceholderColor3 = theme.SubText,
		TextColor3 = theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14,
		ClearTextOnFocus = false,
	}, hub)
	corner(search, 10)

	local list = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 44), Size = UDim2.new(1, -40, 1, -52),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, hub)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local fakeScripts = {
		{ "Fly Mode", "by Nova", "12.4k" },
		{ "Speed Boost", "by Kairo", "8.1k" },
		{ "ESP Universal", "by Zephyr", "21.7k" },
		{ "Noclip Plus", "by Orion", "5.9k" },
		{ "Auto Farm Simulator", "by Lyra", "15.3k" },
		{ "Teleport Menu", "by Atlas Team", "9.8k" },
		{ "Infinite Jump", "by Vega", "30.2k" },
		{ "Night Vision", "by Echo", "3.4k" },
	}

	local rows = {}
	for i, s in ipairs(fakeScripts) do
		local row = make("Frame", {
			Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = theme.Element,
			BorderSizePixel = 0, LayoutOrder = i,
		}, list)
		corner(row, 10)
		label(row, s[1], 14, {
			Position = UDim2.new(0, 14, 0, 5), Size = UDim2.new(0.6, 0, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label(row, s[2] .. "  •  " .. s[3] .. " uses", 11, {
			Position = UDim2.new(0, 14, 0, 24), Size = UDim2.new(0.6, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.SubText, Font = Enum.Font.Gotham,
		})
		local load = makeButton(row, "Load", UDim2.new(0, 64, 0, 28), UDim2.new(1, -76, 0.5, -14), true)
		load.MouseButton1Click:Connect(function()
			load.Text = "..."
			task.wait(0.6)
			load.Text = "Loaded"
			notify(s[1] .. " loaded (fake)")
			task.wait(1.5)
			load.Text = "Load"
		end)
		rows[i] = { frame = row, name = s[1]:lower() }
	end

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for _, r in ipairs(rows) do
			r.frame.Visible = q == "" or r.name:find(q, 1, true) ~= nil
		end
	end)
end

--------------------------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------------------------
do
	local settings = pages.Settings

	local scroll = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 4), Size = UDim2.new(1, -40, 1, -12),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, settings)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	-- Couleur d'accent
	local colorRow = make("Frame", { Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = theme.Element, BorderSizePixel = 0 }, scroll)
	corner(colorRow, 10)
	label(colorRow, "Accent color", 14, {
		Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -28, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium,
	})
	local swatches = {
		Color3.fromRGB(88, 101, 242), Color3.fromRGB(235, 69, 158), Color3.fromRGB(237, 66, 69),
		Color3.fromRGB(250, 166, 26), Color3.fromRGB(87, 242, 135), Color3.fromRGB(0, 190, 230),
		Color3.fromRGB(170, 100, 255),
	}
	for i, c in ipairs(swatches) do
		local s = make("TextButton", {
			Position = UDim2.new(0, 14 + (i - 1) * 34, 0, 32), Size = UDim2.new(0, 26, 0, 26),
			BackgroundColor3 = c, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		}, colorRow)
		corner(s, 13)
		s.MouseButton1Click:Connect(function()
			setAccent(c)
			notify("Accent color updated")
		end)
	end

	makeSlider(scroll, "Window transparency", 0, 0.6, 0, function(v)
		main.BackgroundTransparency = v
	end, true)

	makeSlider(scroll, "UI scale", 0.7, 1.3, 1, function(v)
		mainScale.Scale = v
	end, true)

	makeToggle(scroll, "Rounded corners", true, function(on)
		mainCorner.CornerRadius = UDim.new(0, on and 24 or 0)
	end)

	makeToggle(scroll, "Draggable window", true, function(on)
		draggable = on
	end)

	makeToggle(scroll, "Notifications", true, function(on)
		notificationsEnabled = on
	end)

	local hint = label(scroll, "RightShift : afficher / masquer", 12, {
		Size = UDim2.new(1, -8, 0, 24), TextColor3 = theme.SubText, Font = Enum.Font.GothamMedium,
	})
end

--------------------------------------------------------------------
-- TOGGLE UI (RightShift) + START
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)

selectTab("Home")
