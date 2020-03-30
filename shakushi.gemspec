# frozen_string_literal: true

require "./lib/shakushi/version"

Gem::Specification.new do |s|
  s.name = "shakushi"
  s.version = Shakushi::VERSION
  s.authors = ["Michael Camilleri"]
  s.email = ["mike@inqk.net"]
  s.summary = "A library for filtering and manipulating RSS/Atom feeds."
  s.description = <<-desc.strip.gsub(/\s+/, " ")
    Shakushi is a library for filtering and manipulating RSS/Atom feeds.
  desc
  s.homepage = "https://github.com/pyrmont/shakushi/"
  s.licenses = "Unlicense"
  s.required_ruby_version = ">= 2.5"

  s.files = Dir["Gemfile", "LICENSE", "README.md",
                "shakushi.gemspec", "lib/shakushi.rb", "lib/**/*.rb"]
  s.require_paths = ["lib"]

  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.add_runtime_dependency "nokogiri"

  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  s.add_development_dependency "warning"
end
