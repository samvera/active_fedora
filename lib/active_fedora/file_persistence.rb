module ActiveFedora
  module FilePersistence
    extend ActiveSupport::Concern

    include ActiveFedora::Persistence

    private

      def _create_record(_options = {})
        return false if content.nil?
        @ldp_source = build_ldp_binary_source
        ldp_source.create do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def _update_record(_options = {})
        return true unless content_changed?
        ldp_source.content = content
        ldp_source.update do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def build_ldp_binary_source
        if id
          build_ldp_resource_via_uri(uri, content)
        else
          build_ldp_resource_via_uri(nil, content)
        end
      end
  end
end
