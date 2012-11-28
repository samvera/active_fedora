module ActiveFedora
  module NamedRelationships
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = 'active-fedora 6.0'

    included do
      class_attribute :class_named_relationships_desc
      self.class_named_relationships_desc = {}
    end

      # ** EXPERIMENTAL **
      # 
      # Check to make sure a subject,name, and predicate triple does not already exist
      # with the same subject but different name.
      # This method is used to ensure conflicting has_relationship calls are not made because
      # predicates cannot be reused across relationship names.  Otherwise, the mapping of relationship name
      # to predicate in RELS-EXT would be broken.
      def named_predicate_exists_with_different_name?(subject,name,predicate)
        if named_relationships_desc.has_key?(subject)
          named_relationships_desc[subject].each_pair do |existing_name, args|
            return true if !args[:predicate].nil? && args[:predicate] == predicate && existing_name != name 
          end
        end
        return false
      end
      
      # ** EXPERIMENTAL **
      #  
      # Return hash that stores named relationship metadata defined by has_relationship calls
      # ====Example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      # Results in the following returned by named_relationships_desc
      #  {:self=>{"audio_records"=>{:type=>AudioRecord, :singular=>nil, :predicate=>:has_part, :inbound=>false}}}
      def named_relationships_desc
        @class_named_relationships_desc ||= Hash[:self => {}]
        #class_named_relationships_desc
      end
      
      # ** EXPERIMENTAL **
      #   
      # Internal method that ensures a relationship subject such as :self and :inbound
      # exist within the named_relationships_desc hash tracking named relationships metadata. 
      def register_named_subject(subject)
        unless named_relationships_desc.has_key?(subject) 
          named_relationships_desc[subject] = {} 
        end
      end
  
      # ** EXPERIMENTAL **
      # 
      # Internal method that adds relationship name and predicate pair to either an outbound (:self)
      # or inbound (:inbound) relationship types.
      def register_named_relationship(subject, name, predicate, opts)
        register_named_subject(subject)
        opts.merge!({:predicate=>predicate})
        named_relationships_desc[subject][name] = opts
      end
      
      # ** EXPERIMENTAL **
      #   
      # Used in has_relationship call to create dynamic helper methods to 
      # append and remove objects to and from a named relationship
      # ====Example
      # For the following relationship
      #
      #  has_relationship "audio_records", :has_part, :type=>AudioRecord
      #
      # Methods audio_records_append and audio_records_remove are created.
      # Boths methods take an object that is kind_of? ActiveFedora::Base as a parameter
      def create_named_relationship_methods(name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_named_relationship(name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_named_relationship(name,object)}
      end 

      #  ** EXPERIMENTAL **
      #  Similar to +create_named_relationship_methods+ except we are merely creating an alias for outbound portion of bidirectional
      #
      #  ====Example
      #    has_bidirectional_relationship "members", :has_collection_member, :is_member_of_collection
      #    
      #    Method members_outbound_append and members_outbound_remove added
      #    This method will create members_append which does same thing as members_outbound_append
      #    and will create members_remove which does same thing as members_outbound_remove
      def create_bidirectional_named_relationship_methods(name,outbound_name)
        append_method_name = "#{name.to_s.downcase}_append"
        remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_method_name}") {|object| add_named_relationship(outbound_name,object)}
        self.send(:define_method,:"#{remove_method_name}") {|object| remove_named_relationship(outbound_name,object)}
      end

    
      deprecation_deprecate :named_predicate_exists_with_different_name?, :named_relationships_desc, :register_named_subject, :register_named_relationship, :create_named_relationship_methods, :create_bidirectional_named_relationship_methods
  end
end
