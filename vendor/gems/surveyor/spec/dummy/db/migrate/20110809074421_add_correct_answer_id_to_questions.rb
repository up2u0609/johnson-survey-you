class AddCorrectAnswerIdToQuestions < ActiveRecord::Migration
  def change
    add_column :surveyor_questions, :correct_answer_id, :integer
  end
end
