require 'spec_helper'
require_relative '../fixtures/views'
require 'pry'
require 'securerandom'

RSpec.describe Rack::Component do
  describe 'responding to call' do
    describe 'with defaults' do
      let(:app) { Rack::Component }
      before { @res = get('/') }

      it('has HTTP status 200') { expect(@res.status).to eq(200) }
      it('has the default Rack::Response headers') do
        expect(@res.header).to have_key('Content-Length')
      end
      it('renders an empty body') { expect(@res.body).to eq('') }
    end
  end

  describe 'rendering to string' do
    it 'renders children by default' do
      Rack::Component.new { 'child node' }.to_s.tap do |res|
        expect(res).to eq('child node')
      end
    end

    it 'renders nested components' do
      Views::Layout.new { 'nested' }.to_s.tap do |res|
        expect(res).to include('nested')
      end
    end

    it 'can mix ERB and string interpolation' do
      Test = Class.new(Rack::Component) do
        def render
          %(
            #{Views::Header.new}
            <main>the content</main>
            <%= Views::Footer.new %>
          )
        end
      end
      Test.new.to_s.tap do |res|
        expect(res).to include('<header>')
        expect(res).to include('<footer>')
      end
    end

    it 'has access to props when rendering' do
      Views::PropsComponent.new(name: 'Chris').to_s.tap do |res|
        expect(res).to eq('Chris')
      end
    end

    it 'can render json' do
      Views::JSONComponent.new { 'hmmm' }.tap do |res|
        expect(JSON.parse(res.to_s).first.fetch('rank')).to eq('captain')
      end
    end

    it 'can render children of any arity' do
      Comp = Class.new(Rack::Component) do
        def hi() 'hi' end

        def render
          children(self, 'this', 'that')
        end
      end
      Comp.new { |scope, x, y| [scope.hi, x, y].join(' ') }.to_s.tap do |res|
        expect(res).to eq('hi this that')
      end
    end
  end

  describe Rack::Component::Memoized do
    RandomComponent = Class.new(Rack::Component::Memoized) do
      def render
        SecureRandom.uuid
      end
    end

    it 'caches identical calls' do
      RandomComponent.new.to_s.tap do |uuid|
        expect(RandomComponent.new.to_s).to eq(uuid)
      end
    end

    it 'busts cache based on block' do
      RandomComponent.new.to_s do |uuid|
        expect(RandomComponent.new { 'children' }.to_s).not_to eq(uuid)
      end
    end

    it 'busts cache based on props' do
      RandomComponent.new.to_s do |uuid|
        expect(RandomComponent.new(1).to_s).not_to eq(uuid)
      end
    end

    it 'busts cache based on nested blocks' do
      Layout = Class.new(RandomComponent)
      first = Layout.new do
        RandomComponent.new do
          RandomComponent.new do
            'hi'
          end
        end
      end.to_s

      last = Layout.new do
        RandomComponent.new do
          RandomComponent.new do
            'bye'
          end
        end
      end.to_s

      expect(first).not_to eq(last)
    end
  end
end
