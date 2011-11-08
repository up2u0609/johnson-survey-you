class AddDefaultValueToAnswers < ActiveRecord::Migration
  def change
    add_column :surveyor_answers, :default_value, :string
  end
end
