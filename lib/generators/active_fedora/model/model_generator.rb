require 'rails/generators'

module ActiveFedora
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
    check_class_collision

    class_option :directory, :type => :string, :default => 'models', :desc => "Which directory to generate? (i.e. app/DIRECTORY)"

    def install
      template('model.rb.erb',File.join('app', directory, "#{file_name}.rb"))
      template('model_spec.rb.erb',File.join('spec', directory, "#{file_name}_spec.rb"))
    end

    protected

    def directory
      options[:directory] || 'models'
    end
  end
end
