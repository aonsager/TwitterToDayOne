TwitterToDayOne
===============

Pull recent tweets into DayOne.app
After entering your twitter username, your tweets and the tweets you favorite will be entered in DayOne as journal entries.
Updates from the same day will be combined into a single digest for that day

==Setup==

Rename the config file as "t2d1-config.rb" and enter your credentials.
Twitter OAuth is required

Update the plist file with the path to your ruby runtime and the location where you saved the ruby script.
Then place the plist file in ~/Library/LaunchAgents to have it run once per hour, starting the next time you reboot your system.