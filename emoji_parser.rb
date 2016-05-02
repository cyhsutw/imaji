require 'httparty'
require 'plist'

all_emojis = JSON.parse(HTTParty.get('https://raw.githubusercontent.com/muan/emojilib/master/emojis.json'))

mapping = {}

all_emojis.each do |_, value|
  emoji = value['char']
  next if emoji.nil? || emoji.empty?

  value['keywords'].each do |keyword|
    next unless mapping[keyword].nil?
    mapping[keyword] = emoji
  end
end

puts mapping.to_plist
