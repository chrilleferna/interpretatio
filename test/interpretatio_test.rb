require 'test_helper'

class InterpretatioTest < ActiveSupport::TestCase
  test "truth1" do
    puts "Running vanilla test"
    assert_kind_of Module, Interpretatio
  end
end
