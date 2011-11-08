require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Surveyor::DependencyCondition do
  it "should have a list of operators" do
    %w(== != < > <= >=).each do |operator|
      Surveyor::DependencyCondition.operators.include?(operator).should be_true
    end
  end  
  describe "instance" do
    before(:each) do
      @default_answer = Surveyor::Answer.make(:question_id => 45, :response_class => "answer")
      @dependency_condition = Surveyor::DependencyCondition.new(:dependency_id => 1, :question_id => 45, :operator => "==", :answer => @default_answer, :rule_key => "1")
    end

    it "should be valid" do
      @dependency_condition.should be_valid
    end

    it "should be invalid without a parent dependency_id, question_id" do
      # this causes issues with building and saving
      # @dependency_condition.dependency_id = nil
      # @dependency_condition.should have(1).errors_on(:dependency_id)
      # @dependency_condition.question_id = nil
      # @dependency_condition.should have(1).errors_on(:question_id)
    end

    it "should be invalid without an operator" do
      @dependency_condition.operator = nil
      @dependency_condition.should have(2).errors_on(:operator)
    end
  
    it "should be invalid without a rule_key" do
      @dependency_condition.should be_valid
      @dependency_condition.rule_key = nil
      @dependency_condition.should_not be_valid
      @dependency_condition.should have(1).errors_on(:rule_key)
    end

    it "should have unique rule_key within the context of a dependency" do
     @dependency_condition.should be_valid
     Surveyor::DependencyCondition.create(:dependency_id => 2, :question_id => 46, :operator => "==", :answer_id => 14, :rule_key => "2")
     @dependency_condition.rule_key = "2" #rule key uniquness is scoped by dependency_id
     @dependency_condition.dependency_id = 2
     @dependency_condition.should_not be_valid
     @dependency_condition.should have(1).errors_on(:rule_key)
    end

    it "should have an operator in Surveyor::DependencyCondition.operators" do
      Surveyor::DependencyCondition.operators.each do |o|
        @dependency_condition.operator = o
        @dependency_condition.should have(0).errors_on(:operator)
      end
      @dependency_condition.operator = "#"
      @dependency_condition.should have(1).error_on(:operator)
    end

    it "should evaluate within the context of a response set object" do
      @response = Surveyor::Response.make(:question_id => 45, :response_set_id => 40 , :answer_id => @default_answer.id )
      @dependency_condition.is_met?([@response]).should be_true
      # inversion
      answer = Surveyor::Answer.make(:question_id => 45, :response_class => "answer")
      @alt_response = Surveyor::Response.make(:question_id => 45, :response_set_id => 40 , :answer_id => answer.id)
      @dependency_condition.is_met?([@alt_response]).should be_false
    end
  
    it "converts to a hash for evaluation by the dependency object" do
      @response = Surveyor::Response.new(:question_id => 45, :response_set_id => 40, :answer_id => 23)
      @rs = mock(Surveyor::ResponseSet, :responses => [@response])
      @dependency_condition.stub!(:is_met?).and_return(true)
      @dependency_condition.to_hash(@rs)
    end
  end
  describe "to_hash" do
    before do
      @response = mock(Surveyor::Response)
      @question = mock(Surveyor::Question)
      @dependency_condition = Surveyor::DependencyCondition.new(:rule_key => "A")
      @answer = mock(Surveyor::Answer)
      @question.stub!(:answers).and_return([@answer])
      @response.stub!(:answer).and_return(@answer)
      @rs = mock(Surveyor::ResponseSet, :responses => [@response])
      @dependency_condition.stub!(:question).and_return(@question)
    end
    
    it "converts unmet condition to {:A => false}" do
      @dependency_condition.stub!(:is_met?).and_return(false)
      @dependency_condition.to_hash(@rs).should == {:A => false}
    end
    
    it "converts met condition to {:A => true}" do
      @dependency_condition.stub!(:is_met?).and_return(true)
      @dependency_condition.to_hash(@rs).should == {:A => true}
    end
    
    it "converts unanswered condition to {:A => false}" do
      @question.stub!(:answers).and_return([])
      @response.stub!(:answer).and_return(nil)
      @rs.stub!(:responses).and_return([])
      @dependency_condition.to_hash(@rs).should == {:A => false}
    end 
  end
  describe "when if given a response object whether the dependency is satisfied using '=='" do
    before(:each) do
      @select_answer = Surveyor::Answer.make(:question_id => 1, :response_class => "answer")
      @dep_c = Surveyor::DependencyCondition.create(:answer_id => @select_answer.id, :operator => "==" , :rule_key => "K")
      @response = Surveyor::Response.make(:question_id => 314, :response_set_id => 159, :answer_id => @select_answer.id)
#      @response.answer = @select_answer
#      @dep_c.answer = @select_answer
      @dep_c.as(:answer).should == @select_answer.id
      @response.as(:answer).should == @select_answer.id
      @dep_c.as(:answer).should == @response.as(:answer)
    end
    
    after(:each) do
      @dep_c.delete
    end
    
    it "knows checkbox/radio type response" do
      @dep_c.is_met?([@response]).should be_true
      @dep_c.answer_id = 12
      @dep_c.is_met?([@response]).should be_false
    end

    it "knows string value response" do
      @select_answer.response_class = "string"
      @select_answer.save
      @response.string_value = "hello123"
      @dep_c.string_value = "hello123"
      @dep_c.is_met?([@response]).should be_true
      @response.string_value = "foo_abc"
      @dep_c.is_met?([@response]).should be_false
    end

    it "knows a text value response" do
      @select_answer.response_class = "text"
      @select_answer.save
      @response.text_value = "hello this is some text for comparison"
      @dep_c.text_value = "hello this is some text for comparison"
      @dep_c.is_met?([@response]).should be_true
      @response.text_value = "Not the same text"
      @dep_c.is_met?([@response]).should be_false 
    end

    it "knows an integer value response" do
      @select_answer.response_class = "integer"
      @select_answer.save
      @response.integer_value = 10045
      @dep_c.integer_value = 10045
      @dep_c.is_met?([@response]).should be_true
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_false
    end

    it "knows a float value response" do
      @select_answer.response_class = "float"
      @select_answer.save
      @response.float_value = 121.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_true
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_false
    end

  end

  describe "when if given a response object whether the dependency is satisfied using '!='" do
    before(:each) do
      @select_answer = Surveyor::Answer.make(:question_id => 1, :response_class => "answer")
      @dep_c = Surveyor::DependencyCondition.create(:answer_id => @select_answer.id, :operator => "!=")
      @response = Surveyor::Response.make(:question_id => 314, :response_set_id => 159, :answer_id => @select_answer.id)
#      @response.answer = @select_answer
#      @dep_c.answer = @select_answer
      @dep_c.as(:answer).should == @select_answer.id
      @response.as(:answer).should == @select_answer.id
      @dep_c.as(:answer).should == @response.as(:answer)
    end

    it "knows checkbox/radio type response" do
      @dep_c.is_met?([@response]).should be_false
      @dep_c.answer_id = 12
      @dep_c.is_met?([@response]).should be_true
    end

    it "knows string value response" do
      @select_answer.response_class = "string"
      @select_answer.save
      @response.string_value = "hello123"
      @dep_c.string_value = "hello123"
      @dep_c.is_met?([@response]).should be_false
      @response.string_value = "foo_abc"
      @dep_c.is_met?([@response]).should be_true
    end

    it "knows a text value response" do
      @select_answer.response_class = "text"
      @select_answer.save
      @response.text_value = "hello this is some text for comparison"
      @dep_c.text_value = "hello this is some text for comparison"
      @dep_c.is_met?([@response]).should be_false
      @response.text_value = "Not the same text"
      @dep_c.is_met?([@response]).should be_true 
    end

    it "knows an integer value response" do
      @select_answer.response_class = "integer"
      @select_answer.save
      @response.integer_value = 10045
      @dep_c.integer_value = 10045
      @dep_c.is_met?([@response]).should be_false
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_true
    end

    it "knows a float value response" do
      @select_answer.response_class = "float"
      @select_answer.save
      @response.float_value = 121.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_false
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_true
    end

  end

  describe "when if given a response object whether the dependency is satisfied using '<'" do
    before(:each) do
      @dep_c = Surveyor::DependencyCondition.new(:answer_id => 2, :operator => "<")
      @select_answer = Surveyor::Answer.new(:question_id => 1, :response_class => "answer")
      @response = Surveyor::Response.new(:question_id => 314, :response_set_id => 159, :answer_id => 2)
      @response.answer = @select_answer
      @dep_c.answer = @select_answer

    end

    it "knows operator on integer value response" do
      @select_answer.response_class = "integer"
      @response.integer_value = 50
      @dep_c.integer_value = 100
      @dep_c.is_met?([@response]).should be_true
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_false
    end

    it "knows operator on float value response" do
      @select_answer.response_class = "float"
      @response.float_value = 5.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_true
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_false
    end

  end

  describe "when if given a response object whether the dependency is satisfied using '<='" do
    before(:each) do
      @dep_c = Surveyor::DependencyCondition.new(:answer_id => 2, :operator => "<=")
      @select_answer = Surveyor::Answer.new(:question_id => 1, :response_class => "answer")
      @response = Surveyor::Response.new(:question_id => 314, :response_set_id => 159, :answer_id => 2)
      @response.answer = @select_answer
      @dep_c.answer = @select_answer

    end

    it "knows operator on integer value response" do
      @select_answer.response_class = "integer"
      @response.integer_value = 50
      @dep_c.integer_value = 100
      @dep_c.is_met?([@response]).should be_true
      @response.integer_value = 100
      @dep_c.is_met?([@response]).should be_true
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_false
    end

    it "knows operator on float value response" do
      @select_answer.response_class = "float"
      @response.float_value = 5.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_true
      @response.float_value = 121.1
      @dep_c.is_met?([@response]).should be_true
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_false
    end

  end

  describe "when if given a response object whether the dependency is satisfied using '>'" do
    before(:each) do
      @dep_c = Surveyor::DependencyCondition.new(:answer_id => 2, :operator => ">")
      @select_answer = Surveyor::Answer.new(:question_id => 1, :response_class => "answer")
      @response = Surveyor::Response.new(:question_id => 314, :response_set_id => 159, :answer_id => 2)
      @response.answer = @select_answer
      @dep_c.answer = @select_answer

    end

    it "knows operator on integer value response" do
      @select_answer.response_class = "integer"
      @response.integer_value = 50
      @dep_c.integer_value = 100
      @dep_c.is_met?([@response]).should be_false
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_true
    end

    it "knows operator on float value response" do
      @select_answer.response_class = "float"
      @response.float_value = 5.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_false
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_true
    end

  end

  describe "when if given a response object whether the dependency is satisfied using '>='" do
    before(:each) do
      @dep_c = Surveyor::DependencyCondition.new(:answer_id => 2, :operator => ">=")
      @select_answer = Surveyor::Answer.new(:question_id => 1, :response_class => "answer")
      @response = Surveyor::Response.new(:question_id => 314, :response_set_id => 159, :answer_id => 2)
      @response.answer = @select_answer
      @dep_c.answer = @select_answer

    end

    it "knows operator on integer value response" do
      @select_answer.response_class = "integer"
      @response.integer_value = 50
      @dep_c.integer_value = 100
      @dep_c.is_met?([@response]).should be_false
      @response.integer_value = 100
      @dep_c.is_met?([@response]).should be_true
      @response.integer_value = 421
      @dep_c.is_met?([@response]).should be_true
    end

    it "knows operator on float value response" do
      @select_answer.response_class = "float"
      @response.float_value = 5.1
      @dep_c.float_value = 121.1
      @dep_c.is_met?([@response]).should be_false
      @response.float_value = 121.1
      @dep_c.is_met?([@response]).should be_true
      @response.float_value = 130.123
      @dep_c.is_met?([@response]).should be_true
    end
  end

  describe "when evaluating a pick one/many with response_class e.g. string" do
    it "should compare answer ids when the string_value is nil" do
      a = Surveyor::Answer.make(:response_class => "string")
      dc = Surveyor::DependencyCondition.make(:question_id => a.question.id, :answer_id => a.id, :operator => "==")
      r = Surveyor::Response.make(:question_id => a.question.id, :answer_id => a.id, :string_value => "")
      r.should_receive(:as).with("answer").and_return(a.id)
      dc.is_met?([r]).should be_true
    end
    it "should compare strings when the string_value is not nil, even if it is blank" do
      a = Surveyor::Answer.make(:response_class => "string")
      dc = Surveyor::DependencyCondition.make( :question_id => a.question.id, :answer_id => a.id, :operator => "==", :string_value => "foo")
      r = Surveyor::Response.make(:question_id => a.question.id, :answer_id => a.id, :string_value => "foo")
      r.should_receive(:as).with("string").and_return("foo")
      dc.is_met?([r]).should be_true      

      dc2 = Surveyor::DependencyCondition.make( :question_id => a.question.id, :answer_id => a.id, :operator => "==", :string_value => "" , :rule_key => "B")
      r2 = Surveyor::Response.make( :question_id => a.question.id, :answer_id => a.id, :string_value => "")
      r2.should_receive(:as).with("string").and_return("")
      dc2.is_met?([r2]).should be_true      
    end
  end
  describe "when given responses whether the dependency is satisfied using 'count'" do
    before(:each) do
      @dep_c = Surveyor::DependencyCondition.new(:answer_id => nil, 
                                       :operator => "count>2")
      @question = Surveyor::Question.new
      @select_answers = []
      3.times do 
        @select_answers << Surveyor::Answer.new(:question => @question, 
                                      :response_class => "answer")
      end
      @responses = []
      @select_answers.slice(0,2).each do |a|
        @responses << Surveyor::Response.new(:question => @question, :answer => a, 
                                   :response_set_id => 159)
      end
     end

    it "knows operator with >" do
      @dep_c.is_met?(@responses).should be_false
      @responses << Surveyor::Response.new(:question => @question, 
                                 :answer => @select_answers.last, 
                                 :response_set_id => 159)
      @dep_c.is_met?(@responses).should be_true
    end

    it "knows operator with <" do
      @dep_c.operator = "count<2"
      @dep_c.is_met?(@responses).should be_false
      @dep_c.operator = "count<3"
      @dep_c.is_met?(@responses).should be_true
    end

    it "knows operator with <=" do
      @dep_c.operator = "count<=1"
      @dep_c.is_met?(@responses).should be_false
      @dep_c.operator = "count<=2"
      @dep_c.is_met?(@responses).should be_true
      @dep_c.operator = "count<=3"
      @dep_c.is_met?(@responses).should be_true
    end

    it "knows operator with >=" do
      @dep_c.operator = "count>=1"
      @dep_c.is_met?(@responses).should be_true
      @dep_c.operator = "count>=2"
      @dep_c.is_met?(@responses).should be_true
      @dep_c.operator = "count>=3"
      @dep_c.is_met?(@responses).should be_false
    end

    it "knows operator with !=" do
      @dep_c.operator = "count!=1"
      @dep_c.is_met?(@responses).should be_true
      @dep_c.operator = "count!=2"
      @dep_c.is_met?(@responses).should be_false
      @dep_c.operator = "count!=3"
      @dep_c.is_met?(@responses).should be_true
    end
  end
end
