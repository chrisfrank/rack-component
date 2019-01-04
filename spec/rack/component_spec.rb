require 'spec_helper'
require 'pry'
require 'securerandom'

RSpec.describe Rack::Component do
  Fn = proc do |env, &child|
    local = 'Hello'
    <<~HTML
      <h1>#{local} #{env[:name]}</h1>
      #{child&.call}
    HTML
  end

  class Comp < Rack::Component
    render do |env, &child|
      local = 'Hello'
      <<~HTML
        <h1>#{local} %{name}</h1>
        #{child&.call}
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

    describe 'with HTML in env' do
      it 'escapes output by default' do
        props = { name: '<span>jim</span>' }
        result = Comp.call(props)
        expect(result).not_to eq(Fn.call(props))
        expect(result).to eq("<h1>Hello &lt;span&gt;jim&lt;/span&gt;</h1>\n\n")
      end
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

    it 'can set optional keywords with instance methods' do
      comp = Class.new(Rack::Component) do
        render { |name:, dept: department| "#{name} - #{dept}" }
        def department
          'Staff'
        end
      end
      expect(comp.call(name: 'La Forge')).to eq('La Forge - Staff')
    end
  end

  describe 'without a render block' do
    it 'returns its env by default' do
      expect(Rack::Component.call).to eq({})
    end

    it 'yields self when called with a block' do
      @comp = Class.new(Rack::Component)

      @comp.call({ id: 1}) { |env| "Hi from comp #{env[:id]}" }.tap do |res|
        expect(res).to eq('Hi from comp 1')
      end
    end
  end

  it 'still works after overriding initialize' do
    comp = Class.new(Rack::Component) do
      def initialize(id)
        @id = id
      end
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

  it 'escapes output by default' do
    comp = Class.new(Rack::Component) do
      render { |env| "<h1><%= env[:name] %></h1>" }
    end

  end

  describe 'memoized' do
    before do
      @rando = Class.new(Rack::Component) do
        render { |_| SecureRandom.uuid }
      end
    end

    it 'caches identical calls' do
      @rando.memoized.tap do |uuid|
        expect(@rando.memoized).to eq(uuid)
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

      comp.memoized(id: 1, name: "chris").tap do |output|
        expect(comp.memoized(id: 1, name: "chris")).to eq(output)
        expect(comp.memoized(id: 2, name: "chris")).not_to eq(output)
      end
    end

    it 'limits the cache size to 100 keys by default' do
      (0..200).map { |key| @rando.memoized(key: key) }
      @rando.send(:cache).store.tap do |store|
        expect(store.length).to eq(100)
      end
    end

    it 'overrides the cache size by calling class#cache with a block' do
      class Tiny < Rack::Component
        cache { MemoryCache.new(length: 50) }
        render { |_| "meh" }
      end
      (0..200).map { |key| Tiny.memoized(key: key) }
      Tiny.send(:cache).store.tap do |store|
        expect(store.length).to eq(50)
      end
    end

    it 'busts cache based on props' do
      @rando.memoized.tap do |uuid|
        expect(@rando.memoized(key: 1)).not_to eq(uuid)
      end
    end

    it 'does not bust cache based on block' do
      @rando.memoized.tap do |uuid|
        expect(@rando.memoized { 'children' }).to eq(uuid)
      end
    end

    it 'flushes itself on #flush' do
      @rando.memoized
      @rando.flush
      expect(@rando.send(:cache).store.empty?).to eq(true)
    end
  end
end
