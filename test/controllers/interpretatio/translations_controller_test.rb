require 'test_helper'

module Interpretatio
  class TranslationsControllerTest < ActionController::TestCase

    # ======================= Setup and helper routines ==========================
    HASH_FILE = HASH_DIRECTORY+'mega.rb'
  
    setup do
      @routes = Engine.routes
    end
    
    def cleanup_all_files
      # Remove all data files
      FileUtils.rm_f Dir.glob(File.join(HASH_DIRECTORY,"*"))
      FileUtils.rm_f Dir.glob(File.join(YAML_DIRECTORY,"*"))
      FileUtils.rm_f Dir.glob(File.join(BACKUP_DIRECTORY,"*"))
    end
    
    
    def copy_yaml_file(name)
      FileUtils.cp((Rails.root.join("..", "datafiles", "#{name}.yml")), YAML_DIRECTORY)
    end

    def copy_yaml_files
      copy_yaml_file('en')
      copy_yaml_file('sv')
    end
    
    def load_yaml_file(name)
      YAML::load(File.open(Rails.root.join("..", "datafiles", "#{name}.yml")))
    end
    
    def init_normal
      # Create hashfile and hash in @mega. Remove any offending YAML files. Set @mega
      cleanup_all_files
      y1 = load_yaml_file('en')
      y2 = load_yaml_file('sv')
      @mega = y1.rmerge(y2)
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      FileUtils.rm Dir.glob(File.join(HASH_DIRECTORY, "*.yml"))
    end
    
    def init_normal_and_first_backup
      init_normal
      # Put YAML files in YAML_DIRECTORY and clean out BACKUP files
      copy_yaml_files
      FileUtils.rm Dir.glob(File.join(BACKUP_DIRECTORY, "*.yml"))
      # First run should create copies of original YAML files
      get :backup_files
    end

    
    # ====================== Test of: before filter that checks the configuration =====
    
    test "should redirect to fix_config with errorcode = 1 when no hash file" do
      cleanup_all_files
      get :index
      assert_redirected_to fix_config_translations_path({:errcode => "1"})
    end
    
    test "should redirect to fix_config with errorcode = 2 when language missing in hash file" do
      y1 = load_yaml_file('en')
      File.open(HASH_FILE, "w") {|file| file.puts y1.inspect }
      get :index
      assert_redirected_to fix_config_translations_path({:errcode => "2", :langs_not_in_hash => ['sv']})
    end
    
    test "should redirect to fix_config with errorcode = 3 when superfluous language in hash file" do
      y1 = load_yaml_file('en')
      y2 = load_yaml_file('fr')
      y3 = load_yaml_file('sv')
      mega = y1.rmerge(y2).rmerge(y3)
      File.open(HASH_FILE, "w") {|file| file.puts mega.inspect }
      get :index
      assert_redirected_to fix_config_translations_path({:errcode => "3", :keys_not_in_langs => ['fr'], :have_data => true})
    end
    
    test "should not redirect but display a warning if offending YAML files are in the HASH directory" do
      # 1) make hash file OK
      init_normal
      # 2) put offending YAML file in HASH dir
      FileUtils.cp((Rails.root.join("..", "datafiles", "en.yml")), HASH_DIRECTORY)
      get :index
      assert_response(:success, "Redirected when it shouldn't")
      # the flash should have a warning message related to YAML (case insensitive)
      assert_match(/.*YAML.*/i, flash[:warning], "No YAML-related message in the flash: #{flash.inspect}")
      assert_select "#flash_warning" do |elem|
        assert_not_nil (/YAML/i =~ elem.text), "No WARNING message displayed to user"
      end
    end
    
    # ====================== Test of method: create ====================================

    test "adding new path should extend the hash and display confirmation" do
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :create, :key => 'models.tents'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      lgth2 = @mega2.hash_to_paths.length
      assert_equal(2, lgth2-lgth1, "Adding a path did not add one path per language")
      assert @mega2.hash_to_paths.include?(["en", "models", "tents"]), "The added path does not appear in the paths"
      assert_not_nil(/created/i =~ flash[:notice], "No notice message in the flash")
      assert_redirected_to translations_path
      # Would have liked to assert flash notice on the page, but this does not work after redirect
      # assert_select '#flash_notice' do |elem|
      #   assert_not_nil (/created/i =~ elem.text), "No notice message displayed to user"
      # end
    end
    
    test "attempt to add a new path with illegal characters should not extend the hash and display error message" do
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :create, :key => 'models.te<nts'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      lgth2 = @mega2.hash_to_paths.length
      assert_equal(0, lgth2-lgth1, "Adding path with illegal characters was accepted")
      assert !@mega2.hash_to_paths.include?(["en", "models", "te<nts"]), "Adding path with illegal characters was accepted"
      assert flash[:error].length > 3, "No error message in the flash"
    end
    
    test "attempt to add a new path with illegal format should not extend the hash and display error message" do
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :create, :key => 'models.tents.'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      lgth2 = @mega2.hash_to_paths.length
      assert_equal(0, lgth2-lgth1, "Adding path with illegal format was accepted")
      assert !@mega2.hash_to_paths.include?(["en", "models", "tents."]), "Adding path with illegal format was accepted"
      assert flash[:error].length > 3, "No error message in the flash"
    end
      
    # ====================== Test of method: update_path ===============================

    test "changing leaf path to correct new path" do
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :update_path, :current_path => 'models.cars', :new_path => 'models.automobiles'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      lgth2 = @mega2.hash_to_paths.length
      assert_equal(0, lgth2-lgth1, "Changing the path modified the size of the hash")
      assert @mega2.hash_to_paths.include?(["en", "models", "automobiles"]), "The new path does not appear in the paths"
      assert_equal(@mega2.rread(["sv", "models", "automobiles"]), "bilar", "Could not read from the new path")
    end
    
    test "changing internal path to correct new path" do
      # This can not be done via the UI, but perhaps via future API
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :update_path, :current_path => 'models', :new_path => 'prototypes'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      lgth2 = @mega2.hash_to_paths.length
      assert_equal(0, lgth2-lgth1, "Changing the path modified the size of the hash")
      assert_includes @mega2.hash_to_paths, ["en", "prototypes", "cars"], "The new path does not appear in the paths"
      assert_equal("bilar", @mega2.rread(["sv", "prototypes", "cars"]), "Could not read from the new path")
    end
    
    test "attempt to change path to new path with illegal characters should not be accepted" do
      init_normal
      lgth1 = @mega.hash_to_paths.length
      post :update_path, :current_path => 'models.cars', :new_path => 'models.car<s'
      File.open(HASH_FILE, "r") {|file| @mega2 = eval(file.read)}
      assert_not_includes @mega2.hash_to_paths, ["en", "models", "car<s"], "The erraneous path appears in the paths"
      assert flash[:error].length > 3, "No error message in the flash"
    end
    
    # ====================== Test of method: backup_files ==============================
    
    test "backup" do
      init_normal_and_first_backup 
      yml_origins = Dir.glob(File.join(BACKUP_DIRECTORY, "*_original.yml")).collect{|fpath| fpath.split('/').last}
      assert_includes yml_origins, "en_original.yml", "Original YML files not backed up"
      assert_equal 2, yml_origins.length, "Wrong number of original YML files backed up"
      yml_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*_bu*.yml")).collect{|fpath| fpath.split('/').last}
      assert_includes yml_bus, "sv_bu0.yml", "YML files not correctly backed up"
      assert_equal 2, yml_bus.length, "Wrong number of YML backup files"
      rb_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*_bu*.rb")).collect{|fpath| fpath.split('/').last}
      assert_includes rb_bus, "mega_bu0.rb", "HASH file not correctly backed up"
      assert_equal 1, rb_bus.length, "Wrong number of HASH backup files"
      all_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*"))
      assert_equal 5, all_bus.length, "Wrong total number of backup files"
      # Second and third run should create 3 more backup files
      get :backup_files
      all_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*"))
      assert_equal 8, all_bus.length, "Wrong total number of backup files"
      get :backup_files
      all_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*"))
      assert_equal 11, all_bus.length, "Wrong total number of backup files"
      # Forth run should create no more files
      get :backup_files
      all_bus = Dir.glob(File.join(BACKUP_DIRECTORY, "*"))
      assert_equal 11, all_bus.length, "Wrong total number of backup files"      
    end

    # ====================== Test of method: backup_revert =============================

    test "revert backups" do
      init_normal_and_first_backup
      # Make a modification, test it, then revert and test that we have the original value
      @mega = @mega.rput('en.models.cars'.split('.'), 'automobiles', true)
      assert_not_equal false, @mega, "Rput failed"
      assert_equal('automobiles', @mega.rread('en.models.cars'.split('.')))
      get :backup_revert
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal('cars', @mega.rread('en.models.cars'.split('.')), "Did nto revert")
    end

    # ====================== Test of method: initialize_hash_file ======================
    
    test "initialize_hash_file" do
      cleanup_all_files
      assert_equal 0, Dir.glob(File.join(HASH_DIRECTORY, "*.rb")).length
      get :initialize_hash_file
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal 2, @mega.keys.length, "Wrong number of languages initiated in hash file"
      assert_equal({}, @mega['en'], "Language badly initiated in hash file")
    end
    
    # ====================== Test of method: add_languages_to_hash =====================
    
    test "add languages to hash" do
      cleanup_all_files
      get :initialize_hash_file # We know this should work since tested above
      get :add_languages_to_hash, :langs_not_in_hash => ['es', 'it']
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal 4, @mega.keys.length, "Wrong number of languages in hash file after adding es and it"
      assert_equal({}, @mega['it'], "Language it not added")
    end
    
    
    # ====================== Test of method: remove_languages_from_hash ================
    
    test "remove_languages_from_hash" do
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      assert_equal 2, @mega.keys.length
      get :remove_languages_from_hash, :keys_not_in_langs => ['sv']
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal 1, @mega.keys.length, "One language was not removed"
      assert_nil @mega.rread('sv.models.cars'.split('.')), "Swedish translation not removed"
      assert_equal "cars", @mega.rread('en.models.cars'.split('.')), "English translation changed"      
    end
    
    # ====================== Test of method: index and set_filter ======================
    # Tested only manually with UI
    
    # ====================== Test of method: destroy ===================================
    
    test "destroy leaf node with existing key" do
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      no_paths = @mega.hash_to_paths.length # Number of localization keys
      delete :destroy, :key => ['models', 'cars'] 
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal no_paths-2, @mega.hash_to_paths.length, "Record not removed for the two languages"
      assert_nil @mega.rread('sv.models.cars'.split('.')), "Record not correctly deleted from Swedish"
    end

    test "destroy with non-existing key" do
      # Should do nothing but not complain
      init_normal
      no_paths = @mega.hash_to_paths.length # Number of localization keys
      oldmega = @mega
      delete :destroy, :key => ['models', 'boats'] 
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal no_paths, @mega.hash_to_paths.length, "Record(s)  removed from hash"
      assert_equal oldmega, @mega, "Record(s)  removed from hash"
    end
    
    test "destroy internal node with existing key" do
      # This can not be done through the usual UI
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      no_paths = @mega.hash_to_paths.length # Number of localization keys
      delete :destroy, :key => ['models'] # Should remove 3 leaf nodes from each language
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal no_paths-6, @mega.hash_to_paths.length, "Record not removed for the two languages"
      assert_nil @mega.rread('sv.models.cars'.split('.')), "Record not correctly deleted from Swedish"
    end

    
    # ====================== Test of method: update_record =============================

    test "Update_record with legal and existing key and legal new value. Calling via HTTP" do
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      get :update_record, :key => 'sv.models.cars', :new_value => 'automobiler'
      assert_redirected_to translations_path, "Redirected when it shouldn't"
      assert_equal "Data updated", flash[:notice], "Incorrect flash message"
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal "automobiler", @mega.rread('sv.models.cars'.split('.')), "Translation not updated"
    end
      
    test "Update_record with illegal key and legal new value. Calling via HTTP" do
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      oldmega = @mega
      get :update_record, :key => 'sv.mod<els.cars', :new_value => 'automobiler'
      assert_redirected_to translations_path, "Redirected when it shouldn't"
      assert_equal "Invalid translation key", flash[:error], "Incorrect flash message"
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal oldmega, @mega, "Record(s) changed from hash"
    end
      
    test "Update_record with legal key and illegal new value. Calling via HTTP" do
      init_normal
      assert_equal "bilar", @mega.rread('sv.models.cars'.split('.'))
      oldmega = @mega
      get :update_record, :key => 'sv.models.cars', :new_value => 'automobiler <script>alert(22)</script'
      assert_redirected_to translations_path, "Redirected when it shouldn't"
      assert_equal "Invalid translation value", flash[:error], "Incorrect flash message"
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal oldmega, @mega, "Record(s) changed from hash"
    end
      
    # ====================== Test of method: import_files ==============================
    test "Import WITHOUT overwrite" do
      # Do not overwrite other than empty on non-existing records
      init_normal
      FileUtils.cp(Rails.root.join("..", "datafiles", "en_extended.yml"), File.join(YAML_DIRECTORY, "en.yml"))
      copy_yaml_file('sv')
      get :import_files, :overwrite => "no"
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal "ships", @mega.rread('en.models.boats'.split('.')), "New translation record not added"
      assert_equal "houses", @mega.rread('en.models.houses'.split('.')), "Existing translation record was modified"
      assert_equal "2 YAML file(s) imported", flash[:notice], "Incorrect flash message"
    end
    
    test "Import WITH overwrite" do
      # Do not overwrite other than empty on non-existing records
      init_normal
      FileUtils.cp(Rails.root.join("..", "datafiles", "en_extended.yml"), File.join(YAML_DIRECTORY, "en.yml"))
      copy_yaml_file('sv')
      get :import_files, :overwrite => "yes"
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      assert_equal "ships", @mega.rread('en.models.boats'.split('.')), "New translation record not added"
      assert_equal "different", @mega.rread('en.models.houses'.split('.')), "Existing translation record was modified"
    end
    
  end
end
