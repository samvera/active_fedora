module ActiveFedora
  class FilePathBuilder
    # Builds a relative path for a file
    def self.build(digital_object, name, prefix)
      name = nil if name == ''
      prefix ||= 'DS'
      name || generate_dsid(digital_object, prefix)
    end

    # return a valid dsid that is not currently in use.  Uses a prefix (default "DS") and an auto-incrementing integer
    # Example: if there are already datastreams with IDs DS1 and DS2, this method will return DS3.  If you specify FOO as the prefix, it will return FOO1.
    def self.generate_dsid(digital_object, prefix)
      return unless digital_object
      matches = digital_object.attached_files.keys.map do |d|
        data = /^#{prefix}(\d+)$/.match(d)
        data && data[1].to_i
      end.compact
      val = matches.empty? ? 1 : matches.max + 1
      format_dsid(prefix, val)
    end

    ### Provided so that an application can override how generated ids are formatted (e.g DS01 instead of DS1)
    def self.format_dsid(prefix, suffix)
      format "%s%i", prefix, suffix
    end
  end
end
