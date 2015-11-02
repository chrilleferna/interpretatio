Interpretatio::Engine.routes.draw do
  
  resources :translations do
    collection do
      get :init, :test, :backup_files, :delete, :edit_path
      post :set_filter, :update_path, :update_record
    end
    member do
    end
  end
  
  root to: "translations#index"
  
end
