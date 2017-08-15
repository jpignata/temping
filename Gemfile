source "https://rubygems.org"

gemspec

rails_version = ENV["RAILS_VERSION"] || "default"
version = case rails_version
          when "master"
            { github: "rails/rails" }
          when "default"
            ">= 4.2.0"
          else
            "~> #{rails_version}"
          end

gem "activerecord", version
gem "activesupport", version
