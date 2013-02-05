# RSpec matcher to spec delegations.

RSpec::Matchers.define :match_fedora_datastream do |method|
  match do |object|
    @method = method
    @object = object
    if @expected_xml.nil?
      raise(
        ArgumentError,
        "match_fedora_datastream(<datastream_name>).with(<expected_xml>)"
      )
    end
    expected = Nokogiri::XML(@expected_xml)

    base_url = ActiveFedora.config.credentials[:url]
    @fedora_datastream_url = File.join(
      base_url, 'objects', @object.pid.to_s,'datastreams', @method, 'content'
    )

    response = RestClient.get(@fedora_datastream_url)

    actual = Nokogiri::XML(response.body)

    EquivalentXml.equivalent?(expected, actual, :normalize_whitespace => true)
  end

  chain(:with) { |expected_xml| @expected_xml = expected_xml }

  description do
    "#{@object.class} PID=#{@object.pid} datastream: #{@method.inspect} matches Fedora"
  end

  failure_message_for_should do |text|
    "expected #{@object.class} PID=#{@object.pid} datastream: #{@method.inspect} to match Fedora"
  end

  failure_message_for_should_not do |text|
    "expected #{@object.class} PID=#{@object.pid} datastream: #{@method.inspect} to NOT match Fedora"
  end

end
