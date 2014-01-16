module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = 'active-fedora version 8.0.0'
    

    def new?
      new_record?
    end
    deprecation_deprecate :new?

    # Has this object been saved?
    def new_object?
      new_record?
    end
    deprecation_deprecate :new_object?
    

    ## Required by associations
    def new_record?
      inner_object.new_record?
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    # Returns true if this object has been destroyed, otherwise returns false.
    def destroyed?
      @destroyed
    end

    #Saves a Base object, and any dirty datastreams, then updates 
    #the Solr index for this object.
    def save(*)
      # If it's a new object, set the conformsTo relationship for Fedora CMA
      new_record? ? create : update_record
    end

    def save!(*)
      save
    end

    # This can be overriden to assert a different model
    # It's normally called once in the lifecycle, by #create#
    def assert_content_model
      add_relationship(:has_model, self.class.to_class_uri)
    end

    # Pushes the object and all of its new or dirty datastreams into Fedora
    def update(attributes)
      self.attributes=attributes
      save
    end

    alias update_attributes update
    
    # Refreshes the object's info from Fedora
    # Note: Currently just registers any new datastreams that have appeared in fedora
    def refresh
#      inner_object.load_attributes_from_fedora
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and 
    #the underlying inner_object.  If this object is held in any relationships (ie inbound relationships
    #outside of this object it will remove it from those items rels-ext as well
    def delete
      reflections.each_pair do |name, reflection|
        if reflection.macro == :has_many
          association(name).delete_all
        end
      end

      pid = self.pid ## cache so it's still available after delete
      begin
        @inner_object.delete
      rescue RestClient::ResourceNotFound =>e
        raise ObjectNotFoundError, "Unable to find #{pid} in the repository"
      end
      if ENABLE_SOLR_UPDATES
        solr = ActiveFedora::SolrService.instance.conn
        solr.delete_by_id(pid, params: {'softCommit' => true}) 
      end
      @destroyed = true
      freeze
    end

    def destroy
      delete
    end

    module ClassMethods
      # Creates an object (or multiple objects) and saves it to the repository, if validations pass.
      # The resulting object is returned whether the object was saved successfully to the repository or not.
      #
      # The +attributes+ parameter can be either be a Hash or an Array of Hashes.  These Hashes describe the
      # attributes on the objects that are to be created.
      #
      # ==== Examples
      #   # Create a single new object
      #   User.create(:first_name => 'Jamie')
      #
      #   # Create an Array of new objects
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }])
      #
      #   # Create a single object and pass it into a block to set other attributes.
      #   User.create(:first_name => 'Jamie') do |u|
      #     u.is_admin = false
      #   end
      #
      #   # Creating an Array of new objects using a block, where the block is executed for each object:
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }]) do |u|
      #     u.is_admin = false
      #   end
      def create(attributes = nil, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, &block) }
        else
          object = new(attributes)
          yield(object) if block_given?
          object.save
          object
        end
      end
    end

  protected

    # Determines whether a create operation cause a solr index of this object.
    # Override this if you need different behavior
    def create_needs_index?
      ENABLE_SOLR_UPDATES
    end

    # Determines whether an update operation cause a solr index of this object.
    # Override this if you need different behavior
    def update_needs_index?
      ENABLE_SOLR_UPDATES
    end

  private
    
    # Deals with preparing new object to be saved to Fedora, then pushes it and its datastreams into Fedora. 
    def create
      assign_pid
      assert_content_model
      persist(create_needs_index?)
    end

    def update_record
      persist(update_needs_index?)
    end

    # replace the unsaved digital object with a saved digital object
    def assign_pid
      @inner_object = @inner_object.save 
    end
    
    def persist(should_update_index)
      serialize_datastreams
      result = @inner_object.save
      ### Rubydora re-inits the datastreams after a save, so ensure our copy stays in synch
      @inner_object.datastreams.each do |dsid, ds|
        datastreams[dsid] = ds
        ds.model = self if ds.kind_of? RelsExtDatastream
      end 
      refresh
      update_index if should_update_index
      return !!result
    end
  end
end
