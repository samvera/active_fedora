module ActiveFedora
  # Represents the mapping between a model attribute and a field in a datastream
  class DatastreamAttribute
    
    attr_accessor :dsid, :field, :klass, :at, :reader, :writer, :multiple

    def initialize(field, dsid, klass, args={})
      self.field = field
      self.dsid = dsid
      self.klass = klass
      self.multiple = args[:multiple].nil? ? false : args[:multiple]
      self.at = args[:at]

      initialize_reader!
      initialize_writer!
    end

    # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first 
    def primary_solr_name
      if klass.respond_to?(:primary_solr_name)
        klass.primary_solr_name(dsid, field)
      else
        raise IllegalOperation, "the class '#{klass}' doesn't respond to 'primary_solr_name'"
      end
    end

    def type
      if klass.respond_to?(:type)
        klass.type(field)
      else
        raise IllegalOperation, "the class '#{klass}' doesn't respond to 'type'"
      end
    end

    private

    def initialize_writer!
      this = self
      self.writer = lambda do |v|
        ds = datastream_for_attribute(this.dsid)
        mark_as_changed(this.field) if value_has_changed?(this.field, v)
        if ds.kind_of?(ActiveFedora::RDFDatastream)
          ds.send("#{this.field}=", v)
        else
          terminology = this.at || [this.field]
          ds.send(:update_indexed_attributes, {terminology => v})
        end
      end
    end

    def initialize_reader!
      this = self
      self.reader = lambda do |*opts|
        if inner_object.is_a? SolrDigitalObject
          # Look in the cache
          # TODO catch a non-cached error and try fedora.
          inner_object.fetch(this.field)
        else
          # Load from fedora
          ds = datastream_for_attribute(this.dsid)
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send(this.field)
          else
            terminology = this.at || [this.field]
            if terminology.length == 1 && opts.present?
              ds.send(terminology.first, *opts)
            else
              ds.send(:term_values, *terminology)
            end
          end
        end
      end
    end

  end
end
