module ActiveFedora
  # Represents the mapping between a model attribute and a field in a datastream
  class DatastreamAttribute
    
    attr_accessor :dsid, :field, :datastream_class, :at, :multiple

    def initialize(field, dsid, datastream_class, args={})
      self.field = field
      self.dsid = dsid
      self.datastream_class = datastream_class
      self.multiple = args[:multiple].nil? ? false : args[:multiple]
      self.at = args[:at]
    end

    # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first 
    def primary_solr_name
      @datastream ||= datastream_class.new(nil, dsid)
      if @datastream.respond_to?(:primary_solr_name)
        @datastream.primary_solr_name(field)
      else
        raise NoMethodError, "the datastream '#{datastream_class}' doesn't respond to 'primary_solr_name'"
      end
    end

    def type
      if datastream_class.respond_to?(:type)
        datastream_class.type(field)
      else
        raise NoMethodError, "the datastream '#{datastream_class}' doesn't respond to 'type'"
      end
    end

    def writer(obj, v)
      ds = datastream_for_attribute(obj, dsid)
      obj.mark_as_changed(field) if obj.value_has_changed?(field, v)
      if ds.kind_of?(ActiveFedora::RDFDatastream)
        ds.send("#{field}=", v)
      else
        terminology = at || [field]
        ds.send(:update_indexed_attributes, {terminology => v})
      end
    end

    def reader(obj, *opts)
      if obj.inner_object.is_a? SolrDigitalObject
        begin
          # Look in the cache
          return obj.inner_object.fetch(field)
        rescue NoMethodError => e
          # couldn't get it from solr, so try from fedora.
          logger.info "Couldn't get #{field} out of solr, because #{e.message}. Trying another way."
        end
      end
      # Load from fedora
      ds = datastream_for_attribute(obj, dsid)
      if ds.kind_of?(ActiveFedora::RDFDatastream)
        ds.send(field)
      else
        terminology = at || [field]
        if terminology.length == 1 && opts.present?
          ds.send(terminology.first, *opts)
        else
          ds.send(:term_values, *terminology)
        end
      end
    end

    private

    def datastream_for_attribute(obj, dsid)
      obj.datastreams[dsid] || raise(ArgumentError, "Undefined datastream id: `#{dsid}' in has_attributes")
    end

  end
end
