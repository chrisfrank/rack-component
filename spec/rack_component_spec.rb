require 'spec_helper'
require_relative 'fixtures/views'
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

    describe 'with a real component chain' do
      let(:app) do
        Class.new(Rack::Component) do
          def status
            207
          end

          def headers
            { 'X-Rendered-By' => 'Rack::Component' }
          end

          def render
            Views::Layout.new do
              %(
                <article>
                  <p>I am an html paragraph</p>
                  #{Views::Footer.new}
                  #{props['HTTP_HOST']}
                </article>
              )
            end
          end
        end
      end

      before { @res = get('/') }

      it 'renders its child components' do
        expect(@res.body).to include('<article>')
        expect(@res.body).to include('<nav>')
      end

      it 'merges custom headers' do
        expect(@res.headers['X-Rendered-By']).to eq('Rack::Component')
        expect(@res.headers).to have_key('Content-Length')
      end

      it('respects custom status') { expect(@res.status).to eq(207) }

      it 'has access to Rack’s [env] hash via self.props' do
        expect(@res.body).to include('example.org')
      end
    end
  end

  describe 'rendering' do
    it 'renders children by default' do
      Rack::Component.render { 'child node' }.tap do |res|
        expect(res).to eq('child node')
      end
    end

    it 'nests components' do
      Views::Layout.render { 'nested' }.tap do |res|
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
      Test.render.tap do |res|
        expect(res).to include('<header>')
        expect(res).to include('<footer>')
      end
    end

    it 'has access to props when rendering' do
      Views::PropsComponent.render(name: 'Chris').tap do |res|
        expect(res).to eq('Chris')
      end
    end

    it 'can render json' do
      Views::JSONComponent.render { 'hmmm' }.tap do |res|
        expect(JSON.parse(res).first.fetch('rank')).to eq('captain')
      end
    end
  end

  describe Rack::Component::Pure do
    RandomComponent = Class.new(Rack::Component::Pure) do
      def render
        SecureRandom.uuid
      end
    end

    it 'caches identical calls' do
      RandomComponent.render.tap do |uuid|
        expect(RandomComponent.render).to eq(uuid)
      end
    end

    it 'busts cache based on block' do
      RandomComponent.render.tap do |uuid|
        expect(RandomComponent.render { 'children' }).not_to eq(uuid)
      end
    end

    it 'busts cache based on props' do
      RandomComponent.render.tap do |uuid|
        expect(RandomComponent.render(1)).not_to eq(uuid)
      end
    end
  end
end
