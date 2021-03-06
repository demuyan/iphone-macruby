# $Id: runner.rb 16364 2008-05-11 13:54:04Z nobu $

# NOTE:
# Never use optparse in this file.
# Never use test/unit in this file.
# Never use Ruby extensions in this file.

begin
  require 'fileutils'
  require 'tmpdir'
rescue LoadError
  $:.unshift File.join(File.dirname(__FILE__), '../lib')
  retry
end

if !Dir.respond_to?(:mktmpdir)
  # copied from lib/tmpdir.rb
  def Dir.mktmpdir(prefix="d", tmpdir=nil)
    tmpdir ||= Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path
      end
    else
      path
    end
  end
end

def main
  @ruby = File.expand_path('miniruby')
  @verbose = false
  dir = nil
  quiet = false
  tests = nil
  ARGV.delete_if {|arg|
    case arg
    when /\A--ruby=(.*)/
      @ruby = $1
      @ruby.gsub!(/^([^ ]*)/){File.expand_path($1)}
      @ruby.gsub!(/(\s+-I\s*)((?!(?:\.\/)*-(?:\s|\z))\S+)/){$1+File.expand_path($2)}
      @ruby.gsub!(/(\s+-r\s*)(\.\.?\/\S+)/){$1+File.expand_path($2)}
      true
    when /\A--sets=(.*)/
      tests = Dir.glob("#{File.dirname($0)}/test_{#{$1}}*.rb")
      puts tests.map {|path| File.basename(path) }.inspect
      true
    when /\A--dir=(.*)/
      dir = $1
      true
    when /\A(--stress|-s)/
      $stress = true
    when /\A(-q|--q(uiet))\z/
      quiet = true
      true
    when /\A(-v|--v(erbose))\z/
      @verbose = true
    when /\A(-h|--h(elp)?)\z/
      puts(<<-End)
Usage: #{File.basename($0, '.*')} --ruby=PATH [--sets=NAME,NAME,...]
        --sets=NAME,NAME,...        Name of test sets.
        --dir=DIRECTORY             Working directory.
                                    default: /tmp/bootstraptest.tmpwd
    -s, --stress                    stress test.
    -v, --verbose                   Output test name before exec.
    -q, --quiet                     Don\'t print header message.
    -h, --help                      Print this message and quit.
End
      exit true
    else
      false
    end
  }
  if tests and not ARGV.empty?
    $stderr.puts "--tests and arguments are exclusive"
    exit false
  end
  tests ||= ARGV
  tests = Dir.glob("#{File.dirname($0)}/test_*.rb") if tests.empty?
  pathes = tests.map {|path| File.expand_path(path) }

  unless quiet
    puts Time.now
    patchlevel = defined?(RUBY_PATCHLEVEL) ? " patchlevel #{RUBY_PATCHLEVEL}" : ''
    puts "Driver is ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}#{patchlevel}) [#{RUBY_PLATFORM}]"
    puts "Target is #{`#{@ruby} -v`.chomp}"
    puts
    $stdout.flush
  end

  in_temporary_working_directory(dir) {
    exec_test pathes
  }
end

def exec_test(pathes)
  @count = 0
  @error = 0
  @errbuf = []
  @location = nil
  pathes.each do |path|
    $stderr.print "\n#{File.basename(path)} "
    load File.expand_path(path)
  end
  $stderr.puts
  if @error == 0
    $stderr.puts "PASS #{@count} tests"
    exit true
  else
    @errbuf.each do |msg|
      $stderr.puts msg
    end
    $stderr.puts "FAIL #{@error}/#{@count} tests failed"
    exit false
  end
end

def assert_check(testsrc, message = '', opt = '')
  $stderr.puts "\##{@count} #{@location}" if @verbose
  result = get_result_string(testsrc, opt)
  check_coredump
  faildesc = yield(result)
  if !faildesc
    $stderr.print '.'
  else
    $stderr.print 'F'
    error faildesc, message
  end
rescue Exception => err
  $stderr.print 'E'
  error err.message, message
end

def assert_equal(expected, testsrc, message = '')
  newtest
  assert_check(testsrc, message) {|result|
    if expected == result
      nil
    else
      desc = "#{result.inspect} (expected #{expected.inspect})"
      pretty(testsrc, desc, result)
    end
  }
end

def assert_match(expected_pattern, testsrc, message = '')
  newtest
  assert_check(testsrc, message) {|result|
    if expected_pattern =~ result
      nil
    else
      desc = "#{expected_pattern.inspect} expected to be =~\n#{result.inspect}"
      pretty(testsrc, desc, result)
    end
  }
end

def assert_not_match(unexpected_pattern, testsrc, message = '')
  newtest
  assert_check(testsrc, message) {|result|
    if unexpected_pattern !~ result
      nil
    else
      desc = "#{unexpected_pattern.inspect} expected to be !~\n#{result.inspect}"
      pretty(testsrc, desc, result)
    end
  }
end

def assert_valid_syntax(testsrc, message = '')
  newtest
  assert_check(testsrc, message, '-c') {|result|
    result if /Syntax OK/ !~ result
  }
end

def assert_normal_exit(testsrc, message = '')
  newtest
  $stderr.puts "\##{@count} #{@location}" if @verbose
  faildesc = nil
  filename = make_srcfile(testsrc)
  `#{@ruby} -W0 #{filename}`
  if $?.signaled?
    signo = $?.termsig
    signame = Signal.list.invert[signo]
    sigdesc = "signal #{signo}"
    if signame
      sigdesc = "SIG#{signame} (#{sigdesc})"
    end
    faildesc = pretty(testsrc, "killed by #{sigdesc}", nil)
  end
  if !faildesc
    $stderr.print '.'
  else
    $stderr.print 'F'
    error faildesc, message
  end
rescue Exception => err
  $stderr.print 'E'
  error err.message, message
end

def assert_finish(timeout_seconds, testsrc, message = '')
  newtest
  $stderr.puts "\##{@count} #{@location}" if @verbose
  faildesc = nil
  filename = make_srcfile(testsrc)
  io = IO.popen("#{@ruby} -W0 #{filename}")
  pid = io.pid
  waited = false
  tlimit = Time.now + timeout_seconds
  while Time.now < tlimit
    if Process.waitpid pid, Process::WNOHANG
      waited = true
      break
    end
    sleep 0.1
  end
  if !waited
    Process.kill(:KILL, pid)
    Process.waitpid pid
    faildesc = pretty(testsrc, "not finished in #{timeout_seconds} seconds", nil)
  end
  io.close
  if !faildesc
    $stderr.print '.'
  else
    $stderr.print 'F'
    error faildesc, message
  end
rescue Exception => err
  $stderr.print 'E'
  error err.message, message
end

def flunk(message = '')
  newtest
  $stderr.print 'F'
  error message, ''
end

def pretty(src, desc, result)
  src = src.sub(/\A.*\n/, '')
  (/\n/ =~ src ? "\n#{adjust_indent(src)}" : src) + "  #=> #{desc}"
end

INDENT = 27

def adjust_indent(src)
  untabify(src).gsub(/^ {#{INDENT}}/o, '').gsub(/^/, '   ')
end

def untabify(str)
  str.gsub(/^\t+/) {' ' * (8 * $&.size) }
end

def make_srcfile(src)
  filename = 'bootstraptest.tmp.rb'
  File.open(filename, 'w') {|f|
    f.puts "GC.stress = true" if $stress
    f.puts "print(begin; #{src}; end)"
  }
  filename
end

def get_result_string(src, opt = '')
  if @ruby
    filename = make_srcfile(src)
    begin
      `#{@ruby} -W0 #{opt} #{filename}`
    ensure
      raise CoreDumpError, "core dumped" if $? and $?.coredump?
    end
  else
    eval(src).to_s
  end
end

def newtest
  @location = File.basename(caller(2).first)
  @count += 1
  cleanup_coredump
end

def error(msg, additional_message)
  @errbuf.push "\##{@count} #{@location}: #{msg}  #{additional_message}"
  @error += 1
end

def in_temporary_working_directory(dir)
  if dir
    Dir.mkdir dir
    Dir.chdir(dir) {
      yield
    }
  else
    Dir.mktmpdir("bootstraptest.tmpwd") {|d|
      Dir.chdir(d) {
        yield
      }
    }
  end
end

def cleanup_coredump
  FileUtils.rm_f 'core'
  FileUtils.rm_f Dir.glob('core.*')
  FileUtils.rm_f @ruby+'.stackdump' if @ruby
end

class CoreDumpError < StandardError; end

def check_coredump
  if File.file?('core') or not Dir.glob('core.*').empty? or
      (@ruby and File.exist?(@ruby+'.stackdump'))
    raise CoreDumpError, "core dumped"
  end
end

main
