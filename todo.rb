#!/usr/bin/ruby 

#coloros for priorities
clr_pri = {
  'A' => :red,
  'B' => :red,
  'C' => :lignt_red,
  'D' => :yellow,
  'E' => :yellow,
  'F' => :light_yellow,
  'G' => :green,
  'H' => :green,
  'I' => :light_green,
  'J' => :cyan,
  'K' => :cyan,
  'L' => :light_cyan,
  'M' => :blue,
  'N' => :blue,
  'O' => :light_blue,
  'P' => :magenta,
  'Q' => :magenta,
  'R' => :light_magenta,
  'S' => :white,
  'T' => :white,
  'U' => :white,
  'V' => :light_yellow,
  'W' => :light_blue,
  'X' => :light_green,
  'Y' => :light_cyan,
  'Z' => :light_magenta,
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

  opts.on('-l', '--limit REGEXP', String, 'Show only item which match REGEXP') do |l|
    options[:limit] = l
  end 

  opts.on('-e', '--edit', 'Edit todo list with your favorite editor (use "export EDITOR=..."') do |e|
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
      donefile = File.open(done_list, File::WRONLY|File::APPEND|File::CREAT, 0600)
      donefile.puts "#{Time.now} #{line}"
      donefile.close
      puts "Item #{options[:done]} was moved to the #{done_list}";
    else 
      file.puts line
    end
    n=n+1
  end
end

regexp = Regexp.compile (options[:limit]) if options[:limit]


n=0
priority_list={}
deadline_list={}
list={}
IO.foreach(options[:file]) do |line|
  n=n+1
  line.chomp!
  next if line =~ /^$/

  if regexp 
      next unless line =~ regexp
  end 

  case line.to_s 
    when /^(\([A-Z]\)\s)?\d{4}-\d{2}-\d{2}\s/
       deadline_list.[]=(n, line.colorize(clr_deadline).underline)
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


