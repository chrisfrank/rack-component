require 'spec_helper'
require 'pry'
require 'securerandom'

RSpec.describe Rack::Component do
  it 'renders children by default' do
    Rack::Component.call { 'child node' }.tap do |res|
      expect(res).to eq('child node')
    end
  end

  it 'can yield to nested components' do
    @comp = Class.new(Rack::Component) do
      def render
        yield
      end
    end

    @comp.call { 'nested' }.tap do |res|
      expect(res).to include('nested')
    end
  end

  it 'has access to props when rendering' do
    @comp = Class.new(Rack::Component) do
      def render
        "#{props[:name]}"
      end
    end

    @comp.call(name: 'Chris').tap do |res|
      expect(res).to eq('Chris')
    end
  end

  it 'can render json' do
    require 'json'
    @comp = Class.new(Rack::Component) do
      def render
        props.to_json
      end
    end

    @comp.call(captain: 'kirk') do |res|
      expect(JSON.parse(res.to_s).first.fetch('rank')).to eq('captain')
    end
  end

  it 'can yield to nested components of any arity' do
    @comp = Class.new(Rack::Component) do
      def hi() 'hi' end

      def render
        yield(self, 'this', 'that')
      end
    end

    @comp.call { |scope, x, y| [scope.hi, x, y].join(' ') }.tap do |res|
      expect(res).to eq('hi this that')
    end
  end

  describe Rack::Component::Memoized do
    RandomComponent = Class.new(Rack::Component::Memoized) do
      def render
        SecureRandom.uuid
      end
    end

    it 'caches identical calls' do
      RandomComponent.call.tap do |uuid|
        expect(RandomComponent.call).to eq(uuid)
      end
    end

    it 'limits the cache size to 100 keys by default' do
      (0..200).map { |key| RandomComponent.call(key) }
      RandomComponent.cache.instance_variable_get(:@cache).tap do |cache|
        expect(cache.length).to eq(100)
      end
    end

    it 'can change the cache size' do
      class Tiny < Rack::Component::Memoized
        CACHE_SIZE = 50
      end
      (0..200).map { |key| Tiny.call(key) }
      Tiny.cache.instance_variable_get(:@cache).tap do |cache|
        expect(cache.length).to eq(50)
      end
    end

    it 'busts cache based on props' do
      RandomComponent.call.tap do |uuid|
        expect(RandomComponent.call(1)).not_to eq(uuid)
      end
    end

     it 'busts cache based on block' do
      RandomComponent.call do |uuid|
        expect(RandomComponent.call { 'children' }).not_to eq(uuid)
      end
    end

   it 'does not bust cache based on nested blocks' do
      Layout = Class.new(RandomComponent)
      first = Layout.call do
        RandomComponent.call do
          RandomComponent.call do
            'hi'
          end
        end
      end

      last = Layout.call do
        RandomComponent.call do
          RandomComponent.call do
            'bye'
          end
        end
      end

      expect(first).to eq(last)
    end
  end
end
