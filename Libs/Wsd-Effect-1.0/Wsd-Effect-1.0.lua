--[[
Name: Wsd-Effect-1.0
Revision: $Rev: 10001 $
Author(s): xhwsd
Website: https://github.com/xhwsd
Description: 效果相关操作库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Effect-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10004 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 效果相关操作库。
---@class Wsd-Effect-1.0
local Library = {}

-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)

end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

--------------------------------

-- 效果提示
-- GameTooltip方法 https://warcraft.wiki.gg/wiki/Special:PrefixIndex/API_GameTooltip
-- GameTooltip模板 https://warcraft.wiki.gg/wiki/XML/GameTooltip
local EffectTooltip = CreateFrame("GameTooltip", "EffectTooltip", nil, "GameTooltipTemplate")

-- 查找单位效果名称
---@param name string 效果名称
---@param unit? string 目标单位；额外还支持`mainhand`、`offhand`；缺省为`player`
---@return string kind 效果类型；可选值：`mainhand`、`offhand`、`buff`、`debuff`
---@return integer index 效果索引；从1开始
---@return string text 效果文本
function Library:FindName(name, unit)
	unit = unit or "player"

	if not name then
		return
	end

	EffectTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	-- 适配单位
	if string.lower(unit) == "mainhand" then
		-- 主手
		EffectTooltip:ClearLines()
		EffectTooltip:SetInventoryItem("player", GetInventorySlotInfo("MainHandSlot"));
		for index = 1, EffectTooltip:NumLines() do
			local text = getglobal("EffectTooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "mainhand", index, text
			end
		end
	elseif string.lower(unit) == "offhand" then
		-- 副手
		EffectTooltip:ClearLines()
		EffectTooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
		for index = 1, EffectTooltip:NumLines() do
			local text = getglobal("EffectTooltipTextLeft" .. index):GetText() or ""
			if string.find(text, name) then
				return "offhand", index, text
			end
		end
	else
		-- 增益
		local index = 1
		while UnitBuff(unit, index) do
			EffectTooltip:ClearLines()
			EffectTooltip:SetUnitBuff(unit, index)
			local text = EffectTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				return "buff", index, text
			end
			index = index + 1
		end

		-- 减益
		index = 1
		while UnitDebuff(unit, index) do
			EffectTooltip:ClearLines()
			EffectTooltip:SetUnitDebuff(unit, index)
			local text = EffectTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				return "debuff", index, text
			end
			index = index + 1
		end
	end
end

-- 取自身效果信息
---@param name string 效果名称
---@return integer index 效果索引；从1开始
---@return string text 效果文本
---@return integer timeleft 效果剩余时间
---@return string texture 效果图标
function Library:GetInfo(name)
	EffectTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	for id = 0, 64 do
		-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuff?oldid=3951140
		local index = GetPlayerBuff(id)
		if index >= 0 then
			EffectTooltip:ClearLines()
			-- https://warcraft.wiki.gg/wiki/API_GameTooltip_SetPlayerBuff?oldid=323371
			EffectTooltip:SetPlayerBuff(index)
			local text = EffectTooltipTextLeft1:GetText() or ""
			if string.find(text, name) then
				-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuffTimeLeft?oldid=2250730
				local timeleft = GetPlayerBuffTimeLeft(index)
				-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuffTexture?oldid=4896681
				local texture = GetPlayerBuffTexture(index)
				return index, text, timeleft, texture
			end
		end
	end

	-- buffId 从0开始
	-- buffIndex 从1开始
	-- https://warcraft.wiki.gg/wiki/BuffId?oldid=1793622
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil