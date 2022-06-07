# frozen_string_literal: true
module ActiveFedora
  module Persistence
    # An identifier service that doesn't mint IDs, so that the autocreated
    # identifiers from Fedora will be used.
    class NullIdentifierService
      # Effectively a no-op
      # @return [NilClass]
      def mint; end
    end
  end
end
