module ActiveFedora::Aggregation
  class Proxy < ActiveFedora::Base
    belongs_to :container, predicate: ::RDF::Vocab::ORE.proxyIn, class_name: 'ActiveFedora::Base'
    belongs_to :target, predicate: ::RDF::Vocab::ORE.proxyFor, class_name: 'ActiveFedora::Base'
    belongs_to :next, predicate: ::RDF::Vocab::IANA.next, class_name: 'ActiveFedora::Aggregation::Proxy'
    belongs_to :prev, predicate: ::RDF::Vocab::IANA.prev, class_name: 'ActiveFedora::Aggregation::Proxy'

    type ::RDF::Vocab::ORE.Proxy

    def as_list
      if self.next
        [self] + self.next.as_list
      else
        [self]
      end
    end
  end
end
