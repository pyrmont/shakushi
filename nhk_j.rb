require_relative 'shakushi'

filtrate = Shakushi::Base.new(
  feed_attributes: {
    title: 'NHK Radio News (Japanese)',
    itunes: {
      image: 'nhk.jpg',
    }
  },
  parent_url: 'http://filtrates.inqk.net',
  content_dir: 'nhk-japanese',
  target_url: 'http://www.nhk.or.jp/r-news/podcast/nhkradionews.xml',
  filters: [
    { tag: 'title', pattern: /夜7|７時/ }
  ]
)

puts filtrate.output_rss