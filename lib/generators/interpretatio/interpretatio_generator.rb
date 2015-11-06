require 'rails/generators'

module Interpretatio
  module Generators
    class InterpretatioGenerator < Rails::Generators::Base
      source_root(File.expand_path(File.dirname(__FILE__)))
      def copy_initializer
        copy_file 'interpretatio_initializer.rb', 'config/initializers/interpretatio_initializer.rb'
      end
    end
  end
end
