module Theconfig
  def get_config
    return {
      :yaml_dir => Rails.root.to_s + '/config/locales/YAML',
      :hash_dir => Rails.root.to_s + '/config/locales/',
      :yaml_bu_dir => Rails.root.to_s + '/config/locales/BACKUPS',
      :languages => {'en' => 'English', 'sv' => "Svenskish"}
    }
  end
end