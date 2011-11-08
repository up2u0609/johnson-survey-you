require 'rails/generators'
require 'rails/generators/migration'
class SurveyorGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      if current_migration_number(dirname).to_s == "0"
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        current_migration_number(dirname) + 1
      end
    else
      current_migration_number(dirname) + 1
    end
  end
  
  def copy_migrations
    [ "create_surveys", "create_survey_sections", "create_questions", "create_question_groups", "create_answers", 
      "create_response_sets", "create_responses", 
      "create_dependencies", "create_dependency_conditions", 
      "create_validations", "create_validation_conditions", 
      "add_display_order_to_surveys", "add_correct_answer_id_to_questions",
      "add_index_to_response_sets", "add_index_to_surveys", 
      "add_unique_indicies", "add_section_id_to_responses",
      "add_default_value_to_answers", "add_api_ids",
      "add_display_type_to_answers"].each do | m |
        migration_template "migrate/#{m}.rb" , "db/migrate/#{m}.rb"
    end
  end
  
  def copy_locales
    empty_directory "config/locales"
    Dir.glob(File.join(File.dirname(__FILE__), "templates", "locales", "*.yml")).map{|path| File.basename(path)}.each do |filename|
      copy_file "locales/#{filename}", "config/locales/#{filename}"
    end
  end
  
#  def copy_assets
#    ["images", "javascripts", "stylesheets"].each do |asset_type|
#      empty_directory "public/#{asset_type}/surveyor"
#      Dir.glob(File.join(File.dirname(__FILE__), "templates", "assets", asset_type, "*.*")).map{|path| File.basename(path)}.each do |filename|
#        copy_file "assets/#{asset_type}/#{filename}", "public/#{asset_type}/surveyor/#{filename}"
#      end
#    end
#    empty_directory "public/stylesheets/sass"
#    copy_file "assets/stylesheets/sass/surveyor.sass", "public/stylesheets/sass/surveyor.sass"
#    copy_file "assets/stylesheets/sass/custom.sass", "public/stylesheets/sass/custom.sass"
#  end
  
  def copy_survey
    # Surveys
    empty_directory "lib/surveys"
    
    copy_file "surveys/kitchen_sink_survey.rb", "lib/surveys/kitchen_sink_survey.rb"
    copy_file "surveys/quiz.rb", "lib/surveys/quiz.rb"
  end
  
  private
  def file_has_line(filename, rxp)
    File.readlines(filename).each{ |line| return true if line =~ rxp }
    false
  end
end
