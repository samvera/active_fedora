module ActiveFedora
  module Rdf
    extend ActiveSupport::Autoload
    autoload :Indexing
    autoload :Identifiable
    autoload :ObjectResource

    # Aliases for deprecated ActiveFedora::Rdf Classes/Modules
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
end
