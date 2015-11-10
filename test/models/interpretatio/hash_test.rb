require 'test_helper'

# Tests of our hash extensions
class HashTest < ActiveSupport::TestCase
  require 'interpretatio/mylib'
  
  test "hash to yaml" do
    # load YAML into HASH, save as new HAML, reload and compare
    y1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    s1 = y1.to_yaml
    File.open(Rails.root.join("../tmp/yaml1.yml"), "w") {|file| file.puts s1 }
    y2 = YAML::load(File.open(Rails.root.join("../tmp/yaml1.yml")))
    assert_equal y2, y1
  end
  
  test "recursive merge of hashes" do
    # rmerge not used. We use Rail' deep_merge instead
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = YAML::load(File.open(Rails.root.join("../datafiles/yaml2.yml")))
    h12 = YAML::load(File.open(Rails.root.join("../datafiles/yaml12.yml")))
    h21 = YAML::load(File.open(Rails.root.join("../datafiles/yaml21.yml")))
    assert_equal h1.rmerge(h2),h12
    assert_equal h2.rmerge(h1),h21
  end
  
  test "hash to paths" do
    # should return an array of all the path arrays where we can find data in the self nested hash 
    h21 = YAML::load(File.open(Rails.root.join("../datafiles/yaml21.yml")))
    p=h21.hash_to_paths
    a = [%w(yaml1 lev00 lev1 abe), %w(yaml1 lev00 lev1 cde), %w(yaml1 lev00 lev1 xyz), %w(yaml1 lev00 lev2 p2p),
        %w(yaml1 lev00 lev2 l2op), %w(yaml1 lev00 lev3 abc), %w(yaml1 levx levxy), %w(yaml1 levx levxz),
        %w(yaml1 lev01 lev11), %w(yaml1 lev01 lev12), %w(yaml1 lev01 lev13 lev131), %w(yaml1 lev01 lev13 lev132),
        %w(yaml1 lev01 lev14)
        ]
    assert_equal p, a
  end
  
  test "remove leaf level path" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h1.remove_path('yaml1.lev00.lev1.cde'.split('.'))
    h11 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1_remove1.yml")))
    assert_equal h11,h1
  end

  test "remove higher level path" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h1.remove_path('yaml1.lev00'.split('.'))
    h11 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1_remove2.yml")))
    assert_equal h11,h1
  end

  test "remove leaf that make parent childless should remove this parent" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h1.remove_path('yaml1.lev00.lev3.abc'.split('.'))
    h11 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1_remove3.yml")))
    assert_equal h11,h1
  end
  
  test "recursive read: leaf, non-leaf" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    v1 = h1.rread('yaml1.lev00.lev2.l2op'.split('.'))
    assert_equal v1, "po2l"
    v2 = h1.rread('yaml1.lev00'.split('.'))
    h2 = {'lev1' => {'abe' => 'eba', 'cde' => 'edc', 'xyz' => 'zyx'}, 'lev2' => {'p2p' => 'p2p', 'l2op' => 'po2l'}, 'lev3' => {'abc' => 'cba'}}
    assert_equal v2, h2
  end
  
  test "recursive read with erranous key and deeper key than what's in the hash" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    v1 = h1.rread('yaml1.kallepelle.lev2.l2op'.split('.'))
    v2 = h1.rread('yaml1.lev00.lev2.l2op.kallepelle'.split('.'))
    assert_nil v1
    assert_nil v2
  end
  
  test "recursive put into existing leaf with overwrite should succeed" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = h1.rput('yaml1.lev01.lev12'.split('.'), 'intepelle', true)
    assert_equal h1.rread('yaml1.lev01.lev12'.split('.')), 'pelle'
    assert_equal h2.rread('yaml1.lev01.lev12'.split('.')), 'intepelle'
  end
  
  test "recursive put into existing leaf without overwrite should fail" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = h1.rput('yaml1.lev01.lev12'.split('.'), 'intepelle')
    assert_equal h2, false
  end

  test "recursive put into internal node (hash) without hash-overwrite should fail" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = h1.rput('yaml1.lev01'.split('.'), 'intepelle',true)
    assert_equal h2, false
  end

  test "recursive put into internal node (hash) with hash-overwrite should succeed" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = h1.rput('yaml1.lev01'.split('.'), 'intepelle',true,true)
    assert_equal h2.rread('yaml1.lev01'.split('.')), 'intepelle'
  end
  
  test "recursive put adding a new substructure should succeed" do
    h1 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1.yml")))
    h2 = YAML::load(File.open(Rails.root.join("../datafiles/yaml1_extended1.yml")))
    assert_equal h1.rput('yaml1.lev00.lev2.newpart.aa.bb.cc'.split('.'),'dd'), h2
    assert_equal h2.rread('yaml1.lev00.lev2.newpart.aa.bb.cc'.split('.')), "dd"
  end


end

