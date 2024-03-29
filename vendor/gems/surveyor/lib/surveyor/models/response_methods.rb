module Surveyor
  module Models
    module ResponseMethods
      def self.included(base)
        # Associations
        base.send :belongs_to, :response_set , :foreign_key => "response_set_id" , :class_name => "Surveyor::ResponseSet"
        base.send :belongs_to, :question , :foreign_key => "question_id" , :class_name => "Surveyor::Question"
        base.send :belongs_to, :answer , :foreign_key => "answer_id" , :class_name => "Surveyor::Answer"
        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :response_set_id , :question_id
          base.send :validates_associated, :answer , :question
          
          @@validations_already_included = true
        end
        base.send :include, Surveyor::ActsAsResponse # includes "as" instance method
        
        # Class methods
        base.instance_eval do
          def applicable_attributes(attrs)
            result = HashWithIndifferentAccess.new(attrs)
            answer_id = result[:answer_id].is_a?(Array) ? result[:answer_id].last : result[:answer_id] # checkboxes are arrays / radio buttons are not arrays
            if result[:string_value] && !answer_id.blank? && Surveyor::Answer.exists?(answer_id)
              answer = Surveyor::Answer.find(answer_id)
              result.delete(:string_value) unless answer.response_class && answer.response_class.to_sym == :string
            end
            result
          end
        end
      end

      # Instance Methods
      def answer_id=(val)
        write_attribute :answer_id, (val.is_a?(Array) ? val.detect{|x| !x.to_s.blank?} : val)
      end
      def correct?
        question.correct_answer_id.nil? or self.answer.response_class != "answer" or (question.correct_answer_id.to_i == answer_id.to_i)
      rescue
        false
      end

      def to_s # used in dependency_explanation_helper
        if self.answer.response_class == "answer" and self.answer_id
          return self.answer.text
        else
          return "#{(self.string_value || self.text_value || self.integer_value || self.float_value || nil).to_s}"
        end
      end
    end
  end
end
