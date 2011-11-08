require "surveyor/models/survey_methods"
module Surveyor
  class Survey < ActiveRecord::Base
    unloadable
    include Surveyor::Models::SurveyMethods  
  end
end
