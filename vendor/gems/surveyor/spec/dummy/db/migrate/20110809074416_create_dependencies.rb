class CreateDependencies < ActiveRecord::Migration
  def change
    create_table :surveyor_dependencies do |t|
      # Context
      t.integer :question_id # the dependent question
      t.integer :question_group_id
      
      # Conditional
      t.string :rule

      # Result - TODO: figure out the dependency hook presentation options
      # t.string :property_to_toggle # visibility, class_name,
      # t.string :effect #blind, opacity

      t.timestamps
    end
  end
end
