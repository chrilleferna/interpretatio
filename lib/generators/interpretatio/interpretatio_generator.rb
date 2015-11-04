require 'rails/generators'
require 'rails/generators/named_base'
module Interpretatio
  module Generators

class InterpretatioGenerator < Rails::Generators::Base
  source_root(File.expand_path(File.dirname(__FILE__))
  def copy_initializer
    copy_file 'myfile.rb', 'config/initializers/myfile.rb'
  end
end
end
end
