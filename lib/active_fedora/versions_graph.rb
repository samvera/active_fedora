module ActiveFedora
  class VersionsGraph < ::RDF::Graph
    def all(opts = {})
      versions = fedora_versions
      versions.sort_by { |version| DateTime.parse(version.created) }
    rescue ArgumentError, NoMethodError
      raise ActiveFedora::VersionLacksCreateDate
    end

    delegate :first, to: :all

    delegate :last, to: :all

    def with_datetime(datetime)
      all.each do |version|
        return version if version.created == datetime
      end
    end

    def versions
      query(predicate: ::RDF::Vocab::LDP.contains)
    end

    private

      class ResourceVersion
        attr_accessor :uri, :created
      end

      def version_from_resource(statement)
        version = ResourceVersion.new
        version.uri = statement.object
        version.created = statement.object.to_s.split("fcr:versions/")[1]
        version
      end

      def fedora_versions
        versions.map { |statement| version_from_resource(statement) }
      end
  end
end
