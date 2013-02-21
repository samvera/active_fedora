module ActiveFedora
  module Auditable
    
    def audit_trail
      @audit_trail ||= FedoraAuditTrail.new(self)
    end
    
    private
    
    AT_NS = {'audit' => 'info:fedora/fedora-system:def/audit#'}
    FOXML_NS = {'foxml' => 'info:fedora/fedora-system:def/foxml#'}
    AT_XPATH = '/foxml:digitalObject/foxml:datastream[@ID = "AUDIT"]/descendant::audit:auditTrail'
        
    class FedoraAuditTrail
      def initialize(object)
        @ng_xml = Nokogiri::XML(object.inner_object.repository.object_xml(:pid => object.pid)).xpath(AT_XPATH, FOXML_NS.merge(AT_NS))  
      end
      def records
        if !@records
          @records = []
          @ng_xml.xpath('.//audit:record', AT_NS).each do |node| 
            @records << FedoraAuditRecord.new(node)
          end
        end
        @records
      end
      def to_xml
        @ng_xml.to_xml
      end
    end
  
    class FedoraAuditRecord
      def initialize(node)
        @record = node
      end
      def id
        @record['ID']
      end
      def process_type
        @record.at_xpath('audit:process/@type', AT_NS).text
      end
      def action
        @record.at_xpath('audit:action', AT_NS).text
      end
      def component_id
        @record.at_xpath('audit:componentID', AT_NS).text
      end
      def responsibility
        @record.at_xpath('audit:responsibility', AT_NS).text
      end
      def date
        @record.at_xpath('audit:date', AT_NS).text
      end
      def justification
        @record.at_xpath('audit:justification', AT_NS).text
      end
    end    
        
  end
end