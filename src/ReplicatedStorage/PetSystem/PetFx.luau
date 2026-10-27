--[[
	PetFx: shared pet effects for the game and the Pet Lab.
	Distance LOD lives in PetAnimator:Step (pass camDist). This module owns the outline budget: Roblox draws at
	most 31 Highlights at once, so only your own pets and the nearest others keep their Outline (PET_BIBLE §6).
	Call PetFx.outlines a few times a second, not every frame.
]]
local PetFx = {}

PetFx.MAX_OUTLINES = 24 -- under 31, leaving room for the game's other Highlights

-- models: pet models with an "Outline" Highlight; from: camera position; mine: optional {[model] = true}, always kept
function PetFx.outlines(models, from, mine)
	local list = {}
	for _, m in ipairs(models) do
		local hl = m:FindFirstChild("Outline")
		if hl and m.PrimaryPart then
			local d = (mine and mine[m]) and -1 or (m.PrimaryPart.Position - from).Magnitude
			table.insert(list, {hl, d})
		end
	end
	table.sort(list, function(a, b)
		return a[2] < b[2]
	end)
	for i, e in ipairs(list) do
		e[1].Enabled = i <= PetFx.MAX_OUTLINES
	end
end

return PetFx
