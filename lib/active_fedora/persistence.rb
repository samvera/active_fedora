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
    def save(options={})
      # If it's a new object, set the conformsTo relationship for Fedora CMA
      new_record? ? create_record(options) : update_record(options)
    end

    def save!(options={})
      save(options)
    end

    # Pushes the object and all of its new or dirty attached files into Fedora
    def update(attributes)
      self.attributes=attributes
      save
    end

    alias update_attributes update

    def refresh
      @ldp_source = LdpResource.new(conn, uri)
      @resource = nil
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and
    #the underlying inner_object.  If this object is held in any relationships (ie inbound relationships
    #outside of this object it will remove it from those items rels-ext as well
    def delete
      return self if new_record?

      @destroyed = true
      reflections.each_pair do |name, reflection|
        if reflection.macro == :has_many
          association(name).delete_all
        end
      end

      id = self.id ## cache so it's still available after delete
      # Clear out the ETag
      @ldp_source = LdpResource.new(conn, uri)
      begin
        @ldp_source.delete
      rescue Ldp::NotFound
        raise ObjectNotFoundError, "Unable to find #{id} in the repository"
      end

      ActiveFedora::SolrService.delete(id) if ENABLE_SOLR_UPDATES
      freeze
    end

    def destroy
      delete
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
          object = new(attributes)
          yield(object) if block_given?
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

  private

    # Deals with preparing new object to be saved to Fedora, then pushes it and its attached files into Fedora.
    def create_record(options = {})
      assign_rdf_subject
      serialize_attached_files
      @ldp_source = @ldp_source.create
      @resource = nil
      assign_uri_to_attached_files
      should_update_index = create_needs_index? && options.fetch(:update_index, true)
      persist(should_update_index)
      true
    end

    def update_record(options = {})
      serialize_attached_files
      execute_sparql_update
      should_update_index = update_needs_index? && options.fetch(:update_index, true)
      persist(should_update_index)
      true
    end

    def execute_sparql_update
      change_set = ChangeSet.new(self, self.resource, self.changed_attributes.keys)
      return true if change_set.empty?
      SparqlInsert.new(change_set.changes).execute(uri)
    end


    def assign_id
    end

    def assign_rdf_subject
      @ldp_source = if !id && new_id = assign_id
        LdpResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(new_id), @resource)
      else
        LdpResource.new(ActiveFedora.fedora.connection, @ldp_source.subject, @resource, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      end
    end

    def assign_uri_to_attached_files
      attached_files.each do |name, ds|
        ds.uri= "#{uri}/#{name}"
      end
    end

    def persist(should_update_index)
      attached_files.select { |_, ds| ds.changed? }.each do |_, ds|
        ds.save # Don't call save! because if the content_changed? returns false, it'll raise an error.
      end

      refresh
      update_index if should_update_index
    end
  end
end
