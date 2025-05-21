if not DruidBird then
	return
end

-- 定义辅助对象
local Helper = {}

---@type Wsd-Buff-1.0
local Buff = AceLibrary("Wsd-Buff-1.0")

-- 检验饰品是否可用
---@param slot number 装备栏位；`13`为饰品1，`14`为饰品2
---@return boolean used 可否使用
function Helper:CanJewelry(slot)
	local start, _, enable = GetInventoryItemCooldown("player", slot)
	return start == 0 and enable == 1
end

-- 检验单位能否施加减益
---@param debuff string 减益名称
---@param unit? string 目标单位；缺省为`target`
---@return boolean can 可否施法
function Helper:CanDebuff(debuff, unit)
	unit = unit or "target"

	if Cursive then
		-- 有Cursive插件
		-- 返回值`guid`来源`SuperWoW`模组
		local _, guid = UnitExists(unit)
		return Cursive.curses:HasCurse(debuff, guid) ~= true
	else
		-- 仅在确定没debuff时，可施放
		return not Buff:FindUnit(debuff, unit)
	end
end

-- 将辅助注入到插件中
DruidBird.helper = Helper