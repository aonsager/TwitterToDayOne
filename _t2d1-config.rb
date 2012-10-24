Twitter.configure do |config|
  config.consumer_key = "CONSUMERKEY"
  config.consumer_secret = "CONSUMERSECRET"
  config.oauth_token = "OAUTHTOKEN"
  config.oauth_token_secret = "OAUTHTOKENSECRET"
end

@username = "TWITTERUSERNAME"

@dayone_journal_path = "/Users/USERNAME/Dropbox/Apps/Day One/Journal.dayone"

# only get results for the past week. change as needed
@time_limit = Time.now - 60*60*24*7

# template for DayOne entries
@template = ERB.new <<-XMLTEMPLATE
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Creation Date</key>
      <date><%= created_time %></date>
      <key>Entry Text</key>
      <string><%= text %></string>
      <key>Starred</key>
      <false/>
      <key>UUID</key>
      <string><%= uuid %></string>
    </dict>
    </plist>
    XMLTEMPLATE