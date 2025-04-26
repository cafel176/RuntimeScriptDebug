# ============================================================================= //
# RMConsolePlugin
# ============================================================================= //
# 
# 当前版本：V1
# RGSS控制台内接插件，适用于RMVA、RMVX和RMXP
# 作者： cafel
# QQ群：792888538  
# github地址：https://github.com/cafel176/RuntimeScriptDebug
# Project1：
# 视频教程：https://www.bilibili.com/video/BV14ELRzXEmb/
#
#
# ★ 控制台配置说明：
# 1. 请将插件 RMConsolePlugin.rb 中的内容全部复制添加到RM编辑器的插件管理器中并保存工程
# 2. 请将 RMConsole.exe 控制台程序放到RM工程目录下，与游戏启动exe并列
# 3. 有时命令行窗口没刷新不显示UI或不显示新消息，可以选中它按回车来让他刷新
#
#
# ★ 注意：插件需和RGSS外接控制台配合使用！
# ★ 注意：控制台不支持多开，不要同时打开多个，每个控制台只能控制他所在工程的游戏进程！
# ★ 注意：控制台生命周期应与游戏相同，两者启动先后顺序无所谓。但当重启游戏时，控制台也要重启！
# ★ 注意：RGSS内部无法开多线程，因此外接控制台输入指令后，需要切到游戏窗口才会对指令做出响应
#          之后再次切回控制台，即可根据游戏的响应打开对应编辑窗口再应用回游戏
# ★ 注意：控制台内的修改完全是运行时的，不会影响RM工程，因此调试时的修改如要保留，请自行添加到插件管理器中
# ★ 注意：XP版本没有Scene_Base，因此写在Window_Base，即需要至少有一个窗口创建过才可以正常响应！
#
#
# ★ 控制台提供如下功能：
# 
# 1. 支持运行时函数源码查看和修改，在控制台输入函数，可以打开函数源码编辑面板，修改后可以应用到运行时的游戏内
#    控制台指令输入格式案例如下：
#
#    通过Class类名获取类函数：  TestClass.method(:test_func)
#    通过Class类名获取成员函数：Scene_Base.instance_method(:update)
#    通过Class实例获取成员函数：$instance.method(:update)
#    通过Module名获取类函数：   DataManager.method(:init)
#    获取全局函数：             $console.method(:test_func)
# 
# 2. 支持运行时变量的查看和修改，在控制台输入变量，得到游戏响应后，可以打开变量编辑面板，修改后可以应用到运行时的游戏内
#    控制台指令输入格式案例如下：
#
#    ★ 注意：当前并不支持整体修改object，显示的信息仅供读取，请自行写ruby代码来修改object
#    查看：$game_temp
#    
#    ★ 注意：以下这种基础类型支持直接修改，但仍要在类里先定义attr_accessor将之暴露出来
#    查看：$game_party.gold
#    修改：$game_party.gold = 100
#    查看：DataManager.last_savefile_index
#    修改：DataManager.last_savefile_index = 1
# 
# 3. 如果想要完全新加脚本，在调试界面输入new，即可打开一个全新的编辑界面，可以在此加入全新的rbuy脚本并应用
#
#
# ★ 注意：本插件完全用于开发调试，开发完成后进入部署阶段时，请将$debug_active关闭避免影响到游戏流程
#

# ============================================================================= //
# 插件配置
# ============================================================================= //

# 控制插件是否生效
$debug_active = true
# 测试用，会定义一些测试用的类型
$debug_test = true

#版本
$debug_version = "v1"
#传输信息用文件所在目录
$debug_file_dir = "/console/"

# ============================================================================= //
# 全局变量
# ============================================================================= //

#输出的消息
$debug_token_puts = "puts"
#输出的变量
$debug_token_var_puts = "var_puts"

#变量指令
$debug_token_vars = "vars"
#变量编辑指令
$debug_token_var_edit = "var_edit"
#新建指令
$debug_token_new = "new"
#需要识别的所有token
$debug_tokens = [$debug_token_vars, $debug_token_var_edit, $debug_token_new]

# ============================================================================= //
# 全局函数
# ============================================================================= //
if !defined? $console

#当前目录
def cur_path
    return Dir.pwd
end

def global_marshal_dump(input)
    begin
        return Marshal.dump(input)
    rescue Exception => err
        puts err.to_s
    end
    return nil   
end

def global_marshal_load(input)
    begin
        return Marshal.load(input)
    rescue Exception => err
        puts err.to_s
    end
    return nil   
end

# 对于函数和变量的更改，需要在main环境下eval
def global_eval(command)
    begin
        return eval(command)
    rescue Exception => err
        puts err.to_s
        raise Exception
    end
    return nil
end

alias console_origin_puts puts
def puts(content)
    begin
        console_origin_puts(content)
    rescue Exception => err
        console_origin_puts(err.to_s)
    end
end

end
# ============================================================================= //
# 函数Module
# ============================================================================= //

# 公共函数类库
module DebugUtils
    def self.split(text, token)
        begin
            #split有时会有问题，重新实现
            i = text.index(token)
            if i == nil
                return [text]
            else
                b = i-1
                a = i+1
                return [text[0..b], text[a..-1]]
            end
        rescue Exception => err
            puts err.to_s
        end
        return [text]
    end

    def self.get_file_full_name(name)
        return cur_path + $debug_file_dir + name + ".txt"
    end

    def self.read_file(file_name)
      return File.read(file_name)
    end

    def self.write_file(command, content)
      # 控制台是分线程读取，因此需要先写后改名
      file_name = self.get_file_full_name(command + "_" + Time.now.to_i.to_s)
      temp_name = self.get_file_full_name("temp" + "_" + Time.now.to_i.to_s)
      File.open(temp_name, "wb") do |file|
        file.puts content
      end
      File.rename(temp_name, file_name)
    end

    def self.get_all_files()
      # 按时间顺序获取所有文件
      list_file = []
      Dir.foreach(cur_path + $debug_file_dir) do |file_name|
        for token in $debug_tokens do
          if file_name.include?(token)
            list_file.push(cur_path + $debug_file_dir + file_name)
            break
          end
        end
      end
      return list_file if list_file.length == 0
      list_file.sort_by{ |file_name| File.ctime(file_name) }
      return list_file.reverse
    end

    def self.copy_instance_variables(from, to)
        # 逐属性拷贝，暂时没用到
        for var in from.instance_variables do
            value = from.instance_variable_get(var)
            to.instance_variable_set(var, value)
        end
        return to
    end
end

# 消息发送类库
module DebugMessage
  #向控制台发送Log
  def self.Log(text)
    DebugUtils.write_file($debug_token_puts, text)
  end
end

# 指令处理类库
module DebugCommand
    #指令处理
    def self.input_process_internal(filename, text)
      puts text

      #变量指令
      if filename.include?($debug_token_vars)
        begin
          var = global_eval(text)    
          DebugUtils.write_file($debug_token_var_puts, text + "=" + var.inspect)
        rescue Exception => err
          puts text + " : " + err.to_s
          DebugUtils.write_file($debug_token_var_puts, text + " : " + err.to_s)
        end

      #变量编辑指令
      elsif filename.include?($debug_token_var_edit)
        arr = DebugUtils.split(text, "=")
        if arr.length != 2
            puts "变量编辑格式错误！" + text
            return
        else
            begin
                #复杂的object编辑，暂时不支持
                #$debug_global_var = global_marshal_load(arr[1])
                #puts global_eval(arr[0] + "=DebugUtils.copy_instance_variables($debug_global_var, "+arr[0]+")")

                #简单的object编辑
                global_eval(text)
                puts "编辑变量完成"
            rescue Exception => err
                puts text + " : " + err.to_s
                DebugUtils.write_file($debug_token_puts, text + " : " + err.to_s)
            end
        end

      #新建指令
      elsif filename.include?($debug_token_new)
        begin
          global_eval(text)
          puts "新指令执行完成"
        rescue Exception => err
          puts text + " : " + err.to_s
          DebugUtils.write_file($debug_token_puts, text + " : " + err.to_s)
        end

      #未支持的指令
      else
        puts "未支持的指令" + filename
      end
    end

    # 删除之前遗留的旧指令
    def self.clear_old_input()
      list_file = DebugUtils.get_all_files()
      for file_name in list_file do
        File.delete(File.dirname(file_name) + "/" + File.basename(file_name))
      end
    end

    #主要指令队列
    def self.input_process()
      list_file = DebugUtils.get_all_files()
      return if list_file.length == 0
      # 获取所有文件内容
      for file_name in list_file do
        content = DebugUtils.read_file(file_name)
        base_name = File.basename(file_name).to_s
        File.delete(File.dirname(file_name) + "/" + File.basename(file_name))
        self.input_process_internal(base_name, content)     
      end
      list_file = []
    end
end

# ============================================================================= //
# 准备逻辑
# ============================================================================= //
if $debug_active && !defined? $console

  # 检查目录是否存在
  if !File.directory?(cur_path + $debug_file_dir)
    # 不存在则生成
    Dir.mkdir(cur_path + $debug_file_dir)
  end

  # 删除之前遗留的旧指令
  DebugCommand.clear_old_input
  # 如果控制台先启动，向控制台发送
  DebugMessage.Log("★ 已启动游戏进程")

  puts "#------------------------------------------------------------------------------------------------"
  puts "# RPGMaker控制台内接插件"+$debug_version+" 适用于RMVA RMVX RMXP 作者: cafel QQ群：792888538"
  puts "#------------------------------------------------------------------------------------------------"
  puts "★ 插件已开始运行"

end
# ============================================================================= //
# 测试逻辑
# ============================================================================= //
if $debug_active && $debug_test

class Game_Party
  attr_writer   :gold                     
end

end
# ============================================================================= //
# 脚本执行
# ============================================================================= //

if defined?(Scene_Base)
    # VA VX
    class Scene_Base
      #--------------------------------------------------------------------------
      # * Frame Update
      #--------------------------------------------------------------------------
      alias console_origin_update update
      def update
        console_origin_update
        # 非active下不执行
        return if !$debug_active
        DebugCommand.input_process
      end
    end
else
    # XP
    class Window_Base
      #--------------------------------------------------------------------------
      # * Frame Update
      #--------------------------------------------------------------------------
      alias console_origin_update update
      def update
        console_origin_update
        # 非active下不执行
        return if !$debug_active
        DebugCommand.input_process
      end
    end
end