Surveyor::Engine.routes.draw do

  match "results" => "results#index" , :as => :results
  match "results/:survey_code" => "results#show" , :as => :result
  
  match "surveys" => "surveyor#new" , :as => :available_surveys
  match "surveys/:survey_code" => "surveyor#create" , :as => :take_survey
  match "surveys/:survey_code/:response_set_code.:format" => "surveyor#show" , :as => :view_my_survey
  match "surveys/:survey_code/:response_set_code/take" => "surveyor#edit" , :as => :edit_my_survey
  match "surveys/:survey_code/:response_set_code" => "surveyor#update" , :as => :update_my_survey
  
end
