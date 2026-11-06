--[[
	GameArt: the game's own drawn images (art/ui_art.py in the project folder), in one place, so the Shop, the gifts and the
	reward reveals all show the same picture of the same thing.
]]
local function id(n)
	return "rbxassetid://" .. n
end
local Art = {
	Starter = id(132469528350677), Money2 = id(94338274258521), Speed2 = id(98810325061016), Steal2 = id(93734116033725), Treadmill = id(120697822309767), Spin = id(116727093951796),
	SpeedS = id(80053541213183), SpeedM = id(103003411223800), SpeedL = id(117922721743964), SpeedXL = id(105969043771031), SpeedXXL = id(71362868350167),
	Cash5 = id(120964100993168), CashS = id(70462964176547), CashL = id(88722430842154), CashXL = id(119371175714915), CashXXL = id(138130633944708),
	Mystery = id(71703662705307), HudShop = id(116653349031037), HudIndex = id(76709464275335), HudFuse = id(93496904053742), HudPlus = id(93349033495929), HudTrail = id(72215911914200),
	TortoiseBody = id(103265432156831), TortoiseHead = id(106799663697102),
}
-- by Shop item key
Art.Shop = {
	Starter = Art.Starter, DoubleMoney = Art.Money2, DoubleSpeed = Art.Speed2, DoubleSteal = Art.Steal2, Treadmill = Art.Treadmill, Spin = Art.Spin,
	SpeedS = Art.SpeedS, SpeedM = Art.SpeedM, SpeedL = Art.SpeedL, SpeedXL = Art.SpeedXL, SpeedXXL = Art.SpeedXXL,
	Cash5 = Art.Cash5, CashS = Art.CashS, CashL = Art.CashL, CashXL = Art.CashXL, CashXXL = Art.CashXXL,
}
-- the server names a reward's picture with an emoji; these are the drawings that replace them
local BY_ICON = {
	["\u{1F45F}"] = Art.SpeedM, ["\u{1F680}"] = Art.SpeedL, ["\u{26A1}"] = Art.SpeedL, ["\u{1F4B0}"] = Art.CashS, ["\u{1F4B5}"] = Art.Cash5, ["\u{1F911}"] = Art.Money2,
	["\u{2753}"] = Art.Mystery, ["\u{1F3AE}"] = Art.Mystery, ["\u{1F451}"] = Art.Mystery, ["\u{1F381}"] = Art.Starter,
}
local BY_KIND = {cash = Art.CashS, speed = Art.SpeedM, boost = Art.SpeedL, game = Art.Mystery, pack = Art.Starter, spin = Art.Spin, area = Art.CashXL, index = Art.HudIndex, daily = Art.CashS}
function Art.forReward(o)
	return o.Image or BY_ICON[o.Icon] or BY_KIND[o.Kind]
end
function Art.forIcon(icon)
	return BY_ICON[icon]
end
return Art
