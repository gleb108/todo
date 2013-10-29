#!/usr/bin/ruby 


require 'optparse'
require 'colorize'
require 'readline'
require 'openssl'
require 'digest/sha2'
require 'base64'
require 'yaml'



options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: todo.rb [options]'

  #default options
  options[:config] = File.join(ENV['HOME'], '.todorc'); 

  opts.on('-v', '--verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end
 
  opts.on('-c', '--config CONFIG', String, 'Configuration file (default is $HOME/.todorc') do |c|
    options[:config] = c
  end 

  opts.on('-f', '--file TODO_LIST', String, 'Todo file (default is $HOME/todo.txt') do |f|
    options[:file] = f
  end 

  opts.on('-l', '--limit REGEXP', String, 'Show only items that match REGEXP') do |l|
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

  opts.on('--encrypt FILE', String, 'Encrypt file to STDIN') do |encrypt|
    options[:encrypt] = encrypt
  end

  opts.on('--decrypt ENCRYPTED_FILE', String, 'Decrypt encrypted file to STDIN') do |decrypt|
    options[:decrypt] = decrypt
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end

end.parse!

#Reading config file
puts "Using config #{options[:config]}" if options[:verbose]
config = YAML.load_file(options[:config])

if config['editor']
  editor = config['editor']
elsif ENV['EDITOR'] 
  editor = ENV['EDITOR'] 
else 
  editor = '/usr/bin/vi'   
end
puts "editor = #{editor}" if options[:verbose]

if (options[:file])
  todo_list = options[:file]
elsif config['todo_list']
  todo_list = config['todo_list']
else 
  todo_list = File.join(ENV['HOME'], 'todo.txt'); 
end
puts "todo_list = #{todo_list}" if options[:verbose]

unless File.exist?(todo_list) 
  file = File.open(todo_list, File::WRONLY|File::TRUNC|File::CREAT, 0600)
  file.close 
end

done_list=config['done_list'] if config['done_list']
puts "done_list = #{done_list}" if options[:verbose]

if config['tmp']
  tmp = config['tmp']
else 
  tmp = '/tmp/todo.tmp'
end

ENCRYPTION = config['encryption']
puts "encryption = true" if options[:verbose]

my_key = config['my_key']
IV = config['iv']
clr_deadline = config['clr_deadline']
clr_pri=config['clr_pri']


def get_encrypted_items (file)
  todo_list = File.open(file, 'r')
  aes = OpenSSL::Cipher.new("AES-256-CFB") if ENCRYPTION
  items=[]
  IO.foreach(file) do |line|
    line.chomp!
    aes.decrypt
    aes.key = KEY
    aes.iv = IV
    tmp=Base64.strict_decode64(line)
    decrypted_line = aes.update(tmp) + aes.final
    items << decrypted_line
  end
  return items
end

def get_plain_items (file)
  todo_list = File.open(file, 'r')
  items=[]
  IO.foreach(file) do |line|
    line.chomp!
    items << line
  end
  return items
end


def encrypt_item (item)
  aes = OpenSSL::Cipher.new("AES-256-CFB")
  aes.encrypt
  aes.key = KEY
  aes.iv = IV
  encrypted_item = aes.update(item) + aes.final
  return Base64.strict_encode64(encrypted_item)
end


if ENCRYPTION or options[:decrypt] or options[:encrypt]
  sha256 = Digest::SHA2.new(256)
  KEY = sha256.digest(my_key)
end



if options[:decrypt] 
  lines = get_encrypted_items(options[:decrypt])
  lines.each do |line|
    puts line
  end
  exit;
end

if options[:encrypt] 
  lines = get_plain_items(options[:encrypt])
  lines.each do |line|
    puts encrypt_item(line)
  end
  exit;
end



if options[:edit] 
   if ENCRYPTION 
     tmp_file = File.open(tmp, File::WRONLY|File::TRUNC|File::CREAT, 0600)
     lines = get_encrypted_items(todo_list)
       lines.each do |line|
       tmp_file.puts line
     end
     tmp_file.close

     system("#{editor} #{tmp}")

     lines = get_plain_items(tmp)
     todofile = File.open(todo_list, 'w+')
     lines.each do |line|
         todofile.puts encrypt_item(line);
     end
     todofile.close
   else 
     exec("#{editor} #{todo_list}") 
   end
end

if options[:add] 
  stty_save = `stty -g`.chomp
  begin
    line = Readline.readline('> ', true)
  rescue Interrupt => e
    system('stty', stty_save) # Restore
    exit
  end
  todofile = File.open(todo_list, 'a')
  todofile.puts encrypt_item(line);
  todofile.close
end

if options[:done]
 
  if ENCRYPTION 
    lines = get_encrypted_items(todo_list)
  else 
    lines = get_plain_items(todo_list)
  end

  if options[:done].to_i <=0 or options[:done].to_i > lines.size
     puts "invalid option:  --done #{options[:done]}"
     exit
  end 

  file = File.open(todo_list, 'w+')
  n=1
  lines.each do |line|
    if n == options[:done].to_i
      donefile = File.open(done_list, File::WRONLY|File::APPEND|File::CREAT, 0600)
      item = Time.now.to_s + ' ' + line 
      if ENCRYPTION 
        donefile.puts encrypt_item(item)
      else 
        donefile.puts item
      end
      donefile.close
      puts "Item #{options[:done]} was moved to the #{done_list}";
    else 
      if ENCRYPTION
        file.puts encrypt_item(line)
      else 
        file.puts line
      end
    end
    n=n+1
  end
end

regexp = Regexp.compile (options[:limit]) if options[:limit]


n=0
priority_list={}
deadline_list={}
list={}

if ENCRYPTION
  lines = get_encrypted_items(todo_list)
else 
  lines = get_plain_items(todo_list)
end

lines.each do |line|
  line.chomp!
  n=n+1
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



