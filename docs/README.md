# ActiveFedora

## Relationships

Relationships between fcrepo/LDP resources are maintained using the following:

- Reflections (`ActiveFedora::Reflections::AbstractReflection`)
  - Defines relationships between knowledge graph resource URIs and ActiveFedora models at the Class level
  - Supports the following types of relationships:
    - `HasManyReflection`
    - `BelongsToReflection`
    - `HasAndBelongsToManyReflection`
    - `HasSubresourceReflection`
    - `DirectlyContainsReflection`
    - `DirectlyContainsOneReflection`
    - `IndirectlyContainsReflection`
    - `BasicContainsReflection`
    - `RDFPropertyReflection`
    - `SingularRDFPropertyReflection`
    - `FilterReflection`
    - `OrdersReflection`
- Associations (`ActiveFedora::Associations::Association`)
  - Structures the state of relationships between graph URIs for ActiveFedora LDP resources
  - Supports the following types of relationships:
    - `SingularAssociation`
    - `RDF`
    - `SingularRDF`
    - `CollectionAssociation`
    - `CollectionProxy`
    - `ContainerProxy`
    - `HasManyAssociation`
    - `BelongsToAssociation`
    - `HasAndBelongsToManyAssociation`
    - `BasicContainsAssociation`
    - `HasSubresourceAssociation`
    - `DirectlyContainsAssociation`
    - `DirectlyContainsOneAssociation`
    - `IndirectlyContainsAssociation`
    - `ContainsAssociation`
    - `FilterAssociation`
    - `OrdersAssociation`
- Properties (`ActiveTriples::NodeConfig`)
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
- `Collection#list_source`

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

```ruby
> collection.association(:list_source).class
=> ActiveFedora::Associations::HasSubresourceAssociation
> collection.association(:list_source).target.class
=> ActiveFedora::Aggregation::ListSource
> collection.association(:list_source).target.ordered_self.class
=> ActiveFedora::Orders::OrderedList
```

`OrderedList` class is an implementation of the linked list data structure with the following instance variables and methods:

- `OrderedList#head`
- `OrderedList#tail`
- `OrderedList#ordered_self`
- `OrderedList#to_a`

`OrderedList#head` and `OrderedList#tail` provide access to instances of `ActiveFedora::Orders::OrderedList::HeadSentinel` and  `ActiveFedora::Orders::OrderedList::TailSentinel`

`OrderedList#to_a` delegates to the method `OrderedList#ordered_self`, which references an instance of `ActiveFedora::Aggregation::OrderedReader`:

```ruby
> collection.association(:list_source).target.ordered_self.ordered_reader.class
=> ActiveFedora::Aggregation::OrderedReader
```



parent_uri > list_source_uri > proxy > proxy_head_uri > first_child_uri
parent_uri > list_source_uri > proxy > proxy_tail_uri > last_child_uri

## LDP

Every ActiveFedora::Base Model contains, as a private member variable, a LDP Resource. This, in turn, provides access to the RDF Graph for the Resource.