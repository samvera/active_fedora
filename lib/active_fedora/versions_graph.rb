module ActiveFedora
  class VersionsGraph < ::RDF::Graph

    def all opts={}
      if opts[:include_auto_save]
        fedora_versions
      else
        fedora_versions.reject { |v| v.label.match("auto") }
      end
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def with_label label
      all.each do |version|
        return version if version.label == label
      end
    end

    def resources
      query(predicate: ActiveFedora::RDF::Fcrepo4.hasVersion)
    end

    private

      class ResourceVersion
        attr_accessor :uri, :label, :created
      end

      def version_from_resource statement
        version = ResourceVersion.new
        version.uri = statement.object.to_s.gsub(/\/fcr:metadata$/,"")
        version.label = label_query(statement)
        version.created = created_query(statement)
        return version
      end

      def label_query statement
        query(subject: statement.object).query(predicate: ActiveFedora::RDF::Fcrepo4.hasVersionLabel).first.object.to_s
      end

      def created_query statement
        query(subject: statement.object).query(predicate: ActiveFedora::RDF::Fcrepo4.created).first.object.to_s
      end

      def fedora_versions
        list = resources.map { |statement| version_from_resource(statement) }
        list.sort { |a,b| a.created <=> b.created }
      end

  end

end
