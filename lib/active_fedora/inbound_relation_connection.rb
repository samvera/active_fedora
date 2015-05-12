module ActiveFedora
  class InboundRelationConnection < SimpleDelegator
    def get(*args)
      result = __getobj__.get(*args) do |req|
        prefer_headers = Ldp::PreferHeaders.new(req.headers["Prefer"])
        prefer_headers.include = prefer_headers.include | include_uris
        req.headers["Prefer"] = prefer_headers.to_s
        yield req if block_given?
      end
      result
    end

    private

    def include_uris
      [
        RDF::Fcrepo4.InboundReferences
      ]
    end
  end
end
