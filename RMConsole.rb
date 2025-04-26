# ============================================================================= //
# RMConsole
# ============================================================================= //
# 
# 当前版本：V1
# RGSS外接控制台，适用于RMVA、RMVX和RMXP
# 作者： cafel
# QQ群：792888538  
# github地址：https://github.com/cafel176/RuntimeScriptDebug
# Project1：
# 视频教程：
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
#    ★ 注意：当前并不支持以json格式修改object，显示的json格式信息仅供读取，请自行写ruby代码来修改object
#    ★ 注意：XP版本则由于其序列化字符不符合ut8解析规则因此完全无法查看json格式的object
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
# ★ 注意：控制台完全用于开发调试，开发完成后进入部署阶段时，请插件关闭避免影响到游戏流程
#

require "find"
require "oj"
require "method_source"
require "zlib"
require "ruby2d"
require "glimmer-dsl-libui"

# ============================================================================= //
# 控制台配置
# ============================================================================= //

# 测试用，会定义一些测试用的类型
$test_console = true

#版本
$console_version = "v1"
#等待游戏回应的最大循环次数 次数x0.1秒=总时间
$console_max_wait_times = 300
#传输信息用文件所在目录
$console_file_dir = "/console/"
#传输信息用文件所在目录
$console_script_dir = "/console/script/"
#rgss脚本位置
$console_script_data = ["/Data/Scripts.rvdata2", "/Data/Scripts.rvdata", "/Data/Scripts.rxdata"]

# ============================================================================= //
# 全局变量
# ============================================================================= //

#当前环境
$console = self

#临时脚本文件名
$console_token_script = "temp_script"

#变量指令
$console_token_vars = "vars"
#变量编辑指令
$console_token_var_edit = "var_edit"
#函数指令
$console_token_funcs = "funcs"
#函数编辑指令
$console_token_func_edit = "func_edit"
#新建指令
$console_token_new = "new"

#输出的消息
$console_token_puts = "puts"
#输出的变量
$console_token_var_puts = "var_puts"
#需要识别的所有token
$console_tokens = [$console_token_puts, $console_token_var_puts]

# 接收到的错误
$console_get_error = ""
# 接收到的消息
$console_get_message = ""

# ============================================================================= //
# 全局函数
# ============================================================================= //

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

def global_oj_dump(input)
    begin
        return Oj::dump input, :indent => 2
    rescue Exception => err
        puts err.to_s
    end
    return nil  
end

def global_oj_load(input)
    begin
        return Oj::load(input)
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

# require需要在main环境下
def global_require(file)
    begin
        require(file)
    rescue Exception => err
        puts err.to_s
        File.delete(file)
    end
end

# 用于生成并载入临时脚本
def temp_script(script)
    begin
      # 加载脚本到临时文件，以供source识别
      script_file_name = ConsoleUtils.dump_scripts($console_token_script + "_" + Time.now.to_i.to_s, script)
      # require脚本，以供source识别
      global_require(script_file_name)
    rescue Exception => err
      puts "加载脚本出错！" + err.to_s
    end
end

# ============================================================================= //
# 函数Module
# ============================================================================= //

# 公共函数类库
module ConsoleUtils
    def self.get_file_full_name(name)
        return cur_path + $console_file_dir + name + ".txt"
    end

    def self.get_script_full_name(name)
        return cur_path + $console_script_dir + name + ".rb"
    end

    def self.read_file(file_name)
      return File.read(file_name)
    end

    # 读取rgss脚本
    def self.read_rvdata_file(file_name)
      File.open(file_name, "rb") do |file|
        result = global_marshal_load(file)
        file.close
        return result
      end
      return nil
    end

    def self.write_file(command, content)
      file_name = self.get_file_full_name(command + "_" + Time.now.to_i.to_s)
      temp_name = self.get_file_full_name("temp" + "_" + Time.now.to_i.to_s)
      File.write(temp_name, content)
      File.rename(temp_name, file_name)
    end

    def self.get_all_files()
      # 按时间顺序获取所有文件
      list_file = []
      Find.find(cur_path + $console_file_dir) do |file|
        filename = File.basename(file)
        for token in $console_tokens do
            if filename.start_with?(token)
               list_file.push(file)
               break
            end
        end
      end
      return list_file if list_file.length == 0
      list_file.sort_by{ |file| File.ctime(file) }
      return list_file.reverse
    end

    def self.get_all_scripts()
      # 按时间顺序获取所有文件
      list_file = []
      Find.find(cur_path + $console_script_dir) do |file|
        filename = File.basename(file)
        if filename.start_with?($console_token_script)
           list_file.push(file)
        end
      end
      return list_file if list_file.length == 0
      list_file.sort_by{ |file| File.ctime(file) }
      return list_file.reverse
    end

    def self.load_scripts()
      for script_data in $console_script_data
        if !File.exist?(cur_path + script_data)
            next
        end

        scripts = self.read_rvdata_file(cur_path + script_data)      
        # 加载脚本
        text = ""
        for script in scripts do
          next if script[1] == "Main"
          text += Zlib::Inflate.inflate(script[2]) + "\n";
        end
        # 生成临时脚本文件
        return self.dump_scripts($console_token_script + "_" + Time.now.to_i.to_s, text)
      end
      return nil
    end

    def self.dump_scripts(fine_name, script)
      # 生成临时脚本文件
      full_name = self.get_script_full_name(fine_name)
      File.write(full_name, script)
      return full_name
    end

    # 删除之前遗留的旧脚本
    def self.clear_old_scripts()
      list_file = ConsoleUtils.get_all_scripts()
      for file in list_file do
        File.delete(File.dirname(file) + "/" + File.basename(file))
      end
    end

    def self.copy_instance_variables(from, to)
        # 逐属性拷贝，暂未用到
        for var in from.instance_variables do
            value = from.instance_variable_get(var)
            to.instance_variable_set(var, value)
        end
        return to
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
      elsif filename.start_with?($console_token_var_puts)
        begin
            arr = text.split("=", 2)
            if arr.length != 2
              # 提交到全局变量供GUI处理
              $console_get_error = text
            else
              var = global_marshal_load(arr[1])
              json = global_oj_dump(var)
              # 提交到全局变量供GUI处理
              $console_get_message = arr[0] + "=" + json
            end
        rescue Exception => err
            $console_get_error = "加载消息出错！" + err.to_s
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
          content = ConsoleUtils.read_file(file_name)
          File.delete(File.dirname(file_name) + "/" + File.basename(file_name))
          self.message_process_internal(File.basename(file_name), content)                   
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
          return [false, "指令格式错误" + command]
        else
          ConsoleUtils.write_file($console_token_vars, arr[1])
          return [true, ""]
        end
        
      #函数指令
      elsif command.start_with?($console_token_funcs)
        arr = command.split("#", 2)
        if arr.length != 2
          return [false, "指令格式错误" + command]
        else
          #输出函数源码
          begin
            method = global_eval(arr[1])
            if method.class.name == "UnboundMethod" #Class从类名来查的成员函数
              return [true, "class " + method.owner.name + "\n" + method.source + "end"]
            elsif method.receiver.to_s == "main" #全局函数
              return [true, method.source]
            elsif method.receiver.class.name == "Module" #Module类函数
              return [true, "module " + method.receiver.name + "\n" + method.source + "end"]
            elsif method.receiver.class.name == "Class" #Class从类名来查的类函数
              return [true, "class " + method.receiver.name + "\n" + method.source + "end"]
            elsif method.owner.class.name == "Class" #Class从实例来查的成员函数
              return [true, "class " + method.owner.name + "\n" + method.source + "end"]
            end 
          rescue Exception => err
            return [false, arr[1] + " : " + err.to_s]
          end
          return [false, "未识别的函数" + command]
        end

      #新建指令
      elsif command.start_with?($console_token_new)
        arr = command.split("#", 2)
        if arr.length != 2
          return [false, "指令格式错误" + command]
        else
          #用于使得eval可以处理多行文本
          script = "eval %{\n" + arr[1] + "\n}"
          # 游戏内rgss要执行这里要额外再加eval
          ConsoleUtils.write_file($console_token_new, script)
          # 这里要同步应用
          begin
            # 加载脚本到临时文件并require，以供source识别
            global_require(ConsoleUtils.dump_scripts($console_token_script + "_" + Time.now.to_i.to_s, arr[1]))
          rescue Exception => err
            return [false, "加载脚本出错！" + err.to_s]
          end
          return [true, ""]
        end
        
      #变量编辑指令
      elsif command.start_with?($console_token_var_edit)
        arr = command.split("#", 2)
        if arr.length != 2
          return [false, "指令格式错误" + command]
        else
          #用于使得eval可以处理多行文本
          script = "eval %{\n" + arr[1] + "\n}"
          # 游戏内rgss要执行这里要额外再加eval
          ConsoleUtils.write_file($console_token_var_edit, script)
          # 这里要同步应用
          begin
            # 加载脚本到临时文件并require，以供source识别
            global_require(ConsoleUtils.dump_scripts($console_token_script + "_" + Time.now.to_i.to_s, arr[1]))
          rescue Exception => err
            return [false, "加载脚本出错！" + err.to_s]
          end
          return [true, ""]
        end

      #函数编辑指令
      elsif command.start_with?($console_token_func_edit)
        arr = command.split("#", 2)
        if arr.length != 2
          return [false, "指令格式错误" + command]
        else
          #用于使得eval可以处理多行文本
          script = "eval %{\n" + arr[1] + "\n}"
          # 游戏内rgss要执行这里要额外再加eval
          ConsoleUtils.write_file($console_token_new, script)
          # 对函数的修改，这里要同步应用
          begin
            # 加载脚本到临时文件并require，以供source识别
            global_require(ConsoleUtils.dump_scripts($console_token_script + "_" + Time.now.to_i.to_s, arr[1]))
          rescue Exception => err
            #return [false, "加载脚本出错！" + err.to_s]
          end
          return [true, ""]
        end

      end

      #未支持的指令
      return [false, "未支持的指令" + command]     
    end

    #指令检查和分类
    def self.input_check(command)
        # 去除首尾空格
        command = command.strip
        # 去除末尾换行符
        command = command.chomp
        if command == ""
          return [false, "指令不能为空！"]
        end

        final = ""
        if command == $console_token_new
          return [true, command]
        else
          begin
            result = global_eval(command)
            if result.class.name.include?("Method")
              final = $console_token_funcs + "#" + command
            else
              final = $console_token_vars + "#" + command
            end 
          rescue Exception => err
            final = $console_token_vars + "#" + command
          end  
        end

        return self.input_process_internal(final) if final != ""
        return [false, "未识别的指令"]
    end

    #非GUI指令系统，已弃用
    def self.input_process()
      puts "#------------------------------------------------------------------------------------------------"
      puts "# RPGMaker外接控制台"+$console_version+" 适用于RMVA RMVX RMXP 作者: cafel"
      puts "#------------------------------------------------------------------------------------------------"
      puts "★ 输入队列已开始执行"
      while true
        puts "请输入指令："
        command = gets
        self.input_check(command)
      end
    end
end

# ============================================================================= //
# GUI
# ============================================================================= //

# 是否正在编辑状态，用于窗口间通信
$can_edit = true

# 编辑窗口
class EditWindow
  include Glimmer

  attr_accessor :var_mode, :func_mode, :code, :hint, :hint2, :hint3

  def initialize
    @code_area = nil

    self.prepare(false, false, "", "")

    @hint2 = "确定：将修改应用到游戏"
    @hint3 = "重置：将文本框重置为初始内容"
  end

  def prepare(in_var_mode, in_func_mode, in_code, in_hint)
    @var_mode = in_var_mode
    @func_mode = in_func_mode
    @code = (@var_mode ? "#当前并不支持以json格式修改object，请自行写ruby代码来修改object\n" : "") + in_code
    @hint = in_hint
  end

  def launch
    $can_edit = false
    window("编辑窗口", 800, 500) { |edit_window|
        margined true

        vertical_box {
            label {
                stretchy false

                text <= [self, :hint]
            }

            label {
                stretchy false

                text <= [self, :hint2]
            }

            label {
                stretchy false

                text <= [self, :hint3]
            }

            horizontal_box {
                stretchy false

                button("确定") {
                    on_clicked do
                        result = @code_area.text.to_s
                        # UI获得的文本都要转utf-8
                        result = result.force_encoding("utf-8")
                        # 变量模式
                        if @var_mode
                            arr = result.split("=", 2)
                            if arr.length != 2
                                msg_box("错误！", "变量编辑格式错误！" + result)
                            else
                                ConsoleCommand.input_process_internal($console_token_var_edit + "#" + result)
                                msg_box("完成！", "变量修改完成，请切到游戏触发处理")
                                # 不hide直接继续编辑会导致游戏崩溃
                                edit_window.hide
                                $can_edit = true
                            end

                        # 函数模式
                        elsif @func_mode
                            ConsoleCommand.input_process_internal($console_token_func_edit + "#" + result)
                            msg_box("完成！", "函数修改完成，请切到游戏触发处理")
                            # 不hide直接继续编辑会导致游戏崩溃
                            edit_window.hide
                            $can_edit = true

                        # new模式
                        else
                            ConsoleCommand.input_process_internal($console_token_new + "#" + result)
                            msg_box("完成！", "脚本执行完成，请切到游戏触发处理")
                            # 不hide直接继续编辑会导致游戏崩溃
                            edit_window.hide
                            $can_edit = true
                        end
                    end
                }

                button("重置") {
                    on_clicked do
                        @code_area.text = @code
                    end
                }

                button("清空") {
                    on_clicked do
                        @code_area.text = ""
                    end
                }
            }

            @code_area = multiline_entry{
                text <= [self, :code]
            }
        }

        on_closing do
          # 非常奇怪，这里把任意全局变量设为false就会出错，设为true就没问题
          # 评价为 Glimmer 系统一坨
          $can_edit = true
        end
    }.show
  end
end

# 指令窗口
class InputWindow
  include Glimmer

  attr_accessor :input, :hint

  def initialize
    @input = ""
    @hint = "请输入想调试的变量或函数，输入new以完全新建脚本。关闭本窗口退出程序。"

    puts "★ 输入窗口已打开"
  end

  def launch
    window("RPGMaker外接控制台"+$console_version+" 适用于RMVA RMVX RMXP 作者: cafel", 600, 100) {
        margined true

        vertical_box {
            label {
                stretchy false

                text <= [self, :hint]
            }

            @entry = entry{
                stretchy false

                text <= [self, :input]
            }

            horizontal_box {
                stretchy false

                button("确定") {
                    on_clicked do  
                        if $can_edit
                            entry_text = @entry.text.to_s
                            # UI获得的文本都要转utf-8
                            entry_text = entry_text.force_encoding("utf-8")
                            # 检查指令
                            result = ConsoleCommand.input_check(entry_text)
                            # 正常处理
                            if result[0]
                              # 为空意味着需要等待游戏回应
                              if result[1] == ""
                                msg_box("指令已输入，请切到游戏触发处理！")
                                check = false

                                # 为了避免直接在消息线程里进行GUI操作，采用循环等待全局变量同步
                                # 循环加入超时处理避免卡死
                                times = 0
                                $console_max_wait_times.times do |i|
                                  sleep(0.1)

                                  # 游戏反馈了错误
                                  if $console_get_error != ""
                                    text = $console_get_error
                                    $console_get_error = ""

                                    msg_box("游戏反馈的错误！", text) 
                                    
                                    check = true
                                    break

                                  # 游戏反馈了消息
                                  elsif $console_get_message != ""
                                    text = $console_get_message
                                    $console_get_message = ""

                                    arr = text.split("=", 2)
                                    if arr.length != 2
                                        msg_box("游戏反馈的错误！", "消息无法解析" + text)                                        
                                    else
                                        var_mode = true
                                        func_mode = false
                                        code = text
                                        hint = entry_text

                                        editWindow = EditWindow.new
                                        editWindow.prepare(var_mode, func_mode, code, hint)
                                        editWindow.launch
                                    end

                                    check = true
                                    break

                                  end
                                end

                                if !check
                                    msg_box("指令已超时！" + times.to_s)
                                end

                              # 不为空可以直接处理，一般为new和函数
                              else
                                var_mode = false
                                func_mode = (result[1] != $console_token_new)
                                code = (result[1] != $console_token_new ? result[1] : "")
                                hint = entry_text

                                editWindow = EditWindow.new
                                editWindow.prepare(var_mode, func_mode, code, hint)
                                editWindow.launch
                              end
                            else
                                msg_box("指令错误！", result[1])
                            end  
                        else
                          msg_box("正在编辑中！")
                        end
                    end
                }
                
                button("清空") {
                    on_clicked do
                        if $can_edit
                            @entry.text = ""
                        else
                            msg_box("正在编辑中！")
                        end                        
                    end
                }
            }
        }
        
        on_closing do
            # 删除之前遗留的旧消息
            ConsoleMessage.clear_old_message
            # 删除旧的脚本文件
            ConsoleUtils.clear_old_scripts
        end
    }.show
  end
end

# ============================================================================= //
# 准备逻辑
# ============================================================================= //

# 检查主目录是否存在
if !File.directory?(cur_path + $console_file_dir)
  # 不存在则生成
  Dir.mkdir(cur_path + $console_file_dir)
end
# 检查脚本目录是否存在
if !File.directory?(cur_path + $console_script_dir)
  # 不存在则生成
  Dir.mkdir(cur_path + $console_script_dir)
end

# 删除之前遗留的旧消息
ConsoleMessage.clear_old_message

# 删除旧的脚本文件
ConsoleUtils.clear_old_scripts

# XP需要额外处理
if !defined?(Scene_Base)
    module RPG
      module Cache
        @cache = {}
        def self.load_bitmap(folder_name, filename, hue = 0)
          path = folder_name + filename
          if not @cache.include?(path) or @cache[path].disposed?
            if filename != ""
              @cache[path] = Bitmap.new(path)
            else
              @cache[path] = Bitmap.new(32, 32)
            end
          end
          if hue == 0
            @cache[path]
          else
            key = [path, hue]
            if not @cache.include?(key) or @cache[key].disposed?
              @cache[key] = @cache[path].clone
              @cache[key].hue_change(hue)
            end
            @cache[key]
          end
        end
        def self.animation(filename, hue)
          self.load_bitmap("Graphics/Animations/", filename, hue)
        end
        def self.autotile(filename)
          self.load_bitmap("Graphics/Autotiles/", filename)
        end
        def self.battleback(filename)
          self.load_bitmap("Graphics/Battlebacks/", filename)
        end
        def self.battler(filename, hue)
          self.load_bitmap("Graphics/Battlers/", filename, hue)
        end
        def self.character(filename, hue)
          self.load_bitmap("Graphics/Characters/", filename, hue)
        end
        def self.fog(filename, hue)
          self.load_bitmap("Graphics/Fogs/", filename, hue)
        end
        def self.gameover(filename)
          self.load_bitmap("Graphics/Gameovers/", filename)
        end
        def self.icon(filename)
          self.load_bitmap("Graphics/Icons/", filename)
        end
        def self.panorama(filename, hue)
          self.load_bitmap("Graphics/Panoramas/", filename, hue)
        end
        def self.picture(filename)
          self.load_bitmap("Graphics/Pictures/", filename)
        end
        def self.tileset(filename)
          self.load_bitmap("Graphics/Tilesets/", filename)
        end
        def self.title(filename)
          self.load_bitmap("Graphics/Titles/", filename)
        end
        def self.windowskin(filename)
          self.load_bitmap("Graphics/Windowskins/", filename)
        end
        def self.tile(filename, tile_id, hue)
          key = [filename, tile_id, hue]
          if not @cache.include?(key) or @cache[key].disposed?
            @cache[key] = Bitmap.new(32, 32)
            x = (tile_id - 384) % 8 * 32
            y = (tile_id - 384) / 8 * 32
            rect = Rect.new(x, y, 32, 32)
            @cache[key].blt(0, 0, self.tileset(filename), rect)
            @cache[key].hue_change(hue)
          end
          @cache[key]
        end
        def self.clear
          @cache = {}
          GC.start
        end
      end

      class Sprite < ::Sprite
        @@_animations = []
        @@_reference_count = {}
        def initialize(viewport = nil)
          super(viewport)
          @_whiten_duration = 0
          @_appear_duration = 0
          @_escape_duration = 0
          @_collapse_duration = 0
          @_damage_duration = 0
          @_animation_duration = 0
          @_blink = false
        end
        def dispose
          dispose_damage
          dispose_animation
          dispose_loop_animation
          super
        end
        def whiten
          self.blend_type = 0
          self.color.set(255, 255, 255, 128)
          self.opacity = 255
          @_whiten_duration = 16
          @_appear_duration = 0
          @_escape_duration = 0
          @_collapse_duration = 0
        end
        def appear
          self.blend_type = 0
          self.color.set(0, 0, 0, 0)
          self.opacity = 0
          @_appear_duration = 16
          @_whiten_duration = 0
          @_escape_duration = 0
          @_collapse_duration = 0
        end
        def escape
          self.blend_type = 0
          self.color.set(0, 0, 0, 0)
          self.opacity = 255
          @_escape_duration = 32
          @_whiten_duration = 0
          @_appear_duration = 0
          @_collapse_duration = 0
        end
        def collapse
          self.blend_type = 1
          self.color.set(255, 64, 64, 255)
          self.opacity = 255
          @_collapse_duration = 48
          @_whiten_duration = 0
          @_appear_duration = 0
          @_escape_duration = 0
        end
        def damage(value, critical)
          dispose_damage
          if value.is_a?(Numeric)
            damage_string = value.abs.to_s
          else
            damage_string = value.to_s
          end
          bitmap = Bitmap.new(160, 48)
          bitmap.font.name = "Arial Black"
          bitmap.font.size = 32
          bitmap.font.color.set(0, 0, 0)
          bitmap.draw_text(-1, 12-1, 160, 36, damage_string, 1)
          bitmap.draw_text(+1, 12-1, 160, 36, damage_string, 1)
          bitmap.draw_text(-1, 12+1, 160, 36, damage_string, 1)
          bitmap.draw_text(+1, 12+1, 160, 36, damage_string, 1)
          if value.is_a?(Numeric) and value < 0
            bitmap.font.color.set(176, 255, 144)
          else
            bitmap.font.color.set(255, 255, 255)
          end
          bitmap.draw_text(0, 12, 160, 36, damage_string, 1)
          if critical
            bitmap.font.size = 20
            bitmap.font.color.set(0, 0, 0)
            bitmap.draw_text(-1, -1, 160, 20, "CRITICAL", 1)
            bitmap.draw_text(+1, -1, 160, 20, "CRITICAL", 1)
            bitmap.draw_text(-1, +1, 160, 20, "CRITICAL", 1)
            bitmap.draw_text(+1, +1, 160, 20, "CRITICAL", 1)
            bitmap.font.color.set(255, 255, 255)
            bitmap.draw_text(0, 0, 160, 20, "CRITICAL", 1)
          end
          @_damage_sprite = ::Sprite.new(self.viewport)
          @_damage_sprite.bitmap = bitmap
          @_damage_sprite.ox = 80
          @_damage_sprite.oy = 20
          @_damage_sprite.x = self.x
          @_damage_sprite.y = self.y - self.oy / 2
          @_damage_sprite.z = 3000
          @_damage_duration = 40
        end
        def animation(animation, hit)
          dispose_animation
          @_animation = animation
          return if @_animation == nil
          @_animation_hit = hit
          @_animation_duration = @_animation.frame_max
          animation_name = @_animation.animation_name
          animation_hue = @_animation.animation_hue
          bitmap = RPG::Cache.animation(animation_name, animation_hue)
          if @@_reference_count.include?(bitmap)
            @@_reference_count[bitmap] += 1
          else
            @@_reference_count[bitmap] = 1
          end
          @_animation_sprites = []
          if @_animation.position != 3 or not @@_animations.include?(animation)
            for i in 0..15
              sprite = ::Sprite.new(self.viewport)
              sprite.bitmap = bitmap
              sprite.visible = false
              @_animation_sprites.push(sprite)
            end
            unless @@_animations.include?(animation)
              @@_animations.push(animation)
            end
          end
          update_animation
        end
        def loop_animation(animation)
          return if animation == @_loop_animation
          dispose_loop_animation
          @_loop_animation = animation
          return if @_loop_animation == nil
          @_loop_animation_index = 0
          animation_name = @_loop_animation.animation_name
          animation_hue = @_loop_animation.animation_hue
          bitmap = RPG::Cache.animation(animation_name, animation_hue)
          if @@_reference_count.include?(bitmap)
            @@_reference_count[bitmap] += 1
          else
            @@_reference_count[bitmap] = 1
          end
          @_loop_animation_sprites = []
          for i in 0..15
            sprite = ::Sprite.new(self.viewport)
            sprite.bitmap = bitmap
            sprite.visible = false
            @_loop_animation_sprites.push(sprite)
          end
          update_loop_animation
        end
        def dispose_damage
          if @_damage_sprite != nil
            @_damage_sprite.bitmap.dispose
            @_damage_sprite.dispose
            @_damage_sprite = nil
            @_damage_duration = 0
          end
        end
        def dispose_animation
          if @_animation_sprites != nil
            sprite = @_animation_sprites[0]
            if sprite != nil
              @@_reference_count[sprite.bitmap] -= 1
              if @@_reference_count[sprite.bitmap] == 0
                sprite.bitmap.dispose
              end
            end
            for sprite in @_animation_sprites
              sprite.dispose
            end
            @_animation_sprites = nil
            @_animation = nil
          end
        end
        def dispose_loop_animation
          if @_loop_animation_sprites != nil
            sprite = @_loop_animation_sprites[0]
            if sprite != nil
              @@_reference_count[sprite.bitmap] -= 1
              if @@_reference_count[sprite.bitmap] == 0
                sprite.bitmap.dispose
              end
            end
            for sprite in @_loop_animation_sprites
              sprite.dispose
            end
            @_loop_animation_sprites = nil
            @_loop_animation = nil
          end
        end
        def blink_on
          unless @_blink
            @_blink = true
            @_blink_count = 0
          end
        end
        def blink_off
          if @_blink
            @_blink = false
            self.color.set(0, 0, 0, 0)
          end
        end
        def blink?
          @_blink
        end
        def effect?
          @_whiten_duration > 0 or
          @_appear_duration > 0 or
          @_escape_duration > 0 or
          @_collapse_duration > 0 or
          @_damage_duration > 0 or
          @_animation_duration > 0
        end
        def update
          super
          if @_whiten_duration > 0
            @_whiten_duration -= 1
            self.color.alpha = 128 - (16 - @_whiten_duration) * 10
          end
          if @_appear_duration > 0
            @_appear_duration -= 1
            self.opacity = (16 - @_appear_duration) * 16
          end
          if @_escape_duration > 0
            @_escape_duration -= 1
            self.opacity = 256 - (32 - @_escape_duration) * 10
          end
          if @_collapse_duration > 0
            @_collapse_duration -= 1
            self.opacity = 256 - (48 - @_collapse_duration) * 6
          end
          if @_damage_duration > 0
            @_damage_duration -= 1
            case @_damage_duration
            when 38..39
              @_damage_sprite.y -= 4
            when 36..37
              @_damage_sprite.y -= 2
            when 34..35
              @_damage_sprite.y += 2
            when 28..33
              @_damage_sprite.y += 4
            end
            @_damage_sprite.opacity = 256 - (12 - @_damage_duration) * 32
            if @_damage_duration == 0
              dispose_damage
            end
          end
          if @_animation != nil and (Graphics.frame_count % 2 == 0)
            @_animation_duration -= 1
            update_animation
          end
          if @_loop_animation != nil and (Graphics.frame_count % 2 == 0)
            update_loop_animation
            @_loop_animation_index += 1
            @_loop_animation_index %= @_loop_animation.frame_max
          end
          if @_blink
            @_blink_count = (@_blink_count + 1) % 32
            if @_blink_count < 16
              alpha = (16 - @_blink_count) * 6
            else
              alpha = (@_blink_count - 16) * 6
            end
            self.color.set(255, 255, 255, alpha)
          end
          @@_animations.clear
        end
        def update_animation
          if @_animation_duration > 0
            frame_index = @_animation.frame_max - @_animation_duration
            cell_data = @_animation.frames[frame_index].cell_data
            position = @_animation.position
            animation_set_sprites(@_animation_sprites, cell_data, position)
            for timing in @_animation.timings
              if timing.frame == frame_index
                animation_process_timing(timing, @_animation_hit)
              end
            end
          else
            dispose_animation
          end
        end
        def update_loop_animation
          frame_index = @_loop_animation_index
          cell_data = @_loop_animation.frames[frame_index].cell_data
          position = @_loop_animation.position
          animation_set_sprites(@_loop_animation_sprites, cell_data, position)
          for timing in @_loop_animation.timings
            if timing.frame == frame_index
              animation_process_timing(timing, true)
            end
          end
        end
        def animation_set_sprites(sprites, cell_data, position)
          for i in 0..15
            sprite = sprites[i]
            pattern = cell_data[i, 0]
            if sprite == nil or pattern == nil or pattern == -1
              sprite.visible = false if sprite != nil
              next
            end
            sprite.visible = true
            sprite.src_rect.set(pattern % 5 * 192, pattern / 5 * 192, 192, 192)
            if position == 3
              if self.viewport != nil
                sprite.x = self.viewport.rect.width / 2
                sprite.y = self.viewport.rect.height - 160
              else
                sprite.x = 320
                sprite.y = 240
              end
            else
              sprite.x = self.x - self.ox + self.src_rect.width / 2
              sprite.y = self.y - self.oy + self.src_rect.height / 2
              sprite.y -= self.src_rect.height / 4 if position == 0
              sprite.y += self.src_rect.height / 4 if position == 2
            end
            sprite.x += cell_data[i, 1]
            sprite.y += cell_data[i, 2]
            sprite.z = 2000
            sprite.ox = 96
            sprite.oy = 96
            sprite.zoom_x = cell_data[i, 3] / 100.0
            sprite.zoom_y = cell_data[i, 3] / 100.0
            sprite.angle = cell_data[i, 4]
            sprite.mirror = (cell_data[i, 5] == 1)
            sprite.opacity = cell_data[i, 6] * self.opacity / 255.0
            sprite.blend_type = cell_data[i, 7]
          end
        end
        def animation_process_timing(timing, hit)
          if (timing.condition == 0) or
             (timing.condition == 1 and hit == true) or
             (timing.condition == 2 and hit == false)
            if timing.se.name != ""
              se = timing.se
              Audio.se_play("Audio/SE/" + se.name, se.volume, se.pitch)
            end
            case timing.flash_scope
            when 1
              self.flash(timing.flash_color, timing.flash_duration * 2)
            when 2
              if self.viewport != nil
                self.viewport.flash(timing.flash_color, timing.flash_duration * 2)
              end
            when 3
              self.flash(nil, timing.flash_duration * 2)
            end
          end
        end
        def x=(x)
          sx = x - self.x
          if sx != 0
            if @_animation_sprites != nil
              for i in 0..15
                @_animation_sprites[i].x += sx
              end
            end
            if @_loop_animation_sprites != nil
              for i in 0..15
                @_loop_animation_sprites[i].x += sx
              end
            end
          end
          super
        end
        def y=(y)
          sy = y - self.y
          if sy != 0
            if @_animation_sprites != nil
              for i in 0..15
                @_animation_sprites[i].y += sy
              end
            end
            if @_loop_animation_sprites != nil
              for i in 0..15
                @_loop_animation_sprites[i].y += sy
              end
            end
          end
          super
        end
      end
    end
end

begin
  # 加载脚本到临时文件并require，以供source识别
  global_require(ConsoleUtils.load_scripts)
rescue Exception => err
  puts "加载脚本出错！" + err.to_s
  exit;
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

end
# ============================================================================= //
# 程序运行
# ============================================================================= //

# 消息处理队列
message_processor = Thread.new { ConsoleMessage.message_process() }

# 进入GUI循环
console_input_window = InputWindow.new
console_input_window.launch

# 输入处理队列
#input_processor = Thread.new { ConsoleCommand.input_process() }
#input_processor.join