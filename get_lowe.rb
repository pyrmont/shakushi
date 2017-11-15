require_relative 'shakushi'

filtrate = Shakushi::Base.new(
  feed_attributes: {
    title: 'Get Lowe',
    description: "Zach Lowe's ESPN columns."
  },
  parent_url: 'http://filtrates.inqk.net',
  content_dir: 'get-lowe',
  target_url: 'http://www.espn.com/espn/rss/nba/news',
  filters: [
    { tag: 'title', pattern: /^Lowe:/ }
  ],
  match_all: false
)

puts filtrate.output_rss