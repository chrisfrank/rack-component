require 'spec_helper'
require 'pry'

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
        <h1>#{local} %{env[:name]}</h1>
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
        render { |name:, dept: department| "%{name} - %{dept}" }
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
      def initialize(id:)
        super
        @id = id
      end
    end
    instance = comp.new(id: 1)
    expect(instance.instance_variable_get(:@id)).to be(1)
    expect(comp.call(id: 2)).to eq({ id: 2 })
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
end
