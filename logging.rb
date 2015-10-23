module Logging
    class ScopedLogger
    @prefix
    def initialize(prefix, logger)
      @prefix = prefix
      @logger = logger
    end

    def fatal(message)
      @logger.fatal(@prefix + ': ' + message)
    end

    def error(message)
      @logger.error(@prefix + ': ' + message)
    end

    def warn(message)
      @logger.warn(@prefix + ': ' + message)
    end

    def info(message)
      @logger.info(@prefix + ': ' + message)
    end

    def debug(message)
      @logger.debug(@prefix + ': ' + message)
    end

    def close
      @logger.close()
    end
  end

  class MultiLogger
    def initialize(location)
      @fileLogger = Logger.new(location)
      @fileLogger.level = Logger::DEBUG
      @stdLogger = Logger.new(STDOUT)
      @stdLogger.level = Logger::INFO
    end

    def fatal(message)
      @fileLogger.fatal(message)
      @stdLogger.fatal(message)
    end

    def error(message)
      @fileLogger.error(message)
      @stdLogger.error(message)
    end

    def warn(message)
      @fileLogger.warn(message)
      @stdLogger.warn(message)
    end

    def info(message)
      @fileLogger.info(message)
      @stdLogger.info(message)
    end

    def debug(message)
      @fileLogger.debug(message)
      @stdLogger.debug(message)
    end

    def close
      @fileLogger.close()
      @stdLogger.close()
    end
  end
end