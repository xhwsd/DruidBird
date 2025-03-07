# 鸟德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- [可选][[文档](https://github.com/pepopo978/Cursive/)][[下载](https://github.com/pepopo978/Cursive/archive/master.zip)]安装`Cursive`插件，安装后将区分减益是否是自己施放
    - [依赖][[文档](https://github.com/balakethelock/SuperWoW/)][[下载](https://github.com/balakethelock/SuperWoW/releases/download/Release/SuperWoW.release.1.3.zip)]安装`SuperWoW`模组，将使用`SuperWoWlauncher.exe`启动游戏
- [可选][[文档](https://github.com/xhwsd/SuperMacro/)][[下载](https://github.com/xhwsd/SuperMacro/archive/master.zip)]安装`SuperMacro`插件，安装后将获得更多宏位
- [[文档](https://github.com/xhwsd/DruidBird/)][[下载](https://github.com/xhwsd/DruidBird/archive/main.zip)]安装`DruidBird`插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 确保插件最新版本、已适配乌龟服、目录名正确（如删除末尾`-main`、`-master`等）


## 可用宏


### 日食

> 根据自身增益输出法术，关于鸟德知识推荐参考[1.17.2 咕咕PVE不完全指北](https://luntan.turtle-wow.org/viewtopic.php?t=1241)

```
/script -- CastSpellByName("愤怒")
/script DruidBird:Eclipse()
```

参数列表：
- `@param kill? number` 斩杀阶段生命值百分比；缺省为`10`
- `@param ... string` 欲在日蚀或月蚀使用的物品名称；包中物品仅可以使用消耗品

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
/script DruidBird:Entangle()
```

### 减伤

> 给目标上持续伤害法术，用于磨死BOSS等场景

```
/script -- CastSpellByName("月火术")
/script DruidBird:Dot()
```

参数列表：
-  `@param spell? string` 各减益存在时使用的法术；缺省为`愤怒`
-  `@param ... string` 减益名称；缺省为`虫群`和`月火术`
-  `@return string spell` 施放的法术名称


## 简单宏
- `/ndfz tsms` - 调试模式：开启或关闭调试模式
- `/ndfz tsdj [等级]` - 调试等级：设置或获取调试等级，等级取值范围`1~3`


## 参考天赋
![参考天赋](/Talent.png)