module Rack
  class Component
    # Threadsafe in-memory cache
    class MemoryCache
      attr_reader :store, :mutex

      # Store cache in a hash
      def initialize(length: 100)
        @store = {}
        @length = length
        @mutex = Mutex.new
      end

      # Fetch a key from the cache, if it exists
      # If the key doesn't exist and a block is passed, set the key
      # @return the cached value
      def fetch(key)
        store.fetch(key) do
          set(key, yield) if block_given?
        end
      end

      # empty the cache
      # @return [Hash] the empty store
      def flush
        mutex.synchronize { @store = {} }
      end

      private

      # Cache a value and return it
      def set(key, value)
        mutex.synchronize do
          store[key] = value
          store.delete(@store.keys.first) if store.length > @length
          value
        end
      end
    end

    private_constant :MemoryCache
  end
end
