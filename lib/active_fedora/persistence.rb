module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    extend ActiveSupport::Concern

    def persisted?
      !(new_record? || destroyed?)
    end

    # Returns true if this object has been destroyed, otherwise returns false.
    def destroyed?
      @destroyed
    end

    # Saves a Base object, and any dirty datastreams, then updates 
    # the Solr index for this object, unless option :update_index=>false is present.
    # Indexing is also controlled by the `create_needs_index?' and `update_needs_index?' methods.
    #
    # @param [Hash] options
    # @option options [Boolean] :update_index (true) set false to skip indexing
    # @return [Boolean] true if save was successful, otherwise false
    def save(options={})
      # If it's a new object, set the conformsTo relationship for Fedora CMA
      new_record? ? create_record(options) : update_record(options)
    end

    def save!(options={})
      save(options)
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
      # TODO need to set the new modified_date after save
#      inner_object.load_attributes_from_fedora
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and 
    #the underlying inner_object.  If this object is held in any relationships (ie inbound relationships
    #outside of this object it will remove it from those items rels-ext as well
    def delete
      return self if new_record?

      reflections.each_pair do |name, reflection|
        if reflection.macro == :has_many
          association(name).delete_all
        end
      end

      pid = self.pid ## cache so it's still available after delete
      reload # Reload to pick up any changes because of updating reflections.
      begin
        super
      rescue Ldp::NotFound
        raise ObjectNotFoundError, "Unable to find #{pid} in the repository"
      end

      ActiveFedora::SolrService.delete(pid) if ENABLE_SOLR_UPDATES
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

    # Determines whether a create operation causes a solr index of this object by default.
    # Override this if you need different behavior.
    def create_needs_index?
      ENABLE_SOLR_UPDATES
    end

    # Determines whether an update operation causes a solr index of this object by default.
    # Override this if you need different behavior
    def update_needs_index?
      ENABLE_SOLR_UPDATES
    end

    # This can be overriden to assert a different model
    # It's normally called once in the lifecycle, by #create#
    def assert_content_model
      self.has_model = self.class.to_s
    end

  private
    
    # Deals with preparing new object to be saved to Fedora, then pushes it and its datastreams into Fedora. 
    def create_record(options = {})
      assign_rdf_subject
      assert_content_model
      serialize_datastreams
      result = super()
      assign_uri_to_datstreams
      should_update_index = create_needs_index? && options.fetch(:update_index, true)
      persist(should_update_index)
      return !!result
    end

    def update_record(options = {})
      serialize_datastreams
      result = super()
      should_update_index = update_needs_index? && options.fetch(:update_index, true)
      persist(should_update_index)
      return !!result
    end

    def assign_pid
    end

    def assign_rdf_subject
      if !pid && new_pid = assign_pid
        @orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(FedoraLens.connection, self.class.id_to_uri(new_pid), RDF::Graph.new))
      end
    end

    def assign_uri_to_datstreams
      datastreams.each do |_, ds|
        ds.digital_object= self
      end
    end
    
    def persist(should_update_index)
      datastreams.select { |_, ds| ds.changed? }.each do |_, ds|
        ds.save # Don't call save! because if the content_changed? returns false, it'll raise an error.
      end

      refresh
      update_index if should_update_index
    end
  end
end
