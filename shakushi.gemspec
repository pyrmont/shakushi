
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shakushi/version"

Gem::Specification.new do |spec|
  spec.name          = "shakushi"
  spec.version       = Shakushi::VERSION
  spec.authors       = ["Michael Camilleri"]
  spec.email         = ["dev@inqk.net"]

  spec.summary       = %q{Filter and combine XML feeds.}
  spec.description   = %q{Shakushi provides an easy way to filter and combine XML feeds.}
  spec.homepage      = "https://github.con/pyrmont/shakushi/"
  spec.license       = "Unlicense"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_runtime_dependency "taipo", "~> 1.3.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.10.3"
  spec.add_development_dependency "minitest-reporters", "~> 1.1.19"
  spec.add_development_dependency "shoulda-context", "~> 1.2.0"
  spec.add_development_dependency "simplecov", "~> 0.15.1"
  spec.add_development_dependency "yard", "~> 0.9.12"
end
