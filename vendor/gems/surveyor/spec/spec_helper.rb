# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path(File.join(File.dirname(__FILE__),'..','spec', 'dummy' ,'config','environment'))
require 'rspec/rails'
require "database_cleaner"
require "forgery"
require 'machinist/active_record'
require 'sham'

RSpec.configure do |config|
  config.mock_with :rspec
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.include Surveyor::Engine.routes.url_helpers
end


DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean
require File.expand_path(File.dirname(__FILE__) + '/blueprints')
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
