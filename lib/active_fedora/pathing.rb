module ActiveFedora
  module Pathing
    extend ActiveSupport::Concern

    included do
      def uri_prefix
        nil
      end

      def has_uri_prefix?
        !uri_prefix.nil?
      end

      def root_resource_path
        if has_uri_prefix?
          ActiveFedora.fedora.base_path + "/" + uri_prefix
        else
          ActiveFedora.fedora.base_path
        end
      end
    end
  end
end
