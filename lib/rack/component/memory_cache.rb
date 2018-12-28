module Rack
  class Component
    # A threadsafe, in-memory, per-component cache
    class MemoryCache
      attr_reader :store, :mutex

      # Use a hash to store cached calls and a mutex to make it threadsafe
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

      # Empty the cache
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
  end
end
