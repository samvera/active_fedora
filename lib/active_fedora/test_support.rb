require File.expand_path('../../../spec/support/an_active_model', __FILE__)
module ActiveFedora
  module TestSupport
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
