shared_examples_for "An ActiveModel" do
  begin
    require 'minitest/unit'
    include Minitest::Assertions
  rescue NameError
    puts "Unable to load minitest, here's hoping these methods are adequate"

    def assert(test, *args)
      expect(test).to eq(true)
    end

    def assert_kind_of(klass, inspected_object)
      expect(inspected_object).to be_kind_of(klass)
    end
  end
  include ActiveModel::Lint::Tests

  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

  def model
    subject
  end

end
