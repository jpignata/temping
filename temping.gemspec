Gem::Specification.new do |s|
  s.name = "temping"
  s.version = "4.2.0"
  s.authors = ["John Pignata"]
  s.email = "john@pignata.com"
  s.homepage = "https://github.com/jpignata/temping"
  s.summary = "Create temporary table-backed ActiveRecord models for use in tests"
  s.license = "MIT"

  s.files = Dir["lib/**/*.rb"]

  s.required_ruby_version = ">= 2.5"

  s.add_dependency "activerecord", ">= 6.0", "< 8.1"
  s.add_dependency "activesupport", ">= 6.0", "< 8.1"

  s.add_development_dependency "appraisal", "~> 2.5"
end
