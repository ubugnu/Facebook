# Facebook 'name by phone number' vulnerability

Hi everyone,

In order to show that the last security flaw that [I discovered](http://redd.it/26uysm) is really a security flaw (unlike what the sec guys of facebook [are saying](http://www.reddit.com/r/hacking/comments/26uysm/get_name_by_telephone_number_thank_you_fb/chv86bp)), I've written a small [bash script](https://github.com/ubugnu/Facebook/blob/master/scrape_fb.sh) that:

* Generates random phone number (you chose the format) 
* Then looks up for the corresponding name, you must have Tor installed, as well as wget, curl and torsocks
* You can run multiple instances of that script, do not use excessive number of tor instances when the script will ask for a port range (10 to 20 ports is good), also do not run excessive number of instances (the number of the ports divided by 2 is good enough)
* To terminate each instance, press Ctrl-C, it will then ask you if you want to kill all tor instances, say "no" if you have other instances of the script runing
* It will than outputs [ix.io](ix.io) link where have been uploaded found number
* You can paste the link here (in reddit) if you wish so we can construct a big database to show to FB that it is really a security issue ;-).

enjoy
