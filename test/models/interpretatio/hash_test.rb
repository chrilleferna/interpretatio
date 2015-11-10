require 'test_helper'
class HashTest < ActiveSupport::TestCase
  require 'interpretatio/mylib'
  
  test "loading of YAML into HASH" do
    puts "the dir is"+File.dirname(File.expand_path('..', '..','fixtures','interpretatio', __FILE__)).to_s
    #y1 = YAML::load( File.open(YAML_DIRECTORY+"#{lang}.yml" ))
  end
  
  test "recursive merge of hashes" do
    def hash_to_yaml(h, level=0)
      # Return a string of pretty printed YAML code from the hash
      str = ""
      for key in h.keys do
        str << "\n" + " "*level*2 + key.to_s + ": "
        if h[key].class == {}.class
          str << hash_to_yaml(h[key], level+1)
        else
          str << h[key].inspect
        end
      end
      str
    end


    h1 = {
      h11: 'h11_v1',
      h12:
      {
        h111_1: 'h111_1_v1',
        h111_2: 'h111_2_v1'
      },
      h13: 'h13_v1',
      h14: 'h1_v1'
    }

    h2 = {
      h11: 'h21_v1',
      h12:
      {
        h111_3: 'h111_3_v1',
        h111_2: 'h211_2_v1',
      },
      h22:
      {h221: 'h221_v1'},
      h23: 'h23_v1', 
      h24: 'h24_v1'
    }


    h21 = {
      h11: "h11_v1",
      h12:
      {
        h111_1: 'h111_1_v1',
        h111_2: 'h111_2_v1',
        h111_3: 'h111_3_v1'
      },
      h13: 'h13_v1',
      h14: 'h1_v1',
      h22:
      {h221: 'h221_v1'},
      h23: 'h23_v1', 
      h24: 'h24_v1'
    }

    h12 = {
    h12: {
      h111_1: "h111_1_v1",
      h111_3: "h111_3_v1",
      h111_2: "h211_2_v1"
    },
    h13: "h13_v1",
    h11: "h21_v1",
    h14: "h1_v1",
    h22: {
      h221: "h221_v1"
    },
    h23: "h23_v1",
    h24: "h24_v1"
    }

    assert_equal h12, h1.rmerge(h2)
    assert_equal h21, h2.rmerge(h1)
  end
end

# puts "="*30
# puts "h1"
# puts "="*30
# puts hash_to_yaml(h1)
# puts "="*30
# puts "h2"
# puts "="*30
# puts hash_to_yaml(h2)
# puts "="*30
# puts "h21"
# puts "="*30
# puts hash_to_yaml(h21)
# puts "="*30
# puts "h2.rmerge(h1)"
# puts "="*30
# puts hash_to_yaml(h2.rmerge(h1))
# puts "="*30
# puts "h12"
# puts "="*30
# puts hash_to_yaml(h12)
# puts "="*30
# puts "h1.rmerge(h2)"
# puts "="*30
# puts hash_to_yaml(h1.rmerge(h2))
# puts "="*50
# puts h1==h2
# puts h21==h2.rmerge(h1)
# puts h12==h1.rmerge(h2)