module Surveyor
  class ResultsController < ApplicationController
    helper 'surveyor/surveyor'
    layout 'surveyor/results' 
    def index
      @surveys = Surveyor::Survey.all
    end

    def show
      @survey = Surveyor::Survey.find_by_access_code(params[:survey_code])
      @response_sets = @survey.response_sets
      @questions = @survey.sections_with_questions.map(&:questions).flatten
    end
  end
end
