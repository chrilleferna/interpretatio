require_dependency "interpretatio/application_controller"

module Interpretatio
  class TranslationsController < ApplicationController   
    require 'interpretatio/mylib'
    before_filter :check_config, :except => [:fix_config, :initialize_hash_file, :add_languages_to_hash, :remove_languages_from_hash]
    before_filter :_interpreatio_authorization
    
    def _interpreatio_authorization
      # If there is an authorization hook in the application then call it
      try(:interpretatio_authorization)
    end
    

    LANGS =  LOCALES.keys
    LANGUAGES = LOCALES.values
    HASH_FILE = File.join(HASH_DIRECTORY, 'mega.rb')

    $KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'
    
    # Verification of the configuration: the before_filter check_config checks and in case of problems it redirects to
    # fix_config, which presents the user with various options to fix the configuration.
    # The methods add_languages_to_hash and remove_languages_from_hash may be called as part of the fixing
    #
    def fix_config
      @errcode = params[:errcode].to_s
      @have_data = params[:have_data] == "true"
      @keys_not_in_langs = params[:keys_not_in_langs]
      @langs_not_in_hash = params[:langs_not_in_hash]
      @hash_directory = HASH_DIRECTORY
      @yaml_directory = YAML_DIRECTORY
      @backup_directory = BACKUP_DIRECTORY
    end
    
    def initialize_hash_file
      @mega = {}
      LANGS.each{|lang| @mega[lang] = {}}
      File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      flash[:notice] = "Empty Hash file created"
      redirect_to :action => :index
    end      
    
    def add_languages_to_hash
      langs_not_in_hash = params[:langs_not_in_hash]
      File.open(HASH_FILE, "r") {|file| @mega = eval(file.read)}
      langs_not_in_hash.each{|lang| @mega[lang] = {}}
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
    
    # Index presents localization records
    # set_filter may be called from the index view to limit the localization records to be shozn
    #
    def index
      session[:localization_section] = session[:localization_section] || "none"
      @all_langs = LANGS
      @all_languages = LANGUAGES
      @toplevels = @mega[LANGS[0]].keys.sort
      @the_section = session[:localization_section] || ""
      @selected_langs = session[:localization_language] || @all_langs
      @translation_quality = session[:translation_quality] || "any"
      @path_array = @mega[@all_langs[0]].hash_to_paths.rsort
    end

    def set_filter
      # Modify filter settings
      session[:localization_section] =  params[:filter_section] == "all" ? "" : params[:filter_section]
      session[:localization_language] = params[:language] || []
      redirect_to :action => :index
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
      if legal_key?(params[:new_path])
        if current_path == new_path
          flash[:notice] = "Not modified since you entered the current key"
          redirect_to :action => :index
          return
        end
        ok = true
        for lang in LANGS do
          lcurr = [lang].concat(current_path)
          lnew = [lang].concat(new_path)
          current_value = @mega.rread(lcurr) || {}
          @mega = @mega.rput(lnew, current_value, true, true)
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
      else
        flash[:error] = "The translation key you provided is invalid"
      end
      redirect_to :action => :index
    end
    
  
    def new
      #return render :text => params.inspect
      @key = params[:key].present? ? params[:key].join('.') : ""
    end

    def create
      # return render :text => params.inspect
      if legal_key?(params[:key])
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
          flash[:error] = "Key or part of it exists already and has localization data"
        else
          for lang in LANGS do
            lpath = [lang].concat(path)
            @mega = @mega.rput(lpath, nil, true)
            # Don't need to test the result of rput here since we already know that there is no data at lpath
          end
          File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
          flash[:notice] = "New key created: #{path.join('.')}"
        end
      else
        flash[:error] = "The translation key you provided is invalid"
      end
      redirect_to :action => :index
    end


    # update_record method will be called via AJAX except when we test
    def update_record
      @val = params[:new_value]=="nil" ? nil : params[:new_value]
      @key = params[:key]
      ok = true
      unless legal_key?(params[:key])
        ok = false
        errmsg = "Invalid translation key"
      end
      unless legal_value?(@val)
        ok = false
        errmsg = "Invalid translation value"
      end
      if ok
        path = params[:key].split('.')
        @underscored_key = path.join('_') # jQuery will like this better than a string with dots
        @mega = @mega.rput(path, @val, true)
        if !@mega
          ok = false
          errmsg = "Could not update"
        end
      end
      @result="HICK"
      respond_to do |format|
        if ok
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
                flash[:error] = errmsg
                redirect_to :action => :index
          }
          format.js
          format.json {}
        end
      end
    end
  
  
    # backup_files will:
    # - make sure that we have a copy of any initial YAML files in BACKUP
    # - create rotating backups for YAML files and the HASH file
    # - export the HASH to new YAML files
    def backup_files
      # Make sure that all language YAML files have an original version in the BACKUP directory
      Dir.glob(File.join(YAML_DIRECTORY, "*.yml")).each do |yaml_filename|
        lang = yaml_filename.split('/').last.split('.')[0] # Notice that yaml_filename contains directory path
        unless File.exist?(File.join(BACKUP_DIRECTORY, "#{lang}_original.yml"))
          FileUtils.copy(File.join(YAML_DIRECTORY, "#{lang}.yml"), File.join(BACKUP_DIRECTORY, "#{lang}_original.yml"))
        end
      end
      # Rotate backup files to give room for the new backup
      _rolling_backup_one('mega', 'rb')
      for lang in LANGS do
        _rolling_backup_one(lang, 'yml')
      end
      # Export HASH to YAML files
      for lang in LANGS do
        s = "# YAML file created by export from Interpretio at #{Time.now}\n"
        s << "#{lang}:"
        s << @mega[lang].to_yaml(1)
        File.open(File.join(YAML_DIRECTORY, "#{lang}.yml"), "w") {|file| file.puts s }
      end
      flash[:notice] = "Files have been backed up and new YAML files created from the HASH"
      redirect_to :action => :import_export
    end
    
    def _rolling_backup_one(name, filetype)
      # Perform a rolling backup of one file, which is either a yaml or a ruby file
      raise ArgumentError, "Wrong filetype" unless (filetype == 'rb') || (filetype == "yml")
      # 0) We only do this if the file exists
      if ((filetype == "yml") && File.exist?(File.join(YAML_DIRECTORY, "#{name}.yml"))) ||
         ((filetype == "rb") && File.exist?(File.join(HASH_DIRECTORY, "#{name}.rb")))
        # 1) Rotate existing backup files to give room for the new backup
        backup_no = 0 # Count number of backup files with most recent being no 0
        while File.exist?(File.join(BACKUP_DIRECTORY, "#{name}_bu#{backup_no.to_s}.#{filetype}")) do
          backup_no = backup_no + 1
        end
        if backup_no >= MAX_BACKUPS
        # 2) If we reach max count then remove the least recent one
          FileUtils.remove(File.join(BACKUP_DIRECTORY, "#{name}_bu#{(backup_no-1).to_s}.#{filetype}"))
          backup_no = backup_no - 1
        end
        # 3) Renumber the backup files
        for ind in backup_no.downto(1) do
          logger.debug "Move #{BACKUP_DIRECTORY}/#{name}_bu#{(ind-1).to_s}.#{filetype} to #{BACKUP_DIRECTORY}/#{name}_bu#{ind.to_s}.#{filetype}"
          FileUtils.mv(File.join(BACKUP_DIRECTORY, "#{name}_bu#{(ind-1).to_s}.#{filetype}"),
                       File.join(BACKUP_DIRECTORY, "#{name}_bu#{ind.to_s}.#{filetype}"))
        end
        # 4) Copy the original file
        if filetype == "yml"
          logger.debug "Copy #{YAML_DIRECTORY}/#{name}.yml to #{BACKUP_DIRECTORY}/#{name}_bu0.yml"
          FileUtils.copy(File.join(YAML_DIRECTORY, "#{name}.yml"), File.join(BACKUP_DIRECTORY, "#{name}_bu0.yml"))
        else
          logger.debug "Copy #{HASH_DIRECTORY}/#{name}.rb to #{BACKUP_DIRECTORY}/#{name}_bu0.rb"
          FileUtils.copy(File.join(HASH_DIRECTORY, "#{name}.rb"), File.join(BACKUP_DIRECTORY, "#{name}_bu0.rb"))
        end
      end
    end
      
    
    def backup_revert
      # Copy the latest HASH backup (if it exists) to the HASH file
      # We do not currently renumber the backup files, meaning that subsequent reverts will always load the same file
      if File.exist?(File.join(BACKUP_DIRECTORY, "mega_bu0.rb"))
        FileUtils.copy(File.join(BACKUP_DIRECTORY, "mega_bu0.rb"), File.join(HASH_DIRECTORY, "mega.rb"))
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
        if File.exist?(File.join(YAML_DIRECTORY, "#{lang}.yml"))
          num += 1
          data = YAML::load( File.open(File.join(YAML_DIRECTORY, "#{lang}.yml" )))
          if overwrite
            @mega = @mega.deep_merge(data)
          else
            @mega = data.deep_merge(@mega)
          end
        end
      end
      if num > 0
        File.open(HASH_FILE, "w") {|file| file.puts @mega.inspect }
      end
      flash[:notice] = "#{num} YAML file(s) imported"
      redirect_to :action => :import_export
    end

    # LIBRARY ROUTINES
    # ================
    private
  
  
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
    
    
    def legal_key?(key)
      # word, optionally followed by any number of  .word
      # logger.debug "\n\n#{key} : #{path =~ /^[a-z]*(\.[a-z]+)*$/}\n\n"
      return !(key =~ /^[a-z]*(\.[a-z]+)*$/).nil?
    end
    
    def legal_value?(val)
      # accept any string except if it contains '<script'
      return (val =~ /.*<script.*/i).nil?
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
      rescue Exception => e 
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
      # Look for YAML files in the HASH directory that would impact the I18n 
      possibly_offending = LANGS.collect{|lang| HASH_DIRECTORY.join(lang+'.yml')}
      logger.debug "POSSIBLE OFFENDING: #{possibly_offending.inspect}"
      #if Dir.glob(HASH_DIRECTORY+"*.yml").length > 0
      if Dir.glob(possibly_offending).length > 0
        flash[:warning] = "Please notice that there are Yaml files for the selected langiages in the Hash directory. These should be moved"
      end
      return true
    end

  end
end
