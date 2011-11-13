$:.push File.expand_path("../lib", __FILE__)

require "temping"

Gem::Specification.new do |s|
  s.name        = "temping"
  s.version     = Temping::VERSION
  s.authors     = ["John Pignata"]
  s.email       = "john@pignata.com"
  s.homepage    = "http://github.com/jpignata/temping"
  s.summary     = "Create temporary table-backed ActiveRecord models for use in tests"

  s.add_dependency "activerecord", "~> 3.1.1"
  s.add_dependency "activesupport", "~> 3.1.1"
  s.add_dependency "sqlite3", "~> 1.3.4"

  s.add_development_dependency "rspec", "~> 2.7.0"
end
