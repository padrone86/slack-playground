require 'csv'
require 'time'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_USER_TOKEN']
end

client = Slack::Web::Client.new

post_channel = ENV['POST_CHANNEL']

# UNIX TIME に変換
latest_ts = Time.parse(ENV['LATEST']).to_i
oldest_ts = Time.parse(ENV['OLDEST']).to_i

channels = []
result_array = []

list_channels_options = {types: 'public_channel', cursor: nil, limit: 1000}
loop {
  response = client.conversations_list(list_channels_options)
  channels.concat(response.channels.map {|channel| '#' + channel.name})

  break if response.response_metadata.next_cursor.empty?
  sleep 1
  list_channels_options.update(cursor: response.response_metadata.next_cursor)
  # puts "next: " + list_channels_options[:cursor]
}
channels.sort

channels.each_with_index {|channel, index|
  puts("channel: #{channel}, #{index + 1}/#{channels.count}")
  channel_result = {}
  message_options = {channel: channel, cursor: nil, latest: latest_ts, oldest: oldest_ts, limit: 1000}
  loop {
    response = client.conversations_history(message_options)

    reactions = response.messages
                  .filter { |msg| msg.reactions }
                  .map { |msg| {}.merge(*msg.reactions.map {
                    |val| {val['name'] => val['count'] }
                  })}
    channel_result = channel_result.merge(*reactions) { |_key, old_val, new_val| old_val + new_val }

    break if response.response_metadata.nil? 

    sleep 1
    message_options.update(cursor: response.response_metadata.next_cursor)
    # puts "next: " + message_options[:cursor]
  }
  result_array.push(channel_result)
}

results = {}.merge(*result_array) { |_key, old_val, new_val| old_val + new_val }.sort_by { |_, v| -v}

# CSV
CSV.open('report.csv', 'w',:force_quotes => true){ |writer|
  writer << ["emoji", "count"]
	results.each{ |row|
  	writer << row
  }
}

post_messages = results.first(20).map.with_index { |record, idx| "#{idx + 1} :#{record[0]}:\t#{record[1]}" }
client.chat_postMessage(channel: post_channel, text: post_messages.join("\n"))
