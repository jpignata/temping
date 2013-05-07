Gem::Specification.new do |s|
  s.name        = "temping"
  s.version     = "3.2.0"
  s.authors     = ["John Pignata"]
  s.email       = "john@pignata.com"
  s.homepage    = "http://github.com/jpignata/temping"
  s.summary     = "Create temporary table-backed ActiveRecord models for use in tests"

  s.files = ["lib/temping.rb"]

  s.add_dependency "activerecord", ">= 3.1"
  s.add_dependency "activesupport", ">= 3.1"
  s.add_dependency "sqlite3", "~> 1.3.7"

  s.add_development_dependency "rspec", ">= 2.13.0"
  s.add_development_dependency "rake", ">= 10.0.4"
end
