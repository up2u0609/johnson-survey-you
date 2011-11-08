require "surveyor/models/survey_section_methods"
module Surveyor
  class SurveySection < ActiveRecord::Base
    unloadable
    include Surveyor::Models::SurveySectionMethods
  end
end
