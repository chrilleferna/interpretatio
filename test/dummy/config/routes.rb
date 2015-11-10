Rails.application.routes.draw do

  mount Interpretatio::Engine => "/interpretatio"
  
  get 'home/other' => 'home#other'
  get 'home/log_in' => 'home#log_in'
  get 'home/log_out' => 'home#log_out'
  
  root "home#index"
end
