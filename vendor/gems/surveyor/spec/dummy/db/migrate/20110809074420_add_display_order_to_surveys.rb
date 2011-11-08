class AddDisplayOrderToSurveys < ActiveRecord::Migration
  def change
    add_column :surveyor_surveys, :display_order, :integer
  end
end
