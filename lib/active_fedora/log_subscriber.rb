module ActiveFedora
  class LogSubscriber < ActiveSupport::LogSubscriber
    def initialize
      super
      @odd = false
    end

    def ldp(event)
      return unless logger.debug?

      payload = event.payload

      name = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      id = payload[:id] || "[no id]"

      if odd?
        name = color(name, CYAN, true)
        id = color(id, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name} #{id} Service: #{payload[:ldp_service]}"
    end

    def odd?
      @odd = !@odd
    end

    def logger
      ActiveFedora::Base.logger
    end
  end
end

ActiveFedora::LogSubscriber.attach_to :active_fedora
