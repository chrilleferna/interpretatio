Interpretatio::Engine.routes.draw do
  
  resources :translations do
    collection do
      get :init, :test, :backup_files, :delete, :edit_path, :edit_config, :init_config
      post :set_filter, :update_path, :update_record, :update_config
    end
    member do
    end
  end
  
  root to: "translations#index"
  
end
