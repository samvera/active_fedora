module ActiveFedora
  class SparqlInsert

    attr_reader :changed_attributes, :resource

    def initialize(obj)
      @object = obj
      @resource = obj.resource
      @changed_attributes = obj.changed_attributes
    end

    def empty?
      changes.empty?
    end

    def changes
      @changes ||= changed_attributes.each_with_object({}) do |(key, value), result|
        if m = /^.*_ids?$/.match(key)
          predicate = @object.association(m[0]).reflection.predicate
          result[predicate] = resource.query(predicate: predicate)
        elsif @object.class.properties.keys.include?(key)
          # This is the ActiveTriples 0.4.0+ way:
          # predicate = resource.reflections.reflect_on_property(key).predicate
          # This is the old 0.2.3 way:
          predicate = @object.singleton_class.properties[key].predicate
          result[predicate] = resource.query(predicate: predicate)
        elsif @object.local_attributes.include?(key)
          raise "Unable to find a graph predicate corresponding to the attribute: \"#{key}\""
        end
      end
    end

    def build
      subject = RDF::URI.new(nil)

      patterns = changes.map do |key, _|
        RDF::Query::Pattern.new(subject, key, :wild).to_s
      end.join("\n")

      query = "DELETE { \n"
      query += patterns
      query += "\n}\n"
      query += "WHERE { \n"
      query += patterns
      query += "\n} ;"

      query += "INSERT { \n"
      query +=
        changes.map do |_, result|
          result.map do |statement|
            RDF::Query::Pattern.new(subject: subject, predicate: statement.predicate, object: statement.object).to_s
          end.join("\n")
        end.join("\n")

      query += "\n}\n WHERE { }"
      query
    end
  end
end
