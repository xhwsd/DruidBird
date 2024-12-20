# 鸟德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- 安装[ShaguPlates](https://ghgo.xyz/https://github.com/xhwsd/ShaguPlates/archive/master.zip)插件
- 可选的，安装[SuperMacro](https://ghgo.xyz/https://github.com/xhwsd/SuperMacro/archive/master.zip)插件
- 安装[DaruidBird](https://ghgo.xyz/https://github.com/xhwsd/DaruidBird/archive/master.zip)插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 请确保依赖插件最新版和已适配乌龟，插件目录名正确（如删除末尾`-main`等）


## 可用宏


### 日食

> 根据自身增益输出法术，关于鸟德知识推荐参考[1.17.2 咕咕PVE不完全指北](https://luntan.turtle-wow.org/viewtopic.php?t=1241)

```
/script -- CastSpellByName("愤怒")
/script DaruidBird:Eclipse(10)
```

参数列表：
- `@param number kill = 10` 斩杀阶段生命值百分比

逻辑描述：
- 斩杀目标
- 补虫群
- 补月火术
- 有日蚀打愤怒
- 有月蚀打星火术
- 其他打愤怒

> 日蚀或月蚀失去后会继续保持15秒，直到获得对应效果或超时退出等待  


### 减伤

> 给目标上持续伤害法术，用于磨死BOSS等场景

```
/script -- CastSpellByName("虫群")
/script DaruidBird:Dot()
```


### 纠缠

> 立即打断施法，对目标施放纠缠根须

```
/script -- CastSpellByName("纠缠根须")
/script DaruidBird:Entangle()
```


#### 节能

> 对附近进入战斗目标施法精灵之火（按下ALT释放最高级），以此触发节能效果

```
/script -- CastSpellByName("精灵之火")
/script DaruidBird:EnergySaving()
```


## 简单宏
- `/nd debug` - 开启或关闭调试模式，调试模式下会输出详细信息
- `/nd level [level]` 设置调试等级，`level`取值`1~3`；设置调试模式下输出等级
