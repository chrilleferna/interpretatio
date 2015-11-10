$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "interpretatio/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "interpretatio"
  s.version     = Interpretatio::VERSION
  s.authors     = ["Christer Fernstrom"]
  s.email       = ["christer@fernstromOnThe.net"]
  s.homepage    = ""
  s.summary     = "Interpretatio helps manage your translation files"
  s.description = "Kepp all your localization files in sync"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.4"
  s.add_dependency 'sass-rails', '~> 5.0'
  s.add_dependency 'uglifier', '>= 1.3.0'
  s.add_dependency 'therubyracer'#, platforms: :ruby
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jbuilder', '~> 2.0'
  s.add_dependency 'json'
  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'minitest-colorize' 
  s.add_development_dependency 'terminal-notifier-guard'
end
