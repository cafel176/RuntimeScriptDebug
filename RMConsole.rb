require 'find'
require 'oj'
require 'method_source'
require 'zlib'
require 'ruby2d'

$test_console = true

# ============================================================================= //
# 全局变量
# ============================================================================= //

#当前环境
$console = self
#当前目录
$console_cur_path = File.dirname(__FILE__)
#传输信息用文件所在目录
$console_file_dir = "/console/"
#临时脚本文件
$console_script = "temp_script.rb"

#变量指令
$console_token_vars = "vars"
#函数指令
$console_token_func = "func"
#新建指令
$console_token_new = "new"

#输出的消息
$console_token_puts = "puts"
#输出的变量
$console_token_vars_puts = "var_puts"
#需要识别的所有token
$console_tokens = [$console_token_puts, $console_token_vars_puts]

# ============================================================================= //
# 函数Module
# ============================================================================= //

# 公共函数类库
module ConsoleUtils
    def self.get_file_full_name(name)
        return $console_cur_path + $console_file_dir + name + ".txt"
    end

    def self.read_file(file_name)
      return File.read(file_name)
    end

    def self.read_rvdata2_file(file_name)
      File.open(file_name, "rb") do |file|
        result = Marshal.load(file)
        file.close
        return result
      end
      return nil
    end

    def self.write_file(command, content)
      file_name = self.get_file_full_name(command + "_" + Time.now.to_i.to_s)
      File.write(file_name, content)
    end

    def self.get_all_files()
      # 按时间顺序获取所有文件
      list_file = []
      Find.find($console_cur_path + $console_file_dir) do |file|
        filename = File.basename(file)
        for token in $console_tokens do
            if filename.start_with?(token)
               list_file.push(file)
            end
        end
      end
      return list_file if list_file.length == 0
      list_file.sort_by{ |file| File.ctime(file) }
      return list_file.reverse
    end

    def self.load_scripts
      # 加载脚本
      scripts = self.read_rvdata2_file($console_cur_path + "/Data/Scripts.rvdata2")
      text = ""
      for script in scripts do
        next if script[1] == 'Main'
        text += Zlib::Inflate.inflate(script[2]) + "\n";
      end
      # 生成临时脚本文件
      File.write($console_cur_path + "/" + $console_script, text)
    end
end

# 消息处理类库
module ConsoleMessage
    #内容处理
    def self.message_process_internal(filename, text)
      #输出的消息
      if filename.start_with?($console_token_puts) 
        puts "输出：" + text

      #输出的变量
      elsif filename.start_with?($console_token_vars_puts) 
        arr = text.split("=", 2)
        if arr.length != 2
          puts "消息格式错误" + text
        else
          var = Marshal.load(arr[1])        
          json = Oj::dump var, :indent => 2
          puts arr[0] + "=" + json
        end

      #未支持的消息
      else
        puts "未支持的消息" + filename
      end
    end

    # 删除之前遗留的旧消息
    def self.clear_old_message()
      list_file = ConsoleUtils.get_all_files()
      for file in list_file do
        File.delete(File.dirname(file) + "/" + File.basename(file))
      end
    end

    #主要消息队列
    def self.message_process()
      puts "★ 消息队列已开始执行"
      list_file = []
      while true
        list_file = ConsoleUtils.get_all_files()

        # 获取所有文件内容
        for file_name in list_file do
          self.message_process_internal(File.basename(file_name), ConsoleUtils.read_file(file_name))
          while true do
            begin
              File.delete(File.dirname(file_name) + "/" + File.basename(file_name))
              break
            rescue => err
              #puts "删除文件失败，正在重试 " + err.to_s
            end          
          end          
        end
        list_file = []
      end
    end
end

# 指令处理类库
module ConsoleCommand
    #指令处理
    def self.input_process_internal(command)
      #变量指令
      if command.start_with?($console_token_vars)
        arr = command.split("#", 2)
        if arr.length != 2
          puts "指令格式错误" + command 
        else
          ConsoleUtils.write_file($console_token_vars, arr[1])
        end
        
      #函数指令
      elsif command.start_with?($console_token_func)
        arr = command.split("#", 2)
        if arr.length != 2
          puts "指令格式错误" + command
        else
          #输出函数源码
          begin
            method = eval(arr[1])
            if method.class.name == "UnboundMethod" #Class从类名来查的成员函数
              puts "class " + method.owner.name + "\n" + method.source + "end"
            elsif method.receiver.to_s == "main" #全局函数
              puts method.source
            elsif method.receiver.class.name == "Module" #Module类函数
              puts "module " + method.receiver.name + "\n" + method.source + "end"
            elsif method.receiver.class.name == "Class" #Class从类名来查的类函数
              puts "class " + method.receiver.name + "\n" + method.source + "end"
            elsif method.owner.class.name == "Class" #Class从实例来查的成员函数
              puts "class " + method.owner.name + "\n" + method.source + "end"
            end 
          rescue => err
            puts arr[1] + " : " + err.to_s
          end
        end

      #新建指令
      elsif command.start_with?($console_token_new) 
        arr = command.split("#")
        if arr.length != 2
          puts "指令格式错误" + command
        else
          ConsoleUtils.write_file($console_token_new, arr[1])
          # 如果是对函数的修改，这里要同步应用
          begin
            eval(arr[1])
          rescue => err
            # 如果出问题不做任何反馈，游戏测会反馈
          end
        end
        
      #未支持的指令
      else
        puts "未支持的指令" + command
      end
    end

    #主要输入队列
    def self.input_process()
      puts "★ 输入队列已开始执行"
      while true
        puts "请输入指令："
        command = gets
        # 去除首尾空格
        command = command.strip
        # 去除末尾换行符
        command = command.chomp
        if command == ""
          next
        end

        final = ""
        if command.start_with?($console_token_new + "#")
          final = command
        else
          begin
            result = eval(command)
            if result.class.name.include?("Method")
              final = $console_token_func + "#" + command
            else
              final = $console_token_vars + "#" + command
            end 
          rescue => err
            final = $console_token_vars + "#" + command
          end  
        end

        self.input_process_internal(final) if final != ""

      end
    end
end

# ============================================================================= //
# 准备逻辑
# ============================================================================= //

# 检查目录是否存在
if !File.directory?($console_cur_path + $console_file_dir)
  # 不存在则生成
  Dir.mkdir($console_cur_path + $console_file_dir)
end

# 删除之前遗留的旧消息
ConsoleMessage.clear_old_message
# 删除旧的脚本文件
if !Dir.glob($console_cur_path + $console_file_dir + $console_script).empty?
  File.delete($console_cur_path + $console_file_dir + $console_script)
end

begin
  # 加载脚本到临时文件，以供source识别
  ConsoleUtils.load_scripts
  # require脚本，以供source识别
  require $console_cur_path + "/" + $console_script
rescue => err
  puts "加载脚本失败！" + err.to_s
  exit 1;
end

# ============================================================================= //
# 测试逻辑
# ============================================================================= //
if $test_console

# 函数解析测试
def test_func
end

class TestClass
  def self.test_func
  end

  def update
  end
end
$instance = TestClass.new

#ConsoleCommand.input_process_internal("func#Scene_Base.instance_method(:update)")
#ConsoleCommand.input_process_internal("func#\$console.method(:test_func)")
#ConsoleCommand.input_process_internal("func#DataManager.method(:init)")
#ConsoleCommand.input_process_internal("func#TestClass.method(:test_func)")
#ConsoleCommand.input_process_internal("func#\$instance.method(:update)")

end
# ============================================================================= //
# 程序运行
# ============================================================================= //

puts "#------------------------------------------------------------------------------------------------"
puts "# RPGMaker外接控制面板V1 适用于RMVA 作者: cafel"
puts "# "
puts "# 可用指令如下："
puts "# "
puts "# ★ 1.变量指令： " + $console_token_vars + "#x"
puts "# x为任意RGSS的变量，例如 $game_party.gold、DataManager.last_savefile_index"
puts "# 会将结果输出到控制台并弹出编辑面板"
puts "# "
puts "# ★ 2.函数指令： " + $console_token_func + "#x"
puts "# x为任意RGSS的函数，例如 $console.method(:test)、DataManager.method(:init)、Scene_Base.instance_method(:update)、SceneManager.scene.method(:update)、TestClass.method(:test_func)"
puts "# 会将结果输出到控制台并弹出编辑面板"
puts "# "
puts "# ★ 3.新建指令： " + $console_token_new + "#x" 
puts "# x为任意ruby脚本，例如 puts 'aaaa'"
puts "# 会将脚本直接应用到游戏"
puts "#------------------------------------------------------------------------------------------------"

# 消息处理队列
message_processor = Thread.new { ConsoleMessage.message_process() }

# 输入处理队列
input_processor = Thread.new { ConsoleCommand.input_process() }
input_processor.join