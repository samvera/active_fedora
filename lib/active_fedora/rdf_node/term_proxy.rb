module ActiveFedora
  module RdfNode
    class TermProxy

      attr_reader :parent, :subject, :predicate, :options
      delegate *(Array.public_instance_methods - [:__send__, :__id__, :class, :object_id] + [:as_json]), :to => :target
      

      # @param parent RdfNode
      # @param subject RDF::URI
      # @param options Hash
      def initialize(parent, subject, predicate, options)
        @parent = parent
        @subject = subject
        @predicate = predicate
        @options = options
      end


      def build(attributes={})
        node = mint_node(attributes)
        parent.insert_child(predicate, node)
        reset!
        new_node = target.find { |n| n.rdf_subject == node.rdf_subject}
        new_node = node unless new_node #if it's a list, the find doesn't work, just use the new node
        new_node.new_record = true
        new_node
      end

      def reset!
        @target = nil
      end
      
      # @param [Hash] attributes
      # @option attributes id the rdf subject to use for the node, if omitted the new node will be a b-node
      def mint_node(attributes)
        new_subject = attributes.key?('id') ? RDF::URI.new(attributes.delete('id')) : RDF::Node.new
        return parent.target_class(predicate).new(parent.graph, new_subject).tap do |node|
          node.attributes = attributes if attributes
        end
      end

      def <<(*values)
        values.each { |value| parent.append(subject, predicate, value) }
        reset!
        values
      end

      def delete(*values)
        values.each do |value| 
          parent.delete_predicate(subject, predicate, value)
        end

        values
      end

      def target
        @target ||= load_values
      end

      # Get the values off of the rdf nodes this proxy targets
      def load_values
        values = []

        parent.query(subject, predicate).each do |solution|
          v = solution.value
          v = v.to_s if v.is_a? RDF::Literal
          if options.type == :date
            v = Date.parse(v)
          end
          # If the user provided options[:class_name], we should query to make sure this 
          # potential solution is of the right RDF.type
          if options.class_name
            klass =  class_from_rdf_type(v)
            values << v if klass == ActiveFedora.class_from_string(options.class_name, parent.class)
          else
            values << v
          end
        end

        if options.class_name
          values = values.map{ |found_subject| class_from_rdf_type(found_subject).new(parent.graph, found_subject)}
        end
        
        options.multivalue ? values : values.first
      end
      
      private 

      def target_class
        parent.target_class(predicate)
      end

      # Look for a RDF.type assertion on this node to see if an RDF class is specified.
      # Two classes may be valid for the same predicate (e.g. hasMember)
      # If no RDF.type assertion is found, fall back to using target_class
      def class_from_rdf_type(subject)
        unless subject.kind_of?(RDF::Node) || subject.kind_of?(RDF::URI)
          raise ArgumentError, "Expected the value of #{predicate} to be an RDF object but it is a #{subject.class} #{subject.inspect}"
        end
        q = RDF::Query.new do
          pattern [subject, RDF.type, :value]
        end

        type_uri = []
        q.execute(parent.graph).each do |sol| 
          type_uri << sol.value
        end
        
        klass = ActiveFedora::RdfNode.rdf_registry[type_uri.first]
        klass ||= target_class
        klass
      end

    end
  end
end
