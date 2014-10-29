module ActiveFedora
  module LoadableFromJson
    extend ActiveSupport::Concern

    class SolrBackedDatastream
      def freeze
        @hash.freeze
      end

      def initialize
        @hash = {}
      end

      def term_values *terminology
        @hash.fetch(terminology.first, [])
      end

      def update_indexed_attributes hash
        hash.each do |k, v|
          @hash[k.first] = v
        end
      end
    end

    class SolrBackedResource
      def freeze
        @hash.freeze
      end

      def initialize
        @hash = {}
      end

      def set_value(k, v)
        @hash[k] = v
      end

      def get_values(k)
        @hash[k]
      end
    end

    # @param json [String] json to be parsed into attributes
    def init_with_json(json)
      attrs = JSON.parse(json)
      pid = attrs.delete('id')

      datastreams
      @orm = Ldp::Orm.new(build_ldp_resource(pid))
      @association_cache = {}
      child_resource_reflections.dup.each do |key, val|
        datastreams[key] = SolrBackedDatastream.new
      end
      @resource = SolrBackedResource.new
      self.attributes = attrs.except(ds_specs.keys)
      # TODO Should we clear the change tracking, or make this object Read-only?

      run_callbacks :find
      run_callbacks :initialize
      freeze
      self
    end

  end
end
