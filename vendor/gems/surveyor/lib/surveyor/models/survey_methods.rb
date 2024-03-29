require 'uuid'

module Surveyor
  module Models
    module SurveyMethods
      def self.included(base)
        # Associations
        base.send :has_many, :sections, :class_name => "Surveyor::SurveySection", :order => 'display_order', :dependent => :destroy , :foreign_key => "survey_id"
        base.send :has_many, :sections_with_questions, :include => :questions, :class_name => "Surveyor::SurveySection", :order => 'display_order', :foreign_key => "survey_id"
        base.send :has_many, :response_sets, :foreign_key => "survey_id", :class_name => "Surveyor::ResponseSet"

        # Scopes
        base.send :scope, :with_sections, {:include => :sections}
        base.send :before_create, :default_args
        base.send :before_create, :forge_access_code_and_title
        
        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :title
          base.send :validates_uniqueness_of, :access_code
          
          @@validations_already_included = true
        end        

        # Class methods
        base.instance_eval do
          def to_normalized_string(value)
            # replace non-alphanumeric with "-". remove repeat "-"s. don't start or end with "-"
            value.to_s.downcase.gsub(/[^a-z0-9]/,"-").gsub(/-+/,"-").gsub(/-$|^-/,"")
          end
        end
      end

      def default_args
        self.inactive_at ||= DateTime.now
        self.api_id ||= UUID.generate
      end

      def forge_access_code_and_title
        adjusted_value = self.title
        while Survey.find_by_access_code(Survey.to_normalized_string(self.title))
          i ||= 0
          i += 1
          self.title = "#{adjusted_value} #{i.to_s}"
        end
        self.access_code = Survey.to_normalized_string(self.title)
      end

      def active?
        self.active_as_of?(DateTime.now)
      end
      def active_as_of?(datetime)
        (self.active_at.nil? or self.active_at < datetime) and (self.inactive_at.nil? or self.inactive_at > datetime)
      end  
      def activate!
        self.active_at = DateTime.now
      end
      def deactivate!
        self.inactive_at = DateTime.now
      end
      def active_at=(datetime)
        self.inactive_at = nil if !datetime.nil? and !self.inactive_at.nil? and self.inactive_at < datetime
        super(datetime)
      end
      def inactive_at=(datetime)
        self.active_at = nil if !datetime.nil? and !self.active_at.nil? and self.active_at > datetime
        super(datetime)
      end
    end
  end
end
