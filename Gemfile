source "https://rubygems.org"

gemspec

gem "rspec", "~> 3.13"
gem "rake", "~> 13.0"
gem "simplecov", "~> 0.21"
gem "standard", ">= 0.0.1", "< 2.0"

platforms :jruby do
  gem "activerecord-jdbcsqlite3-adapter", ">= 60.0"
  gem "activerecord-jdbcpostgresql-adapter", ">= 60.0"
  gem "activerecord-jdbcmysql-adapter", ">= 60.0"
end
