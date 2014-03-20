module ActiveFedora
  module Core
    extend ActiveSupport::Concern
    
    included do
      attribute :has_model, [ RDF::URI.new("info:fedora/fedora-system:def/relations-external#hasModel")]
      # TODO is it possible to put defaults here?
      attribute :create_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#created")]
      attribute :modified_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#lastModified")]
    end

    # Constructor.  You may supply a custom +:pid+, or we call the Fedora Rest API for the
    # next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    def initialize(attrs = nil)
      super
      @association_cache = {}
      self.relationships_loaded = true
      load_datastreams
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved" unless persisted?
      clear_association_cache
      clear_relationships
      init_with(self.class.find(self.pid).inner_object)
    end

    # Initialize an empty model object and set the +inner_obj+
    # example:
    #
    #   class Post < ActiveFedora::Base
    #     has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream
    #   end
    #
    #   post = Post.allocate
    #   post.init_with(DigitalObject.find(pid))
    #   post.properties.title # => 'hello world'
    def init_with(inner_obj)
      @association_cache = {}
      @inner_object = inner_obj
      unless @inner_object.is_a? SolrDigitalObject
        @inner_object.original_class = self.class
        ## Replace existing unchanged datastreams with the definitions found in this class if they have a different type.
        ## Any datastream that is deleted here will cause a reload from fedora, so avoid it whenever possible
        ds_specs.keys.each do |key|
          if @inner_object.datastreams[key] != nil && !@inner_object.datastreams[key].content_changed? && @inner_object.datastreams[key].class != self.class.ds_specs[key][:type]
            @inner_object.datastreams.delete(key)
          end
        end
      end
      load_datastreams
      run_callbacks :find
      run_callbacks :initialize
      self
    end

    def ==(comparison_object)
         comparison_object.equal?(self) ||
           (comparison_object.instance_of?(self.class) &&
             comparison_object.pid == pid &&
             !comparison_object.new_record?)
    end

    def clone
      new_object = self.class.create
      clone_into(new_object)
    end

    # Clone the datastreams from this object into the provided object, while preserving the pid of the provided object
    # @param [Base] new_object clone into this object
    def clone_into(new_object)
      raise "need to rewrite the local graph"
      datastreams.each do |k, v|
        new_object.datastreams[k].content = v.content
      end
      new_object if new_object.save
    end

    def freeze
      datastreams.freeze
      self
    end

    def frozen?
      datastreams.frozen?
    end

    # This method adapts the inner_object to a new ActiveFedora::Base implementation
    # This is intended to minimize redundant interactions with Fedora
    def adapt_to(klass)
      unless klass.ancestors.include? ActiveFedora::Base
        raise "Cannot adapt #{self.class.name} to #{klass.name}: Not a ActiveFedora::Base subclass"
      end
      klass.allocate.init_with(inner_object)
    end

    # Examines the :has_model assertions in the RELS-EXT.
    #
    # If the object is of type ActiveFedora::Base, then use the first :has_model
    # in the RELS-EXT for this object. Due to how the RDF writer works, this is
    # currently just the first alphabetical model.
    #
    # If the object was instantiated with any other class, then use that class
    # as the base of the type the user wants rather than casting to the first
    # :has_model found on the object.
    #
    # In either case, if an extended model of that initial base model of the two
    # cases above exists in the :has_model, then instantiate as that extended
    # model type instead.
    def adapt_to_cmodel
      best_model_match = ActiveFedora::ContentModel.best_model_for(self)

      self.instance_of?(best_model_match) ? self : self.adapt_to(best_model_match)
    end
    
    # ** EXPERIMENTAL **
    # This method returns a new object of the same class, with the internal SolrDigitalObject
    # replaced with an actual DigitalObject.
    def reify
      if self.inner_object.is_a? DigitalObject
        raise "#{self.inspect} is already a full digital object"
      end
      self.class.find self.pid
    end
    
    # ** EXPERIMENTAL **
    # This method reinitializes a lightweight, loaded-from-solr object with an actual
    # DigitalObject inside.
    def reify!
      if self.inner_object.is_a? DigitalObject
        raise "#{self.inspect} is already a full digital object"
      end
      self.init_with DigitalObject.find(self.class,self.pid)
    end
    
    module ClassMethods
      private
      def relation
        Relation.new(self)
      end
    end
  end
end
