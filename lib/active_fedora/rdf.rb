module ActiveFedora
  module RDF
    extend ActiveSupport::Autoload
    autoload :Fcrepo
    autoload :Indexing
    autoload :Identifiable
    autoload :ObjectResource
    autoload :Persistence
    autoload :ProjectHydra

    # Aliases for deprecated ActiveFedora::RDF Classes/Modules
    # TODO: Remove in 8.0.0
    Resource = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::Resource', 'ActiveTriples::Resource')
    Term = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::Term', 'ActiveTriples::Term')
    List = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::List', 'ActiveTriples::List')
    Configurable = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::Configurable', 'ActiveTriples::Configurable')
    Properties = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::Properties', 'ActiveTriples::Properties')
    Repositories = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::Repositories', 'ActiveTriples::Repositories')
    NodeConfig = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::NodeConfig', 'ActiveTriples::NodeConfig')
    NestedAttributes = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf::NestedAttributes', 'ActiveTriples::NestedAttributes')
  end
  Rdf = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveFedora::Rdf', 'ActiveFedora::RDF')
end
