require "surveyor/models/validation_condition_methods"
module Surveyor
  class ValidationCondition < ActiveRecord::Base
    unloadable
    include Surveyor::Models::ValidationConditionMethods
  end
end
