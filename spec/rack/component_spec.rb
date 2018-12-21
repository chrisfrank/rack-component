require 'spec_helper'
require 'pry'
require 'securerandom'

RSpec.describe Rack::Component do
  it 'renders children by default when passed a block' do
    Rack::Component.call { 'child node' }.tap do |res|
      expect(res).to eq('child node')
    end
  end

  it 'returns self by default with no block' do
    expect(Rack::Component.call).to be_a(Rack::Component)
  end

  it 'yields to nested blocks' do
    @comp = Class.new(Rack::Component)

    @comp.call { 'nested' }.tap do |res|
      expect(res).to include('nested')
    end
  end

  it 'lets you override initialize easily' do
    @comp = Class.new(Rack::Component) do
      def initialize(id)
        @id = id
      end

      def render
        @id
      end
    end

    @comp.call('chris').tap do |res|
      expect(res).to eq('chris')
    end
  end

  it 'renders json swimmingly' do
    require 'json'
    @comp = Class.new(Rack::Component) do
      def initialize(props)
        @props = props
      end

      def render
        @props.to_json
      end
    end

    @comp.call(captain: 'kirk').tap do |res|
      expect(JSON.parse(res).fetch('captain')).to eq('kirk')
    end
  end

  it 'yields to nested blocks of any arity' do
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
    before do
      @rando = Class.new(Rack::Component::Memoized) do
        def initialize(key = nil)
          @key = key
        end

        def render
          SecureRandom.uuid
        end
      end
    end

    it 'caches identical calls' do
      @rando.call.tap do |uuid|
        expect(@rando.call).to eq(uuid)
      end
    end

    it 'works with components that have overriden initialize' do
      comp = Class.new(Rack::Component::Memoized) do
        def initialize(id, name)
          @id = id
          @name = name
        end

        def render
          SecureRandom.uuid
        end
      end

      comp.call(1, "chris").tap do |output|
        expect(comp.call(1, "chris")).to eq(output)
        expect(comp.call(2, "chris")).not_to eq(output)
      end
    end

    it 'limits the cache size to 100 keys by default' do
      (0..200).map { |key| @rando.call(key) }
      @rando.cache.store.tap do |store|
        expect(store.length).to eq(100)
      end
    end

    it 'overrides the cache size via a CACHE_SIZE constant' do
      class Tiny < Rack::Component::Memoized
        CACHE_SIZE = 50
        def initialize(key)
          @key = key
        end
      end
      (0..200).map { |key| Tiny.call(key) }
      Tiny.cache.store.tap do |store|
        expect(store.length).to eq(50)
      end
    end

    it 'busts cache based on props' do
      @rando.call.tap do |uuid|
        expect(@rando.call(1)).not_to eq(uuid)
      end
    end

    it 'does not bust cache based on block' do
      @rando.call.tap do |uuid|
        expect(@rando.call { 'children' }).to eq(uuid)
      end
    end

    describe 'flushing the entire component cache' do
      before do
        # fill the cache of two memoized components
        @alt = Class.new(@rando)
        @rando.call
        @alt.call
      end

      it 'flushes itself and its descendants' do
        Rack::Component::Memoized.clear_caches
        [@rando, @alt, Rack::Component::Memoized].each do |comp|
          expect(comp.cache.store.empty?).to eq(true)
        end
      end
    end
  end
end
