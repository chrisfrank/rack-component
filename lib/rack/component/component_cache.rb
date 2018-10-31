module Rack
  class Component
    # Threadsafe in-memory cache
    class ComponentCache
      attr_reader :store

      # Initialize a mutex for threadsafe reads and writes
      LOCK = Mutex.new

      # Store cache in a hash
      def initialize(limit = 100)
        @store = {}
        @limit = limit
      end

      # Fetch a key from the cache, if it exists
      # If the key doesn't exist and a block is passed, set the key
      # @return the cached value
      def fetch(key)
        store.fetch(key) do
          write(key, yield) if block_given?
        end
      end

      # empty the cache
      # @return [Hash] the empty store
      def flush
        LOCK.synchronize { @store = {} }
      end

      private

      # Cache a value and return it
      def write(key, value)
        LOCK.synchronize do
          store[key] = value
          store.delete(@store.keys.first) if store.length > @limit
          value
        end
      end
    end

    private_constant :ComponentCache
  end
end
