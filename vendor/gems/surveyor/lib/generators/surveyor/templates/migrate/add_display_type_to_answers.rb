class AddDisplayTypeToAnswers < ActiveRecord::Migration
  def self.up
    add_column :surveyor_answers, :display_type, :string
    Surveyor::Answer.all.each{|a| a.update_attributes(:display_type => "hidden_label") if a.hide_label == true}
    remove_column :surveyor_answers, :hide_label
  end

  def self.down
    add_column :surveyor_answers, :hide_label, :boolean
    Surveyor::Answer.all.each{|a| a.update_attributes(:hide_label => true) if a.display_type == "hidden_label"}
    remove_column :surveyor_answers, :display_type
  end
end
