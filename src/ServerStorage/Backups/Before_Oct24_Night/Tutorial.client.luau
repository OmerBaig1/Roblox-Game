--[[
	Tutorial
	A first-time walkthrough for brand-new players:
	  1. Glowing arrows on the ground lead to the Game Vault
	  2. ...then to a game to steal
	  3. Once you're holding it, a line of arrows leads back to your base
	  4. A guide box types out how installing, the Index, money and the treadmill work
	  5. Finally it points at the ? button, where help always lives
	Finishing (or skipping) tells the server, so it only ever runs once.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local player = Players.LocalPlayer
local new, label = UI.new, UI.label

-- Wait for the save to load; only players who haven't done it yet get the tutorial
while player:GetAttribute("TutorialDone") == nil do
	player:GetAttributeChangedSignal("TutorialDone"):Wait()
end
if player:GetAttribute("TutorialDone") then
	return
end

local map = workspace:WaitForChild("StealAGameMap")
local ENTRANCE = map:GetAttribute("VaultEntrance") or Vector3.new(0, 0, 20)
local HALL_HALF = (map:GetAttribute("HallWidth") or 120) / 2
local gamesFolder = map:WaitForChild("VaultGames")
local bases = map:WaitForChild("Bases")
local playerGui = player:WaitForChild("PlayerGui")
local menuGui = playerGui:WaitForChild("MenuUI")
local baseGui = playerGui:WaitForChild("BaseUI")

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Your base: its front barrier carries your UserId once you own it
local function myPlot()
	for _, plot in ipairs(bases:GetChildren()) do
		local b = plot:FindFirstChild("LaserBarrier")
		if b and b:GetAttribute("OwnerId") == player.UserId then
			return plot, b
		end
	end
end
local function insideMyBase(pos)
	local _, barrier = myPlot()
	if not barrier then return false end
	local lp = barrier.CFrame:PointToObjectSpace(pos)
	return lp.Z > -1 and math.abs(lp.X) < 34
end
local function inVault(pos)
	return math.abs(pos.X) < HALL_HALF and pos.Z > ENTRANCE.Z + 2
end

------------------------------------------------------------------
-- GUIDE BOX: the text types itself out like someone is writing to you
------------------------------------------------------------------
local gui = new("ScreenGui", {Name = "TutorialUI", ResetOnSpawn = false, DisplayOrder = 15, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local box = new("Frame", {Name = "Guide", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -236), Size = UDim2.new(0.55, 0, 0, 156), BackgroundColor3 = UI.WHITE, Visible = false, Parent = gui},
	{UI.corner(20), UI.stroke(UI.BLACK, 4), new("UISizeConstraint", {MaxSize = Vector2.new(720, 156), MinSize = Vector2.new(340, 0)})})
UI.gradient(box, Color3.fromRGB(70, 50, 130), UI.BG, 90)
local boxScale = new("UIScale", {Parent = box})
local face = new("Frame", {Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(70, 70), BackgroundColor3 = UI.WHITE, Parent = box}, {UI.corner(1, true), UI.stroke(UI.BLACK, 3)})
UI.gradient(face, Color3.fromRGB(255, 225, 120), Color3.fromRGB(255, 150, 40), 90)
label({Position = UDim2.fromScale(0.12, 0.12), Size = UDim2.fromScale(0.76, 0.76), Text = "\u{1F575}\u{FE0F}", Outline = false, Parent = face})
label({Position = UDim2.fromOffset(98, 10), Size = UDim2.new(1, -230, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Text = "HOW TO STEAL", TextColor3 = UI.GOLD, Outline = 3, Parent = box})
local stepText = label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 13), Size = UDim2.fromOffset(110, 20), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Text = "", TextColor3 = Color3.fromRGB(200, 190, 235), Outline = 2, Parent = box})
local body = label({Position = UDim2.fromOffset(98, 40), Size = UDim2.new(1, -114, 0, 66), Font = Enum.Font.GothamBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Outline = false, Parent = box})
new("UITextSizeConstraint", {MaxTextSize = 21, Parent = body})
local nextButton, nextText = UI.actionButton({Name = "Next", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.fromOffset(150, 38), Text = "NEXT \u{25B6}", Parent = box}, UI.GREEN)
local skipButton = new("TextButton", {Name = "Skip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.fromOffset(70, 24), BackgroundTransparency = 1, Text = "Skip", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(180, 170, 215), Parent = box})

local typeToken, typing = 0, false
local function say(text, step, buttonText)
	typeToken += 1
	local my = typeToken
	body.Text = text
	body.MaxVisibleGraphemes = 0
	stepText.Text = step or ""
	nextButton.Visible = buttonText ~= nil
	nextText.Text = buttonText or ""
	if not box.Visible then
		box.Visible = true
		boxScale.Scale = 0.6
		TweenService:Create(boxScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	else
		boxScale.Scale = 0.96
		TweenService:Create(boxScale, TweenInfo.new(0.15), {Scale = 1}):Play()
	end
	typing = true
	task.spawn(function()
		local n = utf8.len(text) or #text
		for i = 1, n do
			if typeToken ~= my then return end
			body.MaxVisibleGraphemes = i
			task.wait(0.024)
		end
		if typeToken == my then
			body.MaxVisibleGraphemes = -1
			typing = false
		end
	end)
end

------------------------------------------------------------------
-- POINTER: a bouncing hand and a glowing ring around a button on screen
------------------------------------------------------------------
local hand = label({AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Text = "", Outline = false, Visible = false, ZIndex = 20, Parent = gui})
local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 19, Parent = gui}, {UI.corner(20)})
local ringStroke = UI.stroke(UI.GOLD, 5)
ringStroke.Parent = ring
local pointTarget, pointDir -- a GuiObject, and which side the hand sits on ("left", "right" or "below")
local HANDS = {left = "\u{1F449}", right = "\u{1F448}", below = "\u{1F446}"}
local function pointAt(target, dir)
	pointTarget, pointDir = target, dir
	hand.Text = dir and HANDS[dir] or ""
end

------------------------------------------------------------------
-- GROUND ARROWS: chevrons that flow along a route toward the goal
------------------------------------------------------------------
local arrowFolder = new("Folder", {Name = "TutorialArrows", Parent = workspace})
local ARROW_COLOR = Color3.fromRGB(255, 220, 60)
local MAX_ARROWS, SPACING = 28, 6
local arrows = {}
for i = 1, MAX_ARROWS do
	local pair = {}
	for k = 1, 2 do
		pair[k] = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = ARROW_COLOR, Size = Vector3.new(0.8, 0.25, 3.2), Transparency = 1, Parent = arrowFolder})
	end
	arrows[i] = pair
end
local ARM_A, ARM_B = CFrame.Angles(0, math.rad(38), 0) * CFrame.new(0, 0, 1.45), CFrame.Angles(0, -math.rad(38), 0) * CFrame.new(0, 0, 1.45)
local function setArrow(pair, cf, transparency)
	if cf then
		pair[1].CFrame, pair[2].CFrame = cf * ARM_A, cf * ARM_B
	end
	pair[1].Transparency, pair[2].Transparency = transparency, transparency
end

-- A floating marker over the goal (seen through walls)
local markerPart = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, Parent = arrowFolder})
local marker = new("BillboardGui", {Size = UDim2.fromOffset(200, 110), AlwaysOnTop = true, LightInfluence = 0, Enabled = false, Adornee = markerPart, Parent = arrowFolder})
label({Size = UDim2.new(1, 0, 0, 36), Text = "", Outline = 3, Name = "Title", TextColor3 = UI.GOLD, Parent = marker})
label({Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 70), Text = "\u{2B07}\u{FE0F}", Outline = false, Parent = marker})

local route -- list of points the arrows lead through (nil hides them)
local function setRoute(points, goal, goalText)
	route = points
	if goal then
		markerPart.Position = goal
		marker.Title.Text = goalText or ""
	end
	marker.Enabled = goal ~= nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {map}
local function groundY(x, z, fromY)
	local origin = Vector3.new(x, fromY, z)
	for _ = 1, 4 do
		local hit = workspace:Raycast(origin, Vector3.new(0, -30, 0), rayParams)
		if not hit then return nil end
		if hit.Instance.Transparency < 0.95 then
			return hit.Position.Y
		end
		origin = hit.Position - Vector3.new(0, 0.05, 0) -- skip invisible parts
	end
	return nil
end

local arrowsShown = false
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	-- on-screen pointer
	local target = pointTarget
	if target and UI.shown(target) then
		local inset = GuiService:GetGuiInset()
		local pos, size = target.AbsolutePosition + inset, target.AbsoluteSize
		local center = pos + size / 2
		local bob = math.sin(t * 6) * 8
		local offset = pointDir == "left" and Vector2.new(-size.X / 2 - 40 + bob, 0)
			or pointDir == "right" and Vector2.new(size.X / 2 + 40 - bob, 0)
			or Vector2.new(0, size.Y / 2 + 40 - bob)
		hand.Position = UDim2.fromOffset(center.X + offset.X, center.Y + offset.Y)
		ring.Position = UDim2.fromOffset(center.X, center.Y)
		ring.Size = UDim2.fromOffset(size.X + 14, size.Y + 14)
		ringStroke.Transparency = 0.15 + (math.sin(t * 5) + 1) * 0.25
		hand.Visible, ring.Visible = true, true
	else
		hand.Visible, ring.Visible = false, false
	end

	-- ground arrows
	local root = getRoot()
	if not route or not root then
		if arrowsShown then
			arrowsShown = false
			for _, pair in ipairs(arrows) do
				setArrow(pair, nil, 1)
			end
		end
		return
	end
	arrowsShown = true
	marker.StudsOffset = Vector3.new(0, 6 + math.sin(t * 4) * 0.8, 0)
	local pts = {Vector3.new(root.Position.X, 0, root.Position.Z)}
	for _, p in ipairs(route) do
		table.insert(pts, Vector3.new(p.X, 0, p.Z))
	end
	local lengths, total = {}, 0
	for i = 1, #pts - 1 do
		lengths[i] = (pts[i + 1] - pts[i]).Magnitude
		total += lengths[i]
	end
	local fromY = root.Position.Y + 2
	local phase = (t * 7) % SPACING -- the arrows creep forward toward the goal
	for i, pair in ipairs(arrows) do
		local d = 5 + phase + (i - 1) * SPACING
		if d > total - 2 then
			setArrow(pair, nil, 1)
		else
			local seg, along = 1, d
			while seg < #lengths and along > lengths[seg] do
				along -= lengths[seg]
				seg += 1
			end
			local a, b = pts[seg], pts[seg + 1]
			local dir = (b - a).Magnitude > 0.01 and (b - a).Unit or Vector3.new(0, 0, -1)
			local p = a + dir * along
			local y = groundY(p.X, p.Z, fromY)
			if not y then
				setArrow(pair, nil, 1)
			else
				local pos = Vector3.new(p.X, y + 0.3, p.Z)
				-- fade in near you and out near the goal, with a shimmer running toward the goal
				local edge = math.clamp((d - 5) / 4, 0, 1) * math.clamp((total - 2 - d) / 6, 0, 1)
				local shimmer = (math.sin(t * 6 - i * 0.8) + 1) / 2
				setArrow(pair, CFrame.lookAt(pos, pos + dir), 1 - edge * (0.55 + shimmer * 0.4))
			end
		end
	end
end)

------------------------------------------------------------------
-- THE STEPS
------------------------------------------------------------------
local TOTAL = 8
local function stepLabel(n)
	return n .. " / " .. TOTAL
end
local advance = Instance.new("BindableEvent")
local finished = false

local function finish()
	if finished then return end
	finished = true
	typeToken += 1
	setRoute(nil)
	pointAt(nil)
	remotes:WaitForChild("TutorialDone"):FireServer()
	TweenService:Create(boxScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
	task.delay(0.3, function()
		gui:Destroy()
		arrowFolder:Destroy()
	end)
	advance:Fire()
end
skipButton.Activated:Connect(finish)
nextButton.Activated:Connect(function()
	if typing then
		-- first tap finishes the sentence, the next one moves on
		typeToken += 1
		body.MaxVisibleGraphemes = -1
		typing = false
	else
		advance:Fire()
	end
end)

-- Show a line with a NEXT button and wait for it (or for `doneWhen` to come true)
local function textStep(text, n, buttonText, doneWhen)
	if finished then return end
	say(text, stepLabel(n), buttonText or "NEXT \u{25B6}")
	local done = false
	local conn = advance.Event:Connect(function()
		done = true
	end)
	while not done and not finished do
		if doneWhen and doneWhen() then
			break
		end
		task.wait(0.1)
	end
	conn:Disconnect()
end

local function held()
	return (player:GetAttribute("Held") or 0) > 0
end

-- The nearest game still sitting on a pedestal in the first level
local function nearestVaultGame(from)
	local best, bestD
	for _, item in ipairs(gamesFolder:GetChildren()) do
		if item:IsA("BasePart") and item.Position.Z < ENTRANCE.Z + 200 then
			local d = (item.Position - from).Magnitude
			if not bestD or d < bestD then
				best, bestD = item, d
			end
		end
	end
	return best
end

local VAULT_OUTSIDE = ENTRANCE + Vector3.new(0, 0, -8)
local VAULT_INSIDE = ENTRANCE + Vector3.new(0, 0, 14)

local function runTutorial()
	-- wait until you have a base and a body
	while not (myPlot() and getRoot()) do
		task.wait(0.5)
	end
	task.wait(1.5)

	-- 1-3: vault, steal, home (repeats if a shopkeeper takes the game back)
	local stage = "vault"
	while not finished and stage ~= "home done" do
		local root = getRoot()
		if root then
			local pos = root.Position
			if stage == "vault" then
				if inVault(pos) then
					stage = "steal"
				elseif held() then
					stage = "home"
				else
					setRoute({VAULT_OUTSIDE, VAULT_INSIDE}, ENTRANCE + Vector3.new(0, 6, 0), "GAME VAULT")
					if stepText.Text ~= stepLabel(1) then
						say("Welcome to Steal a Game! Follow the glowing arrows to the Game Vault.", stepLabel(1))
					end
				end
			elseif stage == "steal" then
				if held() then
					stage = "home"
				else
					local item = nearestVaultGame(pos)
					if item then
						local pts = inVault(pos) and {item.Position} or {VAULT_OUTSIDE, VAULT_INSIDE, item.Position}
						setRoute(pts, item.Position, "STEAL ME!")
					else
						setRoute(nil)
					end
					if stepText.Text ~= stepLabel(2) then
						say("Every level has 3 games on pedestals. Walk up to one and hold E to steal it!", stepLabel(2))
					end
				end
			elseif stage == "home" then
				local plot, barrier = myPlot()
				if not held() then
					if insideMyBase(pos) then
						stage = "home done"
					else
						stage = "steal"
						say("The shopkeeper took it back! Grab another one and run straight home.", stepLabel(2))
					end
				elseif barrier then
					local home = (barrier.CFrame * CFrame.new(0, -7, 6)).Position
					local pts = inVault(pos) and {ENTRANCE + Vector3.new(0, 0, -6), home} or {home}
					setRoute(pts, home + Vector3.new(0, 4, 0), "YOUR BASE")
					if stepText.Text ~= stepLabel(3) then
						say("You got one! Now run it back to your base before the shopkeeper catches you!", stepLabel(3))
					end
				end
			end
		end
		task.wait(0.15)
	end
	setRoute(nil)

	-- 4: installing
	pointAt(baseGui:FindFirstChild("DOWNLOADS", true), "left")
	textStep("Nice steal! Your game is installing in one of your cases. Games only earn money once they finish installing. Check DOWNLOADS to see how long is left.", 4)

	-- 5: the Index (moves on by itself once you claim)
	local indexButton = menuGui:FindFirstChild("INDEX", true)
	local indexPanel = menuGui:FindFirstChild("Index")
	local claimAll = indexPanel and indexPanel:FindFirstChild("ClaimAll", true)
	local function claimedSomething()
		if indexPanel and indexPanel.Visible then
			pointAt(claimAll, "below")
		else
			pointAt(indexButton, "right")
		end
		local ok, state = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("IndexState") or "{}")
		if ok then
			for _, info in pairs(state) do
				if info.C then
					return true
				end
			end
		end
		return false
	end
	textStep("Every new game you find goes in your INDEX. Open it and claim the reward for free cash and speed!", 5, "NEXT \u{25B6}", claimedSomething)

	-- 6: collecting money (arrows to the cash pad)
	pointAt(nil)
	local plot = myPlot()
	local pad = plot and plot:FindFirstChild("CollectPad")
	if pad then
		setRoute({pad.Position}, pad.Position + Vector3.new(0, 3, 0), "COLLECT CASH")
	end
	textStep("Installed games earn money every second. Walk over the green pad in your base to collect it.", 6)

	-- 7: the treadmill (arrows to it)
	local tread = plot and plot:FindFirstChild("TreadmillAnchor")
	if tread then
		setRoute({tread.Position}, tread.Position + Vector3.new(0, 4, 0), "TREADMILL")
	end
	textStep("Run on your treadmill to get faster. Faster runners can escape the shopkeepers deeper in the Vault, where the rarer games are!", 7)
	setRoute(nil)

	-- 8: where to find help
	pointAt(menuGui:FindFirstChild("INFO"), "below")
	textStep("That's it! If you ever get stuck, press the ? button to see how to play. Happy stealing!", 8, "GOT IT!")
	finish()
end

task.spawn(runTutorial)
