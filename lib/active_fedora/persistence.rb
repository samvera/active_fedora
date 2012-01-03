module ActiveFedora
  # = Active Fedora Persistence
  module Persistence

    #Saves a Base object, and any dirty datastreams, then updates 
    #the Solr index for this object.
    def save(*)
      # If it's a new object, set the conformsTo relationship for Fedora CMA
      if new_object? 
        result = create
      else
        result = update
      end
      update_index if @metadata_is_dirty == true && ENABLE_SOLR_UPDATES
      @metadata_is_dirty = false
      return result
    end

    def save!(*)
      save
    end

    # This can be overriden to assert a different model
    # It's normally called once in the lifecycle, by #create#
    def assert_content_model
      add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(self.class))
    end


    def update_attributes(properties)
      self.attributes=properties
      save
    end

    # Refreshes the object's info from Fedora
    # Note: Currently just registers any new datastreams that have appeared in fedora
    def refresh
#      inner_object.load_attributes_from_fedora
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and 
    #the underlying inner_object.  If this object is held in any relationships (ie inbound relationships
    #outside of this object it will remove it from those items rels-ext as well
    def delete
      inbound_relationships(:objects).each_pair do |predicate, objects|
        objects.each do |obj|
          if obj.respond_to?(:remove_relationship)
            obj.remove_relationship(predicate,self)
            obj.save
          end 
        end
      end
      
      #Fedora::Repository.instance.delete(@inner_object)
      pid = self.pid ## cache so it's still available after delete
      begin
        @inner_object.delete
      rescue RestClient::ResourceNotFound =>e
        raise ObjectNotFoundError, "Unable to find #{pid} in the repository"
      end
      if ENABLE_SOLR_UPDATES
        ActiveFedora::SolrService.instance.conn.delete(pid) 
        # if defined?( Solrizer::Solrizer ) 
        #   solrizer = Solrizer::Solrizer.new
        #   solrizer.solrize_delete(pid)
        # end
      end
    end



  private
    
    # Updates Solr index with self.
    def update_index
      if defined?( Solrizer::Fedora::Solrizer ) 
        #logger.info("Trying to solrize pid: #{pid}")
        solrizer = Solrizer::Fedora::Solrizer.new
        solrizer.solrize( self )
      else
        #logger.info("Trying to update solr for pid: #{pid}")
        SolrService.instance.conn.update(self.to_solr)
      end
    end

    # Deals with preparing new object to be saved to Fedora, then pushes it and its datastreams into Fedora. 
    def create
      assign_pid
      assert_content_model
      @metadata_is_dirty = true
      persist
    end

    def assign_pid
      @inner_object = @inner_object.save #replace the unsaved digital object with a saved digital object
    end
    
    # Pushes the object and all of its new or dirty datastreams into Fedora
    def update
      persist
    end

    def metadata_is_dirty=(bool)
      @metadata_is_dirty = bool
    end

    def persist
      result = @inner_object.save

      ### Rubydora re-inits the datastreams after a save, so ensure our copy stays in synch
      @inner_object.datastreams.each do |dsid, ds|
        datastreams[dsid] = ds
        ds.model = self if ds.kind_of? RelsExtDatastream
      end 
      refresh
      return !!result
    end


  end
end
