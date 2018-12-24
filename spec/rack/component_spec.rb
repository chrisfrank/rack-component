require 'spec_helper'
require 'pry'
require 'securerandom'

RSpec.describe Rack::Component do
  Fn = proc do |env = {}, &children|
    <<~HTML
      <h1>Hello #{env[:name]}</h1>
      #{children&.call}
    HTML
  end

  Comp = Class.new(Rack::Component) do
    render do |env, &children|
      <<~HTML
        <h1>Hello #{env[:name]}</h1>
        #{children&.call}
      HTML
    end
  end

  describe 'compared to a Proc' do
    it 'behaves identically without children' do
      props = { name: 'Chris' }
      expect(Comp.call(props)).to eq(Fn.call(props))
    end

    it 'behaves identically with children' do
      props = { name: 'Chris' }
      expect(Comp.call(props) { 'child' }).to eq(Fn.call(props) { 'child' })
    end

    it 'lets you call without arguments' do
      expect(Fn.call).to eq(Comp.call)
    end
  end

  describe 'handling keyword arguments' do
    it 'supports required args' do
      comp = Class.new(Rack::Component) { render { |name:| name } }
      expect(comp.call(name: 'Jean Luc')).to eq('Jean Luc')
      expect { comp.call }.to raise_error(ArgumentError)
    end

    it 'supports optional keyword args' do
      comp = Class.new(Rack::Component) { render { |name: 'Jean Luc'| name } }
      expect(comp.call).to eq('Jean Luc')
      expect(comp.call(name: 'Riker')).to eq('Riker')
    end

    it 'supports a single &block arg' do
      comp = Class.new(Rack::Component) { render { |_, &children| children.call } }
      expect(comp.call { "hi" }).to eq('hi')
    end

    it 'supports no args at all' do
      comp = Class.new(Rack::Component) { render { |_| 'hi' } }
      expect(comp.call).to eq('hi')
      expect(comp.call(jim: 'miller')).to eq('hi')
    end

    it 'can mix required and optional keywords' do
      comp = Class.new(Rack::Component) do
        render { |name:, dept: 'Staff'| "#{name} - #{dept}" }
      end
      actual = comp.call(name: 'La Forge', dept: 'Engineering')
      expect(actual).to eq('La Forge - Engineering')
    end
  end

  it 'returns self by default when render is not defined' do
    expect(Rack::Component.call).to be_a(Rack::Component)
  end

  it 'yields to nested blocks' do
    @comp = Class.new(Rack::Component)

    @comp.call { 'nested' }.tap do |res|
      expect(res).to include('nested')
    end
  end

  it 'lets you override initialize easily' do
    comp = Class.new(Rack::Component) do
      def initialize(id)
        @id = id
      end

      render { |env| env }
    end
    instance = comp.new(1)
    expect(instance.instance_variable_get(:@env)).to be(nil)
    expect(instance.instance_variable_get(:@id)).to be(1)
    expect(instance.call(2)).to eq(2)
  end

  it 'renders json swimmingly' do
    require 'json'
    @comp = Class.new(Rack::Component) do
      render { |env| env.to_json }
    end

    @comp.call(captain: 'kirk').tap do |res|
      expect(JSON.parse(res).fetch('captain')).to eq('kirk')
    end
  end

  describe 'cached' do
    before do
      @rando = Class.new(Rack::Component) do
        render { |_| SecureRandom.uuid }
      end
    end

    it 'caches identical calls' do
      @rando.cached.tap do |uuid|
        expect(@rando.cached).to eq(uuid)
      end
    end

    it 'works with components that have overriden initialize' do
      comp = Class.new(Rack::Component) do
        def initialize(id:, name:)
          @id = id
          @name = name
        end

        render { |_| SecureRandom.uuid }
      end

      comp.cached(id: 1, name: "chris").tap do |output|
        expect(comp.cached(id: 1, name: "chris")).to eq(output)
        expect(comp.cached(id: 2, name: "chris")).not_to eq(output)
      end
    end

    it 'limits the cache size to 100 keys by default' do
      (0..200).map { |key| @rando.cached(key) }
      @rando.send(:cache).store.tap do |store|
        expect(store.length).to eq(100)
      end
    end

    it 'overrides the cache size via a CACHE_SIZE constant' do
      class Tiny < Rack::Component
        CACHE_SIZE = 50
        render { |_| "meh" }
      end
      (0..200).map { |key| Tiny.cached(key) }
      Tiny.send(:cache).store.tap do |store|
        expect(store.length).to eq(50)
      end
    end

    it 'busts cache based on props' do
      @rando.cached.tap do |uuid|
        expect(@rando.cached(1)).not_to eq(uuid)
      end
    end

    it 'does not bust cache based on block' do
      @rando.cached.tap do |uuid|
        expect(@rando.cached { 'children' }).to eq(uuid)
      end
    end

    describe 'flushing the entire component cache' do
      before do
        # fill the cache of two memoized components
        @alt = Class.new(@rando) do
          render { |_| 'etc' }
        end
        @rando.cached
        @alt.cached
      end

      it 'flushes itself and its descendants' do
        Rack::Component.flush
        [@rando, @alt, Rack::Component].each do |comp|
          expect(comp.send(:cache).store.empty?).to eq(true)
        end
      end
    end
  end
end
