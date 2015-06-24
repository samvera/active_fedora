module ActiveFedora::Associations::Builder
  class DirectlyContainsOne < SingularAssociation #:nodoc:
    self.macro = :directly_contains_one
    self.valid_options += [:has_member_relation, :is_member_of_relation, :type, :through]
    self.valid_options -= [:predicate]

    def validate_options
      raise ArgumentError, "you must specify a :through option on #{name}.  #{name} will use the container from that directly_contains association." if !options[:through]
      if options[:through]
        inherit_options_from_association(options[:through])
      end
      super

      if options[:class_name] == "ActiveFedora::File"
        raise ArgumentError, "You cannot set :class_name of #{name} to ActiveFedora::File because directly_contains_one needs to assert and read RDF.type assertions, which is not supported by ActiveFedora::File.  To make Files support RDF.type assertions, define a subclass of ActiveFedora::File and make it `include ActiveFedora::WithMetadata`. Otherwise, all subclasses of ActiveFedora::Base support RDF.type assertions."
      elsif !options[:has_member_relation] && !options[:is_member_of_relation]
        raise ArgumentError, "You must specify a :has_member_relation or :is_member_of_relation predicate for #{name}"
      elsif !options[:has_member_relation].kind_of?(RDF::URI) && !options[:is_member_of_relation].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end

      if !options[:type].kind_of?(RDF::URI)
        raise ArgumentError, "You must specify a Type and it must be a kind of RDF::URI"
      end
    end

    private

    # Inherits :has_member_relation from the association corresponding to association_name
    # @param [Symbol] association_name of the association to inherit from
    def inherit_options_from_association(association_name)
      associated_through_reflection = lookup_reflection(association_name)
      raise ArgumentError, "You specified `:through => #{@reflection.options[:through]}` on the #{name} associaiton but #{model} does not actually have a #{@reflection.options[:through]}` association" if associated_through_reflection.nil? || !associated_through_reflection.name
      raise ArgumentError, "You must specify a directly_contains association as the :through option on #{name}.  You provided a #{associated_through_reflection.macro}" unless associated_through_reflection.macro == :directly_contains
      options[:has_member_relation] = associated_through_reflection.options[:has_member_relation] unless options[:has_member_relation]
      options[:class_name] = associated_through_reflection.options[:class_name] unless (options[:class_name] && options[:class_name] != "ActiveFedora::File")
    end

    def lookup_reflection(association_name)
      model.reflect_on_association(association_name)
    end

  end
end
