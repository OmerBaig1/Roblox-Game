--[[
	MenuUI
	Left menu: SHOP, INDEX, DAILY and the PLAYTIME gift. Small help button top right.
	Also the reward pop-ups. (The first-time tutorial lives in its own script, Tutorial.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local player = Players.LocalPlayer
local new, label, fmt = UI.new, UI.label, UI.fmt

local function decode(name)
	return HttpService:JSONDecode(ReplicatedStorage:WaitForChild(name).Value)
end
local function decodeAttr(name, default)
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute(name) or default)
	end)
	return ok and t or HttpService:JSONDecode(default)
end
local index = decode("GameIndexData")
local rarities = decode("RarityData")
local daily = decode("DailyData")
local robux = decode("RobuxShopData")
local playtime = decode("PlaytimeData")

local gui = new("ScreenGui", {Name = "MenuUI", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})
local popGui = new("ScreenGui", {Name = "PopupUI", ResetOnSpawn = false, DisplayOrder = 20, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player.PlayerGui})

------------------------------------------------------------------
-- MENU BUTTONS
------------------------------------------------------------------
local menu = new("Frame", {
	Name = "Menu", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 40),
	Size = UDim2.fromOffset(248, 400), BackgroundTransparency = 1, Parent = gui,
}, {new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})})

local shopButton, shopRefs = UI.fancyButton({Name = "SHOP", Parent = menu, LayoutOrder = 1, Size = UDim2.fromOffset(244, 86), Color = Color3.fromRGB(255, 80, 170), Icon = "\u{1F6CD}\u{FE0F}", Text = "SHOP", Wide = true, SparkleEvery = 0.35})
-- hot pink to gold, with gold lettering and a tilted HOT! sticker
shopButton:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 200)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 70, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 40)),
})
shopButton:FindFirstChildOfClass("UIGradient").Rotation = 20
UI.gradient(shopRefs.Text, Color3.fromRGB(255, 255, 210), Color3.fromRGB(255, 205, 60), 90)
do
	local hot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -16, 0, 4), Size = UDim2.fromOffset(54, 24), Rotation = 14, BackgroundColor3 = UI.WHITE, ZIndex = 12, Parent = shopButton}, {UI.corner(8), UI.stroke(UI.BLACK, 2.5)})
	UI.gradient(hot, Color3.fromRGB(255, 90, 80), Color3.fromRGB(210, 20, 40), 90)
	label({Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.8), Text = "HOT!", Outline = 2, ZIndex = 13, Parent = hot})
	local s = new("UIScale", {Parent = hot})
	task.spawn(function()
		while hot.Parent do
			TweenService:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Scale = 1.15}):Play()
			task.wait(0.5)
			TweenService:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Scale = 1}):Play()
			task.wait(0.5)
		end
	end)
end
local indexButton, indexRefs = UI.fancyButton({Name = "INDEX", Parent = menu, LayoutOrder = 2, Size = UDim2.fromOffset(244, 86), Color = UI.GOLD, Icon = "\u{1F4D6}", Text = "INDEX", Wide = true, SparkleEvery = 0.45})
-- DAILY and GIFT are smaller square buttons, lined up with the left edge of the wide ones, each with a countdown underneath
local row = new("Frame", {LayoutOrder = 3, Size = UDim2.fromOffset(244, 112), BackgroundTransparency = 1, Parent = menu})
local dailyButton, dailyRefs = UI.fancyButton({Name = "DAILY", Parent = row, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(80, 80), Color = UI.PINK, Icon = "\u{1F4C5}", Text = "DAILY", Radius = 16})
local dailyTimer = label({Position = UDim2.fromOffset(-8, 84), Size = UDim2.fromOffset(96, 24), Text = "", TextColor3 = Color3.fromRGB(255, 170, 230), Outline = 3, Parent = row})
local giftButton, giftRefs = UI.fancyButton({Name = "GIFT", Parent = row, Position = UDim2.fromOffset(92, 0), Size = UDim2.fromOffset(80, 80), Color = Color3.fromRGB(70, 200, 230), Icon = "", Text = "", Radius = 16})
-- the gift turns round and round (it "opens" when you click it, further down)
local giftIcon = giftRefs.Icon
giftIcon.AnchorPoint = Vector2.new(0.5, 0.5)
giftIcon.Position = UDim2.fromScale(0.5, 0.5)
giftIcon.Size = UDim2.fromScale(0.84, 0.86)
giftIcon.Text = "\u{1F381}"
local giftTimer = label({Position = UDim2.fromOffset(84, 84), Size = UDim2.fromOffset(96, 24), Text = "10:00", TextColor3 = Color3.fromRGB(140, 240, 255), Outline = 3, Parent = row})
for _, refs in ipairs({dailyRefs, giftRefs}) do
	refs.Badge.Size = UDim2.fromOffset(24, 24)
end

-- Small help button, top right, next to the player list
local infoButton = UI.fancyButton({Name = "INFO", Parent = gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -340, 0, 8), Size = UDim2.fromOffset(46, 46), Color = UI.BLUE, Icon = "", Text = "", Radius = 12, Border = 3})
label({Size = UDim2.fromScale(1, 1), Text = "?", Outline = 3, ZIndex = 5, Parent = infoButton})

------------------------------------------------------------------
-- PANELS (one at a time)
------------------------------------------------------------------
local panels = {}
local function openPanel(name, onOpen)
	local target = panels[name]
	local wasOpen = target.Frame.Visible
	for _, p in pairs(panels) do
		if p ~= target then
			if p.Hide then
				p.Hide(true)
			else
				p.Frame.Visible = false
			end
		end
	end
	if wasOpen then
		-- the button toggles its menu
		if target.Hide then
			target.Hide()
		else
			target.Frame.Visible = false
		end
		return
	end
	if onOpen then
		onOpen()
	end
	if target.Open then
		target.Open()
	else
		UI.open(target)
	end
end

local scroller = UI.scroller

-- Reward pop-ups from the server (spins, gifts, area rewards)
remotes:WaitForChild("RewardPopup").OnClientEvent:Connect(function(data)
	local opts = {Title = data.Title, Sub = data.Sub, Color = Color3.fromHex(data.Color or "ffcd32"), Icon = data.Icon}
	if data.Game then
		-- a mystery game: the ? cracks open to show the real cover
		local color = Color3.fromHex(data.Game.Color)
		opts.Poster = GamePoster.Create({Name = data.Game.Name, Rarity = data.Game.Rarity, Color = color})
		opts.Reveal = true
		opts.RevealTitle = string.upper(data.Game.Rarity) .. " GAME!"
		opts.RevealColor = color
	end
	UI.popup(popGui, opts)
end)

------------------------------------------------------------------
-- INDEX: a collection journal. The areas run down the left, each with its progress; the chosen area's page is on the
-- right: its preview, progress bar and prize, then every game in it (found ones in colour, the rest as silhouettes).
------------------------------------------------------------------
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local C = K.C
local RGB = Color3.fromRGB
local WHITE, BLACK = UI.WHITE, UI.BLACK
-- light text on a bright card stays readable with a thin dark edge
local function ink(lbl, color)
	new("UIStroke", {Color = color or RGB(40, 20, 50), Thickness = lbl.TextSize >= 24 and 1.8 or 1.2, Transparency = 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = lbl})
	return lbl
end
-- a little burst of stars out of a frame (a claim, a reward)
local function stars(parent, color, count)
	for _ = 1, count do
		local st = K.text({Text = "\u{2726}", FontFace = K.TITLE, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(24, 24), TextColor3 = math.random() < 0.5 and WHITE or color, ZIndex = 30, Parent = parent})
		local ang = math.random() * math.pi * 2
		local d = math.random(50, 110)
		TweenService:Create(st, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, math.cos(ang) * d, 0.5, math.sin(ang) * d), Rotation = math.random(-160, 160), TextTransparency = 1}):Play()
		task.delay(0.65, st.Destroy, st)
	end
end

local IW, IH = 1080, 620
local indexPanel = K.window(gui, {Name = "Index", W = IW, H = IH, Title = "Game Index", Icon = "\u{1F4D6}", Accent = RGB(255, 194, 60), Accent2 = RGB(40, 170, 150),
	Motion = "book", Sounds = {{"page"}}})
panels.Index = indexPanel
local ib = indexPanel.Body
local foundLabel = K.text({Text = "", FontFace = K.TITLE, TextSize = 24, Position = UDim2.fromOffset(22, 10), Size = UDim2.fromOffset(420, 30), ZIndex = 3, Parent = ib})
local setFound = K.bar({Position = UDim2.fromOffset(22, 44), Size = UDim2.fromOffset(420, 14), Color = RGB(255, 200, 70), ZIndex = 3, Parent = ib})
local indexMsg = K.text({Text = "", TextSize = 16, TextColor3 = C.Green, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -258, 0, 22), Size = UDim2.fromOffset(340, 24), ZIndex = 3, Parent = ib})
local claimAll = K.button({Text = "Claim all", Kind = "primary", TextSize = 19, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 10), Size = UDim2.fromOffset(222, 48), ZIndex = 3, Parent = ib})

local cards, areas, grids = {}, {}, {}
local built = false
local totalGames = 0
local currentArea = 1
local previews = ReplicatedStorage:WaitForChild("AreaPreviews", 15)
local claimFunction = remotes:WaitForChild("ClaimIndex")
local areaFunction = remotes:WaitForChild("ClaimArea")

-- the page for the chosen area
local PX = 288
local PW = IW - PX - 20
local page = new("Frame", {Position = UDim2.fromOffset(PX, 74), Size = UDim2.fromOffset(PW, 458), BackgroundTransparency = 1, ZIndex = 3, Parent = ib})
local head = new("Frame", {Size = UDim2.fromOffset(PW, 122), BackgroundColor3 = WHITE, ZIndex = 3, Parent = page}, {K.corner(18), K.stroke(WHITE, 1.5, 0.86)})
new("UIGradient", {Color = ColorSequence.new(C.Surface2:Lerp(RGB(40, 170, 150), 0.18), C.Surface), Parent = head})
local previewHolder = new("Frame", {Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(186, 104), BackgroundTransparency = 1, ZIndex = 4, Parent = head})
local areaName = K.text({Text = "", FontFace = K.TITLE, TextSize = 28, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(212, 10), Size = UDim2.fromOffset(330, 36), ZIndex = 4, Parent = head})
local setArea = K.bar({Position = UDim2.fromOffset(212, 52), Size = UDim2.fromOffset(330, 24), Color = C.Green, ZIndex = 4, Parent = head})
local areaCount = ink(K.text({Text = "", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(212, 52), Size = UDim2.fromOffset(330, 24), ZIndex = 7, Parent = head}))
local areaHint = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Medium), TextSize = 15, TextColor3 = C.Text2, Position = UDim2.fromOffset(212, 84), Size = UDim2.fromOffset(330, 22), ZIndex = 4, Parent = head})
local prize = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 9), Size = UDim2.fromOffset(204, 104), BackgroundColor3 = WHITE, ZIndex = 4, Parent = head}, {K.corner(14), K.stroke(WHITE, 1.5, 0.55)})
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(RGB(255, 224, 112), RGB(240, 148, 40)), Parent = prize})
new("TextLabel", {Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Text = "\u{1F3C6}", TextScaled = true, ZIndex = 5, Parent = prize})
ink(K.text({Text = "Area prize", FontFace = K.TITLE, TextSize = 20, Position = UDim2.fromOffset(56, 8), Size = UDim2.fromOffset(140, 24), ZIndex = 5, Parent = prize}), RGB(120, 60, 0))
K.text({Text = "Big cash + speed", TextSize = 14, TextColor3 = RGB(110, 56, 8), Position = UDim2.fromOffset(56, 30), Size = UDim2.fromOffset(140, 18), ZIndex = 5, Parent = prize})
local prizeBtn = K.button({Text = "Locked", Kind = "ghost", TextSize = 17, Position = UDim2.fromOffset(10, 56), Size = UDim2.fromOffset(184, 40), ZIndex = 5, Parent = prize})
local gridHost = new("Frame", {Position = UDim2.fromOffset(0, 134), Size = UDim2.fromOffset(PW, 324), BackgroundTransparency = 1, ZIndex = 3, Parent = page})

local function makePreview(parent, zoneIndex)
	local vp = new("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = RGB(150, 200, 255), Ambient = RGB(200, 200, 205), LightColor = WHITE, LightDirection = Vector3.new(-0.3, -1, 0.5), ZIndex = 4, Parent = parent},
		{K.corner(12), K.stroke(WHITE, 1.5, 0.7)})
	local model = previews and previews:FindFirstChild(tostring(zoneIndex))
	if model then
		local copy = model:Clone()
		copy.Parent = vp
		local z0 = copy:GetAttribute("Z0") or 0
		local len = copy:GetAttribute("SegLen") or 200
		local cam = Instance.new("Camera")
		cam.FieldOfView = 60
		cam.CFrame = CFrame.lookAt(Vector3.new(28, 34, z0 - 12), Vector3.new(-4, 8, z0 + len * 0.55))
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	return vp
end

-- a short message by the Claim all button that fades by itself
local msgId = 0
local function flashMsg(text, color)
	msgId += 1
	local my = msgId
	indexMsg.Text = text or ""
	indexMsg.TextColor3 = color or WHITE
	indexMsg.TextTransparency = 0
	task.delay(2.5, function()
		if msgId == my then
			TweenService:Create(indexMsg, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		end
	end)
end

local function claim(name, card)
	local ok, msg = claimFunction:InvokeServer(name)
	flashMsg(msg, ok and C.Green or C.Red)
	if ok then
		UI.claimSfx()
		if card then
			stars(card.Frame, RGB(255, 220, 110), 10)
		end
		UI.popup(popGui, {Title = "REWARD CLAIMED!", Sub = msg, Color = UI.GOLD, Icon = "\u{1F4D6}", Duration = 2})
	else
		UI.sfx("deny")
	end
end
claimAll.Activated:Connect(function()
	claim("all")
end)
prizeBtn.Activated:Connect(function()
	local ok, msg = areaFunction:InvokeServer(currentArea)
	if not ok then
		UI.sfx("deny")
		prizeBtn.shake()
		flashMsg(msg, RGB(255, 170, 120))
	else
		stars(prize, RGB(255, 230, 120), 12)
	end
end)

local function setCard(card, info)
	card.Poster:ClearAllChildren()
	K.corner(8).Parent = card.Poster
	if info then
		local r = rarities[info.R] or rarities[1]
		local color = Color3.fromHex(r.Color)
		card.Grad.Color = ColorSequence.new(color:Lerp(C.Surface, 0.45), C.Surface)
		card.Stroke.Color = color
		card.Stroke.Transparency = 0.35
		GamePoster.Create({Name = card.Name, Rarity = r.Name, Color = color}).Parent = card.Poster
		card.Title.Text = card.Name
		card.Title.TextColor3 = WHITE
		card.Claim.Holder.Visible = true
		if info.C then
			card.Line.Text = string.upper(r.Name)
			card.Line.TextColor3 = color:Lerp(WHITE, 0.35)
			card.Claim.setText("Claimed")
			card.Claim.setEnabled(false)
		else
			card.Line.Text = "+$" .. fmt(info.Cash) .. "  +" .. fmt(info.Speed) .. " speed"
			card.Line.TextColor3 = RGB(140, 255, 160)
			card.Claim.setText("Claim")
			card.Claim.setEnabled(true)
		end
	else
		card.Grad.Color = ColorSequence.new(C.Surface2, C.Surface)
		card.Stroke.Color = WHITE
		card.Stroke.Transparency = 0.9
		local sil = GamePoster.Create({Name = card.Name, Rarity = "", Color = BLACK})
		for _, d in ipairs(sil:GetDescendants()) do
			if d:IsA("UIGradient") then
				d:Destroy()
			elseif d:IsA("GuiObject") then
				local full = d.Size == UDim2.fromScale(1, 1)
				d.BackgroundColor3 = full and RGB(78, 70, 112) or RGB(16, 12, 28)
				if d:IsA("TextLabel") then
					d.TextTransparency = 1
					d.TextStrokeTransparency = 1
				end
			end
		end
		sil.BackgroundColor3 = RGB(78, 70, 112)
		sil.Parent = card.Poster
		K.text({Text = "?", FontFace = K.TITLE, TextSize = 44, TextColor3 = RGB(196, 188, 236), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = card.Poster})
		card.Title.Text = "???"
		card.Title.TextColor3 = C.Muted
		card.Line.Text = "Not found yet"
		card.Line.TextColor3 = C.Muted
		card.Claim.Holder.Visible = false
	end
end

local refreshIndex -- below
local areaTabs
-- Only the page you're looking at is inside the window. The others stay built (cards and previews are reused, never
-- rebuilt) but sit outside it, so opening the Index lays out one page instead of all ten (about 6,500 UI objects).
local previewCache = {}
local function showArea(zi)
	currentArea = zi
	local zone = index[zi]
	if not zone then
		return
	end
	for k, vp in pairs(previewCache) do
		if k ~= zi then
			vp.Parent = nil
		end
	end
	if not previewCache[zi] then
		previewCache[zi] = makePreview(nil, zi)
	end
	previewCache[zi].Parent = previewHolder
	areaName.Text = zone.Area
	areaHint.Text = "Find all " .. #zone.Games .. " games for the area prize!"
	for k, g in pairs(grids) do
		g.Parent = k == zi and gridHost or nil
	end
	if grids[zi] then
		grids[zi].CanvasPosition = Vector2.zero
	end
	refreshIndex()
end

-- the areas down the left (scrolls if there are many)
local sideScroll = new("ScrollingFrame", {Position = UDim2.fromOffset(20, 74), Size = UDim2.fromOffset(252, 458), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = ib})
do
	-- each area's own icon (by a word in its name); anything new falls back to a game pad
	local AREA_ICONS = {Basement = "\u{1F3F7}\u{FE0F}", Arcade = "\u{1F579}\u{FE0F}", Toy = "\u{1F9F8}", Pirate = "\u{1F3F4}\u{200D}\u{2620}\u{FE0F}", Haunted = "\u{1F47B}",
		Cyber = "\u{1F306}", Ninja = "\u{26E9}\u{FE0F}", Robot = "\u{1F916}", Dragon = "\u{1F409}", Space = "\u{1FA90}"}
	local items = {}
	for zi, zone in ipairs(index) do
		local icon = "\u{1F3AE}"
		for word, emoji in pairs(AREA_ICONS) do
			if zone.Area:find(word, 1, true) then
				icon = emoji
			end
		end
		items[zi] = {Icon = icon, Text = zone.Area}
	end
	areaTabs = K.sideTabs({Parent = sideScroll, Position = UDim2.new(), Size = UDim2.new(1, -10, 0, 0), Items = items, Height = 50, Gap = 6, Accent = RGB(255, 194, 60), TextSize = 16, ZIndex = 4, Sfx = "page",
		OnSelect = function(zi)
			showArea(zi)
		end})
	areaTabs.Frame.AutomaticSize = Enum.AutomaticSize.Y
end

refreshIndex = function()
	local state = decodeAttr("IndexState", "{}")
	local claimedAreas = {}
	for _, zi in ipairs(decodeAttr("AreaClaimed", "[]")) do
		claimedAreas[tonumber(zi)] = true
	end
	local found, unclaimed = 0, 0
	for _, info in pairs(state) do
		found += 1
		if not info.C then
			unclaimed += 1
		end
	end
	indexRefs.Badge.Visible = unclaimed > 0
	indexRefs.BadgeText.Text = tostring(unclaimed)
	local total = 0
	for zi, zone in ipairs(index) do
		local have = 0
		for _, g in ipairs(zone.Games) do
			total += 1
			if state[g.Name] then
				have += 1
			end
		end
		local n = #zone.Games
		local done = have >= n
		areaTabs.note(zi, have .. "/" .. n, claimedAreas[zi] and C.Gold or (done and C.Green or C.Muted))
		if zi == currentArea then
			setArea(have / n, true)
			areaCount.Text = have .. " / " .. n .. " found"
			if claimedAreas[zi] then
				prizeBtn.setText("Claimed")
				prizeBtn.setKind("ghost")
				prizeBtn.setEnabled(false)
			elseif done then
				prizeBtn.setText("Claim!")
				prizeBtn.setKind("primary")
				prizeBtn.setEnabled(true)
			else
				prizeBtn.setText("Locked")
				prizeBtn.setKind("ghost")
				prizeBtn.setEnabled(false)
			end
		end
	end
	foundLabel.Text = string.format("Found %d <font color=\"#c8c0ec\">of %d games</font>", found, total)
	setFound(found / math.max(total, 1), true)
	claimAll.setText(unclaimed > 0 and ("Claim all (" .. unclaimed .. ")") or "Claim all")
	claimAll.setEnabled(unclaimed > 0)
	if not built then
		return
	end
	for name, card in pairs(cards) do
		local info = state[name]
		local key = info and (info.R .. tostring(info.C)) or "none"
		if card.Key ~= key then
			card.Key = key
			setCard(card, info)
		end
	end
end

-- every area's games, built a few at a time while the Index is hidden so opening it never stutters
local CARD_W, CARD_H, CARD_GAP = 140, 214, 14
local function buildIndex()
	if built then
		return
	end
	built = true
	task.spawn(function()
		for zi, zone in ipairs(index) do
			-- built outside the window; showArea puts the current page in
			local grid = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.5,
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3},
				{new("UIGridLayout", {CellSize = UDim2.fromOffset(CARD_W, CARD_H), CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP), SortOrder = Enum.SortOrder.LayoutOrder}),
				new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 1), PaddingBottom = UDim.new(0, 8)})})
			grids[zi] = grid
			if zi == currentArea then
				grid.Parent = gridHost
			end
			for gi, g in ipairs(zone.Games) do
				totalGames += 1
				local frame = new("Frame", {LayoutOrder = gi, BackgroundColor3 = WHITE, ZIndex = 4, Parent = grid}, {K.corner(14)})
				local grad = new("UIGradient", {Rotation = 90, Parent = frame})
				local stroke = K.stroke(WHITE, 1.5, 0.9)
				stroke.Parent = frame
				local poster = new("Frame", {Position = UDim2.fromOffset(18, 10), Size = UDim2.fromOffset(104, 124), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5, Parent = frame})
				local title = K.text({Text = "", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(6, 138), Size = UDim2.fromOffset(CARD_W - 12, 18), ZIndex = 5, Parent = frame})
				local line = K.text({Text = "", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(6, 156), Size = UDim2.fromOffset(CARD_W - 12, 16), ZIndex = 5, Parent = frame})
				local claimB = K.button({Text = "Claim", Kind = "primary", TextSize = 15, Position = UDim2.fromOffset(12, 176), Size = UDim2.fromOffset(CARD_W - 24, 30), Radius = 10, ZIndex = 5, Parent = frame})
				local card = {Name = g.Name, Frame = frame, Grad = grad, Stroke = stroke, Poster = poster, Title = title, Line = line, Claim = claimB, Key = ""}
				claimB.Activated:Connect(function()
					local info = decodeAttr("IndexState", "{}")[g.Name]
					if info and not info.C then
						claim(g.Name, card)
					end
				end)
				cards[g.Name] = card
				if gi % 3 == 0 then
					task.wait()
				end
			end
			refreshIndex()
			task.wait()
		end
	end)
end

player:GetAttributeChangedSignal("IndexState"):Connect(refreshIndex)
player:GetAttributeChangedSignal("AreaClaimed"):Connect(refreshIndex)
areaTabs.select(1, true)
-- Build the Index quietly while it's hidden, so opening it is as smooth as the Shop
task.delay(4, buildIndex)

indexButton.Activated:Connect(function()
	openPanel("Index", function()
		indexMsg.Text = ""
		buildIndex()
		refreshIndex()
	end)
end)

------------------------------------------------------------------
-- SHOP (Robux): categories down the left; the list on the right scrolls through them (the tabs follow it).
-- The pictures breathe and wiggle on hover, driven by one per-frame loop that only runs while the shop is open.
------------------------------------------------------------------
local shopPanel = K.window(gui, {Name = "Shop", W = 1080, H = 620, Title = "Shop", Icon = "\u{1F6CD}\u{FE0F}", Accent = RGB(255, 84, 170), Accent2 = RGB(255, 168, 48),
	Motion = "rise", Sounds = {{"coin"}}})
panels.Shop = shopPanel
local sb = shopPanel.Body
local CATS = {
	{Key = "featured", Icon = "\u{2B50}", Text = "Featured", Color = RGB(255, 190, 60)},
	{Key = "passes", Icon = "\u{1F3AB}", Text = "Game Passes", Color = RGB(255, 90, 170)},
	{Key = "boosts", Icon = "\u{26A1}", Text = "Boosts", Color = RGB(90, 170, 255)},
	{Key = "speed", Icon = "\u{1F45F}", Text = "Speed Packs", Color = RGB(70, 210, 200)},
	{Key = "cash", Icon = "\u{1F4B0}", Text = "Cash Packs", Color = RGB(110, 220, 90)},
}
local LX = 256
local shopList = new("ScrollingFrame", {Position = UDim2.fromOffset(LX, 14), Size = UDim2.fromOffset(1080 - LX - 14, 524), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
	ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.45, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = sb},
	{new("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder}), new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 18)})})
local CW = 1080 - LX - 14 - 14 -- content width beside the scroll bar
local shopButtons = {}
local shopSections = {}
local syncing = false
local catTabs = K.sideTabs({Parent = sb, Position = UDim2.fromOffset(20, 14), Size = UDim2.fromOffset(218, 0), Items = CATS, Height = 56, Gap = 8, Accent = RGB(255, 84, 170), TextSize = 17, ZIndex = 4,
	OnSelect = function(i)
		if syncing then
			return
		end
		local target = shopSections[CATS[i].Key]
		if target then
			local y = target.AbsolutePosition.Y - shopList.AbsolutePosition.Y + shopList.CanvasPosition.Y
			-- the window is scaled to the screen; canvas units are unscaled
			local s = shopList.AbsoluteSize.Y / shopList.Size.Y.Offset
			TweenService:Create(shopList, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {CanvasPosition = Vector2.new(0, math.max(0, y / s - 2))}):Play()
		end
	end})
-- a little "you're supporting the game" note under the tabs
K.text({Text = "Every purchase helps us make the game bigger. Thank you!", TextSize = 14, TextColor3 = C.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromOffset(24, 340), Size = UDim2.fromOffset(210, 60), ZIndex = 3, Parent = sb})

-- SHOP ICONS: a big picture with a glowing aura and slowly turning light rays behind it. It breathes gently on its own;
-- hover the card and it wiggles, the aura spins faster and stars burst out.
local ICON_EXTRA = {
	Starter = "\u{2B50}", DoubleMoney = "\u{1F4B5}", DoubleSpeed = "\u{26A1}", DoubleSteal = "\u{270B}",
	Treadmill = "\u{26A1}", Spin = "\u{1F340}", SpeedS = "\u{1F4A8}", SpeedM = "\u{1F45F}", SpeedL = "\u{2728}",
	SpeedXL = "\u{26A1}", SpeedXXL = "\u{1F680}", Cash5 = "\u{2728}", CashS = "\u{1FA99}", CashL = "\u{1F48E}",
	CashXL = "\u{1F4B0}", CashXXL = "\u{1F451}",
}
local shopIcons = {}
local function shopIcon(card, key, look, size, pos)
	local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = 5, Parent = card})
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86), BackgroundColor3 = look.B:Lerp(WHITE, 0.7), BackgroundTransparency = 0.5, ZIndex = 5, Parent = holder}, {K.corner()})
	local aura = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3), BackgroundTransparency = 1, ZIndex = 5, Parent = holder})
	for i = 0, 5 do
		local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.13, 0, 1, 0), Rotation = i * 30, BackgroundColor3 = WHITE, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 5, Parent = aura}, {K.corner()})
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
	end
	local pic = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Parent = holder})
	local scale = new("UIScale", {Parent = pic})
	new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = look.Icon, TextScaled = true, ZIndex = 6, Parent = pic})
	if ICON_EXTRA[key] then
		new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.82), Size = UDim2.fromScale(0.44, 0.44), Rotation = 14, BackgroundTransparency = 1, Text = ICON_EXTRA[key], TextScaled = true, ZIndex = 7, Parent = pic})
	end
	local a = {Pic = pic, Scale = scale, Aura = aura, Glow = glow, Phase = #shopIcons * 0.9, Hover = false, H = 0, Wiggle = #shopIcons * 0.9}
	table.insert(shopIcons, a)
	card.MouseEnter:Connect(function()
		a.Hover = true
		stars(holder, RGB(255, 240, 150), 6)
	end)
	card.MouseLeave:Connect(function()
		a.Hover = false
		a.H = 0
	end)
	return holder
end

-- a colourful card: the look's two colours, a soft shine across the top, one light outline
local function shopCard(parent, look, order, size)
	local card = new("Frame", {LayoutOrder = order or 0, Size = size or UDim2.new(), BackgroundColor3 = WHITE, ZIndex = 4, Parent = parent}, {K.corner(20), K.stroke(WHITE, 2, 0.55)})
	new("UIGradient", {Rotation = 115, Color = ColorSequence.new(look.A, look.B), Parent = card})
	new("Frame", {Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0.38, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.84, ZIndex = 4, Parent = card}, {K.corner(16)})
	return card
end

local ROBUX = UI.ROBUX
local function priceButton(parent, item, kind, pos, size, anchor, textSize)
	local b = K.button({Text = "", Kind = "primary", TextSize = textSize or 22, AnchorPoint = anchor, Position = pos, Size = size, ZIndex = 6, Parent = parent})
	shopButtons[item.Key] = {Btn = b, Item = item, Kind = kind}
	b.Activated:Connect(function()
		if item.Id == 0 then
			return
		end
		if kind == "pass" then
			if player:GetAttribute("Pass_" .. item.Key) then return end
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			if item.OneTime and player:GetAttribute("StarterBought") then return end
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
	end)
end

local function sectionTitle(order, cat)
	local f = new("Frame", {LayoutOrder = order, Size = UDim2.fromOffset(CW, 40), BackgroundTransparency = 1, ZIndex = 4, Parent = shopList})
	shopSections[cat.Key] = f
	new("TextLabel", {Position = UDim2.fromOffset(2, 4), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Text = cat.Icon, TextScaled = true, ZIndex = 4, Parent = f})
	local t = K.text({Text = cat.Text, FontFace = K.TITLE, TextSize = 26, Position = UDim2.fromOffset(42, 0), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 4, Parent = f})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, cat.Color:Lerp(WHITE, 0.4)), Parent = t})
	new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(1, -260, 0, 2), BackgroundColor3 = cat.Color, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Parent = f})
end

local function findItem(list, key)
	for _, it in ipairs(list) do
		if it.Key == key then
			return it
		end
	end
end
local function grid(order, cellW, cellH, cols)
	-- a short last row sits in the middle instead of leaving a gap on the right
	return new("Frame", {LayoutOrder = order, Size = UDim2.fromOffset(CW, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 4, Parent = shopList},
		{new("UIGridLayout", {CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset((CW - cols * cellW) / math.max(1, cols - 1), 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
end

-- Featured: the Starter Pack
sectionTitle(1, CATS[1])
do
	local starter = findItem(robux.Products, "Starter")
	local card = shopCard(shopList, {A = RGB(255, 226, 92), B = RGB(255, 128, 40)}, 2, UDim2.fromOffset(CW, 196))
	shopIcon(card, "Starter", {Icon = "\u{1F381}", B = RGB(255, 160, 40)}, 150, UDim2.fromOffset(104, 98))
	ink(K.text({Text = "Starter Pack", FontFace = K.TITLE, TextSize = 40, Position = UDim2.fromOffset(200, 18), Size = UDim2.fromOffset(340, 46), ZIndex = 6, Parent = card}), RGB(130, 50, 0))
	for i, line in ipairs({"$25,000 Cash", "+5,000 Speed", "A free Epic Game"}) do
		ink(K.text({Text = "\u{2714}  " .. line, TextSize = 20, Position = UDim2.fromOffset(204, 66 + (i - 1) * 32), Size = UDim2.fromOffset(330, 28), ZIndex = 6, Parent = card}), RGB(130, 50, 0))
	end
	K.chip({Text = "ONE TIME ONLY", Color = RGB(255, 70, 90), Style = "solid", TextSize = 14, Height = 26, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 22), ZIndex = 6, Parent = card})
	if starter then
		priceButton(card, starter, "product", UDim2.new(1, -22, 1, -22), UDim2.fromOffset(210, 72), Vector2.new(1, 1), 26)
	end
end

-- Game passes: two to a row
sectionTitle(3, CATS[2])
local PASS_LOOK = {
	DoubleMoney = {Icon = "\u{1F4B0}", A = RGB(255, 236, 140), B = RGB(248, 176, 40)},
	DoubleSpeed = {Icon = "\u{1F45F}", A = RGB(170, 255, 200), B = RGB(50, 196, 120)},
	DoubleSteal = {Icon = "\u{1F3AE}", A = RGB(255, 180, 200), B = RGB(226, 56, 116)},
}
do
	local g = grid(4, (CW - 14) / 2, 210, 2)
	for i, pass in ipairs(robux.Passes) do
		local look = PASS_LOOK[pass.Key] or PASS_LOOK.DoubleMoney
		local card = shopCard(g, look, i)
		shopIcon(card, pass.Key, look, 126, UDim2.fromOffset(80, 92))
		local two = ink(K.text({Text = "2X", FontFace = K.TITLE, TextSize = 46, TextXAlignment = Enum.TextXAlignment.Center, Rotation = -12, Position = UDim2.fromOffset(84, 118), Size = UDim2.fromOffset(84, 56), ZIndex = 8, Parent = card}), RGB(120, 50, 0))
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new(RGB(255, 248, 170), RGB(255, 170, 30)), Parent = two})
		ink(K.text({Text = pass.Name, FontFace = K.TITLE, TextSize = 28, TextWrapped = true, Position = UDim2.fromOffset(162, 16), Size = UDim2.new(1, -176, 0, 64), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 6, Parent = card}), look.B:Lerp(BLACK, 0.6))
		ink(K.text({Text = pass.Desc, TextSize = 17, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(164, 80), Size = UDim2.new(1, -180, 0, 54), ZIndex = 6, Parent = card}), look.B:Lerp(BLACK, 0.6))
		priceButton(card, pass, "pass", UDim2.new(1, -16, 1, -16), UDim2.fromOffset(176, 56), Vector2.new(1, 1))
	end
end

-- Boosts and the two packs: three to a row
local BOOST_LOOK = {
	Treadmill = {Icon = "\u{1F3C3}", A = RGB(160, 225, 255), B = RGB(60, 140, 240)},
	CashS = {Icon = "\u{1F4B5}", A = RGB(200, 255, 180), B = RGB(60, 190, 80)},
	CashL = {Icon = "\u{1F911}", A = RGB(255, 232, 150), B = RGB(240, 160, 40)},
	Spin = {Icon = "\u{1F3A1}", A = RGB(255, 196, 240), B = RGB(220, 80, 200)},
	SpeedS = {Icon = "\u{1F45F}", A = RGB(176, 222, 255), B = RGB(60, 140, 240)},
	SpeedM = {Icon = "\u{26A1}", A = RGB(160, 242, 255), B = RGB(30, 160, 230)},
	SpeedL = {Icon = "\u{1F680}", A = RGB(196, 178, 255), B = RGB(100, 60, 230)},
	CashXL = {Icon = "\u{1F3E6}", A = RGB(255, 240, 160), B = RGB(230, 150, 20)},
	SpeedXL = {Icon = "\u{1F32A}", A = RGB(176, 204, 255), B = RGB(60, 80, 220)},
	SpeedXXL = {Icon = "\u{1F31F}", A = RGB(255, 204, 255), B = RGB(160, 60, 230)},
	Cash5 = {Icon = "\u{1FA99}", A = RGB(220, 255, 200), B = RGB(90, 200, 90)},
	CashXXL = {Icon = "\u{1F30D}", A = RGB(255, 228, 140), B = RGB(220, 120, 20)},
}
local THIRD = math.floor((CW - 28) / 3)
sectionTitle(5, CATS[3])
do
	local boosts = {}
	for _, p in ipairs(robux.Products) do
		if p.Section == "boost" then
			table.insert(boosts, p)
		end
	end
	if robux.Spin then
		table.insert(boosts, {Key = robux.Spin.Key, Id = robux.Spin.Id, Name = robux.Spin.Name, Desc = "Spin the Lucky Wheel again right now", Price = robux.Spin.Price})
	end
	local g = grid(6, THIRD, 236, 3)
	for i, p in ipairs(boosts) do
		local look = BOOST_LOOK[p.Key] or BOOST_LOOK.CashS
		local card = shopCard(g, look, i)
		shopIcon(card, p.Key, look, 80, UDim2.new(0.5, 0, 0, 54))
		ink(K.text({Text = p.Name, FontFace = K.TITLE, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 8, 0, 98), Size = UDim2.new(1, -16, 0, 28), ZIndex = 6, Parent = card}), look.B:Lerp(BLACK, 0.6))
		ink(K.text({Text = p.Desc, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.new(0, 12, 0, 128), Size = UDim2.new(1, -24, 0, 40), ZIndex = 6, Parent = card}), look.B:Lerp(BLACK, 0.6))
		priceButton(card, p, "product", UDim2.new(0.5, 0, 1, -14), UDim2.new(1, -28, 0, 50), Vector2.new(0.5, 1))
	end
end

-- SPEED PACKS and CASH PACKS (the + buttons by your cash and speed jump here)
local cashAmountLabels = {}
local function cashPackAmount(p)
	local perSec = player:GetAttribute("IncomePerSec") or 0
	return math.floor(math.max(p.Min or 0, perSec * 60 * (p.Minutes or 0)))
end
local function refreshCashAmounts()
	for lbl, p in pairs(cashAmountLabels) do
		lbl.Text = "+$" .. fmt(cashPackAmount(p))
	end
end
player:GetAttributeChangedSignal("IncomePerSec"):Connect(refreshCashAmounts)
local function packSection(order, cat, section)
	sectionTitle(order, cat)
	local g = grid(order + 1, THIRD, 250, 3)
	local list = {}
	for _, p in ipairs(robux.Products) do
		if p.Section == section then
			table.insert(list, p)
		end
	end
	for i, p in ipairs(list) do
		local look = BOOST_LOOK[p.Key] or BOOST_LOOK.CashS
		local card = shopCard(g, look, i)
		shopIcon(card, p.Key, look, 78, UDim2.new(0.5, 0, 0, 54))
		local dark = look.B:Lerp(BLACK, 0.6)
		ink(K.text({Text = p.Name, FontFace = K.TITLE, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 8, 0, 98), Size = UDim2.new(1, -16, 0, 26), ZIndex = 6, Parent = card}), dark)
		-- the amount, big and clear
		local amount = ink(K.text({Text = "", FontFace = K.TITLE, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = RGB(255, 255, 196), Position = UDim2.new(0, 8, 0, 124), Size = UDim2.new(1, -16, 0, 40), ZIndex = 6, Parent = card}), dark)
		if p.Amount then
			amount.Text = "+" .. fmt(p.Amount) .. " speed"
		else
			cashAmountLabels[amount] = p
			ink(K.text({Text = (p.Minutes >= 60 and (p.Minutes / 60 .. " hour" .. (p.Minutes > 60 and "s" or "")) or (p.Minutes .. " min")) .. " of your income", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(0, 8, 0, 164), Size = UDim2.new(1, -16, 0, 18), ZIndex = 6, Parent = card}), dark)
		end
		if i == #list then
			local ribbon = K.chip({Text = "BEST VALUE", Color = RGB(255, 70, 90), Style = "solid", TextSize = 13, Height = 26, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), ZIndex = 8, Parent = card})
			ribbon.Rotation = 8
		end
		priceButton(card, p, "product", UDim2.new(0.5, 0, 1, -14), UDim2.new(1, -28, 0, 50), Vector2.new(0.5, 1))
	end
	refreshCashAmounts()
end
packSection(10, CATS[4], "speed")
packSection(20, CATS[5], "cash")

local function refreshShop()
	for key, sbtn in pairs(shopButtons) do
		local owned = (sbtn.Kind == "pass" and player:GetAttribute("Pass_" .. key)) or (sbtn.Item.OneTime and player:GetAttribute("StarterBought"))
		if sbtn.Item.Id == 0 then
			sbtn.Btn.setText("Soon")
			sbtn.Btn.setEnabled(false)
		elseif owned then
			sbtn.Btn.setText("Owned")
			sbtn.Btn.setEnabled(false)
		else
			sbtn.Btn.setText(ROBUX .. " " .. sbtn.Item.Price)
			sbtn.Btn.setEnabled(true)
		end
	end
end
for _, attr in ipairs({"Pass_DoubleMoney", "Pass_DoubleSpeed", "Pass_DoubleSteal", "StarterBought"}) do
	player:GetAttributeChangedSignal(attr):Connect(refreshShop)
end
refreshShop()

-- the tab follows the list as you scroll
shopList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local s = shopList.AbsoluteSize.Y / shopList.Size.Y.Offset
	local top = shopList.AbsolutePosition.Y + 60 * s
	local pick = 1
	for i, cat in ipairs(CATS) do
		local f = shopSections[cat.Key]
		if f and f.AbsolutePosition.Y <= top then
			pick = i
		end
	end
	syncing = true
	catTabs.select(pick, true)
	syncing = false
end)
catTabs.select(1, true)

-- one smooth per-frame loop drives every shop picture (only while the shop is open)
RunService.RenderStepped:Connect(function(dt)
	if not shopPanel.Frame.Visible then return end
	local t = os.clock()
	for _, a in ipairs(shopIcons) do
		if a.Hover then
			a.H += (1 - a.H) * math.min(1, dt * 8)
		end
		local h = a.H
		a.Wiggle += dt * (1.8 + 2.6 * h)
		a.Pic.Position = UDim2.fromScale(0.5, 0.5 + math.sin(t * 2 + a.Phase) * (0.03 + 0.015 * h))
		a.Pic.Rotation = math.sin(a.Wiggle) * (2 + 8 * h)
		a.Scale.Scale = 1 + 0.035 * math.sin(t * 2.6 + a.Phase) + 0.12 * h
		a.Aura.Rotation = (a.Aura.Rotation + dt * (18 + 45 * h)) % 360
		a.Glow.BackgroundTransparency = 0.5 - 0.2 * h + 0.08 * math.sin(t * 2.4 + a.Phase)
	end
end)
shopButton.Activated:Connect(function()
	openPanel("Shop", function()
		refreshShop()
		shopList.CanvasPosition = Vector2.zero
	end)
end)

-- Open the shop at a section (used by the + buttons next to cash and speed)
local openSection = new("BindableEvent", {Name = "OpenShopSection", Parent = gui})
openSection.Event:Connect(function(section)
	if not shopPanel.Frame.Visible then
		openPanel("Shop", refreshShop)
	end
	task.wait(0.1)
	for i, cat in ipairs(CATS) do
		if cat.Key == section then
			catTabs.select(i)
		end
	end
end)

------------------------------------------------------------------
-- DAILY REWARDS: a 7-day streak on one big board. When it opens, the cards
-- pop in one by one, the streak track fills up to today, and today's card is
-- raised, glowing and bouncing with a TODAY! tag so you can't miss it.
------------------------------------------------------------------
local dailyPanel = UI.panel(gui, {Name = "Daily", Title = "DAILY REWARDS", Icon = "\u{1F4C5}", Color = UI.PINK, MaxSize = Vector2.new(1180, 680), Size = UDim2.fromScale(0.92, 0.88)})
panels.Daily = dailyPanel
-- Everything sits on a fixed-size board that scales down to fit smaller screens
local BOARD_W, BOARD_H = 1080, 560
local board = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(BOARD_W, BOARD_H), BackgroundTransparency = 1, Parent = dailyPanel.Body})
local boardScale = new("UIScale", {Parent = board})
local function fitBoard()
	local s = dailyPanel.Body.AbsoluteSize / math.max(0.01, dailyPanel.Scale.Scale)
	boardScale.Scale = math.clamp(math.min((s.X - 24) / BOARD_W, (s.Y - 8) / BOARD_H), 0.4, 1)
end
dailyPanel.Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitBoard)

local streakLabel = label({Position = UDim2.fromOffset(18, 2), Size = UDim2.fromOffset(560, 44), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 3.5, Parent = board})
UI.gradient(streakLabel, Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 160, 50), 90)
label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12), Size = UDim2.fromOffset(470, 24), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Text = "Come back every day! Missing a day starts the streak over.", TextColor3 = Color3.fromRGB(235, 220, 255), Outline = 2, Parent = board})

-- Card layout: six cards and a bigger one for the Day 7 mega prize
local CARD_W, BIG_W, GAP, CARD_TOP, TRACK_Y = 132, 176, 14, 100, 70
local cardX = {}
do
	local x = (BOARD_W - (CARD_W * (#daily - 1) + BIG_W + GAP * (#daily - 1))) / 2
	for i = 1, #daily do
		local w = i == #daily and BIG_W or CARD_W
		cardX[i] = {X = x, W = w, Center = x + w / 2}
		x += w + GAP
	end
end

-- Streak track: a bar through a numbered node above every card
local GREEN_SEQ = ColorSequence.new(Color3.fromRGB(130, 255, 150), Color3.fromRGB(40, 180, 80))
local GOLD_SEQ = ColorSequence.new(Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 150, 30))
local GREY_SEQ = ColorSequence.new(Color3.fromRGB(120, 115, 150), Color3.fromRGB(70, 65, 95))
local track = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(cardX[1].Center, TRACK_Y), Size = UDim2.fromOffset(cardX[#daily].Center - cardX[1].Center, 14), BackgroundColor3 = Color3.fromRGB(20, 16, 36), Parent = board}, {UI.corner(7), UI.stroke(UI.BLACK, 3)})
local trackFill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.WHITE, Parent = track}, {UI.corner(7)})
UI.gradient(trackFill, Color3.fromRGB(255, 235, 120), Color3.fromRGB(255, 140, 40), 0)
local nodes = {}
for i, cx in ipairs(cardX) do
	local node = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx.Center, TRACK_Y), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = UI.WHITE, Parent = board}, {UI.corner(1, true), UI.stroke(UI.BLACK, 3)})
	nodes[i] = {Grad = UI.gradient(node, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90), Text = label({Size = UDim2.fromScale(1, 1), Text = tostring(i), Outline = 2.5, Parent = node}), Scale = new("UIScale", {Parent = node})}
end

local KIND_LOOK = {
	cash = {Icon = "\u{1F4B5}", A = Color3.fromRGB(130, 235, 140), B = Color3.fromRGB(35, 150, 70)},
	speed = {Icon = "\u{1F45F}", A = Color3.fromRGB(140, 205, 255), B = Color3.fromRGB(40, 105, 220)},
	game = {Icon = "\u{1F3AE}", A = Color3.fromRGB(210, 150, 255), B = Color3.fromRGB(110, 40, 200)},
	mega = {Icon = "\u{1F381}", A = Color3.fromRGB(255, 235, 130), B = Color3.fromRGB(240, 130, 20)},
}
local function lookFor(i)
	return i == #daily and KIND_LOOK.mega or KIND_LOOK[daily[i].Kind] or KIND_LOOK.cash
end

local dayCards = {}
for i, d in ipairs(daily) do
	local big = i == #daily
	local look = lookFor(i)
	local w, h = cardX[i].W, big and 300 or 268
	local slot = new("Frame", {Position = UDim2.fromOffset(cardX[i].X, CARD_TOP), Size = UDim2.fromOffset(w, 300), BackgroundTransparency = 1, Parent = board})
	local card = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(w, h), BackgroundColor3 = UI.WHITE, Parent = slot}, {UI.corner(18)})
	local stroke = UI.stroke(UI.BLACK, 4)
	stroke.Parent = card
	UI.gradient(card, look.A, look.B, 90)
	new("Frame", {Position = UDim2.fromOffset(5, 44), Size = UDim2.new(1, -10, 0.34, 0), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.82, Parent = card}, {UI.corner(14)})
	-- ribbon with the day number
	local ribbonColor = look.B:Lerp(UI.BLACK, 0.35)
	local ribbon = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = ribbonColor, Parent = card}, {UI.corner(18)})
	new("Frame", {Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = ribbonColor, BorderSizePixel = 0, Parent = ribbon})
	label({Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 1, -10), Text = big and "DAY 7 \u{2022} MEGA" or ("DAY " .. i), Outline = 3, Parent = ribbon})
	-- the reward picture in a glowing bubble (light rays turn behind it on today's card)
	local iconSize = big and 120 or 92
	local iconPos = UDim2.new(0.5, 0, 0, 52 + iconSize / 2)
	local rays = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = iconPos, Size = UDim2.fromOffset(iconSize * 1.6, iconSize * 1.6), BackgroundTransparency = 1, Visible = false, Parent = card})
	for r = 0, 5 do
		new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 16, 1, 0), Rotation = r * 30, BackgroundColor3 = Color3.fromRGB(255, 250, 200), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = rays}, {UI.corner(1, true)})
	end
	local bubble = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = iconPos, Size = UDim2.fromOffset(iconSize, iconSize), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.7, Parent = card}, {UI.corner(1, true)})
	label({Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.8, 0.8), Text = look.Icon, Outline = false, Parent = bubble})
	label({Position = UDim2.new(0, 8, 0, 60 + iconSize), Size = UDim2.new(1, -16, 0, big and 60 or 52), TextWrapped = true, Text = d.Text, Outline = 3, Parent = card})
	-- status pill
	local pill = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -18, 0, 34), BackgroundColor3 = UI.BLACK, BackgroundTransparency = 0.55, Parent = card}, {UI.corner(12)})
	local state = label({Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.9, 0.76), Text = "", Outline = 2.5, Parent = pill})
	if big then
		UI.sparkles(card, 0.35)
		UI.shine(card, 2.5)
	end
	-- dim cover + check stamp for claimed days, a lock for days to come, and a tilted TODAY! tag
	local cover = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 8, 20), BackgroundTransparency = 1, ZIndex = 6, Parent = card}, {UI.corner(18)})
	local stamp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(84, 84), Rotation = -14, BackgroundColor3 = Color3.fromRGB(60, 210, 90), Visible = false, ZIndex = 7, Parent = card}, {UI.corner(1, true), UI.stroke(UI.WHITE, 4)})
	label({Size = UDim2.fromScale(1, 1), Text = "\u{2713}", Outline = 3, ZIndex = 8, Parent = stamp})
	local lock = label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 46), Size = UDim2.fromOffset(28, 28), Text = "\u{1F512}", Outline = false, Visible = false, ZIndex = 7, Parent = card})
	local tag = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(92, 30), Rotation = 12, BackgroundColor3 = UI.WHITE, Visible = false, ZIndex = 9, Parent = card}, {UI.corner(10), UI.stroke(UI.BLACK, 3)})
	UI.gradient(tag, Color3.fromRGB(255, 90, 80), Color3.fromRGB(210, 20, 50), 90)
	label({Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.8), Text = "TODAY!", Outline = 2.5, ZIndex = 10, Parent = tag})
	dayCards[i] = {
		Card = card, Scale = new("UIScale", {Parent = card}), Stroke = stroke, Rays = rays, BubbleScale = new("UIScale", {Parent = bubble}),
		State = state, Cover = cover, Stamp = stamp, StampScale = new("UIScale", {Parent = stamp}), Lock = lock, Tag = tag,
		Rest = UDim2.new(0.5, 0, 1, 0), Popped = true,
	}
end

local dailyClaim, dailyClaimText, setDailyColor = UI.actionButton({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 420), Size = UDim2.fromOffset(440, 80), Text = "\u{1F381} CLAIM", Parent = board, Radius = 22}, UI.GREEN)
local claimStroke = dailyClaim:FindFirstChildOfClass("UIStroke")
UI.sparkles(dailyClaim, 0.4)
local dailyMsg = label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 512), Size = UDim2.new(1, -40, 0, 26), Font = Enum.Font.GothamBold, TextColor3 = UI.GOLD, Text = "", Outline = 2, Parent = board})

local todayIndex, todayReady, trackProgress, animating = 1, false, 0, false
local function dailyTimeLeft()
	local now = workspace:GetServerTimeNow()
	return (math.floor(now / 86400) + 1) * 86400 - now
end

local function refreshDaily()
	local nextDay = player:GetAttribute("DailyNext") or 1
	local ready = player:GetAttribute("DailyReady") == true
	todayIndex, todayReady = nextDay, ready
	-- when not ready, DailyNext is the day already claimed today
	local claimedUpTo = ready and nextDay - 1 or nextDay
	local tomorrow = not ready and (nextDay % #daily + 1) or nil
	for i, c in ipairs(dayCards) do
		local claimed = i <= claimedUpTo
		local isToday = ready and i == nextDay
		c.Stamp.Visible = claimed
		c.Cover.BackgroundTransparency = claimed and 0.45 or (isToday and 1 or 0.3)
		c.Lock.Visible = not claimed and not isToday
		c.Tag.Visible = isToday
		c.Rays.Visible = isToday
		c.Stroke.Color = UI.BLACK
		c.Stroke.Thickness = isToday and 5 or 4
		c.BubbleScale.Scale = 1
		c.Rest = UDim2.new(0.5, 0, 1, isToday and -18 or 0)
		if c.Popped then
			c.Card.Position = c.Rest
		end
		if claimed then
			c.State.Text, c.State.TextColor3 = "CLAIMED", Color3.fromRGB(150, 255, 160)
		elseif isToday then
			c.State.Text, c.State.TextColor3 = "CLAIM NOW!", UI.GOLD
		elseif i == tomorrow then
			c.State.Text, c.State.TextColor3 = "TOMORROW", UI.WHITE
		else
			c.State.Text, c.State.TextColor3 = "LOCKED", Color3.fromRGB(200, 195, 220)
		end
		local n = nodes[i]
		n.Grad.Color = claimed and GREEN_SEQ or (isToday and GOLD_SEQ or GREY_SEQ)
		n.Text.Text = claimed and "\u{2713}" or tostring(i)
		n.Scale.Scale = 1
	end
	trackProgress = math.clamp(((ready and nextDay or claimedUpTo) - 1) / (#daily - 1), 0, 1)
	if not animating then
		trackFill.Size = UDim2.fromScale(trackProgress, 1)
	end
	if not ready and claimedUpTo >= #daily then
		streakLabel.Text = "\u{1F3C6} 7-DAY STREAK COMPLETE!"
	elseif ready and claimedUpTo == 0 then
		streakLabel.Text = "\u{1F525} START YOUR STREAK!"
	elseif ready then
		streakLabel.Text = "\u{1F525} " .. claimedUpTo .. "-DAY STREAK \u{2022} DAY " .. nextDay .. " IS READY!"
	else
		streakLabel.Text = "\u{1F525} " .. claimedUpTo .. "-DAY STREAK"
	end
	dailyClaimText.Text = ready and ("\u{1F381} CLAIM DAY " .. nextDay) or ("NEXT REWARD IN " .. UI.fmtTime(dailyTimeLeft()))
	setDailyColor(ready and UI.GREEN or Color3.fromRGB(110, 100, 140))
	claimStroke.Color = UI.BLACK
	dailyRefs.Badge.Visible = ready
end
player:GetAttributeChangedSignal("DailyNext"):Connect(refreshDaily)
player:GetAttributeChangedSignal("DailyReady"):Connect(refreshDaily)
refreshDaily()

-- Countdowns tick once a second
task.spawn(function()
	while true do
		local ready = player:GetAttribute("DailyReady") == true
		local left = dailyTimeLeft()
		dailyTimer.Text = ready and "READY!" or UI.fmtTime(left)
		if not ready and dailyPanel.Frame.Visible then
			dailyClaimText.Text = "NEXT REWARD IN " .. UI.fmtTime(left)
		end
		task.wait(1)
	end
end)

-- While the menu is open, today's card glows, bobs and turns its light rays
local pulseConn
local function startPulse()
	if pulseConn then return end
	pulseConn = RunService.RenderStepped:Connect(function()
		if not dailyPanel.Frame.Visible then
			pulseConn:Disconnect()
			pulseConn = nil
			return
		end
		local c = todayReady and dayCards[todayIndex]
		if not c then return end
		local t = os.clock()
		local glow = (math.sin(t * 5) + 1) / 2
		c.Rays.Rotation = (t * 35) % 360
		c.BubbleScale.Scale = 1 + math.sin(t * 4) * 0.06
		c.Stroke.Color = UI.GOLD:Lerp(UI.WHITE, glow)
		if c.Popped then
			c.Card.Position = c.Rest + UDim2.fromOffset(0, math.sin(t * 3) * 3)
		end
		nodes[todayIndex].Scale.Scale = 1 + glow * 0.15
		claimStroke.Color = UI.GOLD:Lerp(UI.WHITE, glow)
	end)
end

-- A burst of stars flying out of a card
local function starBurst(card)
	for k = 1, 10 do
		local ang = k / 10 * math.pi * 2
		local star = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(26, 26), Text = "\u{2726}", TextColor3 = k % 2 == 0 and UI.GOLD or UI.WHITE, Outline = false, ZIndex = 11, Parent = card})
		local tw = TweenService:Create(star, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(ang) * 110, 0.4, math.sin(ang) * 110), TextTransparency = 1, Rotation = 180,
		})
		tw:Play()
		tw.Completed:Once(function()
			star:Destroy()
		end)
	end
end

-- Opening animation: cards drop in one after another, then the track fills, then today's card bursts
local function animateDaily()
	animating = true
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	for i, c in ipairs(dayCards) do
		c.Popped = false
		c.Scale.Scale = 0.2
		c.Card.Position = c.Rest + UDim2.fromOffset(0, -70)
		c.Card.Rotation = i % 2 == 0 and 8 or -8
		task.delay(0.1 + (i - 1) * 0.07, function()
			TweenService:Create(c.Scale, info, {Scale = 1}):Play()
			local tw = TweenService:Create(c.Card, info, {Position = c.Rest, Rotation = 0})
			tw:Play()
			tw.Completed:Once(function()
				c.Popped = true
			end)
		end)
	end
	trackFill.Size = UDim2.fromScale(0, 1)
	task.delay(0.65, function()
		local tw = TweenService:Create(trackFill, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(trackProgress, 1)})
		tw:Play()
		tw.Completed:Once(function()
			animating = false
		end)
	end)
	task.delay(1.2, function()
		local c = todayReady and dayCards[todayIndex]
		if c and dailyPanel.Frame.Visible then
			starBurst(c.Card)
		end
	end)
	startPulse()
end

local function onDailyOpen()
	dailyMsg.Text = ""
	refreshDaily()
	fitBoard()
	animateDaily()
end

local dailyFunction = remotes:WaitForChild("ClaimDaily")
dailyClaim.Activated:Connect(function()
	local day = player:GetAttribute("DailyNext") or 1
	local ok, msg = dailyFunction:InvokeServer()
	if ok then
		dailyMsg.Text = ""
		local c = dayCards[day]
		if c then
			-- stamp the card
			c.Stamp.Visible = true
			c.StampScale.Scale = 3
			TweenService:Create(c.StampScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			starBurst(c.Card)
		end
		local look = lookFor(day)
		UI.popup(popGui, {Title = "DAY " .. day .. " REWARD!", Sub = (msg or ""):gsub("^Day %d+ reward: ", ""), Color = look.A, Icon = look.Icon})
	else
		dailyMsg.Text = msg or ""
	end
	refreshDaily()
end)
dailyButton.Activated:Connect(function()
	openPanel("Daily", onDailyOpen)
end)
-- Pop the menu open by itself when a reward is waiting at join
task.spawn(function()
	local waited = 0
	while player:GetAttribute("DailyReady") == nil and waited < 20 do
		task.wait(0.5)
		waited += 0.5
	end
	task.wait(2)
	if player:GetAttribute("DailyReady") == true and not dailyPanel.Frame.Visible then
		openPanel("Daily", onDailyOpen)
	end
end)

------------------------------------------------------------------
-- PLAYTIME GIFTS
------------------------------------------------------------------
local playPanel = UI.panel(gui, {Name = "Playtime", Title = "PLAYTIME GIFTS", Icon = "\u{1F381}", Color = Color3.fromRGB(70, 200, 230), MaxSize = Vector2.new(1060, 540), Size = UDim2.fromScale(0.86, 0.72)})
panels.Playtime = playPanel
label({Position = UDim2.fromOffset(24, 8), Size = UDim2.new(1, -48, 0, 26), Font = Enum.Font.GothamBold, Text = "A new gift every 10 minutes you play!", TextColor3 = Color3.fromRGB(220, 245, 255), Outline = 2, Parent = playPanel.Body})
-- progress bar
local pBar = new("Frame", {Position = UDim2.fromOffset(30, 44), Size = UDim2.new(1, -330, 0, 34), BackgroundColor3 = Color3.fromRGB(20, 18, 32), Parent = playPanel.Body}, {UI.corner(17), UI.stroke(UI.BLACK, 3)})
local pFill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.WHITE, Parent = pBar}, {UI.corner(17)})
UI.gradient(pFill, Color3.fromRGB(140, 240, 255), Color3.fromRGB(40, 160, 220), 90)
local pText = label({Size = UDim2.fromScale(1, 1), Text = "", Outline = 2.5, ZIndex = 3, Parent = pBar})
local playAll, playAllText = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -170, 0, 40), Size = UDim2.fromOffset(130, 42), Text = "CLAIM ALL", Parent = playPanel.Body}, UI.GREEN)
local skipAll, skipAllText = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 40), Size = UDim2.fromOffset(136, 42), Text = "SKIP ALL", Parent = playPanel.Body}, UI.PURPLE)
local giftRow = new("Frame", {Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 290), BackgroundTransparency = 1, Parent = playPanel.Body},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
local playMsg = label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 396), Size = UDim2.new(1, -40, 0, 24), Font = Enum.Font.GothamBold, TextColor3 = UI.GOLD, Text = "", Outline = 2, Parent = playPanel.Body})
local giftCards = {}
for i, g in ipairs(playtime) do
	local mystery = g.Mystery
	local color = Color3.fromHex(g.Color)
	local card = new("Frame", {LayoutOrder = i, Size = UDim2.fromOffset(mystery and 176 or 140, mystery and 286 or 252), BackgroundColor3 = UI.WHITE, Parent = giftRow}, {UI.corner(16), UI.stroke(UI.BLACK, 4)})
	UI.gradient(card, color:Lerp(UI.WHITE, 0.35), color:Lerp(UI.BLACK, 0.3), 90)
	label({Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 28), Text = g.Minute .. " MIN", Outline = 3, Parent = card})
	if mystery then
		UI.sparkles(card, 0.3)
		UI.shine(card, 2.5)
		-- a silhouette of a random game
		local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 42), Size = UDim2.fromOffset(104, 130), BackgroundTransparency = 1, ClipsDescendants = true, Parent = card}, {UI.corner(10), UI.stroke(UI.BLACK, 3)})
		local sil = GamePoster.Create({Name = "Mystery Prize", Rarity = "", Color = UI.BLACK})
		for _, d in ipairs(sil:GetDescendants()) do
			if d:IsA("UIGradient") then
				d:Destroy()
			elseif d:IsA("GuiObject") then
				local full = d.Size == UDim2.fromScale(1, 1)
				d.BackgroundColor3 = full and Color3.fromRGB(150, 90, 230) or Color3.fromRGB(30, 10, 60)
				if d:IsA("TextLabel") then
					d.TextTransparency = 1
					d.TextStrokeTransparency = 1
				end
			end
		end
		sil.BackgroundColor3 = Color3.fromRGB(150, 90, 230)
		sil.Parent = holder
		label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.6, 0.45), Text = "?", Outline = 4, ZIndex = 10, Parent = holder})
	else
		label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 42), Size = UDim2.fromOffset(90, 90), Text = g.Icon, Outline = false, Parent = card})
	end
	label({Position = UDim2.new(0, 6, 0, mystery and 178 or 138), Size = UDim2.new(1, -12, 0, 50), TextWrapped = true, Text = g.Text, Outline = 3, Parent = card})
	local claimB, claimT, setColor = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -18, 0, 44), Text = "", Parent = card}, UI.GREEN)
	local cardScale = new("UIScale", {Parent = card})
	claimB.Activated:Connect(function()
		local ok, msg = remotes.ClaimPlaytime:InvokeServer(i)
		if ok then
			-- the gift bursts open
			starBurst(card)
			cardScale.Scale = 1.15
			TweenService:Create(cardScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		else
			playMsg.Text = msg or ""
		end
	end)
	giftCards[i] = {Text = claimT, SetColor = setColor, Card = card, Scale = cardScale}
end
playAll.Activated:Connect(function()
	local ok, msg = remotes:WaitForChild("ClaimPlaytime"):InvokeServer("all")
	playMsg.Text = ok and "" or (msg or "")
end)
skipAll.Activated:Connect(function()
	local p = robux.SkipPlaytime
	if p and p.Id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, p.Id)
	else
		playMsg.Text = "Skipping isn't set up yet"
	end
end)
skipAllText.Text = UI.ROBUX .. " " .. ((robux.SkipPlaytime and robux.SkipPlaytime.Price) or 150) .. " SKIP"

local function now()
	return workspace:GetServerTimeNow()
end

local playFillAnimating = false -- the opening animation fills the bar itself
local function updatePlaytime()
	local start = player:GetAttribute("PlayStart")
	if not start then return end
	local played = now() - start
	local claimed = {}
	for _, i in ipairs(decodeAttr("PlayClaimed", "[]")) do
		claimed[tonumber(i)] = true
	end
	local ready, nextIn = 0, nil
	for i, g in ipairs(playtime) do
		local left = g.Minute * 60 - played
		local card = giftCards[i]
		if claimed[i] then
			card.Text.Text = "\u{2713}"
			card.SetColor(Color3.fromRGB(110, 100, 140))
		elseif left <= 0 then
			ready += 1
			card.Text.Text = "CLAIM!"
			card.SetColor(UI.GREEN)
		else
			card.Text.Text = UI.fmtTime(left)
			card.SetColor(Color3.fromRGB(110, 100, 140))
			nextIn = nextIn and math.min(nextIn, left) or left
		end
	end
	local total = playtime[#playtime].Minute * 60
	if not playFillAnimating then
		pFill.Size = UDim2.fromScale(math.clamp(played / total, 0, 1), 1)
	end
	pText.Text = played >= total and "ALL GIFTS UNLOCKED!" or (math.floor(played / 60) .. " / " .. playtime[#playtime].Minute .. " minutes")
	giftRefs.Badge.Visible = ready > 0
	giftRefs.BadgeText.Text = tostring(ready)
	if ready > 0 then
		giftTimer.Text = "CLAIM!"
		giftTimer.TextColor3 = Color3.fromRGB(140, 255, 150)
	elseif nextIn then
		giftTimer.Text = UI.fmtTime(nextIn)
		giftTimer.TextColor3 = Color3.fromRGB(140, 240, 255)
	else
		giftTimer.Text = "DONE!"
		giftTimer.TextColor3 = Color3.fromRGB(200, 200, 220)
	end
	playAllText.Text = ready > 0 and ("CLAIM ALL (" .. ready .. ")") or "CLAIM ALL"
end
task.spawn(function()
	while true do
		updatePlaytime()
		task.wait(0.5)
	end
end)
-- Opening the playtime menu: the cards tumble in one after another, the bar fills up,
-- and the gifts you can claim give a little wiggle
local function animatePlaytime()
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	for i, c in ipairs(giftCards) do
		c.Scale.Scale = 0
		c.Card.Rotation = i % 2 == 0 and 14 or -14
		task.delay(0.08 + (i - 1) * 0.07, function()
			TweenService:Create(c.Scale, info, {Scale = 1}):Play()
			TweenService:Create(c.Card, info, {Rotation = 0}):Play()
		end)
	end
	local full = pFill.Size
	playFillAnimating = true
	pFill.Size = UDim2.fromScale(0, 1)
	task.delay(0.35, function()
		local tw = TweenService:Create(pFill, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Size = full})
		tw:Play()
		tw.Completed:Once(function()
			playFillAnimating = false
		end)
	end)
	task.delay(0.1 + #giftCards * 0.07 + 0.4, function()
		for _, c in ipairs(giftCards) do
			if c.Text.Text == "CLAIM!" then
				local wiggle = TweenService:Create(c.Card, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true), {Rotation = 6})
				wiggle:Play()
				wiggle.Completed:Once(function()
					c.Card.Rotation = 0
				end)
			end
		end
	end)
end

-- The menu gift is a real 3D box that slowly turns in place (no bouncing around)
giftIcon.Text = ""
local giftView = new("ViewportFrame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.95, 0.95),
	BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 210), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.4, -1, -0.5),
	ZIndex = giftButton.ZIndex + 1, Parent = giftButton,
})
local giftModel = new("Model", {Parent = giftView})
local function giftPart(props)
	local p = new("Part", {Anchored = true, Material = Enum.Material.SmoothPlastic, Parent = giftModel})
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end
local RED, GOLDC = Color3.fromRGB(235, 55, 75), Color3.fromRGB(255, 205, 60)
giftPart({Size = Vector3.new(2.4, 2, 2.4), CFrame = CFrame.new(0, -0.3, 0), Color = RED})
giftPart({Size = Vector3.new(2.7, 0.55, 2.7), CFrame = CFrame.new(0, 0.95, 0), Color = RED:Lerp(Color3.new(1, 1, 1), 0.1)})
giftPart({Size = Vector3.new(0.5, 2.62, 2.74), CFrame = CFrame.new(0, 0.05, 0), Color = GOLDC})
giftPart({Size = Vector3.new(2.74, 2.62, 0.5), CFrame = CFrame.new(0, 0.05, 0), Color = GOLDC})
for _, sx in ipairs({-1, 1}) do
	giftPart({Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.7, 0.7), CFrame = CFrame.new(sx * 0.45, 1.5, 0) * CFrame.Angles(0, 0, sx * 0.5), Color = GOLDC})
end
giftPart({Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), CFrame = CFrame.new(0, 1.45, 0), Color = GOLDC})
local giftCam = new("Camera", {FieldOfView = 40, Parent = giftView})
giftCam.CFrame = CFrame.lookAt(Vector3.new(0, 2.6, 6.2), Vector3.new(0, 0.25, 0))
giftView.CurrentCamera = giftCam
local giftParts = {}
for _, p in ipairs(giftModel:GetChildren()) do
	giftParts[p] = p.CFrame
end
RunService.RenderStepped:Connect(function()
	if not UI.shown(giftButton) then return end
	local spin = CFrame.Angles(0, os.clock() * 0.8, 0) -- slow, steady turn
	for p, cf in pairs(giftParts) do
		p.CFrame = spin * cf
	end
end)

-- A little confetti puff when you click it (the menu opens straight away, no waiting)
local CONFETTI = {Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 210, 60), Color3.fromRGB(90, 220, 255), Color3.fromRGB(120, 255, 140), Color3.fromRGB(200, 120, 255)}
local function confetti()
	for k = 1, 12 do
		local ang = k / 12 * math.pi * 2
		local bit = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(9, 5), Rotation = math.random(0, 360), BackgroundColor3 = CONFETTI[k % #CONFETTI + 1], BorderSizePixel = 0, ZIndex = 20, Parent = giftButton})
		local dist = math.random(45, 70)
		local tw = TweenService:Create(bit, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, math.cos(ang) * dist, 0.45, math.sin(ang) * dist + 16), Rotation = bit.Rotation + 300, BackgroundTransparency = 1})
		tw:Play()
		tw.Completed:Once(function()
			bit:Destroy()
		end)
	end
end
giftButton.Activated:Connect(function()
	if playPanel.Frame.Visible then
		openPanel("Playtime") -- already open: this closes it
		return
	end
	confetti()
	openPanel("Playtime", function()
		playMsg.Text = ""
		updatePlaytime()
		animatePlaytime()
	end)
end)

------------------------------------------------------------------
-- HOW TO PLAY
------------------------------------------------------------------
local infoPanel = UI.panel(gui, {Name = "Info", Title = "HOW TO PLAY", Icon = "\u{2753}", Color = UI.BLUE, MaxSize = Vector2.new(760, 620)})
panels.Info = infoPanel
local infoList = scroller(infoPanel.Body, UDim2.fromOffset(16, 8), UDim2.new(1, -32, 1, -16))
new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = infoList})
new("UIPadding", {PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = infoList})
local INFO = {
	{"\u{1F3C3}", "Steal games", "Run into the Game Vault, hold E on a game to grab it, and run it home. The deeper you go, the rarer the games. You won't know a game's rarity until it's in your base! Every level gets 3 new games every 7 minutes."},
	{"\u{1F46E}", "Shopkeepers", "The shopkeeper of the level you stole from chases you until you leave the Vault. A small sign hangs under every level's name with the recommended \u{1F45F} speed. If you're faster, you can escape!"},
	{"\u{1F45F}", "Get faster", "Run on the treadmill in front of your base to raise your speed. Upgrade it to gain speed faster."},
	{"\u{2B07}", "Installing", "New games need to install before they earn money. Rarer games take longer. Installing keeps going at half speed while you're offline."},
	{"\u{1F4B0}", "Earn money", "Installed games earn money every second. Walk over the green pad in your base to collect it."},
	{"\u{1F512}", "Lock your base", "Step on the red pad to lock your base for 1:30. The lock timer PAUSES while you're being chased, so your base stays safe while you're out stealing."},
	{"\u{1F3DB}", "Upgrade your base", "Buy more cases at the glowing spots in your base. When a floor is full, you can build a new floor with stairs on the side."},
	{"\u{270B}", "Hold, swap & drop", "Hold up to 2 games. Pick games up from your cases to swap them around, or press DROP (G). Use the Slap tool on thieves."},
	{"\u{1F4D6}", "Index", "Every game you find shows up in the Index. Claim each one for cash and speed, and find all 15 in an area for a big prize."},
	{"\u{1F381}", "Gifts", "Daily rewards, playtime gifts every 10 minutes, and a free Lucky Spin every day at the booth by the Vault entrance."},
}
for i, item in ipairs(INFO) do
	local r = new("Frame", {LayoutOrder = i, Size = UDim2.new(1, -8, 0, 100), BackgroundColor3 = UI.PANEL, Parent = infoList}, {UI.corner(14), UI.stroke(UI.BLACK, 3)})
	label({Position = UDim2.fromOffset(12, 18), Size = UDim2.fromOffset(62, 62), Text = item[1], Outline = false, Parent = r})
	label({Position = UDim2.fromOffset(84, 8), Size = UDim2.new(1, -96, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Text = item[2], TextColor3 = Color3.fromRGB(140, 200, 255), Outline = 3, Parent = r})
	local t = label({Position = UDim2.fromOffset(85, 40), Size = UDim2.new(1, -98, 0, 54), Font = Enum.Font.GothamBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(230, 230, 240), Text = item[3], Outline = false, Parent = r})
	new("UITextSizeConstraint", {MaxTextSize = 17, Parent = t})
end
infoButton.Activated:Connect(function()
	openPanel("Info")
end)
