module ActiveFedora

  # Class for attributes that are delegated to a RDFDatastream

  class RdfDatastreamAttribute < StreamAttribute

    # @param [ActiveFedora::Base] obj the object that has the attribute
    # @param [Object] v value to write to the attribute
    def writer(obj, v)
      node = file_for_attribute(obj, delegate_target)
      obj.mark_as_changed(field) if obj.value_has_changed?(field, v)
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

    # @param [ActiveFedora::Base] obj the object that has the attribute
    def reader(obj)
      node = file_for_attribute(obj, delegate_target)
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

  end
end
