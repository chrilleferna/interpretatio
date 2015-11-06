Interpretatio::Engine.routes.draw do
  
  resources :translations do
    collection do
      get :init, :test, :backup_files, :backup_revert, :import_files, :delete, :edit_path, :import_export, :fix_config, :add_languages_to_hash, :remove_languages_from_hash
      post :set_filter, :update_path, :update_record, :update_config
    end
    member do
    end
  end
  
  root to: "translations#index"
  
end
