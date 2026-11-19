--// Atlas UI v4 (mobile) - LocalScript
--// Emplacement : StarterPlayer > StarterPlayerScripts
--// Fonctionne au toucher (téléphone / tablette) et à la souris (PC).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer

local ATLAS_VERSION = "1.0 (release)"
local KEY_DURATION = 2 * 3600 -- 2h

--------------------------------------------------------------------
-- THEMES
--------------------------------------------------------------------
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local PRESETS = {
	{ name = "Midnight", c = {
		Background = rgb(17, 23, 29), Sidebar = rgb(13, 18, 23), Panel = rgb(22, 30, 38),
		Element = rgb(27, 36, 46), Stroke = rgb(44, 58, 72), Text = rgb(205, 218, 228),
		SubText = rgb(110, 128, 142), Accent = rgb(80, 160, 224),
	} },
	{ name = "Carbon", c = {
		Background = rgb(18, 18, 18), Sidebar = rgb(13, 13, 13), Panel = rgb(26, 26, 26),
		Element = rgb(32, 32, 32), Stroke = rgb(55, 55, 55), Text = rgb(235, 235, 235),
		SubText = rgb(140, 140, 140), Accent = rgb(210, 210, 210),
	} },
	{ name = "Crimson", c = {
		Background = rgb(24, 15, 17), Sidebar = rgb(18, 11, 13), Panel = rgb(32, 20, 23),
		Element = rgb(40, 25, 29), Stroke = rgb(70, 40, 46), Text = rgb(235, 215, 218),
		SubText = rgb(150, 115, 120), Accent = rgb(230, 70, 85),
	} },
	{ name = "Forest", c = {
		Background = rgb(14, 22, 18), Sidebar = rgb(10, 17, 14), Panel = rgb(19, 30, 24),
		Element = rgb(24, 38, 30), Stroke = rgb(40, 66, 52), Text = rgb(210, 230, 218),
		SubText = rgb(115, 145, 125), Accent = rgb(80, 210, 130),
	} },
	{ name = "Violet", c = {
		Background = rgb(20, 16, 30), Sidebar = rgb(15, 12, 24), Panel = rgb(27, 21, 40),
		Element = rgb(34, 27, 50), Stroke = rgb(60, 48, 88), Text = rgb(222, 215, 240),
		SubText = rgb(135, 122, 165), Accent = rgb(160, 110, 255),
	} },
}

local theme = {}
for k, v in pairs(PRESETS[1].c) do
	theme[k] = v
end

-- Couleurs de la coloration syntaxique (hex)
local SYN = { kw = "AA96EB", fn = "69AAE6", str = "9C93D9", num = "E6AA6E", comment = "6E808E" }

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local boundList = {}
local themeCallbacks = {}
local connections = {}
local cornerList = {}
local roundedOn = false -- angles droits par défaut
local orderCounter = 0

local colorProps = {
	BackgroundColor3 = true,
	TextColor3 = true,
	Color = true,
	PlaceholderColor3 = true,
	ScrollBarImageColor3 = true,
}

local function ord()
	orderCounter += 1
	return orderCounter
end

local function track(conn)
	table.insert(connections, conn)
	return conn
end

-- Une propriété de couleur donnée comme texte ("Panel", "Accent"...) suit le thème.
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if colorProps[k] and type(v) == "string" then
			table.insert(boundList, { obj, k, v })
			obj[k] = theme[v]
		else
			obj[k] = v
		end
	end
	obj.Parent = parent
	return obj
end

local function applyTheme(values)
	for k, v in pairs(values) do
		theme[k] = v
	end
	local alive = {}
	for _, e in ipairs(boundList) do
		if e[1].Parent ~= nil then
			table.insert(alive, e)
			TweenService:Create(e[1], TweenInfo.new(0.25), { [e[2]] = theme[e[3]] }):Play()
		end
	end
	boundList = alive
	for _, cb in ipairs(themeCallbacks) do
		cb()
	end
end

local function corner(parent, radius)
	local c = make("UICorner", { CornerRadius = UDim.new(0, roundedOn and radius or 0) }, parent)
	table.insert(cornerList, { c, radius })
	return c
end

local function setRounded(on)
	roundedOn = on
	local alive = {}
	for _, e in ipairs(cornerList) do
		if e[1].Parent ~= nil then
			table.insert(alive, e)
			e[1].CornerRadius = UDim.new(0, on and e[2] or 0)
		end
	end
	cornerList = alive
end

local function stroke(parent, color, thickness)
	return make("UIStroke", {
		Color = color or "Stroke",
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function outline(parent, radius, color)
	local st = stroke(parent, color)
	corner(parent, radius or 6)
	return st
end

local function label(parent, text, size, props)
	local p = {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = "Text",
		Font = Enum.Font.GothamBold,
		TextSize = size,
	}
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	return make("TextLabel", p, parent)
end

--------------------------------------------------------------------
-- SCREEN GUI + FENÊTRE
--------------------------------------------------------------------
local DESIGN = Vector2.new(700, 390)
local SIDEBAR_W = 72
local TOP_H = 40
local CONTENT_W = DESIGN.X - SIDEBAR_W -- 628
local CONTENT_H = DESIGN.Y - TOP_H -- 350

local gui = make("ScreenGui", {
	Name = "AtlasUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

gui.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
end)

local main = make("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 16),
	Size = UDim2.fromOffset(DESIGN.X, DESIGN.Y),
	BackgroundColor3 = "Background",
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
}, gui)
outline(main, 10)
local mainScale = make("UIScale", { Scale = 1 }, main)

-- Mise à l'échelle automatique : la fenêtre s'adapte à l'écran (téléphone, tablette, PC)
local userScale = 1
local function updateScale()
	local vp = gui.AbsoluteSize
	local base = 1
	if vp.X > 1 and vp.Y > 1 then
		base = math.min(vp.X * 0.94 / DESIGN.X, vp.Y * 0.92 / DESIGN.Y, 1.3)
	end
	mainScale.Scale = math.max(base, 0.3) * userScale
end
track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))
updateScale()

local refs = {}
local keybind = { key = Enum.KeyCode.RightShift, listening = false, refresh = function() end }
local draggable = true
local notificationsEnabled = true

--------------------------------------------------------------------
-- DÉPLACEMENT (souris + toucher)
--------------------------------------------------------------------
local function makeDraggable(handle, target, canDrag, onTap)
	local dragging, dragStart, startPos, moved = false, nil, nil, false
	track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if canDrag and not canDrag() then return end
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved and onTap then onTap() end
		end
	end))
end

--------------------------------------------------------------------
-- BOUTON FLOTTANT (pour rouvrir l'interface sur mobile)
--------------------------------------------------------------------
local fab = make("TextButton", {
	Name = "AtlasToggle",
	Position = UDim2.new(0, 16, 0.5, -24),
	Size = UDim2.new(0, 48, 0, 48),
	BackgroundColor3 = "Panel",
	Text = "A",
	TextColor3 = "Accent",
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 5,
}, gui)
stroke(fab, "Accent", 2)
corner(fab, 10)

local function setWindowVisible(v)
	main.Visible = v
	fab.Visible = not v
end

makeDraggable(fab, fab, nil, function()
	setWindowVisible(true)
end)

--------------------------------------------------------------------
-- NOTIFICATIONS (toast)
--------------------------------------------------------------------
local function notify(text)
	if not notificationsEnabled then return end
	local toast = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 60),
		Size = UDim2.new(0, 300, 0, 38),
		BackgroundColor3 = "Element",
		BorderSizePixel = 0,
		ZIndex = 50,
	}, main)
	outline(toast, 8)
	make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = "Accent",
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
			Position = UDim2.new(0.5, 0, 1, 60),
		})
		t:Play()
		t.Completed:Wait()
		toast:Destroy()
	end)
end

--------------------------------------------------------------------
-- BARRE LATÉRALE + BARRE DU HAUT + CONTENU
--------------------------------------------------------------------
local pages, navItems = {}, {}
local currentPage

local sidebar = make("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, SIDEBAR_W, 1, 0),
	BackgroundColor3 = "Sidebar",
	BorderSizePixel = 0,
}, main)
make("Frame", {
	Position = UDim2.new(1, -1, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = "Stroke",
	BorderSizePixel = 0,
}, sidebar)

-- Logo
local logo = make("Frame", {
	Position = UDim2.new(0.5, -17, 0, 11),
	Size = UDim2.new(0, 34, 0, 34),
	BackgroundTransparency = 1,
}, sidebar)
stroke(logo, "Accent", 2)
corner(logo, 8)
label(logo, "A", 20, { Size = UDim2.new(1, 0, 1, 0), TextColor3 = "Accent" })

local navHolder = make("Frame", {
	Position = UDim2.new(0, 0, 0, 58),
	Size = UDim2.new(1, 0, 1, -82),
	BackgroundTransparency = 1,
}, sidebar)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, navHolder)

label(sidebar, "v1.0", 10, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, -6),
	Size = UDim2.new(1, 0, 0, 14),
	TextColor3 = "SubText",
	Font = Enum.Font.GothamMedium,
})

local topbar = make("Frame", {
	Name = "Topbar",
	Position = UDim2.new(0, SIDEBAR_W, 0, 0),
	Size = UDim2.new(1, -SIDEBAR_W, 0, TOP_H),
	BackgroundTransparency = 1,
}, main)

local controls = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 0),
	Size = UDim2.new(0, 138, 1, 0),
	BackgroundTransparency = 1,
}, topbar)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, controls)

local function controlButton(order)
	return make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(0, 44, 0, 40),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = "SubText",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = false,
	}, controls)
end

local minBtn = controlButton(1)
make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 12, 0, 2),
	BackgroundColor3 = "SubText",
	BorderSizePixel = 0,
}, minBtn)

local centerBtn = controlButton(2)
do
	local sq = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 11, 0, 11),
		BackgroundTransparency = 1,
	}, centerBtn)
	stroke(sq, "SubText", 2)
end

local closeBtn = controlButton(3)
closeBtn.Text = "X"

makeDraggable(topbar, main, function() return draggable end)
makeDraggable(logo, main, function() return draggable end)

minBtn.MouseButton1Click:Connect(function()
	setWindowVisible(false)
end)
centerBtn.MouseButton1Click:Connect(function()
	TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local content = make("Frame", {
	Name = "Content",
	Position = UDim2.new(0, SIDEBAR_W, 0, TOP_H),
	Size = UDim2.new(0, CONTENT_W, 0, CONTENT_H),
	BackgroundTransparency = 1,
}, main)

--------------------------------------------------------------------
-- ICÔNES DE LA BARRE LATÉRALE (dessinées avec des Frames)
--------------------------------------------------------------------
local function newIcon(parent, kind)
	local holder = make("Frame", {
		Position = UDim2.new(0.5, -12, 0, 10),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
	}, parent)
	local fills, strokes, texts = {}, {}, {}

	local function rect(x, y, w, h, rot)
		local f = make("Frame", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, w, 0, h),
			BorderSizePixel = 0,
			Rotation = rot or 0,
		}, holder)
		table.insert(fills, f)
	end
	local function ring(x, y, s)
		local f = make("Frame", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, s, 0, s),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, holder)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		table.insert(strokes, make("UIStroke", {
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, f))
	end

	if kind == "home" then
		ring(1, 1, 22)
		rect(8, 8, 8, 8, 45)
	elseif kind == "editor" then
		table.insert(texts, label(holder, "</>", 15, {
			Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.Code,
			TextColor3 = theme.SubText,
		}))
	elseif kind == "scripts" then
		ring(3, 0, 8)
		ring(3, 16, 8)
		rect(6, 8, 2, 8)
		ring(15, 4, 8)
		rect(6, 10, 10, 2)
	elseif kind == "themes" then
		rect(1, 1, 10, 10)
		rect(13, 1, 10, 10)
		rect(1, 13, 10, 10)
		rect(13, 13, 10, 10)
	else -- config
		rect(1, 5, 22, 2)
		rect(1, 11, 22, 2)
		rect(1, 17, 22, 2)
		rect(14, 3, 6, 6)
		rect(4, 9, 6, 6)
		rect(12, 15, 6, 6)
	end

	return function(color)
		for _, f in ipairs(fills) do f.BackgroundColor3 = color end
		for _, s in ipairs(strokes) do s.Color = color end
		for _, t in ipairs(texts) do t.TextColor3 = color end
	end
end

local navDefs = {
	{ "Home", "HOME", "home" },
	{ "Editor", "EDITOR", "editor" },
	{ "Scripts", "SCRIPTS", "scripts" },
	{ "Themes", "THEMES", "themes" },
	{ "Config", "CONFIG", "config" },
}

local function refreshNav()
	for name, n in pairs(navItems) do
		local active = (name == currentPage)
		n.bar.Visible = active
		n.bar.BackgroundColor3 = theme.Accent
		n.item.BackgroundColor3 = theme.Panel
		n.item.BackgroundTransparency = active and 0 or 1
		n.paint(active and theme.Accent or theme.SubText)
		n.lbl.TextColor3 = active and theme.Text or theme.SubText
	end
end
table.insert(themeCallbacks, refreshNav)

local function selectPage(name)
	if currentPage == name then return end
	local first = currentPage == nil
	currentPage = name
	for n, p in pairs(pages) do
		p.Visible = (n == name)
	end
	refreshNav()
	if not first then
		local p = pages[name]
		p.Position = UDim2.new(0, 0, 0, 10)
		TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
	end
end

for i, def in ipairs(navDefs) do
	local name = def[1]
	pages[name] = make("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, content)

	local item = make("TextButton", {
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, navHolder)
	local bar = make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Visible = false,
	}, item)
	local paint = newIcon(item, def[3])
	local lbl = label(item, def[2], 10, {
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 14),
		TextColor3 = theme.SubText,
	})
	paint(theme.SubText)
	navItems[name] = { item = item, bar = bar, paint = paint, lbl = lbl }
	item.MouseButton1Click:Connect(function()
		selectPage(name)
	end)
end

--------------------------------------------------------------------
-- WIDGETS
--------------------------------------------------------------------
local function makeButton(parent, text, size, pos, primary)
	local b = make("TextButton", {
		LayoutOrder = ord(),
		Size = size,
		Position = pos or UDim2.new(),
		BackgroundColor3 = "Element",
		Text = text,
		TextColor3 = primary and "Accent" or "Text",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
	outline(b, 6, primary and "Accent" or nil)
	local function release()
		TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	end
	b.MouseButton1Down:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), { BackgroundTransparency = 0.45 }):Play()
	end)
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)
	return b
end

local function section(parent, text)
	return label(parent, text, 11, {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = "SubText",
	})
end

local function makeToggle(parent, text, default, callback)
	local row = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 44),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
	}, parent)
	outline(row, 8)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -90, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local trackBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 46, 0, 24),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
	}, row)
	corner(trackBtn, 12)
	local knob = make("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
	}, trackBtn)
	corner(knob, 9)

	local state = default
	local function render()
		TweenService:Create(knob, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
			BackgroundColor3 = theme.Text,
		}):Play()
		TweenService:Create(trackBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = state and theme.Accent or theme.Stroke,
		}):Play()
	end
	render()
	table.insert(themeCallbacks, render)

	trackBtn.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)

	return function(v)
		state = v
		render()
		callback(v)
	end
end

local function makeSlider(parent, text, min, max, default, callback)
	local scrollParent = parent:IsA("ScrollingFrame") and parent or nil
	local row = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 62),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
	}, parent)
	outline(row, 8)
	label(row, text, 14, {
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(0.6, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local valueLabel = label(row, "", 13, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.new(0.3, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = "SubText",
	})
	-- Zone tactile large (28px) autour de la barre fine
	local hit = make("Frame", {
		Position = UDim2.new(0, 14, 0, 32),
		Size = UDim2.new(1, -28, 0, 26),
		BackgroundTransparency = 1,
	}, row)
	local bar = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = "Stroke",
		BorderSizePixel = 0,
	}, hit)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = "Accent",
		BorderSizePixel = 0,
	}, bar)
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 12, 0, 20),
		BackgroundColor3 = "Text",
		BorderSizePixel = 0,
	}, bar)
	corner(knob, 4)

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
		set((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1))
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			if scrollParent then scrollParent.ScrollingEnabled = false end
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
		if sliding and (i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch) then
			sliding = false
			if scrollParent then scrollParent.ScrollingEnabled = true end
		end
	end))

	return function(v)
		set((v - min) / (max - min))
	end
end

local function chipStyle(btn, st, active)
	TweenService:Create(btn, TweenInfo.new(0.2), {
		TextColor3 = active and theme.Accent or theme.SubText,
	}):Play()
	TweenService:Create(st, TweenInfo.new(0.2), {
		Color = active and theme.Accent or theme.Stroke,
	}):Play()
end

--------------------------------------------------------------------
-- HOME
--------------------------------------------------------------------
do
	local home = pages.Home

	local holder = make("Frame", {
		Position = UDim2.new(0, 20, 0, 14),
		Size = UDim2.new(1, -40, 0, 80),
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

	local barTrack = make("Frame", {
		Position = UDim2.new(0, 20, 0, 104),
		Size = UDim2.new(1, -40, 0, 6),
		BackgroundColor3 = "Stroke",
		BorderSizePixel = 0,
	}, home)
	local barFill = make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = "Accent",
		BorderSizePixel = 0,
	}, barTrack)

	local stats = make("Frame", {
		Position = UDim2.new(0, 20, 0, 126),
		Size = UDim2.new(1, -40, 0, 80),
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
			BackgroundColor3 = "Panel",
			BorderSizePixel = 0,
		}, stats)
		outline(t, 8)
		make("Frame", {
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = "Accent",
			BorderSizePixel = 0,
		}, t)
		local v = label(t, "--", 24, {
			Position = UDim2.new(0, 16, 0, 12),
			Size = UDim2.new(1, -24, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label(t, title, 11, {
			Position = UDim2.new(0, 16, 0, 46),
			Size = UDim2.new(1, -24, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = "SubText",
			Font = Enum.Font.GothamMedium,
		})
		return v
	end

	local fpsLabel = tile("FPS", 1)
	local pingLabel = tile("PING", 2)
	local plrLabel = tile("PLAYERS", 3)

	-- Raccourcis (grandes zones tactiles)
	local openEditor = makeButton(home, "OPEN EDITOR", UDim2.new(0, 288, 0, 46), UDim2.new(0, 20, 0, 226), false)
	local browse = makeButton(home, "BROWSE SCRIPTS", UDim2.new(0, 288, 0, 46), UDim2.new(0, 320, 0, 226), true)
	openEditor.MouseButton1Click:Connect(function() selectPage("Editor") end)
	browse.MouseButton1Click:Connect(function() selectPage("Scripts") end)

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
-- EDITOR (comme la capture : panneau de fichiers + onglets + code coloré)
--------------------------------------------------------------------
do
	local page = pages.Editor

	local PANEL_W = 176
	local AREA_H = CONTENT_H - 12 -- 338
	local OPEN_X, CLOSED_X = 214, 32
	local panelOpen = true

	local DEFAULT_CODE = table.concat({
		"-- Atlas demo script",
		"local Players = game:GetService(\"Players\")",
		"local player = Players.LocalPlayer",
		"",
		"print(\"Hello from Atlas, \" .. player.Name)",
		"",
		"for i = 1, 3 do",
		"\tprint(\"Tick\", i)",
		"end",
	}, "\n")

	----------------------------------------------------------------
	-- Coloration syntaxique
	----------------------------------------------------------------
	local KEYWORDS = {}
	for w in ("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%S+") do
		KEYWORDS[w] = true
	end
	local BUILTINS = {}
	for w in ("print warn error assert pcall xpcall spawn wait delay tick time os task game workspace script require pairs ipairs next select type typeof tostring tonumber math string table coroutine Instance Vector2 Vector3 CFrame Color3 UDim UDim2 Enum setmetatable getmetatable"):gmatch("%S+") do
		BUILTINS[w] = true
	end

	local function esc(s)
		s = s:gsub("&", "&amp;")
		s = s:gsub("<", "&lt;")
		s = s:gsub(">", "&gt;")
		return s
	end

	local function colorize(s, hex)
		return '<font color="#' .. hex .. '">' .. esc(s) .. "</font>"
	end

	local function highlightLine(line)
		local out, plain = {}, {}
		local function flush()
			if #plain > 0 then
				table.insert(out, esc(table.concat(plain)))
				table.clear(plain)
			end
		end
		local i, n = 1, #line
		while i <= n do
			local c = line:sub(i, i)
			if line:sub(i, i + 1) == "--" then
				flush()
				table.insert(out, colorize(line:sub(i), SYN.comment))
				i = n + 1
			elseif c == '"' or c == "'" then
				flush()
				local j = i + 1
				while j <= n do
					local d = line:sub(j, j)
					if d == "\\" then
						j += 2
					elseif d == c then
						break
					else
						j += 1
					end
				end
				j = math.min(j, n)
				table.insert(out, colorize(line:sub(i, j), SYN.str))
				i = j + 1
			elseif c:match("[%a_]") then
				local w = line:match("^[%w_]+", i)
				local nextChar = line:sub(i + #w, i + #w)
				if KEYWORDS[w] then
					flush()
					table.insert(out, colorize(w, SYN.kw))
				elseif BUILTINS[w] or nextChar == "(" then
					flush()
					table.insert(out, colorize(w, SYN.fn))
				else
					table.insert(plain, w)
				end
				i += #w
			elseif c:match("%d") then
				local w = line:match("^%d[%d%.]*", i)
				flush()
				table.insert(out, colorize(w, SYN.num))
				i += #w
			else
				table.insert(plain, c)
				i += 1
			end
		end
		flush()
		return table.concat(out)
	end

	local function highlight(text)
		if #text > 12000 then return esc(text) end
		local out = {}
		for line in (text .. "\n"):gmatch("(.-)\n") do
			table.insert(out, highlightLine(line))
		end
		return table.concat(out, "\n")
	end

	----------------------------------------------------------------
	-- Panneau de gauche (filtre, TXT / LUA / ALL FILES, liste)
	----------------------------------------------------------------
	local panel = make("Frame", {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, PANEL_W, 0, AREA_H),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, page)

	local filter = make("TextBox", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Filter Items..",
		PlaceholderColor3 = "SubText",
		TextColor3 = "Text",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, panel)
	outline(filter, 6)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12) }, filter)

	local chipDefs = { { "TXT", "txt", 0, 50 }, { "LUA", "lua", 54, 50 }, { "ALL FILES", "all", 108, 68 } }
	local chips = {}
	local fileFilter = "all"

	local fileList = make("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 82),
		Size = UDim2.new(1, 0, 1, -82),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Stroke",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, fileList)

	----------------------------------------------------------------
	-- Zone d'édition
	----------------------------------------------------------------
	local handle = make("TextButton", {
		Position = UDim2.new(0, 12 + PANEL_W + 4, 0, 141),
		Size = UDim2.new(0, 16, 0, 56),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
		Text = "<",
		TextColor3 = "SubText",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
	}, page)
	outline(handle, 4)

	local area = make("Frame", {
		Position = UDim2.new(0, OPEN_X, 0, 0),
		Size = UDim2.new(0, CONTENT_W - OPEN_X - 12, 0, AREA_H),
		BackgroundTransparency = 1,
	}, page)

	local tabScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, -38, 0, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
	}, area)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabScroll)

	local plusBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
		Text = "+",
		TextColor3 = "Text",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
	}, area)
	outline(plusBtn, 6)

	-- Éditeur de code : numéros de ligne + texte coloré + TextBox transparent par-dessus
	local code = make("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 1, -86),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = "Stroke",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ClipsDescendants = true,
	}, area)
	outline(code, 6)

	local gutter = make("TextLabel", {
		Position = UDim2.new(0, 0, 0, 6),
		Size = UDim2.new(0, 34, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "1",
		TextColor3 = "SubText",
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, code)

	local overlay = make("TextLabel", {
		Position = UDim2.new(0, 44, 0, 6),
		Size = UDim2.new(0, 340, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		RichText = true,
		TextColor3 = "Text",
		Font = Enum.Font.Code,
		TextSize = 14,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 1,
	}, code)

	local input = make("TextBox", {
		Position = UDim2.new(0, 44, 0, 6),
		Size = UDim2.new(0, 340, 0, 236),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = DEFAULT_CODE,
		TextTransparency = 1,
		TextColor3 = "Text",
		Font = Enum.Font.Code,
		TextSize = 14,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		MultiLine = true,
		ClearTextOnFocus = false,
		ZIndex = 2,
	}, code)

	local function refreshCode()
		local text = input.Text
		local n = select(2, text:gsub("\n", "")) + 1
		local nums = table.create(n)
		for i = 1, n do nums[i] = tostring(i) end
		gutter.Text = table.concat(nums, "\n")
		overlay.Text = highlight(text)
	end
	input:GetPropertyChangedSignal("Text"):Connect(refreshCode)
	refreshCode()

	----------------------------------------------------------------
	-- Onglets
	----------------------------------------------------------------
	local tabsData = { { name = "NewScript.lua", text = DEFAULT_CODE } }
	local activeTab = 1
	local newCounter = 1
	local renderTabs, switchTab, closeTab

	function renderTabs()
		for _, c in ipairs(tabScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, t in ipairs(tabsData) do
			local active = (i == activeTab)
			local tb = make("TextButton", {
				LayoutOrder = i,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = active and "Panel" or "Element",
				BorderSizePixel = 0,
				Text = t.name,
				TextColor3 = active and "Accent" or "SubText",
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				AutoButtonColor = false,
			}, tabScroll)
			make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 34) }, tb)
			corner(tb, 6)
			if active then
				make("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = "Accent",
					BorderSizePixel = 0,
				}, tb)
			end
			local x = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 30, 1, 0),
				BackgroundTransparency = 1,
				Text = "x",
				TextColor3 = "SubText",
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				AutoButtonColor = false,
			}, tb)
			tb.MouseButton1Click:Connect(function()
				if i ~= activeTab then switchTab(i) end
			end)
			x.MouseButton1Click:Connect(function()
				closeTab(i)
			end)
		end
	end

	function switchTab(i)
		tabsData[activeTab].text = input.Text
		activeTab = i
		input.Text = tabsData[i].text
		renderTabs()
	end

	local function addTab(name, text)
		tabsData[activeTab].text = input.Text
		table.insert(tabsData, { name = name, text = text })
		activeTab = #tabsData
		input.Text = text
		renderTabs()
	end

	function closeTab(i)
		if #tabsData == 1 then
			tabsData[1].text = ""
			input.Text = ""
			notify("Tab cleared")
			return
		end
		tabsData[activeTab].text = input.Text
		table.remove(tabsData, i)
		if activeTab > #tabsData then
			activeTab = #tabsData
		elseif i < activeTab then
			activeTab -= 1
		end
		input.Text = tabsData[activeTab].text
		renderTabs()
	end

	plusBtn.MouseButton1Click:Connect(function()
		newCounter += 1
		addTab("NewScript" .. newCounter .. ".lua", "")
	end)
	renderTabs()

	----------------------------------------------------------------
	-- Fichiers
	----------------------------------------------------------------
	local files = {
		{ name = "README.txt", text = "Put your own scripts in here" },
		{ name = "Atlas Demo.lua", text = DEFAULT_CODE },
		{ name = "Walk Speed.lua", text = "local hum = game.Players.LocalPlayer.Character.Humanoid\nhum.WalkSpeed = 24" },
		{ name = "Notes.txt", text = "Ideas:\n- add more themes\n- save scripts" },
	}

	local function openFile(f)
		for i, t in ipairs(tabsData) do
			if t.name == f.name then
				if i ~= activeTab then switchTab(i) end
				return
			end
		end
		addTab(f.name, f.text)
	end

	local function renderFiles()
		for _, c in ipairs(fileList:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local q = filter.Text:lower()
		for i, f in ipairs(files) do
			local ext = f.name:match("%.(%w+)$") or ""
			local okExt = (fileFilter == "all") or (ext == fileFilter)
			local okName = (q == "") or (f.name:lower():find(q, 1, true) ~= nil)
			if okExt and okName then
				local b = make("TextButton", {
					LayoutOrder = i,
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundColor3 = "Panel",
					BorderSizePixel = 0,
					Text = f.name,
					TextColor3 = "Text",
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					AutoButtonColor = false,
				}, fileList)
				outline(b, 6)
				make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6) }, b)
				b.MouseButton1Click:Connect(function()
					openFile(f)
				end)
			end
		end
	end

	local function refreshChips()
		for key, c in pairs(chips) do
			chipStyle(c.btn, c.st, key == fileFilter)
		end
	end
	table.insert(themeCallbacks, refreshChips)

	for _, d in ipairs(chipDefs) do
		local btn = make("TextButton", {
			Position = UDim2.new(0, d[3], 0, 44),
			Size = UDim2.new(0, d[4], 0, 30),
			BackgroundColor3 = theme.Element,
			BorderSizePixel = 0,
			Text = d[1],
			TextColor3 = theme.SubText,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			AutoButtonColor = false,
		}, panel)
		local st = stroke(btn, theme.Stroke)
		corner(btn, 6)
		chips[d[2]] = { btn = btn, st = st }
		btn.MouseButton1Click:Connect(function()
			fileFilter = d[2]
			refreshChips()
			renderFiles()
		end)
	end
	filter:GetPropertyChangedSignal("Text"):Connect(renderFiles)
	refreshChips()
	renderFiles()

	----------------------------------------------------------------
	-- Ouverture / fermeture du panneau (flèche < >)
	----------------------------------------------------------------
	local function setPanelOpen(open)
		panelOpen = open
		local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint)
		TweenService:Create(panel, info, {
			Size = UDim2.new(0, open and PANEL_W or 0, 0, AREA_H),
		}):Play()
		TweenService:Create(handle, info, {
			Position = UDim2.new(0, open and (12 + PANEL_W + 4) or 12, 0, 141),
		}):Play()
		TweenService:Create(area, info, {
			Position = UDim2.new(0, open and OPEN_X or CLOSED_X, 0, 0),
			Size = UDim2.new(0, CONTENT_W - (open and OPEN_X or CLOSED_X) - 12, 0, AREA_H),
		}):Play()
		handle.Text = open and "<" or ">"
	end
	handle.MouseButton1Click:Connect(function()
		setPanelOpen(not panelOpen)
	end)

	----------------------------------------------------------------
	-- Boutons du bas : EXECUTE / CLEAR / OPEN / SAVE ... INJECT
	----------------------------------------------------------------
	local row = make("Frame", {
		Position = UDim2.new(0, 0, 1, -40),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
	}, area)

	local left = make("Frame", {
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
	}, row)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, left)

	local execBtn = makeButton(left, "EXECUTE", UDim2.new(0, 84, 1, 0), nil, false)
	local clearBtn = makeButton(left, "CLEAR", UDim2.new(0, 66, 1, 0), nil, false)
	local openBtn = makeButton(left, "OPEN", UDim2.new(0, 60, 1, 0), nil, false)
	local saveBtn = makeButton(left, "SAVE", UDim2.new(0, 60, 1, 0), nil, false)
	local injectBtn = makeButton(row, "INJECT", UDim2.new(0, 74, 1, 0), UDim2.new(1, -74, 0, 0), true)

	execBtn.MouseButton1Click:Connect(function()
		-- Exécution simulée (démo) : rien n'est réellement lancé
		notify("Executed (demo)")
	end)
	clearBtn.MouseButton1Click:Connect(function()
		input.Text = ""
	end)
	openBtn.MouseButton1Click:Connect(function()
		setPanelOpen(true)
		notify("Select a file to open")
	end)
	saveBtn.MouseButton1Click:Connect(function()
		tabsData[activeTab].text = input.Text
		local name = tabsData[activeTab].name
		local found = false
		for _, f in ipairs(files) do
			if f.name == name then
				f.text = input.Text
				found = true
			end
		end
		if not found then
			table.insert(files, { name = name, text = input.Text })
		end
		renderFiles()
		notify("Saved " .. name)
	end)

	local injecting = false
	injectBtn.MouseButton1Click:Connect(function()
		if injecting then return end
		injecting = true
		injectBtn.Text = "..."
		task.wait(0.8)
		injectBtn.Text = "DONE"
		notify("Injected (demo)")
		task.wait(1.4)
		injectBtn.Text = "INJECT"
		injecting = false
	end)
end

--------------------------------------------------------------------
-- SCRIPTS (faux script hub)
--------------------------------------------------------------------
do
	local hub = pages.Scripts

	local search = make("TextBox", {
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -40, 0, 38),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Search scripts...",
		PlaceholderColor3 = "SubText",
		TextColor3 = "Text",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, hub)
	outline(search, 6)
	make("UIPadding", { PaddingLeft = UDim.new(0, 12) }, search)

	local categories = { "All", "Universal", "Games" }
	local currentCat = "All"
	local chips = {}

	local chipHolder = make("Frame", {
		Position = UDim2.new(0, 20, 0, 46),
		Size = UDim2.new(0.7, 0, 0, 32),
		BackgroundTransparency = 1,
	}, hub)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, chipHolder)

	local count = label(hub, "", 12, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 46),
		Size = UDim2.new(0, 110, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = "SubText",
		Font = Enum.Font.GothamMedium,
	})

	local list = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 86),
		Size = UDim2.new(1, -40, 1, -98),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Stroke",
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

	local function refreshChips()
		for name, c in pairs(chips) do
			chipStyle(c.btn, c.st, name == currentCat)
		end
	end
	table.insert(themeCallbacks, refreshChips)

	for i, cat in ipairs(categories) do
		local btn = make("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(0, 84, 1, 0),
			BackgroundColor3 = theme.Element,
			BorderSizePixel = 0,
			Text = cat:upper(),
			TextColor3 = theme.SubText,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			AutoButtonColor = false,
		}, chipHolder)
		local st = stroke(btn, theme.Stroke)
		corner(btn, 6)
		chips[cat] = { btn = btn, st = st }
		btn.MouseButton1Click:Connect(function()
			currentCat = cat
			refreshChips()
			applyFilter()
		end)
	end

	for i, s in ipairs(fakeScripts) do
		local r = make("Frame", {
			Size = UDim2.new(1, -8, 0, 52),
			BackgroundColor3 = "Panel",
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, list)
		outline(r, 8)
		make("Frame", {
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = "Accent",
			BorderSizePixel = 0,
		}, r)
		label(r, s[1], 14, {
			Position = UDim2.new(0, 16, 0, 7),
			Size = UDim2.new(0.6, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label(r, s[2] .. "  •  " .. s[3] .. " uses  •  " .. s[4], 11, {
			Position = UDim2.new(0, 16, 0, 28),
			Size = UDim2.new(0.7, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = "SubText",
			Font = Enum.Font.Gotham,
		})
		local load = makeButton(r, "LOAD", UDim2.new(0, 78, 0, 34), UDim2.new(1, -90, 0.5, -17), true)
		local busy = false
		load.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			load.Text = "..."
			task.wait(0.6)
			load.Text = "LOADED"
			notify(s[1] .. " loaded (fake)")
			task.wait(1.5)
			load.Text = "LOAD"
			busy = false
		end)
		rows[i] = { frame = r, name = s[1]:lower(), cat = s[4] }
	end

	search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
	refreshChips()
	applyFilter()
end

--------------------------------------------------------------------
-- THEMES
--------------------------------------------------------------------
local selectSwatch
local selectedPreset = 1
local setPresetSelection

do
	local themesPage = pages.Themes

	local scroll = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -40, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Stroke",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, themesPage)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	section(scroll, "ACCENT COLOR")

	local swRow = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
	}, scroll)
	outline(swRow, 8)

	local swatches = {
		rgb(80, 160, 224), rgb(235, 69, 158), rgb(237, 66, 69), rgb(250, 166, 26),
		rgb(87, 242, 135), rgb(0, 200, 190), rgb(170, 100, 255),
	}
	local swatchStrokes = {}
	function selectSwatch(idx)
		for i, st in ipairs(swatchStrokes) do
			st.Enabled = (i == idx)
		end
	end
	for i, c in ipairs(swatches) do
		local s = make("TextButton", {
			Position = UDim2.new(0, 14 + (i - 1) * 52, 0.5, -20),
			Size = UDim2.new(0, 40, 0, 40),
			BackgroundColor3 = c,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, swRow)
		local st = stroke(s, rgb(255, 255, 255), 2)
		st.Enabled = false
		swatchStrokes[i] = st
		corner(s, 8)
		s.MouseButton1Click:Connect(function()
			applyTheme({ Accent = c })
			selectSwatch(i)
			notify("Accent color updated")
		end)
	end

	section(scroll, "PRESETS")

	local presetRows = {}
	local function refreshPresets()
		for i, r in ipairs(presetRows) do
			r.st.Color = (i == selectedPreset) and theme.Accent or theme.Stroke
			r.st.Thickness = (i == selectedPreset) and 2 or 1
		end
	end
	table.insert(themeCallbacks, refreshPresets)

	function setPresetSelection(i)
		selectedPreset = i
		refreshPresets()
	end

	for i, p in ipairs(PRESETS) do
		local b = make("TextButton", {
			LayoutOrder = ord(),
			Size = UDim2.new(1, -8, 0, 50),
			BackgroundColor3 = "Panel",
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, scroll)
		local st = stroke(b, theme.Stroke)
		corner(b, 8)
		presetRows[i] = { st = st }
		label(b, p.name, 14, {
			Position = UDim2.new(0, 16, 0, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local keys = { "Background", "Panel", "Stroke", "Accent" }
		for k, key in ipairs(keys) do
			local sq = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14 - (#keys - k) * 26, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				BackgroundColor3 = p.c[key],
				BorderSizePixel = 0,
			}, b)
			stroke(sq, rgb(90, 90, 90), 1)
			corner(sq, 4)
		end
		b.MouseButton1Click:Connect(function()
			selectedPreset = i
			applyTheme(p.c)
			selectSwatch(0)
			notify(p.name .. " theme")
		end)
	end
	refreshPresets()
end

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
do
	local cfg = pages.Config

	local scroll = make("ScrollingFrame", {
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -40, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Stroke",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, cfg)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	section(scroll, "INTERFACE")

	local setScale = makeSlider(scroll, "UI scale", 0.6, 1.2, 1, function(v)
		userScale = v
		updateScale()
	end)

	local setRoundedToggle = makeToggle(scroll, "Rounded corners", false, function(on)
		setRounded(on)
	end)

	local setStats = makeToggle(scroll, "Show stats on Home", true, function(on)
		refs.stats.Visible = on
	end)

	section(scroll, "BEHAVIOR")

	local setDrag = makeToggle(scroll, "Draggable window", true, function(on)
		draggable = on
	end)

	local setNotif = makeToggle(scroll, "Notifications", true, function(on)
		notificationsEnabled = on
	end)

	section(scroll, "CONTROLS (PC)")

	local kRow = make("Frame", {
		LayoutOrder = ord(),
		Size = UDim2.new(1, -8, 0, 48),
		BackgroundColor3 = "Panel",
		BorderSizePixel = 0,
	}, scroll)
	outline(kRow, 8)
	label(kRow, "Show / hide key", 14, {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
	})
	local kBtn = makeButton(kRow, keybind.key.Name, UDim2.new(0, 130, 0, 32), UDim2.new(1, -142, 0.5, -16), false)
	keybind.refresh = function()
		kBtn.Text = keybind.listening and "Press a key..." or keybind.key.Name
	end
	kBtn.MouseButton1Click:Connect(function()
		keybind.listening = true
		keybind.refresh()
	end)

	local resetBtn = makeButton(scroll, "RESET TO DEFAULT", UDim2.new(1, -8, 0, 44), nil, false)
	resetBtn.MouseButton1Click:Connect(function()
		selectedPreset = 1
		applyTheme(PRESETS[1].c)
		selectSwatch(0)
		setScale(1)
		setRoundedToggle(false)
		setStats(true)
		setDrag(true)
		setNotif(true)
		keybind.key = Enum.KeyCode.RightShift
		keybind.listening = false
		keybind.refresh()
		notify("Settings reset")
	end)
end

--------------------------------------------------------------------
-- TOUCHE AFFICHER / MASQUER (PC) - sur mobile : bouton "A" flottant
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
		setWindowVisible(not main.Visible)
	end
end))

--------------------------------------------------------------------
-- DÉMARRAGE
--------------------------------------------------------------------
selectPage("Home")
updateScale()
TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
	Position = UDim2.new(0.5, 0, 0.5, 0),
}):Play()
