-- `FindItemInfo`来源`!Libs\!MyLib\api\wowAPI.lua`
-- `GetItemInfoByName`来源`!Libs\!MyLib\api\wowAPI.lua`
-- `UnitHasAura`来源`!Libs\SE\SpecialEvents-Aura-2.0\SpecialEvents-Aura-2.0.lua`库

-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DruidBird = AceLibrary("AceAddon-2.0"):new(
	-- 调试
	"AceDebug-2.0",
	-- 事件
	"AceEvent-2.0",
	-- 控制台
	"AceConsole-2.0"
)

-- 光环事件
local auraEvents = AceLibrary("SpecialEvents-Aura-2.0")
-- 施法库
local castLib = AceLibrary("CastLib-1.0")

-- 日食
local eclipse = {
	-- 状态
	state = "",
	-- 等待
	waiting = 0,
	-- 等待
	waits = {
		["日蚀"] = 15,
		["月蚀"] = 15
	}
}

---插件载入
function DruidBird:OnInitialize()
	-- 精简标题
	self.title = "鸟德辅助"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)
end

---插件打开
function DruidBird:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 注册命令
	self:RegisterChatCommand({'/NDFZ', "/DruidBird"}, {
		type = "group",
		args = {
			tsms = {
				name = "调试模式",
				desc = "开启或关闭调试模式",
				type = "toggle",
				get = "IsDebugging",
				set = "SetDebugging"
			},
			tsdj = {
				name = "调试等级",
				desc = "设置或获取调试等级",
				type = "range",
				min = 1,
				max = 3,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		},
	})

	-- 注册事件
	self:RegisterEvent("SpecialEvents_UnitBuffGained")
	self:RegisterEvent("SpecialEvents_UnitBuffLost")
end

---插件关闭
function DruidBird:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

-- 获得增益效果
---@param unit string 事件单位
---@param buff string 增益名称
function DruidBird:SpecialEvents_UnitBuffGained(unit, buff)
	-- 仅限自身
	if not UnitIsUnit(unit, "player") then
		return
	end

	-- 仅限日蚀和月蚀效果
	if buff ~= "日蚀" and buff ~= "月蚀" then
		return
	end

	-- 当前状态
	eclipse.state = buff
	-- 无等待
	eclipse.waiting = 0

	-- 取消延迟事件
	if self:IsEventScheduled("DruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DruidBird_WaitTimeout")
	end

	self:LevelDebug(3, "获得增益；效果：%s", buff)
end

---失去增益效果
---@param unit string 事件单位
---@param buff string 增益名称
function DruidBird:SpecialEvents_UnitBuffLost(unit, buff)
	-- 仅限自身
	if not UnitIsUnit(unit, "player") then
		return
	end

	-- 仅限日蚀和月蚀效果
	if buff ~= "日蚀" and buff ~= "月蚀" then
		return
	end

	-- 等待时间
	eclipse.waiting = GetTime() +  eclipse.waits[buff]

	-- 取消已有延迟事件
	if self:IsEventScheduled("DruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DruidBird_WaitTimeout")
	end

	-- 延迟触发事件
	self:ScheduleEvent("DruidBird_WaitTimeout", self.DruidBird_WaitTimeout, eclipse.waits[buff], self)

	self:LevelDebug(3, "失去增益；效果：%s；等待：%d", buff, eclipse.waits[buff])
end

---等待超时
function DruidBird:DruidBird_WaitTimeout()
	self:LevelDebug(3, "等待超时；状态：%s", eclipse.state)

	-- 无状态
	eclipse.state = ""
	-- 无等待
	eclipse.waiting = 0
end

---使用物品
---@param item string 欲使用物品的名称；包中物品仅可以使用消耗品
---@param ... string 限定使用物品的增益名称
---@return boolean use 是否使用成功
function DruidBird:UseItem(item, ...)
	if not item then
		return false
	end

	-- 查找物品
	local bag, slot = FindItemInfo(item)
	if not bag then
		return false
	end

	-- 检验物品
	if slot then
		-- 检验包中物品冷却
		if GetContainerItemCooldown(bag, slot) > 0 then
			return false
		end

		-- 检验包中物品不可是装备或武器（如玩家换下的饰品在包中时）
		local _, _, _, _, type = GetItemInfoByName(item)
		if type ~= "消耗品" then
			return false
		end
	else
		-- 检验身上物品冷却
		if GetInventoryItemCooldown("player", bag) > 0 then
			return false
		end
	end

	-- 检测增益
	if arg.n > 0 then
		-- 匹配增益
		local buff = nil
		for _, value in ipairs(arg) do
			if UnitHasAura("player", value) then
				buff = value
				break
			end
		end

		-- 无任意匹配
		if not buff then
			return false
		end
	end

	-- 打断施法
	SpellStopCasting()

	-- 使用物品
	if slot then
		-- 使用包中的物品
		UseContainerItem(bag, slot)
	else
		-- 使用身上的物品
		UseInventoryItem(bag)
	end
	return true
end

---可否减益
---@param debuff string  减益名称
---@param unit? string 目标单位；缺省为`target`
---@return boolean can 可否施法
function DruidBird:CanDebuff(debuff, unit)
	unit = unit or "target"

	-- 无减益
	if not UnitHasAura(unit, debuff) then
		-- 可以施法
		return true
	end

	-- 方法`Cursive.curses:HasCurse`来源`Cursive`插件
	if Cursive and Cursive.curses then
		-- 返回值`guid`来源`SuperWoW`模组
		local _, guid = UnitExists(unit)
		return Cursive.curses:HasCurse(debuff, guid) ~= true
	else
		-- 无法判断，不可施法
		return false
	end
end

---取状态
---@return string state 为空字符串表示无状态
function DruidBird:GetState()
	return eclipse.state
end

---取等待
---@return number waiting 为`0`表示无等待
function DruidBird:GetWaiting()
	return eclipse.waiting
end

---日食；根据自身增益输出法术
---@param kill? number 斩杀阶段生命值百分比；缺省为`10`
---@param ... string 欲在日蚀或月蚀使用的物品名称；包中物品仅可以使用消耗品
function DruidBird:Eclipse(kill, ...)
	kill = kill or 10

	-- 抉择法术
	local health = math.floor(UnitHealth("target") / UnitHealthMax("target") * 100)
	if health <= kill then
		-- 尽快斩杀
		CastSpellByName("愤怒")
	else
		-- 使用物品
		for _, item in ipairs(arg) do
			if self:UseItem(item, "日蚀", "月蚀") then
				return
			end
		end

		-- 抉择施法
		if self:GetState() == "日蚀" then
			-- 自然伤害提高
			if self:CanDebuff("虫群") then
				-- 持续自然伤害
				CastSpellByName("虫群")
			elseif self:GetWaiting() > 0 and self:CanDebuff("月火术") then
				-- 无日蚀等待月蚀时，愤怒法力消耗降低
				CastSpellByName("月火术")
			else
				-- 造成自然伤害，暴击获得月蚀
				CastSpellByName("愤怒")
			end
		elseif self:GetState() == "月蚀" then
			-- 奥术伤害提高
			if self:CanDebuff("月火术") then
				-- 持续奥术伤害
				CastSpellByName("月火术")
			elseif self:CanDebuff("虫群") then
				-- 星火施法时间缩短
				CastSpellByName("虫群")
			else
				-- 造成奥术伤害，暴击获得日蚀
				CastSpellByName("星火术")
			end
		elseif self:CanDebuff("虫群") then
			-- 补虫群
			CastSpellByName("虫群")
		elseif self:CanDebuff("月火术") then
			-- 补月火
			CastSpellByName("月火术")
		else
			CastSpellByName("愤怒")
		end
	end

	-- 愤怒：造成自然伤害；造成致命一击后有概率获得月蚀
	-- 星火术：造成奥术伤害；造成致命一击后有概率获得日蚀
	-- 月火术：立即伤害、持续18秒奥术伤害；造成伤害后有30%几率获得自然恩赐
	-- 虫群：降低命中2%、持续18秒自然伤害；造成伤害后有30%几率获得万物平衡
	-- 日蚀：增加25%自然伤害，持续15秒，冷却30秒
	-- 月蚀：增加25%奥术伤害，持续15秒，冷却30秒
	-- 万物平衡：下一次星火术施法时间减少0.5秒，可累积3次
	-- 自然恩赐：下一次愤怒法力值消耗降低50%，可累积3次
end

---纠缠；中断施法，使用纠缠根须
function DruidBird:Entangle()
	-- 中断非纠缠根须施法
	if castLib.isCasting and castLib.GetSpell() ~= "纠缠根须" then
		SpellStopCasting()
	end
	CastSpellByName("纠缠根须")
end

---减伤：给目标上持续伤害法术，用于磨死BOSS等场景
---@param spell? string 各减益存在时使用的法术；缺省为`愤怒`
---@param ... string 减益名称；缺省为`虫群`和`月火术`
---@return string spell 施放的法术名称
function DruidBird:Dot(spell, ...)
	spell = spell or "愤怒"
	if arg.n <= 0 then
		arg = {"虫群", "月火术"}
	end

	for _, debuff in ipairs(arg) do
		if not UnitHasAura("target", debuff) then
			CastSpellByName(debuff)
			return debuff
		end
	end

	CastSpellByName(spell)
	return spell
end

---减益：切换到战斗中的无减益目标，上减益
---@param limit? integer 最多尝试切换目标次数；缺省为`30`
---@param ... string 减益名称；缺省为`虫群`和`月火术`
---@return string debuff 施放的减益名称
function DruidBird:Debuffs(limit, ...)
	limit = limit or 30
	if arg.n <= 0 then
		arg = {"虫群", "月火术"}
	end

	for index = 1, limit do
		-- 可攻击和战斗中的目标
		if UnitCanAttack("player", "target") and UnitAffectingCombat("target") then
			for _, value in ipairs(arg) do
				-- 可否施放减益
				if self:CanDebuff(value) then
					-- 施放减益
					CastSpellByName(value)
					return value
				end
			end
		end

		-- 切换目标
		TargetNearestEnemy()

		-- 切换后还是没目标
		if not UnitExists("target") then
			break
		end
	end
	UIErrorsFrame:AddMessage("无可减益目标", 1.0, 1.0, 0.0, 53, 5)
end
