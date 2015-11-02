require_dependency "interpretatio/application_controller"

module Interpretatio
  class TranslationsController < ApplicationController   
    require 'interpretatio/mylib'

    LANGUAGES_MAP = {'en' => 'English', 'sv' => 'Svenska'}
    LANGS =  LANGUAGES_MAP.keys
    LANGUAGES = LANGUAGES_MAP.values
    LOCALES_DIR = Rails.root.to_s + '/config/locales/'
    ORIGINAL_DIR = Rails.root.to_s + '/config/locales/original/'
    BU_LIMIT = 3 # Max number of backup files to keep

    $KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'
    #require 'ya2yaml'
    
    
    def init
      init_languages_hash
      redirect_to action: :index
    end
  
    def index
      File.open(LOCALES_DIR + 'mega.rb', "r") {|file| @mega = eval(file.read) }
      session[:localization_section] = session[:localization_section] || "none"
      @all_langs = LANGS
      @all_languages = LANGUAGES
      @toplevels = @mega[LANGS[0]].keys.sort
      logger.debug "toplevels=#{@toplevels}"
      @the_section = session[:localization_section] || ""
      @selected_langs = session[:localization_language] || @all_langs
      @translation_quality = session[:translation_quality] || "any"
    end
  
    def destroy
      # render :text => params.inspect
      path = params[:key]
      File.open(LOCALES_DIR + 'mega.rb', "r") {|file| @mega = eval(file.read) }
      for lang in LANGS do
        @mega.remove_path([lang].concat(path))
      end
      File.open(Rails.root.to_s+'/config/locales/mega.rb', "w") {|file| file.puts @mega.inspect }
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
      File.open(LOCALES_DIR + 'mega.rb', "r") {|file| @mega = eval(file.read)}
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
        File.open(Rails.root.to_s+'/config/locales/mega.rb', "w") {|file| file.puts @mega.inspect }
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
      File.open(LOCALES_DIR + 'mega.rb', "r") {|file| @mega = eval(file.read) }
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
        File.open(Rails.root.to_s+'/config/locales/mega.rb', "w") {|file| file.puts @mega.inspect }
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
      File.open(LOCALES_DIR + 'mega.rb', "r") {|file| @mega = eval(file.read) }
      @mega = @mega.rput(path, @val, true)
      @result="HICK"
      respond_to do |format|
        if @mega
          @result = "OK"
          File.open(Rails.root.to_s+'/config/locales/mega.rb', "w") {|file| file.puts @mega.inspect }
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

  
  
    # LIBRARY ROUTINES
    # ================
  
    def init_languages_hash
      # Called in the beginning of a session
      # Read in the original yaml files, sort and add any keys that are present in some but not all languages
      # Write the full hash to file
      full = {}
      data = {}
      LANGS.each {|language|
        data[language] = YAML::load( File.open(ORIGINAL_DIR+language+'.yml' ))[language].sort_by_key(true)
        full=full.rmerge(data[language])
      }
      @mega = {}
      LANGS.each do |language|
        @mega[language] = full.deep_dup # Create a deep copy
        @mega[language].set_values_from_other(data[language], path = [])
      end
      File.open(Rails.root.to_s+'/config/locales/mega.rb', "w") {|file| file.puts @mega.inspect }
    end
  
    def pretty_mega(heading)
      # Pretty print the @mega hash
      @res << "<h2>#{heading}</h2>"
      @mega.keys.each do |language|
        @res << "<h2>#{language}</h2>"
        @res << pretty(@mega[language])
      end
    end

  

  # ================== END ROUTINES
  
  

  
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
      # Copy the current files to backup
      for lang in LANGUAGES do
        backup_no = 0 # Count number of backup files with most recent being no 0
        while File.exist?(RAILS_ROOT+'/config/locales/backups/'+lang+"_bu"+backup_no.to_s+".yml") do
          backup_no = backup_no + 1
        end
        if backup_no >= BU_LIMIT
          logger.debug "Removing #{RAILS_ROOT+'/config/locales/backups/'+lang+"_bu"+(backup_no-1).to_s+".yml"}"
          FileUtils.remove(RAILS_ROOT+'/config/locales/backups/'+lang+"_bu"+(backup_no-1).to_s+".yml")
          backup_no = backup_no - 1
        end
        for ind in backup_no.downto(1) do
          logger.debug "Move #{RAILS_ROOT+'/config/locales/backups/'+lang+'_bu'+(ind-1).to_s+'.yml'} to #{RAILS_ROOT+'/config/locales/backups/'+lang+'_bu'+ind.to_s+'.yml'}"
          FileUtils.mv(RAILS_ROOT+'/config/locales/backups/'+lang+'_bu'+(ind-1).to_s+'.yml',
                       RAILS_ROOT+'/config/locales/backups/'+lang+'_bu'+ind.to_s+'.yml')
        end
        logger.debug "Copy #{RAILS_ROOT+'/config/locales/'+lang+'.yml'} to #{RAILS_ROOT+'/config/locales/backups/'+lang+'_bu0.yml'}"
        FileUtils.copy(RAILS_ROOT+'/config/locales/'+lang+'.yml', RAILS_ROOT+'/config/locales/backups/'+lang+'_bu0.yml')
      end
      flash[:notice] = "Language files backed up"
      redirect_to :action => :index
      FileUtils.copy(RAILS_ROOT+'/config/locales/'+lang+'.yml', RAILS_ROOT+'/config/locales/backups/'+lang+"_bu"+backup_no.to_s+".yml")
      #File.open(RAILS_ROOT+'/config/locales/'+lang+'.yml', 'w') {|f| f << @txt}
    end


  
  
    # Update method called via AJAX
    def update_recordOLD
      logger.debug "Updating record #{params.inspect}"
      @languages = LANGUAGES
      @records = {}
      lang = params[:key].partition('.')[0]
      @data = YAML::load( File.open(RAILS_ROOT+'/config/locales/'+lang+'.yml' ))
      key = params[:key].partition('.')[2]
      keylist = params[:key].split('.')
      logger.debug "Keylist = #{keylist.inspect}"
      newHash = keylist.reverse.inject(params[:newValue]) { |a, n| { n => a } }
      logger.debug "New hash=#{newHash.inspect}"
      @data = @data.rmerge(newHash)
      File.open(RAILS_ROOT+"/config/locales/#{lang}.yml", "w") {|file| file.puts(@data.ya2yaml) }
      render :text => "Language file #{lang} updated".to_json
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
  
    def test
      # Start from yml language files: sv.yml and en.yml
      # 1) Show originals
      #    Add missing keys in each language and at the same time build up a "full" hash with all keys from all languages
      # 2) Show the full hash
      # 3) For each language: add all missing keys with values set to nil.
      #    Create a @mega hash for this with level-0 keys being the language tags. Show
      # 4) Write the new, complete, languages hashes to ruby files
      # 5) Add a key path that is new to all languages with value in English, creating a nil value for Swedish
      # 6) Add a value to the Swedish translation
      # 7) Modify one translation but not the other
      # 8) Remove various paths
    
      @res = "<h1>Originals for each Language</h1>"
      full = {}
      LANGS.each {|language|
        @res << "<h2>#{language}</h2>"
        @data = YAML::load( File.open(ORIGINAL_DIR+language+'.yml' ))[language].sort_by_key(true)
        full=full.rmerge(@data)
        #logger.debug data.inspect
        #recurse(@data, "", language)
        @res << pretty(@data)
      }
    

      # == 2 ==
      @res << "<h1>Full</h1>"
      @res << "<p>Starting the first language (sv) then replace and add in missing stuff from the following language(s)</p>"
      @res << pretty(full)
    
      # For test only 
      # @res << "<h1>Filled-up languages</h1>"
      # @res << "<p>Method: for each language: add all new keys from other languages and set the value to nil."
      # @res << "Here it is entirely done using a modified pretty printing.</p>"
      # LANGS.each do |language|
      #   @res << "<h2>Filled up #{language}</h2>"
      #   @data = YAML::load( File.open(ORIGINAL_DIR+language+'.yml' ))[language].sort_by_key(true)
      #   @res << pretty_fixed(full, @data)
      # end
    
      # == 3 ==
      @res << "<h1>Filled-up languages</h1>"
      @res << "<p>Method: first adding the stuff to the language hashes, then pretty print these normally</p>"
      @mega = {}
      LANGS.each do |language|
        @data = YAML::load( File.open(ORIGINAL_DIR+language+'.yml' ))[language].sort_by_key(true)
        @mega[language] = full.deep_dup # Create a deep copy
        @mega[language].set_values_from_other(@data, path = [])
      end
      pretty_mega "Fixed"
    
      # == 4 ==
      LANGS.each do |language|
        File.open(ORIGINAL_DIR+language+'0.rb', 'w') { |file| file.write({language => @mega[language]}.to_s) }
      end
    
      # == 5 ==
      path = ["paper", "acceptance", "result"]
      @mega['en'] = @mega['en'].rput(path, "Review results")
      @mega['sv'] = @mega['sv'].rput(path, nil)
      pretty_mega "New path with value in English"
    
      # == 6 ==
      path = ["paper", "acceptance", "result"]
      @mega['en'] = @mega['en'].rput(path, nil)
      @mega['sv'] = @mega['sv'].rput(path, "Granskningsresultat")
      pretty_mega "Adding a value to the Swedish translation"

      # == 7 ==
      path = ["paper", "acceptance", "result"]
      @mega['en'] = @mega['en'].rput(path, "Stupidity", true)
      @mega['sv'] = @mega['sv'].rput(path, "Stupidity")
      pretty_mega "Modifying only the English translation"
    
      # == 8 ==
      path = ["paper", "acceptance", "reviewer"]
      @mega['sv'] = @mega['sv'].rput(path, "Granskare")
      path = ["paper", "acceptance", "result"]
      @mega['sv'].remove_path(path)
      path = ["paper", "acceptance", "reviewer"]
      @mega['sv'].remove_path(path)
      pretty_mega "Removed path only from the Swedish translation"
      @res << @mega['sv'].inspect
    
      path = ["sv", "broadcast", "date"]
      @mega.remove_path(path)
      pretty_mega "Removed broadcast date from Swedish translation"
      @res << @mega['sv'].inspect

      path = ["sv", "broadcast", "frequency"]
      @mega.remove_path(path)
      pretty_mega "Removed broadcast frequency from Swedish translation"
      @res << @mega['sv'].inspect
    
      @mega.remove_path(["en", "paper", "format"])
      pretty_mega "Removed paper format from English"


    
    
      I18n.locale = "sv"
      # return render :text => res
      # @all_languages = LANGS
      # @toplevels = @data.keys.sort
      # @the_section = session[:localization_section] || ""
      # @selected_languages = session[:localization_language] || @all_languages
    end
  
    private
    def update_translation_record(lang, key, newValue)
      logger.debug "Updating record. Language= #{lang}, Key=#{key}, Value=#{newValue}"
      @data = YAML::load( File.open(RAILS_ROOT+'/config/locales/'+lang+'.yml' ))
      keylist = [lang] + key.split('.')
      newHash = keylist.reverse.inject(newValue) { |a, n| { n => a } }
      @data = @data.rmerge(newHash)
      File.open(RAILS_ROOT+"/config/locales/#{lang}.yml", "w") {|file| file.puts(@data.ya2yaml) }
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
  
    def recurse(data, parent, lang)
      # This version of the recurse function creates a tree structure of db records of type "localization_tag"
      # Leaf nodes are of type "localization", and point to the immediate parent among the "localization_tags"
     if data.class != {}.class
       data = data.inspect if data.class == [].class
       #@records[parent] = {lang => data}
       if @records[parent]
         @records[parent][lang] = data
       else
         @records[parent] = {lang => data}
       end
     else
        for akey in data.keys.sort do
          prefix = parent=="" ? akey : "#{parent}.#{akey}"
          recurse(data[akey], prefix, lang)
        end
      end
    end
  end

  
end
