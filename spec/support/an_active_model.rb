shared_examples_for "An ActiveModel" do
  def assert(test, *_args)
    expect(test).to be true
  end

  def assert_kind_of(klass, inspected_object)
    expect(inspected_object).to be_kind_of(klass)
  end

  def assert_equal(the_other, one)
    expect(one).to eq the_other
  end

  include ActiveModel::Lint::Tests

  ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/).each do |m|
    example m.tr('_', ' ') do
      send m
    end
  end

  def model
    subject
  end
end
