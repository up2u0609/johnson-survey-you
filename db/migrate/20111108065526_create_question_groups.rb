class CreateQuestionGroups < ActiveRecord::Migration
  def change
    create_table :surveyor_question_groups do |t|
      # Content
      t.text :text
      t.text :help_text
      
      # Reference
      t.string :reference_identifier # from paper
      t.string :data_export_identifier # data export
      t.string :common_namespace # maping to a common vocab
      t.string :common_identifier # maping to a common vocab
            
      # Display
      t.string :display_type
      
      t.string :custom_class
      t.string :custom_renderer
      
      t.timestamps
    end
  end
end
