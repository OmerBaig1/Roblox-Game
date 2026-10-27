--[[
	PetLabDev (Studio only)
	The Pet Lab lives in ServerStorage so live players never load it. In Studio playtests this moves it
	into the Workspace (far from the map), gives each player the lab controls, and handles the P-key trip
	to and from the lab on the server, marking you with the InPetLab attribute so the fence check leaves you be.
	On real servers it does nothing.
	To remove the lab entirely: delete ServerStorage.PetLab, this script, and the inPetLab check in StealAGame.
]]
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local lab = ServerStorage:FindFirstChild("PetLab")
if not lab then
	return
end
-- raw mesh generations are kept for comparison only; they stay out of the world
local raws = lab:FindFirstChild("RawGenerations")
if raws then
	raws.Parent = ServerStorage
end
-- the gallery shows copies of the game's own models (ReplicatedStorage.PetAssets), so the lab never drifts from the game.
-- They keep their authored gallery positions. Persistent, because the lab is far from the map and would never stream in.
-- The client waits for this many descendants before animating a pet, so it never rigs half a model.
for _, src in ipairs(game:GetService("ReplicatedStorage").PetAssets:GetChildren()) do
	local m = src:Clone()
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute("Descendants", #m:GetDescendants())
	m.Parent = lab.Pets
end
lab.Parent = workspace
local origin = lab:GetAttribute("Origin")

local travel = lab.Code:FindFirstChild("PetLabTravel") or Instance.new("RemoteEvent")
travel.Name = "PetLabTravel"
travel.Parent = lab.Code

local returnTo = {}
travel.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not (char and char.PrimaryPart) then
		return
	end
	if player:GetAttribute("InPetLab") then
		char:PivotTo(returnTo[player] or char:GetPivot())
		returnTo[player] = nil
		task.delay(0.5, function()
			player:SetAttribute("InPetLab", nil)
		end)
	else
		returnTo[player] = char:GetPivot()
		player:SetAttribute("InPetLab", true)
		char:PivotTo(CFrame.lookAt(origin + Vector3.new(0, 4, 4), origin + Vector3.new(0, 4, -14)))
	end
end)

local function give(player)
	-- respawning puts you back in the game normally
	player.CharacterAdded:Connect(function()
		player:SetAttribute("InPetLab", nil)
		returnTo[player] = nil
	end)
	local ls = lab.Code:FindFirstChild("PetLabClient")
	if ls then
		-- inside a ScreenGui that survives respawns, so the controls keep working after you reset
		local holder = Instance.new("ScreenGui")
		holder.Name = "PetLabControls"
		holder.ResetOnSpawn = false
		ls:Clone().Parent = holder
		holder.Parent = player:WaitForChild("PlayerGui")
	end
end
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(give, p)
end
Players.PlayerAdded:Connect(give)
Players.PlayerRemoving:Connect(function(player)
	returnTo[player] = nil
end)
