require_relative 'shakushi'

get_lowe = Shakushi::Base.new(
  title: 'Get Lowe',
  description: "Zach Lowe's ESPN columns.",
  parent_url: 'http://filtrates.inqk.net/',
  local_dir: 'get-lowe',
  target_url: 'http://www.espn.com/espn/rss/nba/news',
  filters: [
    { attribute: 'title', pattern: /^Lowe:/ }
  ],
  match_all: false
)

get_lowe.output_rss