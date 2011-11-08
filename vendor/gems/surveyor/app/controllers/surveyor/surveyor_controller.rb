require "surveyor/surveyor_controller_methods"
module Surveyor
  class SurveyorController < ApplicationController
    unloadable
    include Surveyor::SurveyorControllerMethods
  end
end
