require "surveyor/models/question_group_methods"
module Surveyor
  class QuestionGroup < ActiveRecord::Base
    unloadable
    include Surveyor::Models::QuestionGroupMethods
    
  end
end
