require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Surveyor::Response, "when saving a response" do
  before(:each) do
    # @response = Response.new(:question_id => 314, :response_set_id => 159, :answer_id => 1)
    @response = Surveyor::Response.make( :question => Surveyor::Question.make, :answer => Surveyor::Answer.make)
  end

  it "should be valid" do
    @response.should be_valid
  end

  it "should be invalid without a parent response set and question" do
    @response.response_set_id = nil
    @response.should have(1).error_on(:response_set_id)

    @response.question_id = nil
    @response.should_not be_valid
    @response.should have(1).error_on(:question_id)
  end

  it "should be correct if the question has no correct_answer_id" do
    @response.question.correct_answer_id.should be_nil
    @response.correct?.should be_true
  end
  it "should be correct if the answer's response class != answer" do
    @response.answer.response_class.should_not == "answer"
    @response.correct?.should be_true
  end  
  it "should be (in)correct if answer_id is (not) equal to question's correct_answer_id" do
    @answer = Surveyor::Answer.make( :response_class => "answer")
    @question = Surveyor::Question.make(:correct_answer_id => @answer.id)
    @response = Surveyor::Response.make( :question => @question, :answer => @answer)
    @response.correct?.should be_true
    @response.answer_id = 143
    @response.correct?.should be_false
  end
  describe "returns the response as the type requested" do

    it "returns 'string'" do
      @response.string_value = "blah"
      @response.as("string").should == "blah"
      @response.as(:string).should == "blah"
    end

    it "returns 'integer'" do
      @response.integer_value = 1001
      @response.as(:integer).should == 1001
    end

    it "returns 'float'" do
      @response.float_value = 3.14
      @response.as(:float).should == 3.14
    end

    it "returns 'answer'" do
      @response.answer_id = 14
      @response.as(:answer).should == 14
    end

    it "default returns answer type if not specified" do
      @response.answer_id =18
      @response.as(:stuff).should == 18
    end

    it "returns empty elements if the response is cast as a type that is not present" do
      resp = Surveyor::Response.new(:question_id => 314, :response_set_id => 156)
      resp.as(:string).should == nil
      resp.as(:integer).should == nil
      resp.as(:float).should == nil
      resp.as(:answer).should == nil
      resp.as(:stuff).should == nil
    end

  end

end

describe Surveyor::Response, "applicable_attributes" do
  before(:each) do
    @who = Surveyor::Question.make(:text => "Who rules?")
    @odoyle = Surveyor::Answer.make( :text => "Odoyle", :response_class => "answer")
    @other = Surveyor::Answer.make( :text => "Other", :response_class => "string")
  end
  
  it "should have string_value if response_type is string" do
    good = {"question_id" => @who.id, "answer_id" => @other.id, "string_value" => "Frank"}
    Surveyor::Response.applicable_attributes(good).should == good
  end
  
  it "should not have string_value if response_type is answer" do
    bad = {"question_id"=>@who.id, "answer_id"=>@odoyle.id, "string_value"=>"Frank"}
    Surveyor::Response.applicable_attributes(bad).should == {"question_id" => @who.id, "answer_id"=> @odoyle.id}
  end
  
  it "should have string_value if response_type is string and answer_id is an array (in the case of checkboxes)" do
    good = {"question_id"=>@who.id, "answer_id"=>["", @odoyle.id], "string_value"=>"Frank"}
    Surveyor::Response.applicable_attributes(good).should == {"question_id" => @who.id, "answer_id"=> ["", @odoyle.id]}
  end
  
  it "should have ignore attribute if missing answer_id" do
    ignore = {"question_id"=>@who.id, "answer_id"=>"", "string_value"=>"Frank"}
    Surveyor::Response.applicable_attributes(ignore).should == {"question_id"=>@who.id, "answer_id"=>"", "string_value"=>"Frank"}
  end
  
  it "should have ignore attribute if missing answer_id is an array" do
    ignore = {"question_id"=>@who.id, "answer_id"=>[""], "string_value"=>"Frank"}
    Surveyor::Response.applicable_attributes(ignore).should == {"question_id"=>@who.id, "answer_id"=>[""], "string_value"=>"Frank"}
  end
  
end
