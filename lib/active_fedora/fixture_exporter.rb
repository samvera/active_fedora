module ActiveFedora
  module FixtureExporter

    def self.export_to_path(pid, path, extra_params={})
      foxml = export(pid, extra_params)
      name = "#{pid.gsub(":","_")}.foxml.xml"
      filename = File.join(path, name)
      file = File.new(filename,"w")
      file.syswrite(foxml)
      filename
    end

    def self.export(pid, extra_params={})
      extra_params = {:format=>:foxml, :context=>:archive}.merge!(extra_params)
      if extra_params[:format].kind_of?(String)
        format = extra_params[:format]
      else
        format = case extra_params[:format]
          when :atom then "info:fedora/fedora-system:ATOM-1.1"
          when :atom_zip then "info:fedora/fedora-system:ATOMZip-1.1"
          when :mets then "info:fedora/fedora-system:METSFedoraExt-1.1"
          when :foxml then "info:fedora/fedora-system:FOXML-1.1"
          else "info:fedora/fedora-system:FOXML-1.1"
        end
      end

      ActiveFedora::Base.connection_for_pid(pid).export(:pid=>pid, :format=>format, :context=>extra_params[:context].to_s)
    end


  end
end

