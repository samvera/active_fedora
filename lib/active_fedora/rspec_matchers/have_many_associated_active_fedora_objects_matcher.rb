# RSpec matcher to spec delegations.

RSpec::Matchers.define :have_many_associated_active_fedora_objects do |association_name|
  match do |subject|
    @association_name = association_name
    if @association_name.nil? || !@expected_objects.respond_to?(:count)
      raise(
        ArgumentError,
        "expect(subject).to have_many_associated_active_fedora_objects(<association_name>).with_objects(<objects[]>)"
      )
    end

    @subject = subject.class.find(subject.id)
    @actual_objects = @subject.send(@association_name)

    if @expected_objects
      actual_count = @actual_objects.count
      expected_count = @expected_objects.count
      if actual_count != expected_count
        raise(
          RSpec::Expectations::ExpectationNotMetError,
          "#{@subject.class} ID=#{@subject.id} relationship: #{@association_name.inspect} count <Expected Count: #{expected_count}> <Actual: #{actual_count}>"
        )
      end
      intersection = @actual_objects & @expected_objects
      intersection.count == @expected_objects.count
    end
  end

  chain(:with_objects) { |objects| @expected_objects = objects }

  description do
    "#{@subject.class} ID=#{@subject.id} association: #{@association_name.inspect} matches ActiveFedora"
  end

  failure_message do |_text|
    "expected #{@subject.class} ID=#{@subject.id} association: #{@association_name.inspect} to match"
  end

  failure_message_when_negated do |_text|
    "expected #{@subject.class} ID=#{@subject.id} association: #{@association_name.inspect} to NOT match"
  end
end
