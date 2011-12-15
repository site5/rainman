module Rainman
  module Driver
    # Array of known handlers
    def handlers
      @handlers ||= []
    end

    # Action options
    def options
      @options ||= {}
    end

    # Registers a handler with the driver
    def register_handler(name, &block)
      add_handler(name)
      name  = name.to_s
      klass = "#{self.name}::#{name.to_s.camelize}"
      if self::const_defined?(name.camelize)
        k = klass.constantize.extend(Rainman::Handler)
        yield k.config if block_given?
      else
        raise "Unknown handler '#{self}::#{name.camelize}'"
      end
    end

    # Adds a driver method
    def define_action(name, &block)
      opts = Option.new(name)
      if block_given?
        yield opts
        options[name] = opts.all unless opts.all.empty?
      end

      (class << self; self; end).class_eval do
        define_method name do |*args|
          opts.validate!(*args)
        end
      end
    end

  private
    # Records the driver handler in the @handlers array
    def add_handler(name)
      if handlers.include?(name)
        raise "Handler already registered '#{self}::#{name.to_s.camelize}'"
      else
        handlers << name
      end
    end

  end
end
