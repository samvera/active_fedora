# RSpec matcher to spec delegations.

RSpec::Matchers.define :have_predicate do |predicate|
  match do |subject|
    @predicate = predicate
    if @predicate.nil? || !@expected_objects.respond_to?(:count)
      raise(
        ArgumentError,
        "subject.should have_predicate(<predicate>).with_objects(<objects[]>)"
      )
    end
    @subject = subject.class.find(subject.pid)
    @actual_objects = @subject.relationships(predicate)

    if @expected_objects
      actual_count = @actual_objects.count
      expected_count = @expected_objects.count
      if actual_count != expected_count
        raise(
          RSpec::Expectations::ExpectationNotMetError,
          "#{@subject.class} PID=#{@subject.pid} relationship: #{@predicate.inspect} count <Expected Count: #{expected_count}> <Actual: #{actual_count}>"
        )
      end
      intersection = @actual_objects.collect do |ao|
        internal_uri = ao.respond_to?(:internal_uri) ? ao.internal_uri : ao
      end & @expected_objects

      intersection.count == @expected_objects.count
    end
  end

  chain(:with_objects) { |objects| @expected_objects = objects }


  description do
    "#{@subject.class} PID=#{@subject.pid} relationship: #{@predicate.inspect} matches Fedora"
  end

  failure_message_for_should do |text|
    "expected #{@subject.class} PID=#{@subject.pid} relationship: #{@predicate.inspect} to match"
  end

  failure_message_for_should_not do |text|
    "expected #{@subject.class} PID=#{@subject.pid} relationship: #{@predicate.inspect} to NOT match"
  end

end
