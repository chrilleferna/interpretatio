class ::Hash
  # Extends the Hash class with methods to access and manipulate nested hashes.
  # Many of the methods rely on 'paths' to address a particular part of the nested hash.
  # A 'path' is an array of keys, where the first element is the key on the first level, which may thus have a hash as its value.
  # The second element in the path is the key used to access the hash returned from using the first key, etc.
  
    def self.init_from_yaml
      # NOT USED
      # Initialize the hash from all the yaml localization files that have data for the chosen languages
      # Read in the original yaml files, sort and add any keys that are present in some but not all languages
      # Write the full hash to file
      config = Config.first
      raise "Configuration missing" if config.nil?
      full = {}
      data = {}
      config.langs.each {|lang|
        data[lang] = YAML::load( File.open(config.yaml_dir+"/"+lang+'.yml' ))[lang].sort_by_key(true)
        full=full.deep_merge(data[lang])
      }
      @mega = {}
      config.langs.each do |lang|
        @mega[lang] = full.deep_dup # Create a deep copy
        @mega[lang].set_values_from_other(data[lang], path = [])
      end
      File.open(config.hash_dir+'/interpretatio_hash.rb', "w") {|file| file.puts @mega.inspect }
    end

    def hash_to_paths
      # returns an array of all the path arrays where we can find data in the self nested hash
      arr = []
      for key in self.keys do
        if self[key].class == {}.class
          belows = self[key].hash_to_paths
          arr.concat( belows.collect{|below| [key].concat(below)} )
        else
          arr << [key]
        end
      end
      return arr
    end
  
    def remove_path(path)
      # Modifies self by removing the key-value-pair addressed by path
      # If path goes "deeper" into self than where there is data, this is OK. We go as far as possible
      # This may mean that other parts higher up in the hierarchy becomes empty, so these are removed too
      # 1) remove the last key-value
      path.first(path.length-1).inject(self){|mem,item| mem = mem[item]}.delete(path.last) rescue return false
      # 2) move backwards, deleting key-values where the values are {}
      prunable = Array.new(path.first(path.length-1))
      while (prunable.length > 1) && (self.rread(prunable) == {}) do
        prunable.first(prunable.length-1).inject(self){|mem,item| mem = mem[item]}.delete(prunable.last) rescue return false
        prunable.pop
      end
    end

    def self.create_nested_hash(path, val)
      # Create and return a new nested hash copy staring from path in self
      self._create_nested_hash(Array.new(path),val)
    end

        def self._create_nested_hash(path, val)
          if path.length > 0
            return {path.shift => self._create_nested_hash(path,val)}
          else
            return val
          end
        end


    def rread(path)
      # Use the path to move down self, returning either the value addressed by path or nil
      # (A nil return may mean that either the path does not exist or that it exists and its value is nil)
      path.inject(self){|mem,item| mem = mem[item]} rescue nil
    end
    
    def rdirty?(path)
      # Run down the path (like rread) and return true if there is a 
    end
    
    def rput(path, val, overwrite=false, overwrite_hash=false)
      # Returns either a copy of self with a new value at path or false
      # It returns false if:
      #    - there already is a value at path and the overwrite parameter is false
      #    - there is a value which is a hash at path and the overwrite_hash is false
      #      (this would mean that we're trying to overwrite a deeper structure)
      # Rails.logger.debug "In rput"
      existing_value = self.rread(path)
      Rails.logger.debug "Existing value = #{existing_value}"
      if existing_value
        return false if !overwrite
        return false if !overwrite_hash && (existing_value.class == {}.class) && (existing_value != {})
      end
      hx = Hash.create_nested_hash(path,val)
      Rails.logger.debug "hx = #{hx.inspect}"
      # puts "hx = #{hx.inspect}"
      # Rails.logger.debug "Result of merge: #{self.deep_merge(hx)}"
      self.deep_merge(hx)
    end


    def rmerge(other_hash)
      # Recursively merge with the other hash
      # NOT USED. RAILS NOW HAS A DEEP MERGE
      # Any path of keys that appears in the other_hash will add the corresponding part to self, using the
      # values picked up in other_hash
      # Rails.logger.debug "RMERGE. self=#{self}, other_hash=#{other_hash}"
      r = {}
      merge(other_hash)  do |key, oldval, newval| 
        r[key] = oldval.class == self.class ? oldval.rmerge(newval) : newval
      end
    end
    
    def sort_by_key(recursive = false, &block)
      # Extension of the standard sort_by_key which only sorts the keys at the first level
      # If the parameter is set to true, then this becomes a recursive sort that will sort the keys on all levels
      # CURRENTLY NOT USED since there is no guarantee that a sorted hash is stored as such when written/re-read to/from file
      # Courtesy http://dan.doezema.com/2012/04/recursively-sort-ruby-hash-by-key/
      # License conditions and disclaimer: http://dan.doezema.com/licenses/new-bsd/
      self.keys.sort(&block).reduce({}) do |seed, key|
        seed[key] = self[key]
        if recursive && seed[key].is_a?(Hash)
          seed[key] = seed[key].sort_by_key(true, &block)
        end
        seed
      end
    end
    
    def set_values_from_other(other_hash, path = [])
      # Set all the values in self from the values found in other_hash at the same path,
      # or nil if there is no value in other_hash
      # NOT CURRENTLY USED
      for key in self.keys do
        if self[key].class == {}.class
          self[key].set_values_from_other(other_hash, path + [key])
        else
          self[key] = other_hash.rread(path + [key])
        end
      end
    end
    
    def to_yaml(level=0)
      # Return a string of pretty printed YAML code from the hash
      str = ""
      for key in self.keys do
        str << "\n" + " "*level*2 + key.to_s + ": "
        if self[key].class == {}.class
          str << self[key].to_yaml(level+1)
        else
          str << self[key].inspect
        end
      end
      str
    end

end

class ::Array
  # Recursive sort of nested array
  # This is NOT the version we want since it reorders the elements of the array
    def sort_recur!
      sort! do |a,b|
          a.sort_recur! if a.is_a? Array
          b.sort_recur! if b.is_a? Array
          a <=> b
      end
    end
    
    def rsort
      self.sort_by {|e| [e[0], e[1], e[2], e[3], e[4], e[5], e[6]]}
    end
    
end
