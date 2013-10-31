todo
====

CLI interface for todo.txt 

I like todo.txt_cli by ginatrapani https://github.com/ginatrapani/todo.txt-cli,
but I need some additional features. So I decided to write my own client.

 * This client supports readline features for adding new items.
 * This client can call external editor for edit items 
 * This client support fast and strong crypto. This is useful where you sync list via clouds.


== HOWTO use crypto 

I never plan something evil but I don't like the idea that companies can use my private todo list.
This why I like to encrypt it before to sync it via clouds. 
First I tried to use shell wrapper with EncFS but it worked too slow, so I had to implement crypto inside the client.

If you want to use crypto you need to edit your .todorc config.  
Set 
encryption: true
my_key: "My passphrase"
iv: "0.67379912027482785"

Key and iv must be unique. You can use command ruby -e 'puts rand.to_s' to generate iv

Copy this .todorc config to another computes where you're going to use this.

Now every new items in todo list and done list are going to be encrypted.
Warning! All items are not going to be encrypted. If you want to encrypt them too you should use --encrypt option.
For instance todo.rb --encrypt my_old_plain_text_todo_list > my_new_encrypted_todo_list

Also you can use --decrypt option to see encrypted file.


