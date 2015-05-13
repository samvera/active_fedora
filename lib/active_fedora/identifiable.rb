module ActiveFedora
  module Identifiable
    extend ActiveSupport::Concern

    included do
      class_attribute :translate_id_to_uri
      self.translate_id_to_uri = Core::FedoraIdTranslator

      class_attribute :translate_uri_to_id
      self.translate_uri_to_id = Core::FedoraUriTranslator
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
      def from_uri(uri,_)
        begin
          self.find(uri_to_id(uri))
        rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
          ActiveTriples::Resource.new(uri)
        end
      end
    end
  end
end
