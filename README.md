# RuntimeScriptDebug

运行时脚本调试工具

——***以创作者为本，让RM没有难做的演出***

<br/>

适用于RMMZ、RMMV、RMVA、RMVX、RMXP

QQ群：***792888538***   欢迎反馈遇到的问题和希望支持的功能

<br/>

VA/VX/XP 视频教程(必看)：https://www.bilibili.com/video/BV14ELRzXEmb/

<br/>

VA/VX/XP Project1：https://rpg.blue/thread-497298-1-1.html

<br/>

MZ/MV 视频教程(必看)：https://www.bilibili.com/video/BV186LAz2EWX/

<br/>

MZ/MV Project1：https://rpg.blue/forum.php?mod=viewthread&tid=497271&fromuid=2681370

<br/>

> [!IMPORTANT] 
> 注意：本工具完全用于开发调试，开发完成后进入部署阶段时，请将插件关闭避免影响到游戏流程

## VA/VX/XP外接控制台：

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic1_2.png?raw=true '调试界面')

<br/>

1. 支持运行时函数源码查看和修改，在控制台输入函数，可以打开函数源码编辑面板，修改后可以应用到运行时的游戏内<br/>
    控制台指令输入格式案例如下：
    
	<br/>

    通过Class类名获取类函数：   TestClass.method(:test_func)<br/>
    通过Class类名获取成员函数：Scene_Base.instance_method(:update)<br/>
    通过Class实例获取成员函数：$instance.method(:update)<br/>
    通过Module名获取类函数：   DataManager.method(:init)<br/>
    获取全局函数：             		 $console.method(:test_func)

<br/>

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic2_2.png?raw=true '编辑界面-函数')

<br/>

2. 支持运行时变量的查看和修改，在控制台输入变量，得到游戏响应后，可以打开变量编辑面板，修改后可以应用到运行时的游戏内<br/>
    控制台指令输入格式案例如下：
   
   <br/>
   
    ★ 注意：当前并不支持整体修改object，显示的信息仅供读取，请自行写ruby代码来修改object    <br/>
    查看：$game_temp
    
    <br/>
    
    ★ 注意：以下这种基础类型支持直接修改，但仍要在类里先定义 attr_accessor 将之暴露出来<br/>
    查看：$game_party.gold<br/>
    修改：$game_party.gold = 100<br/>
    查看：DataManager.last_savefile_index<br/>
    修改：DataManager.last_savefile_index = 1

<br/>

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic3_2.png?raw=true '编辑界面-变量')

<br/>

3. 如果想要完全新加js脚本，在调试界面输入***new*** ，即可打开一个全新的编辑界面，可以在此加入全新的rbuy脚本并应用

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic4_2.png?raw=true '编辑界面-new')

<br/>

 ★ 控制台配置说明：<br/>
 1. 请将插件 RMConsolePlugin.rb 中的内容全部复制添加到RM编辑器的插件管理器中并保存工程<br/>
 2. 请将 RMConsole.exe 控制台程序放到RM工程目录下，与游戏启动exe并列<br/>
 3. 有时命令行窗口没刷新不显示UI或不显示新消息，可以选中它按回车来让他刷新
 4. RM插件读取文件路径时无法识别中文和一些特殊符号，可能因此而报错；如果可能的话，请保持工程目录为全英文。
 
<br/>

> [!IMPORTANT] 
>  注意：插件需和RGSS外接控制台配合使用！<br/>
> 注意：控制台不支持多开，不要同时打开多个，每个控制台只能控制他所在工程的游戏进程！<br/>
> 注意：控制台生命周期应与游戏相同，两者启动先后顺序无所谓。但当重启游戏时，控制台也要重启！<br/>
> 注意：RGSS内部无法开多线程，因此外接控制台输入指令后，需要切到游戏窗口才会对指令做出响应<br/>
          之后再次切回控制台，即可根据游戏的响应打开对应编辑窗口再应用回游戏<br/>
> 注意：控制台内的修改完全是运行时的，不会影响RM工程，因此调试时的修改如要保留，请自行添加到插件管理器中<br/>
> 注意：XP版本没有Scene_Base，因此写在Window_Base，即需要至少有一个窗口创建过才可以正常响应！

<br/>
<br/>

## MZ/MV插件功能：

1. 支持运行时在任意时间打开脚本调试界面，快捷键F11

![调试界面](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic1.png?raw=true '调试界面')

<br/>

2. 在调试界面下，可以输入想要调试的变量或函数，如果输入合理，之后会在控制台输出该变量或函数的信息，与此同时打开编辑面板支持编辑
   * 变量例如：$gameMap、DataManager._databaseFiles
   * 函数例如：DataManager.loadDataFile、Scene_Base.prototype.update
   
![编辑界面-函数](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic2.png?raw=true '编辑界面-函数')
![编辑界面-变量](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic3.png?raw=true '编辑界面-变量')

<br/>

3. 如果想要完全新加js脚本，在调试界面输入***new*** ，即可打开一个全新的编辑界面，可以在此加入全新的内容

![编辑界面-new](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic4.png?raw=true '编辑界面-new')

<br/>