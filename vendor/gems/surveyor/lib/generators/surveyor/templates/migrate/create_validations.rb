class CreateValidations < ActiveRecord::Migration
  def change
    create_table :surveyor_validations do |t|
      # Context
      t.integer :answer_id # the answer to validate
      
      # Conditional
      t.string :rule

      # Message
      t.string :message
      
      t.timestamps
    end
  end
end
