require "surveyor/engine"
require 'surveyor/common'
require 'surveyor/acts_as_response'
require 'formtastic/surveyor_builder'
require "surveyor/surveyor_controller_methods"
Dir[File.dirname(__FILE__) + "/surveyor/models/*.rb"].each {|f| require f}
#require 'tasks/surveyor'
Formtastic::SemanticFormHelper.builder = Formtastic::SurveyorBuilder
Formtastic::SemanticFormBuilder.default_text_area_height = 5
Formtastic::SemanticFormBuilder.default_text_area_width = 50
Formtastic::SemanticFormBuilder.all_fields_required_by_default = false

module Surveyor
end

