module ActiveFedora
  class SparqlInsert

    attr_reader :changes, :subject

    def initialize(changes, subject = ::RDF::URI.new(nil))
      @changes = changes
      @subject = subject
    end

    def execute(uri)
      result = ActiveFedora.fedora.connection.patch(uri, build, "Content-Type" => "application/sparql-update")
      return true if result.status == 204
      raise "Problem updating #{result.status} #{result.body}"
    end

    def build
      query = deletes(subject).join
      query += "INSERT { \n"
      query +=
        changes.map do |_, result|
          result.map do |statement|
            ::RDF::Query::Pattern.new(subject: subject, predicate: statement.predicate, object: statement.object).to_s
          end.join("\n")
        end.join("\n")

      query += "\n}\n WHERE { }"
      query
    end

    private

    def deletes(subject)
      patterns(subject).map do |pattern|
        "DELETE { #{pattern} }\n  WHERE { #{pattern} } ;\n"
      end
    end

    def patterns(subject)
      changes.map do |key, _|
        ::RDF::Query::Pattern.new(subject, key, :change).to_s
      end
    end
  end
end
