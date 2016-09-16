module ActiveFedora
  module RDF
    extend ActiveSupport::Autoload
    autoload :Fcrepo
    autoload :IndexingService
    autoload :Persistence
    autoload :ProjectHydra
    autoload :FieldMap
    autoload :FieldMapEntry
    autoload :ValueCaster
  end
end
