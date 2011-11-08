require "surveyor/models/answer_methods"
module Surveyor
  class Answer < ActiveRecord::Base
    unloadable
    include Surveyor::Models::AnswerMethods
  end
end
