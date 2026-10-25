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
		p.Frame.Visible = false
	end
	if wasOpen then return end
	if onOpen then
		onOpen()
	end
	UI.open(target)
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
-- INDEX: every area with a progress bar, a completion reward, and all 15 games
------------------------------------------------------------------
local indexPanel = UI.panel(gui, {Name = "Index", Title = "GAME INDEX", Icon = "\u{1F4D6}", Color = UI.GOLD, MaxSize = Vector2.new(980, 640)})
panels.Index = indexPanel
local foundLabel = label({Position = UDim2.fromOffset(20, 6), Size = UDim2.new(0.5, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = indexPanel.Body})
local claimAll, claimAllText = UI.actionButton({Name = "ClaimAll", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 2), Size = UDim2.fromOffset(220, 42), Text = "CLAIM ALL", Parent = indexPanel.Body}, UI.GREEN)
local indexMsg = label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -268, 0, 12), Size = UDim2.fromOffset(380, 20), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.GREEN, Text = "", Outline = 2, Parent = indexPanel.Body})
local indexList = scroller(indexPanel.Body, UDim2.fromOffset(14, 52), UDim2.new(1, -28, 1, -64))
new("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = indexList})
new("UIPadding", {PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 12), PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 4), Parent = indexList})

local cards, areas = {}, {}
local built = false
local totalGames = 0
local previews = ReplicatedStorage:WaitForChild("AreaPreviews", 15)
local claimFunction = remotes:WaitForChild("ClaimIndex")
local areaFunction = remotes:WaitForChild("ClaimArea")

local function makePreview(parent, zoneIndex, size, pos)
	local vp = new("ViewportFrame", {
		Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(150, 200, 255),
		Ambient = Color3.fromRGB(200, 200, 205), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.3, -1, 0.5), Parent = parent,
	}, {UI.corner(12), UI.stroke(UI.BLACK, 3)})
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
end

-- Show a short message that fades away by itself
local msgTokens = {}
local function flashMsg(lbl, text, color)
	msgTokens[lbl] = (msgTokens[lbl] or 0) + 1
	local my = msgTokens[lbl]
	lbl.Text = text or ""
	lbl.TextColor3 = color or UI.WHITE
	lbl.TextTransparency = 0
	local st = lbl:FindFirstChildOfClass("UIStroke")
	if st then
		st.Transparency = 0
	end
	task.delay(2.5, function()
		if msgTokens[lbl] == my then
			TweenService:Create(lbl, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
			if st then
				TweenService:Create(st, TweenInfo.new(0.6), {Transparency = 1}):Play()
			end
		end
	end)
end

local function claim(name)
	local ok, msg = claimFunction:InvokeServer(name)
	flashMsg(indexMsg, msg, ok and UI.GREEN or Color3.fromRGB(255, 120, 120))
	if ok then
		UI.popup(popGui, {Title = "REWARD CLAIMED!", Sub = msg, Color = UI.GOLD, Icon = "\u{1F4D6}", Duration = 2})
	end
end
claimAll.Activated:Connect(function()
	claim("all")
end)

local function setCard(card, info)
	card.Poster:ClearAllChildren()
	UI.corner(8).Parent = card.Poster
	if info then
		local r = rarities[info.R] or rarities[1]
		local color = Color3.fromHex(r.Color)
		card.Grad.Color = ColorSequence.new(color:Lerp(UI.WHITE, 0.15), color:Lerp(UI.BLACK, 0.45))
		GamePoster.Create({Name = card.Name, Rarity = r.Name, Color = color}).Parent = card.Poster
		card.Title.Text = card.Name
		card.Rarity.Text = string.upper(r.Name)
		card.Rarity.TextColor3 = color:Lerp(UI.WHITE, 0.4)
		if info.C then
			card.ClaimText.Text = "CLAIMED \u{2713}"
			card.SetClaimColor(Color3.fromRGB(90, 90, 110))
		else
			card.ClaimText.Text = "CLAIM"
			card.SetClaimColor(UI.GREEN)
		end
		card.Reward.Text = "+$" .. fmt(info.Cash) .. "  +" .. fmt(info.Speed) .. " \u{1F45F}"
		card.Claim.Visible = true
		card.Reward.Visible = not info.C
	else
		card.Grad.Color = ColorSequence.new(Color3.fromRGB(60, 56, 84), Color3.fromRGB(30, 28, 44))
		local sil = GamePoster.Create({Name = card.Name, Rarity = "", Color = UI.BLACK})
		for _, d in ipairs(sil:GetDescendants()) do
			if d:IsA("UIGradient") then
				d:Destroy()
			elseif d:IsA("GuiObject") then
				local full = d.Size == UDim2.fromScale(1, 1)
				d.BackgroundColor3 = full and Color3.fromRGB(80, 76, 104) or Color3.fromRGB(14, 12, 22)
				if d:IsA("TextLabel") then
					d.TextTransparency = 1
					d.TextStrokeTransparency = 1
				end
			end
		end
		sil.BackgroundColor3 = Color3.fromRGB(80, 76, 104)
		sil.Parent = card.Poster
		label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.5, 0.35), Text = "?", TextColor3 = Color3.fromRGB(190, 185, 220), ZIndex = 10, Parent = card.Poster})
		card.Title.Text = "???"
		card.Rarity.Text = "NOT FOUND"
		card.Rarity.TextColor3 = Color3.fromRGB(150, 145, 175)
		card.Claim.Visible = false
		card.Reward.Visible = false
	end
end

local function refreshIndex()
	local state = decodeAttr("IndexState", "{}")
	local claimedAreas = {}
	for _, zi in ipairs(decodeAttr("AreaClaimed", "[]")) do
		claimedAreas[tonumber(zi)] = true
	end
	local found, unclaimed = 0, 0
	for name, info in pairs(state) do
		found += 1
		if not info.C then
			unclaimed += 1
		end
	end
	indexRefs.Badge.Visible = unclaimed > 0
	indexRefs.BadgeText.Text = tostring(unclaimed)
	if not built then return end
	for name, card in pairs(cards) do
		local info = state[name]
		local key = info and (info.R .. tostring(info.C)) or "none"
		if card.Key ~= key then
			card.Key = key
			setCard(card, info)
		end
	end
	for zi, area in pairs(areas) do
		local have = 0
		for _, name in ipairs(area.Names) do
			if state[name] then
				have += 1
			end
		end
		local total = #area.Names
		area.Fill.Size = UDim2.fromScale(math.max(0.02, have / total), 1)
		area.Count.Text = have .. " / " .. total
		if claimedAreas[zi] then
			area.ClaimText.Text = "CLAIMED \u{2713}"
			area.SetColor(Color3.fromRGB(90, 90, 110))
		elseif have >= total then
			area.ClaimText.Text = "CLAIM!"
			area.SetColor(UI.GOLD)
		else
			area.ClaimText.Text = "\u{1F512} LOCKED"
			area.SetColor(Color3.fromRGB(90, 90, 110))
		end
	end
	foundLabel.Text = string.format("Found <font color=\"#ffcd32\">%d</font> / %d games", found, totalGames)
	claimAllText.Text = unclaimed > 0 and ("CLAIM ALL (" .. unclaimed .. ")") or "CLAIM ALL"
end

local function buildIndex()
	if built then return end
	built = true
	-- Built a little at a time so the game never freezes
	task.spawn(function()
	for zi, zone in ipairs(index) do
		local section = new("Frame", {LayoutOrder = zi, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UI.PANEL, Parent = indexList}, {
			UI.corner(16), UI.stroke(UI.BLACK, 3),
			new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}),
			new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
		})
		local head = new("Frame", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 118), BackgroundTransparency = 1, Parent = section})
		makePreview(head, zi, UDim2.fromOffset(200, 112), UDim2.fromOffset(0, 3))
		label({Position = UDim2.fromOffset(214, 4), Size = UDim2.new(1, -440, 0, 38), TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(zone.Area), Outline = 3, Parent = head})
		-- progress bar
		local bar = new("Frame", {Position = UDim2.fromOffset(214, 50), Size = UDim2.new(1, -440, 0, 30), BackgroundColor3 = Color3.fromRGB(20, 18, 32), Parent = head}, {UI.corner(15), UI.stroke(UI.BLACK, 3)})
		local fill = new("Frame", {Size = UDim2.fromScale(0.02, 1), BackgroundColor3 = UI.WHITE, Parent = bar}, {UI.corner(15)})
		UI.gradient(fill, Color3.fromRGB(120, 255, 140), Color3.fromRGB(40, 190, 80), 90)
		local count = label({Size = UDim2.fromScale(1, 1), Text = "0 / " .. #zone.Games, Outline = 2.5, ZIndex = 3, Parent = bar})
		label({Position = UDim2.fromOffset(214, 86), Size = UDim2.new(1, -440, 0, 22), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 195, 230), Text = "Find all " .. #zone.Games .. " games for the area prize!", Outline = 2, Parent = head})
		-- special reward box
		local prize = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(212, 112), BackgroundColor3 = UI.WHITE, Parent = head}, {UI.corner(14), UI.stroke(UI.BLACK, 3)})
		UI.gradient(prize, Color3.fromRGB(255, 230, 120), Color3.fromRGB(240, 150, 30), 90)
		UI.sparkles(prize, 0.9)
		label({Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(44, 44), Text = "\u{1F3C6}", Outline = false, Parent = prize})
		label({Position = UDim2.fromOffset(56, 6), Size = UDim2.new(1, -64, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Text = "AREA PRIZE", Outline = 2.5, Parent = prize})
		label({Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -64, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Text = "Big cash + speed", Outline = 2, Parent = prize})
		local claimB, claimT, setColor = UI.actionButton({Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 40), Text = "\u{1F512} LOCKED", Parent = prize}, Color3.fromRGB(90, 90, 110))
		claimB.Activated:Connect(function()
			local ok, msg = areaFunction:InvokeServer(zi)
			if not ok then
				flashMsg(indexMsg, msg, Color3.fromRGB(255, 160, 120))
			end
		end)
		local area = {Fill = fill, Count = count, ClaimText = claimT, SetColor = setColor, Names = {}}
		areas[zi] = area

		local grid = new("Frame", {LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = section}, {
			new("UIGridLayout", {CellSize = UDim2.fromOffset(152, 246), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		for gi, g in ipairs(zone.Games) do
			totalGames += 1
			table.insert(area.Names, g.Name)
			local frame = new("Frame", {LayoutOrder = gi, BackgroundColor3 = UI.WHITE, Parent = grid}, {UI.corner(12), UI.stroke(UI.BLACK, 3)})
			local grad = UI.gradient(frame, Color3.fromRGB(60, 56, 84), Color3.fromRGB(30, 28, 44), 90)
			local posterHolder = new("Frame", {Position = UDim2.fromOffset(20, 8), Size = UDim2.fromOffset(112, 140), BackgroundTransparency = 1, ClipsDescendants = true, Parent = frame}, {UI.stroke(UI.BLACK, 2.5)})
			local title = label({Position = UDim2.fromOffset(6, 151), Size = UDim2.fromOffset(140, 24), Text = "", TextWrapped = true, Outline = 2.5, Parent = frame})
			local rarity = label({Position = UDim2.fromOffset(6, 175), Size = UDim2.fromOffset(140, 14), Text = "", Outline = 2, Parent = frame})
			local reward = label({Position = UDim2.fromOffset(6, 190), Size = UDim2.fromOffset(140, 14), Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.fromRGB(150, 255, 160), Outline = 2, Parent = frame})
			local claimButton, claimText, setClaimColor = UI.actionButton({Position = UDim2.fromOffset(10, 207), Size = UDim2.fromOffset(132, 32), Text = "CLAIM", Parent = frame}, UI.GREEN)
			local card = {Name = g.Name, Frame = frame, Grad = grad, Poster = posterHolder, Title = title, Rarity = rarity, Reward = reward, Claim = claimButton, ClaimText = claimText, SetClaimColor = setClaimColor, Key = ""}
			claimButton.Activated:Connect(function()
				local info = decodeAttr("IndexState", "{}")[g.Name]
				if info and not info.C then
					claim(g.Name)
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
refreshIndex()
-- Build the Index quietly while it's hidden, so opening it is as smooth as the Shop
-- (building 150 cards during the open animation made it stutter and jump)
task.delay(4, buildIndex)

indexButton.Activated:Connect(function()
	openPanel("Index", function()
		indexMsg.Text = ""
		buildIndex()
		refreshIndex()
	end)
end)

------------------------------------------------------------------
-- SHOP (Robux)
------------------------------------------------------------------
local shopPanel = UI.panel(gui, {Name = "Shop", Title = "SHOP", Icon = "\u{1F6D2}", Color = UI.GOLD, MaxSize = Vector2.new(900, 640)})
panels.Shop = shopPanel
local shopList = scroller(shopPanel.Body, UDim2.fromOffset(16, 8), UDim2.new(1, -32, 1, -16))
new("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = shopList})
new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 12), Parent = shopList})
local shopButtons = {}

-- SHOP ICONS: a big picture with a glowing aura and slowly turning light rays behind it.
-- It breathes gently on its own; hover the card and it wiggles back and forth, the aura
-- spins faster and stars burst out. Everything animates every frame using Scale, Rotation
-- and UIScale (pixel offsets are whole numbers, which is what made the old bob stutter).
local ICON_EXTRA = {
	Starter = "\u{2B50}", DoubleMoney = "\u{1F4B5}", DoubleSpeed = "\u{26A1}", DoubleSteal = "\u{270B}",
	Treadmill = "\u{26A1}", Spin = "\u{1F340}", SpeedS = "\u{1F4A8}", SpeedM = "\u{1F45F}", SpeedL = "\u{2728}",
	SpeedXL = "\u{26A1}", SpeedXXL = "\u{1F680}", Cash5 = "\u{2728}", CashS = "\u{1FA99}", CashL = "\u{1F48E}",
	CashXL = "\u{1F4B0}", CashXXL = "\u{1F451}",
}
local shopIcons = {}
local function shopIcon(card, key, look, size, pos)
	local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = card})
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.92), BackgroundColor3 = look.B:Lerp(UI.WHITE, 0.65), BackgroundTransparency = 0.5, Parent = holder}, {UI.corner(1, true)})
	local aura = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3), BackgroundTransparency = 1, Parent = holder})
	for i = 0, 5 do
		local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.14, 0, 1, 0), Rotation = i * 30, BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = aura}, {UI.corner(1, true)})
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
	end
	local pic = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = holder})
	local scale = new("UIScale", {Parent = pic})
	label({Size = UDim2.fromScale(1, 1), Text = look.Icon, Outline = false, ZIndex = 2, Parent = pic})
	if ICON_EXTRA[key] then
		label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.82), Size = UDim2.fromScale(0.46, 0.46), Rotation = 14, Text = ICON_EXTRA[key], Outline = false, ZIndex = 3, Parent = pic})
	end
	local a = {Pic = pic, Scale = scale, Aura = aura, Glow = glow, Phase = #shopIcons * 0.9, Hover = false, H = 0}
	table.insert(shopIcons, a)
	card.MouseEnter:Connect(function()
		a.Hover = true
		-- a little burst of stars from the picture
		for _ = 1, 7 do
			local star = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), Text = "\u{2726}", TextColor3 = math.random() < 0.5 and UI.WHITE or Color3.fromRGB(255, 240, 150), Outline = false, ZIndex = 4, Parent = holder})
			local ang = math.random() * math.pi * 2
			TweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5 + math.cos(ang) * 0.75, 0.5 + math.sin(ang) * 0.75), Rotation = math.random(-180, 180), TextTransparency = 1}):Play()
			task.delay(0.65, star.Destroy, star)
		end
	end)
	card.MouseLeave:Connect(function()
		a.Hover = false
	end)
	return holder
end

local function priceButton(parent, item, kind, pos, size, anchor)
	local b, t, setColor = UI.actionButton({AnchorPoint = anchor, Position = pos, Size = size, Text = "", Parent = parent}, UI.PURPLE)
	shopButtons[item.Key] = {Text = t, SetColor = setColor, Item = item, Kind = kind}
	b.Activated:Connect(function()
		if item.Id == 0 then return end
		if kind == "pass" then
			if player:GetAttribute("Pass_" .. item.Key) then return end
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			if item.OneTime and player:GetAttribute("StarterBought") then return end
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
	end)
end

local shopSections = {}
local function sectionTitle(order, text, key)
	local f = new("Frame", {LayoutOrder = order, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = shopList})
	if key then
		shopSections[key] = f
	end
	new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.new(0.22, 0, 0, 3), BackgroundColor3 = UI.GOLD, BorderSizePixel = 0, Parent = f})
	new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.95, 0.5), Size = UDim2.new(0.22, 0, 0, 3), BackgroundColor3 = UI.GOLD, BorderSizePixel = 0, Parent = f})
	local t = label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.46, 0, 1, 0), Text = "\u{25C6} " .. text .. " \u{25C6}", TextColor3 = UI.GOLD, Outline = 3.5, Parent = f})
	UI.gradient(t, Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 180, 40), 90)
end

local function findItem(list, key)
	for _, it in ipairs(list) do
		if it.Key == key then
			return it
		end
	end
end

-- Featured: Starter Pack banner
do
	local starter = findItem(robux.Products, "Starter")
	local card = new("Frame", {LayoutOrder = 1, Size = UDim2.new(1, -10, 0, 200), BackgroundColor3 = UI.WHITE, Parent = shopList}, {UI.corner(18), UI.stroke(UI.BLACK, 4)})
	UI.gradient(card, Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 140, 30), 20)
	UI.sparkles(card, 0.4)
	UI.shine(card, 4)
	shopIcon(card, "Starter", {Icon = "\u{1F381}", B = Color3.fromRGB(255, 160, 40)}, 160, UDim2.fromOffset(101, 100))
	label({Position = UDim2.fromOffset(200, 14), Size = UDim2.new(1, -440, 0, 48), TextXAlignment = Enum.TextXAlignment.Left, Text = "STARTER PACK", Outline = 4, Parent = card})
	for i, line in ipairs({"\u{2022} $25,000 Cash", "\u{2022} +5,000 Speed", "\u{2022} A free Epic Game"}) do
		label({Position = UDim2.fromOffset(204, 66 + (i - 1) * 40), Size = UDim2.new(1, -440, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, Text = line, Outline = 3, Parent = card})
	end
	label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 18), Size = UDim2.fromOffset(200, 26), Text = "ONE TIME ONLY!", TextColor3 = Color3.fromRGB(255, 255, 255), Outline = 3, Parent = card})
	priceButton(card, starter, "product", UDim2.new(1, -20, 0.5, 18), UDim2.fromOffset(210, 84), Vector2.new(1, 0.5))
end

sectionTitle(2, "GAME PASSES")
-- two passes per row; a third wraps onto the next row, centred
local passRow = new("Frame", {LayoutOrder = 3, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = shopList},
	{new("UIGridLayout", {CellSize = UDim2.new(0.48, 0, 0, 236), CellPadding = UDim2.new(0.02, 0, 0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
local PASS_LOOK = {
	DoubleMoney = {Icon = "\u{1F4B0}", A = Color3.fromRGB(255, 240, 160), B = Color3.fromRGB(250, 190, 50)},
	DoubleSpeed = {Icon = "\u{1F45F}", A = Color3.fromRGB(190, 255, 210), B = Color3.fromRGB(70, 210, 130)},
	DoubleSteal = {Icon = "\u{1F3AE}", A = Color3.fromRGB(255, 190, 200), B = Color3.fromRGB(230, 60, 110)},
}
for i, pass in ipairs(robux.Passes) do
	local look = PASS_LOOK[pass.Key] or PASS_LOOK.DoubleMoney
	local card = new("Frame", {LayoutOrder = i, BackgroundColor3 = UI.WHITE, Parent = passRow}, {UI.corner(18), UI.stroke(UI.BLACK, 4)})
	UI.gradient(card, look.A, look.B, 110)
	UI.sparkles(card, 0.6)
	shopIcon(card, pass.Key, look, 140, UDim2.fromOffset(87, 105))
	local two = label({Position = UDim2.fromOffset(92, 120), Size = UDim2.fromOffset(84, 60), Text = "2X", Rotation = -12, TextColor3 = UI.GOLD, Outline = 4, Parent = card})
	UI.gradient(two, Color3.fromRGB(255, 240, 140), Color3.fromRGB(240, 150, 20), 90)
	label({Position = UDim2.new(0, 170, 0, 18), Size = UDim2.new(1, -180, 0, 46), TextXAlignment = Enum.TextXAlignment.Left, Text = pass.Name, Outline = 4, Parent = card})
	label({Position = UDim2.new(0, 172, 0, 68), Size = UDim2.new(1, -184, 0, 60), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = pass.Desc, Outline = 2.5, Parent = card})
	priceButton(card, pass, "pass", UDim2.new(1, -16, 1, -16), UDim2.fromOffset(190, 70), Vector2.new(1, 1))
end

sectionTitle(4, "BOOSTS")
local boostGrid = new("Frame", {LayoutOrder = 5, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = shopList},
	{new("UIGridLayout", {CellSize = UDim2.new(0.31, 0, 0, 230), CellPadding = UDim2.new(0.02, 0, 0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
local BOOST_LOOK = {
	Treadmill = {Icon = "\u{1F3C3}", A = Color3.fromRGB(150, 220, 255), B = Color3.fromRGB(60, 140, 240)},
	CashS = {Icon = "\u{1F4B5}", A = Color3.fromRGB(190, 255, 180), B = Color3.fromRGB(60, 190, 80)},
	CashL = {Icon = "\u{1F911}", A = Color3.fromRGB(255, 230, 150), B = Color3.fromRGB(240, 160, 40)},
	Spin = {Icon = "\u{1F3A1}", A = Color3.fromRGB(255, 190, 240), B = Color3.fromRGB(220, 80, 200)},
}
BOOST_LOOK.SpeedS = {Icon = "\u{1F45F}", A = Color3.fromRGB(170, 220, 255), B = Color3.fromRGB(60, 140, 240)}
BOOST_LOOK.SpeedM = {Icon = "\u{26A1}", A = Color3.fromRGB(150, 240, 255), B = Color3.fromRGB(30, 160, 230)}
BOOST_LOOK.SpeedL = {Icon = "\u{1F680}", A = Color3.fromRGB(190, 170, 255), B = Color3.fromRGB(100, 60, 230)}
BOOST_LOOK.CashXL = {Icon = "\u{1F3E6}", A = Color3.fromRGB(255, 240, 160), B = Color3.fromRGB(230, 150, 20)}
local boosts = {}
for _, p in ipairs(robux.Products) do
	if p.Section == "boost" then
		table.insert(boosts, p)
	end
end
if robux.Spin then
	table.insert(boosts, {Key = robux.Spin.Key, Id = robux.Spin.Id, Name = robux.Spin.Name, Desc = "Spin the Lucky Wheel again right now", Price = robux.Spin.Price})
end
for i, p in ipairs(boosts) do
	local look = BOOST_LOOK[p.Key] or BOOST_LOOK.CashS
	local card = new("Frame", {LayoutOrder = i, BackgroundColor3 = UI.WHITE, Parent = boostGrid}, {UI.corner(16), UI.stroke(UI.BLACK, 4)})
	UI.gradient(card, look.A, look.B, 90)
	UI.sparkles(card, 0.9)
	shopIcon(card, p.Key, look, 78, UDim2.new(0.5, 0, 0, 49))
	label({Position = UDim2.new(0, 8, 0, 92), Size = UDim2.new(1, -16, 0, 30), Text = p.Name, Outline = 3, Parent = card})
	label({Position = UDim2.new(0, 10, 0, 124), Size = UDim2.new(1, -20, 0, 36), TextWrapped = true, Font = Enum.Font.GothamBold, Text = p.Desc, Outline = 2, Parent = card})
	priceButton(card, p, "product", UDim2.new(0.5, 0, 1, -10), UDim2.new(1, -24, 0, 54), Vector2.new(0.5, 1))
end

-- SPEED PACKS and CASH PACKS (the + buttons by your cash and speed jump here)
BOOST_LOOK.SpeedXL = {Icon = "\u{1F32A}", A = Color3.fromRGB(170, 200, 255), B = Color3.fromRGB(60, 80, 220)}
BOOST_LOOK.SpeedXXL = {Icon = "\u{1F31F}", A = Color3.fromRGB(255, 200, 255), B = Color3.fromRGB(160, 60, 230)}
BOOST_LOOK.Cash5 = {Icon = "\u{1FA99}", A = Color3.fromRGB(220, 255, 200), B = Color3.fromRGB(90, 200, 90)}
BOOST_LOOK.CashXXL = {Icon = "\u{1F30D}", A = Color3.fromRGB(255, 225, 140), B = Color3.fromRGB(220, 120, 20)}
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
local function packSection(order, title, key, section)
	sectionTitle(order, title, key)
	local grid = new("Frame", {LayoutOrder = order + 1, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = shopList},
		{new("UIGridLayout", {CellSize = UDim2.new(0.31, 0, 0, 250), CellPadding = UDim2.new(0.02, 0, 0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
	local list = {}
	for _, p in ipairs(robux.Products) do
		if p.Section == section then
			table.insert(list, p)
		end
	end
	for i, p in ipairs(list) do
		local look = BOOST_LOOK[p.Key] or BOOST_LOOK.CashS
		local card = new("Frame", {LayoutOrder = i, BackgroundColor3 = UI.WHITE, Parent = grid}, {UI.corner(18), UI.stroke(UI.BLACK, 4)})
		UI.gradient(card, look.A, look.B, 90)
		UI.sparkles(card, 0.9)
		shopIcon(card, p.Key, look, 76, UDim2.new(0.5, 0, 0, 50))
		label({Position = UDim2.new(0, 8, 0, 96), Size = UDim2.new(1, -16, 0, 26), Text = p.Name, Outline = 3, Parent = card})
		-- the amount, big and clear
		local amount = label({Position = UDim2.new(0, 8, 0, 124), Size = UDim2.new(1, -16, 0, 42), Text = "", TextColor3 = Color3.fromRGB(255, 255, 180), Outline = 3.5, Parent = card})
		if p.Amount then
			amount.Text = "+" .. fmt(p.Amount) .. " \u{1F45F}"
		else
			cashAmountLabels[amount] = p
			label({Position = UDim2.new(0, 8, 0, 164), Size = UDim2.new(1, -16, 0, 16), Font = Enum.Font.GothamBold, Text = (p.Minutes >= 60 and (p.Minutes / 60 .. " hour" .. (p.Minutes > 60 and "s" or "")) or (p.Minutes .. " min")) .. " of your income", Outline = 2, Parent = card})
		end
		if i == #list then
			local ribbon = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0, 14), Size = UDim2.fromOffset(110, 26), Rotation = 18, BackgroundColor3 = UI.WHITE, ZIndex = 8, Parent = card}, {UI.corner(8), UI.stroke(UI.BLACK, 2.5)})
			UI.gradient(ribbon, Color3.fromRGB(255, 90, 90), Color3.fromRGB(200, 20, 50), 90)
			label({Size = UDim2.fromScale(1, 1), Text = "BEST VALUE", Outline = 2, ZIndex = 9, Parent = ribbon})
		end
		priceButton(card, p, "product", UDim2.new(0.5, 0, 1, -10), UDim2.new(1, -24, 0, 52), Vector2.new(0.5, 1))
	end
	refreshCashAmounts()
end
packSection(10, "SPEED PACKS", "speed", "speed")
packSection(20, "CASH PACKS", "cash", "cash")

-- A slow drifting pattern behind the whole shop, so it feels alive (very light)
do
	local layer = new("Frame", {Name = "ShopPattern", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0, Parent = shopPanel.Body})
	local dots = {}
	for k = 1, 18 do
		local d = new("TextLabel", {BackgroundTransparency = 1, Text = (k % 3 == 0) and "\u{2605}" or "\u{25C6}", Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = UI.WHITE, TextTransparency = 0.88, Size = UDim2.fromOffset(28, 28), ZIndex = 0, Parent = layer})
		dots[k] = {Label = d, X = math.random(), Y = math.random(), Speed = 0.01 + math.random() * 0.015}
	end
	task.spawn(function()
		while layer.Parent do
			if shopPanel.Frame.Visible then
				for _, d in ipairs(dots) do
					d.Y = (d.Y - d.Speed * 0.05) % 1
					d.Label.Position = UDim2.fromScale(d.X, d.Y)
				end
			end
			task.wait(0.05)
		end
	end)
end

local function refreshShop()
	for key, s in pairs(shopButtons) do
		local owned = (s.Kind == "pass" and player:GetAttribute("Pass_" .. key)) or (s.Item.OneTime and player:GetAttribute("StarterBought"))
		if s.Item.Id == 0 then
			s.Text.Text = "SOON"
			s.SetColor(Color3.fromRGB(110, 100, 140))
		elseif owned then
			s.Text.Text = "OWNED \u{2713}"
			s.SetColor(Color3.fromRGB(110, 100, 140))
		else
			s.Text.Text = UI.ROBUX .. " " .. s.Item.Price
			s.SetColor(UI.PURPLE)
		end
	end
end
for _, attr in ipairs({"Pass_DoubleMoney", "Pass_DoubleSpeed", "Pass_DoubleSteal", "StarterBought"}) do
	player:GetAttributeChangedSignal(attr):Connect(refreshShop)
end

-- one smooth per-frame loop drives every shop picture (only while the shop is open)
RunService.RenderStepped:Connect(function(dt)
	if not shopPanel.Frame.Visible then return end
	local t = os.clock()
	for _, a in ipairs(shopIcons) do
		a.H += ((a.Hover and 1 or 0) - a.H) * math.min(1, dt * 10)
		local h = a.H
		a.Pic.Position = UDim2.fromScale(0.5, 0.5 + math.sin(t * 2 + a.Phase) * (0.03 + 0.02 * h))
		a.Pic.Rotation = math.sin(t * (2 + 6 * h) + a.Phase) * (2 + 11 * h)
		a.Scale.Scale = 1 + 0.035 * math.sin(t * 2.6 + a.Phase) + 0.14 * h
		a.Aura.Rotation = (a.Aura.Rotation + dt * (18 + 80 * h)) % 360
		a.Glow.BackgroundTransparency = 0.5 - 0.2 * h + 0.08 * math.sin(t * 2.4 + a.Phase)
	end
end)
shopButton.Activated:Connect(function()
	openPanel("Shop", refreshShop)
end)

-- Open the shop at a section (used by the + buttons next to cash and speed)
local openSection = new("BindableEvent", {Name = "OpenShopSection", Parent = gui})
openSection.Event:Connect(function(section)
	if not shopPanel.Frame.Visible then
		openPanel("Shop", refreshShop)
	end
	task.wait(0.1)
	local target = shopSections[section]
	if target then
		local y = target.AbsolutePosition.Y - shopList.AbsolutePosition.Y + shopList.CanvasPosition.Y - 6
		TweenService:Create(shopList, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(0, math.max(0, y))}):Play()
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
