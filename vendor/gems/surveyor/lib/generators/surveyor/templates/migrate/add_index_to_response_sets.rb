class AddIndexToResponseSets < ActiveRecord::Migration
  def change
    add_index(:surveyor_response_sets, :access_code, :name => 'response_sets_ac_idx')
  end
end
