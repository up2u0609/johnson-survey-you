require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Surveyor::ValidationCondition, "Class methods" do
  it "should have a list of operators" do
    %w(== != < > <= >= =~).each{|operator| Surveyor::ValidationCondition.operators.include?(operator).should be_true }
  end
end

describe Surveyor::ValidationCondition do
  before(:each) do
    @validation_condition =  Surveyor::ValidationCondition.make
  end
  
  it "should be valid" do
     @validation_condition.should be_valid
  end
  # this causes issues with building and saving
  # it "should be invalid without a parent validation_id" do
  #   @validation_condition.validation_id = nil
  #   @validation_condition.should have(1).errors_on(:validation_id)
  # end

  it "should be invalid without an operator" do
    @validation_condition.operator = nil
    @validation_condition.should have(2).errors_on(:operator)
  end
  
  it "should be invalid without a rule_key" do
    @validation_condition.should be_valid
    @validation_condition.rule_key = nil
    @validation_condition.should_not be_valid
    @validation_condition.should have(1).errors_on(:rule_key)
  end

  it "should have unique rule_key within the context of a validation" do
   @validation_condition.should be_valid
    Surveyor::ValidationCondition.make( :validation_id => 2, :rule_key => "2")
   @validation_condition.rule_key = "2" #rule key uniquness is scoped by validation_id
   @validation_condition.validation_id = 2
   @validation_condition.should_not be_valid
   @validation_condition.should have(1).errors_on(:rule_key)
  end

  it "should have an operator in Surveyor::ValidationCondition.operators" do
    Surveyor::ValidationCondition.operators.each do |o|
      @validation_condition.operator = o
      @validation_condition.should have(0).errors_on(:operator)
    end
    @validation_condition.operator = "#"
    @validation_condition.should have(1).error_on(:operator)
  end
  
end

describe Surveyor::ValidationCondition, "validating responses" do
  def test_var(vhash, ahash, rhash)
    v =  Surveyor::ValidationCondition.make( vhash)
    a =  Surveyor::Answer.make( ahash)
    r =  Surveyor::Response.make( {:answer => a, :question => a.question}.merge(rhash))
    return v.is_valid?(r)
  end
  
  it "should validate a response by regexp" do
    test_var({:operator => "=~", :regexp => "^[a-z]{1,6}$"}, {:response_class => "string"}, {:string_value => "foobarbaz"}).should be_false
    test_var({:operator => "=~", :regexp => "^[a-z]{1,6}$"}, {:response_class => "string"}, {:string_value => "clear"}).should be_true
  end
  it "should validate a response by integer comparison" do
    test_var({:operator => ">", :integer_value => 3}, {:response_class => "integer"}, {:integer_value => 4}).should be_true
    test_var({:operator => "<=", :integer_value => 256}, {:response_class => "integer"}, {:integer_value => 512}).should be_false
  end
  it "should validate a response by (in)equality" do
    test_var({:operator => "!=", :datetime_value => Date.today + 1}, {:response_class => "date"}, {:datetime_value => Date.today}).should be_true
    test_var({:operator => "==", :string_value => "foo"}, {:response_class => "string"}, {:string_value => "foo"}).should be_true
  end
  it "should represent itself as a hash" do
    @v =  Surveyor::ValidationCondition.make( :rule_key => "A")
    @v.stub!(:is_valid?).and_return(true)
    @v.to_hash("foo").should == {:A => true}
    @v.stub!(:is_valid?).and_return(false)
    @v.to_hash("foo").should == {:A => false}
  end
end

describe Surveyor::ValidationCondition, "validating responses by other responses" do
  def test_var(v_hash, a_hash, r_hash, ca_hash, cr_hash)
    ca =  Surveyor::Answer.make( ca_hash)
    cr =  Surveyor::Response.make( cr_hash.merge(:answer => ca, :question => ca.question))
    v =  Surveyor::ValidationCondition.make( v_hash.merge({:question_id => ca.question.id, :answer_id => ca.id}))
    a =  Surveyor::Answer.make( a_hash)
    r =  Surveyor::Response.make( r_hash.merge(:answer => a, :question => a.question))
    return v.is_valid?(r)
  end
  it "should validate a response by integer comparison" do
    test_var({:operator => ">"}, {:response_class => "integer"}, {:integer_value => 4}, {:response_class => "integer"}, {:integer_value => 3}).should be_true
    test_var({:operator => "<="}, {:response_class => "integer"}, {:integer_value => 512}, {:response_class => "integer"}, {:integer_value => 4}).should be_false
  end
  it "should validate a response by (in)equality" do
    test_var({:operator => "!="}, {:response_class => "date"}, {:datetime_value => Date.today}, {:response_class => "date"}, {:datetime_value => Date.today + 1}).should be_true
    test_var({:operator => "=="}, {:response_class => "string"}, {:string_value => "donuts"}, {:response_class => "string"}, {:string_value => "donuts"}).should be_true
  end
  it "should not validate a response by regexp" do
    test_var({:operator => "=~"}, {:response_class => "date"}, {:datetime_value => Date.today}, {:response_class => "date"}, {:datetime_value => Date.today + 1}).should be_false
    test_var({:operator => "=~"}, {:response_class => "string"}, {:string_value => "donuts"}, {:response_class => "string"}, {:string_value => "donuts"}).should be_false
  end
end
