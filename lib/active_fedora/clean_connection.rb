module ActiveFedora
  class CleanConnection < SimpleDelegator
    def get(*args)
      result = __getobj__.get(*args) do |req|
        prefer_headers = Ldp::PreferHeaders.new(req.headers["Prefer"])
        prefer_headers.omit = prefer_headers.omit | omit_uris
	req.headers["Prefer"] = prefer_headers.to_s
      end
      CleanResult.new(result)
    end

    private

      def omit_uris
        [
	  "http://fedora.info/definitions/fcrepo#ServerManaged",
          ::RDF::Vocab::Fcrepo4.ServerManaged,
          ::RDF::Vocab::LDP.PreferContainment,
          ::RDF::Vocab::LDP.PreferEmptyContainer,
          ::RDF::Vocab::LDP.PreferMembership
        ]
      end

      class CleanResult < SimpleDelegator
        def graph
          @graph ||= clean_graph
        end

        private

          def clean_graph
            __getobj__.graph.delete(has_model_query)
            __getobj__.graph
          end

          def has_model_query
            [nil, ActiveFedora::RDF::Fcrepo::Model.hasModel, nil]
          end
      end
  end
end
