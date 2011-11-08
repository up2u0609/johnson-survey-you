require "surveyor/models/dependency_condition_methods"
module Surveyor
  class DependencyCondition < ActiveRecord::Base
    unloadable
    include Surveyor::Models::DependencyConditionMethods
  end
end
