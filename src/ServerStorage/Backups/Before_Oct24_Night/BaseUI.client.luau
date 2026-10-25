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
-- DOWNLOADS / INSTALLED buttons
------------------------------------------------------------------
local side = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 10), Size = UDim2.fromOffset(128, 276), BackgroundTransparency = 1, Parent = gui},
	{new("UIListLayout", {Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder})})
local dlButton, dlRefs = UI.fancyButton({Name = "DOWNLOADS", Parent = side, LayoutOrder = 1, Size = UDim2.fromOffset(128, 128), Color = UI.BLUE, Icon = "", Text = "DOWNLOADS", SparkleEvery = 0.6, ShineEvery = 3.5})
local libButton, libRefs = UI.fancyButton({Name = "INSTALLED", Parent = side, LayoutOrder = 2, Size = UDim2.fromOffset(128, 128), Color = UI.GREEN, Icon = "", Text = "INSTALLED", SparkleEvery = 0.6, ShineEvery = 3.5})

-- Hand-drawn icons. Each shape is drawn twice: a black outline layer underneath, then the colour on top.
local BLACK = UI.BLACK
local function iconCanvas(refs)
	return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = refs.Icon},
		{new("UIAspectRatioConstraint", {AspectRatio = 1})})
end
local function blob(parent, x, y, w, h, color, round, rot)
	return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), Rotation = rot or 0, BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent},
		round and {UI.corner(round, true)} or nil)
end
-- a downward triangle: the bottom half of a diamond, clipped
local function arrowHead(parent, x, top, width, color)
	local h = width / 2
	local clip = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, top), Size = UDim2.fromScale(width, h), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent})
	local edge = width / math.sqrt(2)
	new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(edge / width, edge / h), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0, Parent = clip})
end

-- DOWNLOADS: a cloud with an arrow coming down out of it
do
	local c = iconCanvas(dlRefs)
	local function cloud(grow, color)
		blob(c, 0.32, 0.4, 0.4 + grow, 0.4 + grow, color, 1)
		blob(c, 0.54, 0.31, 0.5 + grow, 0.5 + grow, color, 1)
		blob(c, 0.74, 0.44, 0.36 + grow, 0.36 + grow, color, 1)
		blob(c, 0.52, 0.54, 0.72 + grow, 0.26 + grow, color, 0.5)
	end
	cloud(0.08, BLACK)
	cloud(0, UI.WHITE)
	blob(c, 0.52, 0.6, 0.24, 0.4, BLACK)
	arrowHead(c, 0.52, 0.71, 0.6, BLACK)
	blob(c, 0.52, 0.6, 0.15, 0.36, Color3.fromRGB(40, 130, 255))
	arrowHead(c, 0.52, 0.76, 0.44, Color3.fromRGB(40, 130, 255))
end

-- INSTALLED: a game cartridge with a green check badge
do
	local c = iconCanvas(libRefs)
	blob(c, 0.46, 0.5, 0.7, 0.86, BLACK, 0.14)
	local body = blob(c, 0.46, 0.5, 0.6, 0.76, UI.WHITE, 0.12)
	UI.gradient(body, Color3.fromRGB(190, 195, 215), Color3.fromRGB(120, 125, 150), 90)
	blob(c, 0.46, 0.17, 0.3, 0.07, Color3.fromRGB(70, 72, 90), 0.4)
	blob(c, 0.46, 0.45, 0.48, 0.36, BLACK, 0.12)
	local sticker = blob(c, 0.46, 0.45, 0.42, 0.3, UI.WHITE, 0.1)
	UI.gradient(sticker, Color3.fromRGB(255, 120, 200), Color3.fromRGB(130, 80, 255), 45)
	label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.8), Text = "\u{2605}", Outline = 2, Parent = sticker})
	for _, x in ipairs({0.3, 0.41, 0.52, 0.63}) do
		blob(c, x, 0.8, 0.07, 0.08, Color3.fromRGB(255, 205, 60))
	end
	blob(c, 0.8, 0.78, 0.42, 0.42, BLACK, 1)
	blob(c, 0.8, 0.78, 0.34, 0.34, Color3.fromRGB(60, 220, 100), 1)
	label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.78), Size = UDim2.fromScale(0.28, 0.28), Text = "\u{2713}", Outline = 2, Parent = c})
end

-- Gentle motion: slowly turning light rays behind a softly bobbing icon, and twinkling corner stars.
-- One loop drives both buttons, and it rests while the buttons are hidden.
local fancy = {}
for _, pair in ipairs({{dlButton, dlRefs, Color3.fromRGB(170, 220, 255)}, {libButton, libRefs, Color3.fromRGB(190, 255, 190)}}) do
	local btn, refs, rayColor = pair[1], pair[2], pair[3]
	local rays = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.95, 0.95), BackgroundTransparency = 1, ZIndex = btn.ZIndex, Parent = btn})
	for r = 0, 5 do
		new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 14, 1, 0), Rotation = r * 30, BackgroundColor3 = rayColor, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = rays}, {UI.corner(1, true)})
	end
	refs.Icon.ZIndex = btn.ZIndex + 1
	local stars = {}
	for k, corner in ipairs({{0.1, 0.1}, {0.9, 0.12}, {0.12, 0.88}, {0.88, 0.86}}) do
		stars[k] = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(corner[1], corner[2]), Size = UDim2.fromOffset(18, 18), Text = "\u{2726}", TextColor3 = Color3.fromRGB(255, 250, 200), Outline = false, ZIndex = btn.ZIndex + 4, Parent = btn})
	end
	table.insert(fancy, {Button = btn, Rays = rays, Icon = refs.Icon, Home = refs.Icon.Position, Stars = stars})
end
task.spawn(function()
	while true do
		local t = os.clock()
		for _, f in ipairs(fancy) do
			if UI.shown(f.Button) then
				f.Rays.Rotation = (t * 12) % 360
				f.Icon.Position = f.Home + UDim2.fromOffset(0, math.sin(t * 2) * 1.5)
				for k, star in ipairs(f.Stars) do
					star.TextTransparency = 0.55 - math.sin(t * 1.6 + k * 1.7) * 0.45
					star.Rotation = (t * 30 + k * 40) % 360
				end
			end
		end
		task.wait(0.05)
	end
end)

local listPanel = UI.panel(gui, {Name = "Library", Title = "DOWNLOADS", Icon = "\u{2B07}", Color = UI.BLUE, MaxSize = Vector2.new(520, 620), Size = UDim2.fromScale(0.42, 0.8), Position = UDim2.new(1, -140, 0.53, 0)})
listPanel.Frame.AnchorPoint = Vector2.new(1, 0.5)
local listTitle = listPanel.Header:FindFirstChildWhichIsA("TextLabel", true)
for _, l in ipairs(listPanel.Header:GetChildren()) do
	if l:IsA("TextLabel") and l.Text == "DOWNLOADS" then
		listTitle = l
	end
end
local listSub = label({Position = UDim2.fromOffset(20, 4), Size = UDim2.new(1, -40, 0, 24), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(220, 220, 240), Text = "", Outline = 2, Parent = listPanel.Body})
local list = scroller(listPanel.Body, UDim2.fromOffset(12, 34), UDim2.new(1, -24, 1, -46))
new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
new("UIPadding", {PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10), Parent = list})
local emptyText = label({Size = UDim2.new(1, 0, 0, 60), Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(190, 190, 210), Text = "", Visible = false, Outline = 2, Parent = list})

local mode
local latest = {Installing = {}, Installed = {}, IncomePerSecond = 0}
local rows = {}
local skipFunction = remotes:WaitForChild("RequestSkip")

local function makeRow(i)
	local row = new("Frame", {LayoutOrder = i, Size = UDim2.new(1, -6, 0, 92), BackgroundColor3 = UI.PANEL, Parent = list}, {UI.corner(14), UI.stroke(UI.BLACK, 3)})
	local thumb = new("Frame", {Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(61, 76), BackgroundTransparency = 1, ClipsDescendants = true, Parent = row}, {UI.corner(8), UI.stroke(UI.BLACK, 2)})
	local name = label({Position = UDim2.fromOffset(78, 6), Size = UDim2.new(1, -86, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 2.5, Parent = row})
	local info = label({Position = UDim2.fromOffset(78, 33), Size = UDim2.new(1, -86, 0, 16), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 1.5, Parent = row})
	local barBack = new("Frame", {Position = UDim2.fromOffset(78, 56), Size = UDim2.new(1, -176, 0, 26), BackgroundColor3 = Color3.fromRGB(18, 16, 30), Parent = row}, {UI.corner(13), UI.stroke(UI.BLACK, 2)})
	local bar = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.WHITE, Parent = barBack}, {UI.corner(13)})
	UI.gradient(bar, Color3.fromRGB(140, 210, 255), Color3.fromRGB(40, 130, 230), 90)
	local barText = label({Size = UDim2.fromScale(1, 1), Text = "", Outline = 2, ZIndex = 3, Parent = barBack})
	local skip, skipText = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 52), Size = UDim2.fromOffset(86, 32), Text = "", Parent = row, Radius = 10}, UI.PURPLE)
	local earn = label({Position = UDim2.fromOffset(78, 54), Size = UDim2.new(1, -86, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(120, 255, 140), Text = "", Outline = 2.5, Parent = row})
	local r = {Frame = row, Thumb = thumb, Name = name, Info = info, BarBack = barBack, Bar = bar, BarText = barText, Skip = skip, SkipText = skipText, Earn = earn, Key = "", Id = nil}
	skip.Activated:Connect(function()
		if not r.Id then return end
		local ok, result = skipFunction:InvokeServer(r.Id)
		if ok and result == "free" then
			listSub.Text = "Installing now!"
		elseif ok then
			MarketplaceService:PromptProductPurchase(player, result)
		else
			listSub.Text = result or ""
		end
	end)
	return r
end

local function render()
	if not mode then return end
	local items = mode == "downloads" and latest.Installing or latest.Installed
	if mode == "downloads" then
		listTitle.Text = "DOWNLOADS"
		listSub.Text = #items .. " installing  \u{2022}  half speed while you're offline"
		emptyText.Text = "Nothing installing. Steal a game from the Vault!"
	else
		listTitle.Text = "INSTALLED"
		listSub.Text = #items .. " games  \u{2022}  earning $" .. fmt(latest.IncomePerSecond or 0) .. "/s"
		emptyText.Text = "No installed games yet."
	end
	emptyText.Visible = #items == 0
	for i, g in ipairs(items) do
		local row = rows[i] or makeRow(i)
		rows[i] = row
		row.Frame.Visible = true
		row.Id = g.Id
		local key = g.Name .. "|" .. g.Where .. "|" .. tostring(g.Income) .. "|" .. g.Rarity
		if row.Key ~= key then
			row.Key = key
			row.Thumb:ClearAllChildren()
			UI.corner(8).Parent = row.Thumb
			GamePoster.Create({Name = g.Name, Rarity = g.Rarity, Color = Color3.fromHex(g.Color)}).Parent = row.Thumb
			row.Name.Text = g.Name
		end
		row.Info.Text = string.format('<font color="#%s">%s</font>  \u{2022} %s', g.Color, string.upper(g.Rarity), g.Where)
		if mode == "downloads" then
			row.BarBack.Visible, row.Skip.Visible, row.Earn.Visible = true, true, false
			local pct = g.Progress / math.max(1, g.InstallTime)
			row.Bar.Size = UDim2.fromScale(math.clamp(pct, 0.03, 1), 1)
			row.BarText.Text = string.format("%d%%  \u{2022}  %s", math.floor(pct * 100), UI.fmtTime(g.InstallTime - g.Progress))
			row.SkipText.Text = "\u{26A1}" .. UI.ROBUX .. (g.SkipRobux or 9)
		else
			row.BarBack.Visible, row.Skip.Visible, row.Earn.Visible = false, false, true
			row.Earn.Text = "+$" .. fmt(g.Income or 0) .. "/s"
		end
	end
	for i = #items + 1, #rows do
		rows[i].Frame.Visible = false
	end
end

-- Badges count only games you haven't seen in that list yet
local seen = {downloads = {}, installed = {}}
local seenReady = false
local function newCount(list, key)
	local n = 0
	for _, g in ipairs(list) do
		if g.Id and not seen[key][g.Id] then
			n += 1
		end
	end
	return n
end
local function markSeen(key)
	local list = key == "downloads" and latest.Installing or latest.Installed
	for _, g in ipairs(list) do
		if g.Id then
			seen[key][g.Id] = true
		end
	end
end
local function refreshBadges()
	if mode and listPanel.Frame.Visible then
		markSeen(mode)
	end
	local d = newCount(latest.Installing, "downloads")
	local i = newCount(latest.Installed, "installed")
	dlRefs.Badge.Visible = d > 0
	dlRefs.BadgeText.Text = tostring(d)
	libRefs.Badge.Visible = i > 0
	libRefs.BadgeText.Text = tostring(i)
end

local function setMode(m)
	if mode == m and listPanel.Frame.Visible then
		mode = nil
		listPanel.Frame.Visible = false
		return
	end
	mode = m
	UI.open(listPanel)
	render()
	refreshBadges()
end
dlButton.Activated:Connect(function() setMode("downloads") end)
libButton.Activated:Connect(function() setMode("installed") end)
listPanel.Close.Activated:Connect(function() mode = nil end)

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
-- "GAME INSTALLED!" pop-ups, styled by rarity
------------------------------------------------------------------
local RARITY_WORDS = {"Nice!", "Cool!", "Awesome!", "EPIC!", "LEGENDARY!", "MYTHIC!!", "GODLY!!", "SECRET!!!", "CELESTIAL!!!", "INFINITY!!!"}
remotes:WaitForChild("Installed").OnClientEvent:Connect(function(g)
	local color = Color3.fromHex(g.Color)
	if (g.R or 1) >= 10 then
		color = Color3.fromHSV((os.clock() * 0.3) % 1, 0.5, 1)
	end
	local poster = GamePoster.Create({Name = g.Name, Rarity = g.Rarity, Color = Color3.fromHex(g.Color)})
	UI.popup(popGui, {
		Title = string.upper(g.Rarity) .. " INSTALLED! " .. (RARITY_WORDS[g.R or 1] or ""),
		Sub = g.Name .. "  \u{2022}  +$" .. fmt(g.Income) .. "/s",
		Color = color, Poster = poster, Duration = 2.2 + (g.R or 1) * 0.25,
	})
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
local animatedRibbons = {}
local pages, trailCards = {}, {}

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
	end
	-- the swoosh: a wide curved ribbon sweeping back and up
	local ribbon = {}
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
		if idx >= 6 then
			-- bright core line through the swoosh
			new("Part", {Anchored = true, Material = Enum.Material.Neon, Size = Vector3.new(0.72, width * 0.15, 0.32), CFrame = p.CFrame, Color = Color3.new(1, 1, 1), Transparency = 0.2 + a * 0.6, Parent = worldModel})
		end
	end
	-- extra effects for the fancier trails
	local fx = t.Fx
	local function blob(pos, size, color, mat, transp)
		return new("Part", {Anchored = true, Shape = Enum.PartType.Ball, Material = mat or Enum.Material.Neon, Size = Vector3.one * size, CFrame = CFrame.new(pos), Color = color, Transparency = transp or 0, Parent = worldModel})
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
				new("Part", {Anchored = true, Material = Enum.Material.Neon, Size = Vector3.new(0.12, 0.12, (p1 - p0).Magnitude), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Color = sampleColors(t.Colors, k / #pts), Parent = worldModel})
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
	if t.Animated then
		table.insert(animatedRibbons, ribbon)
	end
	local cam = new("Camera", {FieldOfView = 45, Parent = vp})
	cam.CFrame = CFrame.lookAt(Vector3.new(5, 4, 10.5), Vector3.new(-3.5, 2.9, 0))
	vp.CurrentCamera = cam
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

local function refreshTrails()
	local have = owned()
	local equipped = player:GetAttribute("TrailEquipped") or 0
	trailCash.Text = "\u{1F4B5} $" .. fmt(cash())
	for i, c in ipairs(trailCards) do
		local t = trails[i]
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
	local card = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = UI.WHITE, Parent = page}, {UI.corner(22), UI.stroke(UI.BLACK, 5)})
	UI.gradient(card, main:Lerp(Color3.new(1, 1, 1), 0.25), main:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	-- light pattern of little squares like the reference
	for k = 1, 24 do
		new("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromScale(((k - 1) % 6) / 6 + 0.05, math.floor((k - 1) / 6) / 4 + 0.05), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.88, Parent = card}, {UI.corner(4)})
	end
	if i >= 7 then
		UI.sparkles(card, 0.25)
	end
	label({Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 50), Text = t.Name .. " Trail", Outline = 4.5, Parent = card})
	local rc = RARITY_COLORS[t.Rarity] or UI.WHITE
	label({Position = UDim2.fromOffset(20, 64), Size = UDim2.new(1, -40, 0, 28), Text = string.upper(t.Rarity), TextColor3 = rc:Lerp(UI.WHITE, 0.3), Outline = 3, Parent = card})
	trailPicture(card, t, i)
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
			UI.popup(popGui, {Title = "NEW TRAIL!", Sub = t.Name .. "  \u{2022}  x" .. tostring(t.Speed) .. " speed", Color = main, Icon = "\u{2728}", Duration = 2})
		end
		refreshTrails()
	end)
	trailCards[i] = {Text = bt, SetColor = setColor}
	if i < #trails then
		label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 70), Size = UDim2.fromOffset(170, 22), Text = "SCROLL \u{25BC}", TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = 0.15, Outline = 2.5, Parent = card})
	end
end

-- One trail per page: pages are exactly as tall as the window.
-- Each mouse-wheel notch turns one page; a drag (touch) goes to the page you pulled toward.
local page = 1
local function pageHeight()
	return math.max(300, pager.AbsoluteSize.Y)
end
local function sizePages()
	for _, p in ipairs(pages) do
		p.Size = UDim2.new(1, -10, 0, pageHeight())
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
local function goToPage(p)
	page = math.clamp(p, 1, #pages)
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

local function openTrailShop()
	trailMsg.Text = ""
	refreshTrails()
	UI.open(trailPanel)
	sizePages()
	page = currentPage()
	pageLabel.Text = page .. " / " .. #pages
end
player:GetAttributeChangedSignal("TrailsOwned"):Connect(refreshTrails)
player:GetAttributeChangedSignal("TrailEquipped"):Connect(refreshTrails)

RunService.RenderStepped:Connect(function()
	if not trailPanel.Frame.Visible then return end
	local hue = (os.clock() * 0.15) % 1
	for _, ribbon in ipairs(animatedRibbons) do
		for i, p in ipairs(ribbon) do
			p.Color = Color3.fromHSV((hue + i * 0.04) % 1, 0.6, 1)
		end
	end
end)

------------------------------------------------------------------
-- TRAIL TRADER (first time only)
------------------------------------------------------------------
local DIALOGUE = {
	"Hey there! I'm the Trail Trader. Welcome to Steal a Game!",
	"See the Game Vault behind me? Run in, grab a game off a pedestal, and race it back to your base before the shopkeeper catches you!",
	"You won't know how rare a game is until it's home. Games install in your cases, then earn you money every second.",
	"Use the treadmill in your base to get faster, so you can outrun the tougher shopkeepers deeper in.",
	"Check the Index for rewards on every game you find, and spin the Lucky Wheel across the way every day!",
	"And when you've got some cash, come back and see me. My trails will make you look awesome!",
}
local dialog = new("Frame", {Name = "Dialog", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.new(0.7, 0, 0, 180), BackgroundColor3 = UI.WHITE, Visible = false, Parent = gui},
	{UI.corner(20), UI.stroke(UI.BLACK, 4), new("UISizeConstraint", {MaxSize = Vector2.new(820, 180)})})
UI.gradient(dialog, Color3.fromRGB(70, 50, 120), UI.BG, 90)
label({Position = UDim2.fromOffset(22, 12), Size = UDim2.new(1, -44, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Text = "TRAIL TRADER", TextColor3 = Color3.fromRGB(255, 130, 230), Outline = 3, Parent = dialog})
local dialogText = label({Position = UDim2.fromOffset(22, 50), Size = UDim2.new(1, -44, 0, 70), Font = Enum.Font.GothamBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Outline = false, Parent = dialog})
new("UITextSizeConstraint", {MaxTextSize = 22, Parent = dialogText})
local dialogNext, dialogNextText = UI.actionButton({Name = "DialogNext", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -14), Size = UDim2.fromOffset(250, 46), Text = "NEXT", Parent = dialog}, UI.PINK)
local dialogLine = 0
local function showLine(i)
	dialogLine = i
	dialogText.Text = DIALOGUE[i]
	dialogNextText.Text = i < #DIALOGUE and "NEXT" or "SHOW ME THE TRAILS!"
end
dialogNext.Activated:Connect(function()
	if dialogLine < #DIALOGUE then
		showLine(dialogLine + 1)
	else
		dialog.Visible = false
		openTrailShop()
	end
end)

remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function(m)
	if m == "intro" then
		trailPanel.Frame.Visible = false
		showLine(1)
		dialog.Visible = true
	else
		openTrailShop()
	end
end)

------------------------------------------------------------------
-- LUCKY SPIN
------------------------------------------------------------------
local spinData = HttpService:JSONDecode(ReplicatedStorage:WaitForChild("SpinData").Value)
local robux = HttpService:JSONDecode(ReplicatedStorage:WaitForChild("RobuxShopData").Value)
local spinPanel = UI.panel(gui, {Name = "Spin", Title = "LUCKY SPIN", Icon = "\u{1F3A1}", Color = UI.GOLD, MaxSize = Vector2.new(900, 600), Size = UDim2.fromScale(0.8, 0.82)})
local wheelHolder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.31, 0, 0.5, 4), Size = UDim2.fromOffset(470, 470), BackgroundTransparency = 1, Parent = spinPanel.Body})
new("UIAspectRatioConstraint", {Parent = wheelHolder})
local wheel = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.92), BackgroundColor3 = UI.WHITE, Parent = wheelHolder}, {UI.corner(1, true), UI.stroke(UI.BLACK, 6)})
UI.gradient(wheel, Color3.fromRGB(255, 250, 230), Color3.fromRGB(255, 220, 140), 45)
local n = #spinData
-- Coloured rim segments, then a round icon bubble for every prize
for i = 1, n do
	local sa = math.rad((i - 1) * 360 / n)
	local c = Color3.fromHex(spinData[i].Color)
	new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.sin(sa) * 0.43, 0.5 - math.cos(sa) * 0.43), Size = UDim2.fromScale(0.3, 0.07), Rotation = (i - 1) * 360 / n, BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = 2, Parent = wheel}, {UI.corner(1, true)})
end
for i, s in ipairs(spinData) do
	local ang = math.rad((i - 1) * 360 / n)
	local r = 0.3
	local c = Color3.fromHex(s.Color)
	local bubble = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.sin(ang) * r, 0.5 - math.cos(ang) * r),
		Size = UDim2.fromScale(0.2, 0.2), Rotation = (i - 1) * 360 / n, BackgroundColor3 = UI.WHITE, ZIndex = 3, Parent = wheel,
	}, {UI.corner(1, true), UI.stroke(UI.BLACK, 3)})
	UI.gradient(bubble, c:Lerp(UI.WHITE, 0.35), c:Lerp(UI.BLACK, 0.1), 90)
	label({Position = UDim2.fromScale(0.15, 0.15), Size = UDim2.fromScale(0.7, 0.7), Text = s.Icon, Outline = false, ZIndex = 4, Parent = bubble})
	-- thin divider between this prize and the next
	local sa = math.rad((i - 0.5) * 360 / n)
	new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.sin(sa) * 0.27, 0.5 - math.cos(sa) * 0.27), Size = UDim2.new(0, 4, 0.36, 0), Rotation = (i - 0.5) * 360 / n, BackgroundColor3 = Color3.fromRGB(225, 180, 90), BorderSizePixel = 0, ZIndex = 2, Parent = wheel})
end
local hub = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 0.2), BackgroundColor3 = UI.WHITE, ZIndex = 5, Parent = wheel}, {UI.corner(1, true), UI.stroke(UI.BLACK, 4)})
UI.gradient(hub, Color3.fromRGB(255, 240, 140), Color3.fromRGB(240, 160, 30), 90)
label({Position = UDim2.fromScale(0.15, 0.15), Size = UDim2.fromScale(0.7, 0.7), Text = "\u{2B50}", Outline = false, ZIndex = 6, Parent = hub})
label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -22), Size = UDim2.fromOffset(64, 64), Text = "\u{1F53B}", Outline = false, ZIndex = 6, Parent = wheelHolder})

-- Right side: spin buttons on top, prize list underneath
local side = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -22, 0.5, 0), Size = UDim2.new(0.36, 0, 1, -32), BackgroundTransparency = 1, Parent = spinPanel.Body})
local spinButton, spinText, setSpinColor = UI.actionButton({Position = UDim2.fromScale(0, 0), Size = UDim2.new(1, 0, 0, 72), Text = "SPIN!", Parent = side, Radius = 20}, UI.GREEN)
UI.sparkles(spinButton, 0.4)
local spinStatus = label({Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBold, Text = "", Outline = 2, Parent = side})
local buySpin, buySpinText = UI.actionButton({Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 0, 48), Text = "", Parent = side}, UI.PURPLE)
label({Position = UDim2.fromOffset(0, 172), Size = UDim2.new(1, 0, 0, 26), Text = "PRIZES", TextColor3 = UI.GOLD, Outline = 3, Parent = side})
local prizeGrid = new("Frame", {Position = UDim2.fromOffset(0, 204), Size = UDim2.new(1, 0, 1, -204), BackgroundTransparency = 1, Parent = side},
	{new("UIGridLayout", {CellSize = UDim2.new(0.485, 0, 0, 40), CellPadding = UDim2.new(0.03, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
for i, s in ipairs(spinData) do
	local c = Color3.fromHex(s.Color)
	local chip = new("Frame", {LayoutOrder = i, BackgroundColor3 = UI.WHITE, Parent = prizeGrid}, {UI.corner(12), UI.stroke(UI.BLACK, 2.5)})
	UI.gradient(chip, c:Lerp(UI.WHITE, 0.25), c:Lerp(UI.BLACK, 0.2), 90)
	label({Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(32, 32), Text = s.Icon, Outline = false, Parent = chip})
	label({Position = UDim2.fromOffset(40, 7), Size = UDim2.new(1, -46, 1, -14), TextXAlignment = Enum.TextXAlignment.Left, Text = s.Text, Outline = 2, Parent = chip})
end
buySpinText.Text = "+1 SPIN  " .. UI.ROBUX .. " " .. ((robux.Spin and robux.Spin.Price) or 25)
buySpin.Activated:Connect(function()
	if robux.Spin and robux.Spin.Id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, robux.Spin.Id)
	else
		spinStatus.Text = "Extra spins aren't set up yet"
	end
end)

local spinning = false
local function updateSpinStatus()
	if spinning then return end
	local readyAt = player:GetAttribute("SpinReadyAt") or 0
	local extra = player:GetAttribute("ExtraSpins") or 0
	local left = readyAt - workspace:GetServerTimeNow()
	if left <= 0 then
		spinText.Text = "FREE SPIN!"
		setSpinColor(UI.GREEN)
		spinStatus.Text = "Your free spin is ready!"
	elseif extra > 0 then
		spinText.Text = "SPIN! (" .. extra .. ")"
		setSpinColor(UI.GREEN)
		spinStatus.Text = "Next free spin in " .. UI.fmtTime(left)
	else
		spinText.Text = UI.fmtTime(left)
		setSpinColor(Color3.fromRGB(120, 110, 150))
		spinStatus.Text = "Come back for your next free spin!"
	end
end
task.spawn(function()
	while true do
		if spinPanel.Frame.Visible then
			updateSpinStatus()
		end
		task.wait(0.5)
	end
end)

local spinFunction = remotes:WaitForChild("Spin")
spinButton.Activated:Connect(function()
	if spinning then return end
	local ok, idx, text = spinFunction:InvokeServer()
	if not ok then
		spinStatus.Text = idx or ""
		return
	end
	spinning = true
	spinText.Text = "SPINNING..."
	local current = wheel.Rotation % 360
	wheel.Rotation = current
	local target = -(idx - 1) * 360 / n + math.random(-12, 12)
	while target < current + 360 * 5 do
		target += 360
	end
	local tween = TweenService:Create(wheel, TweenInfo.new(4.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Rotation = target})
	tween:Play()
	tween.Completed:Wait()
	local s = spinData[idx]
	UI.popup(popGui, {Title = "YOU WON!", Sub = text, Color = Color3.fromHex(s.Color), Icon = s.Icon, Duration = 3})
	spinning = false
	updateSpinStatus()
end)

remotes:WaitForChild("OpenSpin").OnClientEvent:Connect(function()
	updateSpinStatus()
	UI.open(spinPanel)
end)
