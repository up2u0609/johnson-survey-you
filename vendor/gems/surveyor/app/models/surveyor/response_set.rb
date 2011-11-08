require "surveyor/models/response_set_methods"
module Surveyor
  class ResponseSet < ActiveRecord::Base
    unloadable
    include Surveyor::Models::ResponseSetMethods
  end
end
