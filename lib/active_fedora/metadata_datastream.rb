module ActiveFedora
  # A legacy class that creates and updates simple xml documents
  # For much greater flexibility, use {ActiveFedora::NokogiriDatastream} instead.
  # @example The simple, flat xml structure used by these datastreams
  #   <fields>
  #     <title>Foo</title>
  #     <author>Bar</author>
  #   </fields>
  class MetadataDatastream < NokogiriDatastream 
    
    # .to_solr (among other things) is provided by ActiveFedora::MetadataDatastreamHelper
    include ActiveFedora::MetadataDatastreamHelper

    # def initialize(digital_object, dsid)
    #   ActiveSupport::Deprecation.warn("MetadataDatastream is deprecated and will be removed in a future release. Create a NokogiriDatastream to structure your data")
    #   super
    # end
    def to_solr(solr_doc = Hash.new) # :nodoc:
      fields.each do |field_key, field_info|
        if field_info.has_key?(:values) && !field_info[:values].nil?
          field_symbol = ActiveFedora::SolrService.solr_name(field_key, field_info[:type])
          values = field_info[:values]
          values = [values] unless values.respond_to? :each
          values.each do |val|    
            ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val )         
          end
        end
      end

      return solr_doc
    end
  
    # ** EXPERIMENTAL **
    #
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to set 
    # metadata values in this object using the Solr document passed in.
    # Any keys in the solr document that map to a metadata field key within a MetadataDatastream object
    # are set to the corresponding value.  Any others are ignored. ActiveFedora::SolrService.solr_name
    # is used to map solr key to field key name.
    #
    # ====Warning
    #  Solr must be synchronized with data in Fedora.
    def from_solr(solr_doc)
      profile_from_solr(solr_doc)
      fields.each do |field_key, field_info|
        field_symbol = ActiveFedora::SolrService.solr_name(field_key, field_info[:type])
        value = (solr_doc[field_symbol].nil? ? solr_doc[field_symbol.to_s]: solr_doc[field_symbol]) 
        unless value.nil?
          if value.is_a? Array
            update_attributes({field_key=>value})
          else
            update_indexed_attributes({field_key=>{0=>value}})
          end
        end
      end
    end
  



    def update_attributes(params={},opts={})
      result = params.dup
      params.each do |k,v|
        if v == :delete || v == "" || v == nil
          v = []
        end
        if self.fields.has_key?(k.to_sym)
          result[k] = set_value(k, v)
        else
          result.delete(k)
        end
      end
      return result
    end
    
    # An ActiveRecord-ism to udpate metadata values.
    #
    # The passed in hash must look like this : 
    #   {:name=>{"0"=>"a","1"=>"b"}}
    #
    # This will attempt to set the values for any field named fubar in the datastream. 
    # If there is no field by that name, it returns an empty hash and doesn't change the object at all.
    # If there is a field by that name, it will set the values for field of name :name having the value [a,b]
    # and it returns a hash with the field name, value index, and the value as it was set.    
    #
    # An index of -1 will insert a new value. any existing value at the relevant index 
    # will be overwritten.
    #
    # As in update_attributes, this overwrites _all_ available fields by default.
    #
    # Example Usage:
    #
    # ds.update_attributes({:myfield=>{"0"=>"a","1"=>"b"},:myotherfield=>{"-1"=>"c"}})
    #
    def update_indexed_attributes(params={}, opts={})
      ensure_xml_loaded
      
      ##FIX this bug, it should delete it from a copy of params in case passed to another datastream for update since this will modify params
      ##for subsequent calls if updating more than one datastream in a single update_indexed_attributes call
      current_params = params.clone
      
      # remove any fields from params that this datastream doesn't recognize
      current_params.delete_if do |field_name,new_values| 
        if field_name.kind_of?(Array) then field_name = field_name.first end
        !self.fields.include?(field_name.to_sym) 
      end
            
      result = current_params.dup
      current_params.each do |field_name,new_values|
        if field_name.kind_of?(Array) then field_name = field_name.first end
        
        ##FIX this bug, it should delete it from a copy of params in case passed to another datastream for update
        #if field does not exist just skip it
        next if !self.fields.include?(field_name.to_sym)
        field_accessor_method = "#{field_name}_values"
        
        if new_values.kind_of?(Hash)
            result[field_name] = new_values.dup
      
            current_values = instance_eval(field_accessor_method)
        
            # current_values = get_values(field_name) # for some reason this leaves current_values unset?
                
            new_values.delete_if do |y,z| 
              if current_values[y.to_i] and y.to_i > -1
                current_values[y.to_i]=z
                true
              else
                false
              end
            end 
        
            new_values.keys.sort { |a,b| a.to_i <=> b.to_i }.each do |y| 
              z = new_values[y]
              result[field_name].delete(y)
              current_values<<z #just append everything left
              new_array_index = current_values.length - 1
              result[field_name][new_array_index.to_s] = z
            end
            current_values.delete_if {|x| x == :delete || x == "" || x == nil}
            #set_value(field_name, current_values)
            instance_eval("#{field_accessor_method}=(current_values)") #write it back to the ds
            # result[field_name].delete("-1")
        else
          values = instance_eval("#{field_name}_values=(new_values)")
          result[field_name] = {"0"=>values}           
        end
        self.dirty = true
      end
      return result
    end
    
    
    def get_values(field_name, default=[])
      ensure_xml_loaded  
      field_accessor_method = "#{field_name}_values"
      if respond_to? field_accessor_method
        values = self.send(field_accessor_method)
      else
        values = []
      end
      if values.empty?
        if default.nil?
          return default
        else
          return default
        end
      else
        return values
      end
    end
    
    def set_value(field_name, values)
      ensure_xml_loaded  
      field_accessor_method = "#{field_name}_values="
      if respond_to? field_accessor_method
        values = self.send(field_accessor_method, values)
        return self.send("#{field_name}_values")
      end
    end
    
    # Populate a MetadataDatastream object based on the "datastream" node from a FOXML file
    # @param [ActiveFedora::Datastream] tmpl the Datastream object that you are building
    # @param [Nokogiri::XML::Node] node the "foxml:datastream" node from a FOXML file.  Assumes that the content of this datastream is that of an ActiveFedora MetadataDatastream (<fields>...</fields>)
    def self.from_xml(xml, tmpl) # :nodoc:
      node = Nokogiri::XML::Document.parse(xml)
      node.xpath("fields/node()").each do |f|
          tmpl.send("#{f.name}_append", f.text) unless f.class == Nokogiri::XML::Text
      end
      tmpl.send(:dirty=, false)
      tmpl
    end

    def to_xml(xml = Nokogiri::XML::Document.parse("<fields />")) #:nodoc:
      if xml.instance_of?(Nokogiri::XML::Builder)
        xml_insertion_point = xml.doc.root 
      elsif xml.instance_of?(Nokogiri::XML::Document) 
        xml_insertion_point = xml.root
      else
        xml_insertion_point = xml
      end
      
      builder = Nokogiri::XML::Builder.with(xml_insertion_point) do |xml|
        fields.each do |field,field_info|
          element_attrs = field_info[:element_attrs].nil? ? {} : field_info[:element_attrs]
          values = field_info[:values]
          values = [values] unless values.respond_to? :each
          values.each do |val|
            builder_arg = "xml.#{field}(val, element_attrs)"
            eval(builder_arg)
          end
        end
      end
      return builder.to_xml
    end
    
    # This method generates the various accessor and mutator methods on self for the datastream metadata attributes.
    # each field will have the 3 magic methods:
    #   name_values=(arg) 
    #   name_values 
    #   name_append(arg)
    #
    #
    # Calling any of the generated methods marks self as dirty.
    #
    # 'tupe' is a datatype, currently :string, :text and :date are supported.
    #
    # opts is an options hash, which  will affect the generation of the xml representation of this datastream.
    #
    # Currently supported modifiers: 
    # For +QualifiedDublinCorDatastreams+:
    #   :element_attrs =>{:foo=>:bar} -  hash of xml element attributes
    #   :xml_node => :nodename  - The xml node to be used to represent this object (in dcterms namespace)
    #   :encoding=>foo, or encodings_scheme  - causes an xsi:type attribute to be set to 'foo'
    #   :multiple=>true -  mark this field as a multivalue field (on by default)
    #
    #At some point, these modifiers will be ported up to work for any +ActiveFedora::MetadataDatastream+.
    #
    #There is quite a good example of this class in use in spec/examples/oral_history.rb
    #
    #!! Careful: If you declare two fields that correspond to the same xml node without any qualifiers to differentiate them, 
    #you will end up replicating the values in the underlying datastream, resulting in mysterious dubling, quadrupling, etc. 
    #whenever you edit the field's values.
    def field(name, tupe, opts={})
      @fields[name.to_s.to_sym]={:type=>tupe, :values=>[]}.merge(opts)
      eval <<-EOS
        def #{name}_values=(arg)
          ensure_xml_loaded  
          @fields["#{name.to_s}".to_sym][:values]=[arg].flatten
          self.dirty=true
        end
        def #{name}_values
          ensure_xml_loaded  
          @fields["#{name}".to_sym][:values]
        end
        def #{name}_append(arg)
          ensure_xml_loaded  
          @fields["#{name}".to_sym][:values] << arg
          self.dirty =true
        end
      EOS
    end

  end

end
