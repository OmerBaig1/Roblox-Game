--[[
	GameViewer
	A game up close, opened from a cover in any menu: the case itself (flip it to read the back) beside its details.
	Everything comes from CasePackaging, the same place the cases in the world get theirs.

	GameViewer.open(windowBody, {Name, Rarity, Color})
	GameViewer.close()
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local CP = require(ReplicatedStorage:WaitForChild("CasePackaging"))
local new, C = UI.new, K.C
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

local GameViewer = {}
local current

function GameViewer.close()
	if current then
		current:Destroy()
		current = nil
	end
end

function GameViewer.open(parent, rec)
	GameViewer.close()
	local d = CP.details(rec.Name)
	local shade = new("TextButton", {Name = "GameViewer", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.PanelLow, AutoButtonColor = false, Text = "", ZIndex = 60, Parent = parent}, {K.corner(18)})
	current = shade
	shade.Activated:Connect(GameViewer.close) -- tapping the background closes it; the case and details sit on top

	-- THE CASE: fits the height and keeps its own proportions; the flip squeezes it to nothing, swaps sides and opens again
	local slot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 224, 0.5, 0), Size = UDim2.new(0, 400, 1, -36), BackgroundTransparency = 1, ZIndex = 2, Parent = shade},
		{new("UIAspectRatioConstraint", {AspectRatio = CP.aspect(rec.Name)})})
	local flip = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = slot})
	local front = CP.Cover(rec, {Fill = true})
	front.Parent = flip
	local back

	-- THE DETAILS
	local info = new("Frame", {Position = UDim2.fromOffset(446, 22), Size = UDim2.new(1, -468, 1, -92), BackgroundTransparency = 1, ZIndex = 2, Parent = shade},
		{new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})})
	local order = 0
	local function line(props)
		order += 1
		props.LayoutOrder, props.ZIndex, props.Parent = order, 3, info
		props.Size, props.AutomaticSize, props.TextWrapped = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, true
		return K.text(props)
	end
	line({Text = rec.Name, FontFace = K.TITLE, TextSize = 36})
	order += 1
	local chips = new("Frame", {LayoutOrder = order, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ZIndex = 3, Parent = info},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center})})
	local rarityChip = K.chip({Text = string.upper(rec.Rarity or ""), Height = 28, TextSize = 14, Style = "solid", LayoutOrder = 1, ZIndex = 4, Parent = chips})
	rarityChip.BackgroundColor3 = rec.Color or C.Surface2
	K.chip({Text = "RATED " .. d.Rating, Height = 28, TextSize = 14, LayoutOrder = 2, ZIndex = 4, Parent = chips})
	K.chip({Text = d.Console, Height = 28, TextSize = 14, LayoutOrder = 3, ZIndex = 4, Parent = chips})
	line({Text = d.Tag, FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 22, TextColor3 = (d.Accent):Lerp(WHITE, 0.35)})
	if d.Desc ~= "" then
		line({Text = d.Desc, FontFace = K.font(Enum.FontWeight.Medium), TextSize = 19, TextColor3 = C.Text2})
	end
	for _, f in ipairs(d.Features) do
		line({Text = "\u{2022}  " .. f, FontFace = K.font(Enum.FontWeight.Bold), TextSize = 18})
	end
	line({Text = string.format("%s  \u{2022}  %s\n%s  \u{2022}  %s\nPublished by %s", d.Genre, d.Players, d.RatingName, d.Descriptor, d.Publisher), TextSize = 15, TextColor3 = C.Muted})

	-- THE BUTTONS
	local showingBack, busy = false, false
	local flipBtn = K.button({Text = "See the back", Kind = "secondary", TextSize = 17, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 446, 1, -18), Size = UDim2.fromOffset(170, 44), ZIndex = 4, Parent = shade})
	K.button({Text = "Close", Kind = "ghost", TextSize = 17, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -18), Size = UDim2.fromOffset(110, 44), ZIndex = 4, Parent = shade}).Activated:Connect(GameViewer.close)
	flipBtn.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local shut = TweenService:Create(flip, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 1)})
		shut:Play()
		shut.Completed:Wait()
		showingBack = not showingBack
		if showingBack and not back then
			back = CP.Back(rec.Name, {Fill = true}) -- only drawn if someone wants it
			back.Parent = flip
		end
		front.Visible = not showingBack
		if back then
			back.Visible = showingBack
		end
		flipBtn.setText(showingBack and "See the front" or "See the back")
		TweenService:Create(flip, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
		busy = false
	end)
end

return GameViewer
