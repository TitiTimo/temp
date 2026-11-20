local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AtlasDashboard"
gui.ResetOnSpawn = false

local uiScale = 1.25
local function scaled(value)
    return UDim2.new(
        value.X.Scale, value.X.Offset * uiScale,
        value.Y.Scale, value.Y.Offset * uiScale
    )
end

local function corner(instance, radius)
    local item = Instance.new("UICorner", instance)
    item.CornerRadius = UDim.new(0, radius * uiScale)
end

local function panel(parent, name, position, size, color, radius)
    local item = Instance.new("Frame", parent)
    item.Name = name
    item.Position = scaled(position)
    item.Size = scaled(size)
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    if radius then
        corner(item, radius)
    end
    return item
end

local colors = {
    backdrop = Color3.fromRGB(10, 12, 20),
    dock = Color3.fromRGB(21, 24, 35),
    card = Color3.fromRGB(28, 32, 46),
    cardRaised = Color3.fromRGB(40, 44, 62),
    text = Color3.fromRGB(242, 244, 250),
    muted = Color3.fromRGB(148, 157, 177),
    accent = Color3.fromRGB(166, 142, 255),
    accentDeep = Color3.fromRGB(58, 46, 97),
    mint = Color3.fromRGB(121, 231, 205),
    close = Color3.fromRGB(239, 96, 109),
}

local fontFamily = "rbxasset://fonts/families/SourceSansPro.json"
local regular = Enum.FontWeight.Regular
local bold = Enum.FontWeight.Bold
local normal = Enum.FontStyle.Normal

local function textLabel(parent, name, text, position, size, textSize, color, isBold, alignment)
    local item = Instance.new("TextLabel", parent)
    item.Name = name
    item.Position = scaled(position)
    item.Size = scaled(size)
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = color or colors.text
    item.TextSize = math.floor((textSize or 14) * uiScale + 0.5)
    item.TextXAlignment = alignment or Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.FontFace = Font.new(fontFamily, isBold and bold or regular, normal)
    return item
end

local function imageLabel(parent, name, asset, position, size, tint)
    local item = Instance.new("ImageLabel", parent)
    item.Name = name
    item.Position = scaled(position)
    item.Size = scaled(size)
    item.BackgroundTransparency = 1
    item.Image = "localasset://" .. asset
    item.ImageColor3 = tint or colors.muted
    item.ScaleType = Enum.ScaleType.Fit
    return item
end

local function floatingPanel(parent, name, position, size, color, radius)
    return panel(parent, name, position, size, color, radius)
end

local function pageHeading(page, title, subtitle)
    textLabel(page, "PageTitle", title, UDim2.new(0, 0, 0, 0),
        UDim2.new(1, 0, 0, 31), 24, colors.text, true)
    textLabel(page, "PageSubtitle", subtitle, UDim2.new(0, 1, 0, 33),
        UDim2.new(1, -2, 0, 19), 13, colors.muted, false)
end

local function metricCard(parent, name, position, size, heading, value, detail, asset, tint)
    local card = floatingPanel(parent, name, position, size, colors.card, 13)
    local iconTile = panel(card, name .. "IconTile", UDim2.new(1, -46, 0, 13),
        UDim2.new(0, 32, 0, 32), colors.cardRaised, 10)
    imageLabel(iconTile, name .. "Icon", asset, UDim2.new(0, 7, 0, 7),
        UDim2.new(0, 18, 0, 18), tint)
    textLabel(card, name .. "Heading", heading, UDim2.new(0, 15, 0, 11),
        UDim2.new(1, -66, 0, 16), 10, colors.muted, true)
    textLabel(card, name .. "Value", value, UDim2.new(0, 15, 0, 31),
        UDim2.new(1, -28, 0, 25), 17, colors.text, true)
    textLabel(card, name .. "Detail", detail, UDim2.new(0, 15, 0, 61),
        UDim2.new(1, -28, 0, 16), 11, colors.muted, false)
    return card
end

panel(gui, "Backdrop", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
    colors.backdrop)

textLabel(gui, "BrandTitle", "Atlas", UDim2.new(0.055, 0, 0.043, 0),
    UDim2.new(0, 100, 0, 31), 24, colors.text, true)
local controls = floatingPanel(gui, "WindowControls",
    UDim2.new(0.81, 0, 0.05, 0), UDim2.new(0, 154, 0, 48),
    colors.dock, 16)
local controlButtons = {}
local controlSpecs = {
    { name = "Minimize", asset = "window-minimize", tint = colors.muted },
    { name = "Maximize", asset = "window-maximize", tint = colors.muted },
    { name = "Close", asset = "window-close", tint = colors.close },
}
for index, spec in ipairs(controlSpecs) do
    local button = Instance.new("ImageButton", controls)
    button.Name = spec.name .. "Button"
    button.Position = scaled(UDim2.new(0, 8 + (index - 1) * 47, 0.5, -17))
    button.Size = scaled(UDim2.new(0, 38, 0, 34))
    button.BackgroundColor3 = colors.cardRaised
    button.BorderSizePixel = 0
    corner(button, 11)
    imageLabel(button, spec.name .. "Icon", spec.asset,
        UDim2.new(0, 10, 0, 8), UDim2.new(0, 18, 0, 18), spec.tint)
    controlButtons[spec.name] = button
end

local workspace = Instance.new("Frame", gui)
workspace.Name = "Workspace"
workspace.Position = UDim2.new(0.055, 0, 0.17, 0)
workspace.Size = UDim2.new(0.89, 0, 0.75, 0)
workspace.BackgroundTransparency = 1
workspace.BorderSizePixel = 0

local dock = floatingPanel(workspace, "NavigationDock",
    UDim2.new(0, 0, 0, 0), UDim2.new(0, 74, 1, 0), colors.dock, 22)

local content = Instance.new("Frame", workspace)
content.Name = "PageContent"
content.Position = scaled(UDim2.new(0, 96, 0, 0))
content.Size = scaled(UDim2.new(1, -96, 1, 0))
content.BackgroundTransparency = 1
content.BorderSizePixel = 0

local homePage = Instance.new("Frame", content)
homePage.Name = "HomePage"
homePage.Size = UDim2.new(1, 0, 1, 0)
homePage.BackgroundTransparency = 1
local accessPage = Instance.new("Frame", content)
accessPage.Name = "AccessPage"
accessPage.Size = UDim2.new(1, 0, 1, 0)
accessPage.BackgroundTransparency = 1
local accountPage = Instance.new("Frame", content)
accountPage.Name = "AccountPage"
accountPage.Size = UDim2.new(1, 0, 1, 0)
accountPage.BackgroundTransparency = 1
local settingsPage = Instance.new("Frame", content)
settingsPage.Name = "SettingsPage"
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1

pageHeading(homePage, "Your space", "Account, access, and recent activity.")
local keyCard = floatingPanel(homePage, "KeyTimeCard",
    UDim2.new(0, 0, 0, 67), UDim2.new(0.62, -10, 0, 145),
    colors.accentDeep, 16)
keyCard.ClipsDescendants = true
local keyVisual = panel(keyCard, "KeyVisual", UDim2.new(1, -132, 0.5, -48),
    UDim2.new(0, 96, 0, 96), colors.cardRaised, 20)
imageLabel(keyVisual, "KeyVisualIcon", "tab-key",
    UDim2.new(0, 23, 0, 23), UDim2.new(0, 50, 0, 50), colors.mint)
local keyTile = panel(keyCard, "KeyIconTile", UDim2.new(0, 18, 0, 17),
    UDim2.new(0, 42, 0, 42), colors.cardRaised, 12)
imageLabel(keyTile, "KeyIcon", "tab-key", UDim2.new(0, 10, 0, 10),
    UDim2.new(0, 22, 0, 22), colors.mint)
textLabel(keyCard, "KeyHeading", "ACCESS KEY",
    UDim2.new(0, 72, 0, 19), UDim2.new(0, 180, 0, 16), 10, colors.mint, true)
textLabel(keyCard, "KeyTimeValue", "6d 14h",
    UDim2.new(0, 18, 0, 67), UDim2.new(0, 280, 0, 39), 30, colors.text, true)
textLabel(keyCard, "KeyTimeDetail", "Time remaining",
    UDim2.new(0, 20, 0, 111), UDim2.new(0, 210, 0, 17), 12, colors.muted, false)

local membershipCard = floatingPanel(homePage, "MembershipCard",
    UDim2.new(0.65, 0, 0, 67), UDim2.new(0.35, 0, 0, 145),
    colors.card, 16)
local memberAvatar = panel(membershipCard, "MemberAvatar",
    UDim2.new(0, 16, 0, 16), UDim2.new(0, 44, 0, 44), colors.cardRaised, 14)
imageLabel(memberAvatar, "MemberIcon", "tab-account",
    UDim2.new(0, 10, 0, 10), UDim2.new(0, 24, 0, 24), colors.accent)
textLabel(membershipCard, "MemberName", "Atlas User",
    UDim2.new(0, 16, 0, 74), UDim2.new(1, -30, 0, 22), 17, colors.text, true)
textLabel(membershipCard, "MemberPlan", "STANDARD MEMBER",
    UDim2.new(0, 17, 0, 101), UDim2.new(1, -30, 0, 16), 9, colors.muted, true)

metricCard(homePage, "DeviceCard", UDim2.new(0, 0, 0, 231),
    UDim2.new(0.333, -8, 0, 91), "DEVICE", "Android",
    "Last seen today", "tab-device", colors.mint)
metricCard(homePage, "ActivityCard", UDim2.new(0.333, 0, 0, 231),
    UDim2.new(0.333, -8, 0, 91), "LAST ACTIVE", "Today",
    "Recent activity", "tab-clock", colors.accent)
metricCard(homePage, "MembershipTypeCard", UDim2.new(0.666, 0, 0, 231),
    UDim2.new(0.334, -2, 0, 91), "MEMBERSHIP", "Standard",
    "Personal plan", "tab-account", colors.mint)

local recentCard = floatingPanel(homePage, "RecentCard",
    UDim2.new(0, 0, 0, 340), UDim2.new(1, 0, 0, 58), colors.card, 13)
local recentIconTile = panel(recentCard, "RecentIconTile",
    UDim2.new(0, 12, 0.5, -17), UDim2.new(0, 34, 0, 34), colors.cardRaised, 10)
imageLabel(recentIconTile, "RecentIcon", "tab-clock",
    UDim2.new(0, 8, 0, 8), UDim2.new(0, 18, 0, 18), colors.accent)
textLabel(recentCard, "RecentTitle", "Recent activity",
    UDim2.new(0, 58, 0, 8), UDim2.new(0, 200, 0, 19), 13, colors.text, true)
textLabel(recentCard, "RecentDetail", "Last active today from an Android device",
    UDim2.new(0, 58, 0, 29), UDim2.new(1, -72, 0, 17), 12, colors.muted, false)

pageHeading(accessPage, "Access", "A clear view of your current key period.")
local accessHero = floatingPanel(accessPage, "AccessHero",
    UDim2.new(0, 0, 0, 67), UDim2.new(1, 0, 0, 165),
    colors.accentDeep, 16)
accessHero.ClipsDescendants = true
local accessVisual = panel(accessHero, "AccessVisual",
    UDim2.new(1, -132, 0.5, -48), UDim2.new(0, 96, 0, 96),
    colors.cardRaised, 20)
imageLabel(accessVisual, "AccessVisualIcon", "tab-key",
    UDim2.new(0, 23, 0, 23), UDim2.new(0, 50, 0, 50), colors.mint)
local accessIconTile = panel(accessHero, "AccessIconTile",
    UDim2.new(0, 19, 0, 18), UDim2.new(0, 44, 0, 44), colors.cardRaised, 13)
imageLabel(accessIconTile, "AccessIcon", "tab-key",
    UDim2.new(0, 10, 0, 10), UDim2.new(0, 24, 0, 24), colors.mint)
textLabel(accessHero, "AccessEyebrow", "TIME REMAINING",
    UDim2.new(0, 77, 0, 20), UDim2.new(0, 200, 0, 18), 10, colors.mint, true)
textLabel(accessHero, "AccessValue", "6 days, 14 hours",
    UDim2.new(0, 19, 0, 76), UDim2.new(0, 360, 0, 40), 28, colors.text, true)
textLabel(accessHero, "AccessDetail", "Current access period",
    UDim2.new(0, 21, 0, 121), UDim2.new(0, 260, 0, 18), 12, colors.muted, false)

metricCard(accessPage, "AccessPlanCard", UDim2.new(0, 0, 0, 220),
    UDim2.new(0.5, -8, 0, 91), "MEMBERSHIP", "Standard",
    "Personal plan", "tab-account", colors.accent)
metricCard(accessPage, "AccessDeviceCard", UDim2.new(0.5, 0, 0, 220),
    UDim2.new(0.5, 0, 0, 91), "DEVICE", "Android",
    "Last seen today", "tab-device", colors.mint)
local accessNote = floatingPanel(accessPage, "AccessNote",
    UDim2.new(0, 0, 0, 331), UDim2.new(1, 0, 0, 58), colors.card, 13)
textLabel(accessNote, "AccessNoteText", "Key time is shown as a fixed dashboard value.",
    UDim2.new(0, 16, 0, 0), UDim2.new(1, -32, 1, 0), 12, colors.muted, false)

pageHeading(accountPage, "Account", "Your profile and connected device.")
local profileCard = floatingPanel(accountPage, "ProfileCard",
    UDim2.new(0, 0, 0, 67), UDim2.new(1, 0, 0, 122), colors.card, 15)
local profileAvatar = panel(profileCard, "ProfileAvatar",
    UDim2.new(0, 18, 0.5, -27), UDim2.new(0, 54, 0, 54), colors.cardRaised, 17)
imageLabel(profileAvatar, "ProfileIcon", "tab-account",
    UDim2.new(0, 13, 0, 13), UDim2.new(0, 28, 0, 28), colors.accent)
textLabel(profileCard, "ProfileName", "Atlas User",
    UDim2.new(0, 88, 0, 31), UDim2.new(0, 220, 0, 25), 19, colors.text, true)
textLabel(profileCard, "ProfileType", "Standard member",
    UDim2.new(0, 89, 0, 59), UDim2.new(0, 220, 0, 19), 12, colors.muted, false)
metricCard(accountPage, "AccountKeyCard", UDim2.new(0, 0, 0, 213),
    UDim2.new(0.5, -8, 0, 91), "KEY TIME LEFT", "6d 14h",
    "Access duration", "tab-key", colors.mint)
metricCard(accountPage, "AccountPlanCard", UDim2.new(0.5, 0, 0, 213),
    UDim2.new(0.5, 0, 0, 91), "MEMBERSHIP", "Standard",
    "Personal plan", "tab-account", colors.accent)
local deviceCard = floatingPanel(accountPage, "AccountDeviceCard",
    UDim2.new(0, 0, 0, 324), UDim2.new(1, 0, 0, 65), colors.card, 13)
local accountDeviceIcon = panel(deviceCard, "AccountDeviceIconTile",
    UDim2.new(0, 13, 0.5, -17), UDim2.new(0, 34, 0, 34), colors.cardRaised, 10)
imageLabel(accountDeviceIcon, "AccountDeviceIcon", "tab-device",
    UDim2.new(0, 8, 0, 8), UDim2.new(0, 18, 0, 18), colors.mint)
textLabel(deviceCard, "AccountDeviceName", "Android device",
    UDim2.new(0, 58, 0, 8), UDim2.new(0, 220, 0, 20), 14, colors.text, true)
textLabel(deviceCard, "AccountDeviceDetail", "Last active today",
    UDim2.new(0, 58, 0, 31), UDim2.new(0, 220, 0, 18), 12, colors.muted, false)

pageHeading(settingsPage, "Settings", "Tune the look and feel of Atlas.")
local themeCard = floatingPanel(settingsPage, "ThemeCard",
    UDim2.new(0, 0, 0, 67), UDim2.new(1, 0, 0, 112), colors.card, 15)
textLabel(themeCard, "ThemeHeading", "COLOR PALETTE",
    UDim2.new(0, 17, 0, 14), UDim2.new(0, 200, 0, 18), 10, colors.muted, true)
textLabel(themeCard, "ThemeName", "Midnight aurora",
    UDim2.new(0, 17, 0, 43), UDim2.new(0, 220, 0, 25), 16, colors.text, true)
local swatches = {
    { x = 0, color = colors.accent },
    { x = 1, color = colors.mint },
    { x = 2, color = colors.accentDeep },
    { x = 3, color = colors.cardRaised },
}
for _, swatch in ipairs(swatches) do
    panel(themeCard, "ThemeSwatch" .. swatch.x,
        UDim2.new(1, -118 + swatch.x * 23, 0.5, -7),
        UDim2.new(0, 14, 0, 14), swatch.color, 7)
end
metricCard(settingsPage, "RenderModeCard", UDim2.new(0, 0, 0, 207),
    UDim2.new(0.5, -8, 0, 91), "RENDER MODE", "Software",
    "CPU rasterizer", "tab-settings", colors.accent)
metricCard(settingsPage, "RefreshRateCard", UDim2.new(0.5, 0, 0, 207),
    UDim2.new(0.5, 0, 0, 91), "FRAME RATE", "60 FPS",
    "Fixed timestep", "tab-clock", colors.mint)
local windowSettings = floatingPanel(settingsPage, "WindowSettings",
    UDim2.new(0, 0, 0, 318), UDim2.new(1, 0, 0, 68), colors.card, 13)
textLabel(windowSettings, "WindowSettingsTitle", "WINDOW CONTROLS",
    UDim2.new(0, 15, 0, 9), UDim2.new(0, 190, 0, 18), 10, colors.muted, true)
textLabel(windowSettings, "WindowSettingsDetail",
    "Minimize, maximize, or close from the floating control dock.",
    UDim2.new(0, 15, 0, 33), UDim2.new(1, -30, 0, 19), 12, colors.text, false)

local pages = {
    { name = "Home", page = homePage, icon = "tab-home" },
    { name = "Access", page = accessPage, icon = "tab-key" },
    { name = "Account", page = accountPage, icon = "tab-account" },
    { name = "Settings", page = settingsPage, icon = "tab-settings" },
}
local pageButtons = {}

local function showPage(selectedName)
    for _, item in ipairs(pages) do
        local selected = item.name == selectedName
        item.page.Visible = selected
        local tab = pageButtons[item.name]
        tab.button.BackgroundColor3 = selected and colors.cardRaised or colors.dock
        tab.label.TextColor3 = selected and colors.text or colors.muted
        tab.icon.ImageColor3 = selected and colors.mint or colors.muted
    end
end

for index, item in ipairs(pages) do
    local pageName = item.name
    local button = Instance.new("ImageButton", dock)
    button.Name = pageName .. "Tab"
    button.Position = scaled(UDim2.new(0, 8, 0, 20 + (index - 1) * 65))
    button.Size = scaled(UDim2.new(0, 58, 0, 59))
    button.BackgroundColor3 = colors.dock
    button.BorderSizePixel = 0
    corner(button, 13)
    local icon = imageLabel(button, "TabIcon", item.icon,
        UDim2.new(0.5, -11, 0, 7), UDim2.new(0, 22, 0, 22), colors.muted)
    local tabLabel = textLabel(button, "TabLabel", pageName,
        UDim2.new(0, 0, 0, 32), UDim2.new(1, 0, 0, 18), 9,
        colors.muted, false, Enum.TextXAlignment.Center)
    pageButtons[pageName] = { button = button, icon = icon, label = tabLabel }
    button.MouseButton1Click:Connect(function()
        showPage(pageName)
    end)
end

local footer = panel(dock, "DockFooter", UDim2.new(0.5, -19, 1, -54),
    UDim2.new(0, 38, 0, 38), colors.cardRaised, 13)
imageLabel(footer, "FooterUserIcon", "tab-account",
    UDim2.new(0, 9, 0, 9), UDim2.new(0, 20, 0, 20), colors.accent)

showPage("Home")

local normalPosition = UDim2.new(0.055, 0, 0.17, 0)
local normalSize = UDim2.new(0.89, 0, 0.75, 0)
local maximized = false
local minimized = false

controlButtons.Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    workspace.Visible = not minimized
end)

controlButtons.Maximize.MouseButton1Click:Connect(function()
    maximized = not maximized
    workspace.Visible = true
    minimized = false
    if maximized then
        workspace.Position = UDim2.new(0.025, 0, 0.13, 0)
        workspace.Size = UDim2.new(0.95, 0, 0.82, 0)
    else
        workspace.Position = normalPosition
        workspace.Size = normalSize
    end
end)

controlButtons.Close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
