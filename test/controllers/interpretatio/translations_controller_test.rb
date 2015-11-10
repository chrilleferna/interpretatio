require 'test_helper'

module Interpretatio
  class TranslationsControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "the truth" do
      puts "controller test"
      assert true
    end
    
    test "should redirect to fix_config when no hash_file" do
    end
  end
end
