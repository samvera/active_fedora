module ActiveFedora
  module FinderMethods
    # Returns true if the pid exists in the repository
    # @param[String] pid
    # @return[boolean]
    def exists?(conditions)
      conditions = conditions.id if Base === conditions
      return false if !conditions
      !!DigitalObject.find(self.klass, conditions)
    rescue ActiveFedora::ObjectNotFoundError
      false
    end

  end
end
