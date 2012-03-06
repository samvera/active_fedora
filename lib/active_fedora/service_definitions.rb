module ActiveFedora
module ServiceDefinitions
  def self.included(mod)
    # check that it's an AF base
    if mod.ancestors.include? ActiveFedora::Base
      mod.extend(ClassMethods)
      model_uri = mod.to_class_uri
    # load ContentModel, pull Sdef pointers
      begin
        cmodel = ActiveFedora::ContentModel.find(mod.to_class_uri)
        sdef_pids = cmodel.ids_for_outbound(:has_service).collect { |uri|
          uri.split('/')[-1]
        }
      rescue
        sdef_pids = []
      end
      unless sdef_pids.include? "fedora-system:3"
        sdef_pids << "fedora-system:3"
      end
      sdef_pids.each { |sdef_pid| mod.has_service_definition sdef_pid }
    end
  end
  def self.sdef_config
    @@methods ||= begin
      if defined? Rails
        config_path = Rails.root.join('config','service_mappings.yml')
      else
        config_path = 'config/service_mappings.yml'
      end
      YAML::load(File.open(config_path))[:service_mapping]
    end
    @@methods
  end
  def self.lookup_method(sdef_uri, method_name)
    sdef_pid = sdef_uri.split('/')[-1]
    begin
      sdef = sdef_config[sdef_pid]
      return nil unless sdef
      result = nil
      sdef.each { |key, value| result = key if method_name == value }
    rescue
      return nil
    end
    return result
  end

  module ClassMethods
    def sdef_pids
      @sdef_pids ||= []
    end
    def has_service_definition sdef_uri
      sdef_pid = sdef_uri.split('/')[-1]
      unless sdef_pids.include? sdef_pid
        self.add_sdef_methods! sdef_pid
        sdef_pids << sdef_pid
      end
    end
    # iterate over SDef pointers, identify symbols in yaml map
    # inject methods by symbol key
    def add_sdef_methods! sdef_pid
      unless sdef_pid == "fedora-system:3"
        content = ActiveFedora::Base.connection_for_pid(sdef_pid).datastream_dissemination(:pid=>sdef_pid, :dsid=>"METHODMAP")
        method_map = Nokogiri::XML.parse(content)
        methods = method_map.xpath('//fmm:Method').collect { |method|
          method["operationName"]
        }
      else
        methods = ["viewObjectProfile","viewMethodIndex","viewItemIndex","viewDublinCore"]
      end
      methods.each { |method|
        add_method!(sdef_pid, method)
      }
    end
    def add_method!(sdef_pid, method_name)
      # find method_key
      method_key = ServiceDefinitions.lookup_method(sdef_pid, method_name)
      if method_key and not method_defined? method_key
        define_method(method_key) { |*args, &block|
            opts = args[0] || {}
            opts = opts.merge({:pid => pid, :sdef => sdef_pid, :method => method_name })
          # dispatch to the dissemination method on restAPI client
            ActiveFedora::Base.connection_for_pid(pid).dissemination opts, &block
        }
      end
    end
  end
end
end
