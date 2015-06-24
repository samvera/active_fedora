module ActiveFedora

  # Class for attributes that are delegated to an OmDatastream

  class OmAttribute < StreamAttribute

    # @param [ActiveFedora::Base] obj the object that has the attribute
    # @param [Object] v value to write to the attribute
    def writer(obj, v)
      ds = file_for_attribute(obj, delegate_target)
      obj.mark_as_changed(field) if obj.value_has_changed?(field, v)
      terminology = at || [field]
      ds.send(:update_indexed_attributes, {terminology => v})
    end

    # @param [ActiveFedora::Base] obj the object that has the attribute
    # @param [Object] opts extra options that are passed to the target reader
    def reader(obj, *opts)
      ds = file_for_attribute(obj, delegate_target)
      terminology = at || [field]
      if terminology.length == 1 && opts.present?
        ds.send(terminology.first, *opts)
      else
        ds.send(:term_values, *terminology)
      end
    end

  end
end
