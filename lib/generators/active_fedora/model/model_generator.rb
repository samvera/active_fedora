require 'rails/generators'

module ActiveFedora
  class ModelGenerator < Rails::Generators::NamedBase
    source_root ::File.expand_path('../templates', __FILE__)
    check_class_collision

    class_option :directory, type: :string, default: 'models', desc: "Which directory to generate? (i.e. app/DIRECTORY)"
    class_option :datastream_directory, type: :string, default: 'models/datastreams', desc: "Which datastream directory to generate? (i.e. models/datastreams)"
    class_option :has_subresource, type: :string, default: nil, desc: "Name a file to attach"
    class_option :datastream, type: :string, default: nil, desc: "Name a metadata datastream to create"

    def install
      template('model.rb.erb', ::File.join('app', directory, "#{file_name}.rb"))
      template('model_spec.rb.erb', ::File.join('spec', directory, "#{file_name}_spec.rb"))
      return unless options[:datastream]
      template('datastream.rb.erb', ::File.join('app', datastream_directory, "#{file_name}_metadata.rb"))
      template('datastream_spec.rb.erb', ::File.join('spec', datastream_directory, "#{file_name}_metadata_spec.rb"))
    end

    protected

      def directory
        options[:directory]
      end

      def datastream_directory
        options[:datastream_directory]
      end
  end
end
