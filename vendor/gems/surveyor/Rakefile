require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "surveyor"
  gem.summary = "surveyor"
  gem.description = "surveyor"
  gem.version = "0.0.2"
  gem.email = "johnson@secondbureau.com"
  gem.authors = ["johnson"]
  gem.add_dependency 'haml'
  gem.add_dependency 'sass'
  gem.add_dependency 'fastercsv'
  gem.add_dependency 'formtastic'
  gem.add_dependency 'uuid'
  gem.add_development_dependency "yard", ">= 0"
  gem.files = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*" , "{db}/**/*"]
end
Jeweler::RubygemsDotOrgTasks.new
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
