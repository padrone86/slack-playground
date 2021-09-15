require 'time'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_APP_TOKEN']
end

client = Slack::Web::Client.new

# UNIX TIME に変換
latest_ts = Time.parse(ENV['LATEST']).to_i
oldest_ts = Time.parse(ENV['OLDEST']).to_i

# TODO: 存在する全パブリックチャンネルでループ
channel = '#times-devaoki'

# TODO: カーソルでページネーション対応してループ
response = client.conversations_history(channel: channel, latest: latest_ts, oldest: oldest_ts, limit: 5)

# TODO: レスポンス解析して集計しましょうね〜

# debug
pp response
