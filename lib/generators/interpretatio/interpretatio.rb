module Interpretatio

  # There are basically 3 configuration options (that can be further refined). Please read the ReadMe to
  # understand which is the best option for you
  #
  #
  # ======= OPTION 1 (default) ======
  # Uncomment these lines to use YAML format for I18n.
  # You need to explicitly EXPORT YAML FILES to see changes in the localization definitions
  YAML_DIRECTORY = Rails.root.join('config', 'locales')
  HASH_DIRECTORY = Rails.root.join('config', 'locales', 'HASH')
  BACKUP_DIRECTORY = Rails.root.join('config', 'locales', 'BACKUP')
  
  # ======= OPTION 2 =================
  # Uncomment these lines to use HASH format for I18n.
  # Changes in the localization definitions are immediatly seen in the application
  # Use EXPORT YAML FILES from time to time to create snapshots for backup 
  # YAML_DIRECTORY = Rails.root.join('config', 'locales', 'YAML')
  # HASH_DIRECTORY = Rails.root.join('config', 'locales')
  # BACKUP_DIRECTORY = Rails.root.join('config', 'locales', 'BACKUP')

  # ======= OPTION 3 =================
  # Uncomment these lines to use HASH format for I18n with the localization files
  # in public/system. Useful if you're editing localization records on a server to which
  # you deploy the application (using Capistrano). public/system is NOT overwritten at deploy
  # You need to explicitly EXPORT YAML FILES to see changes in the localization definitions
  # YAML_DIRECTORY = Rails.root.join('public', 'system','locales', 'YAML')
  # HASH_DIRECTORY = Rails.root.join('public', 'system', 'locales')
  # BACKUP_DIRECTORY = Rails.root.join('public', 'system', 'locales', 'BACKUP')
  
  
  MAX_BACKUPS = 3
  LOCALES = {'en' => 'English', 'sv' => 'Svenska'}

  #
  # Verify that the directories exist. If not: create them.
  require "fileutils"
  [YAML_DIRECTORY, HASH_DIRECTORY, BACKUP_DIRECTORY].each{|thedir| FileUtils.mkdir_p(thedir)}

  puts "Interpretatio Engine initialized:"
  puts "  YAML files in #{YAML_DIRECTORY}"
  puts "  Localization hash file in #{HASH_DIRECTORY}"
  puts "  Backups in #{BACKUP_DIRECTORY}"
  puts "  Number of backups to be kept #{MAX_BACKUPS}"
  puts "  Languages supported #{LOCALES.inspect}"

end
