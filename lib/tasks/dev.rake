# frozen_string_literal: true

require 'pry-byebug'

require 'active_fedora/rake_support'

namespace :servers do
  desc "Start solr and postgres servers using lando."
  task :start do
    system("lando start")

    begin
      lando_services = JSON.parse(`lando info --format json`, symbolize_names: true)
      lando_services.each do |service|
        urls = service[:urls]
        unless urls.empty?
          value = urls.first
          parsed = URI.parse(value)
          ENV["lando_#{service[:service]}_conn_host"] = parsed.host
          ENV["lando_#{service[:service]}_conn_port"] = parsed.port
        end

        next unless service[:creds]
        service[:creds].each do |key, value|
          ENV["lando_#{service[:service]}_creds_#{key}"] = value
        end
      end
    rescue StandardError
      nil
    end
  end

  desc "Stop lando solr and postgres servers."
  task :stop do
    system("lando stop")
  end
end
