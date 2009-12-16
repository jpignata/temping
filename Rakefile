require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "temping"
    gem.summary = "Create temporary table-backed ActiveRecord models for use in tests"
    gem.homepage = "http://github.com/jpignata/temping"
    gem.email = "john.pignata@gmail.com"
    gem.authors = ["John Pignata"]
    gem.add_dependency "rails", ">= 2.3.3"
    gem.add_development_dependency "rspec", "1.2.9"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end