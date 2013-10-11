#!/usr/bin/ruby 

#coloros for priorities
clr_pri = {
  'A' => :red,
  'B' => :blue,
  'C' => :green,
  'D' => :yellow,
  'E' => :cyan,
  'F' => :white,
  'G' => :light_blue,
  'H' => :light_cyan,

}

#colors to deadlines
clr_deadline = :red

#editor 
if ENV['EDITOR']
   editor = ENV['EDITOR'];
else 
   editor = '/usr/bin/vi'   
end

#done list
done_list = ENV['HOME'] + '/done.txt';




require 'optparse'
require 'colorize'
require 'readline'


options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: todo.rb [options]'

  #default options
  options[:file] = File.join(ENV['HOME'], 'todo.txt'); 

  opts.on('-v', '--verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end
 
  opts.on('-f', '--file TODO_LIST', String, 'Todo file (default is $HOME/todo.txt') do |f|
    options[:file] = f
  end 

  opts.on('-e', '--edit', 'Edit todo list') do |e|
    options[:edit] = e
  end

  opts.on('-a', '--add', 'Add new item to the list') do |a|
    options[:add] = a
  end

  opts.on('-d', '--done LINE_NUMBER', String, 'Move the item to "done" list $HOME/done.txt') do |d|
    options[:done] = d
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end

  opts.on_tail('--version', 'Show version') do
    puts OptionParser::Version.join('.')
    exit
  end


end.parse!

if options[:verbose] 
  p options
  p ARGV
end

if options[:edit] 
   exec("#{editor} #{options[:file]}")
end

if options[:add] 
  stty_save = `stty -g`.chomp
  begin
    line = Readline.readline('> ', true)
  rescue Interrupt => e
    system('stty', stty_save) # Restore
    exit
  end
  todofile = File.open(options[:file], 'a')
  todofile.puts line
  todofile.close
end

if options[:done]

  lines = IO.readlines(options[:file])

  if options[:done].to_i <=0 or options[:done].to_i > lines.size
     puts "invalid option:  --done #{options[:done]}"
     exit
  end 

  file = File.open(options[:file], 'w+')
  n=1
  lines.each do |line|
    if n == options[:done].to_i
      donefile = File.open(done_list, File::WRONLY|File::CREAT, 0600)
      donefile.puts line
      donefile.close
      puts "Item #{options[:done]} was moved to the #{done_list}";
    else 
      file.puts line
    end
    n=n+1
  end
end



n=0
priority_list={}
deadline_list={}
list={}
IO.foreach(options[:file]) do |line|
  line.chomp!
  next if line =~ /^$/
  n=n+1
  case line.to_s 
    when /^(\([A-Z]\)\s)?\d{4}-\d{2}-\d{2}\s/
       deadline_list.[]=(n, line.colorize(clr_deadline))
    when /^\(([A-Z])\)\s/ 
       priority_list.[]=(n, line.colorize(clr_pri[$1]))
    else 
       list.[]=(n, line)
  end
end


priority_list.invert.sort.each do |line, n|
  puts "#{n} #{line}"
end

deadline_list.invert.sort.each do |line, n|
  puts "#{n} #{line}"
end

list.sort.each do |n, line|
  puts "#{n} #{line}"
end


