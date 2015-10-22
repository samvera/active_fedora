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
            ::RDF::Query::Pattern.new(subject: pattern_subject(statement.subject), predicate: statement.predicate, object: statement.object).to_s
          end.join("\n")
        end.join("\n")

      query += "\n}\n WHERE { }"
      query
    end

    private

      def pattern_subject(potential_subject)
        if MaybeHashUri.new(potential_subject).hash?
          potential_subject
        else
          subject
        end
      end

      def deletes(subject)
        patterns(subject).map do |pattern|
          "DELETE { #{pattern} }\n  WHERE { #{pattern} } ;\n"
        end
      end

      # Returns query patterns for finding all existing changed properties as well
      # as well as their embedded hash-uri graphs.
      #
      # @return [Array<::RDF::Query::Pattern>]
      def patterns(subject)
        changes.flat_map do |key, result|
          [
            ::RDF::Query::Pattern.new(subject, key, :change).to_s,
            hash_patterns(result)
          ].flatten
        end
      end

      def hash_patterns(graph)
        graph = graph.select do |statement|
          MaybeHashUri.new(statement.subject).hash?
        end
        graph.map do |statement|
          ::RDF::Query::Pattern.new(statement.subject, statement.predicate, :change).to_s
        end
      end
  end

  class MaybeHashUri
    attr_reader :uri
    def initialize(uri)
      @uri = uri
    end

    def hash?
      uri.to_s.include?("#")
    end
  end
end
