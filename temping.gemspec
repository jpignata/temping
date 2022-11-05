Gem::Specification.new do |s|
  s.name = "temping"
  s.version = "3.10.0"
  s.authors = ["John Pignata"]
  s.email = "john@pignata.com"
  s.homepage = "http://github.com/jpignata/temping"
  s.summary = "Create temporary table-backed ActiveRecord models for use in tests"
  s.license = "MIT"

  s.files = ["lib/temping.rb"]

  s.required_ruby_version = ">= 2.0"

  s.add_dependency "activerecord", ">= 5.2", "< 7.1"
  s.add_dependency "activesupport", ">= 5.2", "< 7.1"

  s.add_development_dependency "appraisal"

  if RUBY_PLATFORM.match?(/java/)
    s.add_development_dependency "activerecord-jdbcsqlite3-adapter", ">= 60.0"
    s.add_development_dependency "activerecord-jdbcpostgresql-adapter", ">= 60.0"
    s.add_development_dependency "activerecord-jdbcmysql-adapter", ">= 60.0"
  else
    s.add_development_dependency "sqlite3", ">= 1.3", "< 2.0"
    s.add_development_dependency "pg", ">= 1.2", "< 2.0"
    s.add_development_dependency "mysql2", "~> 0.5"
  end

  s.add_development_dependency "rspec", "~> 3.12"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "simplecov", "~> 0.18"
  s.add_development_dependency "standard"
end
