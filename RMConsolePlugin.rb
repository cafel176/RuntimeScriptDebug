# ============================================================================= //
# RMConsolePlugin
# ============================================================================= //
# 
# 当前版本：V1
# 运行时脚本调试插件，适用于RMVA、RMVX和RMXP
# 作者： cafel
# QQ群：792888538  
# github地址：https://github.com/cafel176/RuntimeScriptDebug
# Project1：
# 视频教程：
# 
# ★ 本插件提供如下支持：
# 
# 1. 支持运行时在任意时间打开脚本调试界面，快捷键 菜单键+F9
# 
# 2. 在调试界面下，可以输入想要调试的变量或函数，如果输入合理，之后会在控制台输出该变量或函数的信息，与此同时打开编辑面板支持编辑
#    ♦ 变量例如：
#    ♦ 函数例如：
# 
# 3. 如果想要完全新加脚本，在调试界面输入new，即可打开一个全新的编辑界面，可以在此加入全新的内容
# 
#  ★ 注意：本插件完全用于开发调试，开发完成后进入部署阶段时，请将$debug_active关闭避免影响到游戏流程
$debug_active = true

$debug_test = true

# ============================================================================= //
# 全局变量
# ============================================================================= //

#当前目录
$debug_cur_path = File.dirname(__FILE__)
#传输信息用文件所在目录
$debug_file_dir = "/console/"

#输出的消息
$debug_token_puts = "puts"
#输出的变量
$debug_token_vars_puts = "var_puts"

#变量指令
$debug_token_vars = "vars"
#新建指令
$debug_token_new = "new"
#需要识别的所有token
$debug_tokens = [$debug_token_vars, $debug_token_new]

# ============================================================================= //
# 函数Module
# ============================================================================= //

# 公共函数类库
module DebugUtils
    def self.get_file_full_name(name)
        return $debug_cur_path + $debug_file_dir + name + ".txt"
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
        file.close
      end
      File.rename(temp_name, file_name)
    end

    def self.get_all_files()
      # 按时间顺序获取所有文件
      list_file = []
      Dir.foreach($debug_cur_path + $debug_file_dir) do |file_name|
        filename = File.basename(file_name)
        for token in $debug_tokens do
          if filename.start_with?(token)
            list_file.push($debug_cur_path + $debug_file_dir + file_name)
          end
        end
      end
      return list_file if list_file.length == 0
      list_file.sort_by{ |file_name| File.ctime(file_name) }
      return list_file.reverse
    end
end

# 消息发送类库
module DebugMessage
  def self.Log(text)
    DebugUtils.write_file($debug_token_puts, text)
  end
end

# 指令处理类库
module DebugCommand
    #指令处理
    def self.input_process_internal(filename, text)
      #变量指令
      if filename.start_with?($debug_token_vars)
        begin
          var = eval(text)  
          puts text
          DebugUtils.write_file($debug_token_vars_puts, text + "=" + Marshal.dump(var))
        rescue => err
          puts text + " : " + err.to_s
          DebugUtils.write_file($debug_token_puts, text + " : " + err.to_s)
        end

      #新建指令
      elsif filename.start_with?($debug_token_new) 
        begin
          var = eval(text)  
          puts text
        rescue => err
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
      # 获取所有文件内容
      for file_name in list_file do
        self.input_process_internal(File.basename(file_name), DebugUtils.read_file(file_name))
        while true do
          begin
            File.delete(File.dirname(file_name) + "/" + File.basename(file_name))
            break
          rescue => err
            #puts "删除文件失败，正在重试 " + err.to_s
          end          
        end
      end
    end
end

# ============================================================================= //
# 准备逻辑
# ============================================================================= //

if $debug_active
  # 检查目录是否存在
  if !File.directory?($debug_cur_path + $debug_file_dir)
    # 不存在则生成
    Dir.mkdir($debug_cur_path + $debug_file_dir)
  end

  # 删除之前遗留的旧指令
  DebugCommand.clear_old_input

  DebugMessage.Log("★ 已启动游戏进程")

end

# ============================================================================= //
# 测试逻辑
# ============================================================================= //
if $debug_test && $debug_active 

class Game_Party
  attr_writer   :gold                     
end

end
# ============================================================================= //
# 脚本执行
# ============================================================================= //
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