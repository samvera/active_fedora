begin
  lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)
  lando_services.each do |service|
    urls = service[:urls]
    unless urls.empty?
      value = urls.first
      parsed = URI.parse(value)
      ENV["lando_#{service[:service]}_conn_host"] = parsed.host
      ENV["lando_#{service[:service]}_conn_port"] = parsed.port.to_s
    end

    next unless service[:creds]
    service[:creds].each do |key, value|
      ENV["lando_#{service[:service]}_creds_#{key}"] = value
    end
  end
rescue StandardError
  nil
end
