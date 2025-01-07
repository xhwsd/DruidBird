# 鸟德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- [可选]安装[Cursive](https://ghgo.xyz/https://github.com/pepopo978/Cursive/archive/master.zip)插件，安装后将区分减益是否是自己施放
    - [依赖]安装[SuperWoW](https://ghgo.xyz/https://github.com/balakethelock/SuperWoW/releases/download/Release/SuperWoW.release.1.3.zip)模组，将使用`SuperWoWlauncher.exe`启动游戏
- [可选]安装[SuperMacro](https://ghgo.xyz/https://github.com/xhwsd/SuperMacro/archive/master.zip)插件，安装后将获得更多宏位
- 安装[DaruidBird](https://ghgo.xyz/https://github.com/xhwsd/DaruidBird/archive/master.zip)插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 确保插件最新版本、已适配乌龟服、目录名正确（如删除末尾`-main`、`-master`等）


## 可用宏


### 日食

> 根据自身增益输出法术，关于鸟德知识推荐参考[1.17.2 咕咕PVE不完全指北](https://luntan.turtle-wow.org/viewtopic.php?t=1241)

```
/script -- CastSpellByName("愤怒")
/script DaruidBird:Eclipse()
```

参数列表：
- `@param kill? number` 斩杀阶段生命值百分比；缺省为`10`
- `@param ... string` 欲在日蚀或月蚀使用的物品名称

逻辑描述：
- 斩杀目标
- 有日蚀打愤怒
- 日蚀结束等待月蚀15秒，打愤怒
- 月蚀状态打星火术
- 月蚀结束等待日蚀15秒，打星火术
- 补虫群
- 补月火术
- 其他打愤怒

> 日蚀或月蚀失去后会继续保持15秒，直到获得对应效果或超时退出等待  


### 纠缠

> 立即打断施法，对目标施放纠缠根须

```
/script -- CastSpellByName("纠缠根须")
/script DaruidBird:Entangle()
```

### 减伤

> 给目标上持续伤害法术，用于磨死BOSS等场景

```
/script -- CastSpellByName("月火术")
/script DaruidBird:Dot()
```

### 减益

> 切换到战斗中的无减益目标，上减益

```
/script -- CastSpellByName("虫群")
/script DaruidBird:Debuffs()
```

参数列表：
- `@param limit? integer` 最多尝试切换目标次数；缺省为`30`
- `@param ... string` 减益名称；缺省为`虫群`和`月火术`
- `@return string debuff` 施放的减益名称


## 简单宏
- `/ndfz tsms` - 调试模式：开启或关闭调试模式
- `/ndfz tsdj [等级]` - 调试等级：设置或获取调试等级，等级取值范围`1~3`
