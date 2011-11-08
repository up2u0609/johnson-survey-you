require "surveyor/models/question_methods"
module Surveyor
  class Question < ActiveRecord::Base
    unloadable
    include Surveyor::Models::QuestionMethods
  end
end
