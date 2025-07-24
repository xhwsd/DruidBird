if not DruidBird then
	return
end

-- 定义辅助对象
local Helper = {}

---@type KuBa-Buff-1.0
local Buff = AceLibrary("KuBa-Buff-1.0")

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

-- 取当前形态
---@return string|nil name 形态名称,为空表示无形态
function Helper:GetForm()
	-- 取当前形态
	for index = GetNumShapeshiftForms(), 1, -1 do
		local _, name, active = GetShapeshiftFormInfo(index)
		if active then
			return name
		end
	end
end

-- 切换到指定名称形态
---@param name? string|nil 形态名称；为空取消形态
---@return boolean success 成功返回真，否则返回假
function Helper:SwitchForm(name)
	if name then
		for index = GetNumShapeshiftForms(), 1, -1 do
			local _, current, active = GetShapeshiftFormInfo(index)
			if string.find(current, name) then
				if not active then
					CastShapeshiftForm(index)
				end
				return true
			end
		end
		return false
	else
		for index = GetNumShapeshiftForms(), 1, -1 do
			local _, _, active = GetShapeshiftFormInfo(index)
			if active then
				CastShapeshiftForm(index)
				return true
			end
		end
		return true
	end
end

-- 使用物品
---@param item string 物品名称，支持包或身的物品
---@return number bag 背包标识或装备槽
---@return number|nil slot 背包槽
function Helper:UseItem(item)
	-- 查找物品
	local bag, slot = FindItemInfo(item)
	if not bag then
		return
	end

	if slot then
		-- 包中物品
		UseContainerItem(bag, slot)
		return bag, slot
	else
		-- 身上物品
		UseInventoryItem(bag)
		return bag
	end
end

-- 将辅助注入到插件中
DruidBird.helper = Helper