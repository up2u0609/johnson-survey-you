require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Surveyor::SurveyorController do
  
  # map.with_options :controller => 'surveyor' do |s|
  #   s.available_surveys "#{root}",                                       :conditions => {:method => :get}, :action => "new"      # GET survey list
  #   s.take_survey       "#{root}:survey_code",                           :conditions => {:method => :post}, :action => "create"  # Only POST of survey to create
  #   s.view_my_survey    "#{root}:survey_code/:response_set_code",        :conditions => {:method => :get}, :action => "show"     # GET viewable/printable? survey
  #   s.edit_my_survey    "#{root}:survey_code/:response_set_code/take",   :conditions => {:method => :get}, :action => "edit"     # GET editable survey 
  #   s.update_my_survey  "#{root}:survey_code/:response_set_code",        :conditions => {:method => :put}, :action => "update"   # PUT edited survey 
  # end   
  
  describe "available surveys: GET /surveys" do

    before(:each) do
      @survey =  Surveyor::Survey.make
      Surveyor::Survey.stub!(:find).and_return([@survey])
    end
  
    def do_get
      get :new , :use_route => :surveyor
    end
  
    it "should render index template" do
      do_get
      response.should be_success
      response.should render_template('new')
    end

    it "should find all surveys" do
      Surveyor::Survey.should_receive(:find).with(:all).and_return([@survey])
      do_get
    end
    
    it "should assign the found surveys for the view" do
      do_get
      assigns[:surveys].should == [@survey]
    end
  end

  describe "take survey: POST /surveys/xyz" do

    before(:each) do
      @survey =  Surveyor::Survey.make( :title => "xyz", :access_code => "xyz")
      @response_set =  Surveyor::ResponseSet.make( :access_code => "pdq")
      Surveyor::ResponseSet.stub!(:create).and_return(@response_set)
      Surveyor::Survey.stub!(:find_by_access_code).and_return(@survey)
    end
    
    describe "with success" do
      def do_post
        post :create, :survey_code => "xyz" , :use_route => :surveyor
      end
      it "should look for the survey" do
        Surveyor::Survey.should_receive(:find_by_access_code).with("xyz").and_return(@survey)
        do_post
      end
      it "should create a new response_set" do
        Surveyor::ResponseSet.should_receive(:create).and_return(@response_set)
        do_post
      end
      it "should redirect to the new response_set" do
        do_post
        response.should redirect_to(edit_my_survey_path(:survey_code => "xyz", :response_set_code  => "pdq" ))
      end
    end
    
    describe "with failures" do
      it "should re-redirect to 'new' if ResponseSet failed create" do
        Surveyor::ResponseSet.should_receive(:create).and_return(false)
        post :create, :survey_code => "XYZ" , :use_route => :surveyor
        response.should redirect_to(available_surveys_path(  ))
      end
      it "should re-redirect to 'new' if Survey failed find" do
        Surveyor::Survey.should_receive(:find_by_access_code).and_return(nil)
        post :create, :survey_code => "XYZ" , :use_route => :surveyor
        response.should redirect_to(available_surveys_path(  ))
      end
    end
  end

  describe "view my survey: GET /surveys/xyz/pdq" do
   #integrate_views
    before(:each) do
      @survey =  Surveyor::Survey.make( :title => "xyz", :access_code => "xyz", :sections =>  [Surveyor::SurveySection.make])  
      @response_set =  Surveyor::ResponseSet.make( :access_code => "pdq", :survey => @survey)
    end
  
    def do_get
      get :show, :survey_code => "xyz", :response_set_code => "pdq" , :use_route => :surveyor
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
    
    it "should render show template" do
      do_get
      response.should render_template('show')
    end
   
    it "should find the response_set requested" do
      Surveyor::ResponseSet.should_receive(:find_by_access_code).with("pdq",{:include=>{:responses=>[:question, :answer]}}).and_return(@response_set)
      do_get
    end

    it "should redirect if :response_code not found" do
      get :show, :survey_code => "xyz", :response_set_code => "DIFFERENT" , :use_route => :surveyor
      response.should redirect_to(available_surveys_path(  ))      
    end

  end

  describe "edit my survey: GET /surveys/XYZ/PDQ/take" do

    before(:each) do
      @survey =  Surveyor::Survey.make( :title => "XYZ", :access_code => "XYZ")
      @section =  Surveyor::SurveySection.make( :survey => @survey)      
      @response_set =  Surveyor::ResponseSet.make( :access_code => "PDQ", :survey => @survey)
    end

    it "should be successful, render edit with the requested survey" do
      Surveyor::ResponseSet.should_receive(:find_by_access_code).and_return(@response_set)
      get :edit, :survey_code => "XYZ", :response_set_code => "PDQ" , :use_route => :surveyor
      response.should be_success
      response.should render_template('edit')
      assigns[:response_set].should == @response_set
      assigns[:survey].should == @survey
    end
    it "should redirect if :response_code not found" do
      get :edit, :survey_code => "XYZ", :response_set_code => "DIFFERENT" , :use_route => :surveyor
      response.should redirect_to(available_surveys_path(  ))      
    end

  end

  describe "update my survey: PUT /surveys/XYZ/PDQ" do

    before(:each) do
      @survey =  Surveyor::Survey.make( :title => "XYZ", :access_code => "XYZ")
      @section =  Surveyor::SurveySection.make( :survey => @survey)      
      @response_set =  Surveyor::ResponseSet.make( :access_code => "PDQ", :survey => @survey)
      # @response_set.stub!(:update_attributes).and_return(true)
      # @response_set.stub!(:complete!).and_return(Time.now)
      # @response_set.stub!(:save).and_return(true)
    end
    
    def do_put
      put :update, :survey_code => "XYZ", :response_set_code => "PDQ" , :use_route => :surveyor
    end
    def do_put_with_finish
      responses = {
         "6"=>{"question_id"=>"6", "answer_id" => "6", "string_value"=>"saf"}, #string
         "7"=>{"question_id"=>"7", "answer_id" => "11", "text_value"=>"foo"}, #text
         "1"=>{"question_id"=>"1", "answer_id"=>"1", "string_value"=>"bar"}, #radio+txt
         "2"=>{"question_id"=>"2", "answer_id"=>"6"}, #radio
         "3"=>{"question_id"=>"3", "answer_id"=>"10"}, #radio
         "4"=>{"question_id"=>"4", "answer_id"=>"15"}, #check
         "5"=>{"question_id"=>"5", "answer_id"=>"16", "string_value"=>""} #check+txt
      }
      put :update, :survey_code => "XYZ", :response_set_code => "PDQ", :finish => "finish", :r => responses , :use_route => :surveyor
    end
    
    it "should find the response set requested" do
      Surveyor::ResponseSet.should_receive(:find_by_access_code).and_return(@response_set)
      do_put
    end
    it "should redirect to 'edit' without params" do
      do_put
      response.should redirect_to(:action => :edit , :use_route => :surveyor)
    end
    it "should complete the found response set on finish" do      
      do_put_with_finish
      flash[:notice].should == "Completed survey"
    end
    it "should redirect to available surveys if :response_code not found" do
      put :update, :survey_code => "XYZ", :response_set_code => "DIFFERENT" , :use_route => :surveyor
      response.should redirect_to(available_surveys_path(  ))
      flash[:notice].should == "Unable to find your responses to the survey"
    end

  end
  
  describe "update my survey with ajax" do
    before(:each) do
      @survey =  Surveyor::Survey.make( :title => "XYZ", :access_code => "XYZ")
      @section =  Surveyor::SurveySection.make( :survey => @survey)
      @response_set =  Surveyor::ResponseSet.make( :access_code => "PDQ", :survey => @survey)
      Surveyor::ResponseSet.stub!(:find_by_access_code).and_return(@response_set)
    end
    def do_ajax_put(r)
      xhr :put, :update, :survey_code => "XYZ", :response_set_code => "PDQ", :r => r , :use_route => :surveyor
    end
    it "should return an id for new responses" do
      do_ajax_put({
         "2"=>{"question_id"=>"4", "answer_id"=>"14"}, #check
         "4"=>{"question_id"=>"4", "answer_id"=>"15"} #check
      })
      ActiveSupport::JSON.decode( response.body ).should == {"ids" => {"2" => 1, "4" => 2}, "remove" => {}, "show" => [], "hide" => []}
    end
    it "should return a delete for when responses are removed" do
      r = @response_set.responses.create(:question_id => 4, :answer_id => 14)
      do_ajax_put({
         "2"=>{"question_id"=>"4", "answer_id"=>"", "id" => r.id} # uncheck
      })
      ActiveSupport::JSON.decode( response.body ).should == {"ids" => {}, "remove" => {"2" => r.id.to_s}, "show" => [], "hide" => []}
    end
    it "should return dependencies" do
      @response_set.should_receive(:all_dependencies).and_return({"show" => ['q_1'], "hide" => ['q_2']})
      do_ajax_put({
        "4"=>{"question_id"=>"9", "answer_id"=>"12"} #check
      })
      ActiveSupport::JSON.decode( response.body ).should == {"ids" => {"4" => 1}, "remove" => {}, "show" => ['q_1'], "hide" => ["q_2"]}
    end
  end
end
