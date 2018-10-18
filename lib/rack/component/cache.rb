module Rack
  # Render a chain of components
  class Component
    # Threadsafe in-memory cache for holding cached output
    class Cache
      LOCK = Mutex.new

      def initialize
        @cache = {}
      end

      def get(key)
        @cache.fetch(key) do
          set(key, yield)
        end
      end

      def set(key, value)
        LOCK.synchronize do
          @cache[key] = value
          value
        end
      end
    end

    private_constant :Cache
  end
end
