module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    extend Deprecation
    self.deprecation_horizon = 'active-fedora 7.0.0'
    
    
    autoload :Serializers

    included do
      include Serializers
    end

    def attributes=(properties)
      properties.each do |k, v|
        respond_to?(:"#{k}=") ? send(:"#{k}=", v) : raise(UnknownAttributeError, "unknown attribute: #{k}")
      end
    end
    

    # A convenience method  for updating indexed attributes.  The passed in hash
    # must look like this : 
    #   {{:name=>{"0"=>"a","1"=>"b"}}
    #
    # This will result in any datastream field of name :name having the value [a,b]
    #
    # An index of -1 will insert a new value. any existing value at the relevant index 
    # will be overwritten.
    #
    # As in update_attributes, this overwrites _all_ available fields by default.
    #
    # If you want to specify which datastream(s) to update,
    # use the :datastreams argument like so:
    #  m.update_attributes({"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}, :datastreams=>"my_ds")
    # or
    #  m.update_attributes({"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}, :datastreams=>["my_ds", "my_other_ds"])
    #
    def update_indexed_attributes(params={}, opts={})
      if ds = opts[:datastreams]
        ds_array = []
        ds = [ds] unless ds.respond_to? :each
        ds.each do |dsname|
          ds_array << datastreams[dsname]
        end
      else
        ds_array = metadata_streams
      end
      result = {}
      ds_array.each do |d|
        result[d.dsid] = d.update_indexed_attributes(params,opts)
      end
      return result
    end
    
    # Updates the attributes for each datastream named in the params Hash
    # @param [Hash] params A Hash whose keys correspond to datastream ids and whose values are appropriate Hashes to submit to update_indexed_attributes on that datastream
    # @param [Hash] opts (currently ignored.)
    # @example Update the descMetadata and properties datastreams with new values
    #   article = HydrangeaArticle.new
    #   ds_values_hash = {
    #     "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
    #     "properties"=>{ "notes"=>"foo" }
    #   }
    #   article.update_datastream_attributes( ds_values_hash )
    def update_datastream_attributes(params={}, opts={})
      result = params.dup
      params.each_pair do |dsid, ds_params| 
        if datastreams.include?(dsid)
          result[dsid] = datastreams[dsid].update_indexed_attributes(ds_params)
        else
          result.delete(dsid)
        end
      end
      return result
    end
    deprecation_deprecate :update_datastream_attributes
    
    def get_values_from_datastream(dsid,field_key,default=[])
      if datastreams.include?(dsid)
        return datastreams[dsid].get_values(field_key,default)
      else
        return nil
      end
    end
  end
end
