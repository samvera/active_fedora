module ActiveFedora
  class VersionsGraph < ::RDF::Graph
    def all(opts = {})
      versions = fedora_versions
      unless opts[:include_auto_save]
        versions.reject! { |version| version.label =~ /auto/ }
      end
      versions.sort_by { |version| DateTime.parse(version.created) }
    rescue ArgumentError, NoMethodError
      raise ActiveFedora::VersionLacksCreateDate
    end

    delegate :first, to: :all

    delegate :last, to: :all

    def with_label(label)
      all.each do |version|
        return version if version.label == label
      end
    end

    def resources
      query(predicate: ::RDF::Vocab::Fcrepo4.hasVersion)
    end

    private

      class ResourceVersion
        attr_accessor :uri, :label, :created
      end

      def version_from_resource(statement)
        version = ResourceVersion.new
        version.uri = statement.object.to_s.gsub(/\/fcr:metadata$/, "")
        version.label = label_query(statement)
        version.created = created_query(statement)
        version
      end

      def label_query(statement)
        query(subject: statement.object).query(predicate: ::RDF::Vocab::Fcrepo4.hasVersionLabel).first.object.to_s
      end

      def created_query(statement)
        query(subject: statement.object).query(predicate: ::RDF::Vocab::Fcrepo4.created).first.object.to_s
      end

      def fedora_versions
        resources.map { |statement| version_from_resource(statement) }
      end
  end
end
