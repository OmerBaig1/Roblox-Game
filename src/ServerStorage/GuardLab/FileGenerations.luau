-- Studio-only build step: files every finished guard generation lying in the workspace into GuardLab.Raw (named by
-- level, matched on a word from its prompt) and rigs it into ServerStorage.GuardModels with GuardRigKit.
return function()
	local lab = game:GetService("ServerStorage").GuardLab
	local keys = game:GetService("HttpService"):JSONDecode(lab:GetAttribute("Keys"))
	local K = require(lab.GuardRigKit:Clone())
	local out = {}
	for _, d in ipairs(workspace:GetChildren()) do
		if d:IsA("Model") and d.Name ~= "StealAGameMap" then
			local key
			for _, pair in ipairs(keys) do
				if d.Name:lower():find(pair[1]:lower(), 1, true) then
					key = pair[2]
					break
				end
			end
			if key then
				local old = lab.Raw:FindFirstChild(key)
				if old then
					old:Destroy()
				end
				d.Name = key
				d.Parent = lab.Raw
				local ok, err = pcall(K.rig, d, key)
				table.insert(out, key .. (ok and " rigged" or (" RIG FAILED: " .. tostring(err))))
			else
				table.insert(out, "unmatched: " .. d.Name:sub(1, 60))
			end
		end
	end
	return table.concat(out, "\n")
end
