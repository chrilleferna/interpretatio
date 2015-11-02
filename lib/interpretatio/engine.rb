module Interpretatio
  class Engine < ::Rails::Engine
    require "rails"
    require 'sass-rails'
    require 'uglifier'
    require 'therubyracer'#, platforms: :ruby
    require 'jquery-rails'
    require 'jbuilder'
    require 'json'
    isolate_namespace Interpretatio
  end
end
