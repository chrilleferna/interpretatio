require_dependency "interpretatio/application_controller"

module Interpretatio
  class TranslationsController < ApplicationController   
    require 'interpretatio/mylib'
    before_filter :check_config, :except => [:fix_config, :add_languages_to_hash, :remove_languages_from_hash]
    

    LANGUAGES_MAP = Interpretatio::LANGUAGES
    LANGS =  LANGUAGES_MAP.keys
    LANGUAGES = LANGUAGES_MAP.values
    HASH_DIRECTORY = Interpretatio::HASH_DIRECTORY+'/'
    YAML_DIRECTORY = Interpretatio::YAML_DIRECTORY+'/'
    BACKUP_DIRECTORY = Interpretatio::BACKUP_DIRECTORY+'/'
    MAX_BACKUPS = Interpretatio::MAX_BACKUPS
    HASH_FILE = HASH_DIRECTORY+'mega.rb'
    #LOCALES_DIR = Rails.root.to_s + '/config/locales/'
    #ORIGINAL_DIR = Rails.root.to_s + '/config/locales/original/'
    #BU_LIMIT = 3 # Max number of backup files to keep

    $KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'
    #require 'ya2yaml'
    
    
    def init_NU
      #init_languages_hash
      Hash.init_from_yaml
      redirect_to action: :index
    end
    
    def fix_config
      @errcode = params[:errcode].to_s
      @have_data = params[:have_data] == "true"
      @keys_not_in_langs = params[:keys_not_in_langs]
      @langs_not_in_hash = params[:langs_not_in_hash]
    end
    
    def add_languages_to_hash
      langs_not_in_hash = params[:langs_not_in_hash]
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      langs_not_in_hash.each{|lang| @mega[lang] = ""}
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      redirect_to :action => :index
    end
    
    def remove_languages_from_hash
      @keys_not_in_langs = params[:keys_not_in_langs]
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      for lang in @keys_not_in_langs do
        @mega.remove_path([lang])
      end
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      redirect_to :action => :index
    end
  
    def index
      session[:localization_section] = session[:localization_section] || "none"
      @all_langs = LANGS
      @all_languages = LANGUAGES
      @toplevels = @mega[LANGS[0]].keys.sort
      logger.debug "toplevels=#{@toplevels}"
      @the_section = session[:localization_section] || ""
      @selected_langs = session[:localization_language] || @all_langs
      @translation_quality = session[:translation_quality] || "any"
      # IMPROVE: Only send the section to the view
      @path_array = @mega[@all_langs[0]].hash_to_paths.rsort
      
    end
    
    def import_export
      @all_languages = LANGUAGES
      @yaml_directory = YAML_DIRECTORY
    end
  
    def destroy
      # render :text => params.inspect
      path = params[:key]
      for lang in LANGS do
        @mega.remove_path([lang].concat(path))
      end
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      flash[:notice] = "Translations for #{path.join('.')} deleted from all languages"
      redirect_to :action => :index
    end
  
    def edit_path
      @current_path = params[:key].join('.')
    end
  
    def update_path
      # render :text => params.inspect
      current_path = params[:current_path].split('.')
      new_path = params[:new_path].split('.')
      ok = true
      for lang in LANGS do
        lcurr = [lang].concat(current_path)
        lnew = [lang].concat(new_path)
        @mega = @mega.rput(lnew, @mega.rread(lcurr), true, false)
        if @mega
          @mega.remove_path(lcurr)
        else
          ok = false # This means we attempted to overwrite a deeper structure
          break
        end
      end
      if ok
        File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
        flash[:notice] = "The translation key #{current_path.join('.')} has been changed to #{new_path.join('.')} for all languages"
      else
        flash[:error] = "Changing the translation key to #{new_path.join('.')} is not possible, since there is already strucutured data with that key"
      end
      redirect_to :action => :index
    end
    
  
    def new
      #return render :text => params.inspect
      @key = params[:key].join('.')
    end

    def create
      # return render :text => params.inspect
      path = params[:key].split('.')
      exists_already = false
      for lang in LANGS do
        lpath = [lang].concat(path)
        if @mega.rread(lpath)
          exists_already = true
          break
        end
      end
      if exists_already
        flash[:error] = "Key exists already"
      else
        for lang in LANGS do
          lpath = [lang].concat(path)
          @mega = @mega.rput(lpath, nil, true)
          # Don't need to test the result of rput here since we already know that there is no data at lpath
        end
        File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
        flash[:notice] = "New key created: #{path.join('.')}"
      end
      redirect_to :action => :index
    end
  
  
    def set_filter
      # Modify filter settings
      # return render :text => params.inspect
      session[:localization_section] =  params[:filter_section] == "all" ? "" : params[:filter_section]
      session[:localization_language] = params[:language] || []
      redirect_to :action => :index
    end

    # Update method can be called via AJAX

    def update_record
      @val = params[:new_value]=="nil" ? nil : params[:new_value]
      @key = params[:key]
      path = params[:key].split('.')
      @underscored_key = path.join('_') # jQuery will like this better than a string with dots
      @mega = @mega.rput(path, @val, true)
      @result="HICK"
      respond_to do |format|
        if @mega
          @result = "OK"
          File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
          format.html {
                flash[:notice] = "Data updated"
                redirect_to :action => :index
          }
          format.js
          format.json {}
        else
          @result = "Not OK"
          format.html {
                flash[:notice] = "Data NOT updated"
                redirect_to :action => :index
          }
          format.js
          format.json {}
        end
      end
    end
  
  
    def delete
      #return render :text => params.inspect
      @key = params[:key]
      for lang in LANGUAGES do
        remove_translation_record(lang, @key)
      end
      flash[:notice] = "Removed entry for #{@key}"
      redirect_to :action => :index
    end
  
  
    def backup_files
      # Make sure that all language YAML files have an original version in the BACKUP directory
      Dir.glob("#{YAML_DIRECTORY}*.yml").each do |yaml_filename|
        lang = yaml_filename.split('/').last.split('.')[0] # Notice that yaml_filename contains directory path
        unless File.exist?(BACKUP_DIRECTORY+lang+"_original.yml")
          logger.debug "Copying original YAML file #{YAML_DIRECTORY}#{lang}.yml to backup directory"
          FileUtils.copy(YAML_DIRECTORY+lang+'.yml', BACKUP_DIRECTORY+lang+'_original.yml')
        end
      end
      # Rotate backup files to give room for the new backup
      _rolling_backup_one('mega', 'rb')
      for lang in LANGS do
        _rolling_backup_one(lang, 'yml')
      end
      # Export HASH to YAML files
      for lang in LANGS do
        s = "#YAML file created by export from Interpretio at #{Time.now}\n"
        s << "#{lang}:"
        s << hash_to_yaml(@mega[lang],1)
        File.open(YAML_DIRECTORY+lang+".yml", "w") {|file| file.puts s }
      end
      flash[:notice] = "Files have been backed up and new YAML files created from the HASH"
      redirect_to :action => :import_export
    end
    
    def _rolling_backup_one(name, filetype)
      # Perform a rolling backup of one file, which is either a yaml or a ruby file
      raise ArgumentError, "Wrong filetype" unless (filetype == 'rb') || (filetype == "yml")
      # 0) We only do this if the file exists
      if ((filetype == "yml") && File.exist?(YAML_DIRECTORY+name+".yml")) ||
         ((filetype == "rb") && File.exist?(HASH_DIRECTORY+name+".rb"))
        # 1) Rotate existing backup files to give room for the new backup
        backup_no = 0 # Count number of backup files with most recent being no 0
        while File.exist?(BACKUP_DIRECTORY+name+"_bu"+backup_no.to_s+"."+filetype) do
          backup_no = backup_no + 1
        end
        if backup_no >= MAX_BACKUPS
        # 2) If we reach max count then remove the least recent one
          logger.debug "Removing #{BACKUP_DIRECTORY}#{name}_bu#{(backup_no-1).to_s}.#{filetype}"
          FileUtils.remove(BACKUP_DIRECTORY+name+"_bu"+(backup_no-1).to_s+"."+filetype)
          backup_no = backup_no - 1
        end
        # 3) Renumber the backup files
        for ind in backup_no.downto(1) do
          logger.debug "Move #{BACKUP_DIRECTORY+name+'_bu'+(ind-1).to_s+'.'+filetype} to #{BACKUP_DIRECTORY+name+'_bu'+ind.to_s+'.'+filetype}"
          FileUtils.mv(BACKUP_DIRECTORY+name+'_bu'+(ind-1).to_s+'.'+filetype,
                       BACKUP_DIRECTORY+name+'_bu'+ind.to_s+'.'+filetype)
        end
        # 4) Copy the original file
        if filetype == "yml"
          logger.debug "Copy #{YAML_DIRECTORY+name+'.yml'} to #{BACKUP_DIRECTORY+name+'_bu0.yml'}"
          FileUtils.copy(YAML_DIRECTORY+name+'.yml', BACKUP_DIRECTORY+name+'_bu0.yml')
        else
          logger.debug "Copy #{HASH_DIRECTORY+name+'.rb'} to #{BACKUP_DIRECTORY+name+'_bu0.rb'}"
          FileUtils.copy(HASH_DIRECTORY+name+'.rb', BACKUP_DIRECTORY+name+'_bu0.rb')
        end
      end
    end
      
    
    def backup_revert
      # Copy the latest HASH backup (if it exists) to the HASH file
      # We do not currently renumber the backup files, meaning that subsequent reverts will always load the same file
      if File.exist?(BACKUP_DIRECTORY+"mega_bu0.rb")
        FileUtils.copy(BACKUP_DIRECTORY+'mega_bu0.rb', HASH_DIRECTORY+'mega.rb')
        flash[:notice] = "Reverted HASH to backup version"
      else
        flash[:warning] = "Could not revert since no backup file available"
      end
      redirect_to :action => :import_export
    end
    
    def import_files
      overwrite = (params[:overwrite] == "yes")
      num = 0
      for lang in LANGS do
        if File.exist?(YAML_DIRECTORY+lang+'.yml')
          num += 1
          data = YAML::load( File.open(YAML_DIRECTORY+lang+'.yml' ))
          if overwrite
            @mega = @mega.rmerge(data)
          else
            @mega = data.rmerge(@mega)
          end
        end
      end
      if num > 0
        File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      end
      flash[:notice] = "#{num} YAML files imported"
      redirect_to :action => :import_export
    end

    # LIBRARY ROUTINES
    # ================
    private
  
    def init_languages_hash
      # Called in the beginning of a session
      # Read in the original yaml files, sort and add any keys that are present in some but not all languages
      # Write the full hash to file
      full = {}
      data = {}
      LANGS.each {|language|
        data[language] = YAML::load( File.open(YAML_DIRECTORY+language+'.yml' ))[language].sort_by_key(true)
        full=full.rmerge(data[language])
      }
      @mega = {}
      LANGS.each do |language|
        @mega[language] = full.deep_dup # Create a deep copy
        @mega[language].set_values_from_other(data[language], path = [])
      end
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
    end
  
    def pretty_mega(heading)
      # Pretty print the @mega hash
      @res << "<h2>#{heading}</h2>"
      @mega.keys.each do |language|
        @res << "<h2>#{language}</h2>"
        @res << pretty(@mega[language])
      end
    end

  
  
    def pretty(h, level = 0)
      # Pretty hash printer that generates HTML to make the hash look like yaml
      str = ""
      #logger.debug "Called with #{h}"
      for key in h.keys do
        #logger.debug "Looping with #{key}"
        str << "<br>" + "&nbsp;"*level*6 + key.to_s + ": "
        if h[key].class == {}.class
          str << pretty(h[key], level+1)
        else
          str << h[key].inspect
        end
      end
      str
    end
    
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
  
    def pretty_fixed(h, data, path = [], level = 0)
      str = ""
      for key in h.keys do
        str << "<br>" + "&nbsp;"*level*4 + key.to_s + ": "
        if h[key].class == {}.class
          str << pretty_fixed(h[key], data, path + [key], level+1)
        else
          str << data.rread(path + [key]).inspect
        end
      end
      str
    end    

    def remove_translation_record(lang, key)
      logger.debug "Removing record. Language= #{lang}, Key=#{key}"
      @data = YAML::load( File.open(RAILS_ROOT+'/config/locales/'+lang+'.yml' ))
      keylist = [lang] + key.split('.')
      lastkey = keylist.pop
      deep_hash_access = keylist.inject(""){|memo, key| memo + "[\"#{key}\"]"}
      code = "@data#{deep_hash_access}.delete(#{lastkey.inspect})"
      #logger.debug code
      #logger.debug "\n\n\nBEFORE:"
      #logger.debug @data.inspect
      eval(code)
      #logger.debug "\n\n\nAFTER:"
      #logger.debug @data.inspect
      File.open(RAILS_ROOT+"/config/locales/#{lang}.yml", "w") {|file| file.puts(@data.delete_blank.ya2yaml) }
    end
    
    def check_config
      # load Hash file into global variable
      # filter to check for configuration problems:
      #  - No Hash file => Redirect to fix_config with message
      #  - A specified language not in the Hash file => Redirect to fix_config with message
      #  - A key in the Hash file not among the specified language => Redirect to fix_config with message
      #  - Yaml files in the HASH_DIRECTORY => Continue with error warning
      begin
        File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      rescue
        flash[:error] = "No Hash file with localization records found in #{HASH_DIRECTORY}"
        redirect_to :action => :fix_config, :errcode => 1
        return
      end
      keys = @mega.keys
      langs_not_in_hash = LANGS - keys
      keys_not_in_langs = keys - LANGS
      if langs_not_in_hash.length > 0
        flash[:error] = "The following languages are not yet in the Hash file: #{langs_not_in_hash}"
        redirect_to :action => :fix_config, :errcode => 2, :langs_not_in_hash => langs_not_in_hash
        return
      elsif keys_not_in_langs.length > 0
        are_empty = keys_not_in_langs.inject(true){|mem, lang| mem &&= @mega[lang].empty?}
        flash[:error] = "The following languages in the Hash file are not specified to be supported: #{keys_not_in_langs}"
        redirect_to :action => :fix_config, :errcode => 3, :have_data => !are_empty, :keys_not_in_langs => keys_not_in_langs
        return
      end
      if Dir.glob(HASH_DIRECTORY+"*.yml").length > 0
        flash[:warning] = "Please notice that there are Yaml files in the Hash directory. These should be moved"
      end
      return true
    end

  end
end
