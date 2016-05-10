module ActiveFedora
  module Identifiable
    extend ActiveSupport::Concern

    included do
      ##
      # :singleton-method
      #
      # Accepts a proc that takes an id and transforms it to a URI
      mattr_reader :translate_id_to_uri

      # This method is mixed into ActiveFedora::Base and ActiveFedora::File, so don't
      # overwrite the value if it's already set.
      @@translate_id_to_uri ||= Core::FedoraIdTranslator

      def self.translate_id_to_uri=(translator)
        @@translate_id_to_uri = translator || Core::FedoraIdTranslator
      end

      ##
      # :singleton-method
      #
      # Accepts a proc that takes a uri and transforms it to an id
      mattr_reader :translate_uri_to_id

      # This method is mixed into ActiveFedora::Base and ActiveFedora::File, so don't
      # overwrite the value if it's already set.
      @@translate_uri_to_id ||= Core::FedoraUriTranslator

      def self.translate_uri_to_id=(translator)
        @@translate_uri_to_id = translator || Core::FedoraUriTranslator
      end
    end

    def id
      if uri.is_a?(::RDF::URI) && uri.value.blank?
        nil
      elsif uri.present?
        self.class.uri_to_id(URI.parse(uri))
      end
    end

    def id=(id)
      raise "ID has already been set to #{self.id}" if self.id
      @ldp_source = build_ldp_resource(id.to_s)
    end

    # @return [RDF::URI] the uri for this resource
    def uri
      @ldp_source.subject_uri
    end

    module ClassMethods
      ##
      # Transforms an id into a uri
      # if translate_id_to_uri is set it uses that proc, otherwise just the default
      def id_to_uri(id)
        translate_id_to_uri.call(id)
      end

      ##
      # Transforms a uri into an id
      # if translate_uri_to_id is set it uses that proc, otherwise just the default
      def uri_to_id(uri)
        translate_uri_to_id.call(uri)
      end

      ##
      # Provides the common interface for ActiveTriples::Identifiable
      def from_uri(uri, _)
        find(uri_to_id(uri))
      rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
        ActiveTriples::Resource.new(uri)
      end
    end
  end
end
