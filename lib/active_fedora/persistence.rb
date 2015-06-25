module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    extend ActiveSupport::Concern

    def new_record?
      @ldp_source.new?
    end

    def persisted?
      !(destroyed? || new_record?)
    end

    # Returns true if this object has been destroyed, otherwise returns false.
    def destroyed?
      @destroyed
    end

    # Saves a Base object, and any dirty attached files, then updates
    # the Solr index for this object, unless option :update_index=>false is present.
    # Indexing is also controlled by the `create_needs_index?' and `update_needs_index?' methods.
    #
    # @param [Hash] options
    # @option options [Boolean] :update_index (true) set false to skip indexing
    # @return [Boolean] true if save was successful, otherwise false
    def save(*options)
      create_or_update(*options)
    end

    def save!(*args)
      create_or_update(*args)
    end

    # Pushes the object and all of its new or dirty attached files into Fedora
    def update(attributes)
      self.attributes=attributes
      save
    end

    alias update_attributes update

    # Deletes an object from Fedora and deletes the indexed record from Solr.
    # Delete does not run any callbacks, so consider using _destroy_ instead.
    # @param [Hash] opts
    # @option opts [Boolean] :eradicate if passed in, eradicate the tombstone from Fedora
    def delete(opts = {})
      return self if new_record?

      @destroyed = true

      id = self.id ## cache so it's still available after delete
      # Clear out the ETag
      @ldp_source = build_ldp_resource(id)
      begin
        @ldp_source.delete
      rescue Ldp::NotFound
        raise ObjectNotFoundError, "Unable to find #{id} in the repository"
      end

      ActiveFedora::SolrService.delete(id) if ENABLE_SOLR_UPDATES
      if opts[:eradicate]
        self.class.eradicate(id)
      end
      freeze
    end

    # Delete the object from Fedora and Solr. Run any before/after/around callbacks for destroy
    # @param [Hash] opts
    # @option opts [Boolean] :eradicate if passed in, eradicate the tombstone from Fedora
    def destroy(*opts)
      raise ReadOnlyRecord if readonly?
      delete(*opts)
    end

    def eradicate
      self.class.eradicate(self.id)
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
          object = new(attributes, &block)
          object.save
          object
        end
      end

      # Removes an object's tombstone so another object with the same uri may be created.
      # NOTE: this is in violation of the linked data platform and is only here as a convience
      # method. It shouldn't be used in the general course of repository operations.
      def eradicate(uri)
        gone?(uri) ? delete_tombstone(uri) : false
      end

      private

      def gone? uri
        ActiveFedora::Base.find(uri)
        false
      rescue Ldp::Gone
        true
      end

      def delete_tombstone uri
        tombstone = ActiveFedora::Base.id_to_uri(uri) + "/fcr:tombstone"
        ActiveFedora.fedora.connection.delete(tombstone)
        true
      end
    end

  private

    def create_or_update(*args)
      raise ReadOnlyRecord if readonly?
      result = new_record? ? create_record(*args) : update_record(*args)
      result != false
    end

    # Deals with preparing new object to be saved to Fedora, then pushes it and its attached files into Fedora.
    def create_record(options = {})
      assign_rdf_subject
      serialize_attached_files
      @ldp_source = @ldp_source.create
      assign_uri_to_attached_files
      save_attached_files
      refresh
    end

    def update_record(options = {})
      serialize_attached_files
      execute_sparql_update
      save_attached_files
      refresh
    end

    def refresh
      @ldp_source = build_ldp_resource(id)
      @resource = nil
    end

    def execute_sparql_update
      change_set = ChangeSet.new(self, self.resource, self.changed_attributes.keys)
      return true if change_set.empty?
      ActiveFedora.fedora.ldp_resource_service.update(change_set, self.class, id)
    end

    # Override to tie in an ID minting service
    def assign_id
    end

    # This is only used when creating a new record. If the object doesn't have an id
    # and assign_id can mint an id for the object, then assign it to the resource.
    # Otherwise the resource will have the id assigned by the LDP server
    def assign_rdf_subject
      @ldp_source = if !id && new_id = assign_id
        LdpResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(new_id), @resource)
      else
        LdpResource.new(ActiveFedora.fedora.connection, @ldp_source.subject, @resource, ActiveFedora.fedora.host + base_path_for_resource)
      end
    end

    def base_path_for_resource
      init_root_path if self.has_uri_prefix?
      self.root_resource_path
    end

    def init_root_path
      path = self.root_resource_path.gsub(/^\//,"")
      ActiveFedora.fedora.connection.head(path)
    rescue Ldp::NotFound
      ActiveFedora.fedora.connection.put(path, "")
    end

    def assign_uri_to_attached_files
      attached_files.each do |name, ds|
        ds.uri= "#{uri}/#{name}"
      end
    end

    def save_attached_files
      attached_files.select { |_, file| file.changed? }.each do |_, file|
        file.save # Don't call save! because if the content_changed? returns false, it'll raise an error.
      end
    end
  end
end
