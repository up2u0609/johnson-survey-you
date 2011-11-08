class CreateResponseSets < ActiveRecord::Migration
  def change
    create_table :surveyor_response_sets do |t|
      # Context
      t.integer :user_id
      t.integer :survey_id

      # Content
      t.string :access_code #unique id for the object used in urls

      # Expiry
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
