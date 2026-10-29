-- Tests for Guards.ROSTER: one guard per vault level, every guard its own character (no shared name, key or laugh),
-- every guard has a rigged body with all six joints, and every guard has its own motion and running sound in GuardKit.
return function(t)
	local SSS = game:GetService("ServerScriptService")
	local C = require(SSS.StealAGame.Config)
	local Guards = require(SSS.StealAGame.Guards)
	local K = require(game:GetService("ReplicatedStorage").GuardKit)
	local models = game:GetService("ServerStorage"):FindFirstChild("GuardModels")
	local expect = t.expect

	t.test("one guard for every level", function()
		expect.equal(#Guards.ROSTER, C.NUM_LEVELS)
	end)

	t.test("nothing is shared between guards", function()
		for _, field in ipairs({"Name", "Key"}) do
			local seen = {}
			for level, g in ipairs(Guards.ROSTER) do
				local v = g[field]
				expect.truthy(v)
				if seen[v] then
					error(field .. " '" .. v .. "' used by levels " .. seen[v] .. " and " .. level)
				end
				seen[v] = level
			end
		end
		local laughs = {}
		for level, g in ipairs(Guards.ROSTER) do
			expect.falsy(laughs[g.Laugh.Id])
			laughs[g.Laugh.Id] = level
		end
	end)

	t.test("every guard has a rigged body", function()
		expect.truthy(models)
		for level = 1, C.NUM_LEVELS do
			local m = models:FindFirstChild(string.format("L%02d", level))
			if not m then
				error("no body for level " .. level)
			end
			expect.truthy(m.PrimaryPart and m:FindFirstChildOfClass("Humanoid"))
			local joints = {}
			for _, j in ipairs(m:GetDescendants()) do
				if j:IsA("Motor6D") then
					joints[j.Name] = true
				end
			end
			for _, name in ipairs({"Root", "Neck", "LeftShoulder", "RightShoulder", "LeftHip", "RightHip"}) do
				if not joints[name] then
					error("level " .. level .. " is missing its " .. name .. " joint")
				end
			end
		end
	end)

	t.test("every guard has its own motion and running sound", function()
		local signatures = {}
		for level, g in ipairs(Guards.ROSTER) do
			local m, au = K.MOTION[g.Key], K.AUDIO[g.Key]
			if not m or not au then
				error("no motion or sound for " .. g.Key)
			end
			for _, fn in ipairs({"Gait", "Idle", "Grab", "Laugh"}) do
				expect.equal(type(m[fn]), "function")
			end
			-- the ones that glide or float have a loop; everyone else has footfalls
			if g.Step == 0 then
				expect.truthy(au.Loop)
			else
				expect.truthy(au.Steps)
			end
			local sig = au.Loop and ("loop:" .. au.Loop[1] .. au.Loop[2])
				or (au.Steps[1] .. au.Steps[2] .. au.Pitch .. (au.Layer and au.Layer[1] .. au.Layer[2] or ""))
			if signatures[sig] then
				error(g.Key .. " sounds exactly like level " .. signatures[sig])
			end
			signatures[sig] = level
			for _, name in ipairs({au.Steps and au.Steps[1], au.Steps and au.Steps[2], au.Layer and au.Layer[1], au.Loop and au.Loop[1]}) do
				if name and not K.SOUNDS[name] then
					error(g.Key .. " uses unknown sound " .. name)
				end
			end
		end
	end)
end
