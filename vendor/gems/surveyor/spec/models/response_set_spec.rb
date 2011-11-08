require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Surveyor::ResponseSet do
  before(:each) do
    @response_set = Surveyor::ResponseSet.make
    @radio_response_attributes = HashWithIndifferentAccess.new({"1"=>{"question_id"=>"1", "answer_id"=>"1", "string_value"=>"XXL"}, "2"=>{"question_id"=>"2", "answer_id"=>"6"}, "3"=>{"question_id"=>"3"}})
    @checkbox_response_attributes = HashWithIndifferentAccess.new({"1"=>{"question_id"=>"9", "answer_id"=>"11"}, "2"=>{"question_id"=>"9", "answer_id"=>"12"}})
    @other_response_attributes = HashWithIndifferentAccess.new({"6"=>{"question_id"=>"6", "answer_id" => "3", "string_value"=>""}, "7"=>{"question_id"=>"7", "answer_id" => "4", "text_value"=>"Brian is tired"}, "5"=>{"question_id"=>"5", "answer_id" => "5", "string_value"=>""}})
  end

  it "should have a unique code with length 10 that identifies the survey" do
    @response_set.access_code.should_not be_nil
    @response_set.access_code.length.should == 10
  end

  it "is completable" do
    @response_set.completed_at.should be_nil
    @response_set.complete!
    @response_set.completed_at.should_not be_nil
    @response_set.completed_at.is_a?(Time).should be_true
    @response_set.should be_complete
  end

  it "does not allow completion through mass assignment" do
    @response_set.completed_at.should be_nil
    @response_set.update_attributes(:completed_at => Time.now)
    @response_set.completed_at.should be_nil
  end

  it "should save new responses from radio buttons, ignoring blanks" do
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks(@radio_response_attributes))
    @response_set.responses.should have(2).items
    @response_set.responses.detect{|r| r.question_id == 2}.answer_id.should == 6
  end

  it "should save new responses from other types, ignoring blanks" do
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks(@other_response_attributes))
    @response_set.responses.should have(1).items
    @response_set.responses.detect{|r| r.question_id == 7}.text_value.should == "Brian is tired"
  end

  it "should ignore data if corresponding radio button is not selected" do
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks(@radio_response_attributes))
    @response_set.responses.select{|r| r.question_id == 2}.should have(1).item
    @response_set.responses.detect{|r| r.question_id == 2}.string_value.should == nil
  end

  it "should preserve response ids in checkboxes when adding another checkbox" do
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks(@checkbox_response_attributes))
    @response_set.responses.should have(2).items
    initial_response_ids = @response_set.responses.map(&:id)
    # adding a checkbox
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks({"1"=>{"question_id"=>"9", "answer_id"=>"13"}}))
    @response_set.responses.should have(3).items
    @response_set.responses.map(&:id) - initial_response_ids
    (@response_set.responses.map(&:id) - initial_response_ids).size.should == 1
  end
  
  it "should preserve response ids in checkboxes when removing another checkbox" do
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks(@checkbox_response_attributes))
    @response_set.responses.should have(2).items
    initial_response_ids = @response_set.responses.map(&:id)
    # removing a checkbox, reload the response set
    @response_set.update_attributes(:responses_attributes => Surveyor::ResponseSet.reject_or_destroy_blanks({"1"=>{"question_id"=>"9", "answer_id"=>"", "id" => initial_response_ids.first}}))
    @response_set.reload.responses.should have(1).items
    (initial_response_ids - @response_set.responses.map(&:id)).size.should == 1
  end
  it "should clean up a blank or empty hash" do
    Surveyor::ResponseSet.reject_or_destroy_blanks(nil).should == {}
    Surveyor::ResponseSet.reject_or_destroy_blanks({}).should == {}
  end
  it "should clean up responses_attributes before passing to nested_attributes" do
    hash_of_hashes = {
      "11" => {"question_id" => "1", "answer_id" => [""]}, # new checkbox, blank
      "12" => {"question_id" => "2", "answer_id" => ["", "124"]}, # new checkbox, checked
      "13" => {"id" => "101", "question_id" => "3", "answer_id" => [""]}, # existing checkbox, unchecked
      "14" => {"id" => "102", "question_id" => "4", "answer_id" => ["", "147"]}, # existing checkbox, left alone
      "15" => {"question_id" => "5", "answer_id" => ""}, # new radio, blank
      "16" => {"question_id" => "6", "answer_id" => "161"}, # new radio, selected
      "17" => {"id" => "103", "question_id" => "7", "answer_id" => "171"}, # existing radio, changed
      "18" => {"id" => "104", "question_id" => "8", "answer_id" => "181"}, # existing radio, unchanged
      "19" => {"question_id" => "9", "answer_id" => "191", "string_value" => ""}, # new string, blank
      "20" => {"question_id" => "10", "answer_id" => "201", "string_value" => "hi"}, # new string, filled
      "21" => {"id" => "105", "question_id" => "11", "answer_id" => "211", "string_value" => ""}, # existing string, cleared
      "22" => {"id" => "106", "question_id" => "12", "answer_id" => "221", "string_value" => "ho"}, # existing string, changed
      "23" => {"id" => "107", "question_id" => "13", "answer_id" => "231", "string_value" => "hi"}, # existing string, unchanged
      "24" => {"question_id" => "14", "answer_id" => [""], "string_value" => "foo"}, # new checkbox with string value, blank
      "25" => {"question_id" => "15", "answer_id" => ["", "241"], "string_value" => "bar"}, # new checkbox with string value, checked
      "26" => {"id" => "108", "question_id" => "14", "answer_id" => [""], "string_value" => "moo"}, # existing checkbox with string value, unchecked
      "27" => {"id" => "109", "question_id" => "15", "answer_id" => ["", "251"], "string_value" => "mar"}, # existing checkbox with string value, left alone
      "28" => {"question_id" => "16", "answer_id" => "", "string_value" => "foo"}, # new radio with string value, blank
      "29" => {"question_id" => "17", "answer_id" => "261", "string_value" => "bar"}, # new radio with string value, selected
      "30" => {"id" => "110", "question_id" => "18", "answer_id" => "271", "string_value" => "moo"}, # existing radio with string value, changed
      "31" => {"id" => "111", "question_id" => "19", "answer_id" => "281", "string_value" => "mar"} # existing radio with string value, unchanged
    }
    Surveyor::ResponseSet.reject_or_destroy_blanks(hash_of_hashes).should == {
      # "11" => {"question_id" => "1", "answer_id" => [""]}, # new checkbox, blank
      "12" => {"question_id" => "2", "answer_id" => ["", "124"]}, # new checkbox, checked
      "13" => {"id" => "101", "question_id" => "3", "answer_id" => [""], "_destroy" => "true"}, # existing checkbox, unchecked
      "14" => {"id" => "102", "question_id" => "4", "answer_id" => ["", "147"]}, # existing checkbox, left alone
      # "15" => {"question_id" => "5", "answer_id" => ""}, # new radio, blank
      "16" => {"question_id" => "6", "answer_id" => "161"}, # new radio, selected
      "17" => {"id" => "103", "question_id" => "7", "answer_id" => "171"}, # existing radio, changed
      "18" => {"id" => "104", "question_id" => "8", "answer_id" => "181"}, # existing radio, unchanged
      # "19" => {"question_id" => "9", "answer_id" => "191", "string_value" => ""}, # new string, blank
      "20" => {"question_id" => "10", "answer_id" => "201", "string_value" => "hi"}, # new string, filled
      "21" => {"id" => "105", "question_id" => "11", "answer_id" => "211", "string_value" => "", "_destroy" => "true"}, # existing string, cleared
      "22" => {"id" => "106", "question_id" => "12", "answer_id" => "221", "string_value" => "ho"}, # existing string, changed
      "23" => {"id" => "107", "question_id" => "13", "answer_id" => "231", "string_value" => "hi"}, # existing string, unchanged
      # "24" => {"question_id" => "14", "answer_id" => [""], "string_value" => "foo"}, # new checkbox with string value, blank
      "25" => {"question_id" => "15", "answer_id" => ["", "241"], "string_value" => "bar"}, # new checkbox with string value, checked
      "26" => {"id" => "108", "question_id" => "14", "answer_id" => [""], "string_value" => "moo", "_destroy" => "true"}, # existing checkbox with string value, unchecked
      "27" => {"id" => "109", "question_id" => "15", "answer_id" => ["", "251"], "string_value" => "mar"}, # existing checkbox with string value, left alone
      # "28" => {"question_id" => "16", "answer_id" => "", "string_value" => "foo"}, # new radio with string value, blank
      "29" => {"question_id" => "17", "answer_id" => "261", "string_value" => "bar"}, # new radio with string value, selected
      "30" => {"id" => "110", "question_id" => "18", "answer_id" => "271", "string_value" => "moo"}, # existing radio with string value, changed
      "31" => {"id" => "111", "question_id" => "19", "answer_id" => "281", "string_value" => "mar"} # existing radio with string value, unchanged
    }
  end
  it "should clean up radio and string responses_attributes before passing to nested_attributes" do
    @qone =  Surveyor::Question.make( :pick => "one")
    hash_of_hashes = {
      "32" => {"question_id" => @qone.id, "answer_id" => "291", "string_value" => ""} # new radio with blank string value, selected      
    }
    Surveyor::ResponseSet.reject_or_destroy_blanks(hash_of_hashes).should == {
      "32" => {"question_id" => @qone.id, "answer_id" => "291", "string_value" => ""} # new radio with blank string value, selected
    }
  end
  it "should clean up responses for lookups to get ids after saving via ajax" do
    hash_of_hashes = {"1"=>{"question_id"=>"2", "answer_id"=>"1"},
      "2"=>{"question_id"=>"3", "answer_id"=>["", "6"]},
      "9"=>{"question_id"=>"6", "string_value"=>"jack", "answer_id"=>"13"},
      "17"=>{"question_id"=>"13", "datetime_value(1i)"=>"2006", "datetime_value(2i)"=>"2", "datetime_value(3i)"=>"4", "datetime_value(4i)"=>"02", "datetime_value(5i)"=>"05", "answer_id"=>"21"},
      "18"=>{"question_id"=>"14", "datetime_value(1i)"=>"1", "datetime_value(2i)"=>"1", "datetime_value(3i)"=>"1", "datetime_value(4i)"=>"01", "datetime_value(5i)"=>"02", "answer_id"=>"22"},
      "19"=>{"question_id"=>"15", "datetime_value"=>"", "answer_id"=>"23", "id" => "1"},
      "47"=>{"question_id"=>"38", "answer_id"=>"220", "integer_value"=>"2", "id" => "2"},
      "61"=>{"question_id"=>"44", "response_group"=>"0", "answer_id"=>"241", "integer_value"=>"12"}}
    Surveyor::ResponseSet.trim_for_lookups(hash_of_hashes).should == 
    { "1"=>{"question_id"=>"2", "answer_id"=>"1"},
      "2"=>{"question_id"=>"3", "answer_id"=>["", "6"]},
      "9"=>{"question_id"=>"6", "answer_id"=>"13"},
      "17"=>{"question_id"=>"13", "answer_id"=>"21"},
      "18"=>{"question_id"=>"14", "answer_id"=>"22"},
      "19"=>{"question_id"=>"15", "answer_id"=>"23", "id" => "1", "_destroy" => "true"},
      "47"=>{"question_id"=>"38", "answer_id"=>"220", "id" => "2"},
      "61"=>{"question_id"=>"44", "response_group"=>"0", "answer_id"=>"241"}
    }
  end
  it "should remove responses" do
    r = @response_set.responses.create(:question_id => 1, :answer_id => 2)
    r.id.should_not be nil
    @response_set.should have(1).responses
    Surveyor::ResponseSet.reject_or_destroy_blanks({"2"=>{"question_id"=>"1", "id"=> r.id, "answer_id"=>[""]}}).should == {"2"=>{"question_id"=>"1", "id"=> r.id, "_destroy"=> "true", "answer_id"=>[""]}}
    @response_set.update_attributes(:responses_attributes => {"2"=>{"question_id"=>"1", "id"=> r.id, "_destroy"=> "true", "answer_id"=>[""]}}).should be_true
    @response_set.reload.should have(0).responses
  end
end

describe Surveyor::ResponseSet, "with dependencies" do
  before(:each) do
    @section = Surveyor::SurveySection.make
    # Questions
    @do_you_like_pie = Surveyor::Question.make( :text => "Do you like pie?", :survey_section => @section)
    @what_flavor = Surveyor::Question.make( :text => "What flavor?", :survey_section => @section)
    @what_bakery = Surveyor::Question.make( :text => "What bakery?", :survey_section => @section)
    # Answers
    @do_you_like_pie.answers << Surveyor::Answer.make( :text => "yes", :question_id => @do_you_like_pie.id)
    @do_you_like_pie.answers << Surveyor::Answer.make( :text => "no", :question_id => @do_you_like_pie.id)
    @what_flavor.answers << Surveyor::Answer.make( :response_class => :string, :question_id => @what_flavor.id)
    @what_bakery.answers << Surveyor::Answer.make( :response_class => :string, :question_id => @what_bakery.id)
    # Dependency
    @what_flavor_dep = Surveyor::Dependency.make( :rule => "A", :question_id => @what_flavor.id , :question_group => nil)
    Surveyor::DependencyCondition.make( :rule_key => "A", :question_id => @do_you_like_pie.id, :operator => "==", :answer_id => @do_you_like_pie.answers.first.id, :dependency_id => @what_flavor_dep.id)
    @what_bakery_dep = Surveyor::Dependency.make( :rule => "B", :question_id => @what_bakery.id , :question_group => nil)
    Surveyor::DependencyCondition.make( :rule_key => "B", :question_id => @do_you_like_pie.id, :operator => "==", :answer_id => @do_you_like_pie.answers.first.id, :dependency_id => @what_bakery_dep.id)
    # Responses
    @response_set = Surveyor::ResponseSet.make
    @response_set.responses << Surveyor::Response.make( :question_id => @do_you_like_pie.id, :answer_id => @do_you_like_pie.answers.first.id, :response_set_id => @response_set.id)
    @response_set.responses << Surveyor::Response.make( :string_value => "pecan pie", :question_id => @what_flavor.id, :answer_id => @what_flavor.answers.first.id, :response_set_id => @response_set.id)
  end
  
  it "should list unanswered dependencies to show at the top of the next page (javascript turned off)" do
    @response_set.unanswered_dependencies.should == [@what_bakery]
  end
  it "should list answered and unanswered dependencies to show inline (javascript turned on)" do
    @response_set.all_dependencies[:show].should == ["q_#{@what_flavor.id}", "q_#{@what_bakery.id}"]
  end
  it "should list group as dependency" do
    # Question Group
    crust_group = Surveyor::QuestionGroup.make(  :text => "Favorite Crusts")
    
    # Question
    what_crust = Surveyor::Question.make( :text => "What is your favorite curst type?", :survey_section => @section )
    crust_group.questions << what_crust

    # Answers
    what_crust.answers << Surveyor::Answer.make( :response_class => :string, :question_id => what_crust.id)
    
    # Dependency
    crust_group_dep = Surveyor::Dependency.make( :rule => "C", :question_group_id => crust_group.id, :question => nil)
    Surveyor::DependencyCondition.make(  :rule_key => "C", :question_id => @do_you_like_pie.id, :operator => "==", :answer_id => @do_you_like_pie.answers.first.id, :dependency_id => crust_group_dep.id)
    
    @response_set.unanswered_dependencies.should == [@what_bakery, crust_group]
  end
end
describe Surveyor::ResponseSet, "dependency_conditions" do
  before do
    @section =  Surveyor::SurveySection.make()
    # Questions
    @like_pie =  Surveyor::Question.make( :text => "Do you like pie?", :survey_section => @section)
    @like_jam =  Surveyor::Question.make( :text => "Do you like jam?", :survey_section => @section)
    @what_is_wrong_with_you =  Surveyor::Question.make( :text => "What's wrong with you?", :survey_section => @section)    
    # Answers
    @like_pie.answers <<  Surveyor::Answer.make( :text => "yes", :question_id => @like_pie.id)
    @like_pie.answers <<  Surveyor::Answer.make( :text => "no", :question_id => @like_pie.id)
    @like_jam.answers <<  Surveyor::Answer.make( :text => "yes", :question_id => @like_jam.id)
    @like_jam.answers <<  Surveyor::Answer.make( :text => "no", :question_id => @like_jam.id)
    # Dependency
    @what_is_wrong_with_you =  Surveyor::Dependency.make( :rule => "A or B", :question_id => @what_is_wrong_with_you.id)
    @dep_a =  Surveyor::DependencyCondition.make( :rule_key => "A", :question_id => @like_pie.id, :operator => "==", :answer_id => @like_pie.answers.first.id, :dependency_id => @what_is_wrong_with_you.id)
    @dep_b =  Surveyor::DependencyCondition.make( :rule_key => "B", :question_id => @like_jam.id, :operator => "==", :answer_id => @like_jam.answers.first.id, :dependency_id => @what_is_wrong_with_you.id)
    # Responses
    @response_set =  Surveyor::ResponseSet.make()
    @response_set.responses <<  Surveyor::Response.make( :question_id => @like_pie.id, :answer_id => @like_pie.answers.last.id, :response_set_id => @response_set.id)
  end
  it "should list all dependencies for answered questions" do
    dependency_conditions = @response_set.send(:dependencies).last.dependency_conditions
    dependency_conditions.size.should == 2
    dependency_conditions.should include(@dep_a)
    dependency_conditions.should include(@dep_b)
    
  end
  it "should list all dependencies for passed question_id" do
    # Questions
    like_ice_cream =  Surveyor::Question.make( :text => "Do you like ice_cream?", :survey_section => @section)
    what_flavor =  Surveyor::Question.make( :text => "What flavor?", :survey_section => @section)
    # Answers
    like_ice_cream.answers <<  Surveyor::Answer.make( :text => "yes", :question_id => like_ice_cream.id)
    like_ice_cream.answers <<  Surveyor::Answer.make( :text => "no", :question_id => like_ice_cream.id)
    what_flavor.answers <<  Surveyor::Answer.make( :response_class => :string, :question_id => what_flavor.id)
    # Dependency
    flavor_dependency =  Surveyor::Dependency.make( :rule => "C", :question_id => what_flavor.id)
    flavor_dependency_condition =  Surveyor::DependencyCondition.make( :rule_key => "A", :question_id => like_ice_cream.id, :operator => "==", 
                                          :answer_id => like_ice_cream.answers.first.id, :dependency_id => flavor_dependency.id)
    # Responses    
    dependency_conditions = @response_set.send(:dependencies, like_ice_cream.id).should == [flavor_dependency]
  end
end

describe Surveyor::ResponseSet, "as a quiz" do
  before(:each) do
    @survey =  Surveyor::Survey.make
    @section =  Surveyor::SurveySection.make( :survey => @survey)
    @response_set =  Surveyor::ResponseSet.make( :survey => @survey)
  end
  def generate_responses(count, quiz = nil, correct = nil)
    count.times do |i|
      q =  Surveyor::Question.make( :survey_section => @section )
      a =  Surveyor::Answer.make( :question => q, :response_class => "answer")
      x =  Surveyor::Answer.make( :question => q, :response_class => "answer")
      q.correct_answer_id = (quiz == "quiz" ? a.id : nil)
      q.save
      @response_set.responses <<  Surveyor::Response.make( :question => q, :answer => (correct == "correct" ? a : x))
    end
  end
  
  it "should report correctness if it is a quiz" do
    generate_responses(3, "quiz", "correct")
    @response_set.correct?.should be_true
    @response_set.correctness_hash.should == {:questions => 3, :responses => 3, :correct => 3}
  end
  it "should report incorrectness if it is a quiz" do
    generate_responses(3, "quiz", "incorrect")
    @response_set.correct?.should be_false
    @response_set.correctness_hash.should == {:questions => 3, :responses => 3, :correct => 0}
  end
  it "should report correct if it isn't a quiz" do
    generate_responses(3, "non-quiz")
    @response_set.correct?.should be_true
    @response_set.correctness_hash.should == {:questions => 3, :responses => 3, :correct => 3}
  end
end
describe Surveyor::ResponseSet, "with mandatory questions" do
  before(:each) do
    @survey =  Surveyor::Survey.make
    @section =  Surveyor::SurveySection.make( :survey => @survey)
    @response_set =  Surveyor::ResponseSet.make( :survey => @survey)
  end
  def generate_responses(count, mandatory = nil, responded = nil)
    count.times do |i|
      q =  Surveyor::Question.make( :survey_section => @section, :is_mandatory => (mandatory == "mandatory"))
      a =  Surveyor::Answer.make( :question => q, :response_class => "answer")
      if responded == "responded"
        @response_set.responses <<  Surveyor::Response.make( :question => q, :answer => a)
      end
    end
  end
  it "should report progress without mandatory questions" do
    generate_responses(3)
    @response_set.mandatory_questions_complete?.should be_true
    @response_set.progress_hash.should == {:questions => 3, :triggered => 3, :triggered_mandatory => 0, :triggered_mandatory_completed => 0}
  end
  it "should report progress with mandatory questions" do
    generate_responses(3, "mandatory", "responded")
    @response_set.mandatory_questions_complete?.should be_true
    @response_set.progress_hash.should == {:questions => 3, :triggered => 3, :triggered_mandatory => 3, :triggered_mandatory_completed => 3}
  end
  it "should report progress with mandatory questions" do
    generate_responses(3, "mandatory", "not-responded")
    @response_set.mandatory_questions_complete?.should be_false
    @response_set.progress_hash.should == {:questions => 3, :triggered => 3, :triggered_mandatory => 3, :triggered_mandatory_completed => 0}
  end
  it "should ignore labels and images" do
    generate_responses(3, "mandatory", "responded")
     Surveyor::Question.make( :survey_section => @section, :display_type => "label", :is_mandatory => true)
     Surveyor::Question.make( :survey_section => @section, :display_type => "image", :is_mandatory => true)
    @response_set.mandatory_questions_complete?.should be_true
    @response_set.progress_hash.should == {:questions => 5, :triggered => 5, :triggered_mandatory => 5, :triggered_mandatory_completed => 5}
  end
end
describe Surveyor::ResponseSet, "with mandatory, dependent questions" do
  before(:each) do
    @survey =  Surveyor::Survey.make
    @section =  Surveyor::SurveySection.make( :survey => @survey)
    @response_set =  Surveyor::ResponseSet.make( :survey => @survey)
  end
  def generate_responses(count, mandatory = nil, dependent = nil, triggered = nil)
    dq =  Surveyor::Question.make( :survey_section => @section, :is_mandatory => (mandatory == "mandatory"))
    da =  Surveyor::Answer.make( :question => dq, :response_class => "answer")
    dx =  Surveyor::Answer.make( :question => dq, :response_class => "answer")
    count.times do |i|
      q =  Surveyor::Question.make( :survey_section => @section, :is_mandatory => (mandatory == "mandatory"))
      a =  Surveyor::Answer.make( :question => q, :response_class => "answer")
      if dependent == "dependent"
        rn = ("A".."Z").to_a.sample
        d =  Surveyor::Dependency.make( :question => q , :rule => rn)
        dc =  Surveyor::DependencyCondition.make( :dependency => d, :question_id => dq.id, :answer_id => da.id , :rule_key => rn )
      end
      @response_set.responses <<  Surveyor::Response.make( :question => dq, :answer => (triggered == "triggered" ? da : dx))
      @response_set.responses <<  Surveyor::Response.make( :question => q, :answer => a)
    end
  end
  it "should report progress without mandatory questions" do
    generate_responses(3, "mandatory", "dependent")
    @response_set.mandatory_questions_complete?.should be_true
    @response_set.progress_hash.should == {:questions => 4, :triggered => 1, :triggered_mandatory => 1, :triggered_mandatory_completed => 1}
  end
  it "should report progress with mandatory questions" do
    generate_responses(3, "mandatory", "dependent", "triggered")
    @response_set.mandatory_questions_complete?.should be_true
    @response_set.progress_hash.should == {:questions => 4, :triggered => 4, :triggered_mandatory => 4, :triggered_mandatory_completed => 4}
  end
end
describe Surveyor::ResponseSet, "exporting csv" do
  before(:each) do
    @section =  Surveyor::SurveySection.make()
    # Questions
    @do_you_like_pie =  Surveyor::Question.make( :text => "Do you like pie?", :survey_section => @section)
    @what_flavor =  Surveyor::Question.make( :text => "What flavor?", :survey_section => @section)
    @what_bakery =  Surveyor::Question.make( :text => "What bakery?", :survey_section => @section)
    # Answers
    @do_you_like_pie.answers <<  Surveyor::Answer.make( :text => "yes", :question_id => @do_you_like_pie.id)
    @do_you_like_pie.answers <<  Surveyor::Answer.make( :text => "no", :question_id => @do_you_like_pie.id)
    @what_flavor.answers <<  Surveyor::Answer.make( :response_class => :string, :question_id => @what_flavor.id)
    @what_bakery.answers <<  Surveyor::Answer.make( :response_class => :string, :question_id => @what_bakery.id)
    # Responses
    @response_set =  Surveyor::ResponseSet.make()
    @response_set.responses <<  Surveyor::Response.make( :question_id => @do_you_like_pie.id, :answer_id => @do_you_like_pie.answers.first.id, :response_set_id => @response_set.id)
    @response_set.responses <<  Surveyor::Response.make( :string_value => "pecan pie", :question_id => @what_flavor.id, :answer_id => @what_flavor.answers.first.id, :response_set_id => @response_set.id)
  end
  it "should export a string with responses" do
    @response_set.responses.size.should == 2
    csv = @response_set.to_csv
    csv.is_a?(String).should be_true
    csv.should match "question.short_text"
    csv.should match "What flavor?"
    csv.should match /pecan pie/    
  end
end
