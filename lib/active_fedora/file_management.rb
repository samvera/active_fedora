module ActiveFedora
  module FileManagement
    extend ActiveSupport::Concern

    included do
      include ActiveFedora::Relationships
      has_relationship "collection_members", :has_collection_member
      has_relationship "part_of", :is_part_of
      has_bidirectional_relationship "parts", :has_part, :is_part_of
    end

    # List the objects that assert isPartOf pointing at this object _plus_ all objects that this object asserts hasPart for
    #   Note: Previous versions of ActiveFedora used hasCollectionMember to represent this type of relationship.  
    #   To accommodate this, until active-fedora-1.3, .file_assets will also return anything that this asserts hasCollectionMember for and will output a warning in the logs.
    #
    # @param [Hash] opts -- same options as auto-generated methods for relationships (ie. :response_format)
    # @return [Array of ActiveFedora objects, Array of PIDs, or Solr::Result] -- same options as auto-generated methods for relationships (ie. :response_format)
    def file_objects(opts={})
      cm_array = collection_members(:response_format=>:id_array)
      
      if !cm_array.empty?
        logger.warn "This object has collection member assertions.  hasCollectionMember will no longer be used to track file_object relationships after active_fedora 1.3.  Use isPartOf assertions in the RELS-EXT of child objects instead."
        if opts[:response_format] == :solr || opts[:response_format] == :load_from_solr
          logger.warn ":solr and :load_from_solr response formats for file_objects search only uses parts relationships (usage of hasCollectionMember is no longer supported)"
          result = parts(opts)
        else
          cm_result = collection_members(opts)
          parts_result = parts(opts)
          ary = cm_result+parts_result
          result = ary.uniq
        end
      else
        result = parts(opts)
      end
      return result
    end
    
    # Add the given obj as a child to the current object using an inbound is_part_of relationship
    #
    # @param [ActiveFedora::Base,String] obj the object or the pid of the object to add
    # @return [Boolean] whether saving the child object was successful
    # @example This will add an is_part_of relationship to the child_object's RELS-EXT datastream pointing at parent_object
    #   parent_object.file_objects_append(child_object)
    def file_objects_append(obj)
      # collection_members_append(obj)
      unless obj.kind_of? ActiveFedora::Base
        begin
          obj = ActiveFedora::Base.load_instance(obj)
        rescue ActiveFedora::ObjectNotFoundError
          "You must provide either an ActiveFedora object or a valid pid to add it as a file object.  You submitted #{obj.inspect}"
        end
      end
      obj.add_relationship(:is_part_of, self)
      obj.save
    end
    
    # Add the given obj as a collection member to the current object using an outbound has_collection_member relationship.
    #
    # @param [ActiveFedora::Base] obj the file to add
    # @return [ActiveFedora::Base] obj returns self
    # @example This will add a has_collection_member relationship to the parent_object's RELS-EXT datastream pointing at child_object
    #   parent_object.collection_members_append(child_object)
    def collection_members_append(obj)
      add_relationship(:has_collection_member, obj)
      return self
    end

    def collection_members_remove()
      # will rely on SemanticNode.remove_relationship once it is implemented
    end

  end
end

