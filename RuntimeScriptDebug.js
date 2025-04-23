// ============================================================================= //
// RuntimeScriptDebug.js
// ============================================================================= //
/*:
 * @plugindesc 当前版本 V1
 * 运行时脚本调试插件，适用于RMMZ和RMMV
 * @author cafel
 * @target MZ
 * @url https://github.com/cafel176/RuntimeScriptDebug
 * @help QQ群：792888538  
 * Project1：https://rpg.blue/forum.php?mod=viewthread&tid=497271&fromuid=2681370
 * 视频教程：https://www.bilibili.com/video/BV186LAz2EWX/
 * 
 * ★ 本插件提供如下支持：
 * 
 * 1. 支持运行时在任意时间打开脚本调试界面，快捷键F11
 * 
 * 2. 在调试界面下，可以输入想要调试的变量或函数，如果输入合理，之后会在控制台
 *    输出该变量或函数的信息，与此同时打开编辑面板支持编辑
 *    ♦ 变量例如：$gameMap、DataManager._databaseFiles
 *    ♦ 函数例如：DataManager.loadDataFile、Scene_Base.prototype.update
 * 
 * 3. 如果想要完全新加js脚本，在调试界面输入new，即可打开一个全新的编辑界面，
 *    可以在此加入全新的内容
 * 
 * ★ 注意：本插件完全用于开发调试，开发完成后进入部署阶段时，请将本插件
 *    关闭避免影响到游戏流程
 * 
 */

var RuntimeScriptDebug = RuntimeScriptDebug || {};
RuntimeScriptDebug.param = PluginManager.parameters('RuntimeScriptDebug');

// ============================================================================= //
// 插件参数
// ============================================================================= //



// ============================================================================= //
// 插件按键
// ============================================================================= //

// 调试
Input.keyMapper[122] = "script";

// ============================================================================= //
// 以下函数完全以使用它的环境为上下文
// ============================================================================= //

// 编辑面板的“确定”按钮
var scriptDialogSubmit = function (context) {
    // 获取文本框的内容
    let text = window.document.getElementById("text_area").value
    // 创建一个新的script并加入主窗口
    const script = context.document.createElement("script");
    script.type = "text/javascript";
    script.async = false;
    script.defer = true;
    script.textContent = text;
    context.document.body.appendChild(script);
    // 关闭当前窗口
    window.close()
}

// 编辑面板的“重置”按钮
var scriptDialogReset = function (context, text) {
    // 重置文本框的内容
    context.document.getElementById("text_area").value = text
}

// 编辑面板的“取消”按钮
var scriptDialogCancel = function () {
    // 关闭当前窗口
    window.close()
}

// ============================================================================= //
// 对所有的事件页进行处理，将其中的注释转化为对应的事件
// ============================================================================= //

// 输入一个已定义的变量或函数，将其内容文本化
var scriptDialogSetText = function (re) {
    var text = ""
    // null意味着完全新建
    if (re === null)
        return ""

    try {
        // 如果是函数
        if (eval("typeof " + re) === 'function') {
            text = re + " = " + eval(re)
        }
        // 如果是变量
        else {
            text = re + " = " + JSON.stringify(eval(re))
        }
    }
    catch (error) {
        alert(error)
        return ""
    }
    return text
}

// 显示编辑窗口
var scriptDialogShow = function (re) {
    let top = window.screenTop + 100
    let left = window.screenLeft + 100
    // 获取要编辑内容的文本
    let text = scriptDialogSetText(re === 'new' ? null : re)
    // 创建编辑窗口
    OpenWindow = window.open("", "scriptDialog", "height=500, width=800, top="+top+", left="+left+", resizable=yes, status=no, location=no, toolbar=no, scrollbars=no, menubar=no");
    OpenWindow.document.write("<html>")
    OpenWindow.document.write("<head>")
    OpenWindow.document.write("<style>")
    OpenWindow.document.write('.my_button { margin: 10; }')
    OpenWindow.document.write('#submit { background-color: #8ad119; }')
    OpenWindow.document.write('#reset { background-color: #f9636b; }')
    OpenWindow.document.write('#text_area { background-color: #3d3c3c; color:#ffffff; width: 100%; height: 75%; flex-grow: 1; display: flex; flex - direction: column; }')
    OpenWindow.document.write("</style>")
    OpenWindow.document.write('<meta charset = "UTF-8">');
    OpenWindow.document.write("<title>例子</title>")
    OpenWindow.document.write("</head>")
    OpenWindow.document.write("<body style='background-color:#414141;'>")
    try {
        OpenWindow.document.write('<script>var scriptDialogSetText=' + eval('scriptDialogSetText') + '</script>')
        OpenWindow.document.write('<script>var scriptDialogSubmit=' + eval('scriptDialogSubmit') + '</script>')
        OpenWindow.document.write('<script>var scriptDialogReset=' + eval('scriptDialogReset') + '</script>')
        OpenWindow.document.write('<script>var scriptDialogCancel=' + eval('scriptDialogCancel') + '</script>')
    } catch (error) {

    }
    OpenWindow.document.write('<font id="origin" color ="#ffffff"></font><br>')
    OpenWindow.document.write('<font color ="#8ad119"><b>确定</b></font><font color ="#ffffff">：将修改应用到游戏</font><br>')
    OpenWindow.document.write('<font color ="#f9636b"><b>重置</b></font><font color ="#ffffff">：将文本框重置为初始内容</font><br>')
    OpenWindow.document.write('<button id="submit" class="my_button" onclick="scriptDialogSubmit(window.mainWindow)"><font color="#000000"><b>确定</b></font></button>')
    OpenWindow.document.write('<button id="reset" class="my_button" onclick="scriptDialogReset(window, window.text)"><font color="#000000"><b>重置</b></font></button>')
    OpenWindow.document.write('<button id="cancel" class="my_button" onclick="scriptDialogCancel()"><font color="#000000"><b>取消</b></font></button>')
    OpenWindow.document.write('<br>')
    OpenWindow.document.write('<textarea id="text_area" autofocus></textarea>')
    OpenWindow.document.write("</body>")
    OpenWindow.document.write("</html>")
    OpenWindow.origin = re
    OpenWindow.text = text
    OpenWindow.mainWindow = window
    // 初始化输入的文本
    OpenWindow.document.getElementById("origin").innerHTML = "<b>输入</b>：" + re
    OpenWindow.focus()
    // 初始化编辑窗口的文本
    scriptDialogReset(OpenWindow, text)
}

// ============================================================================= //
// 调试窗口入口
// ============================================================================= //

// 某些变量禁止修改
const cantEditList = ['window']

// 任何时候都可以调试
var RuntimeScriptDebug_Scene_Base_update = Scene_Base.prototype.update;
Scene_Base.prototype.update = function () {
    RuntimeScriptDebug_Scene_Base_update.call(this);

    if (Input.isTriggered("script")) {
        try {
            var re = ''
            let check = false
            while (!check) {
                re = prompt("请输入想调试的变量或函数，输入new以完全新建脚本", "");
                if (re === '' || re === null)
                    return

                // 完全新建
                if (re === 'new') {
                    scriptDialogShow(re)
                    return
                }

                // 编辑已有

                // 判断是否是禁止编辑变量
                if (cantEditList.includes(re)) {
                    eval("console.log(" + re + ")")
                    alert("已在控制台显示" + re + "的信息，但是不能对" + re + "进行编辑！")
                    return
                }

                // 判断调试内容是否已定义
                if (eval("typeof " + re) === 'undefined') {
                    alert("未找到" + re + "的定义")
                }
                else {
                    check = true
                }
            }

            // 控制台输出
            eval("console.log(" + re + ")")
            // 打开编辑窗口
            scriptDialogShow(re)
        }
        catch (error) {
            alert(error)
        }
    }
};