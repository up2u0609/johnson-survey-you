class AddApiIds < ActiveRecord::Migration
  def change
    add_column :surveyor_surveys, :api_id, :string
    add_column :surveyor_questions, :api_id, :string
    add_column :surveyor_answers, :api_id, :string
  end
end
