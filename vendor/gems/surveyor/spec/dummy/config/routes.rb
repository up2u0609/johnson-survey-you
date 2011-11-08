Rails.application.routes.draw do
  mount Surveyor::Engine => "/surveyor" , :as => :surveyor
end
