-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DaruidBird = AceLibrary("AceAddon-2.0"):new(
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

-- 插件载入
function DaruidBird:OnInitialize()
	-- 精简标题
	self.title = "鸟德辅助"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)
end

-- 插件打开
function DaruidBird:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 注册命令
	self:RegisterChatCommand({'/NDFZ', "/DaruidBird"}, {
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

-- 插件关闭
function DaruidBird:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

-- 获得增益效果
function DaruidBird:SpecialEvents_UnitBuffGained(unit, buff)
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
	if self:IsEventScheduled("DaruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DaruidBird_WaitTimeout")
	end

	self:LevelDebug(3, "获得增益；效果：%s", buff)
end

-- 失去增益效果
function DaruidBird:SpecialEvents_UnitBuffLost(unit, buff)
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
	if self:IsEventScheduled("DaruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DaruidBird_WaitTimeout")
	end

	-- 延迟触发事件
	self:ScheduleEvent("DaruidBird_WaitTimeout", self.DaruidBird_WaitTimeout, eclipse.waits[buff], self)

	self:LevelDebug(3, "失去增益；效果：%s；等待：%d", buff, eclipse.waits[buff])
end

-- 等待超时
function DaruidBird:DaruidBird_WaitTimeout()
	self:LevelDebug(3, "等待超时；状态：%s", eclipse.state)

	-- 无状态
	eclipse.state = ""
	-- 无等待
	eclipse.waiting = 0
end

-- 可否减益
-- @param string debuff 减益名称
-- @param string unit = "target" 目标单位
-- @return boolean 可否施法减益
function DaruidBird:CanDebuff(debuff, unit)
	unit = unit or "target"

	-- 无减益
	if not UnitHasAura(unit, debuff) then
		-- 可以施法
		return true
	end

	-- 偷懒摆烂；需确保插件适配乌龟服，如：debuff位数、debuff持续时间等
	local lib
	if ShaguPlates then
		-- 依赖 ShaguPlates 插件
		lib = ShaguPlates.api.libdebuff
	elseif ShaguTweaks then
		-- 依赖 ShaguTweaks 插件
		lib = ShaguTweaks.libdebuff
	elseif ShaguTweaks then
		-- 依赖 ShaguTweaks 插件
		lib = ShaguTweaks.libdebuff
	elseif pfUI then
		-- 依赖 pfUI 插件
		lib = pfUI.api.libdebuff
	else
		-- 无法判断，不可施法
		return false
	end
	
	-- 遍历减益
	for index = 1, 64 do
		-- 匹配减益
		-- 效果名称, 法术等级, 图标纹理, 效果层数, 减益类型, 持续时间, 结束时间
		if lib:UnitDebuff(unit, index) == debuff then
			-- 不可施法
			return false
		end
	end

	-- 可以施法
	return true
end

-- 取状态
-- @return string 为空字符串表示无状态
function DaruidBird:GetState()
	return eclipse.state
end

-- 取等待
-- @return number 为0表示无等待
function DaruidBird:GetWaiting()
	return eclipse.waiting
end

-- 日食；根据自身增益输出法术
-- @param number kill = 10 斩杀阶段生命值百分比
function DaruidBird:Eclipse(kill)
	kill = kill or 10

	-- 抉择法术
	local health = math.floor(UnitHealth("target") / UnitHealthMax("target") * 100)
	if health <= kill then
		-- 斩杀阶段
		CastSpellByName("愤怒")
	elseif self:CanDebuff("虫群") then
		-- 虫群：降低命中2%、持续18秒自然伤害
		-- 虫群造成伤害后有30%几率获得万物平衡
		CastSpellByName("虫群")
	elseif self:CanDebuff("月火术") then
		-- 月火术：立即伤害、持续18秒奥术伤害
		-- 月火术造成伤害后有30%几率获得自然恩赐
		CastSpellByName("月火术")
	elseif self:GetState() == "日蚀" then
		-- 日蚀：增加25%自然伤害，持续15秒，冷却30秒
		-- 愤怒造成致命一击后有概率获得月蚀
		CastSpellByName("愤怒")
	elseif self:GetState() == "月蚀" then
		-- 月蚀：增加25%奥术伤害，持续15秒，冷却30秒
		-- 万物平衡：下一次星火术施法时间减少0.5秒，可累积3次
		-- 星火术造成致命一击后有概率获得日蚀
		CastSpellByName("星火术")
	else
		-- 自然恩赐：愤怒法力值消耗降低
		CastSpellByName("愤怒")
	end
end

-- 减伤：给目标上持续伤害法术，用于磨死BOSS等场景
function DaruidBird:Dot()
	if not TarDebuff("虫群") then
		-- 补虫群
		CastSpellByName("虫群")
	else
		-- 补月火，无限发
		CastSpellByName("月火术")
	end
end

-- 纠缠；中断施法，使用纠缠根须
function DaruidBird:Entangle()
	-- 中断非纠缠根须施法
	if castLib.isCasting and castLib.GetSpell() ~= "纠缠根须" then
		SpellStopCasting()
	end
	CastSpellByName("纠缠根须")
end

