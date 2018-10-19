module Rack
  class Component
    # Threadsafe in-memory cache
    class Cache
      # A mutex for threadsafe cache writes
      LOCK = Mutex.new

      # Store cache in a hash
      def initialize
        @cache = {}
      end

      # Fetch a key from the cache, if it exists
      # If the key doesn't exist and a block is passed, set the key
      # @return the cached value
      def fetch(key)
        @cache.fetch(key) do
          write(key, yield) if block_given?
        end
      end

      # Cache a value in memory
      def write(key, value)
        LOCK.synchronize do
          @cache.store(key, value)
        end
      end
    end

    private_constant :Cache
  end
end
