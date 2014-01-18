module ActiveFedora
  # Represents the mapping between a model attribute and a field in a datastream
  class DatastreamAttribute
    
    attr_accessor :dsid, :field, :datastream_class, :at, :reader, :writer, :multiple

    def initialize(field, dsid, datastream_class, args={})
      self.field = field
      self.dsid = dsid
      self.datastream_class = datastream_class
      self.multiple = args[:multiple].nil? ? false : args[:multiple]
      self.at = args[:at]

      initialize_reader!
      initialize_writer!
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
          begin
            # Look in the cache
            return inner_object.fetch(this.field)
          rescue NoMethodError => e
            # couldn't get it from solr, so try from fedora.
            logger.info "Couldn't get #{this.field} out of solr, because #{e.message}. Trying another way."
          end
        end
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
