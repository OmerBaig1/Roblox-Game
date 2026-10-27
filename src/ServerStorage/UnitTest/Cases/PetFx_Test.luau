-- Tests for ReplicatedStorage.PetSystem.PetFx.outlines: never more than MAX_OUTLINES lit, your own pets always
-- lit even when far, the nearest others win the rest, and every PetAssets model can be handled.
return function(t)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PetFx = require(ReplicatedStorage.PetSystem.PetFx)
	local expect = t.expect

	local function fake(x)
		local m = Instance.new("Model")
		local p = Instance.new("Part")
		p.Position = Vector3.new(x, 0, 0)
		p.Parent = m
		m.PrimaryPart = p
		Instance.new("Highlight", m).Name = "Outline"
		return m
	end

	t.test("caps lit outlines, keeps mine, prefers nearest", function()
		local models = {}
		for i = 1, 60 do
			table.insert(models, fake(i * 10))
		end
		local far = models[60]
		PetFx.outlines(models, Vector3.zero, {[far] = true})
		local lit = 0
		for _, m in ipairs(models) do
			if m.Outline.Enabled then
				lit += 1
			end
		end
		expect.equal(lit, PetFx.MAX_OUTLINES)
		expect.truthy(far.Outline.Enabled)
		expect.truthy(models[1].Outline.Enabled)
		expect.equal(models[PetFx.MAX_OUTLINES].Outline.Enabled, false)
		for _, m in ipairs(models) do
			m:Destroy()
		end
	end)

	t.test("every PetAssets model has Root, PetId and Outline", function()
		local n = 0
		for _, m in ipairs(ReplicatedStorage.PetAssets:GetChildren()) do
			expect.truthy(m.PrimaryPart and m.PrimaryPart.Name == "Root")
			expect.truthy(m:GetAttribute("PetId"))
			expect.truthy(m:FindFirstChild("Outline"))
			n += 1
		end
		expect.equal(n, 60)
	end)
end
