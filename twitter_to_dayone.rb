#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'time'
require 'twitter'
require 'nokogiri'
require 'nokogiri-plist'
require 'erb'
require_relative 't2d1-config'

AppRoot = File.expand_path(File.dirname(__FILE__))

if File.exists? File.join(AppRoot, "latest_tweet")
  since_id = File.open(File.join(AppRoot, "latest_tweet"), "r").read.to_i
else 
  since_id = 0
end

options = Hash.new
options[:since_id] = since_id unless since_id == 0
tweets = Array.new
temp_id = 0

def get_more_tweets(options)
  # get the most recent tweets, but not before since_id
  statuses = Twitter.user_timeline(@username, options)
  favorites = Twitter.favorites(@username, options)

  statuses.each { |st| 
    # translate the time into local time
    time = Time.parse(st.created_at.to_s)
    time = time.getlocal(st.user.utc_offset)
    st.instance_variable_set(:@time, time)
    #tweets show the time
    st.instance_variable_set(:@type, time.strftime("%R")) 
  }
  favorites.each { |st| 
    # translate the time into local time
    time = Time.parse(st.created_at.to_s)
    time = time.getlocal(st.user.utc_offset)
    st.instance_variable_set(:@time, time) 
    # favorites show a star, and the tweeter's username
    st.text.prepend('☆ ')
    st.instance_variable_set(:@type, st.user.screen_name) 
  }

  # merge the lists and sort by time created
  statuses += favorites
  statuses.sort! { |a,b| b.id <=> a.id }

  return statuses
end

# grab most recent tweets
statuses = get_more_tweets(options)

# check if there are new tweets
unless statuses.length == 0
  statuses.each do |st|
    break if st.created_at < @time_limit
    # save just the information we need
    tweets << Hash[:date => st.created_at, :text => st.text, :id => st.id, :user => st.user.screen_name, :type => st.instance_variable_get(:@type)]
    # keep track of the oldest tweet we've seen so far
    temp_id = st.id
  end
  
  # check if we're still missing some tweets
  while temp_id > since_id
    options[:max_id] = temp_id-1
    # grab more tweets between since_id and the batch we just got
    statuses = get_more_tweets(options)

    # if there were no more tweets left, or we've gone back far enough, we're done
    break if statuses.length == 0 or statuses[0].created_at < @time_limit
    # process each tweet
    statuses.each do |st|
      break if st.created_at < @time_limit
      # save just the information we need
      tweets << Hash[:date => st.instance_variable_get(:@time), :text => st.text, :id => st.id, :user => st.user.screen_name, :type => st.instance_variable_get(:@type)]
      # keep track of the oldest tweet we've seen so far
      temp_id = st.id
    end 
  end
end

if tweets.length > 0
  # grab the most recent tweet so we can use it as since_id next time
  first = tweets[0]

  # dump the data into DayOne
  # loop oldest first
  tweets.reverse_each do |tweet| 
    date = Time.parse(tweet[:date].to_s)
    uuid = "TWITTER" + "000000000000000" + date.strftime("%Y%m%d")
    text = "* #{tweet[:text]} [(#{tweet[:type]})](https://twitter.com/#!/#{tweet[:user]}/status/#{tweet[:id]})"

    filepath = "#{@dayone_journal_path}/entries/#{uuid}.doentry"

    if File.exists? filepath
      plist = Nokogiri::PList(open(filepath))
      plist['Entry Text'] += "\n\n#{text}"
      File.open(filepath, "w+") {|f| f.write(plist.to_plist_xml) }
    else 
      #make a new entry file
      created_time = date.strftime("%FT00:00:00Z")
      text = "Tweets for #{date.strftime('%F')}\n\n" + text
      File.open(filepath, "w+") {|f| f.write(@template.result(binding)) }
    end
  end
  # save the latest tweet's id 
  File.open(File.join(AppRoot, "latest_tweet"), "w+") {|f| f.write(first[:id]) }
  puts "#{Time.now}: Posted #{tweets.length} new tweets to DayOne. Last imported tweet_id: #{first[:id]}"

else 
  puts "#{Time.now}: No new tweets. Last imported tweet_id: #{since_id}"
end