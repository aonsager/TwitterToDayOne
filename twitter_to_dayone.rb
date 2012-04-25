#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'

if File.exists? "latest_tweet"
  since_id = File.open("latest_tweet", "r").read.to_i
else 
  since_id = 0
end

# only get results for the past week. change as needed
time_limit = Time.now - 60*60*24*7

username = "insert_username_here"
options = Hash.new
options[:since_id] = since_id unless since_id == 0;
tweets = Array.new
temp_id = 0

# get the most recent tweets, but not before since_id
statuses = Twitter.user_timeline(username, options)

# grab the most recent tweet so we can use it as since_id next time
first = statuses[0]

# check if there are new tweets
unless first.nil?
  statuses.each do |st|
    break if st.created_at < time_limit
    tweets << Hash[:date => st.created_at, :text => st.text, :id => st.id, :user => st.user.screen_name]
    # keep track of the oldest tweet we've seen so far
    temp_id = st.id
  end
  
  # check if we're still missing some tweets
  while temp_id > since_id
    options[:max_id] = temp_id-1
    # grab 20 more tweets between since_id and the batch we just got
    statuses = Twitter.user_timeline(username, options)
    # if there were no more tweets left, or we've gone back far enough, we're done
    break if statuses.length == 0 or statuses[0].created_at < time_limit
    # process each tweet
    statuses.each do |st|
      break if st.created_at < time_limit
      tweets << Hash[:date => st.created_at, :text => st.text, :id => st.id, :user => st.user.screen_name]
      # keep track of the oldest tweet we've seen so far
      temp_id = st.id
    end 
  end
  
  # dump the data into DayOne
  tweets.each do |tweet|
    text = tweet[:text]
    text += " [(tweet)](https://twitter.com/#!/#{tweet[:user]}/status/#{tweet[:id]})"
    %x{echo "#{text}" | /usr/local/bin/dayone -d="#{tweet[:date]}" new}
  end
  
  # save the latest tweet's id as since_id 
  File.open("latest_tweet", "w") {|f| f.write(first.id) }
else
  puts 'No new tweets'
end