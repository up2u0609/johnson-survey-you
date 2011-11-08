class CreateDependencyConditions < ActiveRecord::Migration
  def change
    create_table :surveyor_dependency_conditions do |t|
      # Context
      t.integer :dependency_id
      t.string :rule_key
      
      # Conditional
      t.integer :question_id # the conditional question
      t.string :operator

      # Value
      t.integer :answer_id
      t.datetime :datetime_value
      t.integer :integer_value
      t.float :float_value
      t.string :unit
      t.text :text_value
      t.string :string_value
      t.string :response_other

      t.timestamps
    end
  end
end
