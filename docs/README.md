# ActiveFedora

Relationships between fcrepo/LDP resources are maintained using the following:

- Reflections (ActiveFedora::Reflections::AbstractReflection)
  - Defines relationships between knowledge graph resource URIs and ActiveFedora models at the Class level
  - Supports the following types of relationships:
    - HasManyReflection
    - BelongsToReflection
    - HasAndBelongsToManyReflection
    - HasSubresourceReflection
    - DirectlyContainsReflection
    - DirectlyContainsOneReflection
    - IndirectlyContainsReflection
    - BasicContainsReflection
    - RDFPropertyReflection
    - SingularRDFPropertyReflection
    - FilterReflection
    - OrdersReflection
- Associations (ActiveFedora::Associations::Association)
  - Structures the state of relationships between graph URIs for ActiveFedora LDP resources
  - Supports the following types of relationships:
    - SingularAssociation
    - RDF
    - SingularRDF
    - CollectionAssociation
    - CollectionProxy
    - ContainerProxy
    - HasManyAssociation
    - BelongsToAssociation
    - HasAndBelongsToManyAssociation
    - BasicContainsAssociation
    - HasSubresourceAssociation
    - DirectlyContainsAssociation
    - DirectlyContainsOneAssociation
    - IndirectlyContainsAssociation
    - ContainsAssociation
    - FilterAssociation
    - OrdersAssociation
- Properties (ActiveTriples::NodeConfig)
  - This is used very closely with ActiveTriples
  - Provides integration with ActiveRecord/ActiveModel attributes and knowledge graph assertions in the RDF

## Ordering in the RDF

Ordering within ActiveFedora is supported using an implementation of an ordered list. For an example, let us define the following class:

```ruby
class Child < ActiveFedora::Base
    # ...
end

class Collection < ActiveFedora::Base
    ordered_aggregation :children, through: :list_source
end
```

...yielding the following methods for the `Collection` objects:

- `Collection#children`
- `Collection#ordered_children`
- `Collection#ordered_children_proxy`

### `Collection#children`

This method provides abstract access to the `Child` objects with a many-to-one relationship with the `Collection` object:

```ruby
> collection = Collection.create
=> 
> collection.association(:children).class
=> ActiveFedora::Associations::IndirectlyContainsAssociation
> collection.association(:children).reader.class
=> ActiveFedora::Associations::ContainerProxy
```

### `Collection#ordered_children`

```ruby
> owner.association(:list_source).class
=> ActiveFedora::Associations::HasSubresourceAssociation
```

### `Collection#ordered_children_proxy`

```ruby
> collection.association(:ordered_children_proxy).class
=> ActiveFedora::Associations::ContainerProxy
> collection.association(:ordered_children_proxy).target.class
=> ActiveFedora::Associations::OrderedList
> collection.association(:ordered_children_proxy).target.ordered_reader
=> ActiveFedora::Associations::OrderedReader
```

### `Collection#list_source`

parent_uri > list_source_uri > proxy > proxy_head_uri > first_child_uri
parent_uri > list_source_uri > proxy > proxy_tail_uri > last_child_uri

# LDP

Every ActiveFedora::Base Model contains, as a private member variable, a LDP Resource. This, in turn, provides access to the RDF Graph for the Resource.

## 