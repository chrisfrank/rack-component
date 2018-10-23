module Rack
  class Component
    # Threadsafe in-memory cache
    class ComponentCache
      # Initialize a mutex for threadsafe reads and writes
      LOCK = Mutex.new

      # Store cache in a hash
      def initialize(limit = 100)
        @cache = {}
        @limit = limit
      end

      # Fetch a key from the cache, if it exists
      # If the key doesn't exist and a block is passed, set the key
      # @return the cached value
      def fetch(key)
        LOCK.synchronize do
          @cache.fetch(key) do
            write(key, yield) if block_given?
          end
        end
      end

      private

      # Cache a value and return it
      def write(key, value)
        @cache.store(key, value)
        @cache.delete(@cache.keys.first) if @cache.length > @limit
        value
      end
    end

    private_constant :ComponentCache
  end
end
