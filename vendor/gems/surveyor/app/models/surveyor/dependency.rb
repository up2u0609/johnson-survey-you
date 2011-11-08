require "surveyor/models/dependency_methods"
module Surveyor
  class Dependency < ActiveRecord::Base
    unloadable
    include Surveyor::Models::DependencyMethods
  end
end
