# encoding: UTF-8
#%w(survey survey_section question_group question dependency dependency_condition answer validation validation_condition).each {|model| require "surveyor/#{model}" }
require "pp"
module Surveyor
  class Parser
    # Attributes
    attr_accessor :context

    # Class methods
    def self.parse(str)
      puts
      Surveyor::Parser.new.parse(str)
      puts
    end

    # Instance methods
    def initialize
      self.context = {}
    end
    def parse(str)
#      debugger
      instance_eval(str)
      return context[:survey]
    end
    # This method_missing does all the heavy lifting for the DSL
    def method_missing(missing_method, *args, &block)
      method_name, reference_identifier = missing_method.to_s.split("_", 2)
      type = full(method_name)
      print reference_identifier.blank? ? "#{type} " : "#{type}_#{reference_identifier} "

      # check for blocks
      raise "Error: A #{type.humanize} cannot be empty" if block_models.include?(type) && !block_given?
      raise "Error: Dropping the #{type.humanize} block like it's hot!" if !block_models.include?(type) && block_given?

      # parse and build
      "surveyor/#{type}".classify.constantize.parse_and_build(context, args, method_name, reference_identifier)

      # evaluate and clear context for block models
      if block_models.include?(type)
        self.instance_eval(&block)
        if type == 'survey'
          puts
          print context[type.to_sym].save ? "saved. " : " not saved! #{context[type.to_sym].errors.each_full{|x| x }.join(", ")} "
        end
        context[type.to_sym].clear(context) unless type == 'survey'
      end
    rescue Exception => e
      pp e.message
      pp e.backtrace
    end

    # Private methods
    private

    def full(method_name)
      case method_name.to_s
      when /^section$/; "survey_section"
      when /^g|grid|group|repeater$/; "question_group"
      when /^q|label|image$/; "question"
      when /^a$/; "answer"
      when /^d$/; "dependency"
      when /^c(ondition)?$/; context[:validation] ? "validation_condition" : "dependency_condition"
      when /^v$/; "validation"
      when /^dc(ondition)?$/; "dependency_condition"
      when /^vc(ondition)?$/; "validation_condition"
      else method_name
      end
    end
    def block_models
      %w(survey survey_section question_group)
    end
  end
end

# Surveyor models with extra parsing methods
class Surveyor::Survey < ActiveRecord::Base
  # block
  has_many :sections, :class_name => "Surveyor::SurveySection", :order => 'display_order', :dependent => :destroy , :foreign_key => "survey_id"
  before_create :default_args
  before_save :forge_access_code_and_title

  def self.to_normalized_string(value)
    # replace non-alphanumeric with "-". remove repeat "-"s. don't start or end with "-"
    value.to_s.downcase.gsub(/[^a-z0-9]/,"-").gsub(/-+/,"-").gsub(/-$|^-/,"")
  end

  def default_args
    self.inactive_at ||= DateTime.now
    self.api_id ||= UUID.generate
  end

  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| true }
    context[:question_references] = {}
    context[:answer_references] = {}

    # build and set context
    title = args[0]
    context[:survey] = new({  :title => title,
                              :reference_identifier => reference_identifier}.merge(args[1] || {}))
  end
  def clear(context)
    context.delete_if{|k,v| true }
    context[:question_references] = {}
    context[:answer_references] = {}
  end
  private
  def forge_access_code_and_title
    adjusted_value = self.title
    while Surveyor::Survey.find_by_access_code(Surveyor::Survey.to_normalized_string(self.title))
      i ||= 0
      i += 1
      self.title = "#{adjusted_value} #{i.to_s}"
    end
    self.access_code = Surveyor::Survey.to_normalized_string(self.title)
  end
end
class Surveyor::SurveySection < ActiveRecord::Base
  # block
  has_many :questions, :order => "display_order ASC", :dependent => :destroy, :class_name => "Surveyor::Question" , :foreign_key => :survey_section_id
  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| !%w(survey question_references answer_references).map(&:to_sym).include?(k)}

    # build and set context
    title = args[0]
    context[:survey_section] = context[:survey].sections.build({ :title => title }.merge(args[1] || {}))
  end
  def clear(context)
    context.delete_if{|k,v| !%w(survey question_references answer_references).map(&:to_sym).include?(k)}
  end
end
class Surveyor::QuestionGroup < ActiveRecord::Base
  # block
  has_many :questions , :foreign_key => :question_group_id , :class_name => "Surveyor::Question"
  has_one :dependency , :foreign_key => :question_group_id , :class_name => "Surveyor::Dependency"
  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| !%w(survey survey_section question_references answer_references).map(&:to_sym).include?(k)}

    # build and set context
    context[:question_group] = context[:question_group] = new({  :text => args[0] || "Question Group",
                                      :display_type => (original_method =~ /grid|repeater/ ? original_method : "default")}.merge(args[1] || {}))

  end
  def clear(context)
    context.delete_if{|k,v| !%w(survey survey_section question_references answer_references).map(&:to_sym).include?(k)}
  end
end
class Surveyor::Question < ActiveRecord::Base
  # nonblock

  # attributes
  attr_accessor :correct, :context_reference
  before_save :resolve_correct_answers
  belongs_to :survey_section , :foreign_key => "survey_section_id" , :class_name => "Surveyor::SurveySection"
  belongs_to :question_group, :dependent => :destroy , :foreign_key => "question_group_id" , :class_name => "Surveyor::QuestionGroup"
  has_many :answers, :order => "display_order ASC", :dependent => :destroy , :foreign_key => :question_id , :class_name => "Surveyor::Answer" # it might not always have answers
  has_one :dependency, :dependent => :destroy, :foreign_key => :question_id , :class_name => "Surveyor::Dependency"
  has_one :correct_answer, :dependent => :destroy, :foreign_key => :question_id , :class_name => "Surveyor::Answer"

  before_create  :default_args

  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| %w(question dependency dependency_condition answer validation validation_condition).map(&:to_sym).include? k}

    # build and set context
    text = args[0] || "Question"
    context[:question] = context[:survey_section].questions.build({
      :context_reference => context,
      :question_group => context[:question_group],
      :reference_identifier => reference_identifier,
      :text => text,
      :display_type => (original_method =~ /label|image/ ? original_method : "default")}.merge(args[1] || {}))

    # keep reference for dependencies
    context[:question_references][reference_identifier] = context[:question] unless reference_identifier.blank?

    # add grid answers
    if context[:question_group] && context[:question_group].display_type == "grid"
      (context[:grid_answers] || []).each do |grid_answer|
        a = context[:question].answers.build(grid_answer.attributes)
        context[:answer_references][reference_identifier] ||= {} unless reference_identifier.blank?
        context[:answer_references][reference_identifier][grid_answer.reference_identifier] = a unless reference_identifier.blank? or grid_answer.reference_identifier.blank?
      end
    end
  end

  def resolve_correct_answers
    unless correct.blank? or reference_identifier.blank? or context_reference.blank?
      # Looking up references for quiz answers
      context_reference[:answer_references][reference_identifier] ||= {}
      print (self.correct_answer = context_reference[:answer_references][reference_identifier][correct]) ? "found correct answer:#{correct} " : "lost! correct answer:#{correct} "
    end
  end
private
  def default_args
    self.is_mandatory ||= true
    self.display_type ||= "default"
    self.pick ||= "none"
    self.display_order ||= self.survey_section ? self.survey_section.questions.count : 0
    self.data_export_identifier ||= Surveyor::Common.normalize(text)
    self.short_text ||= text
    self.api_id ||= UUID.generate
  end
end
class Surveyor::Dependency < ActiveRecord::Base
  # nonblock
  has_many :dependency_conditions, :dependent => :destroy, :foreign_key => :dependency_id , :class_name => "Surveyor::DependencyCondition"
  belongs_to :question_group, :foreign_key => :question_group_id, :class_name => "Surveyor::QuestionGroup"
  belongs_to :question, :foreign_key => :question_id, :class_name => "Surveyor::Question"
  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| %w(dependency dependency_condition).map(&:to_sym).include? k}

    # build and set context
    if context[:question]
      context[:dependency] = context[:question].build_dependency(args[0] || {})
    elsif context[:question_group]
      context[:dependency] = context[:question_group].build_dependency(args[0] || {})
    end
  end
end
class Surveyor::DependencyCondition < ActiveRecord::Base
  # nonblock
  belongs_to :answer , :foreign_key => "answer_id" , :class_name => "Surveyor::Answer"
  belongs_to :dependency , :foreign_key => "dependency_id" , :class_name => "Surveyor::Dependency"
  belongs_to :dependent_question, :foreign_key => :question_id, :class_name => "Surveyor::Question"
  belongs_to :question, :foreign_key => :question_id, :class_name => "Surveyor::Question"
  attr_accessor :question_reference, :answer_reference, :context_reference
  before_save :resolve_references

  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| k == :dependency_condition}

    # build and set context
    a0, a1, a2 = args
    context[:dependency_condition] = context[:dependency].
      dependency_conditions.build(
        {
          :context_reference => context,
          :operator => a1 || "==",
          :question_reference => a0.to_s.gsub(/^q_/, ""),
          :rule_key => reference_identifier
        }.merge(
            a2.is_a?(Hash) ? a2 : { :answer_reference =>
                                      a2.to_s.gsub(/^a_/, "") }
          )
      )
  end

  def resolve_references
    if context_reference
      # Looking up references to questions and answers for linking the dependency objects
      print (self.question = context_reference[:question_references][question_reference]) ? "found question:#{question_reference} " : "lost! question:#{question_reference} "
      context_reference[:answer_references][question_reference] ||= {}
      print (self.answer = context_reference[:answer_references][question_reference][answer_reference]) ? "found answer:#{answer_reference} " : "lost! answer:#{answer_reference} "
    end
  end
end

class Surveyor::Answer < ActiveRecord::Base
  # nonblock

  belongs_to :question , :foreign_key => "question_id" , :class_name => "Surveyor::Question"
  has_many :responses , :foreign_key => "answer_id" , :class_name => "Surveyor::Response"
  has_many :validations, :dependent => :destroy , :foreign_key => "answer_id" , :class_name => "Surveyor::Validation"

  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| %w(answer validation validation_condition reference_identifier).map(&:to_sym).include? k}

    attrs = { :reference_identifier => reference_identifier}.merge(self.parse_args(args))

    # add answers to grid
    if context[:question_group] && context[:question_group].display_type == "grid"
      context[:answer] = new(attrs)
      context[:grid_answers] ||= []
      context[:grid_answers] << context[:answer]
    else
      context[:answer] = context[:question].answers.build(attrs)
      context[:answer_references][context[:question].reference_identifier] ||= {} unless context[:question].reference_identifier.blank?
      context[:answer_references][context[:question].reference_identifier][reference_identifier] = context[:answer] unless reference_identifier.blank? or context[:question].reference_identifier.blank?
    end
  end
  def self.parse_args(args)
    case args[0]
    when Hash # Hash
      self.text_args(args[0][:text]).merge(args[0])
    when String # (String, Hash) or (String, Symbol, Hash)
      self.text_args(args[0]).merge(self.hash_from args[1]).merge(args[2] || {})
    when Symbol # (Symbol, Hash) or (Symbol, Symbol, Hash)
      self.symbol_args(args[0]).merge(self.hash_from args[1]).merge(args[2] || {})
    else
      self.text_args(nil)
    end
  end
  def self.text_args(text = "Answer")
    {:text => text.to_s}
  end
  def self.hash_from(arg)
    arg.is_a?(Symbol) ? {:response_class => arg.to_s} : arg.is_a?(Hash) ? arg : {}
  end
  def self.symbol_args(arg)
    case arg
    when :other
      self.text_args("Other")
    when :other_and_string
      self.text_args("Other").merge({:response_class => "string"})
    when :none, :omit # is_exclusive erases and disables other checkboxes and input elements
      self.text_args(arg.to_s.humanize).merge({:is_exclusive => true})
    when :integer, :date, :time, :datetime, :text, :datetime, :string
      self.text_args(arg.to_s.humanize).merge({:response_class => arg.to_s, :display_type => "hidden_label"})
    end
  end
end
class Surveyor::Validation < ActiveRecord::Base
  # nonblock
  belongs_to :answer, :class_name => "Surveyor::Answer" , :foreign_key => "answer_id"
  has_many :validation_conditions, :dependent => :destroy, :class_name => "Surveyor::ValidationCondition" , :foreign_key => "validation_id"

  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| %w(validation validation_condition).map(&:to_sym).include? k}

    # build and set context
    context[:validation] = context[:answer].validations.build({:rule => "A"}.merge(args[0] || {}))
  end
end
class Surveyor::ValidationCondition < ActiveRecord::Base
  # nonblock
  belongs_to :validation, :class_name => "Surveyor::Validation" , :foreign_key => "validation_id"
  def self.parse_and_build(context, args, original_method, reference_identifier)
    # clear context
    context.delete_if{|k,v| k == :validation_condition}

    # build and set context
    a0, a1 = args
    context[:validation_condition] = context[:validation].validation_conditions.build({
                                      :operator => a0 || "==",
                                      :rule_key => reference_identifier}.merge(a1 || {}))
  end
end

