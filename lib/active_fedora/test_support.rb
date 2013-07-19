require File.expand_path('../../../spec/support/an_active_model', __FILE__)
module ActiveFedora
  module TestSupport

    # Assert that all of the :objects are persisted the :subject's RELS-EXT entry
    # with the :predicate.
    def assert_rels_ext(subject, predicate, objects = [])
      assert_equal objects.count, subject.relationships(predicate).count
      objects.each do |object|
        internal_uri = object.respond_to?(:internal_uri) ?
          object.internal_uri : object
        assert subject.relationships(predicate).include?(internal_uri)
      end
    end

    # Assert that the :subject's RELS-EXT for predicate :has_model collection
    # includes the class_name
    def assert_rels_ext_has_model(subject, class_name)
      model_relationships = subject.relationships(:has_model)
      assert_block("Expected afmodel:#{class_name} to be defined in #{model_relationships.inspect}") do
        model_relationships.detect {|r| r =~ /\/afmodel:#{class_name}\Z/ }
      end
    end

    # Assert that the :subject's :association_name equals the input :object
    def assert_active_fedora_belongs_to(subject, association_name, object)
      subject.send(association_name).must_equal object
    end

    # Assert that the :subject's :association_name contains all of the :objects
    def assert_active_fedora_has_many(subject, association_name, objects)
      association = subject.send(association_name)
      assert_equal objects.count, association.count
      objects.each do |object|
        assert association.include?(object)
      end
    end
  end
end