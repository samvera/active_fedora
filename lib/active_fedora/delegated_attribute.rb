module ActiveFedora
  # Represents the mapping between a model attribute and a field in a datastream
  class DelegatedAttribute

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
      @datastream ||= datastream_class.new
      if @datastream.respond_to?(:primary_solr_name)
        @datastream.primary_solr_name(field, dsid)
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
        write_rdf(ds, v)
      else
        write_om(ds, v)
      end
    end

    def reader(obj, *opts)
      ds = datastream_for_attribute(obj, dsid)
      if ds.kind_of?(ActiveFedora::RDFDatastream)
        read_rdf(ds)
      else
        read_om(ds, *opts)
      end
    end

    private

    def write_om(ds, v)
      terminology = at || [field]
      ds.send(:update_indexed_attributes, {terminology => v})
    end

    def read_om(ds, *opts)
      terminology = at || [field]
      if terminology.length == 1 && opts.present?
        ds.send(terminology.first, *opts)
      else
        ds.send(:term_values, *terminology)
      end
    end

    def write_rdf(node, v)
      term = if at
        vals = at.dup
        while vals.length > 1
          node = node.send(vals.shift)
          node = node.build if node.empty?
          node = node.first
        end
        vals.first
      else
        field
      end
      node.send("#{term}=", v)
    end

    def read_rdf(node)
      term = if at
        vals = at.dup
        while vals.length > 1
          node = node.send(vals.shift)
          node = if node.empty?
            node.build
          else
            node.first
          end
        end
        vals.first
      else
        field
      end
      node.send(term)
    end

    def datastream_for_attribute(obj, dsid)
      obj.attached_files[dsid] || raise(ArgumentError, "Undefined datastream id: `#{dsid}' in has_attributes")
    end

  end
end
