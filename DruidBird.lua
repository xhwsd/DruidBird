-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DruidBird = AceLibrary("AceAddon-2.0"):new(
	-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0",
	-- 事件
	"AceEvent-2.0",
	-- 数据库
	"AceDB-2.0",
	-- 小地图菜单
	"FuBarPlugin-2.0"
)

-- 提示操作
local Tablet = AceLibrary("Tablet-2.0")
-- 光环事件
local AuraEvents = AceLibrary("SpecialEvents-Aura-2.0")
-- 施法库
local CastLib = AceLibrary("CastLib-1.0")

---@type Wsd-Effect-1.0
local Effect = AceLibrary("Wsd-Effect-1.0")
---@type Wsd-Health-1.0
local Health = AceLibrary("Wsd-Health-1.0")

-- 日食
local eclipse = {
	-- 当前状态
	state = "",
	-- 超时时间
	time = 0,
}

-- 可否减益
---@param name string 减益名称
---@param unit? string 目标单位；缺省为`target`
---@return boolean can 可否施法
local function CanDebuff(name, unit)
	unit = unit or "target"

	-- 无减益
	if not Effect:FindName(name, unit) then
		-- 可以施法
		return true
	end

	-- 方法`Cursive.curses:HasCurse`来源`Cursive`插件
	if Cursive and Cursive.curses then
		-- 返回值`guid`来源`SuperWoW`模组
		local _, guid = UnitExists(unit)
		return Cursive.curses:HasCurse(name, guid) ~= true
	else
		-- 无法判断，不可施法
		return false
	end
end

-- 可否饰品
---@param slot number 装备栏位；`13`为饰品1，`14`为饰品2
---@return boolean used 可否使用
local function CanJewelry(slot)
	-- 有日蚀时，使用饰品1
	local start, _, enable = GetInventoryItemCooldown("player", slot)
	return start == 0 and enable == 1
end

-- 插件初始化
function DruidBird:OnInitialize()
	-- 精简标题
	self.title = "鸟德"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)

	-- 注册数据
	self:RegisterDB("DruidBirdDB")
	-- 注册默认值
	self:RegisterDefaults('profile', {
		-- 时机
		timing = {
			-- 虫群
			-- 本身自然伤害，又能提供星火-0.5s的法时间，无论日蚀、月蚀都有收益，可以全程保持不断
			insectSwarm = {
				-- 有日蚀时
				solar = true,
				-- 日蚀等待时
				solarWait = true,
				-- 有月蚀时
				lunar = true,
				-- 月蚀等待时
				lunarWait = true,
				-- 常规时
				normal = true,
			},
			-- 月火术
			-- 本身奥术伤害，提供的愤怒-50%耗蓝对DPS没有提升，仅在月蚀或者无蚀状态下补
			moonfire = {
				-- 有日蚀时
				solar = false,
				-- 日蚀等待时
				solarWait = true,
				-- 有月蚀时
				lunar = true,
				-- 月蚀等待时
				lunarWait = true,
				-- 常规时
				normal = true,
			},
			-- 饰品1
			jewelry1 = {
				-- 有日蚀时
				solar = true,
				-- 有月蚀时
				lunar = true
			},
			-- 饰品2
			jewelry2 = {
				-- 有日蚀时
				solar = true,
				-- 有月蚀时
				lunar = true
			},
			-- 斩杀起始剩余
			kill = 10,
		},
		-- 等待
		wait = {
			-- 日蚀后等待秒数
			solar = 15,
			-- 月蚀后等待秒数
			lunar = 12
		},
	})

	-- 具体图标
	self.hasIcon = true
	-- 小地图图标
	self:SetIcon("Interface\\Icons\\Spell_Nature_ForceOfNature")
	-- 默认位置
	self.defaultPosition = "LEFT"
	-- 默认小地图位置
	self.defaultMinimapPosition = 210
	-- 无法分离提示（标签）
	self.cannotDetachTooltip = false
	-- 角色独立配置
	self.independentProfile = true
	-- 挂载时是否隐藏
	self.hideWithoutStandby = false
	-- 注册菜单项
	self.OnMenuRequest = {
		type = "group",
		handler = self,
		args = {
			timing = {
				type = "group",
				name = "时机",
				desc = "设置法术等触发时机",
				order = 1,
				args = {
					insectSwarm = {
						type = "group",
						name = "虫群",
						desc = "设置虫群施放时机",
						order = 1,
						args = {
							solar = {
								type = "toggle",
								name = "日蚀",
								desc = "有日蚀时",
								order = 1,
								get = function()
									return self.db.profile.timing.insectSwarm.solar
								end,
								set = function(value)
									self.db.profile.timing.insectSwarm.solar = value
								end
							},
							solarWait = {
								type = "toggle",
								name = "日蚀等待",
								desc = "日蚀结束等待时",
								order = 2,
								get = function()
									return self.db.profile.timing.insectSwarm.solarWait
								end,
								set = function(value)
									self.db.profile.timing.insectSwarm.solarWait = value
								end
							},
							lunar = {
								type = "toggle",
								name = "月蚀",
								desc = "有月蚀时",
								order = 3,
								get = function()
									return self.db.profile.timing.insectSwarm.lunar
								end,
								set = function(value)
									self.db.profile.timing.insectSwarm.lunar = value
								end
							},
							lunarWait = {
								type = "toggle",
								name = "月蚀等待",
								desc = "月蚀结束等待时",
								order = 4,
								get = function()
									return self.db.profile.timing.insectSwarm.lunarWait
								end,
								set = function(value)
									self.db.profile.timing.insectSwarm.lunarWait = value
								end
							},
							normal = {
								type = "toggle",
								name = "常规",
								desc = "无日蚀或月蚀且未等待时",
								order = 5,
								get = function()
									return self.db.profile.timing.insectSwarm.solarWait
								end,
								set = function(value)
									self.db.profile.timing.insectSwarm.solarWait = value
								end
							},
						}
					},
					moonfire = {
						type = "group",
						name = "月火术",
						desc = "设置月火术施放时机",
						order = 2,
						args = {
							solar = {
								type = "toggle",
								name = "日蚀",
								desc = "有日蚀时",
								order = 1,
								get = function()
									return self.db.profile.timing.moonfire.solar
								end,
								set = function(value)
									self.db.profile.timing.moonfire.solar = value
								end
							},
							solarWait = {
								type = "toggle",
								name = "日蚀等待",
								desc = "日蚀结束等待时",
								order = 2,
								get = function()
									return self.db.profile.timing.moonfire.solarWait
								end,
								set = function(value)
									self.db.profile.timing.moonfire.solarWait = value
								end
							},
							lunar = {
								type = "toggle",
								name = "月蚀",
								desc = "有月蚀时",
								order = 3,
								get = function()
									return self.db.profile.timing.moonfire.lunar
								end,
								set = function(value)
									self.db.profile.timing.moonfire.lunar = value
								end
							},
							lunarWait = {
								type = "toggle",
								name = "月蚀等待",
								desc = "月蚀结束等待时",
								order = 4,
								get = function()
									return self.db.profile.timing.moonfire.lunarWait
								end,
								set = function(value)
									self.db.profile.timing.moonfire.lunarWait = value
								end
							},
							normal = {
								type = "toggle",
								name = "常规",
								desc = "无日蚀或月蚀且未等待时",
								order = 5,
								get = function()
									return self.db.profile.timing.moonfire.normal
								end,
								set = function(value)
									self.db.profile.timing.moonfire.normal = value
								end
							},
						}
					},
					jewelry1 = {
						type = "group",
						name = "饰品1",
						desc = "设置饰品1施放时机",
						order = 3,
						args = {
							solar = {
								type = "toggle",
								name = "日蚀",
								desc = "有日蚀时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry1.solar
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.solar = value
								end
							},
							lunar = {
								type = "toggle",
								name = "月蚀",
								desc = "有月蚀时",
								order = 2,
								get = function()
									return self.db.profile.timing.jewelry1.lunar
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.lunar = value
								end
							},
						}
					},
					jewelry2 = {
						type = "group",
						name = "饰品2",
						desc = "设置饰品2施放时机",
						order = 4,
						args = {
							solar = {
								type = "toggle",
								name = "日蚀",
								desc = "有日蚀时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry2.solar
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.solar = value
								end
							},
							lunar = {
								type = "toggle",
								name = "月蚀",
								desc = "有月蚀时",
								order = 2,
								get = function()
									return self.db.profile.timing.jewelry2.lunar
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.lunar = value
								end
							},
						}
					},
					kill = {
						type = "range",
						name = "斩杀",
						desc = "目标生命小于或等于该百分比时",
						order = 5,
						min = 0,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.kill
						end,
						set = function(value)
							self.db.profile.timing.kill = value
						end
					},
				}
			},
			wait = {
				type = "group",
				name = "等待",
				desc = "设置日蚀和月蚀结束后等待秒数",
				order = 2,
				args = {
					solar = {
						type = "range",
						name = "日蚀",
						desc = "日蚀结束后等待秒数",
						order = 1,
						min = 0,
						max = 60,
						step = 1,
						get = function()
							return self.db.profile.wait.solar
						end,
						set = function(value)
							self.db.profile.wait.solar = value
						end
					},
					lunar = {
						type = "range",
						name = "月蚀",
						desc = "月蚀结束后等待秒数",
						order = 2,
						min = 0,
						max = 60,
						step = 1,
						get = function()
							return self.db.profile.wait.lunar
						end,
						set = function(value)
							self.db.profile.wait.lunar = value
						end
					},
				}
			},
			-- 其它
			other = {
				type = "header",
				name = "其它",
				order = 3,
			},
			debug = {
				type = "toggle",
				name = "调试模式",
				desc = "开启或关闭调试模式",
				order = 4,
				get = "IsDebugging",
				set = "SetDebugging"
			},
			level = {
				type = "range",
				name = "调试等级",
				desc = "设置或获取调试等级",
				order = 5,
				min = 1,
				max = 3,
				step = 1,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		}
	}
end

-- 插件启用
function DruidBird:OnEnable()
	self:LevelDebug(3, "插件启用")

	-- 注册事件
	self:RegisterEvent("SpecialEvents_UnitBuffGained")
	self:RegisterEvent("SpecialEvents_UnitBuffLost")
end

-- 插件禁用
function DruidBird:OnDisable()
	self:LevelDebug(3, "插件禁用")
end

-- 提示更新
function DruidBear:OnTooltipUpdate()
	-- 置小地图图标点燃提示
	Tablet:SetHint("\n右键 - 显示插件选项")
end

-- 获得增益效果
---@param unit string 事件单位
---@param buff string 增益名称
function DruidBird:SpecialEvents_UnitBuffGained(unit, buff)
	self:LevelDebug(3, "获得增益；效果：%s；单位：%s", buff, unit)

	-- 仅限自身
	-- 会重复收到该事件（如：团队中 raidN、安装 SuperWoW 为 GUID、player）
	if unit ~= "player" then
		return
	end

	-- 仅限日蚀和月蚀效果
	if buff ~= "日蚀" and buff ~= "月蚀" then
		return
	end

	-- 更新状态和时间
	eclipse.state = buff
	eclipse.time = 0

	-- 取消延迟事件
	if self:IsEventScheduled("DruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DruidBird_WaitTimeout")
	end
end

-- 失去增益效果
---@param unit string 事件单位
---@param buff string 增益名称
function DruidBird:SpecialEvents_UnitBuffLost(unit, buff)
	self:LevelDebug(3, "失去增益；效果：%s；单位：%s", buff, unit)

	-- 仅限自身
	-- 会重复收到该事件（如：团队中 raidN、安装 SuperWoW 为 GUID、player）
	if unit ~= "player" then
		return
	end

	-- 取等待秒数
	local wait = nil
	if buff == "日蚀" then
		wait = self.db.profile.wait.solar
	elseif buff == "月蚀" then
		wait = self.db.profile.wait.lunar
	else
		-- 仅限日蚀和月蚀效果
		return
	end

	-- 更新时间
	eclipse.time = GetTime() + wait

	-- 取消已有延迟事件
	if self:IsEventScheduled("DruidBird_WaitTimeout") then
		self:CancelScheduledEvent("DruidBird_WaitTimeout")
	end

	-- 延迟触发事件
	self:ScheduleEvent("DruidBird_WaitTimeout", self.DruidBird_WaitTimeout, wait, self)
end

-- 等待超时
function DruidBird:DruidBird_WaitTimeout()
	self:LevelDebug(3, "等待超时；状态：%s", eclipse.state)

	-- 重置状态和时间
	eclipse.state = ""
	eclipse.time = 0
end

-- 日食；根据自身增益输出法术
function DruidBird:Eclipse()
	-- 抉择法术
	local health = Health:GetRemaining("target")
	if health <= self.db.profile.timing.kill then
		-- 尽快斩杀
		if Effect:FindName("万物平衡") then
			-- 有万物平衡，打星火术（愤怒有弹道时间）
			CastSpellByName("星火术")
		else
			CastSpellByName("愤怒")
		end
	else
		-- 抉择施法
		if eclipse.state == "日蚀" then
			-- 有日蚀时，自然伤害提高
			if self.db.profile.timing.insectSwarm.solar and eclipse.time == 0 and CanDebuff("虫群") then
				-- 有日蚀时；施持续自然伤害
				CastSpellByName("虫群")
			elseif self.db.profile.timing.moonfire.solar and eclipse.time == 0 and CanDebuff("月火术") then
				-- 有日蚀时；愤怒法力消耗降低
				CastSpellByName("月火术")
			elseif self.db.profile.timing.jewelry1.solar and eclipse.time == 0 and CanJewelry(13) then
				-- 有日蚀时；使用饰品1
				UseInventoryItem(13)
			elseif self.db.profile.timing.jewelry2.solar and eclipse.time == 0 and CanJewelry(14) then
				-- 有日蚀时；使用饰品2
				UseInventoryItem(14)
			elseif self.db.profile.timing.insectSwarm.solarWait and eclipse.time and CanDebuff("虫群") then
				-- 日蚀等待时；持续自然伤害
				CastSpellByName("虫群")
			elseif self.db.profile.timing.moonfire.solarWait and eclipse.time and CanDebuff("月火术") then
				-- 日蚀等待时；愤怒法力消耗降低
				CastSpellByName("月火术")
			else
				-- 造成自然伤害，暴击获得月蚀
				CastSpellByName("愤怒")
			end
		elseif eclipse.state == "月蚀" then
			-- 有月蚀时，奥术伤害提高
			if self.db.profile.timing.moonfire.lunar and eclipse.time == 0 and CanDebuff("月火术") then
				-- 有月蚀时，持续奥术伤害
				CastSpellByName("月火术")
			elseif self.db.profile.timing.insectSwarm.lunar and eclipse.time == 0 and CanDebuff("虫群") then
				-- 有月蚀时，星火施法时间缩短
				CastSpellByName("虫群")
			elseif self.db.profile.timing.jewelry1.lunar and eclipse.time == 0 and CanJewelry(13) then
				-- 有月蚀时，使用饰品1
				UseInventoryItem(13)
			elseif self.db.profile.timing.jewelry2.lunar and eclipse.time == 0 and CanJewelry(14) then
				-- 有月蚀时，使用饰品2
				UseInventoryItem(14)
			elseif self.db.profile.timing.moonfire.lunarWait and eclipse.time and CanDebuff("月火术") then
				-- 月蚀等待时，持续奥术伤害
				CastSpellByName("月火术")
			elseif self.db.profile.timing.insectSwarm.lunarWait and eclipse.time and CanDebuff("虫群") then
				-- 月蚀等待时，星火施法时间缩短
				CastSpellByName("虫群")
			else
				-- 造成奥术伤害，暴击获得日蚀
				CastSpellByName("星火术")
			end
		elseif self.db.profile.timing.insectSwarm.normal and CanDebuff("虫群") then
			-- 补虫群
			CastSpellByName("虫群")
		elseif self.db.profile.timing.moonfire.normal and CanDebuff("月火术") then
			-- 补月火
			CastSpellByName("月火术")
		else
			CastSpellByName("愤怒")
		end
	end
end

-- 纠缠；中断施法，使用纠缠根须
function DruidBird:Entangle()
	-- 中断非纠缠根须施法
	if CastLib.isCasting and CastLib.GetSpell() ~= "纠缠根须" then
		SpellStopCasting()
	end
	CastSpellByName("纠缠根须")
end

-- 减伤：给目标上持续伤害法术，用于磨死BOSS等场景
---@param spell? string 各减益存在时使用的法术；缺省为`愤怒`
---@param ... string 减益名称；缺省为`虫群`和`月火术`
---@return string spell 施放的法术名称
function DruidBird:Dot(spell, ...)
	spell = spell or "愤怒"
	if arg.n <= 0 then
		arg = {"虫群", "月火术"}
	end

	for _, debuff in ipairs(arg) do
		if not Effect:FindName(debuff, "target") then
			CastSpellByName(debuff)
			return debuff
		end
	end

	CastSpellByName(spell)
	return spell
end

-- 减益：切换到战斗中的无减益目标，上减益
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
				if CanDebuff(value) then
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


-- 愤怒：造成自然伤害；造成致命一击后有概率获得月蚀
-- 星火术：施法时间3.5秒；造成奥术伤害；造成致命一击后有概率获得日蚀
-- 月火术：立即伤害、持续18秒奥术伤害；造成伤害后有30%几率获得自然恩赐
-- 虫群：降低命中2%、持续18秒自然伤害；造成伤害后有30%几率获得万物平衡
-- 日蚀：增加25%自然伤害，持续15秒，冷却30秒
-- 月蚀：增加25%奥术伤害，持续15秒，冷却30秒
-- 万物平衡：下一次星火术施法时间减少0.75秒，可累积3次
-- 自然恩赐：下一次愤怒法力值消耗降低50%，可累积3次
