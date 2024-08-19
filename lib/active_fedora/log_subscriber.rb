module ActiveFedora
  class LogSubscriber < ActiveSupport::LogSubscriber
    def initialize
      super
      @odd = false
    end

    # rubocop:disable Style/IfInsideElse
    def ldp(event)
      return unless logger.debug?

      payload = event.payload

      name = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      id = payload[:id] || "[no id]"

      if ActiveSupport.version >= Gem::Version.new('7.1.0')
        if odd?
          name = color(name, CYAN, bold: true)
          id = color(id, nil, bold: true)
        else
          name = color(name, MAGENTA, bold: true)
        end
      else
        if odd?
          name = color(name, CYAN, true)
          id = color(id, nil, true)
        else
          name = color(name, MAGENTA, true)
        end
      end

      debug "  #{name} #{id} Service: #{payload[:ldp_service]}"
    end
    # rubocop:enable Style/IfInsideElse

    def odd?
      @odd = !@odd
    end

    def logger
      ActiveFedora::Base.logger
    end
  end
end

ActiveFedora::LogSubscriber.attach_to :active_fedora
