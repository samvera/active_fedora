module Hydra
  # This is an example of a OmDatastream that defines a terminology for Hydra rightsMetadata xml
  # The documentation for Hydra rightsMetadata is on the Hydra wiki at https://wiki.duraspace.org/display/hydra/Hydra+rights+metadata
  # The real version of this Terminology is part of the hydra-head plugin.  See https://github.com/projecthydra/hydra-head/blob/master/lib/hydra/rights_metadata.rb
  #
  # The purpose of rightsMetadata is to store information about access controls and licensing for the object that the rightsMetadata is attached to
  #
  # The most interesting thing going on in this Class is the use of custom methods to access and update permissions in intuitive ways.
  # These methods allow you to do things like
  # * Get reports on which groups & individuals have which permissions
  # * Update permissions for individuals & groups with straightforward syntax
  #
  # Another interesting thing in this Class: it extends to_solr, first calling "super" (the default to_solr behavior) and then inserting an additional embargo_release_date_dt field
  # It uses Solrizer::Extractor.insert_solr_field_value to do this.  That method handles inserting new values into a Hash while ensuring that you don't destroy or overwrite any existing values in the hash.
  class RightsMetadataDatastream < ActiveFedora::OmDatastream       
  
    set_terminology do |t|
      t.root(:path=>"rightsMetadata", :xmlns=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd") 
      t.copyright {
        t.machine {
          t.cclicense        
        }
        t.human_readable(:path=>"human")
        t.cclicense(:proxy=>[:machine, :cclicense ])                  
      }
      t.access {
        t.human_readable(:path=>"human")
        t.machine {
          t.group
          t.person
        }
        t.person(:proxy=>[:machine, :person])
        t.group(:proxy=>[:machine, :group])
        # accessor :access_person, :term=>[:access, :machine, :person]
      }
      t.discover_access(:ref=>[:access], :attributes=>{:type=>"discover"})
      t.read_access(:ref=>[:access], :attributes=>{:type=>"read"})
      t.edit_access(:ref=>[:access], :attributes=>{:type=>"edit"})
      # A bug in OM prevnts us from declaring proxy terms at the root of a Terminology
      # t.access_person(:proxy=>[:access,:machine,:person])
      # t.access_group(:proxy=>[:access,:machine,:group])
    
      t.embargo {
        t.human_readable(:path=>"human")
        t.machine{
          t.date(:type =>"release")
        }
        t.embargo_release_date(:proxy => [:machine, :date])
      }    
    end
    
    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.rightsMetadata(:version=>"0.1", "xmlns"=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1") {
          xml.copyright {
            xml.human
            xml.machine {
              xml.uvalicense "no"
            }
          }
          xml.access(:type=>"discover") {
            xml.human
            xml.machine
          }
          xml.access(:type=>"read") {
            xml.human 
            xml.machine
          }
          xml.access(:type=>"edit") {
            xml.human
            xml.machine
          }
          xml.embargo{
            xml.human
            xml.machine
          }        
        }
      end
      return builder.doc
    end

    def prefix
      "#{dsid.underscore}__"
    end

    
    # Returns the permissions for the selected person/group
    # If new_access_level is provided, updates the selected person/group access_level to the one specified 
    # A new_access_level of "none" will remove all access_levels for the selected person/group
    # @param [Hash] selector
    # @param [String] new_access_level (default nil)
    # @return [Hash] 
    # 
    # @example Query permissions for person123, Set the permissions to "read", then query again to see that they have changed.
    #   permissions({:person=>"person123"})
    #   => {"person123"=>"edit"}
    #   permissions({:person=>"person123"}, "read")
    #   => {"person123"=>"read"}
    #   permissions({:person=>"person123"})
    #   => {"person123"=>"read"}
    def permissions(selector, new_access_level=nil)
    
      type = selector.keys.first.to_sym
      actor = selector.values.first
      if new_access_level.nil?
        xpath = self.class.terminology.xpath_for(:access, type, actor)
        nodeset = self.find_by_terms(xpath)
        if nodeset.empty?
          return "none"
        else
          return nodeset.first.ancestors("access").first.attributes["type"].text
        end
      else
        remove_all_permissions(selector)
        unless new_access_level == "none" 
          access_type_symbol = "#{new_access_level}_access".to_sym
          result = self.update_values([access_type_symbol, type] => {"-1"=>actor})
        end
        self.dirty = true
        return new_access_level
      end
      
    end
  
    # Reports on which groups have which permissions
    # @return [Hash] 
    # @example
    #   sample_ds.permissions({"group"=>"group_zzz"}, "edit")
    #   sample_ds.permissions({"group"=>"public"}, "discover")
    #   sample_ds.groups #=>  {"public"=>"discover", "group_zzz"=>"edit"}
    def groups
      return quick_search_by_type(:group)
    end
  
    # Reports on which groups have which permissions
    # @return [Hash] 
    # @example
    #   sample_ds.permissions({"person"=>"person_123"}, "read")
    #   sample_ds.permissions({""person"=>"person_456"}, "edit")
    #   sample_ds.individuals #=>  {"person_123"=>"read", "person_456"=>"edit"}
    def individuals
      return quick_search_by_type(:person)
    end
  
    # Updates permissions for all of the persons and groups in a hash
    # @param [Hash] params example: {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}}
    # Currently restricts actor type to group or person.  Any others will be ignored
    def update_permissions(params)
      params.fetch("group", {}).each_pair {|group_id, access_level| self.permissions({"group"=>group_id}, access_level)}
      params.fetch("person", {}).each_pair {|group_id, access_level| self.permissions({"person"=>group_id}, access_level)}
    end
  
    # This method limits the response to known access levels (:discover, :read, :edit).  Probably runs a bit faster than {#permissions}.
    # @param [:group,:person] type 
    # @return [Hash] 
    def quick_search_by_type(type)
      result = {}
      [{:discover_access=>"discover"},{:read_access=>"read"},{:edit_access=>"edit"}].each do |access_levels_hash|
        access_level = access_levels_hash.keys.first
        access_level_name = access_levels_hash.values.first
        self.find_by_terms(*[access_level, type]).each do |entry|
          result[entry.text] = access_level_name
        end
      end
      return result
    end

    attr_reader :embargo_release_date
    def embargo_release_date=(release_date)
      release_date = release_date.to_s if release_date.is_a? Date
      begin
        Date.parse(release_date)
      rescue 
        return "INVALID DATE"
      end
      self.update_values({[:embargo,:machine,:date]=>release_date})
    end
    def embargo_release_date(opts={})
      embargo_release_date = self.find_by_terms(*[:embargo,:machine,:date]).first ? self.find_by_terms(*[:embargo,:machine,:date]).first.text : nil
      if opts[:format] && opts[:format] == :solr_date
        embargo_release_date << "T23:59:59Z"
      end
      embargo_release_date
    end
    def under_embargo?
      (embargo_release_date && Date.today < embargo_release_date.to_date) ? true : false
    end

    def to_solr(solr_doc=Hash.new)
      super(solr_doc)
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, "embargo_release_date_dt", embargo_release_date(:format=>:solr_date)) if embargo_release_date
      solr_doc
    end




  
    private
    # Purge all access given group/person 
    def remove_all_permissions(selector)
      type = selector.keys.first.to_sym
      actor = selector.values.first
      xpath = self.class.terminology.xpath_for(:access, type, actor)
      nodes_to_purge = self.find_by_terms(xpath)
      nodes_to_purge.each {|node| node.remove}
    end
  
  end
end
