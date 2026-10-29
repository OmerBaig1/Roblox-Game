--[[
	BaseUI
	Right side: DOWNLOADS and INSTALLED. Pop-ups when a game finishes installing.
	The Trail Shop (and the Trail Trader's first-time chat) and the Lucky Spin wheel.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local player = Players.LocalPlayer
local new, label, fmt = UI.new, UI.label, UI.fmt

local gui = new("ScreenGui", {Name = "BaseUI", ResetOnSpawn = false, DisplayOrder = 6, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})
local popGui = player.PlayerGui:WaitForChild("PopupUI", 10) or new("ScreenGui", {Name = "PopupUI", ResetOnSpawn = false, DisplayOrder = 20, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player.PlayerGui})

local scroller = UI.scroller

------------------------------------------------------------------
-- DOWNLOADS / INSTALLED: two tiles in the right-hand column (under PETS, which PetsUI draws to match), opening one
-- "My Games" window with a Downloads | Installed switch.
------------------------------------------------------------------
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local C = K.C
local RGB = Color3.fromRGB
-- both HUD guis are drawn on the 1440p design canvas, scaled to the screen (UIKit.canvas)
UI.canvas(gui)
UI.canvas(popGui)

-- the right-hand column: PETS (PetsUI) at 0.5 -174, then these two, 112 px tiles 16 px apart
local side = new("Frame", {Name = "SideTiles", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0.5, -46), Size = UDim2.fromOffset(112, 240), BackgroundTransparency = 1, Parent = gui},
	{new("UIListLayout", {Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder})})
local BLUE, GREEN = RGB(64, 150, 255), RGB(52, 196, 112)
local dlButton, dlRefs = UI.tileButton({Name = "DOWNLOADS", Parent = side, LayoutOrder = 1, Size = 112, Color = BLUE, Text = "DOWNLOADS"})
local libButton, libRefs = UI.tileButton({Name = "INSTALLED", Parent = side, LayoutOrder = 2, Size = 112, Color = GREEN, Text = "INSTALLED"})

-- Icons drawn from shapes (no font glyphs, so they look the same on every device): each shape gets a soft dark
-- copy just below it, so the white reads on any colour
local function shape(parent, x, y, w, h, color, round, rot, z)
	local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), Rotation = rot or 0, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or 6, Parent = parent})
	if round then
		UI.corner(round, true).Parent = f
	end
	return f
end
local function shaded(parent, x, y, w, h, color, round, rot)
	local sh = shape(parent, x, y + 0.045, w, h, UI.BLACK, round, rot, 5)
	sh.BackgroundTransparency = 0.7
	return shape(parent, x, y, w, h, color, round, rot, 6)
end
-- DOWNLOADS: an arrow coming down into a tray
do
	local c = dlRefs.Icon
	shaded(c, 0.5, 0.3, 0.16, 0.46, UI.WHITE, 0.4)
	-- the arrow head: a square turned 45 degrees under the shaft
	shaded(c, 0.5, 0.52, 0.36, 0.36, UI.WHITE, 0.12, 45)
	shaded(c, 0.5, 0.9, 0.86, 0.13, UI.WHITE, 0.5)
	shaded(c, 0.12, 0.8, 0.13, 0.3, UI.WHITE, 0.5)
	shaded(c, 0.88, 0.8, 0.13, 0.3, UI.WHITE, 0.5)
end
-- INSTALLED: a game cartridge with a green tick
do
	local c = libRefs.Icon
	local body = shaded(c, 0.44, 0.5, 0.66, 0.84, UI.WHITE, 0.14)
	UI.gradient(body, RGB(250, 250, 255), RGB(205, 215, 235), 90)
	shape(c, 0.44, 0.38, 0.46, 0.34, GREEN:Lerp(UI.BLACK, 0.15), 0.12, 0, 7)
	for k = 0, 3 do
		shape(c, 0.28 + k * 0.105, 0.82, 0.06, 0.08, RGB(255, 200, 70), nil, 0, 7)
	end
	local ring = shaded(c, 0.8, 0.78, 0.44, 0.44, UI.WHITE, 1)
	local disc = shape(c, 0.8, 0.78, 0.34, 0.34, RGB(40, 200, 100), 1, 0, 7)
	disc.ZIndex = 7
	K.icon(disc, "check", 12, UI.WHITE, 8)
	ring.ZIndex = 6
end

------------------------------------------------------------------
-- THE MY GAMES WINDOW
------------------------------------------------------------------
local LW, LH = 780, 600
local win = K.window(gui, {Name = "Library", W = LW, H = LH, Title = "My Games", Icon = "\u{1F3AE}", Accent = RGB(64, 140, 240), Accent2 = RGB(40, 180, 140), Motion = "pop"})
local body = win.Body
-- the Downloads | Installed switch in the header
local modeButtons = {}
local function modeButton(key, text, order)
	local b = new("TextButton", {Name = key, LayoutOrder = order, Size = UDim2.fromOffset(170, 40), BackgroundColor3 = C.Surface, AutoButtonColor = false, Text = "", ZIndex = 4, Parent = win.Tools},
		{K.corner(), K.stroke(UI.WHITE, 1.5, 0.75)})
	local t = K.text({Text = text, TextSize = 17, FontFace = K.font(Enum.FontWeight.Heavy), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = b})
	modeButtons[key] = {Button = b, Text = t}
	return b
end
local dlTab = modeButton("downloads", "Downloads", 1)
local libTab = modeButton("installed", "Installed", 2)

-- the summary line under the header
local summary = K.text({Text = "", FontFace = K.TITLE, TextSize = 24, Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -48, 0, 30), ZIndex = 3, Parent = body})
local summarySub = K.text({Text = "", TextSize = 15, TextColor3 = C.Text2, Position = UDim2.fromOffset(24, 44), Size = UDim2.new(1, -48, 0, 20), ZIndex = 3, Parent = body})

-- The list. Its padding is wider than a card's border on every side (borders are drawn outside a card and the
-- scroller clips), and the bottom padding leaves the last card fully clear of the window's edge.
local list = new("ScrollingFrame", {Position = UDim2.fromOffset(14, 76), Size = UDim2.new(1, -28, 1, -88), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
	ScrollBarImageColor3 = UI.WHITE, ScrollBarImageTransparency = 0.45, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = body},
	{new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}),
	new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 14)})})
local empty = new("Frame", {Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = list})
local emptyIcon = K.text({Text = "", TextSize = 54, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 64), ZIndex = 4, Parent = empty})
local emptyText = K.text({Text = "", FontFace = K.TITLE, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 28), ZIndex = 4, Parent = empty})
local emptySub = K.text({Text = "", TextSize = 15, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 136), Size = UDim2.new(1, 0, 0, 20), ZIndex = 4, Parent = empty})

local mode
local latest = {Installing = {}, Installed = {}, IncomePerSecond = 0}
local rows = {}
local skipFunction = remotes:WaitForChild("RequestSkip")
local AMBER = RGB(255, 190, 70)

local ROW_H = 100
local function makeRow(i)
	local row = new("Frame", {LayoutOrder = i, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = UI.WHITE, ZIndex = 3, Parent = list}, {K.corner(16)})
	local grad = new("UIGradient", {Rotation = 90, Color = ColorSequence.new(C.Surface2, C.Surface), Parent = row})
	local edge = K.stroke(UI.WHITE, 1.5, 0.86)
	edge.Parent = row
	-- a rarity-coloured strip down the left edge, inside the card
	local strip = new("Frame", {Position = UDim2.fromOffset(0, 14), Size = UDim2.new(0, 4, 1, -28), BorderSizePixel = 0, ZIndex = 4, Parent = row}, {K.corner()})
	local thumb = new("Frame", {Position = UDim2.fromOffset(16, 11), Size = UDim2.fromOffset(62, 78), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 4, Parent = row}, {K.corner(10)})
	local name = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(92, 12), Size = UDim2.new(1, -252, 0, 24), ZIndex = 4, Parent = row})
	local chips = new("Frame", {Position = UDim2.fromOffset(92, 40), Size = UDim2.new(1, -252, 0, 24), BackgroundTransparency = 1, ZIndex = 4, Parent = row},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center})})
	local rarityChip, rarityText = K.chip({Text = "", Height = 24, TextSize = 13, Style = "solid", LayoutOrder = 1, ZIndex = 4, Parent = chips})
	local whereChip, whereText = K.chip({Text = "", Height = 24, TextSize = 13, LayoutOrder = 2, ZIndex = 4, Parent = chips})
	local setBar, barTrack = K.bar({Position = UDim2.fromOffset(92, 72), Size = UDim2.new(1, -252, 0, 14), Color = BLUE, ZIndex = 4, Parent = row})
	local status = K.text({Text = "", TextSize = 14, TextColor3 = C.Text2, Position = UDim2.fromOffset(92, 68), Size = UDim2.new(1, -252, 0, 20), ZIndex = 4, Parent = row})
	-- right column: the skip button (downloads) or what it earns (installed)
	local skip = K.button({Text = "\u{26A1} Skip", Sub = "", Kind = "secondary", TextSize = 17, SubSize = 13, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, -2), Size = UDim2.fromOffset(128, 54), Radius = 12, ZIndex = 4, Parent = row})
	local earn = K.text({Text = "", FontFace = K.TITLE, TextSize = 24, TextColor3 = RGB(120, 255, 150), TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 22), Size = UDim2.fromOffset(140, 30), ZIndex = 4, Parent = row})
	local earnSub = K.text({Text = "per second", TextSize = 13, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 54), Size = UDim2.fromOffset(140, 18), ZIndex = 4, Parent = row})
	local r = {Frame = row, Grad = grad, Edge = edge, Strip = strip, Thumb = thumb, Name = name, RarityChip = rarityChip, RarityText = rarityText, WhereChip = whereChip, WhereText = whereText,
		SetBar = setBar, BarTrack = barTrack, Status = status, Skip = skip, Earn = earn, EarnSub = earnSub, Key = "", Id = nil}
	skip.Activated:Connect(function()
		if not r.Id then return end
		local ok, result = skipFunction:InvokeServer(r.Id)
		if ok and result == "free" then
			summarySub.Text = "Installing now!"
		elseif ok then
			MarketplaceService:PromptProductPurchase(player, result)
		else
			skip.shake()
			summarySub.Text = result or ""
		end
	end)
	return r
end

local function paintModeButtons()
	for key, mb in pairs(modeButtons) do
		local on = key == mode
		local accent = key == "downloads" and BLUE or GREEN
		mb.Button.BackgroundColor3 = on and accent or C.Surface
		mb.Text.TextColor3 = on and UI.WHITE or C.Text2
	end
end

local function render()
	if not mode then return end
	paintModeButtons()
	local items = mode == "downloads" and latest.Installing or latest.Installed
	local installing, carrying = 0, 0
	for _, g in ipairs(latest.Installing) do
		if g.Carrying then
			carrying += 1
		else
			installing += 1
		end
	end
	modeButtons.downloads.Text.Text = "Downloads (" .. #latest.Installing .. ")"
	modeButtons.installed.Text.Text = "Installed (" .. #latest.Installed .. ")"
	if mode == "downloads" then
		summary.Text = installing == 1 and "1 game installing" or (installing .. " games installing")
		summarySub.Text = (carrying > 0 and (carrying .. " in your hands, waiting for a case  \u{2022}  ") or "") .. "Installs keep going at half speed while you're offline"
		emptyIcon.Text, emptyText.Text, emptySub.Text = "\u{2B07}\u{FE0F}", "Nothing installing", "Steal a game from the Vault and put it in a case"
	else
		summary.Text = string.format('Earning <font color="#78ff96">$%s/s</font>', fmt(latest.IncomePerSecond or 0))
		summarySub.Text = #items .. (#items == 1 and " game installed" or " games installed")
		emptyIcon.Text, emptyText.Text, emptySub.Text = "\u{1F3AE}", "No installed games yet", "Games earn money once they finish installing"
	end
	empty.Visible = #items == 0
	for i, g in ipairs(items) do
		local row = rows[i] or makeRow(i)
		rows[i] = row
		row.Frame.Visible = true
		row.Id = g.Id
		local color = Color3.fromHex(g.Color)
		local key = g.Name .. "|" .. g.Rarity
		if row.Key ~= key then
			row.Key = key
			row.Thumb:ClearAllChildren()
			K.corner(10).Parent = row.Thumb
			GamePoster.Create({Name = g.Name, Rarity = g.Rarity, Color = color}).Parent = row.Thumb
			row.Name.Text = g.Name
			row.Strip.BackgroundColor3 = color
			row.RarityChip.BackgroundColor3 = color
			row.RarityText.Text = string.upper(g.Rarity)
		end
		row.WhereText.Text = g.Where
		local carried = mode == "downloads" and g.Carrying
		row.WhereChip.BackgroundColor3 = carried and AMBER or C.Text2
		row.WhereText.TextColor3 = carried and AMBER:Lerp(UI.WHITE, 0.4) or C.Text2:Lerp(UI.WHITE, 0.4)
		if mode == "downloads" then
			row.Earn.Visible, row.EarnSub.Visible = false, false
			if carried then
				-- not installing: that only happens in a case
				row.BarTrack.Visible = false
				row.Status.Visible = true
				row.Status.Text = "Carrying \u{2022} put it in a case to start installing"
				row.Status.TextColor3 = AMBER:Lerp(UI.WHITE, 0.3)
				row.Skip.Holder.Visible = false
			else
				local pct = g.Progress / math.max(1, g.InstallTime)
				row.BarTrack.Visible = true
				row.SetBar(pct)
				row.Status.Visible = false
				row.Skip.Holder.Visible = true
				-- the time left sits in the button, under "Skip"
				row.Skip.setText("\u{26A1} Skip", UI.ROBUX .. (g.SkipRobux or 9) .. "  \u{2022}  " .. UI.fmtTime(g.InstallTime - g.Progress), UI.WHITE)
			end
		else
			row.BarTrack.Visible, row.Status.Visible, row.Skip.Holder.Visible = false, false, false
			row.Earn.Visible, row.EarnSub.Visible = true, true
			row.Earn.Text = "+$" .. fmt(g.Income or 0)
		end
	end
	for i = #items + 1, #rows do
		rows[i].Frame.Visible = false
	end
end

-- Badges count only games you haven't seen in that list yet
local seen = {downloads = {}, installed = {}}
local seenReady = false
local function newCount(items, key)
	local n = 0
	for _, g in ipairs(items) do
		if g.Id and not seen[key][g.Id] then
			n += 1
		end
	end
	return n
end
local function markSeen(key)
	local items = key == "downloads" and latest.Installing or latest.Installed
	for _, g in ipairs(items) do
		if g.Id then
			seen[key][g.Id] = true
		end
	end
end
local function refreshBadges()
	if mode and win.Frame.Visible then
		markSeen(mode)
	end
	local d = newCount(latest.Installing, "downloads")
	local i = newCount(latest.Installed, "installed")
	dlRefs.Badge.Visible = d > 0
	dlRefs.BadgeText.Text = tostring(d)
	libRefs.Badge.Visible = i > 0
	libRefs.BadgeText.Text = tostring(i)
end
local function paintTiles()
	dlRefs.setActive(win.Frame.Visible and mode == "downloads")
	libRefs.setActive(win.Frame.Visible and mode == "installed")
end
win.Frame:GetPropertyChangedSignal("Visible"):Connect(function()
	if not win.Frame.Visible then
		mode = nil
	end
	paintTiles()
end)

local function setMode(m, fromTile)
	if fromTile and mode == m and win.Frame.Visible then
		win.Hide()
		return
	end
	mode = m
	list.CanvasPosition = Vector2.zero
	if not win.Frame.Visible then
		win.Open()
	else
		UI.sfx("page")
	end
	render()
	refreshBadges()
	paintTiles()
end
dlButton.Activated:Connect(function() setMode("downloads", true) end)
libButton.Activated:Connect(function() setMode("installed", true) end)
dlTab.Activated:Connect(function() if mode ~= "downloads" then setMode("downloads") end end)
libTab.Activated:Connect(function() if mode ~= "installed" then setMode("installed") end end)

remotes:WaitForChild("Library").OnClientEvent:Connect(function(data)
	latest = data
	if not seenReady then
		-- games you already had when you joined don't count as new
		seenReady = true
		markSeen("downloads")
		markSeen("installed")
	end
	refreshBadges()
	render()
end)

------------------------------------------------------------------
-- "GAME INSTALLED" toast: a little installer window drops in near the top of
-- the screen, its bar finishes filling, then it flips to INSTALLED in the
-- game's rarity colour. Rarer games get a glow and sparkles. Toasts queue up.
------------------------------------------------------------------
local RARITY_WORDS = {"Nice!", "Cool!", "Awesome!", "EPIC!", "LEGENDARY!", "MYTHIC!!", "GODLY!!", "SECRET!!!", "CELESTIAL!!!", "INFINITY!!!"}
local installSound = new("Sound", {Name = "Installed", SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, PlaybackSpeed = 1.25, Parent = game:GetService("SoundService")})
local toastQueue, toastBusy = {}, false
local TOAST_Y = 250
local function showToast(g)
	toastBusy = true
	local r = g.R or 1
	local color = Color3.fromHex(g.Color)
	local toast = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.fromOffset(440, 96), BackgroundColor3 = UI.WHITE, ZIndex = 40, Parent = popGui}, {UI.corner(16)})
	local stroke = UI.stroke(UI.BLACK, 4)
	stroke.Parent = toast
	UI.gradient(toast, Color3.fromRGB(55, 48, 92), Color3.fromRGB(28, 24, 50), 90)
	-- rarity colour strip down the left edge
	local strip = new("Frame", {Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = color, ZIndex = 41, Parent = toast}, {UI.corner(16)})
	local thumb = new("Frame", {Position = UDim2.fromOffset(18, 8), Size = UDim2.fromOffset(64, 80), BackgroundColor3 = color, ClipsDescendants = true, ZIndex = 41, Parent = toast}, {UI.corner(8), UI.stroke(UI.BLACK, 2.5)})
	local thumbScale = new("UIScale", {Scale = 0, Parent = thumb})
	GamePoster.Create({Name = g.Name, Rarity = g.Rarity, Color = color}).Parent = thumb
	local status = label({Position = UDim2.fromOffset(94, 8), Size = UDim2.new(1, -106, 0, 20), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Text = "\u{2B07} DOWNLOADING...", TextColor3 = Color3.fromRGB(150, 200, 255), Outline = 2, ZIndex = 42, Parent = toast})
	local name = label({Position = UDim2.fromOffset(94, 30), Size = UDim2.new(1, -106, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Text = g.Name, Outline = 3, ZIndex = 42, Parent = toast})
	local barBack = new("Frame", {Position = UDim2.fromOffset(94, 64), Size = UDim2.new(1, -110, 0, 22), BackgroundColor3 = Color3.fromRGB(15, 12, 28), ZIndex = 42, Parent = toast}, {UI.corner(11), UI.stroke(UI.BLACK, 2)})
	local bar = new("Frame", {Size = UDim2.fromScale(0.82, 1), BackgroundColor3 = UI.WHITE, ZIndex = 43, Parent = barBack}, {UI.corner(11)})
	local barGrad = UI.gradient(bar, Color3.fromRGB(140, 210, 255), Color3.fromRGB(40, 130, 230), 0)
	local barText = label({Size = UDim2.fromScale(1, 1), Text = "82%", Outline = 2, ZIndex = 44, Parent = barBack})

	-- 1. drop in from the top
	TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, TOAST_Y)}):Play()
	task.wait(0.35)
	-- 2. the bar finishes filling
	TweenService:Create(bar, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 1)}):Play()
	for pct = 84, 100, 2 do
		barText.Text = pct .. "%"
		task.wait(0.05)
	end
	-- 3. flip to INSTALLED in the rarity colour, with the box art popping in
	installSound:Play()
	status.Text = "\u{2713} INSTALLED!  " .. (RARITY_WORDS[r] or "")
	status.TextColor3 = Color3.fromRGB(130, 255, 150)
	barGrad.Color = ColorSequence.new(color:Lerp(UI.WHITE, 0.4), color)
	barText.Text = string.format('<font color="#%s">%s</font>  \u{2022}  +$%s/s', color:Lerp(UI.WHITE, 0.5):ToHex(), string.upper(g.Rarity), fmt(g.Income))
	TweenService:Create(thumbScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	stroke.Color = color
	TweenService:Create(stroke, TweenInfo.new(0.6), {Color = UI.BLACK}):Play()
	if r >= 4 then
		UI.sparkles(toast, math.max(0.12, 0.5 - r * 0.04))
		UI.shine(toast, 0.8)
	end
	local rainbow = r >= 10
	local hold = 1.8 + r * 0.2
	local t0 = os.clock()
	while os.clock() - t0 < hold do
		if rainbow then
			strip.BackgroundColor3 = Color3.fromHSV((os.clock() * 0.5) % 1, 0.7, 1)
		end
		task.wait(0.05)
	end
	-- 4. slide back up and out
	local out = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -10)})
	out:Play()
	out.Completed:Wait()
	toast:Destroy()
	toastBusy = false
	local nextOne = table.remove(toastQueue, 1)
	if nextOne then
		task.spawn(showToast, nextOne)
	end
end
remotes:WaitForChild("Installed").OnClientEvent:Connect(function(g)
	if toastBusy then
		table.insert(toastQueue, g)
	else
		task.spawn(showToast, g)
	end
end)

------------------------------------------------------------------
-- TRAIL SHOP
------------------------------------------------------------------
local trails = HttpService:JSONDecode(ReplicatedStorage:WaitForChild("TrailData").Value)
local shopFunction = remotes:WaitForChild("TrailShop")
local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(85, 200, 90), Rare = Color3.fromRGB(60, 130, 255),
	Epic = Color3.fromRGB(170, 70, 255), Legendary = Color3.fromRGB(255, 170, 0), Mythic = Color3.fromRGB(255, 50, 90),
	Godly = Color3.fromRGB(255, 230, 80), Celestial = Color3.fromRGB(255, 150, 255), Infinity = Color3.fromRGB(255, 255, 255),
}
local trailPanel = UI.panel(gui, {Name = "Trails", Title = "TRAIL SHOP", Icon = "\u{2728}", Color = UI.PINK, MaxSize = Vector2.new(720, 760), Size = UDim2.fromScale(0.6, 0.9)})
local trailCash = label({Position = UDim2.fromOffset(22, 6), Size = UDim2.new(0.4, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(130, 255, 140), Text = "", Outline = 2.5, Parent = trailPanel.Body})
local pageLabel = label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(160, 28), Text = "", Outline = 2.5, Parent = trailPanel.Body})
local trailMsg = label({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -40, 0, 22), Font = Enum.Font.GothamBold, TextColor3 = UI.GOLD, Text = "", Outline = 2, ZIndex = 20, Parent = trailPanel.Body})
local removeButton = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 2), Size = UDim2.fromOffset(150, 34), Text = "REMOVE TRAIL", Parent = trailPanel.Body}, Color3.fromRGB(120, 110, 150))
local pager = new("ScrollingFrame", {
	Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingEnabled = true, Active = true, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = trailPanel.Body,
}, {new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})

local dummyTemplate = ReplicatedStorage:WaitForChild("TrailDummy", 10)
local pages, trailCards, pageFx = {}, {}, {}

local function sampleColors(hexList, a)
	local n = #hexList
	if n == 1 then
		return Color3.fromHex(hexList[1])
	end
	local x = a * (n - 1)
	local i = math.clamp(math.floor(x) + 1, 1, n - 1)
	return Color3.fromHex(hexList[i]):Lerp(Color3.fromHex(hexList[i + 1]), x - (i - 1))
end

-- A big picture: a character tinted in the trail's colour, running, with a huge swoosh behind
local function trailPicture(parent, t, idx)
	local main = Color3.fromHex(t.Colors[1])
	local vp = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.new(1, -40, 1, -260), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 200), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.5, -1, -0.7), Parent = parent,
	})
	local worldModel = new("WorldModel", {Parent = vp})
	local pic = {Ribbon = {}, Base = {}, Cores = {}, Blobs = {}, Flicker = {}, Colors = t.Colors, Animated = t.Animated}
	if dummyTemplate then
		local d = dummyTemplate:Clone()
		for _, p in ipairs(d:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				if p.Name ~= "HumanoidRootPart" then
					p.Color = main:Lerp(Color3.new(1, 1, 1), 0.15)
					p.Material = Enum.Material.SmoothPlastic
				end
			elseif p:IsA("Decal") then
				p:Destroy()
			end
		end
		local POSE = {
			RightShoulder = 1.3, LeftShoulder = -1.2, RightElbow = 1.2, LeftElbow = 1.0,
			RightHip = -1.0, LeftHip = 1.1, RightKnee = -1.3, LeftKnee = -0.5,
		}
		for _, m in ipairs(d:GetDescendants()) do
			if m:IsA("Motor6D") and POSE[m.Name] then
				m.C0 = m.C0 * CFrame.Angles(POSE[m.Name], 0, 0)
			end
		end
		d:PivotTo(CFrame.lookAt(Vector3.new(0, 2.9, 0), Vector3.new(1, 2.9, 0)) * CFrame.Angles(-0.2, 0, 0))
		local motors = {}
		for _, m in ipairs(d:GetDescendants()) do
			if m:IsA("Motor6D") and m.Part0 and m.Part1 then
				table.insert(motors, m)
			end
		end
		local placed = {[d:FindFirstChild("HumanoidRootPart") or 0] = true}
		local changed = true
		while changed do
			changed = false
			for _, m in ipairs(motors) do
				if placed[m.Part0] and not placed[m.Part1] then
					m.Part1.CFrame = m.Part0.CFrame * m.C0 * m.C1:Inverse()
					placed[m.Part1] = true
					changed = true
				end
			end
		end
		d.Parent = worldModel
		pic.Dummy, pic.DummyHome = d, d:GetPivot()
	end
	-- the swoosh: a wide curved ribbon sweeping back and up
	local ribbon = pic.Ribbon
	local slices = 26
	local width = 2.6 + idx * 0.18
	for i = 1, slices do
		local a = (i - 1) / (slices - 1)
		local x = -0.8 - i * 0.62
		local y = 3 + math.sin(a * math.pi * 0.9) * 2.2 - a * 1.2
		local p = new("Part", {
			Anchored = true, Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.7, width * (1 - a * 0.55), 0.3),
			CFrame = CFrame.new(x, y, a * 1.6) * CFrame.Angles(0, -a * 0.6, math.cos(a * math.pi) * 0.35),
			Color = sampleColors(t.Colors, a), Transparency = a * 0.65, Parent = worldModel,
		})
		table.insert(ribbon, p)
		table.insert(pic.Base, p.CFrame)
		if idx >= 6 then
			-- bright core line through the swoosh
			pic.Cores[#ribbon] = new("Part", {Anchored = true, Material = Enum.Material.Neon, Size = Vector3.new(0.72, width * 0.15, 0.32), CFrame = p.CFrame, Color = Color3.new(1, 1, 1), Transparency = 0.2 + a * 0.6, Parent = worldModel})
		end
	end
	-- extra effects for the fancier trails
	local fx = t.Fx
	-- floating bits that drift back along the swoosh
	local function blob(pos, size, color, mat, transp)
		local p = new("Part", {Anchored = true, Shape = Enum.PartType.Ball, Material = mat or Enum.Material.Neon, Size = Vector3.one * size, CFrame = CFrame.new(pos), Color = color, Transparency = transp or 0, Parent = worldModel})
		table.insert(pic.Blobs, {Part = p, Base = pos, Speed = 2 + math.random() * 3, Phase = math.random() * 6})
		return p
	end
	if fx == "lightning" then
		for bolt = 1, 3 do
			local pts = {}
			local y0 = 1.5 + bolt * 1.2
			for k = 0, 7 do
				table.insert(pts, Vector3.new(-1 - k * 2, y0 + math.random(-10, 10) / 10, 0.5 + math.random(-5, 5) / 10))
			end
			for k = 1, #pts - 1 do
				local p0, p1 = pts[k], pts[k + 1]
				table.insert(pic.Flicker, new("Part", {Anchored = true, Material = Enum.Material.Neon, Size = Vector3.new(0.12, 0.12, (p1 - p0).Magnitude), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Color = sampleColors(t.Colors, k / #pts), Parent = worldModel}))
			end
		end
	elseif fx == "fire" then
		for _ = 1, 14 do
			blob(Vector3.new(-1.5 - math.random() * 12, 2 + math.random() * 3, math.random() - 0.5), 0.4 + math.random() * 0.7, sampleColors(t.Colors, math.random()))
		end
	elseif fx == "stars" then
		for _ = 1, 18 do
			blob(Vector3.new(-1 - math.random() * 15, 1 + math.random() * 5, math.random() * 2 - 1), 0.25 + math.random() * 0.3, Color3.new(1, 1, 1))
		end
	elseif fx == "snow" then
		for _ = 1, 22 do
			blob(Vector3.new(-1 - math.random() * 15, 1 + math.random() * 5, math.random() * 2 - 1), 0.2 + math.random() * 0.25, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		end
	elseif fx == "void" then
		for _ = 1, 8 do
			blob(Vector3.new(-2 - math.random() * 12, 2 + math.random() * 3, math.random() - 0.5), 1 + math.random() * 1.5, Color3.fromRGB(40, 0, 70), Enum.Material.SmoothPlastic, 0.3)
		end
	elseif fx == "glow" then
		for _ = 1, 10 do
			blob(Vector3.new(-1 - math.random() * 12, 1.5 + math.random() * 4, math.random() - 0.5), 0.3 + math.random() * 0.4, sampleColors(t.Colors, math.random()))
		end
	end
	local cam = new("Camera", {FieldOfView = 45, Parent = vp})
	cam.CFrame = CFrame.lookAt(Vector3.new(5, 4, 10.5), Vector3.new(-3.5, 2.9, 0))
	vp.CurrentCamera = cam
	return pic
end

local function owned()
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("TrailsOwned") or "[]")
	end)
	local set = {}
	if ok and type(t) == "table" then
		for _, i in ipairs(t) do
			set[i] = true
		end
	end
	return set
end

local function cash()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Cash")
	return c and c.Value or 0
end

local robuxPrices = {} -- trail -> its Developer Product's price, straight from Roblox (filled in below)
local function refreshTrails()
	local have = owned()
	local equipped = player:GetAttribute("TrailEquipped") or 0
	trailCash.Text = "\u{1F4B5} $" .. fmt(cash())
	for i, c in ipairs(trailCards) do
		local t = trails[i]
		-- a Robux button beside the cash price while you don't own it (greyed "Soon" until the trail has a product, like
		-- the rest of the shop); once owned the cash button takes the whole row
		c.Robux.Visible = not have[i]
		if not have[i] then
			local price = robuxPrices[i]
			c.RobuxText.Text = price and (UI.ROBUX .. " " .. price) or (UI.ROBUX .. " Soon")
			c.RobuxColor(price and Color3.fromRGB(30, 180, 110) or Color3.fromRGB(120, 110, 150))
			c.Button.Position = UDim2.new(0.36, 0, 1, -16)
			c.Button.Size = UDim2.new(0.52, 0, 0, 64)
		else
			c.Button.Position = UDim2.new(0.5, 0, 1, -16)
			c.Button.Size = UDim2.new(0.82, 0, 0, 64)
		end
		if equipped == i then
			c.Text.Text = "EQUIPPED \u{2713}"
			c.SetColor(Color3.fromRGB(120, 110, 150))
		elseif have[i] then
			c.Text.Text = "EQUIP"
			c.SetColor(UI.BLUE)
		else
			c.Text.Text = "BUY  $" .. fmt(t.Price)
			c.SetColor(cash() >= t.Price and UI.GREEN or Color3.fromRGB(190, 70, 80))
		end
	end
end

local function flashTrailMsg(text, color)
	trailMsg.Text = text or ""
	trailMsg.TextColor3 = color or UI.GOLD
	local my = text
	task.delay(2.5, function()
		if trailMsg.Text == my then
			trailMsg.Text = ""
		end
	end)
end

for i, t in ipairs(trails) do
	local main = Color3.fromHex(t.Colors[1])
	local page = new("Frame", {LayoutOrder = i, Size = UDim2.new(1, -10, 0, 500), BackgroundTransparency = 1, Parent = pager})
	pages[i] = page
	local card = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = UI.WHITE, ClipsDescendants = true, Parent = page}, {UI.corner(22), UI.stroke(UI.BLACK, 5)})
	local fx = {Card = card, Scale = new("UIScale", {Parent = card}), Squares = {}}
	fx.Grad = UI.gradient(card, main:Lerp(Color3.new(1, 1, 1), 0.25), main:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	-- little squares that float up the background
	for k = 1, 24 do
		local x, y = ((k - 1) % 6) / 6 + 0.05, math.floor((k - 1) / 6) / 4 + 0.05
		local sq = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Position = UDim2.fromScale(x, y), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.86, Parent = card}, {UI.corner(4)})
		table.insert(fx.Squares, {Frame = sq, X = x, Y = y, Speed = 0.03 + (k % 5) * 0.012})
	end
	pageFx[i] = fx
	if i >= 7 then
		UI.sparkles(card, 0.25)
	end
	label({Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 50), Text = t.Name .. " Trail", Outline = 4.5, Parent = card})
	local rc = RARITY_COLORS[t.Rarity] or UI.WHITE
	label({Position = UDim2.fromOffset(20, 64), Size = UDim2.new(1, -40, 0, 28), Text = string.upper(t.Rarity), TextColor3 = rc:Lerp(UI.WHITE, 0.3), Outline = 3, Parent = card})
	fx.Pic = trailPicture(card, t, i)
	-- speed bonus box
	local box = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -92), Size = UDim2.new(0.82, 0, 0, 62), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Parent = card}, {UI.corner(14), UI.stroke(UI.BLACK, 3)})
	label({Size = UDim2.fromScale(1, 1), Text = string.format('<font color="#78ff5a">x%s</font> Speed', tostring(t.Speed)), Outline = 3.5, Parent = box})
	local b, bt, setColor = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(0.82, 0, 0, 64), Text = "", Parent = card, Radius = 16}, UI.GREEN)
	b.Activated:Connect(function()
		if (player:GetAttribute("TrailEquipped") or 0) == i then return end
		local action = owned()[i] and "equip" or "buy"
		local ok, msg = shopFunction:InvokeServer(action, i)
		flashTrailMsg(msg, ok and UI.GREEN or Color3.fromRGB(255, 120, 120))
		if ok and action == "buy" then
			UI.popup(popGui, {Kind = "trail", Rarity = t.Rarity, Badge = string.upper(t.Rarity or "") .. " TRAIL", Title = "NEW TRAIL!", Sub = t.Name .. "  \u{2022}  x" .. tostring(t.Speed) .. " speed", Color = main, Icon = "\u{2728}", Duration = 2})
		end
		refreshTrails()
	end)
	-- buy with Robux: the same trail, given by the server once the purchase is saved (ProcessReceipt)
	local rb, rbt, setRobuxColor = UI.actionButton({AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.91, 0, 1, -16), Size = UDim2.new(0.27, 0, 0, 64), Text = "", Parent = card, Radius = 16}, Color3.fromRGB(30, 180, 110))
	rb.Visible = false
	rb.Activated:Connect(function()
		if owned()[i] then return end
		if robuxPrices[i] then
			MarketplaceService:PromptProductPurchase(player, t.ProductId)
		else
			flashTrailMsg("Robux purchase coming soon!", UI.GOLD)
		end
	end)
	trailCards[i] = {Button = b, Text = bt, SetColor = setColor, Robux = rb, RobuxText = rbt, RobuxColor = setRobuxColor}
	if i < #trails then
		label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 70), Size = UDim2.fromOffset(170, 22), Text = "SCROLL \u{25BC}", TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = 0.15, Outline = 2.5, Parent = card})
	end
end

-- Robux prices come from Roblox itself, so the button always shows what the player will really pay. A trail without
-- a product ID (or whose price can't be read) has no Robux button.
for i, t in ipairs(trails) do
	if (t.ProductId or 0) ~= 0 then
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, t.ProductId, Enum.InfoType.Product)
			if ok and info and info.PriceInRobux then
				robuxPrices[i] = info.PriceInRobux
				refreshTrails()
			end
		end)
	end
end

-- One trail per page: pages are exactly as tall as the window.
-- Each mouse-wheel notch turns one page; a drag (touch) goes to the page you pulled toward.
local page = 1
local function pageHeight()
	return math.max(300, pager.AbsoluteSize.Y)
end
local function sizePages()
	-- AbsoluteSize is in screen pixels; a page's Size is in the panel's own units, which the HUD canvas scales
	local k = UI.canvasScale(pager)
	for _, p in ipairs(pages) do
		p.Size = UDim2.new(1, -10, 0, pageHeight() / k)
	end
	pager.CanvasPosition = Vector2.new(0, (page - 1) * pageHeight())
end
pager:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizePages)
sizePages()
local function currentPage()
	return math.clamp(math.floor(pager.CanvasPosition.Y / pageHeight() + 0.5) + 1, 1, #pages)
end
pager:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	pageLabel.Text = currentPage() .. " / " .. #pages
end)
-- the card you land on gives a little bounce
local function bouncePage(p)
	local fx = pageFx[p]
	if fx then
		fx.Scale.Scale = 0.9
		TweenService:Create(fx.Scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
end
local function goToPage(p)
	local target = math.clamp(p, 1, #pages)
	if target ~= page then
		bouncePage(target)
	end
	page = target
	TweenService:Create(pager, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(0, (page - 1) * pageHeight())}):Play()
end
local lastWheel = 0
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseWheel or not trailPanel.Frame.Visible then return end
	-- trackpads send lots of tiny wheel events, so turn at most one page every 0.25s
	if os.clock() - lastWheel < 0.25 or input.Position.Z == 0 then return end
	lastWheel = os.clock()
	goToPage(page + (input.Position.Z > 0 and -1 or 1))
end)
task.spawn(function()
	local lastY, still = -1, 0
	while true do
		task.wait(0.05)
		if trailPanel.Frame.Visible and os.clock() - lastWheel > 0.35 then
			local y = pager.CanvasPosition.Y
			still = math.abs(y - lastY) < 0.5 and still + 0.05 or 0
			lastY = y
			local h = pageHeight()
			local moved = (y - (page - 1) * h) / h
			if still >= 0.15 and math.abs(moved) * h > 1 then
				-- pulled more than a little toward another page: go there, otherwise spring back
				local turn = 0
				if moved > 0.12 then
					turn = math.max(1, math.floor(moved + 0.5))
				elseif moved < -0.12 then
					turn = math.min(-1, math.ceil(moved - 0.5))
				end
				goToPage(page + turn)
				still = -0.3
			end
		end
	end
end)

removeButton.Activated:Connect(function()
	local _, msg = shopFunction:InvokeServer("unequip")
	flashTrailMsg(msg, UI.GOLD)
	refreshTrails()
end)

local chatting = false -- the Trail Trader's first-time chat is running: the shop stays shut (see TRAIL TRADER)
local function openTrailShop()
	if chatting then
		return
	end
	trailMsg.Text = ""
	refreshTrails()
	UI.open(trailPanel)
	sizePages()
	page = currentPage()
	pageLabel.Text = page .. " / " .. #pages
	bouncePage(page)
end
player:GetAttributeChangedSignal("TrailsOwned"):Connect(refreshTrails)
player:GetAttributeChangedSignal("TrailEquipped"):Connect(refreshTrails)

-- While the shop is open, the trail on screen comes alive: the swoosh waves and its
-- colours flow, the runner bobs, sparks drift and flicker, and the background shimmers
UI.shine(trailPanel.Header, 2.5)
RunService.RenderStepped:Connect(function()
	if not trailPanel.Frame.Visible then return end
	local fx = pageFx[currentPage()]
	if not fx then return end
	local t = os.clock()
	fx.Grad.Rotation = 90 + math.sin(t * 0.8) * 25
	fx.Grad.Offset = Vector2.new(0, math.sin(t * 1.3) * 0.08)
	for k, sq in ipairs(fx.Squares) do
		sq.Frame.Position = UDim2.fromScale(sq.X + math.sin(t + k) * 0.01, (sq.Y - t * sq.Speed) % 1.05)
		sq.Frame.Rotation = (t * 30 + k * 20) % 360
	end
	local pic = fx.Pic
	local n = #pic.Ribbon
	for i, p in ipairs(pic.Ribbon) do
		local a = (i - 1) / math.max(1, n - 1)
		p.CFrame = pic.Base[i] * CFrame.new(0, math.sin(t * 4 - i * 0.45) * 0.4 * a, 0)
		if pic.Cores[i] then
			pic.Cores[i].CFrame = p.CFrame
		end
		if pic.Animated then
			p.Color = Color3.fromHSV((t * 0.15 + i * 0.04) % 1, 0.9, 1)
		else
			p.Color = sampleColors(pic.Colors, math.abs(((a * 0.8 + t * 0.3) % 2) - 1))
		end
	end
	if pic.Dummy then
		pic.Dummy:PivotTo(pic.DummyHome * CFrame.new(0, math.abs(math.sin(t * 6)) * 0.3, 0))
	end
	for _, b in ipairs(pic.Blobs) do
		local back = (-(b.Base.X + 1) + t * b.Speed) % 15
		b.Part.CFrame = CFrame.new(-1 - back, b.Base.Y + math.sin(t * 2 + b.Phase) * 0.3, b.Base.Z)
	end
	for _, p in ipairs(pic.Flicker) do
		p.Transparency = math.random() < 0.2 and 1 or 0
	end
end)

------------------------------------------------------------------
-- TRAIL TRADER: the first time you talk to him he explains the game in a speech bubble over his head: "..." while
-- he thinks, then each line types out with a little gibberish voice, and he nods and waves his hands while he talks.
-- Click or tap to finish a line, again for the next. The shop stays shut until he's done (the server agrees: it won't
-- sell a trail before then). Afterwards he just says hello and opens the shop.
------------------------------------------------------------------
local DIALOGUE = {
	"Hey there! I'm the Trail Trader. Welcome to Steal a Game!",
	"See the Game Vault behind me? Run in, grab a game off a pedestal, and race it back to your base before the shopkeeper catches you!",
	"You won't know how rare a game is until it's home. Games install in your cases, then earn you money every second.",
	"Use the treadmill in your base to get faster, so you can outrun the tougher shopkeepers deeper in.",
	"Check the Index for rewards on every game you find, and spin the Lucky Wheel across the way every day!",
	"And when you've got some cash, come back and see me. My trails will make you look awesome!",
}
local GREETINGS = {"Back for more? Take a look!", "Fresh trails, just for you!", "Looking fast! Want to look faster?"}
local finishIntro = remotes:WaitForChild("FinishTrailIntro")
local talk = 0           -- 0..1: how much he's moving his head and hands right now
local talkGoal = 0

-- the bubble: a white card with a tail, pinned above his head (fixed on-screen size so it's always readable). It sits
-- clear of the booth, so it doesn't need AlwaysOnTop (which Studio's screenshots don't show, so it couldn't be checked)
local bubbleGui = new("BillboardGui", {Name = "TraderBubble", Size = UDim2.fromOffset(400, 138), SizeOffset = Vector2.new(0, 0.5), StudsOffset = Vector3.new(0, 3.6, 0),
	AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 70, Enabled = false, ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui")})
local bubble = new("Frame", {Size = UDim2.new(1, 0, 1, -16), BackgroundColor3 = UI.WHITE, Parent = bubbleGui}, {UI.corner(22), UI.stroke(Color3.fromRGB(60, 30, 90), 3)})
local bubbleScale = new("UIScale", {Parent = bubble})
local tail = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(22, 22), Rotation = 45, BackgroundColor3 = UI.WHITE, BorderSizePixel = 0, ZIndex = 0, Parent = bubble},
	{UI.stroke(Color3.fromRGB(60, 30, 90), 3)})
-- a white patch hides the tail's top half (its outline would otherwise cross the bubble's edge)
new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -1), Size = UDim2.fromOffset(34, 14), BackgroundColor3 = UI.WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = bubble})
label({Position = UDim2.fromOffset(18, 10), Size = UDim2.fromOffset(200, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.FredokaOne, Text = "TRAIL TRADER", TextColor3 = Color3.fromRGB(235, 70, 190), Outline = false, ZIndex = 3, Parent = bubble})
local bubbleText = label({Position = UDim2.fromOffset(18, 32), Size = UDim2.new(1, -36, 1, -46), TextScaled = false, TextSize = 19, TextWrapped = true, Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(40, 24, 64), Text = "", Outline = false, ZIndex = 3, Parent = bubble})
local more = label({AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -6), Size = UDim2.fromOffset(150, 18), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold,
	Text = "click to continue \u{25B6}", TextColor3 = Color3.fromRGB(150, 110, 200), Outline = false, Visible = false, ZIndex = 3, Parent = bubble})

local trader, traderHead
local function findTrader()
	if traderHead and traderHead.Parent then
		return true
	end
	local map = workspace:FindFirstChild("StealAGameMap")
	local shop = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("TrailShop")
	trader = shop and shop:FindFirstChild("Trail Trader")
	traderHead = trader and trader:FindFirstChild("Head")
	bubbleGui.Adornee = traderHead
	return traderHead ~= nil
end

local function showBubble(on)
	if on and not bubbleGui.Enabled then
		bubbleGui.Enabled = true
		bubbleScale.Scale = 0.6
		TweenService:Create(bubbleScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	elseif not on then
		bubbleGui.Enabled = false
	end
end

-- one line: "..." for a moment, then it types out with his voice. Returns when the line is fully shown.
local skipLine = false
local lineToken = 0
local function sayLine(text)
	lineToken += 1
	local my = lineToken
	skipLine = false
	more.Visible = false
	talkGoal = 0.35
	local t0 = os.clock()
	while os.clock() - t0 < 0.7 and not skipLine and lineToken == my do
		bubbleText.Text = string.rep(".", math.floor((os.clock() - t0) * 6) % 3 + 1)
		task.wait(0.05)
	end
	talkGoal = 1
	local shown = 0
	while shown < #text and lineToken == my do
		if skipLine then
			shown = #text
		else
			shown += 1
			local ch = text:sub(shown, shown)
			-- a soft key tick every other letter, and a voice blip on every third letter, at a random pitch: gibberish
			if ch:match("%w") then
				if shown % 2 == 0 then
					UI.sfx("type")
				end
				if shown % 3 == 0 then
					UI.sfx("pop", 0.85 + math.random() * 0.6)
				end
			end
			-- a beat after the end of a sentence
			task.wait(ch:match("[%.!%?]") and 0.16 or ch == "," and 0.08 or 0.028)
		end
		bubbleText.Text = text:sub(1, shown)
	end
	talkGoal = 0
	skipLine = false
	return lineToken == my
end

-- click / tap: finish the line now, or go on
local waitingNext = false
local advance = Instance.new("BindableEvent")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not bubbleGui.Enabled then return end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
		if waitingNext then
			advance:Fire()
		else
			skipLine = true
		end
	end
end)

local function farAway()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return not root or not traderHead or (root.Position - traderHead.Position).Magnitude > 34
end

local function runIntro()
	if chatting or not findTrader() then return end
	chatting = true
	trailPanel.Frame.Visible = false
	showBubble(true)
	local finished = true
	for i, line in ipairs(DIALOGUE) do
		if not sayLine(line) or farAway() then
			finished = false
			break
		end
		more.Text = i < #DIALOGUE and "click to continue \u{25B6}" or "click to see my trails! \u{25B6}"
		more.Visible = true
		waitingNext = true
		-- walking away ends the chat (it starts over next time)
		local go = false
		local conn = advance.Event:Connect(function() go = true end)
		while not go and not farAway() do
			task.wait(0.05)
		end
		conn:Disconnect()
		waitingNext = false
		if not go then
			finished = false
			break
		end
		UI.sfx("tap")
	end
	more.Visible = false
	showBubble(false)
	talkGoal = 0
	chatting = false
	if finished and finishIntro:InvokeServer() then
		openTrailShop()
	end
end

-- a returning player: one quick line, then the shop. The shop waits until the line is typed and has been up long
-- enough to read (it covers the bubble); a click finishes the line sooner.
local greeting = false
local function greet()
	if greeting then
		return
	end
	if chatting or not findTrader() then
		openTrailShop()
		return
	end
	greeting = true
	showBubble(true)
	local my = lineToken + 1
	sayLine(GREETINGS[math.random(#GREETINGS)])
	task.wait(1.2)
	if lineToken == my then
		showBubble(false)
	end
	greeting = false
	openTrailShop()
end

remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function(m)
	if m == "intro" then
		task.spawn(runIntro)
	elseif not chatting then
		greet()
	end
end)

-- HIS MOVES while talking, layered on top of his idle: he turns toward you, his head bobs and nods with the words,
-- and his hands gesture. Each player's own screen drives it (Motor6D.Transform, no uploaded animation needed).
local traderJoints
RunService.PreSimulation:Connect(function(dt)
	talk += (talkGoal - talk) * math.min(1, dt * 6)
	if talk < 0.01 or not findTrader() then return end
	if not traderJoints then
		local function j(part, name)
			local p = trader:FindFirstChild(part)
			return p and p:FindFirstChild(name)
		end
		traderJoints = {Neck = j("Head", "Neck"), Waist = j("UpperTorso", "Waist"), RS = j("RightUpperArm", "RightShoulder"), RE = j("RightLowerArm", "RightElbow"), LS = j("LeftUpperArm", "LeftShoulder"), LE = j("LeftLowerArm", "LeftElbow")}
	end
	local J = traderJoints
	local t = os.clock()
	-- face the player (about the waist and neck, never more than a quarter turn)
	local yaw = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local troot = trader:FindFirstChild("HumanoidRootPart")
	if root and troot then
		local rel = troot.CFrame:PointToObjectSpace(root.Position)
		yaw = math.clamp(math.atan2(-rel.X, -rel.Z), -0.9, 0.9)
	end
	local k = talk
	if J.Waist then
		J.Waist.Transform *= CFrame.Angles(0, yaw * 0.45 * k + math.sin(t * 2.2) * 0.05 * k, math.sin(t * 3.1) * 0.03 * k)
	end
	if J.Neck then
		J.Neck.Transform *= CFrame.Angles(math.sin(t * 11) * 0.09 * k - 0.04 * k, yaw * 0.45 * k + math.sin(t * 4.3) * 0.08 * k, math.sin(t * 5.7) * 0.05 * k)
	end
	-- hands: a talking gesture that comes and goes
	local g = math.max(0, math.sin(t * 1.7))
	if J.RS then
		J.RS.Transform *= CFrame.Angles((0.5 + 0.35 * g + math.sin(t * 7) * 0.08) * k, 0, -0.15 * k)
	end
	if J.RE then
		J.RE.Transform *= CFrame.Angles((0.9 + math.sin(t * 6) * 0.25) * k, 0, 0)
	end
	if J.LS then
		J.LS.Transform *= CFrame.Angles((0.25 + 0.3 * (1 - g)) * k, 0, 0.1 * k)
	end
	if J.LE then
		J.LE.Transform *= CFrame.Angles((0.6 + math.sin(t * 5 + 1) * 0.2) * k, 0, 0)
	end
end)

------------------------------------------------------------------
-- LUCKY SPIN: the prize wheel on its stage in the lobby, with a SPIN board in front of it. Like the Top 10 board it's
-- always there: press SPIN (or E at the wheel) and it spins right away. The server picks and gives the prize; this
-- screen spins the wheel onto that slice. The wheel turns slowly on its own the rest of the time.
------------------------------------------------------------------
local spinData = HttpService:JSONDecode(ReplicatedStorage:WaitForChild("SpinData").Value)
local robux = HttpService:JSONDecode(ReplicatedStorage:WaitForChild("RobuxShopData").Value)
local spinFunction = remotes:WaitForChild("Spin")
task.spawn(function()
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local lobby = map and map:WaitForChild("Lobby", 60)
	local stage = lobby and lobby:WaitForChild("LuckySpin", 60)
	local wheel = stage and stage:WaitForChild("SpinWheel", 30)
	local boardPart = stage and stage:WaitForChild("SpinBoard", 30)
	local pointer = stage and stage:WaitForChild("Pointer", 30)
	if not (wheel and boardPart and pointer) then return end
	local axis, facing = wheel:GetAttribute("Axis"), wheel:GetAttribute("Facing")
	local n = wheel:GetAttribute("Slices") or #spinData
	local step = math.pi * 2 / n
	local pivot = CFrame.lookAt(axis, axis + facing)

	-- every wheel part, kept relative to the axle so the wheel can be set to any angle
	local parts, slices, labels = {}, {}, {}
	local wheelColors = {}
	for i, s in ipairs(spinData) do
		wheelColors[i] = Color3.fromHex(s.Color)
	end
	for _, p in ipairs(wheel:GetDescendants()) do
		if p:IsA("BasePart") then
			parts[p] = pivot:ToObjectSpace(p.CFrame)
			local i = p:GetAttribute("Slice")
			if i and p.Name == "Slice" then
				slices[i] = slices[i] or {}
				table.insert(slices[i], p)
			elseif i then
				labels[i] = p
			end
		end
	end
	-- angle 0: slice 1 under the pointer; slice i is under it at angle (i - 1) * step
	local angle = 0
	local function setAngle(a)
		angle = a
		local turn = pivot * CFrame.Angles(0, 0, a)
		for p, rel in pairs(parts) do
			p.CFrame = turn * rel
		end
	end

	-- the pointer flicks back as each peg passes under it, then settles
	local pointerHome = pointer.CFrame
	local hinge = CFrame.new(pointerHome.Position + pivot.UpVector * 1.2) * (pivot - pivot.Position)
	local flick = 0

	------------------------------------------------------------------
	-- the board
	local sg = new("SurfaceGui", {Name = "SpinBoardGui", Adornee = boardPart, Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 60, LightInfluence = 0, MaxDistance = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui")})
	local bg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.WHITE, Parent = sg}, {UI.corner(26), UI.stroke(Color3.fromRGB(255, 205, 70), 5)})
	UI.gradient(bg, Color3.fromRGB(78, 48, 160), Color3.fromRGB(26, 16, 58), 90)
	local spinButton, spinText, setSpinColor = UI.actionButton({Position = UDim2.fromOffset(22, 22), Size = UDim2.fromOffset(360, 136), Text = "SPIN!", Parent = bg, Radius = 28}, UI.GREEN)
	local spinStatus = label({Position = UDim2.fromOffset(22, 170), Size = UDim2.fromOffset(360, 44), Font = Enum.Font.GothamBold, Text = "", Outline = 2.5, Parent = bg})
	local caption = label({Position = UDim2.fromOffset(402, 18), Size = UDim2.fromOffset(200, 26), Font = Enum.Font.GothamBold, Text = "FREE SPIN", TextColor3 = Color3.fromRGB(205, 190, 255), Outline = 2, Parent = bg})
	local timer = label({Position = UDim2.fromOffset(402, 44), Size = UDim2.fromOffset(200, 62), Text = "", TextColor3 = Color3.fromRGB(120, 255, 140), Outline = 3.5, Parent = bg})
	local extraText = label({Position = UDim2.fromOffset(402, 110), Size = UDim2.fromOffset(200, 30), Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.fromRGB(255, 220, 120), Outline = 2, Parent = bg})
	local buySpin = UI.actionButton({Position = UDim2.fromOffset(402, 152), Size = UDim2.fromOffset(200, 64), Text = "+1 SPIN  " .. UI.ROBUX .. " " .. ((robux.Spin and robux.Spin.Price) or 25), Parent = bg, Radius = 18}, UI.PURPLE)
	UI.sparkles(spinButton, 0.45)

	local spinning = false
	local function refreshBoard()
		local left = (player:GetAttribute("SpinReadyAt") or 0) - workspace:GetServerTimeNow()
		local extra = player:GetAttribute("ExtraSpins") or 0
		extraText.Text = extra > 0 and ("Extra spins: " .. extra) or "No extra spins"
		if left <= 0 then
			timer.Text = "READY!"
			timer.TextColor3 = Color3.fromRGB(120, 255, 140)
		else
			timer.Text = UI.fmtTime(left)
			timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		if spinning then
			spinText.Text = "SPINNING..."
			setSpinColor(UI.GOLD)
		elseif left <= 0 then
			spinText.Text = "FREE SPIN!"
			setSpinColor(UI.GREEN)
			spinStatus.Text = "Your free spin is ready!"
		elseif extra > 0 then
			spinText.Text = "SPIN!  x" .. extra
			setSpinColor(UI.GREEN)
			spinStatus.Text = "Uses 1 extra spin"
		else
			spinText.Text = "SPIN!"
			setSpinColor(Color3.fromRGB(110, 100, 140))
			spinStatus.Text = "Come back when the timer runs out"
		end
	end
	player:GetAttributeChangedSignal("SpinReadyAt"):Connect(refreshBoard)
	player:GetAttributeChangedSignal("ExtraSpins"):Connect(refreshBoard)
	task.spawn(function()
		while sg.Parent do
			local cam = workspace.CurrentCamera
			if cam and (cam.CFrame.Position - axis).Magnitude < 120 then
				refreshBoard()
			end
			task.wait(0.5)
		end
	end)
	buySpin.Activated:Connect(function()
		if robux.Spin and robux.Spin.Id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, robux.Spin.Id)
		else
			spinStatus.Text = "Extra spins aren't on sale yet"
			UI.sfx("deny")
		end
	end)

	------------------------------------------------------------------
	-- spinning
	local spinFrom, spinTo, spinT0, spinTime
	local holdUntil = 0 -- after a spin the prize stays under the pointer for a moment before the slow turn resumes
	local lastPeg = math.floor((angle + step / 2) / step)
	-- speeds up over the first ~12%, then slows smoothly to a stop (cubic tail: a long, gentle creep onto the slice)
	local UA = 0.12
	local TOTAL = UA / 2 + (1 - UA) / 4
	local function spinCurve(u)
		if u < UA then
			return (u * u / (2 * UA)) / TOTAL
		end
		return (UA / 2 + (1 - UA) / 4 * (1 - ((1 - u) / (1 - UA)) ^ 4)) / TOTAL
	end

	local function celebrate(idx)
		-- the winning slice lights up; the others dim for a moment
		for i, list in pairs(slices) do
			for _, p in ipairs(list) do
				local base = p.Color
				if i == idx then
					p.Material = Enum.Material.Neon
					task.delay(1.6, function()
						p.Material = Enum.Material.SmoothPlastic
					end)
				else
					p.Color = base:Lerp(Color3.new(0, 0, 0), 0.45)
					TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), {Color = base}):Play()
				end
			end
		end
		local tag = labels[idx]
		if tag then
			local at = new("Attachment", {Parent = tag})
			local burst = new("ParticleEmitter", {
				Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromHex(spinData[idx].Color):Lerp(UI.WHITE, 0.4), UI.WHITE),
				LightEmission = 1, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.6, 1.1),
				Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(70, 70), Rate = 0, EmissionDirection = Enum.NormalId.Front, Acceleration = Vector3.new(0, -14, 0), Parent = at,
			})
			burst:Emit(48)
			task.delay(1.4, at.Destroy, at)
		end
	end

	local function spin()
		if spinning then return end
		-- the server decides: no spin left means no wheel, no prize, and a "No spins available!" message on screen
		spinning = true
		local ok, idx, text, gameInfo = spinFunction:InvokeServer()
		if not ok then
			spinning = false
			refreshBoard()
			spinStatus.Text = idx or ""
			UI.sfx("deny")
			return
		end
		refreshBoard()
		UI.sfx("press")
		-- land somewhere inside the slice (never on a divider), at least five full turns ahead
		local goal = (idx - 1) * step + (math.random() - 0.5) * step * 0.64
		while goal < angle + math.pi * 2 * 5 do
			goal += math.pi * 2
		end
		spinFrom, spinTo, spinT0, spinTime = angle, goal, os.clock(), 5.4
		task.wait(spinTime)
		local s = spinData[idx]
		celebrate(idx)
		local color = Color3.fromHex(s.Color)
		-- the rarer the slice, the bigger the reveal (1% Legendary is tier 5, the 28% cash is tier 1)
		local w = s.Weight or 10
		local tier = w <= 1 and 5 or w <= 5 and 4 or w <= 9 and 3 or w <= 14 and 2 or 1
		local opts = {Kind = "spin", Tier = tier, Badge = "LUCKY SPIN", Title = "YOU WON!", Sub = text, Color = color, Icon = s.Icon, WheelColors = wheelColors}
		if gameInfo then
			local gc = Color3.fromHex(gameInfo.Color)
			opts.Poster = GamePoster.Create({Name = gameInfo.Name, Rarity = gameInfo.Rarity, Color = gc})
			opts.Reveal = true
			opts.RevealTitle = string.upper(gameInfo.Rarity) .. " GAME!"
			opts.RevealColor = gc
		end
		UI.popup(popGui, opts)
		spinning = false
		refreshBoard()
	end
	spinButton.Activated:Connect(spin)
	remotes:WaitForChild("OpenSpin").OnClientEvent:Connect(spin)

	RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		local near = cam and (cam.CFrame.Position - axis).Magnitude < 220
		if spinTo then
			local u = math.min(1, (os.clock() - spinT0) / spinTime)
			setAngle(spinFrom + (spinTo - spinFrom) * spinCurve(u))
			if u >= 1 then
				-- settle exactly on the result, kept small so the idle turn carries on from here
				setAngle(spinTo % (math.pi * 2))
				spinTo = nil
				holdUntil = os.clock() + 4
			end
		elseif near and not spinning and os.clock() > holdUntil then
			setAngle((angle + dt * 0.3) % (math.pi * 2))
		end
		-- a peg passed the pointer: a tick (higher as it goes faster) and a flick of the pointer
		local peg = math.floor((angle + step / 2) / step)
		if peg ~= lastPeg then
			lastPeg = peg
			if spinTo then
				flick = 0.32
				UI.sfx("tap", 1 + math.random() * 0.12)
			end
		end
		if flick > 0 then
			flick *= math.exp(-dt * 12)
			if flick < 0.002 then
				flick = 0
			end
			pointer.CFrame = hinge * CFrame.Angles(0, 0, -flick) * hinge:Inverse() * pointerHome
		end
	end)
	refreshBoard()
end)
