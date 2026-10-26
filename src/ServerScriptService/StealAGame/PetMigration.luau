--[[
	PetMigration
	Old saves list pets as {I = id, K = "egg-rarity"} from the 15-egg catalog. This turns them into the premium
	catalog's ids (docs/pets/INTEGRATION.md, Phase 3) without ever lowering a pet's rarity or boost:
	old egg e becomes new egg min(8, e // 2 + 1) and keeps its tier. If that egg has no pet of the tier (Secrets in
	the first three eggs), the lowest egg above it that has one is used. Among several pets of a tier the choice is
	fixed by the old egg, so the same old pet always becomes the same new pet.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("Catalog"))

local M = {}
M.VERSION = 2

-- an old key ("egg-rarity") -> the new pet id; a new id comes back unchanged; nil if the key never existed
function M.migrateKey(key)
	if type(key) ~= "string" then
		return nil
	end
	if Catalog.PETS[key] then
		return key
	end
	local e, r = key:match("^(%d+)%-(%d+)$")
	e, r = tonumber(e), tonumber(r)
	if not e or e < 1 or e > 15 or r < 1 or r > 7 then
		return nil
	end
	for k = math.min(#Catalog.EGGS, e // 2 + 1), #Catalog.EGGS do
		local pool = Catalog.EGGS[k].Tiers[r]
		if pool then
			return pool[e % 2 % #pool + 1].Id
		end
	end
	return nil
end

-- an old saved pet table -> the new format. Pet ids (I) and the equipped list are kept as they are, so nothing is
-- awarded again; entries whose key never existed are dropped (load drops them today too). A save already at
-- VERSION, or anything that isn't a save, comes back untouched, so running it twice changes nothing.
function M.migrateSave(saved)
	if type(saved) ~= "table" or (tonumber(saved.PetVersion) or 1) >= M.VERSION then
		return saved
	end
	local out = table.clone(saved)
	out.List = {}
	for _, p in ipairs(type(saved.List) == "table" and saved.List or {}) do
		local id = type(p) == "table" and M.migrateKey(p.K)
		if id then
			table.insert(out.List, {I = p.I, K = id})
		end
	end
	if type(saved.Eq) == "table" then
		out.Eq = table.clone(saved.Eq)
	end
	out.PetVersion = M.VERSION
	return out
end

return M
