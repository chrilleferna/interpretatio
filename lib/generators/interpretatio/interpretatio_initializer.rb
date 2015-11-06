module Interpretatio

  # Uncomment these two lines to use YAML format for I18n.
  # You need to explicitly EXPORT YAML FILES to see changes in the localization definitions
  #YAML_DIRECTORY = Rails.root.join('config', 'locale')
  #HASH_DIRECTORY = Rails.root.join('config', 'locale', 'HASH')
  
  # Uncomment these two lines to use HASH format for I18n.
  # Changes in the localization definitions are immediatly seen in the application
  # Use EXPORT YAML FILES from time to time to create snapshots for backup 
   YAML_DIRECTORY = Rails.root.join('config', 'locales', 'YAML').to_s
   HASH_DIRECTORY = Rails.root.join('config', 'locales').to_s

  BACKUP_DIRECTORY = Rails.root.join('config', 'locales', 'BACKUP').to_s
  MAX_BACKUPS = 3

  LANGUAGES = {'en' => 'English', 'fr' => 'Français', 'sv' => 'Svenska'}

  #
  # Verify that the directories exist. If not: create them.
  [YAML_DIRECTORY, HASH_DIRECTORY, BACKUP_DIRECTORY].each{|thedir| Dir.mkdir(thedir) unless File.exists?(thedir)}

end

puts "Interpretatio Engine initialized:"
puts "  YAML files in #{Interpretatio::YAML_DIRECTORY}"
puts "  Localization hash file in #{Interpretatio::HASH_DIRECTORY}"
puts "  Backups in #{Interpretatio::BACKUP_DIRECTORY}"
puts "  Number of backups to be kept #{Interpretatio::MAX_BACKUPS}"
puts "  Languages supported #{Interpretatio::LANGUAGES.inspect}"