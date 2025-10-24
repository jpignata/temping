appraise "activerecord-6.0" do
  gem "activerecord", "~> 6.0.0"
  gem "activesupport", "~> 6.0.0"
  gem "sqlite3", "~> 1.4", platforms: [:ruby, :truffleruby]
  gem "concurrent-ruby", "1.3.4" # https://stackoverflow.com/a/79361034
end

appraise "activerecord-6.1" do
  gem "activerecord", "~> 6.1.0"
  gem "activesupport", "~> 6.1.0"
  gem "sqlite3", "~> 1.4", platforms: [:ruby, :truffleruby]
  gem "concurrent-ruby", "1.3.4" # https://stackoverflow.com/a/79361034
end

appraise "activerecord-7.0" do
  gem "activerecord", "~> 7.0.0"
  gem "activesupport", "~> 7.0.0"
  gem "sqlite3", "~> 1.6", platforms: [:ruby, :truffleruby]
  gem "standard", "~> 1.31"
  gem "concurrent-ruby", "1.3.4" # https://stackoverflow.com/a/79361034

  install_if '-> { RUBY_VERSION >= "3.4.0" }' do
    gem "mutex_m" # mutex_m is no longer a part of the default gems
  end
end

appraise "activerecord-7.1" do
  gem "activerecord", "~> 7.1.0"
  gem "activesupport", "~> 7.1.0"
  gem "sqlite3", "~> 1.6", platforms: [:ruby, :truffleruby]
  gem "standard", "~> 1.31"
end

appraise "activerecord-7.2" do
  gem "activerecord", "~> 7.2.0"
  gem "activesupport", "~> 7.2.0"
  gem "sqlite3", "~> 2.0", platforms: [:ruby, :truffleruby]
  gem "standard", "~> 1.31"
end

appraise "activerecord-8.0" do
  gem "activerecord", "~> 8.0.0"
  gem "activesupport", "~> 8.0.0"
  gem "sqlite3", "~> 2.1", platforms: [:ruby, :truffleruby]
  gem "standard", "~> 1.31"
end

appraise "activerecord-8.1" do
  gem "activerecord", "~> 8.1.0"
  gem "activesupport", "~> 8.1.0"
  gem "sqlite3", "~> 2.1", platforms: [:ruby, :truffleruby]
  gem "standard", "~> 1.31"
end
