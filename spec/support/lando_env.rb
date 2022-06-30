# frozen_string_literal: true

if ENV["environment"] && ENV["environment"] == "test"
  begin
    lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)

    lando_services.each do |service|
      service[:urls]&.each do |value|
        ENV["lando_#{service[:service]}_url"] = value
      end

      next unless service[:external_connection]
      service[:external_connection].each do |key, value|
        ENV["lando_#{service[:service]}_conn_#{key}"] = value
      end

      next unless service[:creds]
      service[:creds].each do |key, value|
        ENV["lando_#{service[:service]}_creds_#{key}"] = value
      end
    end

    fcrepo_url = ENV["lando_active_fedora_fcrepo4_url"]
    fcrepo_uri = URI.parse(fcrepo_url)
    ENV['FCREPO_HOST'] = fcrepo_uri.host
    ENV['FCREPO_PORT'] = fcrepo_uri.port.to_s

    solr_url = ENV["lando_active_fedora_development_solr_url"]
    solr_uri = URI.parse(solr_url)
    ENV['SOLR_DEVELOPMENT_HOST'] = solr_uri.host
    ENV['SOLR_DEVELOPMENT_PORT'] = solr_uri.port.to_s

    solr_url = ENV["lando_active_fedora_test_solr_url"]
    solr_uri = URI.parse(solr_url)
    ENV['SOLR_TEST_HOST'] = solr_uri.host
    ENV['SOLR_TEST_PORT'] = solr_uri.port.to_s
  rescue StandardError => error
    nil
  end
end
