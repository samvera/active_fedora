module ActiveFedora
  module Datastreams
    module NokogiriDatastreams
      extend ActiveSupport::Concern

      module ClassMethods

        def xml_template
          Nokogiri::XML::Document.parse("<xml/>")
        end

        def decorate_ng_xml(xml)
          xml
        end
      end


      def ng_xml 
        @ng_xml ||= begin
          if new_record?
            ## Load up the template
            xml = self.class.xml_template
          else
            xml = Nokogiri::XML::Document.parse(remote_content)
          end
          self.class.decorate_ng_xml xml
        end
      end
      
      def ng_xml=(new_xml)
        # before we set ng_xml, we load the datastream so we know if the new value differs.
        # TODO reinstate this
        #local_or_remote_content(true)

        case new_xml 
        when Nokogiri::XML::Document
          self.content=new_xml.to_xml
        when  Nokogiri::XML::Node 
          ## Cast a fragment to a document
          self.content=new_xml.to_s
        when String 
          self.content=new_xml
        else
          raise TypeError, "You passed a #{new_xml.class} into the ng_xml of the #{self.dsid} datastream. OmDatastream.ng_xml= only accepts Nokogiri::XML::Document, Nokogiri::XML::Element, Nokogiri::XML::Node, or raw XML (String) as inputs."
        end
      end
      
      def refresh_attributes
        changed_attributes.clear
        @ng_xml = nil
      end

      # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods
      def ng_xml_will_change!
        changed_attributes['ng_xml'] = nil
      end

      def ng_xml_doesnt_change!
        changed_attributes.delete('ng_xml')
      end

      # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods
      def ng_xml_changed?
        changed_attributes.has_key? 'ng_xml'
      end

      def remote_content
        @datastream_content ||= Nokogiri::XML(super).to_xml {|config| config.no_declaration}.strip
      end

      def content=(new_content)
        if remote_content != new_content.to_s
          ng_xml_will_change!
          @ng_xml = Nokogiri::XML::Document.parse(new_content)
          super(@ng_xml.to_s.strip)
        end
        self.class.decorate_ng_xml @ng_xml
      end

      def content_changed?
        return true if autocreate? && new_record?
        return false unless xml_loaded
        ng_xml_changed?
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

        return xml.to_xml.strip
      end

      def content
        @content = to_xml if ng_xml_changed? || autocreate?
        super
      end

      def autocreate?
        changed_attributes.has_key? :profile
      end

      def xml_loaded
        instance_variable_defined? :@ng_xml
      end
    end
  end
end
