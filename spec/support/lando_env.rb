# frozen_string_literal: true

if ENV["environment"] && ENV["environment"] == "test"
  begin
    lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)
    lando_services.each do |service|
      service[:urls]&.each do |value|
        ENV["lando_#{service[:service]}_conn"] = value
      end
      next unless service[:creds]
      service[:creds].each do |key, value|
        ENV["lando_#{service[:service]}_creds_#{key}"] = value
      end
    end

    fcrepo_url = ENV["lando_active_fedora_fcrepo4_conn"]
    fcrepo_uri = URI.parse(fcrepo_url)
    ENV['FCREPO_HOST'] = fcrepo_uri.host
    ENV['FCREPO_PORT'] = '8080'
  rescue StandardError
    nil
  end
end
