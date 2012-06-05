require "nokogiri"
require  "om"
require "solrizer/xml"

#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
module ActiveFedora
  class NokogiriDatastream < Datastream
      
    include MetadataDatastreamHelper
    include OM::XML::Document
    include Solrizer::XML::TerminologyBasedSolrizer # this adds support for calling .to_solr
    
    # extend(OM::XML::Container::ClassMethods)

    alias_method(:om_term_values, :term_values) unless method_defined?(:om_term_values)
    alias_method(:om_update_values, :update_values) unless method_defined?(:om_update_values)
    
    attr_accessor :internal_solr_doc

    # Create an instance of this class based on xml content
    # @param [String, File, Nokogiri::XML::Node] xml the xml content to build from
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are building @default a new instance of this class
    # Careful! If you call this from a constructor, be sure to provide something 'ie. self' as the @tmpl. Otherwise, you will get an infinite loop!
    def self.from_xml(xml, tmpl=nil)
      tmpl = self.new(nil, nil) if tmpl.nil?  ## This path is used only for unit testing (e.g. MarpaDCDatastream.from_xml(fixture("data.xml")) )

      if !xml.present?
        tmpl.ng_xml = self.xml_template
      elsif xml.kind_of? Nokogiri::XML::Node || xml.kind_of?(Nokogiri::XML::Document)
        tmpl.ng_xml = xml
      else
        tmpl.ng_xml = Nokogiri::XML::Document.parse(xml)
      end    
      tmpl.send(:dirty=, false)
      return tmpl
    end
    
    def self.xml_template
      Nokogiri::XML::Document.parse("<xml/>")
    end

    def ng_xml 
      @ng_xml ||= begin
      self.xml_loaded = true

      if new?
        ## Load up the template
        self.class.xml_template
      else
        Nokogiri::XML::Document.parse(content)
      end
      end
    end
    
    def ng_xml=(new_xml)
      ng_xml_will_change!
      self.xml_loaded=true
      case new_xml 
      when Nokogiri::XML::Document
        @ng_xml = new_xml
      when  Nokogiri::XML::Node 
        @ng_xml = Nokogiri::XML(new_xml.to_s) ## Cast a fragment to a document
      when String 
        @ng_xml = Nokogiri::XML::Document.parse(new_xml)
      else
        raise TypeError, "You passed a #{new_xml.class} into the ng_xml of the #{self.dsid} datastream. NokogiriDatastream.ng_xml= only accepts Nokogiri::XML::Document, Nokogiri::XML::Element, Nokogiri::XML::Node, or raw XML (String) as inputs."
      end
    end
    
    # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods 
    def ng_xml_will_change!
      changed_attributes[:ng_xml] = nil
    end
    
    # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods 
    def ng_xml_changed?
      changed_attributes.has_key? :ng_xml
    end
    
    def content=(content)
      super
      self.xml_loaded=true
      @ng_xml = Nokogiri::XML::Document.parse(content)
    end
    
    
    def to_xml(xml = nil)
      xml = self.ng_xml if xml.nil?
      ng_xml = self.ng_xml
      if ng_xml.respond_to?(:root) && ng_xml.root.nil? && self.class.respond_to?(:root_property_ref) && !self.class.root_property_ref.nil?
        ng_xml = self.class.generate(self.class.root_property_ref, "")
        if xml.root.nil?
          xml = ng_xml
        end
      end

      unless xml == ng_xml || ng_xml.root.nil?
        if xml.kind_of?(Nokogiri::XML::Document)
            xml.root.add_child(ng_xml.root)
        elsif xml.kind_of?(Nokogiri::XML::Node)
            xml.add_child(ng_xml.root)
        else
            raise "You can only pass instances of Nokogiri::XML::Node into this method.  You passed in #{xml}"
        end
      end
      
      return xml.to_xml {|config| config.no_declaration}
    end
    
    # ** Experimental **
    #
    # This method is called by ActiveFedora::Base.load_instance_from_solr
    # in order to initialize a nokogiri datastreams values from a solr document.
    # This method merely sets the internal_solr_doc to the document passed in.
    # Then any calls to get_values get values from the solr document on demand
    # instead of directly from the xml stored in Fedora.  This should be used
    # for read-only purposes only, and instances where you want to improve performance by
    # getting data from solr instead of Fedora.
    # 
    # See ActiveFedora::Base.load_instance_from_solr and +get_values_from_solr+ for more information.
    def from_solr(solr_doc)
      #just initialize internal_solr_doc since any value retrieval will be done via lazy loading on this doc on-demand
      @internal_solr_doc = solr_doc
    end


    # ** Experimental **
    # This method is called by +get_values+ if this datastream has been initialized by calling from_solr method via
    # ActiveFedora::Base.load_instance_from_solr. This method retrieves values from a preinitialized @internal_solr_doc instead of xml.
    # This makes the datastream read-only and this method is not intended to be used in any other case.
    #
    # Values are retrieved from the @internal_solr_doc on-demand instead of via xml preloaded into memory.  
    # A term_pointer is passed in and if it contains hierarchical indexes it will detect which solr field values need to be returned.
    #
    # ====Example 1 (non-hierarchical term_pointer):
    #
    #   term_pointer = [:image, :title_set, :title]
    #
    #   Returns value of "image_title_set_title_t" in @internal_solr_doc
    #
    # ====Example 2 (hierarchical term_pointer that contains one or more indexes):
    #   term_pointer = [:image, {:title_set=>1}, :title]
    #
    #   relevant xml:  
    #         <image>
    #           <title_set>
    #             <title>Title 1</title>
    #           </title_set>
    #         </image>
    #         <image>
    #           <title_set>
    #             <title>Title 2</title>
    #           </title_set>
    #           <title_set>
    #             <title>Title 3</title>
    #           </title_set>
    #         </image>
    #    
    #   Repeating element nodes are indexed and will be stored in solr as follows:
    #     image_0_title_set_0_title_t = "Title 1"
    #     image_1_title_set_0_title_t = "Title 2"
    #     image_1_title_set_1_title_t = "Title 3"
    #
    #   Even though no image element index is specified, only the second image element has two title_set elements so the expected return value is
    #     ["Title 3"]
    #
    #   While loading from solr the xml hierarchy is not immediately apparent so we must detect first how many image elements with a title_set element exist
    #   and then check which of those elements have a second title element.
    #   
    #   As this nokogiri datastream is indexed in solr, a value at each level in the tree will be stored independently and therefore 
    #   if 'image_0_title_set_0_title_t' exists in solr 'image_0_title_set_t' will also exist in solr.  
    #   So, we will build up the relevant solr names incrementally for a given term_pointer.  The last element in the
    #   solr_name will not contain an index.
    #
    #   It then will do the following:
    #     Because no index is supplied for :image it will detect which indexes exist in solr
    #        image_0_title_set_t   (found key and add 'image_0_title_set' to base solr_name list)
    #        image_1_title_set_t   (found key and add 'image_0_title_set' to base solr_name list)
    #        image_2_title_set_t   (not found and stop checking indexes for image)
    #     After iteration 1:
    #        bases = ["image_0_title_set","image_1_title_set"]
    #
    #     Two image nodes were found and next sees index of 1 supplied for title_set so just uses index of 1 building off bases found in previous iteration
    #        image_0_title_set_1_title_t (not found remove 'image_0_title_set' from base solr_name list)
    #        image_1_title_set_1_title_t (found and replace 'image_1_title_set' with new base 'image_1_title_set_1_title') 
    #      
    #     After iteration 2:
    #        bases = ["image_1_title_set_1_title"]
    #     It always looks ahead one element so we check if any elements are after title.  There are not any other elements so we are done iterating.
    #        returns @internal_solr_doc["image_1_title_set_1_title_t"]
    # @param [Array] term_pointer Term pointer similar to an xpath ie. [:image, :title_set, :title]
    # @return [Array] If no values are found an empty Array is returned.
    def get_values_from_solr(*term_pointer)
      values = []
      solr_doc = @internal_solr_doc
      return values if solr_doc.nil?
      term = self.class.terminology.retrieve_term(*OM.pointers_to_flat_array(term_pointer, false))
      #check if hierarchical term pointer
      if is_hierarchical_term_pointer?(*term_pointer)
         # if we are hierarchical need to detect all possible node values that exist
         # we do this by building up the possible solr names parent by parent and/or child by child
         # if an index is supplied for any node in the pointer it will be used
         # otherwise it will include all nodes and indexes that exist in solr
         bases = []
         #add first item in term_pointer as start of bases
         # then iterate through possible nodes that might exist
         term_pointer.first.kind_of?(Hash) ? bases << term_pointer.first.keys.first : bases << term_pointer.first
         for i in 1..(term_pointer.length-1)
           #iterate in reverse so that we can modify the bases array while iterating
           (bases.length-1).downto(0) do |j|
             current_last = (term_pointer[i].kind_of?(Hash) ? term_pointer[i].keys.first : term_pointer[i])
             if (term_pointer[i-1].kind_of?(Hash))
               #just use index supplied instead of trying possibilities
               index = term_pointer[i-1].values.first
               solr_name_base = OM::XML::Terminology.term_hierarchical_name({bases[j]=>index},current_last)
               solr_name = generate_solr_symbol(solr_name_base, term.data_type)
               bases.delete_at(j)
               #insert the new solr name base if found
               bases.insert(j,solr_name_base) if has_solr_name?(solr_name,solr_doc)
             else
               #detect how many nodes exist
               index = 0
               current_base = bases[j]
               bases.delete_at(j)
               solr_name_base = OM::XML::Terminology.term_hierarchical_name({current_base=>index},current_last)
               solr_name = generate_solr_symbol(solr_name_base, term.data_type)
               #check for indexes that exist until we find all nodes
               while has_solr_name?(solr_name,solr_doc) do
                 #only reinsert if it exists
                 bases.insert(j,solr_name_base)
                 index = index + 1
                 solr_name_base = OM::XML::Terminology.term_hierarchical_name({current_base=>index},current_last)
                 solr_name = generate_solr_symbol(solr_name_base, term.data_type)
               end
             end
           end
         end

         #all existing applicable solr_names have been found and we can now grab all values and build up our value array
         bases.each do |base|
           field_name = generate_solr_symbol(base.to_sym, term.data_type)
           value = (solr_doc[field_name].nil? ? solr_doc[field_name.to_s]: solr_doc[field_name])
           unless value.nil?
             value.is_a?(Array) ? values.concat(value) : values << value
           end
         end
      else
         #this is not hierarchical and we can simply look for the solr name created using the terms without any indexes
         generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
         generic_field_name = generate_solr_symbol(generic_field_name_base, term.data_type)
         value = (solr_doc[generic_field_name].nil? ? solr_doc[generic_field_name.to_s]: solr_doc[generic_field_name])
         unless value.nil?
           value.is_a?(Array) ? values.concat(value) : values << value
         end
      end
      values
    end

    def generate_solr_symbol(base, data_type)
      Solrizer::XML::TerminologyBasedSolrizer.default_field_mapper.solr_name(base.to_sym, data_type)
    end

    # ** Experimental **
    #@return [Boolean] true if either the key for name exists in solr or if its string value exists
    #@param [String] name Name of key to look for
    #@param [Solr::Document] solr_doc Solr doc to query
    def has_solr_name?(name, solr_doc=Hash.new)
      !solr_doc[name].nil? || !solr_doc[name.to_s].nil?
    end

    # ** Experimental **
    #@return true if the term_pointer contains an index
    # ====Example:
    #     [:image, {:title_set=>1}, :title] return true
    #     [:image, :title_set, :title]      return false
    def is_hierarchical_term_pointer?(*term_pointer)
      if term_pointer.length>1
        term_pointer.each do |pointer|
          if pointer.kind_of?(Hash)
            return true
          end
        end
      end
      return false
    end

    # Update field values within the current datastream using {#update_values}, which is a wrapper for {http://rdoc.info/gems/om/1.2.4/OM/XML/TermValueOperators#update_values-instance_method OM::TermValueOperators#update_values}
    # Ignores any fields from params that this datastream's Terminology doesn't recognize    
    #
    # @param [Hash] params The params specifying which fields to update and their new values.  The syntax of the params Hash is the same as that expected by 
    #         term_pointers must be a valid OM Term pointers (ie. [:name]).  Strings will be ignored.
    # @param [Hash] opts This is not currently used by the datastream-level update_indexed_attributes method
    #
    # Example: 
    #   @mods_ds.update_indexed_attributes( {[{":person"=>"0"}, "role"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} })
    #   => {"person_0_role"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}}
    #
    #   @mods_ds.to_xml # (the following is an approximation)
    #   <mods>
    #     <mods:name type="person">
    #     <mods:role>
    #       <mods:roleTerm>role1</mods:roleTerm>
    #     </mods:role>
    #     <mods:role>
    #       <mods:roleTerm>role2</mods:roleTerm>
    #     </mods:role>
    #     <mods:role>
    #       <mods:roleTerm>role3</mods:roleTerm>
    #     </mods:role>
    #     </mods:name>
    #   </mods>
    def update_indexed_attributes(params={}, opts={})    
      if self.class.terminology.nil?
        raise "No terminology is set for this NokogiriDatastream class.  Cannot perform update_indexed_attributes"
      end
      # remove any fields from params that this datastream doesn't recognize    
      # make sure to make a copy of params so not to modify hash that might be passed to other methods
      current_params = params.clone
      current_params.delete_if do |term_pointer,new_values| 
        if term_pointer.kind_of?(String)
          logger.warn "WARNING: #{dsid} ignoring {#{term_pointer.inspect} => #{new_values.inspect}} because #{term_pointer.inspect} is a String (only valid OM Term Pointers will be used).  Make sure your html has the correct field_selector tags in it."
          true
        else
          !self.class.terminology.has_term?(*OM.destringify(term_pointer))
        end
      end

      result = {}
      unless current_params.empty?
        result = update_values( current_params )
      end
      
      return result
    end
    
    def get_values(field_key,default=[])
      term_values(*field_key)
    end


    def find_by_terms(*termpointer)
      super
    end

    # Update values in the datastream's xml
    # This wraps {http://rdoc.info/gems/om/1.2.4/OM/XML/TermValueOperators#update_values-instance_method OM::TermValueOperators#update_values} so that returns an error if we have loaded from solr since datastreams loaded that way should be read-only
    #
    # @example Updating multiple values with a Hash of Term pointers and values
    #   ds.update_values( {[{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}, [{:person=>1}, :family_name]=>"Andronicus", [{"person"=>"1"},:given_name]=>["Titus"],[{:person=>1},:role,:text]=>["otherrole1","otherrole2"] } )
    #   => {"person_0_role_text"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}, "person_1_role_text"=>{"0"=>"otherrole1", "1"=>"otherrole2"}} 
    def update_values(params={})
      if @internal_solr_doc
        raise "No update performed, this object was initialized via Solr instead of Fedora and is therefore read-only.  Please utilize ActiveFedora::Base.find to first load object via Fedora instead."
      else
        ng_xml_will_change!
        result = om_update_values(params)
        return result
      end
    end

    #override OM::XML::term_values so can lazy load from solr if this datastream initialized using +from_solr+
    def term_values(*term_pointer)
      if @internal_solr_doc
        #lazy load values from solr on demand
        get_values_from_solr(*term_pointer)
      else
        om_term_values(*term_pointer)
      end
    end
  end
end

