require "surveyor/models/response_methods"
module Surveyor
  class Response < ActiveRecord::Base
    unloadable
    include ActionView::Helpers::SanitizeHelper
    include Surveyor::Models::ResponseMethods
  end
end
