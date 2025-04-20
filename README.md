# RuntimeScriptDebug

运行时脚本调试插件

——***以创作者为本，让RM没有难做的演出***

<br/>

适用于RMMZ、RMMV

QQ群：***792888538***   欢迎反馈遇到的问题和希望支持的功能

<br/>

MZ/MV 视频教程(必看)：https://www.bilibili.com/video/BV186LAz2EWX/

<br/>

MZ/MV Project1：https://rpg.blue/forum.php?mod=viewthread&tid=497271&fromuid=2681370

<br/>

## 插件功能：

1. 支持运行时在任意时间打开脚本调试界面，快捷键F11

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic1.png?raw=true '调试界面')

<br/>

2. 在调试界面下，可以输入想要调试的变量或函数，如果输入合理，之后会在控制台输出该变量或函数的信息，与此同时打开编辑面板支持编辑
   * 变量例如：$gameMap、DataManager._databaseFiles
   * 函数例如：DataManager.loadDataFile、Scene_Base.prototype.update
   
![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic2.png?raw=true '编辑界面-函数')
![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic3.png?raw=true '编辑界面-变量')

<br/>

3. 如果想要完全新加js脚本，在调试界面输入***new*** ，即可打开一个全新的编辑界面，可以在此加入全新的内容

![断点](https://github.com/cafel176/RuntimeScriptDebug/blob/main/pic4.png?raw=true '编辑界面-new')

<br/>

> [!IMPORTANT] 
> 注意：本插件完全用于开发调试，开发完成后进入部署阶段时，请将本插件关闭避免影响到游戏流程
