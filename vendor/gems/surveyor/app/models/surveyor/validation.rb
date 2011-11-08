require "surveyor/models/validation_methods"
module Surveyor
  class Validation < ActiveRecord::Base
    unloadable
    include Surveyor::Models::ValidationMethods
  end
end
