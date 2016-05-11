module ActiveFedora::WithMetadata
  class DefaultStrategy < ActiveTriples::ExtensionStrategy
    # override apply method to check if property already exists or reciever already has predicate defined.
    # Do not add property if the rdf_resource already responds to the property name
    # Do not add property if the rdf_resource already has a property with the same predicate.
    def self.apply(resource, property)
      return if resource.respond_to?(property.name)
      return if resource.properties.any? { |p| p[1].predicate == property.predicate }
      resource.property property.name, property.to_h
    end
  end
end
